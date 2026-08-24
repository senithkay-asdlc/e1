// Expense Claims — three roles, six screens, desktop

screen MyClaims "Employee tracks the status of their own submitted expense claims"
  navbar "ExpenseHub"
  sidebar "My Claims -> MyClaims | Submit Claim -> SubmitClaim | Settings"
  row
    heading "My Claims"
    right
    button "New claim" primary -> SubmitClaim
  row
    card "Pending | 2 | awaiting manager review"
    card "Approved | 5 | ready for payroll"
    card "Rejected | 1 | needs your attention"
  tabs "All | Pending | Approved | Rejected"
  table "Date | Category | Amount | Status | Updated" -> ClaimDetail
    row "Aug 20 | Travel | $340.00 | Pending | 2h ago"
    row "Aug 18 | Meals | $42.50 | Approved | 1d ago"
    row "Aug 12 | Office Supplies | $75.00 | Rejected | 3d ago"

screen SubmitClaim "An employee submits a new expense claim"
  navbar "ExpenseHub"
  sidebar "My Claims -> MyClaims | Submit Claim -> SubmitClaim | Settings"
  breadcrumb "My Claims / New claim"
  heading "Submit Expense Claim"
  row
    select "Category: Travel"
    input "Amount — e.g. 120.00"
  input "Date incurred"
  textarea "What was this expense for?"
  input "Attach receipt (optional)"
  row
    right
    button "Cancel"
    button "Submit claim" primary -> MyClaims

screen ClaimDetail "An employee views one claim's status and, if rejected, edits and resubmits it"
  navbar "ExpenseHub"
  sidebar "My Claims -> MyClaims | Submit Claim -> SubmitClaim | Settings"
  breadcrumb "My Claims / Aug 12 Office Supplies"
  row
    heading "Office Supplies — $75.00"
    badge "Rejected" danger
  text "Submitted Aug 12 — Updated 3d ago"
  card "Manager feedback"
    text "R. Osei: missing an itemized receipt — please attach one and resubmit."
  heading "Edit and resubmit"
  row
    select "Category: Office Supplies"
    input "Amount — 75.00"
  input "Date incurred"
  textarea "What was this expense for?"
  input "Attach receipt (optional)"
  row
    right
    button "Resubmit claim" primary -> MyClaims

screen ReviewQueue "Manager reviews and approves or rejects claims from direct reports"
  navbar "ExpenseHub"
  sidebar "Review Queue -> ReviewQueue | Settings"
  row
    heading "Review Queue"
    right
    select "Report: All direct reports"
  row
    card "Pending review | 4 | across 3 direct reports"
    card "Approved this month | 12 | totaling $2,140"
  table "Employee | Date | Category | Amount | Status" -> ManagerClaimDetail
    row "A. Chen | Aug 20 | Travel | $340.00 | Pending"
    row "M. Diaz | Aug 19 | Meals | $28.00 | Pending"
    row "K. Smith | Aug 17 | Lodging | $210.00 | Pending"

screen ManagerClaimDetail "Manager approves or rejects one claim with a reason"
  navbar "ExpenseHub"
  sidebar "Review Queue -> ReviewQueue | Settings"
  breadcrumb "Review Queue / A. Chen — Travel"
  row
    heading "Travel — $340.00"
    badge "Pending" info
  text "Submitted by A. Chen — Aug 20"
  split 60/40
    left
      heading "Claim details"
      text "Round-trip flight for client visit in Chicago."
      text "Receipt attached: flight-receipt.pdf"
    right
      card "Decision"
        textarea "Reason (required if rejecting)"
        row
          button "Reject" danger
          button "Approve" primary -> ReviewQueue

screen ApprovedClaims "Finance views approved claims and exports them to payroll"
  navbar "ExpenseHub"
  sidebar "Approved Claims -> ApprovedClaims | Settings"
  row
    heading "Approved Claims"
    right
    button "Export to CSV" primary
  row
    card "Ready to export | 9 | totaling $1,860"
    card "Already exported | 34 | this quarter"
  table "Employee | Date | Category | Amount | Exported"
    row "A. Chen | Aug 15 | Meals | $28.00 | No"
    row "M. Diaz | Aug 10 | Lodging | $210.00 | No"
    row "K. Smith | Aug 2 | Travel | $340.00 | Yes"

flow "Submit and track a claim"
  role "Employee"
  description "An employee submits a new claim and later resubmits a rejected one"
  MyClaims
  SubmitClaim
  ClaimDetail

flow "Approve or reject claims"
  role "Manager"
  description "A manager reviews their direct reports' pending claims and decides each one"
  ReviewQueue
  ManagerClaimDetail

flow "Export approved claims"
  role "Finance"
  description "Finance reviews approved claims and exports them to a CSV for payroll"
  ApprovedClaims
