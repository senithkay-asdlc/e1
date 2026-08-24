import createClient, { type Middleware } from "openapi-fetch";
import type { paths } from "./generated/expense-api";
import { getAccessToken, signIn } from "./auth";

// X-User-Id is documented on expense-api as required-but-injected: the
// gateway sets it from the caller's validated token and overwrites whatever a
// client sends. We satisfy the generated type with a placeholder; the real
// value never comes from the browser.
const INJECTED_USER_ID_PLACEHOLDER = "gateway-injected";

const authMiddleware: Middleware = {
  async onRequest({ request }) {
    const token = await getAccessToken();
    if (token) {
      request.headers.set("Authorization", `Bearer ${token}`);
    }
    return request;
  },
  async onResponse({ response }) {
    if (response.status === 401) {
      await signIn();
    }
    return response;
  },
};

export const expenseApi = createClient<paths>({ baseUrl: "/api" });
expenseApi.use(authMiddleware);

export const userIdHeader = { "X-User-Id": INJECTED_USER_ID_PLACEHOLDER };
