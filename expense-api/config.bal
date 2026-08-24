import ballerina/os;

// Reads a platform-injected env var, falling back to a sensible local-dev
// default when it is unset — the service must start with no required
// env vars.
function getEnvOrDefault(string envVarName, string defaultValue) returns string {
    string envValue = os:getEnv(envVarName);
    if envValue == "" {
        return defaultValue;
    }
    return envValue;
}

configurable string dbHost = getEnvOrDefault("EXPENSE_DB_HOST", "localhost");
configurable string dbPort = getEnvOrDefault("EXPENSE_DB_PORT", "5432");
configurable string dbUser = getEnvOrDefault("EXPENSE_DB_USER", "postgres");
configurable string dbPassword = getEnvOrDefault("EXPENSE_DB_PASSWORD", "postgres");
configurable string dbName = getEnvOrDefault("EXPENSE_DB_DBNAME", "expense_claims");
