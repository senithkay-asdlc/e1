import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { expenseApi, userIdHeader } from "../api";
import type { components } from "../generated/expense-api";
import { StatusBadge } from "../components/StatusBadge";

type ExpenseClaim = components["schemas"]["ExpenseClaim"];
type TabKey = "all" | "pending" | "approved" | "rejected";

const TABS: TabKey[] = ["all", "pending", "approved", "rejected"];

export function MyClaims() {
  const [claims, setClaims] = useState<ExpenseClaim[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<TabKey>("all");

  useEffect(() => {
    let cancelled = false;
    async function load() {
      const { data, error: apiError } = await expenseApi.GET("/expense-claims", {
        params: { header: userIdHeader },
      });
      if (cancelled) return;
      if (apiError) {
        setError("Could not load your claims.");
        return;
      }
      setClaims(data.data);
    }
    load();
    return () => {
      cancelled = true;
    };
  }, []);

  const counts = useMemo(() => {
    const list = claims ?? [];
    return {
      pending: list.filter((c) => c.status === "pending").length,
      approved: list.filter((c) => c.status === "approved").length,
      rejected: list.filter((c) => c.status === "rejected").length,
    };
  }, [claims]);

  const visible = useMemo(() => {
    const list = claims ?? [];
    if (tab === "all") return list;
    return list.filter((c) => c.status === tab);
  }, [claims, tab]);

  return (
    <div>
      <div className="page-header">
        <h1>My Claims</h1>
        <Link to="/submit" className="btn btn-primary">
          New claim
        </Link>
      </div>

      <div className="card-row">
        <div className="stat-card">
          <div className="stat-label">Pending</div>
          <div className="stat-value">{counts.pending}</div>
          <div className="stat-caption">awaiting manager review</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Approved</div>
          <div className="stat-value">{counts.approved}</div>
          <div className="stat-caption">ready for payroll</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Rejected</div>
          <div className="stat-value">{counts.rejected}</div>
          <div className="stat-caption">needs your attention</div>
        </div>
      </div>

      <div className="tabs">
        {TABS.map((t) => (
          <button
            key={t}
            className={"tab" + (t === tab ? " tab-active" : "")}
            onClick={() => setTab(t)}
          >
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {error && <p className="error-text">{error}</p>}
      {!error && claims === null && <p>Loading…</p>}
      {!error && claims !== null && visible.length === 0 && <p>No claims here yet.</p>}
      {!error && visible.length > 0 && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Category</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Updated</th>
            </tr>
          </thead>
          <tbody>
            {visible.map((c) => (
              <tr key={c.id}>
                <td>
                  <Link to={`/claims/${c.id}`}>{c.date}</Link>
                </td>
                <td>{c.category}</td>
                <td>${c.amount.toFixed(2)}</td>
                <td>
                  <StatusBadge status={c.status} />
                </td>
                <td>{new Date(c.updatedAt).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
