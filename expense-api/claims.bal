import ballerina/sql;
import ballerina/time;
import ballerina/uuid;

type ClaimCategory "Travel"|"Meals"|"Lodging"|"Office Supplies"|"Other";
type ClaimStatus "pending"|"approved"|"rejected";

type ClaimRow record {|
    string id;
    string employeeId;
    string category;
    decimal amount;
    string description;
    string date;
    string status;
    string? receiptUrl;
    string? rejectionReason;
    boolean exported;
    time:Utc createdAt;
    time:Utc updatedAt;
|};

const string CLAIM_ROW_COLUMNS = "id, employee_id AS \"employeeId\", category, amount, description, date, status, " +
    "receipt_url AS \"receiptUrl\", rejection_reason AS \"rejectionReason\", exported, " +
    "created_at AS \"createdAt\", updated_at AS \"updatedAt\"";

function toCategory(string category) returns ClaimCategory|error {
    match category {
        "Travel" => { return "Travel"; }
        "Meals" => { return "Meals"; }
        "Lodging" => { return "Lodging"; }
        "Office Supplies" => { return "Office Supplies"; }
        "Other" => { return "Other"; }
    }
    return error("invalid category stored: " + category);
}

function toStatus(string status) returns ClaimStatus|error {
    match status {
        "pending" => { return "pending"; }
        "approved" => { return "approved"; }
        "rejected" => { return "rejected"; }
    }
    return error("invalid status stored: " + status);
}

function toExpenseClaim(ClaimRow row) returns ExpenseClaim|error {
    ClaimCategory category = check toCategory(row.category);
    ClaimStatus status = check toStatus(row.status);
    return {
        id: row.id,
        employeeId: row.employeeId,
        category,
        amount: row.amount,
        description: row.description,
        date: row.date,
        receiptUrl: row.receiptUrl,
        status,
        rejectionReason: row.rejectionReason,
        exported: row.exported,
        createdAt: time:utcToString(row.createdAt),
        updatedAt: time:utcToString(row.updatedAt)
    };
}

// Validates the fields shared by submission and edit/resubmit. amount,
// category, description and date are required by ExpenseClaimInput's
// generated type already (category is further enum-checked by payload
// binding); this only covers what the type system cannot: value sanity.
function validateClaimInput(ExpenseClaimInput payload) returns string? {
    if payload.amount <= 0d {
        return "amount must be greater than zero";
    }
    string trimmedDescription = payload.description.trim();
    if trimmedDescription.length() == 0 {
        return "description must not be empty";
    }
    if !isValidDate(payload.date) {
        return "date must be a valid date in YYYY-MM-DD format";
    }
    return ();
}

function isValidDate(string dateValue) returns boolean {
    if dateValue.length() != 10 {
        return false;
    }
    if dateValue.substring(4, 5) != "-" || dateValue.substring(7, 8) != "-" {
        return false;
    }
    int|error year = int:fromString(dateValue.substring(0, 4));
    int|error month = int:fromString(dateValue.substring(5, 7));
    int|error day = int:fromString(dateValue.substring(8, 10));
    if year is error || month is error || day is error {
        return false;
    }
    if month < 1 || month > 12 {
        return false;
    }
    if day < 1 || day > 31 {
        return false;
    }
    return true;
}

function fetchClaimRow(string claimId) returns ClaimRow?|error {
    sql:ParameterizedQuery query = sql:queryConcat(
        `SELECT `, `${CLAIM_ROW_COLUMNS}`, ` FROM expense_claim WHERE id = ${claimId}`
    );
    stream<ClaimRow, sql:Error?> resultStream = dbClient->query(query);
    ClaimRow? found = ();
    error? loopError = from ClaimRow claimRow in resultStream
        do {
            found = claimRow;
        };
    check resultStream.close();
    if loopError is error {
        return loopError;
    }
    return found;
}

function insertClaim(string employeeId, ExpenseClaimInput payload) returns ExpenseClaim|error {
    string newId = uuid:createType4AsString();
    time:Utc now = time:utcNow();
    _ = check dbClient->execute(`
        INSERT INTO expense_claim
            (id, employee_id, category, amount, description, date, status, receipt_url, rejection_reason, exported, created_at, updated_at)
        VALUES
            (${newId}, ${employeeId}, ${payload.category}, ${payload.amount}, ${payload.description}, ${payload.date},
             'pending', ${payload?.receiptUrl}, NULL, FALSE, ${now}, ${now})
    `);
    ClaimRow? row = check fetchClaimRow(newId);
    if row is () {
        return error("failed to load claim after insert");
    }
    return toExpenseClaim(row);
}

function updateClaimFields(string claimId, ExpenseClaimInput payload) returns ExpenseClaim|error {
    time:Utc now = time:utcNow();
    _ = check dbClient->execute(`
        UPDATE expense_claim
        SET category = ${payload.category}, amount = ${payload.amount}, description = ${payload.description},
            date = ${payload.date}, receipt_url = ${payload?.receiptUrl}, status = 'pending',
            rejection_reason = NULL, updated_at = ${now}
        WHERE id = ${claimId}
    `);
    ClaimRow? row = check fetchClaimRow(claimId);
    if row is () {
        return error("failed to load claim after update");
    }
    return toExpenseClaim(row);
}

function approveClaimRow(string claimId) returns ExpenseClaim|error {
    time:Utc now = time:utcNow();
    _ = check dbClient->execute(`
        UPDATE expense_claim SET status = 'approved', updated_at = ${now} WHERE id = ${claimId}
    `);
    ClaimRow? row = check fetchClaimRow(claimId);
    if row is () {
        return error("failed to load claim after approve");
    }
    return toExpenseClaim(row);
}

function rejectClaimRow(string claimId, string reason) returns ExpenseClaim|error {
    time:Utc now = time:utcNow();
    _ = check dbClient->execute(`
        UPDATE expense_claim SET status = 'rejected', rejection_reason = ${reason}, updated_at = ${now} WHERE id = ${claimId}
    `);
    ClaimRow? row = check fetchClaimRow(claimId);
    if row is () {
        return error("failed to load claim after reject");
    }
    return toExpenseClaim(row);
}

// Role-scoped, status-filtered, paginated listing. Role scoping follows
// security.md literally: employee -> own claims, manager -> direct reports'
// claims, finance -> approved claims only.
function listClaimsForCaller(Employee caller, string? statusFilter, int pageLimit, int pageOffset)
        returns record {| int count; ExpenseClaim[] data; |}|error {
    sql:ParameterizedQuery whereClause;
    if caller.role == "employee" {
        whereClause = `WHERE employee_id = ${caller.id}`;
    } else if caller.role == "manager" {
        string[] reportIds = check getDirectReportIds(caller.id);
        if reportIds.length() == 0 {
            return {count: 0, data: []};
        }
        whereClause = sql:queryConcat(`WHERE employee_id IN `, buildInClause(reportIds));
    } else if caller.role == "finance" {
        whereClause = `WHERE status = 'approved'`;
    } else {
        return error("unresolved role");
    }
    if statusFilter is string {
        whereClause = sql:queryConcat(whereClause, ` AND status = ${statusFilter}`);
    }

    sql:ParameterizedQuery countQuery = sql:queryConcat(`SELECT COUNT(*) AS total FROM expense_claim `, whereClause);
    record {| int total; |} countRow = check dbClient->queryRow(countQuery);

    sql:ParameterizedQuery dataQuery = sql:queryConcat(
        `SELECT `, `${CLAIM_ROW_COLUMNS}`, ` FROM expense_claim `, whereClause,
        ` ORDER BY created_at DESC LIMIT ${pageLimit} OFFSET ${pageOffset}`
    );
    stream<ClaimRow, sql:Error?> resultStream = dbClient->query(dataQuery);
    ExpenseClaim[] data = [];
    error? loopError = from ClaimRow claimRow in resultStream
        do {
            ExpenseClaim claim = check toExpenseClaim(claimRow);
            data.push(claim);
        };
    check resultStream.close();
    if loopError is error {
        return loopError;
    }
    return {count: countRow.total, data};
}

function buildInClause(string[] ids) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery clause = `(`;
    foreach int idx in 0 ..< ids.length() {
        if idx > 0 {
            clause = sql:queryConcat(clause, `, `);
        }
        clause = sql:queryConcat(clause, `${ids[idx]}`);
    }
    clause = sql:queryConcat(clause, `)`);
    return clause;
}

// Atomically marks approved+unexported claims exported: a single
// UPDATE ... RETURNING is one statement, so Postgres row locking prevents a
// concurrent export from ever picking up the same rows twice.
function exportApprovedClaims() returns ClaimRow[]|error {
    sql:ParameterizedQuery query = sql:queryConcat(
        `UPDATE expense_claim SET exported = TRUE, updated_at = ${time:utcNow()} `,
        `WHERE status = 'approved' AND exported = FALSE RETURNING `,
        `${CLAIM_ROW_COLUMNS}`
    );
    stream<ClaimRow, sql:Error?> resultStream = dbClient->query(query);
    ClaimRow[] rows = [];
    error? loopError = from ClaimRow claimRow in resultStream
        do {
            rows.push(claimRow);
        };
    check resultStream.close();
    if loopError is error {
        return loopError;
    }
    return rows;
}

function claimRowsToCsv(ClaimRow[] rows) returns string {
    string csv = "id,employeeId,category,amount,description,date,receiptUrl,status,createdAt,updatedAt\n";
    foreach ClaimRow row in rows {
        string receipt = row.receiptUrl is string ? <string>row.receiptUrl : "";
        csv = csv + string:'join(",",
            csvField(row.id), csvField(row.employeeId), csvField(row.category), row.amount.toString(),
            csvField(row.description), csvField(row.date), csvField(receipt), csvField(row.status),
            csvField(time:utcToString(row.createdAt)), csvField(time:utcToString(row.updatedAt))
        ) + "\n";
    }
    return csv;
}

function buildPageUri(string? statusFilter, int pageLimit, int pageOffset) returns string {
    string uri = "/expense-claims?limit=" + pageLimit.toString() + "&offset=" + pageOffset.toString();
    if statusFilter is string {
        uri = uri + "&status=" + statusFilter;
    }
    return uri;
}

function csvField(string value) returns string {
    string escaped = re `"`.replaceAll(value, "\"\"");
    return "\"" + escaped + "\"";
}
