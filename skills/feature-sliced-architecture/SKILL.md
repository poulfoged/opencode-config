---
name: feature-sliced-architecture
description: Structure ASP.NET Core applications around vertical feature folders with isolated dependency injection, feature boundaries, and shared infrastructure modules.
license: MIT
compatibility: opencode
metadata:
  stack: aspnet-core
  architecture: feature-folders
---

# Feature-Sliced Architecture Skill

## What I do

Use this skill when creating, refactoring, or reviewing an ASP.NET Core application that should be organized around vertical features rather than technical layers.

A feature is a full vertical slice of the application. It owns one coherent area of behavior, usually centered around a domain concept or DDD aggregate root.

Examples:

- `Ordering` for orders, order lines, checkout, order status, and order-related workflows.
- `Accounts` for user accounts, registration, authentication-adjacent account behavior, and account settings.
- `Billing` for invoices, payments, subscriptions, and payment-related workflows.

Features should be treated as application modules. Each feature should contain the code required to deliver that area of behavior: models, views, controller, service, feature-specific dependency injection setup, domain behavior, persistence concerns, and supporting implementation details.

## Folder structure

Prefer this root-level structure:

```text
src/
  App/
    Features/
      Ordering/
        DependencyInjection/
          OrderingFeatureExtensions.cs
        Model/
        Views/
        OrderingController.cs
        OrderingService.cs
      Accounts/
        DependencyInjection/
          AccountsFeatureExtensions.cs
        Model/
        Views/
        AccountsController.cs
        AccountsService.cs

    Infrastructure/
      SqlServer/
        DependencyInjection/
          SqlServerInfrastructureExtensions.cs
        Options/
      Messaging/
        DependencyInjection/
          MessagingInfrastructureExtensions.cs
        Options/
      Observability/
        DependencyInjection/
          ObservabilityInfrastructureExtensions.cs
        Options/
```

The exact subfolders inside a feature may vary, but the feature folder should remain the primary boundary.

Each feature should contain its own MVC-style structure where relevant: feature-specific models, views, controller, service, dependency injection setup, and any supporting implementation details.

Avoid organizing application behavior primarily by technical layer, such as:

```text
Controllers/
Services/
Repositories/
Dtos/
Validators/
```

unless the project already uses that convention and the task is only a small local change.

## Feature boundaries

Features should strive to be loosely coupled.

A feature should not directly depend on another feature’s internal implementation.

Prefer communication through one of these mechanisms:

1. Interfaces registered through dependency injection.
2. Domain events.
3. Integration events.
4. A message bus or service bus.
5. Explicit public contracts.
6. Shared kernel types only when they are genuinely stable and broadly useful.

Avoid:

- Reaching directly into another feature’s implementation details.
- Sharing repositories between features.
- Importing another feature’s controllers, services, models, or internal types.
- Creating large shared service folders that become hidden coupling points.
- Moving domain behavior into generic cross-feature helpers.

If one feature needs behavior from another feature, define a narrow contract and depend on that contract.

Example:

```csharp
public interface IAccountLookup
{
    Task<AccountSummary?> FindByIdAsync(AccountId accountId, CancellationToken cancellationToken);
}
```

The consuming feature depends on `IAccountLookup`, not on the `Accounts` feature’s internal persistence or domain model.

## Dependency injection convention

Each feature must have a `DependencyInjection` folder.

Each feature should expose one or both of these extension methods:

```csharp
public static IServiceCollection AddOrderingFeature(
    this IServiceCollection services,
    IConfiguration configuration)
```

and/or:

```csharp
public static WebApplication UseOrderingFeature(
    this WebApplication app)
```

Use `Add{FeatureName}Feature` for registering services, options, validators, repositories, feature-local infrastructure, and health checks.

Use `Use{FeatureName}Feature` for mapping controllers, endpoints, middleware, background setup, or feature-specific web application configuration.

Example:

```csharp
namespace App.Features.Ordering.DependencyInjection;

public static class OrderingFeatureExtensions
{
    public static IServiceCollection AddOrderingFeature(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<OrderingOptions>(
            configuration.GetSection(OrderingOptions.SectionName));

        services.AddScoped<OrderingService>();
        services.AddScoped<IOrderRepository, SqlOrderRepository>();
        services.AddScoped<IOrderNumberGenerator, OrderNumberGenerator>();

        return services;
    }

    public static WebApplication UseOrderingFeature(this WebApplication app)
    {
        return app;
    }
}
```

In `Program.cs`, the feature should be wired clearly:

```csharp
builder.Services.AddOrderingFeature(builder.Configuration);
builder.Services.AddAccountsFeature(builder.Configuration);

var app = builder.Build();

app.UseOrderingFeature();
app.UseAccountsFeature();

app.Run();
```

## Infrastructure modules

Cross-feature infrastructure must live under a root-level `Infrastructure` folder next to `Features`.

Infrastructure modules include things such as:

- SQL Server setup.
- Entity Framework Core setup.
- Messaging setup.
- Redis setup.
- Blob storage setup.
- Observability/logging setup.
- Email/SMS provider setup.
- Health check setup.
- External API clients shared by multiple features.

Infrastructure modules should follow the same modular pattern as features.

Each infrastructure module should have a `DependencyInjection` folder and expose extension methods such as:

```csharp
public static IServiceCollection AddSqlServerInfrastructure(
    this IServiceCollection services,
    IConfiguration configuration,
    IHealthChecksBuilder? healthChecks = null)
```

and/or:

```csharp
public static WebApplication UseSqlServerInfrastructure(
    this WebApplication app)
```

Use `Add{InfrastructureName}Infrastructure` for service registration.

Use `Use{InfrastructureName}Infrastructure` for application pipeline setup.

Example:

```csharp
namespace App.Infrastructure.SqlServer.DependencyInjection;

public static class SqlServerInfrastructureExtensions
{
    public static IServiceCollection AddSqlServerInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration,
        IHealthChecksBuilder? healthChecks = null)
    {
        var connectionString = configuration.GetConnectionString("SqlServer");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Missing required connection string: SqlServer.");
        }

        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseSqlServer(connectionString);
        });

        healthChecks?.AddSqlServer(
            connectionString,
            name: "sql-server",
            tags: ["infrastructure", "sql-server", "database"]);

        return services;
    }

    public static WebApplication UseSqlServerInfrastructure(this WebApplication app)
    {
        return app;
    }
}
```

The infrastructure registration should accept configuration and, where relevant, an `IHealthChecksBuilder`.

Prefer meaningful health check names and tags.

Example:

```csharp
var healthChecks = builder.Services.AddHealthChecks();

builder.Services.AddSqlServerInfrastructure(
    builder.Configuration,
    healthChecks);
```

## Configuration

Feature and infrastructure modules should bind their own options.

Use named options classes with a clear section name:

```csharp
public sealed class OrderingOptions
{
    public const string SectionName = "Features:Ordering";

    public int MaxOpenOrdersPerAccount { get; init; } = 50;
}
```

Infrastructure options should also own their configuration section:

```csharp
public sealed class SqlServerOptions
{
    public const string SectionName = "Infrastructure:SqlServer";

    public string ConnectionStringName { get; init; } = "SqlServer";
}
```

Prefer validation at startup when settings are required.

## Naming rules

Use these naming conventions unless the existing project strongly indicates otherwise.

Feature folder:

```text
Features/Ordering
```

Feature DI extension class:

```text
OrderingFeatureExtensions.cs
```

Feature registration method:

```csharp
AddOrderingFeature(...)
```

Feature app method:

```csharp
UseOrderingFeature(...)
```

Feature controller:

```text
OrderingController.cs
```

Feature service:

```text
OrderingService.cs
```

Infrastructure folder:

```text
Infrastructure/SqlServer
```

Infrastructure DI extension class:

```text
SqlServerInfrastructureExtensions.cs
```

Infrastructure registration method:

```csharp
AddSqlServerInfrastructure(...)
```

Infrastructure app method:

```csharp
UseSqlServerInfrastructure(...)
```

Do not use names like `AddServices`, `RegisterDependencies`, or `ServiceCollectionExtensions` when a more specific module name is available.

## Review checklist

When reviewing code, check:

- Does the feature represent a vertical slice rather than a technical layer?
- Does the feature own its own models, views, controller, service, and implementation details?
- Is the feature registered through `Add{FeatureName}Feature()`?
- Is web application setup exposed through `Use{FeatureName}Feature()` when needed?
- Does the feature avoid directly depending on another feature’s internals?
- Are cross-feature dependencies expressed through narrow interfaces, events, or messaging?
- Does shared infrastructure live under root-level `Infrastructure/`?
- Does each infrastructure module have its own `DependencyInjection` folder?
- Does infrastructure setup accept `IConfiguration`?
- Does infrastructure setup accept `IHealthChecksBuilder` where health checks are meaningful?
- Are health checks named and tagged clearly?
- Is `Program.cs` mostly composition, not implementation?

## Decision guidance

When adding new code:

1. First ask: “Which feature owns this behavior?”
2. If the behavior belongs to one feature, place it inside that feature.
3. If the behavior supports many features technically, place it under `Infrastructure`.
4. If the behavior is domain knowledge shared by multiple features, be careful. Prefer duplication or a narrow contract over premature shared abstractions.
5. If two features need to communicate, use an interface, event, or message instead of direct implementation access.

## Avoid

Avoid creating broad shared folders such as:

```text
Common/
Helpers/
Managers/
Services/
Repositories/
```

unless their purpose is extremely clear and stable.

Avoid using feature folders as cosmetic grouping while still keeping all real behavior in global services.

Avoid making infrastructure depend on feature internals. Infrastructure should provide technical capabilities; features decide how to use them.

Avoid leaking database entities, EF Core configuration, or persistence details from one feature into another.
