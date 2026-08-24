import ballerina/http;

listener http:Listener ep0 = new (9090);

service / on ep0 {

    resource function get expense\-claims(@http:Header {name: "X-User-Id"} string? userId,
            "pending"|"approved"|"rejected"? status, int 'limit = 20, int offset = 0)
            returns inline_response_200|http:Unauthorized|ErrorForbidden|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }

        int pageLimit = 'limit;
        if pageLimit < 1 {
            pageLimit = 20;
        } else if pageLimit > 100 {
            pageLimit = 100;
        }
        int pageOffset = offset < 0 ? 0 : offset;

        record {| int count; ExpenseClaim[] data; |} result =
            check listClaimsForCaller(caller, status, pageLimit, pageOffset);

        string? next = ();
        if pageOffset + pageLimit < result.count {
            next = buildPageUri(status, pageLimit, pageOffset + pageLimit);
        }
        string? previous = ();
        if pageOffset > 0 {
            int previousOffset = pageOffset - pageLimit;
            if previousOffset < 0 {
                previousOffset = 0;
            }
            previous = buildPageUri(status, pageLimit, previousOffset);
        }

        return {count: result.count, next, previous, data: result.data};
    }

    resource function get expense\-claims/[string claimId](@http:Header {name: "X-User-Id"} string? userId)
            returns ExpenseClaim|http:Unauthorized|ErrorForbidden|ErrorNotFound|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        ClaimRow? row = check fetchClaimRow(claimId);
        if row is () {
            return notFound("claim not found");
        }

        boolean allowed = row.employeeId == caller.id;
        if !allowed && caller.role == "manager" {
            allowed = check isDirectReportOf(caller.id, row.employeeId);
        }
        if !allowed && caller.role == "finance" {
            allowed = row.status == "approved";
        }
        if !allowed {
            return forbidden("caller may not view this claim");
        }
        return check toExpenseClaim(row);
    }

    resource function get expense\-claims/export(@http:Header {name: "X-User-Id"} string? userId)
            returns http:Response|http:Unauthorized|ErrorForbidden|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        if caller.role != "finance" {
            return forbidden("only finance may export claims");
        }
        ClaimRow[] rows = check exportApprovedClaims();
        string csv = claimRowsToCsv(rows);
        http:Response response = new;
        response.setTextPayload(csv, contentType = "text/csv");
        response.setHeader("Content-Disposition", "attachment; filename=\"expense-claims-export.csv\"");
        return response;
    }

    resource function post expense\-claims(@http:Header {name: "X-User-Id"} string? userId, ExpenseClaimInput payload)
            returns ExpenseClaim|http:Unauthorized|ErrorBadRequest|ErrorForbidden|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        if caller.role != "employee" && caller.role != "manager" {
            return forbidden("caller may not submit expense claims");
        }
        string? validationError = validateClaimInput(payload);
        if validationError is string {
            return badRequest(validationError);
        }
        return check insertClaim(caller.id, payload);
    }

    resource function post expense\-claims/[string claimId]/approve(@http:Header {name: "X-User-Id"} string? userId)
            returns ExpenseClaimOk|http:Unauthorized|ErrorBadRequest|ErrorForbidden|ErrorNotFound|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        if caller.role != "manager" {
            return forbidden("only a manager may approve claims");
        }
        ClaimRow? row = check fetchClaimRow(claimId);
        if row is () {
            return notFound("claim not found");
        }
        if row.employeeId == caller.id {
            return forbidden("a manager cannot approve their own claim");
        }
        boolean isReport = check isDirectReportOf(caller.id, row.employeeId);
        if !isReport {
            return forbidden("caller is not this claim's manager");
        }
        if row.status != "pending" {
            return badRequest("claim is not in pending status");
        }
        ExpenseClaim updated = check approveClaimRow(claimId);
        return <ExpenseClaimOk>{body: updated};
    }

    resource function post expense\-claims/[string claimId]/reject(@http:Header {name: "X-User-Id"} string? userId,
            claimId_reject_body payload)
            returns ExpenseClaimOk|http:Unauthorized|ErrorBadRequest|ErrorForbidden|ErrorNotFound|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        if caller.role != "manager" {
            return forbidden("only a manager may reject claims");
        }
        ClaimRow? row = check fetchClaimRow(claimId);
        if row is () {
            return notFound("claim not found");
        }
        if row.employeeId == caller.id {
            return forbidden("a manager cannot reject their own claim");
        }
        boolean isReport = check isDirectReportOf(caller.id, row.employeeId);
        if !isReport {
            return forbidden("caller is not this claim's manager");
        }
        string reasonValue = payload.reason.trim();
        if reasonValue.length() == 0 {
            return badRequest("reason is required");
        }
        if row.status != "pending" {
            return badRequest("claim is not in pending status");
        }
        ExpenseClaim updated = check rejectClaimRow(claimId, payload.reason);
        return <ExpenseClaimOk>{body: updated};
    }

    resource function put expense\-claims/[string claimId](@http:Header {name: "X-User-Id"} string? userId,
            ExpenseClaimInput payload)
            returns ExpenseClaim|http:Unauthorized|ErrorBadRequest|ErrorForbidden|ErrorNotFound|error {
        if userId is () {
            return unauthorized("X-User-Id header is required");
        }
        Employee? caller = check getEmployeeById(userId);
        if caller is () {
            return forbidden("no employee record for caller");
        }
        ClaimRow? row = check fetchClaimRow(claimId);
        if row is () {
            return notFound("claim not found");
        }
        if row.employeeId != caller.id {
            return forbidden("caller does not own this claim");
        }
        if row.status != "rejected" {
            return badRequest("claim is not in rejected status");
        }
        string? validationError = validateClaimInput(payload);
        if validationError is string {
            return badRequest(validationError);
        }
        return check updateClaimFields(claimId, payload);
    }
}
