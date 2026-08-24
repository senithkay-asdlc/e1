import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { expenseApi, userIdHeader } from "../api";
import type { components } from "../generated/expense-api";
import { StatusBadge } from "../components/StatusBadge";
import { ClaimForm, type ClaimFormValues } from "../components/ClaimForm";

type ExpenseClaim = components["schemas"]["ExpenseClaim"];

export function ClaimDetail() {
  const { claimId } = useParams<{ claimId: string }>();
  const navigate = useNavigate();
  const [claim, setClaim] = useState<ExpenseClaim | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

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

  async function handleResubmit(values: ClaimFormValues) {
    if (!claimId) return;
    setSubmitting(true);
    setFormError(null);
    const { data, error: apiError } = await expenseApi.PUT("/expense-claims/{claimId}", {
      params: { path: { claimId }, header: userIdHeader },
      body: values,
    });
    setSubmitting(false);
    if (apiError) {
      setFormError("Could not resubmit claim. Check the fields and try again.");
      return;
    }
    setClaim(data);
    navigate("/");
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
        Submitted {new Date(claim.createdAt).toLocaleDateString()} — Updated{" "}
        {new Date(claim.updatedAt).toLocaleString()}
      </p>
      <div className="card">
        <p>{claim.description}</p>
        {claim.receiptUrl && <p>Receipt: {claim.receiptUrl}</p>}
      </div>

      {claim.status === "rejected" && (
        <>
          <div className="card">
            <h2>Manager feedback</h2>
            <p>{claim.rejectionReason || "No reason provided."}</p>
          </div>
          <h2>Edit and resubmit</h2>
          <ClaimForm
            initial={claim}
            submitLabel="Resubmit claim"
            submitting={submitting}
            error={formError}
            onSubmit={handleResubmit}
          />
        </>
      )}
    </div>
  );
}
