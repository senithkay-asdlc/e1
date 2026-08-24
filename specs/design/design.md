# Expense Claims — Design

Employees submit expense claims through a single-page web app; managers review and approve or reject their direct reports' claims; finance exports the approved claims to a CSV file for the payroll run. All claim state and business logic live in one Ballerina service backed by a database; sign-in for all three actors runs through Thunder SSO.

## Context (C1)

```mermaid
graph TD
  Employee((Employee))
  Manager((Manager))
  Finance((Finance))
  System[Expense Claims System]
  Thunder[Thunder Auth]

  Employee -->|submits & tracks claims| System
  Manager -->|reviews & approves/rejects| System
  Finance -->|views & exports approved claims| System
  System -->|sign-in| Thunder
```

## Domain model (ER)

```mermaid
erDiagram
  EMPLOYEE ||--o{ EXPENSE_CLAIM : submits
  EMPLOYEE ||--o{ EMPLOYEE : manages

  EMPLOYEE {
    string id
    string name
    string email
    string role
    string managerId
  }

  EXPENSE_CLAIM {
    string id
    string employeeId
    string category
    number amount
    string description
    string date
    string status
    string receiptUrl
    string rejectionReason
    boolean exported
    string createdAt
    string updatedAt
  }
```

`EMPLOYEE.role` is one of `employee`, `manager`, `finance` (a manager is also an employee who can submit their own claims). `EXPENSE_CLAIM.status` is one of `pending`, `approved`, `rejected`. `category` is one of the fixed list: Travel, Meals, Lodging, Office Supplies, Other.

## Key flows

### Submit and approve

```mermaid
sequenceDiagram
  participant E as Employee
  participant W as expense-webapp
  participant A as expense-api
  participant M as Manager

  E->>W: Fill claim form (amount, category, description, date, receipt)
  W->>A: POST /expense-claims
  A-->>W: 201 Created (status: pending)
  M->>W: Open review queue
  W->>A: GET /expense-claims?status=pending
  A-->>W: List of direct reports' pending claims
  M->>W: Approve claim
  W->>A: POST /expense-claims/{claimId}/approve
  A-->>W: 200 OK (status: approved)
```

### Reject and resubmit

```mermaid
sequenceDiagram
  participant M as Manager
  participant W as expense-webapp
  participant A as expense-api
  participant E as Employee

  M->>W: Reject claim with reason
  W->>A: POST /expense-claims/{claimId}/reject
  A-->>W: 200 OK (status: rejected)
  E->>W: View rejected claim + reason
  E->>W: Edit claim details
  W->>A: PUT /expense-claims/{claimId}
  A-->>W: 200 OK (status: pending)
```

### Finance export

```mermaid
sequenceDiagram
  participant F as Finance
  participant W as expense-webapp
  participant A as expense-api

  F->>W: Open approved claims list
  W->>A: GET /expense-claims?status=approved
  A-->>W: List of approved claims
  F->>W: Export to CSV
  W->>A: GET /expense-claims/export
  A-->>W: CSV file (approved, unexported claims)
  A->>A: Mark exported claims as exported
```