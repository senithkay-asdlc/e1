type Status = "pending" | "approved" | "rejected";

const VARIANT: Record<Status, string> = {
  pending: "badge-info",
  approved: "badge-success",
  rejected: "badge-danger",
};

const LABEL: Record<Status, string> = {
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
};

export function StatusBadge({ status }: { status: Status }) {
  return <span className={`badge ${VARIANT[status]}`}>{LABEL[status]}</span>;
}
