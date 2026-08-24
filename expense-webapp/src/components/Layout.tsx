import type { ReactNode } from "react";
import { NavLink } from "react-router-dom";
import { signOut } from "../auth";

const NAV_ITEMS = [
  { to: "/", label: "My Claims", end: true },
  { to: "/submit", label: "Submit Claim", end: true },
  { to: "/review", label: "Review Queue", end: true },
  { to: "/approved", label: "Approved Claims", end: true },
];

export function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="app-shell">
      <header className="navbar">
        <span className="navbar-brand">ExpenseHub</span>
        <button className="btn btn-link" onClick={() => signOut()}>
          Sign out
        </button>
      </header>
      <div className="app-body">
        <nav className="sidebar">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                "sidebar-link" + (isActive ? " sidebar-link-active" : "")
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <main className="app-content">{children}</main>
      </div>
    </div>
  );
}
