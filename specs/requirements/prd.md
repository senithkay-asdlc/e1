# Expense Claims — PRD

## Problem Statement

Employees pay for business expenses out of pocket and need a reliable way to get reimbursed. Today, tracking who submitted what, whether a manager has signed off, and which claims are ready to be paid is scattered across emails, spreadsheets and paper trails — costing managers time chasing details and finance time reconciling what's actually approved before it reaches payroll.

## Solution

A system where employees submit expense claims online, their manager reviews and approves or rejects them, and finance exports the approved claims into a file ready for the payroll run — giving every claim a clear, traceable path from submission to payment.

## Actors

- **Employee** — submits expense claims, tracks their status, and edits/resubmits claims a manager rejects.
- **Manager** — reviews expense claims submitted by their direct reports and approves or rejects each one.
- **Finance** — views all approved claims and exports them to a file for payroll processing.

## User Stories

1. As an Employee, I want to submit an expense claim with an amount, category, description and date, so that I can request reimbursement for a business expense.
2. As an Employee, I want to attach a receipt to my claim, so that I have supporting documentation on hand if it's needed.
3. As an Employee, I want to view the status of my submitted claims (pending, approved, rejected), so that I know where each one stands.
4. As an Employee, I want to edit and resubmit a claim my manager rejected, so that I can fix the issue and get it approved.
5. As a Manager, I want to see a queue of expense claims submitted by my direct reports, so that I know what's waiting on my review.
6. As a Manager, I want to approve a claim, so that it becomes eligible for payroll export.
7. As a Manager, I want to reject a claim with a reason, so that the employee knows what to correct.
8. As Finance, I want to view all approved claims, so that I can see what's ready to be paid out.
9. As Finance, I want to export approved claims to a downloadable file (CSV), so that I can bring them into the payroll system.
10. As Finance, I want exported claims to be marked as exported, so that the same claim is never exported twice.

## Product Decisions

- Sign-in is via SSO through Thunder, the platform identity provider *(organization default)*.
- The web app is built as a TypeScript + React single-page app; backend services are built in Ballerina *(organization default)*.
- Approval is single-level: each employee has one designated manager who approves or rejects their claims directly — no escalation chain by amount.
- A rejected claim returns to the employee, who can edit it and resubmit for another round of review.
- Receipt attachment is optional, not required to submit a claim.
- Finance's export produces a downloadable CSV file for manual import into payroll; there is no live integration with a specific payroll provider in this version.
- Each employee has one designated manager, recorded on the employee's profile; maintaining that assignment is a setup detail and is not itself a user-facing story in this version. *assumed*
- Claims are tracked in a single default currency; multi-currency support is not handled in this version. *assumed*
- Expense categories are a fixed predefined list: Travel, Meals, Lodging, Office Supplies, Other.
- No email/notification alerts are sent on status changes in this version; actors check status by visiting the app.

## Out of Scope

- Multi-level or amount-based approval escalation.
- Direct API integration with a specific payroll provider.
- Multi-currency claims.
- Email or push notifications on claim status changes.
- Employee/manager directory management (org chart, hires, transfers) as a feature of this system.

## Open Questions

1. Should there be a per-claim or per-period spending limit that triggers extra scrutiny?

## Further Notes

None.