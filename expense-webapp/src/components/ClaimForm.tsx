import { useState, type FormEvent } from "react";
import type { components } from "../generated/expense-api";

type ExpenseClaimInput = components["schemas"]["ExpenseClaimInput"];
type Category = ExpenseClaimInput["category"];

const CATEGORIES: Category[] = ["Travel", "Meals", "Lodging", "Office Supplies", "Other"];

export type ClaimFormValues = ExpenseClaimInput;

const EMPTY: ClaimFormValues = {
  category: "Travel",
  amount: 0,
  date: "",
  description: "",
  receiptUrl: "",
};

export function ClaimForm({
  initial,
  submitLabel,
  onSubmit,
  onCancel,
  submitting,
  error,
}: {
  initial?: Partial<ClaimFormValues>;
  submitLabel: string;
  onSubmit: (values: ClaimFormValues) => void | Promise<void>;
  onCancel?: () => void;
  submitting?: boolean;
  error?: string | null;
}) {
  const [values, setValues] = useState<ClaimFormValues>({ ...EMPTY, ...initial });

  function update<K extends keyof ClaimFormValues>(key: K, value: ClaimFormValues[K]) {
    setValues((v) => ({ ...v, [key]: value }));
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const receiptUrl = values.receiptUrl?.trim();
    onSubmit({
      ...values,
      amount: Number(values.amount),
      receiptUrl: receiptUrl ? receiptUrl : null,
    });
  }

  return (
    <form className="claim-form" onSubmit={handleSubmit}>
      <div className="form-row">
        <label className="form-field">
          <span>Category</span>
          <select
            value={values.category}
            onChange={(e) => update("category", e.target.value as Category)}
          >
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </label>
        <label className="form-field">
          <span>Amount</span>
          <input
            type="number"
            step="0.01"
            min="0"
            required
            placeholder="e.g. 120.00"
            value={values.amount || ""}
            onChange={(e) => update("amount", e.target.valueAsNumber || 0)}
          />
        </label>
      </div>
      <label className="form-field">
        <span>Date incurred</span>
        <input
          type="date"
          required
          value={values.date}
          onChange={(e) => update("date", e.target.value)}
        />
      </label>
      <label className="form-field">
        <span>Description</span>
        <textarea
          required
          placeholder="What was this expense for?"
          value={values.description}
          onChange={(e) => update("description", e.target.value)}
        />
      </label>
      <label className="form-field">
        <span>Receipt URL (optional)</span>
        <input
          type="text"
          placeholder="Attach receipt (optional)"
          value={values.receiptUrl ?? ""}
          onChange={(e) => update("receiptUrl", e.target.value)}
        />
      </label>

      {error && <p className="error-text">{error}</p>}

      <div className="form-actions">
        {onCancel && (
          <button type="button" className="btn" onClick={onCancel}>
            Cancel
          </button>
        )}
        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting ? "Saving…" : submitLabel}
        </button>
      </div>
    </form>
  );
}
