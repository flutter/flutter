# Flutter Gradle Plugin (FGP) Architecture & Development Rules

## Scope & Legacy Code Policy (The Ratchet Principle)
- **New Code & Modified Lines**: All newly introduced tasks, properties, build logic, and modified lines must strictly comply with these rules.
- **No Automatic Legacy Refactoring**: Pre-existing code that violates target architectural guidelines (such as Worker API adoption, configuration-cache compliance, or legacy mock boilerplate) should **not** be automatically refactored within an unrelated PR to prevent scope explosion, high review burden, and regression risks.
- **Surface Opportunities to the User**: When encountering adjacent legacy violations or cleanup opportunities during development, bring them to the user's attention with a brief rationale rather than silently skipping them or applying unapproved refactors. The user can then decide whether to include a localized cleanup or track it for a follow-up PR.
- **Dedicated Refactoring**: Large-scale migrations of existing tasks to modern Gradle APIs should be planned and executed in dedicated, standalone pull requests.

---

## 1. Zero Pollution of Customer-Facing Build Scripts
- **Consumer Build Isolation**: `build.gradle.kts` is evaluated directly in customer projects via composite builds (`includeBuild`). Keep build scripts minimal with only logic needed to compile and package the plugin.
- **No Contributor Tasks in Build Scripts**: Never register contributor verification tasks, custom lint tasks, or lifecycle hooks (`check.dependsOn`, `test.dependsOn`) in customer-evaluated build scripts.
- **Offline Verification**: Implement all contributor assertions, bytecode validations, and ABI checks in unit tests (`src/test/kotlin/`) or CI integration test shards (`packages/flutter_tools/test/integration.shard/`).

## 2. Type-Safe AGP & Gradle API Usage (No `@Suppress`)
- **No Unsafe Casts or Suppression**: Never use raw wildcard casts (e.g., `as NamedDomainObjectContainer<Any>`) or `@Suppress("UNCHECKED_CAST")`. Unchecked casts conceal breaking changes across AGP versions.
- **Use Idiomatic Type-Safe APIs**: Use official, type-safe AGP APIs (e.g., `pluginBuildTypes.create(name) { initWith(source) }`) to manipulate domain objects safely across AGP releases.
- **Structured Compatibility Layers**: When bridging binary- or DSL-incompatible AGP versions (e.g., AGP 8 vs 9), introduce explicit, type-safe abstraction wrappers or reflection bridges.

## 3. Lazy Configuration & Execution Avoidance
- **Never Eagerly Resolve at Configuration Time**: Never call .get() or .getOrNull() during plugin application or task configuration (afterEvaluate, task creation). Wire inputs and outputs lazily using Property, Provider, ListProperty, MapProperty, DirectoryProperty, and RegularFileProperty.
- **Wire Providers Directly**: Pass providers directly into task inputs (e.g., `task.inputDir.set(extension.path)`).

## 4. Strict Configuration Cache Compatibility
- **No Project State in Tasks**: Tasks must never hold references to `Project`, `SourceSet`, `Configuration`, or other non-serializable Gradle model objects in fields or action closures.
- **Pass Serializable Inputs**: Inject required values as primitive types, serializable data structures, or Gradle Property instances annotated with @Input, @InputFiles, or @InputDirectory.
- **Use Injected Services**: Use Gradle service injection (e.g., @Inject for FileSystemOperations, ArchiveOperations, or ExecOperations) inside tasks instead of calling Project helper methods.

## 5. Build Avoidance & Path Normalization
- **Path Normalization**: Annotate all file inputs (such as @InputFile or @InputDirectory) with @PathSensitive(PathSensitivity.RELATIVE) or @PathSensitive(PathSensitivity.NAME_ONLY) (instead of absolute paths) to ensure cache hits across different machines and CI environments.
- **Deterministic Cache Keys**: Never mark non-deterministic inputs (such as timestamps or machine-dependent environment variables) as `@Input`.
- **Explicit Outputs**: Declare `@OutputFile` or `@OutputDirectory` for every produced artifact.

## 6. Worker API for Heavy Computation
- **Thread & Classloader Isolation**: Offload heavy computation, class parsing, code generation, or external process execution to `WorkerExecutor` / `WorkQueue` (using `noIsolation()`, `classLoaderIsolation()`, or `processIsolation()`) to keep the main Gradle daemon thread non-blocking.

## 7. Namespace & Environment Hygiene
- **Namespace Internal Properties**: Prefix all internal Gradle properties, project extensions, and system properties with `flutter.internal.` (e.g., `flutter.internal.agpVersion`) to prevent collisions with customer app configurations.
- **Matrix Verification**: Verify compatibility against the full matrix of supported AGP versions (AGP 8.x through 9.x) and Gradle versions.
