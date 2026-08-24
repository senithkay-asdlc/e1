import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { expenseApi, userIdHeader } from "../api";
import type { components } from "../generated/expense-api";
import { StatusBadge } from "../components/StatusBadge";

type ExpenseClaim = components["schemas"]["ExpenseClaim"];

export function ReviewQueue() {
  const [claims, setClaims] = useState<ExpenseClaim[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      const { data, error: apiError } = await expenseApi.GET("/expense-claims", {
        params: { header: userIdHeader, query: { status: "pending" } },
      });
      if (cancelled) return;
      if (apiError) {
        setError("Could not load the review queue.");
        return;
      }
      setClaims(data.data);
    }
    load();
    return () => {
      cancelled = true;
    };
  }, []);

  const totalAmount = (claims ?? []).reduce((sum, c) => sum + c.amount, 0);

  return (
    <div>
      <div className="page-header">
        <h1>Review Queue</h1>
      </div>

      <div className="card-row">
        <div className="stat-card">
          <div className="stat-label">Pending review</div>
          <div className="stat-value">{claims?.length ?? 0}</div>
          <div className="stat-caption">from your direct reports</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Total pending</div>
          <div className="stat-value">${totalAmount.toFixed(2)}</div>
          <div className="stat-caption">awaiting your decision</div>
        </div>
      </div>

      {error && <p className="error-text">{error}</p>}
      {!error && claims === null && <p>Loading…</p>}
      {!error && claims !== null && claims.length === 0 && <p>No pending claims.</p>}
      {!error && claims && claims.length > 0 && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Employee</th>
              <th>Date</th>
              <th>Category</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {claims.map((c) => (
              <tr key={c.id}>
                <td>
                  <Link to={`/review/${c.id}`}>{c.employeeId}</Link>
                </td>
                <td>{c.date}</td>
                <td>{c.category}</td>
                <td>${c.amount.toFixed(2)}</td>
                <td>
                  <StatusBadge status={c.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
