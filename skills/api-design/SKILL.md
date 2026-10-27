---
name: api-design
description: Enforce API design standards for ASP.NET Core APIs including versioning strategy, status code declarations, TypedResults usage, ProblemDetails contracts, and response metadata.
license: Proprietary
compatibility: opencode
metadata:
  audience: contributors
  focus: openapi
---

## What I do

- Enforce true REST resource modelling and URL design.
- Enforce how API response types and status codes are declared and documented.
- Review controllers and endpoints for correct OpenAPI metadata.
- Provide compliant examples and direct fixes when documentation is missing or incorrect.

## When to use me

Use this skill whenever you create, modify, or review ASP.NET Core API endpoints — controllers or minimal APIs — where resource modelling, response types, status codes, or OpenAPI metadata are involved.

## True REST resource modelling

The URL identifies a **resource** — an addressable thing with its own identity and lifecycle. Properties of a resource are not resources.

### Properties belong on the resource

If a concept is an attribute of a resource, it is part of that resource's representation — not a sub-resource with its own URL.

```
// Wrong — writeback is a property of the group, not a resource
GET /groups/{groupId}/writeback

// Correct — the full group representation includes all its properties
GET /groups/{groupId}
```

The server may need extra roundtrips internally to populate certain fields. That is an implementation detail and must not leak into the API contract. The client always receives a complete, consistent representation.

Do not use query parameters (e.g. `?include=writeback`) to conditionally include or exclude properties for performance reasons. The server decides what a resource representation contains.

### When is a sub-resource appropriate?

Give something its own URL only when it has independent identity — it can be created, deleted, or linked to independently of the parent.

| Concept | Has independent identity? | Approach |
|---|---|---|
| Group writeback settings | No — part of the group | Property on `GET /groups/{groupId}` |
| Group members | Yes — members exist independently | Sub-resource: `GET /groups/{groupId}/members` |
| An invitation | Yes — has its own lifecycle | Sub-resource: `GET /invitations/{invitationId}` |

### Partial updates — PATCH over sub-resources

When a client needs to update a subset of a resource's properties, use `PATCH` on the resource — not a dedicated URL for the property.

```
// Wrong — treating a property as a writable sub-resource
PUT /groups/{groupId}/writeback

// Correct — partial update on the resource
PATCH /groups/{groupId}
Body: { "writeback": { "enabled": true } }
```

Use `PUT` when replacing the full resource representation. Use `PATCH` for partial updates.

## Primary approach: TypedResults

Use `TypedResults` with a `Results<T1, T2, ...>` return type. The return type itself becomes the OpenAPI contract at compile time — no additional attributes required for the common case.

```csharp
[HttpGet("{id}")]
public async Task<Results<Ok<OrderDto>, NotFound>> GetOrder(
    string id,
    CancellationToken cancellationToken)
{
    var order = await _orderService.GetOrderAsync(id, cancellationToken);

    return order is null
        ? TypedResults.NotFound()
        : TypedResults.Ok(order);
}
```

```csharp
[HttpPost]
public async Task<Results<Created<OrderDto>, BadRequest<ProblemDetails>>> CreateOrder(
    [FromBody] CreateOrderRequest request,
    CancellationToken cancellationToken)
{
    var result = await _orderService.CreateOrderAsync(request, cancellationToken);

    if (result.IsFailure)
    {
        return TypedResults.BadRequest(new ProblemDetails
        {
            Status = StatusCodes.Status400BadRequest,
            Title = "Invalid order",
            Detail = result.Error
        });
    }

    return TypedResults.Created($"/api/orders/{result.Value.Id}", result.Value);
}
```

Benefits:
- Compile-time guarantee that all declared response types are actually returned.
- OpenAPI metadata is generated automatically from the return type.
- Eliminates the need for `[ProducesResponseType]` attributes in most cases.
- Replaces the deprecated MVC API analyzers (`IncludeOpenAPIAnalyzers`, removed in .NET 10).

## Supplemental: [ProducesResponseType] for descriptions

Use `[ProducesResponseType]` only when you need to add a human-readable `Description` to a response, or when a status code cannot be expressed through the `Results<>` type (e.g. a status code returned by middleware).

```csharp
[HttpGet("{id}")]
[ProducesResponseType<OrderDto>(StatusCodes.Status200OK,
    Description = "The requested order.")]
[ProducesResponseType(StatusCodes.Status404NotFound,
    Description = "No order exists with the given ID.")]
[ProducesResponseType(StatusCodes.Status408RequestTimeout,
    Description = "The client disconnected before the response was sent.")]
public async Task<Results<Ok<OrderDto>, NotFound>> GetOrder(
    string id,
    CancellationToken cancellationToken)
{
    // ...
}
```

Rules:
- Use the generic form `[ProducesResponseType<T>]` when a response body type is involved.
- Use the non-generic form `[ProducesResponseType(statusCode)]` for bodyless responses.
- Always use `StatusCodes.Status*` constants — never raw integers.

## Do not use [SwaggerResponse]

`[SwaggerResponse]` is Swashbuckle-specific and not part of the ASP.NET Core standard. Do not use it.

Use `[ProducesResponseType]` for supplemental metadata instead.

## Standard status code catalogue

These are the agreed status codes for this codebase. Document only the codes an endpoint can actually return. Use only codes from this list unless a specific case requires otherwise, and document the reason in a comment.

### Success codes

| Code | Constant | Meaning | Methods |
|------|----------|---------|---------|
| 200 | `Status200OK` | OK - standard success response with a response body. | ALL |
| 201 | `Status201Created` | Created - successful entity creation. Return a `Location` header when the created resource has a stable URI. | POST, PUT |
| 202 | `Status202Accepted` | Accepted - request was accepted and will be processed asynchronously. | POST, PATCH, PUT, DELETE |
| 204 | `Status204NoContent` | No Content - successful request with no response body. | PUT, PATCH, DELETE |

### Redirection codes

| Code | Constant | Meaning | Methods |
|------|----------|---------|---------|
| 300 | `Status300MultipleChoices` | Multiple Choices - the target resource has more than one representation. | ALL |
| 301 | `Status301MovedPermanently` | Moved Permanently - the target resource has a new permanent URI. HTTP method can change. | ALL |
| 302 | `Status302Found` | Found - the target resource temporarily resides under a different URI. HTTP method can change. | ALL |
| 303 | `Status303SeeOther` | See Other - redirects the user agent to a different resource. | ALL |
| 304 | `Status304NotModified` | Not Modified - no need to transfer a representation because the client already has a valid representation. | GET, PATCH, HEAD |
| 307 | `Status307TemporaryRedirect` | Temporary Redirect - the target resource temporarily resides under a different URI. HTTP method must remain the same. | ALL |
| 308 | `Status308PermanentRedirect` | Permanent Redirect - the target resource has a new permanent URI. HTTP method must remain the same. | ALL |

### Client-side error codes

| Code | Constant | Meaning | Methods |
|------|----------|---------|---------|
| 400 | `Status400BadRequest` | Bad Request - generic or unknown client error. Use for malformed input, model validation failure, and business logic validation by default. Always return `ProblemDetails`. | ALL |
| 401 | `Status401Unauthorized` | Unauthorized - the user must log in or provide valid credentials. This often means unauthenticated. | ALL |
| 403 | `Status403Forbidden` | Forbidden - the user is authenticated but not authorized to use this resource. | ALL |
| 404 | `Status404NotFound` | Not Found - the requested resource does not exist. | PUT, GET, PATCH, DELETE, HEAD, OPTIONS |
| 405 | `Status405MethodNotAllowed` | Method Not Allowed - the HTTP method is not supported. The supported methods should be discoverable through `OPTIONS` or the `Allow` header. | ALL |
| 408 | `Status408RequestTimeout` | Request Timeout - the server timed out waiting for the request or the client disconnected/aborted before the response was sent. | ALL |
| 409 | `Status409Conflict` | Conflict - request cannot be completed due to a state conflict, e.g. duplicate resource or concurrent conflicting update. | GET, POST, PATCH, PUT, DELETE |
| 410 | `Status410Gone` | Gone - the resource intentionally existed before but no longer exists. | ALL |
| 412 | `Status412PreconditionFailed` | Precondition Failed - conditional request failed, e.g. `If-Match` for optimistic locking. | PUT, PATCH, DELETE |
| 415 | `Status415UnsupportedMediaType` | Unsupported Media Type - request body uses an unsupported or missing content type. | POST, PATCH, PUT, DELETE |
| 422 | `Status422UnprocessableEntity` | Unprocessable Entity - request body is well-formed but semantically erroneous. Always return `ProblemDetails`. | POST, PATCH, PUT |
| 423 | `Status423Locked` | Locked - pessimistic locking or processing state prevents the operation. | PUT, PATCH, DELETE |
| 429 | `Status429TooManyRequests` | Too Many Requests - client sent too many requests. Include rate-limit headers when available. | ALL |

### Server-side error codes

| Code | Constant | Meaning | Methods |
|------|----------|---------|---------|
| 500 | `Status500InternalServerError` | Internal Server Error - generic unexpected server execution problem. Client retry may be sensible depending on the operation. Always return `ProblemDetails`. | ALL |
| 501 | `Status501NotImplemented` | Not Implemented - server cannot fulfill the request, usually because the capability is not implemented yet. | ALL |
| 503 | `Status503ServiceUnavailable` | Service Unavailable - service or required downstream component is temporarily unavailable. Include `Retry-After` when possible. | ALL |

### 400 vs 422

- `400 Bad Request` - default client error for malformed input, model binding failure, generic validation failure, and business logic validation unless the API explicitly distinguishes semantic validation.
- `422 Unprocessable Entity` - use only when the endpoint intentionally separates structurally valid but semantically erroneous content from ordinary bad requests.

## ProblemDetails for all error responses

All 4xx and 5xx responses must follow [RFC 7807 Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc7807/).

Rules:
- Use content type `application/problem+json` for JSON error responses.
- Never return a plain string or custom error object for error responses.
- Use ASP.NET Core `ProblemDetails` or `ValidationProblemDetails` unless a more specific RFC 7807-compatible type is required.
- Populate `Status`, `Title`, and `Detail` at minimum.
- Set `Type` to a stable URI when the error represents a reusable problem type.
- Use `about:blank` or omit `Type` only when the status code alone fully describes the problem.
- Set `Instance` when the response should identify this specific occurrence, e.g. a support or trace URI.
- The `Status` member must match the actual HTTP response status code.
- `Title` should be stable for the problem type and should not contain occurrence-specific details.
- `Detail` should help the client understand or correct the problem; do not expose stack traces, SQL errors, secrets, internal hostnames, or implementation details.
- Use `Extensions` for machine-readable problem-specific data. Clients must not parse `Detail` for structured information.

RFC 7807 standard members:

| Member | Meaning | Rule |
|--------|---------|------|
| `type` | URI reference identifying the problem type. Defaults to `about:blank` when absent. | Prefer stable HTTPS documentation URIs for reusable domain/API errors. |
| `title` | Short human-readable summary of the problem type. | Keep stable across occurrences, except localization. |
| `status` | HTTP status code generated for this occurrence. | Must match the actual HTTP status code. |
| `detail` | Human-readable explanation specific to this occurrence. | Useful for humans, not machine parsing. |
| `instance` | URI reference identifying this specific occurrence. | Optional; useful for support, tracing, or audit correlation. |

Example:

```csharp
TypedResults.BadRequest(new ProblemDetails
{
    Type = "https://api.example.com/problems/validation-failed",
    Title = "Validation failed",
    Status = StatusCodes.Status400BadRequest,
    Detail = "The order total must be greater than zero.",
    Instance = "/orders/requests/01HX8Z7N8Y4Z8P5QJ9W1D3K4M2"
});
```

Example with extensions:

```csharp
var problemDetails = new ProblemDetails
{
    Type = "https://api.example.com/problems/invalid-state-transition",
    Title = "Invalid state transition",
    Status = StatusCodes.Status409Conflict,
    Detail = "The order cannot be shipped because it has not been paid.",
    Instance = $"/orders/{orderId}/ship"
};

problemDetails.Extensions["currentState"] = "PendingPayment";
problemDetails.Extensions["requiredState"] = "Paid";

return TypedResults.Conflict(problemDetails);
```

For 500 errors, use exception-handling middleware (e.g. `app.UseExceptionHandler`) to produce an RFC 7807-compatible `ProblemDetails` response centrally. Do not catch and return 500 manually in controllers.

## API versioning

Use this pattern when a new API version requires clients to migrate completely — a client is either on v1 or v2, never mixing endpoints across versions.

Three layers:

- `Shared/Controllers/Base<X>Controller` — `internal`, non-`virtual` methods, holds the real implementation.
- `v1/Controllers/<X>Controller` — `public`, redeclares every method and delegates to `base.X(...)`.
- `v2/Controllers/<X>Controller` — identical structure to v1 today; replace `base.X(...)` with new logic when v2 diverges. v1 is unaffected.

```csharp
// Shared/Controllers/BaseClientsController.cs
internal class BaseClientsController : ControllerBase
{
    protected async Task<Results<Ok<ClientDto>, NotFound>> GetClient(Guid clientId)
    {
        // real implementation
    }
}

// v1/Controllers/ClientsController.cs
[Route("v1/clients")]
public class ClientsController : BaseClientsController
{
    [HttpGet("{clientId}")]
    public Task<Results<Ok<ClientDto>, NotFound>> GetClient(Guid clientId)
        => base.GetClient(clientId);
}

// v2/Controllers/ClientsController.cs
[Route("v2/clients")]
public class ClientsController : BaseClientsController
{
    [HttpGet("{clientId}")]
    public Task<Results<Ok<ClientDto>, NotFound>> GetClient(Guid clientId)
        => base.GetClient(clientId);
}
```

Rules:
- Base methods are `internal` and non-`virtual` — versioned controllers cannot accidentally override them.
- Each versioned controller redeclares every method explicitly with its own route attributes.
- Do not use this pattern for additive changes to individual endpoints — only when the intent is a full client migration to the new version.

## Media type constants

Use `System.Net.Mime.MediaTypeNames` constants instead of raw strings for media types.

```csharp
// Wrong
[Produces("application/json")]
[Consumes("application/problem+json")]

// Correct
[Produces(MediaTypeNames.Application.Json)]
[Consumes(MediaTypeNames.Application.ProblemJson)]
```

This applies everywhere a media type string appears: `[Produces]`, `[Consumes]`, `Content-Type` headers set manually, and OpenAPI metadata.

## URL casing and formatting

Route templates must use lowercase kebab-case segments — no PascalCase, camelCase, or underscores.

```csharp
// Wrong
[Route("api/OrderItems")]
[HttpGet("{orderId}")]

// Correct
[Route("api/order-items")]
[HttpGet("{orderId}")]
```

Enforce globally via `Program.cs`:

```csharp
builder.Services.Configure<RouteOptions>(static options =>
{
    options.LowercaseUrls = true;
    options.LowercaseQueryStrings = true;
});
```

Enum values serialized in API responses and requests must also use lowercase kebab-case:

```csharp
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(
        new JsonStringEnumConverter(JsonNamingPolicy.KebabCaseLower));
});
```

This ensures `OrderStatus.PendingApproval` serializes as `"pending-approval"` rather than `"PendingApproval"` or `"PENDING_APPROVAL"`.

## Enforcement

- Use PR checklists that reference this skill.
- Enforce in code review.
- Prefer `TypedResults` return types as the primary documentation mechanism.
- Flag any use of `[SwaggerResponse]` as a violation.
- Flag raw integer status codes — always use `StatusCodes.Status*` constants.
