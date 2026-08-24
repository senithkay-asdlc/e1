import { useEffect, useState, type ReactNode } from "react";
import { BrowserRouter, Navigate, Route, Routes, useNavigate } from "react-router-dom";
import { currentUser, handleCallback, signIn } from "./auth";
import { Layout } from "./components/Layout";
import { MyClaims } from "./pages/MyClaims";
import { SubmitClaim } from "./pages/SubmitClaim";
import { ClaimDetail } from "./pages/ClaimDetail";
import { ReviewQueue } from "./pages/ReviewQueue";
import { ManagerClaimDetail } from "./pages/ManagerClaimDetail";
import { ApprovedClaims } from "./pages/ApprovedClaims";

function Callback() {
  const navigate = useNavigate();

  useEffect(() => {
    let cancelled = false;
    handleCallback()
      .catch(() => {
        // Nothing useful to show — either way land back on the app root,
        // where the auth gate decides whether a fresh sign-in is needed.
      })
      .finally(() => {
        if (!cancelled) navigate("/", { replace: true });
      });
    return () => {
      cancelled = true;
    };
  }, [navigate]);

  return <p>Signing in…</p>;
}

function AuthGate({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    async function check() {
      const user = await currentUser();
      if (cancelled) return;
      if (user) {
        setReady(true);
      } else {
        await signIn();
      }
    }
    check();
    return () => {
      cancelled = true;
    };
  }, []);

  if (!ready) return <p>Loading…</p>;
  return <>{children}</>;
}

function ProtectedApp() {
  return (
    <AuthGate>
      <Layout>
        <Routes>
          <Route path="/" element={<MyClaims />} />
          <Route path="/submit" element={<SubmitClaim />} />
          <Route path="/claims/:claimId" element={<ClaimDetail />} />
          <Route path="/review" element={<ReviewQueue />} />
          <Route path="/review/:claimId" element={<ManagerClaimDetail />} />
          <Route path="/approved" element={<ApprovedClaims />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Layout>
    </AuthGate>
  );
}

export function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/callback" element={<Callback />} />
        <Route path="/*" element={<ProtectedApp />} />
      </Routes>
    </BrowserRouter>
  );
}
