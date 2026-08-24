import ballerina/http;

function badRequest(string description) returns ErrorBadRequest => {
    body: {code: 400, message: "Bad Request", description}
};

function forbidden(string description) returns ErrorForbidden => {
    body: {code: 403, message: "Forbidden", description}
};

function notFound(string description) returns ErrorNotFound => {
    body: {code: 404, message: "Not Found", description}
};

// The gateway always sets X-User-Id on a request it lets through, so its
// absence means the request did not come through the gateway (api-management).
// Some operations in the openapi contract do not enumerate '401' explicitly,
// but this check is a cross-cutting gateway-contract concern applied uniformly.
function unauthorized(string description) returns http:Unauthorized => {
    body: {code: 401, message: "Unauthorized", description}
};
