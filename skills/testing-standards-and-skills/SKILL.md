---
name: testing-standards-and-skills
description: Enforce repository unit test standards for xUnit, Shouldly, naming, structure, and embedded test resources.
license: Proprietary
compatibility: opencode
metadata:
  audience: contributors
  focus: unit-testing
---

## What I do
- Enforce mandatory unit test conventions in this repository.
- Review new and modified tests for style, structure, and organization.
- Provide compliant examples and direct fixes when tests violate standards.

## When to use me
Use this skill whenever you create, modify, or review unit tests in this repository.

## Required testing framework
- Use `xUnit`.
- Use `[Fact]` for test cases.
- Use `async Task` for async behavior when needed.
- Use `Shouldly` for assertions.

## Prefer [Fact] over [Theory] for small input sets

Use `[Fact]` instead of `[Theory]` when there are only one or two input sets. Split into separate named tests.

Rules:
- If a `[Theory]` has one or two `[InlineData]` cases, replace it with individual `[Fact]` tests.
- Give each fact a name that describes the specific condition — this replaces the data row as documentation.
- Only use `[Theory]` when there are three or more meaningfully distinct input sets that test the same behavior.

Bad example (Theory with two cases):

```csharp
[Theory]
[InlineData("")]
[InlineData(null)]
public void Validate_fails_when_name_is_invalid(string name)
{
    //// Arrange
    var validator = new NameValidator();

    //// Act
    var result = validator.Validate(name);

    //// Assert
    result.IsValid.ShouldBeFalse();
}
```

Good example (split into Facts):

```csharp
[Fact]
[Trait("Category", "Unit")]
public void Validate_fails_when_name_is_empty_string()
{
    //// Arrange
    var validator = new NameValidator();

    //// Act
    var result = validator.Validate("");

    //// Assert
    result.IsValid.ShouldBeFalse();
}

[Fact]
[Trait("Category", "Unit")]
public void Validate_fails_when_name_is_null()
{
    //// Arrange
    var validator = new NameValidator();

    //// Act
    var result = validator.Validate(null);

    //// Assert
    result.IsValid.ShouldBeFalse();
}
```

Benefits:
- Each failure names exactly which condition broke.
- Tests read as individual specifications.
- No need to decode a data table to understand intent.

## Test categorization
Always add a `Category` trait to test classes or methods to indicate the test type:
- Use `[Trait("Category", "Unit")]` for unit tests.
- Use `[Trait("Category", "Integration")]` for integration tests.

If multiple versions of a tested interface exist, add a `Version` trait:
- Example: `[Trait("Version", "v1")]`
- Example: `[Trait("Version", "v2")]`

These traits enable selective test execution and filtering.

## Test naming convention
Pattern:

```text
<MethodUnderTest>_<ExpectedBehavior>_<Condition>
```

Rules:
- Use PascalCase for each segment.
- Keep names explicit and descriptive.
- Each test describes one behavior.
- Avoid conjunctions like `And` or `Or` unless unavoidable.
- Do not encode implementation details.

Example:

```csharp
Has_been_posted_returns_false_when_not_posted
```

## Required test structure
Every test must contain the Arrange, Act, and Assert sections in this order, each prefixed with four slashes (`////`).

Basic form:

```csharp
//// Arrange

//// Act

//// Assert
```

When the test allocates external resources that must be released regardless of outcome, wrap the body in a `try/finally` block and add a `Cleanup` section in the `finally`:

```csharp
try
{
    //// Arrange

    //// Act

    //// Assert
}
finally
{
    //// Cleanup
    await CleanupResources();
}
```

No other sections, no reordering.

## Quad-slash is reserved
The `////` prefix is reserved exclusively for the four section labels: `Arrange`, `Act`, `Assert`, and `Cleanup`. Do not use four leading slashes for any other comment.

Each label may carry an optional clarifying note after a dash:

```csharp
//// Cleanup - delete the group after testing
```

## Section rules
Arrange:
- Set up only what is required for behavior under test.
- Prefer real dependencies through DI when reasonable.
- Avoid unnecessary mocks, data, and helper logic.

Act:
- Perform one action.
- Keep the action minimal (prefer one line).
- Capture the result in a clearly named variable.

Assert:
- Assert one outcome.
- Use Shouldly assertions only.
- Avoid logic, branching, or transformations inside assertions.

Cleanup:
- Only present when external resources (database records, files, API-created objects, etc.) need to be torn down after the test.
- Always placed in a `finally` block so it runs even if Arrange, Act, or Assert throws.
- Keep it minimal — undo only what this test created.

## Canonical example

```csharp
[Fact]
[Trait("Category", "Integration")]
public async Task Has_been_posted_returns_false_when_not_posted()
{
    //// Arrange
    var tracker = _serviceProvider.GetRequiredService<ISocialPostTracker>();
    var puzzleId = $"test-puzzle-{Guid.NewGuid()}";

    //// Act
    var result = await tracker.HasBeenPostedAsync(puzzleId, SocialPlatform.Bluesky);

    //// Assert
    result.ShouldBeFalse();
}
```

Example with version trait:

```csharp
[Fact]
[Trait("Category", "Unit")]
[Trait("Version", "v1")]
public void Calculate_returns_correct_sum_for_v1_interface()
{
    //// Arrange
    var calculator = new CalculatorV1();

    //// Act
    var result = calculator.Calculate(2, 3);

    //// Assert
    result.ShouldBe(5);
}
```

Example with cleanup:

```csharp
[Fact]
[Trait("Category", "Integration")]
public async Task CreateGroup_creates_and_returns_group()
{
    string? groupId = null;

    try
    {
        //// Arrange
        var service = _serviceProvider.GetRequiredService<IGroupService>();

        //// Act
        groupId = await service.CreateGroupAsync("test-group");

        //// Assert
        groupId.ShouldNotBeNullOrEmpty();
    }
    finally
    {
        //// Cleanup - delete the group after testing
        if (groupId is not null)
            await service.DeleteGroupAsync(groupId);
    }
}
```

## Project and folder structure
Mirror production paths inside test projects.

Production file:

```text
/Features/Images/IcoLoader.cs
```

Test file:

```text
/Features/Images/IcoLoaderTests.cs
```

Guidelines:
- Folder names match exactly.
- Test file name is production type name plus `Tests`.
- One test class per production type.
- Do not flatten or reorganize test project folders.

## Test files and embedded resources
For PDFs, images, JSON, and similar test files:
- Store files under `/TestFiles` in the test project.
- Mark files as `Embedded Resource`.
- Do not read test files from disk at runtime.
- Access resources through the test assembly.

Resource pointer pattern:
- Create a sealed empty marker class named `ResourcePointer`.
- Place it in the same `/TestFiles` folder.
- Use it to locate assembly and namespace.

Required loading pattern:

```csharp
typeof(ResourcePointer)
    .Assembly
    .GetManifestResourceStream(
        typeof(ResourcePointer),
        "diploma-with-fields.pdf");
```

Do not:
- Hard-code assembly names.
- Use relative or absolute file paths.
- Duplicate resource-loading helpers unless needed.

## Avoid nullable chain access in assertions
Do not use the null-conditional operator (`?.`) inside assertions. It silently masks null values, causing tests to pass without exercising the expected code path.

Bad (dangerous — null falls through to `ShouldBe`):

```csharp
result?.Item?.ClientId.ShouldBe(clientId);
```

Good (fails fast with a null reference):

```csharp
result.Item.ClientId.ShouldBe(clientId);
```

Better (explicit null guard with a clear failure message):

```csharp
result.ShouldNotBeNull();
result.Item.ClientId.ShouldBe(clientId);
```

## Self-contained tests
Prefer having the full context for a test inside the test method itself. Arrange sections should declare their own dependencies, data, and state inline rather than relying on class-level fields, static helpers, or shared fixture state.

Fixtures (`IClassFixture`, `ICollectionFixture`) are acceptable for genuinely expensive one-time infrastructure — such as starting a test server or a database container — but test-specific data and setup should always live inside the test.

## Extract large helpers to dedicated files

Keep helper methods and classes inside test files short — no more than a few lines. When a helper grows beyond that, extract it to a dedicated file.

Rules:
- Inline helper methods should be roughly ≤5 lines. Beyond that, move them out.
- Place extracted helpers in a `Helpers/` directory that mirrors the test's feature path.
- Prefer extension methods over static helper classes for reusability and discoverability.
- Name the file after the type it extends (e.g., `HttpResponseMessageExtensions.cs`).
- Keep helpers test-framework-agnostic where possible — avoid xUnit-specific dependencies in extracted code.

Bad — bloated helper inline in a test file:

```csharp
private static async Task<string> ExtractFieldAsync(
    HttpResponseMessage response, string fieldName)
{
    var body = await response.Content.ReadAsStringAsync();
    using var doc = JsonDocument.Parse(body);
    var token = doc.RootElement.GetProperty(fieldName);
    return token.GetString() ?? string.Empty;
}
```

Good — extracted to `Helpers/HttpResponseMessageExtensions.cs`:

```csharp
internal static class HttpResponseMessageExtensions
{
    internal static async Task<string> ExtractFieldAsync(
        this HttpResponseMessage response, string fieldName)
    {
        var body = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(body);
        var token = doc.RootElement.GetProperty(fieldName);
        return token.GetString() ?? string.Empty;
    }
}
```

Usage in the test file:

```csharp
//// Act
var response = await client.GetAsync("/api/orders/1");

//// Assert
var clientId = await response.ExtractFieldAsync("clientId");
clientId.ShouldBe("abc-123");
```

## General principles
- Tests read like executable specifications.
- One behavior per test.
- Clarity over cleverness.
- Failures communicate intent clearly.
- Keep Act and Assert sections minimal.

## Enforcement
- Use PR checklists that reference this skill.
- Enforce in code review.
- Optionally add templates or Roslyn analyzers.
