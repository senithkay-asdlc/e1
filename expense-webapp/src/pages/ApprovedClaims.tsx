import { useCallback, useEffect, useState } from "react";
import { expenseApi, userIdHeader } from "../api";
import { getAccessToken, signIn } from "../auth";
import type { components } from "../generated/expense-api";

type ExpenseClaim = components["schemas"]["ExpenseClaim"];

export function ApprovedClaims() {
  const [claims, setClaims] = useState<ExpenseClaim[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const { data, error: apiError } = await expenseApi.GET("/expense-claims", {
      params: { header: userIdHeader, query: { status: "approved" } },
    });
    if (apiError) {
      setError("Could not load approved claims.");
      return;
    }
    setError(null);
    setClaims(data.data);
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const notExported = (claims ?? []).filter((c) => !c.exported);
  const exportedCount = (claims ?? []).filter((c) => c.exported).length;
  const readyTotal = notExported.reduce((sum, c) => sum + c.amount, 0);

  // The export endpoint returns a CSV file, not JSON, so it is fetched
  // directly (same pattern as the thunder-authentication skill's raw-fetch
  // example) rather than through the JSON-typed openapi-fetch client.
  async function handleExport() {
    setExporting(true);
    setExportError(null);
    try {
      const token = await getAccessToken();
      const res = await fetch("/api/expense-claims/export", {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (res.status === 401) {
        await signIn();
        return;
      }
      if (!res.ok) {
        setExportError("Could not export claims.");
        return;
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `expense-claims-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      await load();
    } finally {
      setExporting(false);
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1>Approved Claims</h1>
        <button className="btn btn-primary" onClick={handleExport} disabled={exporting}>
          {exporting ? "Exporting…" : "Export to CSV"}
        </button>
      </div>

      <div className="card-row">
        <div className="stat-card">
          <div className="stat-label">Ready to export</div>
          <div className="stat-value">{notExported.length}</div>
          <div className="stat-caption">totaling ${readyTotal.toFixed(2)}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Already exported</div>
          <div className="stat-value">{exportedCount}</div>
          <div className="stat-caption">sent to payroll</div>
        </div>
      </div>

      {exportError && <p className="error-text">{exportError}</p>}
      {error && <p className="error-text">{error}</p>}
      {!error && claims === null && <p>Loading…</p>}
      {!error && claims !== null && claims.length === 0 && <p>No approved claims yet.</p>}
      {!error && claims && claims.length > 0 && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Employee</th>
              <th>Date</th>
              <th>Category</th>
              <th>Amount</th>
              <th>Exported</th>
            </tr>
          </thead>
          <tbody>
            {claims.map((c) => (
              <tr key={c.id}>
                <td>{c.employeeId}</td>
                <td>{c.date}</td>
                <td>{c.category}</td>
                <td>${c.amount.toFixed(2)}</td>
                <td>{c.exported ? "Yes" : "No"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
