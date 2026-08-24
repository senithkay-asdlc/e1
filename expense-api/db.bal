import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

final postgresql:Client dbClient = check initDbClient();

function initDbClient() returns postgresql:Client|error {
    int dbPortNumber = check int:fromString(dbPort);
    return new (
        host = dbHost,
        port = dbPortNumber,
        username = dbUser,
        password = dbPassword,
        database = dbName
    );
}

function init() returns error? {
    check createSchema();
    check seedEmployees();
}

function createSchema() returns error? {
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS employee (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            role TEXT NOT NULL,
            manager_id TEXT NULL
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS expense_claim (
            id TEXT PRIMARY KEY,
            employee_id TEXT NOT NULL,
            category TEXT NOT NULL,
            amount NUMERIC NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL,
            status TEXT NOT NULL,
            receipt_url TEXT NULL,
            rejection_reason TEXT NULL,
            exported BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL,
            updated_at TIMESTAMPTZ NOT NULL
        )
    `);
}

// Employee/manager directory management has no API in this system (PRD), but
// Employee rows must pre-exist for role resolution to succeed at all, so a
// small fixed roster is seeded idempotently at startup.
type SeedEmployee record {|
    string id;
    string name;
    string email;
    string role;
    string? managerId;
|};

function seedEmployees() returns error? {
    SeedEmployee[] sampleEmployees = [
        {id: "emp-manager-1", name: "Morgan Manager", email: "morgan.manager@example.com", role: "manager", managerId: ()},
        {id: "emp-finance-1", name: "Finn Finance", email: "finn.finance@example.com", role: "finance", managerId: ()},
        {id: "emp-report-1", name: "Riley Report", email: "riley.report@example.com", role: "employee", managerId: "emp-manager-1"},
        {id: "emp-report-2", name: "Reese Report", email: "reese.report@example.com", role: "employee", managerId: "emp-manager-1"}
    ];
    foreach SeedEmployee employeeRecord in sampleEmployees {
        _ = check dbClient->execute(`
            INSERT INTO employee (id, name, email, role, manager_id)
            VALUES (${employeeRecord.id}, ${employeeRecord.name}, ${employeeRecord.email}, ${employeeRecord.role}, ${employeeRecord.managerId})
            ON CONFLICT (id) DO NOTHING
        `);
    }
}
