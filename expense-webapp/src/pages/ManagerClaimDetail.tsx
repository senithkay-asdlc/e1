import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { expenseApi, userIdHeader } from "../api";
import type { components } from "../generated/expense-api";
import { StatusBadge } from "../components/StatusBadge";

type ExpenseClaim = components["schemas"]["ExpenseClaim"];

export function ManagerClaimDetail() {
  const { claimId } = useParams<{ claimId: string }>();
  const navigate = useNavigate();
  const [claim, setClaim] = useState<ExpenseClaim | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [reason, setReason] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!claimId) return;
    let cancelled = false;
    async function load() {
      const { data, error: apiError } = await expenseApi.GET("/expense-claims/{claimId}", {
        params: { path: { claimId: claimId! }, header: userIdHeader },
      });
      if (cancelled) return;
      if (apiError) {
        setError("Could not load this claim.");
        return;
      }
      setClaim(data);
    }
    load();
    return () => {
      cancelled = true;
    };
  }, [claimId]);

  async function approve() {
    if (!claimId) return;
    setSubmitting(true);
    setActionError(null);
    const { error: apiError } = await expenseApi.POST("/expense-claims/{claimId}/approve", {
      params: { path: { claimId }, header: userIdHeader },
    });
    setSubmitting(false);
    if (apiError) {
      setActionError("Could not approve this claim.");
      return;
    }
    navigate("/review");
  }

  async function reject() {
    if (!claimId) return;
    if (!reason.trim()) {
      setActionError("A reason is required to reject a claim.");
      return;
    }
    setSubmitting(true);
    setActionError(null);
    const { error: apiError } = await expenseApi.POST("/expense-claims/{claimId}/reject", {
      params: { path: { claimId }, header: userIdHeader },
      body: { reason },
    });
    setSubmitting(false);
    if (apiError) {
      setActionError("Could not reject this claim.");
      return;
    }
    navigate("/review");
  }

  if (error) return <p className="error-text">{error}</p>;
  if (!claim) return <p>Loading…</p>;

  return (
    <div>
      <div className="page-header">
        <h1>
          {claim.category} — ${claim.amount.toFixed(2)}
        </h1>
        <StatusBadge status={claim.status} />
      </div>
      <p>
        Submitted by {claim.employeeId} — {claim.date}
      </p>

      <div className="card">
        <h2>Claim details</h2>
        <p>{claim.description}</p>
        {claim.receiptUrl && <p>Receipt attached: {claim.receiptUrl}</p>}
      </div>

      {claim.status === "pending" ? (
        <div className="card">
          <h2>Decision</h2>
          <label className="form-field">
            <span>Reason (required if rejecting)</span>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Why is this claim being rejected?"
            />
          </label>
          {actionError && <p className="error-text">{actionError}</p>}
          <div className="form-actions">
            <button type="button" className="btn btn-danger" disabled={submitting} onClick={reject}>
              Reject
            </button>
            <button type="button" className="btn btn-primary" disabled={submitting} onClick={approve}>
              Approve
            </button>
          </div>
        </div>
      ) : (
        <p>This claim has already been {claim.status}.</p>
      )}
    </div>
  );
}
