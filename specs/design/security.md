# Expense Claims — Security

## Roles → permissions

A Manager is also an Employee and keeps that role's permissions for their own claims (they cannot approve their own claim).

## Authentication (Thunder)

- Shared dependency name: `user-auth` (declared identically on `expense-webapp` and `expense-api`).
- Scopes: `openid profile email` (default).
- `expense-webapp` is the SPA side of sign-in: it runs the OIDC + PKCE flow and attaches the resulting token to every call to `expense-api`.
- `expense-api` is the protected backend: every endpoint other than health checks requires a valid token, validated at the gateway.

## Role resolution

- The gateway validates the caller's Thunder token and injects the caller's identity (`X-User-Id`) into every request reaching `expense-api`.
- `expense-api` looks up the caller's `Employee` record by that identity to resolve their `role` (`employee` | `manager` | `finance`) and, for managers, their direct reports (via `managerId`).
- An employee record with no resolvable role, or a caller whose identity matches no `Employee` record, is denied (403) — deny by default.
- A manager may only act on claims whose `employeeId` reports to them; an employee may only view/edit their own claims; finance may only read approved claims and trigger export.