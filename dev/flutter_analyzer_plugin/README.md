# Flutter Analyzer Plugin

`dev/flutter_analyzer_plugin` is a custom Dart Analysis Server plugin providing custom static analysis rules and lints tailored specifically for the `flutter/flutter` repository.

This plugin replaces legacy regex-based and manual AST scripts (previously located in `dev/bots/analyze.dart`) with native, real-time analyzer diagnostics integrated directly into developer IDEs (VS Code, Android Studio) and the `flutter analyze` CLI.

---

## Table of Contents

- [Plugin Overview & Architecture](#plugin-overview--architecture)
- [Configuration](#configuration)
  - [Loading the Plugin](#loading-the-plugin)
  - [Rule Activation & Opt-Out](#rule-activation--opt-out)
  - [Monorepo Path Resolution](#monorepo-path-resolution)
- [Rules Reference](#rules-reference)
- [Detailed Rule Specifications](#detailed-rule-specifications)
  - [General & Global Rules](#general--global-rules)
    - [`avoid_future_catch_error`](#avoid_future_catch_error)
    - [`no_double_clamp`](#no_double_clamp)
    - [`no_stopwatches`](#no_stopwatches)
    - [`deprecation_syntax`](#deprecation_syntax)
    - [`no_runtimetype_in_tostring`](#no_runtimetype_in_tostring)
    - [`no_sync_async_star`](#no_sync_async_star)
  - [Framework & Architecture Rules](#framework--architecture-rules)
    - [`no_bad_imports_in_flutter`](#no_bad_imports_in_flutter)
    - [`protect_public_state_subtypes`](#protect_public_state_subtypes)
    - [`render_box_intrinsics`](#render_box_intrinsics)
    - [`null_initialized_debug_expensive_fields`](#null_initialized_debug_expensive_fields)
  - [Testing Rules](#testing-rules)
    - [`skip_test_comments`](#skip_test_comments)
    - [`integration_test_timeouts`](#integration_test_timeouts)
- [Authoring & Testing Custom Rules](#authoring--testing-custom-rules)
  - [1. Implementing an AnalysisRule](#1-implementing-an-analysisrule)
  - [2. Registering the Rule](#2-registering-the-rule)
  - [3. Writing Unit Tests](#3-writing-unit-tests)
  - [4. Running Unit Tests](#4-running-unit-tests)
  - [5. Best Practices & Migration Tips](#5-best-practices--migration-tips)

---

## Plugin Overview & Architecture

The Flutter SDK repository utilizes custom static analysis rules to enforce architectural boundaries, performance invariants, test hygiene, and style conventions across its packages.

The analysis options hierarchy is structured as follows:
- **Base Options Files (`analysis_options_common.yaml`)**: Define baseline linter rules and analyzer settings shared across repositories and subtrees.
- **Root `analysis_options.yaml`**: The repository root entrypoint, which includes the common baseline options and configures repository-level analyzer behaviors and exclusions.
- **Subpackage `analysis_options.yaml` Files**: Packages and directories (such as `packages/flutter/lib`, `packages/flutter/test`, `packages/flutter_tools`, and `dev/`) include their parent analysis options and load `flutter_analyzer_plugin` via the `plugins:` block with the appropriate relative directory depth.

---

## Configuration

### Loading the Plugin

To load `flutter_analyzer_plugin` in a package or directory's `analysis_options.yaml`, add the plugin entry under the `plugins:` section:

```yaml
plugins:
  flutter_analyzer_plugin:
    path: ../../dev/flutter_analyzer_plugin
```

### Rule Activation & Opt-Out

All warning and error rules registered within `flutter_analyzer_plugin` are **enabled by default** once the plugin is loaded.

Packages or directories can explicitly opt out of specific rules (or re-enable them) using the `diagnostics:` section:

```yaml
plugins:
  flutter_analyzer_plugin:
    path: ../../dev/flutter_analyzer_plugin
    diagnostics:
      # Opt out of specific rules if necessary
      no_stopwatches: false
      avoid_future_catch_error: false
```

### Monorepo Path Resolution

The analyzer requires all `analysis_options.yaml` files referencing `flutter_analyzer_plugin` to resolve to the exact same canonical directory path on disk. Ensure relative paths reflect the correct directory nesting depth:

| Package / Directory Depth | Example Path | Configured Plugin Path |
| :--- | :--- | :--- |
| **Depth 1** | `dev/` | `path: flutter_analyzer_plugin` |
| **Depth 2** | `packages/flutter_tools/`, `packages/flutter_test/` | `path: ../../dev/flutter_analyzer_plugin` |
| **Depth 3** | `packages/flutter/lib/`, `packages/flutter/test/` | `path: ../../../dev/flutter_analyzer_plugin` |

---

## Rules Reference

| Rule Name | Severity | Default | Scope | Summary |
| :--- | :--- | :--- | :--- | :--- |
| [`avoid_future_catch_error`](#avoid_future_catch_error) | `ERROR` | Enabled | Global | Disallow `.catchError` / `.onError` on `Future` (prefer `try`/`catch`). |
| [`no_double_clamp`](#no_double_clamp) | `ERROR` | Enabled | Global | Disallow `double.clamp` / `num.clamp` (prefer `clampDouble`). |
| [`no_stopwatches`](#no_stopwatches) | `ERROR` | Enabled | Global | Disallow raw `Stopwatch` instantiation (prefer `clock.stopwatch()`). |
| [`deprecation_syntax`](#deprecation_syntax) | `ERROR` | Enabled | Global | Enforce standard multi-line formatting on `@Deprecated` annotations. |
| [`no_runtimetype_in_tostring`](#no_runtimetype_in_tostring) | `ERROR` | Enabled | Global | Avoid calling `runtimeType.toString()` inside `toString()` methods. |
| [`no_sync_async_star`](#no_sync_async_star) | `ERROR` | Enabled | Global | Disallow `sync*` and `async*` methods without an explanatory comment. |
| [`no_bad_imports_in_flutter`](#no_bad_imports_in_flutter) | `ERROR` | Enabled | `packages/flutter/lib/src/` | Enforce layer hierarchy, prevent cycles, and forbid meta imports outside foundation. |
| [`protect_public_state_subtypes`](#protect_public_state_subtypes) | `ERROR` | Enabled | `packages/flutter` | Require `@protected` on overridden lifecycle methods in public `State` classes. |
| [`render_box_intrinsics`](#render_box_intrinsics) | `ERROR` | Enabled | `packages/flutter/lib/src/rendering/` | Disallow calling `compute*` intrinsic methods directly (use `get*`). |
| [`null_initialized_debug_expensive_fields`](#null_initialized_debug_expensive_fields) | `ERROR` | Enabled | `packages/flutter` | Require `@_debugOnly` fields to be conditionally initialized via `kDebugMode ? <value> : null;`. |
| [`skip_test_comments`](#skip_test_comments) | `ERROR` | Enabled | Test files | Require justification comments (e.g. `// [intended]` or issue link) for skipped tests. |
| [`integration_test_timeouts`](#integration_test_timeouts) | `ERROR` | Enabled | `test_driver/` files | Require integration test files under `test_driver/` to set `timeout: Timeout.none`. |

---

## Detailed Rule Specifications

### General & Global Rules

#### `avoid_future_catch_error`
- **Severity**: `ERROR`
- **Scope**: Global (all Dart files where the plugin is enabled)
- **Description**: Disallows calling `.catchError()` or `.onError()` on a `Future` instance.
- **Rationale**: `Future.catchError` and `Future.onError` are not type-safe and can introduce subtle runtime bugs by bypassing strong type checks or returning unexpected dynamic types. Developers should use standard asynchronous `try`/`catch` blocks with `await`, or pass `onError` directly to `Future.then()`.
- **References**: [Dart SDK Issue #51248](https://github.com/dart-lang/sdk/issues/51248)

```dart
// BAD:
future.catchError((Object error) {
  handleError(error);
});

// GOOD:
try {
  await future;
} catch (error) {
  handleError(error);
}
```

---

#### `no_double_clamp`
- **Severity**: `ERROR`
- **Scope**: Global (all Dart files where the plugin is enabled)
- **Description**: Disallows direct invocations or tear-offs of `double.clamp()` and `num.clamp()`.
- **Rationale**: Invoking `double.clamp` on numbers incurs boxing/unboxing overhead on web and VM runtimes. Furthermore, tear-offs of `num.clamp` lose integer type promotion. Calling `clampDouble(val, min, max)` from `dart:ui` or `package:flutter/foundation.dart` avoids runtime overhead and retains native floating-point performance.
- **References**: [Flutter PR #103559](https://github.com/flutter/flutter/pull/103559), [Flutter Issue #103917](https://github.com/flutter/flutter/issues/103917)

```dart
// BAD:
final double clamped = value.clamp(0.0, 1.0);

// GOOD:
final double clamped = clampDouble(value, 0.0, 1.0);
```

---

#### `no_stopwatches`
- **Severity**: `ERROR`
- **Scope**: Global (all Dart files where the plugin is enabled)
- **Description**: Disallows direct instantiation of `Stopwatch()` or calling functions that return a `Stopwatch`.
- **Rationale**: Direct usage of `Stopwatch` relies on the host system clock, which can fall out of sync with `FakeAsync` during unit and widget tests, causing non-deterministic test flakes. Code should instead use `clock.stopwatch()` from `package:clock` (which binds with `FakeAsync` during tests) or use `dart:developer` timeline events for profiling.
- **Inline Exemption**: Standard analyzer ignore comments (`// ignore: no_stopwatches`) or legacy inline directive `// flutter_ignore: stopwatch (see analyze.dart)`.

```dart
// BAD:
final Stopwatch stopwatch = Stopwatch()..start();

// GOOD:
final Stopwatch stopwatch = clock.stopwatch()..start();
```

---

#### `deprecation_syntax`
- **Severity**: `ERROR`
- **Scope**: Global (all library declarations and public APIs)
- **Description**: Enforces standard multi-line string formatting on `@Deprecated` annotations.
- **Rationale**: Standardizing deprecation messages ensures all deprecated APIs provide actionable migration instructions, state the exact version of deprecation, and link to the Flutter deprecation policy.
- **Inline Exemption**: Standard analyzer ignore comments (`// ignore: deprecation_syntax`) or legacy inline directive `// flutter_ignore: deprecation_syntax (see analyze.dart)`.

```dart
// BAD:
@Deprecated('Use newMethod instead')
void oldMethod() {}

// GOOD:
@Deprecated(
  'Use newMethod instead. '
  'This feature was deprecated after v3.18.0-0.1.pre.'
)
void oldMethod() {}
```

---

#### `no_runtimetype_in_tostring`
- **Severity**: `ERROR`
- **Scope**: Global (all `toString()` implementations)
- **Description**: Disallows evaluating `runtimeType.toString()` or interpolating `$runtimeType` inside `toString()` methods.
- **Rationale**: Calling `runtimeType.toString()` prevents compiler tree-shaking, impairs dead code elimination, leaks minified symbol names in release builds, and incurs unnecessary string allocation overhead. If class name reflection is necessary for debug diagnostics, it must be enclosed inside `assert()` or guarded by `kDebugMode`.

```dart
// BAD:
@override
String toString() => '$runtimeType(value: $value)';

// GOOD:
@override
String toString() => 'MyClass(value: $value)';

// GOOD (Debug-only):
@override
String toString() {
  String? header;
  assert(() {
    header = '$runtimeType';
    return true;
  }());
  return '${header ?? 'MyClass'}(value: $value)';
}
```

---

#### `no_sync_async_star`
- **Severity**: `ERROR`
- **Scope**: Global (all functions, methods, and closures)
- **Description**: Disallows the use of `sync*` and `async*` generator functions unless accompanied by an explanatory comment.
- **Rationale**: Generator functions (`sync*` and `async*`) introduce heavy state machine and iterator allocations in Dart. Standard loops, collections, or stream controllers are typically more performant. When generators are genuinely necessary, an explanation comment must clarify the rationale.
- **References**: [Flutter Style Guide: Avoid sync\*/async\*](https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md#avoid-syncasync)

```dart
// BAD:
Iterable<int> countTo(int n) sync* {
  for (int i = 0; i < n; i++) yield i;
}

// GOOD:
// Uses sync* to lazily evaluate large datasets on demand.
Iterable<int> countTo(int n) sync* {
  for (int i = 0; i < n; i++) yield i;
}
```

---

### Framework & Architecture Rules

#### `no_bad_imports_in_flutter`
- **Severity**: `ERROR`
- **Scope**: `packages/flutter/lib/src/`
- **Description**: Enforces the strict Flutter layer dependency hierarchy, prohibits circular or recursive imports, enforces parity between `lib/*.dart` and `lib/src/*/`, and forbids importing `package:meta/meta.dart` outside `foundation`.
- **Rationale**: Flutter adheres to a strict layered architecture:
  `foundation` -> `animation` -> `painting` -> `gestures` -> `rendering` -> `widgets` -> `material` / `cupertino`
  Lower layers must never import higher layers. Circular layer imports and direct `package:meta` imports (which must be re-exported through `foundation`) undermine modularity and package encapsulation.

```dart
// BAD (in packages/flutter/lib/src/painting/):
import 'package:flutter/src/widgets/basic.dart'; // Upward layer import
import 'package:meta/meta.dart'; // Meta imported outside foundation

// GOOD (in packages/flutter/lib/src/painting/):
import 'package:flutter/foundation.dart';
```

---

#### `protect_public_state_subtypes`
- **Severity**: `ERROR`
- **Scope**: `packages/flutter` (classes extending `State`)
- **Description**: Requires `@protected` annotations on overridden lifecycle methods in public classes extending `State`.
- **Rationale**: Overridden lifecycle methods (`initState`, `build`, `dispose`, `setState`, `didUpdateWidget`, `didChangeDependencies`, `activate`, `deactivate`, `reassemble`, `debugFillProperties`) in public `State` subclasses become part of the public interface. Adding `@protected` prevents external consumers from invoking internal lifecycle logic directly.

```dart
// BAD:
class MyPublicWidgetState extends State<MyPublicWidget> {
  @override
  void initState() {
    super.initState();
  }
}

// GOOD:
class MyPublicWidgetState extends State<MyPublicWidget> {
  @override
  @protected
  void initState() {
    super.initState();
  }
}
```

---

#### `render_box_intrinsics`
- **Severity**: `ERROR`
- **Scope**: `packages/flutter/lib/src/rendering/` (`RenderBox` subclasses)
- **Description**: Disallows direct calls to intrinsic calculation methods (`compute*`) inside `RenderBox` subclasses and requires calling the corresponding cached `get*` methods instead.
- **Rationale**: `compute*` methods perform raw, uncached geometry evaluations. Calling them directly bypasses `RenderBox` intrinsic dimension caching and can result in exponential layout recalculation time ($O(2^N)$ layout passes).

| Uncached Method (Forbidden) | Cached Replacement (Required) |
| :--- | :--- |
| `computeDryBaseline` | `getDryBaseline` |
| `computeDryLayout` | `getDryLayout` |
| `computeDistanceToActualBaseline` | `getDistanceToBaseline` or `getDistanceToActualBaseline` |
| `computeMaxIntrinsicHeight` | `getMaxIntrinsicHeight` |
| `computeMinIntrinsicHeight` | `getMinIntrinsicHeight` |
| `computeMaxIntrinsicWidth` | `getMaxIntrinsicWidth` |
| `computeMinIntrinsicWidth` | `getMinIntrinsicWidth` |

```dart
// BAD (inside a RenderBox subclass):
final double width = child.computeMinIntrinsicWidth(height);

// GOOD:
final double width = child.getMinIntrinsicWidth(height);
```

---

#### `null_initialized_debug_expensive_fields`
- **Severity**: `ERROR`
- **Scope**: `packages/flutter`
- **Description**: Requires all fields annotated with `@_debugOnly` to be conditionally initialized via `kDebugMode ? <value> : null;`.
- **Rationale**: Expensive diagnostic objects and debug trackers must not allocate heap memory or execute costly initialization logic in profile and release builds. Initializing them with `kDebugMode ? <value> : null` enables the compiler and tree-shaker to eliminate both the field and its initializer in release builds.

```dart
// BAD:
@_debugOnly
List<StackTrace> _creationStackTraces = <StackTrace>[];

// GOOD:
@_debugOnly
List<StackTrace>? _creationStackTraces = kDebugMode ? <StackTrace>[] : null;
```

---

### Testing Rules

#### `skip_test_comments`
- **Severity**: `ERROR`
- **Scope**: All repository test files (`*_test.dart`)
- **Description**: Requires all skipped tests (`test(..., skip: ...)`) to include an inline justification comment explaining why the test is skipped.
- **Rationale**: Tests should never be silently skipped or left skipped indefinitely without tracking. Every `skip:` argument must provide an intentional marker (such as `// [intended]`) or reference an active GitHub tracking issue link (e.g. `https://github.com/flutter/flutter/issues/<issue-number>`).

```dart
// BAD:
test('flaky network test', () {}, skip: true);

// GOOD:
test('flaky network test', () {}, skip: true); // https://github.com/flutter/flutter/issues/<issue-number>

// GOOD:
test('platform specific test', () {},
  // [intended] Not supported on Windows.
  skip: !Platform.isLinux,
);
```

---

#### `integration_test_timeouts`
- **Severity**: `ERROR`
- **Scope**: Integration test suites under `test_driver/`
- **Description**: Requires integration tests under `test_driver/` to explicitly configure `timeout: Timeout.none`.
- **Rationale**: Host-driven integration and device lab tests involve application bootstrapping, emulator interactions, and golden screenshot comparisons that frequently exceed standard unit test timeouts (30 seconds). Explicitly specifying `timeout: Timeout.none` prevents spurious timeout failures under loaded CI test runners.

```dart
// BAD (in test_driver/app_test.dart):
void main() {
  test('starts app', () async {
    ...
  });
}

// GOOD (in test_driver/app_test.dart):
void main() {
  test('starts app', () async {
    ...
  }, timeout: Timeout.none);
}
```

---

## Authoring & Testing Custom Rules

### 1. Implementing an AnalysisRule

Custom rules inherit from `AnalysisRule` (from `package:analyzer/analysis_rule/analysis_rule.dart`).

1. Place the new rule in `dev/flutter_analyzer_plugin/lib/src/rules/<rule_name>.dart`.
2. Define a `LintCode` specifying diagnostic name, message, correction message, and `DiagnosticSeverity`.
3. Implement `registerNodeProcessors` to attach an AST visitor to the node types of interest.

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class MyCustomRule extends AnalysisRule {
  MyCustomRule()
    : super(
        name: code.name,
        description: 'Verify adherence to Flutter repository practices.',
      );

  static const LintCode code = LintCode(
    'my_custom_rule',
    'Explanation of why the pattern is disallowed.',
    correctionMessage: 'Recommended fix or alternatives.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (/* condition */ false) {
      rule.reportAtNode(node);
    }
  }
}
```

---

### 2. Registering the Rule

Register the rule in `dev/flutter_analyzer_plugin/lib/main.dart`:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/rules/my_custom_rule.dart';

class FlutterAnalyzerPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(MyCustomRule());
  }

  @override
  String get name => 'flutter/flutter analyzer plugin';
}
```

---

### 3. Writing Unit Tests

Rules must be covered by reflective tests using `package:analyzer_testing`:

1. Create a test file in `dev/flutter_analyzer_plugin/test/<rule_name>_test.dart`.
2. Extend `AnalysisRuleTest` and annotate the class with `@reflectiveTest`.
3. Register the rule in `setUp()` using `Registry.ruleRegistry.registerWarningRule(...)` and define test cases using `assertDiagnostics()`.

```dart
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_analyzer_plugin/src/rules/my_custom_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class MyCustomRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    // Registers the custom AnalysisRule with the test registry prior to running tests.
    Registry.ruleRegistry.registerWarningRule(MyCustomRule());
    super.setUp();
  }

  @override
  String get analysisRule => MyCustomRule.code.name;

  Future<void> test_disallowedPattern() async {
    await assertDiagnostics(
      '''
void test() {
  badFunction();
}
''',
      <ExpectedDiagnostic>[
        lint(16, 13),
      ],
    );
  }

  Future<void> test_allowedPattern() async {
    await assertNoDiagnostics(
      '''
void test() {
  goodFunction();
}
''',
    );
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MyCustomRuleTest);
  });
}
```

---

### 4. Running Unit Tests

Because tests use `test_reflective_loader` (which depends on `dart:mirrors`), tests must be executed with the standalone Dart VM SDK rather than `flutter test`:

```bash
# 1. Resolve plugin dependencies
cd dev/flutter_analyzer_plugin
../../bin/flutter pub get

# 2. Run unit tests using the Dart SDK
../../bin/cache/dart-sdk/bin/dart test test/my_custom_rule_test.dart
```

---

### 5. Best Practices & Migration Tips

- **Filtering by File Path**: Obtain the current file path via `context.currentUnit!.file.path` rather than `declaredElement` (which may be unpopulated during AST node registration).
- **Checking Generic Base Classes**: When checking if a class extends a generic base class (e.g. `State<T>`), cache the `InterfaceElement` (`superType.element`) rather than `DartType`, so subtype checks remain valid across different type arguments (`State<WidgetA>` vs `State<WidgetB>`).
- **Verifying Compilation**: Before submitting plugin changes, verify the plugin compiles cleanly and passes analysis:
  ```bash
  bin/cache/dart-sdk/bin/dart analyze --fatal-infos dev/flutter_analyzer_plugin
  ```
