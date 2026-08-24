import ballerina/sql;

public type Employee record {|
    string id;
    string name;
    string email;
    string role;
    string? managerId;
|};

// Role resolution for this component looks up the Employee row whose id
// equals the gateway-injected X-User-Id (see specs/design/security.md) —
// deliberately NOT the generic X-User-Name directory-lookup pattern, because
// this design treats Employee.id as the Thunder subject id.
function getEmployeeById(string employeeId) returns Employee?|error {
    stream<Employee, sql:Error?> resultStream = dbClient->query(
        `SELECT id, name, email, role, manager_id AS "managerId" FROM employee WHERE id = ${employeeId}`
    );
    Employee? found = ();
    error? loopError = from Employee employeeRow in resultStream
        do {
            found = employeeRow;
        };
    check resultStream.close();
    if loopError is error {
        return loopError;
    }
    return found;
}

function getDirectReportIds(string managerId) returns string[]|error {
    stream<record {| string id; |}, sql:Error?> resultStream = dbClient->query(
        `SELECT id FROM employee WHERE manager_id = ${managerId}`
    );
    string[] ids = [];
    error? loopError = from record {| string id; |} reportRow in resultStream
        do {
            ids.push(reportRow.id);
        };
    check resultStream.close();
    if loopError is error {
        return loopError;
    }
    return ids;
}

function isDirectReportOf(string managerId, string employeeId) returns boolean|error {
    Employee? owner = check getEmployeeById(employeeId);
    if owner is () {
        return false;
    }
    string? ownerManagerId = owner.managerId;
    return ownerManagerId is string && ownerManagerId == managerId;
}
