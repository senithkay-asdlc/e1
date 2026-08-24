import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { expenseApi, userIdHeader } from "../api";
import { ClaimForm, type ClaimFormValues } from "../components/ClaimForm";

export function SubmitClaim() {
  const navigate = useNavigate();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(values: ClaimFormValues) {
    setSubmitting(true);
    setError(null);
    const { error: apiError } = await expenseApi.POST("/expense-claims", {
      params: { header: userIdHeader },
      body: values,
    });
    setSubmitting(false);
    if (apiError) {
      setError("Could not submit claim. Check the fields and try again.");
      return;
    }
    navigate("/");
  }

  return (
    <div>
      <div className="page-header">
        <h1>Submit Expense Claim</h1>
      </div>
      <ClaimForm
        submitLabel="Submit claim"
        submitting={submitting}
        error={error}
        onCancel={() => navigate("/")}
        onSubmit={handleSubmit}
      />
    </div>
  );
}
