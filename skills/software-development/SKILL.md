---
name: software-development
description: Enforce language-agnostic software engineering principles — SOLID design, the Boy Scout principle, early returns, naming clarity, real types over primitives, value objects, exception handling, and encapsulation. Use for any code review or design discussion regardless of language, and especially when evaluating extensibility, maintainability, or coupling.
license: MIT
compatibility: opencode
metadata:
  audience: contributors
  focus: general-principles
---

## What I do

- Enforce SOLID design principles, with special emphasis on the Open/Closed principle.
- Enforce general engineering practices that apply regardless of language: the Boy Scout principle, early returns, naming clarity, real types over primitives, value objects, exception handling as control flow, and encapsulation via restrictive accessibility.
- Review code and designs for extensibility, coupling, and maintainability concerns that transcend any single language or framework.

## When to use me

Use this skill whenever creating, modifying, or reviewing code in any language — especially when the change touches extensibility (adding new variants/behaviors), class responsibilities, naming, or how errors/nulls are represented.

For C#/.NET-specific syntax and tooling conventions, see the `csharp-development` skill.

## SOLID principles

### Single Responsibility principle

A class should have one reason to change.

Rules:
- Each class owns one cohesive concern (e.g., persistence, validation, orchestration) — not several.
- Split classes that mix unrelated responsibilities (e.g., a service that both validates input and sends emails).
- Prefer small, composed classes over large ones that accumulate unrelated methods over time.

Do not:
- Split so aggressively that trivial, tightly-coupled logic ends up scattered across many single-method classes.

### Open/Closed principle (priority)

Types should be open for extension but closed for modification. This is a priority principle in this codebase — treat violations as non-negotiable findings in review, not stylistic preferences.

Rules:
- Prefer adding new behavior through new classes, interfaces, or strategy/decorator patterns rather than editing existing, working code paths.
- Avoid `switch`/`if-else` chains keyed on a type or enum that grow every time a new case is introduced; extract to polymorphism, a strategy map, or pattern matching over an abstraction instead.
- Depend on interfaces/abstractions at extension points so new implementations can be plugged in via dependency injection without touching consumers.
- Seal or otherwise close classes not designed for inheritance; expose extension only through explicit, intentional seams (interfaces, virtual members).
- Treat every recurring type-switch, or every repeated modification to the same method to support a new variant, as a hard signal to refactor toward an extension point.

Examples of Open/Closed compliant changes:
- Adding a new payment processor implementation instead of adding another branch to an existing payment type-switch.
- Introducing a new validator registered via dependency injection instead of editing a shared validation method.
- Adding a new discount strategy rather than adding another conditional branch to a pricing method that's already been modified for prior customer types.

Do not:
- Modify a stable, tested class's internals every time a new variant is needed — that's a signal to extract an abstraction.
- Over-engineer extension points speculatively; only introduce abstraction when a second variation actually exists or is imminent (avoid premature abstraction).

The Open/Closed principle applies where variation is expected or has already repeated; don't apply it preemptively to code with a single known shape. Because this is a priority principle, code review should flag Open/Closed violations even when the abstraction cost seems high — favor extension points over "just add another case" fixes.

### Liskov Substitution principle

Subtypes must be substitutable for their base types without altering expected behavior.

Rules:
- Overrides must honor the base contract: same or weaker preconditions, same or stronger postconditions.
- Do not opt out of part of an interface by throwing a "not implemented" error from an override — split the interface instead (see Interface Segregation).
- Do not narrow accepted input types or widen thrown exceptions/errors in a derived type in ways callers of the base type wouldn't expect.

Do not:
- Use type-checking on a base-typed parameter to special-case a subtype's behavior — that's a Liskov violation waiting to surface.

### Interface Segregation principle

Prefer small, client-specific interfaces over large, general-purpose ones.

Rules:
- Split interfaces so implementers only need to implement members they actually use.
- Avoid "fat" interfaces that force partial implementations or stub/no-op members.
- Group members by the consumer's use case, not by the implementer's convenience.

Do not:
- Fragment interfaces to the point where every consumer needs three or four interfaces injected for one cohesive capability.

### Dependency Inversion principle

High-level modules should depend on abstractions, not on low-level implementation details.

Rules:
- Depend on interfaces injected via dependency injection rather than concrete classes, especially across layer boundaries (e.g., application layer depending on an infrastructure interface, not a concrete data-access implementation directly).
- Define the abstraction in (or close to) the consuming layer, not the implementing layer.
- Avoid constructing concrete dependencies directly inside business logic; resolve them through the constructor or an equivalent composition seam.

Do not:
- Introduce an interface with exactly one implementation and no plausible second one "just in case" — that's premature abstraction, not Dependency Inversion.

## Boy Scout principle

Always leave the code better than you found it.

Rules:
- When touching existing code, improve it incrementally.
- Fix nearby code smells, outdated patterns, or technical debt when reasonable.
- Refactor for clarity, even if not directly related to your task.
- Update outdated comments and documentation.
- Remove unused code, imports, and variables.

Examples of Boy Scout improvements:
- Rename unclear variables while implementing a feature.
- Extract long methods into smaller, more focused methods.
- Add missing documentation to public APIs.
- Replace magic numbers with named constants.
- Update deprecated API usage to modern alternatives.

Do not:
- Make unrelated changes that obscure the main purpose of your work.
- Refactor entire modules when making a small fix.
- Introduce breaking changes without discussion.

The Boy Scout principle applies to every change, no matter how small.

## Early returns

Always prefer early returns to reduce nesting and improve readability. Exit methods as soon as conditions are met.

Rules:
- Return early when failure conditions are met.
- Avoid wrapping the entire method body in a conditional when the method ends with it.
- Invert conditions to enable early returns when the negative case should exit.
- Reduce indentation by handling edge cases first.

Bad example (nested conditional at the end, pseudocode):

```text
function validateResponse(response, expectedStatus, clientId):
    assertStatus(response, expectedStatus)
    if expectedStatus == OK:
        result = parse(response)
        assertNotNull(result)
        assertEquals(result.clientId, clientId)
```

Good example (early return):

```text
function validateResponse(response, expectedStatus, clientId):
    assertStatus(response, expectedStatus)
    if expectedStatus != OK:
        return
    result = parse(response)
    assertEquals(result?.clientId, clientId)
```

Benefits:
- Reduces nesting levels and improves readability.
- Makes the happy path clear by handling edge cases first.
- Easier to add additional logic without increasing complexity.
- Aligns with guard clause patterns.

More examples:

```text
// Bad: nested validation
function processOrder(order):
    if order != null:
        if order.isValid:
            if order.total > 0:
                // process order...

// Good: early returns
function processOrder(order):
    if order == null: return
    if not order.isValid: return
    if order.total <= 0: return
    // process order...
```

## No abbreviated names

Always use full, descriptive names for variables, parameters, and fields. Never shorten names for brevity.

Rules:
- Write out the full word or phrase that describes the concept.
- Do not use single-letter names, acronyms, or truncations except for universally understood loop counters (`i`, `j`) in trivial loops.
- This applies to parameters, locals, fields, and type parameters, in any language.

Bad examples:

```text
ct    (instead of cancellationToken)
hc    (instead of httpClient)
repo  (instead of orderRepository)
usr   (instead of username)
```

Good examples:

```text
cancellationToken
httpClient
orderRepository
username
```

## Meaningful names and small functions over comments

- Names must be precise enough that no comment is needed to explain intent.
- Keep functions small and single-level; extract steps instead of commenting them.
- A comment explaining *what* code does means: rename or extract instead.
- Comments are for *why* (rationale, tradeoffs), never *what*.

## Storage-agnostic naming for stores

Never name a class after the storage technology it uses. Classes should reflect the domain concept, not the underlying infrastructure.

Bad examples:

```text
SqlServerUserStore
ElasticsearchOrderRepository
MongoDbProductStore
RedisCacheStore
```

Good examples:

```text
UserStore
OrderRepository
ProductStore
CacheStore
```

If you need to differentiate implementations (e.g., for testing or multiple backends), put the technology name in the namespace/module/folder, not the class name.

Rules:
- The class name must describe only the domain concept (`UserStore`, `OrderRepository`).
- Storage technology (SQL Server, Elasticsearch, Redis, MongoDB) goes in the namespace or project folder, never the type name.
- Test doubles follow the same rule: `FakeUserStore`, `InMemoryOrderRepository`, `SpyCacheStore` — not `FakeSqlServerUserStore`.

## Use real types over primitives

Prefer purpose-built types over raw primitives when a richer type exists and accurately represents the value's intent. Avoid "primitive obsession."

Rules:
- Use a URI/URL type instead of a plain string for URLs and URIs.
- Use a GUID/UUID type instead of a string for identifiers that are GUIDs.
- Use strongly-typed ID types (e.g., `CustomerId`, `OrderId`) instead of a plain string or GUID when the domain has specific ID types.
- Use a date/time-with-offset type instead of a string for timestamps.
- Use a decimal type instead of a floating-point or string type for monetary values.
- Use enums instead of strings or integers for fixed sets of values.

Bad examples (pseudocode fields):

```text
webhookUrl: string          // should be a URI type
customerId: string          // should be a GUID or CustomerId
orderId: string             // should be a typed ID
createdAt: string           // should be a date/time-with-offset type
```

Good examples:

```text
webhookUrl: Uri
customerId: Guid
orderId: OrderId             // strongly-typed ID
createdAt: DateTimeOffset
```

When to keep a primitive:
- The value truly has no more specific type (e.g., a free-text name or description).
- Interoperability constraints require it (e.g., serialization boundaries where the richer type cannot be used).
- The value may contain formats not representable by the target type.

At serialization boundaries (e.g., request/response models), accept primitives if needed and map to real types in the domain model. Never propagate raw primitives deeper than the boundary layer.

## Value objects

Use value objects to encapsulate domain concepts with built-in validation, rather than passing raw primitives around. Prefer immutable value types with value-based equality (e.g., records, data classes, or equivalent) — they get equality, string representation, and deconstruction for free. If your language only offers reference types, implement equality and hashing manually.

### Requirements

- Support parsing consistently (e.g., a `Parse`/`TryParse` pair, or the language's idiomatic equivalent).
- Centralize all validation logic in a single private/internal helper.
- Call that validation helper from both the constructor (guards against invalid construction) and the parsing method (returns a failure instead of throwing).
- For non-value-equality types, override equality and hashing based on the underlying value.

### Example (pseudocode)

```text
type Email:
    value: string

    constructor(value):
        if not isValid(value): throw ArgumentError("Invalid email: " + value)
        this.value = value

    static parse(s):
        if not tryParse(s, out result): throw FormatError("Invalid email: " + s)
        return result

    static tryParse(s, out result):
        result = null
        if isNullOrWhitespace(s): return false
        if not isValid(s): return false
        result = new Email(s)
        return true

    private static isValid(value):
        return value.contains('@') and value.length <= 254
```

### When to use value objects

- The value has validation rules beyond a simple null/empty check.
- The same primitive appears in multiple places with the same validation (DRY the rules).
- You want to make illegal states unrepresentable.
- The type benefits from parsing logic that belongs with the data, not scattered across callers.

## Code smells

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Long Method** | > 10 lines | Extract Method |
| **Large Class** | > 50 lines, multiple responsibilities | Extract Class |
| **Long Parameter List** | > 3 parameters | Introduce Parameter Object |
| **Data Clumps** | Same group of variables appear together | Extract Class |

## Exception handling and control flow

Avoid using exceptions (or your language's equivalent panics/errors) for control flow. Prefer explicit return types that communicate success or failure.

Rules:
- Do not throw exceptions for expected conditions or business rule violations.
- Use result types (e.g., a `Result<T, TError>`/`Either`/`Option` type, or nullable types) to represent success/failure outcomes.
- Reserve exceptions for truly exceptional situations (infrastructure failures, unexpected states).
- Let unhandled exceptions flow up to a boundary layer (e.g., API middleware) for centralized handling.

Bad example (control flow via exceptions, pseudocode):

```text
function getOrder(orderId):
    order = repository.findById(orderId)
    if order == null:
        throw OrderNotFoundError(orderId)   // Bad: using exception for control flow
    return order
```

Good example (explicit return type):

```text
function getOrder(orderId):
    return repository.findById(orderId)     // Caller checks for null/absence

// Or with an explicit result type:
function getOrder(orderId):
    order = repository.findById(orderId)
    return order != null
        ? Result.success(order)
        : Result.failure("Order not found")
```

### Result type for flow control

If your language lacks a built-in result/either type, a small `Result<T, TError>` type can carry success/failure without throwing. Wrap it in a way idiomatic to your language (e.g., a `readonly struct` in C#, a sealed class hierarchy, or a discriminated union) exposing `IsSuccess`/`IsFailure`, the success value, and the error value.

## Accessibility — prefer the most restrictive modifier

Always declare classes, types, and members with the most restrictive access modifier possible, in any language that supports access modifiers.

Rules:
- Default to the most private/local visibility available. Widen only when genuinely required.
- Prefer package/module/assembly-level visibility over fully public for types that do not form part of a public API surface.
- If tests need access to non-public members, use your language's sanctioned mechanism for that (e.g., friend assemblies, `@VisibleForTesting`, internal test packages) — do not widen visibility to public just to make tests pass.

Bad example (pseudocode):

```text
public class OrderValidator { }   // Wrong — public when nothing outside the module needs it
```

Good example:

```text
internal class OrderValidator { }  // Correct — scoped to the module/package
```

## No regions or visual section separators

Do not use collapsible region directives or comment-based visual dividers to organize code, regardless of language.

Rules:
- Never use region/fold directives (e.g., `#region`/`#endregion`, `// region`/`// endregion`, or equivalents).
- Never use comment lines that act as visual dividers, such as repeated dashes, underscores, box-drawing characters, or other horizontal-rule-style comments.
- If code needs organization, refactor it into smaller classes or functions.
- Use proper structure and separation of concerns instead.

Why regions and visual separators are problematic:
- They hide code complexity instead of addressing it.
- They encourage large, unfocused classes or modules.
- They make code harder to navigate and understand.
- Modern IDEs provide better ways to collapse and navigate code without markup in the source.
- Comment separators are indistinguishable from real comments in diffs and reviews, adding noise without value.

If a file needs regions or visual separators to be "organized," it's a sign the unit is doing too much and should be split into smaller, focused pieces.

## Enforcement

- Use PR checklists that reference this skill.
- Enforce in code review, with particular attention to Open/Closed violations (recurring type-switches, repeated edits to the same method for new variants).
- Flag primitive obsession and exception-as-control-flow patterns during review.
