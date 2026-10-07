# Migrating the Flutter Gradle Plugin to the AGP Public API Surface

This document is the contributor-facing record of the migration of the Flutter
Gradle Plugin (FGP) off the legacy Android Gradle Plugin (AGP) DSL/Variant API
and AGP internals, onto the public API surface shipped in the
`com.android.tools.build:gradle-api` artifact.

Umbrella issues:

- newDsl flip: https://github.com/flutter/flutter/issues/180137
- Variant API migration: https://github.com/flutter/flutter/issues/166550

The user-facing breaking-change page draft lives next to this file in
[`website-page-draft.md`](website-page-draft.md). It must be published to
`docs.flutter.dev/release/breaking-changes/` before the newDsl flip (phase P9)
reaches the beta channel. Tracking issue:
https://github.com/flutter/flutter/issues/193713

## Why

AGP 9 (January 2026) deprecated the old DSL and Variant APIs behind the
`android.newDsl=false` escape hatch. AGP 10 (late 2026) removes those APIs
entirely **and** removes access to AGP internals — only the public surface of
the `gradle-api` artifact remains. Today the FGP:

- compiles against the FULL `com.android.tools.build:gradle` artifact
  (`packages/flutter_tools/gradle/build.gradle.kts`);
- uses the legacy variant API (`applicationVariants`, `libraryVariants`,
  `variant.outputs`, `assembleProvider`, `packageApplicationProvider`,
  `versionCodeOverride`);
- uses the legacy `BaseExtension`
  (`FlutterPluginUtils.getLegacyAndroidExtension`);
- imports one internal DSL class (`com.android.build.gradle.internal.dsl.BuildType`
  in `plugins/PluginHandler.kt`);
- imports one internal utility
  (`com.android.build.gradle.internal.utils.getKotlinAndroidPluginVersion` in
  `VersionFetcher.kt`);
- drives `flutter build aar` with legacy dynamic Groovy in
  `aar_init_script.gradle`.

Flutter templates pin AGP 9.1.0 but ship `android.newDsl=false`, and a tool
migrator (`disable_new_dsl_migration.dart`) adds the opt-out to existing
projects. That opt-out dies with AGP 10.

## End state

- The FGP uses only public APIs and compiles against `gradle-api`.
- Templates no longer ship `android.newDsl=false`.
- The opt-out **add** migrator is replaced by a **removal** migrator that
  deletes only the Flutter-added opt-out lines.
- A fresh `flutter create` app builds with newDsl on.

## Decision records

1. **Min AGP floor: out of scope.** A separate version bump owned the
   floor, which has now landed on `master` (PRs #176858 and #177416 bumped the
   floor to `8.11.1`). This migration builds seamlessly on that new floor.
   Every replacement API used here was verified public in `gradle-api:8.11.1`
   (decompiled jar inspection). If implementation finds a replacement API that
   genuinely requires a higher min AGP: document which API and why no
   compatible alternative exists in this file, then bump — otherwise version
   floors are untouched by this work.
2. **"Public in 8.x" does not mean binary-compatible on 9.x.**
   `AgpCommonExtensionWrapper.kt` exists precisely because the public
   `CommonExtension` broke between AGP 8 and 9. Mitigation: a CI/test axis
   compiling the FGP against gradle-api 9.x is mandatory from phase P2 onward,
   plus a bytecode check (javap grep) that no compiled FGP class references
   `CommonExtension` as an owner.
3. **`android.builtInKotlin=false` stays out of scope.** Flipping it requires
   the separate built-in-Kotlin migration workstream. Users get a second
   (smaller) gradle.properties churn later; the breaking-change page states
   this explicitly. Corollary: the P9 removal migrator must anchor on the
   `android.newDsl` property line — never on marker-comment wording alone —
   because the template's builtInKotlin marker comment is nearly identical.
4. **Per-ABI versionCode mechanism.** Do NOT re-implement AGP's flavor-merge
   precedence via a `finalizeDsl` snapshot. Preferred mechanism (spiked first
   in P6): read-then-set on `VariantOutput.versionCode` inside `onVariants` —
   it is seeded with the merged value; set `abiOffset * 1000 + current`,
   avoiding a self-referential `.map`. Fall back to a snapshot only if
   read-then-set is impossible; record the outcome here.
   - *Spike result:* read-then-set works only while AGP's compatibility mode is on
     (`android.compatibility.enableLegacyApi`, default `true` through AGP 9.x and marked
     `FeatureStage.Deprecated(VERSION_10_0)`). With it set to `false`, AGP calls
     `disallowUnsafeRead()` on `VariantOutput.versionCode` and the read fails with
     "configuration of project ':app' has not completed yet". `Property` has no lazy
     self-transform to fall back on. AGP deprecates the option for removal in 10.0, and the
     [AGP roadmap](https://developer.android.com/build/releases/gradle-plugin-roadmap)
     describes AGP 10.0 as completing the move to a fully lazy build model, so P6 does not
     depend on the option and ships the `finalizeDsl` snapshot
     instead: `DslVersionCodes` reads `defaultConfig.versionCode` and each product
     flavor's `versionCode` in `finalizeDsl`, and `configureSplitPerAbiVersionCodes` in
     `FlutterPlugin.kt` sets `abiOffset * 1000 + base` without reading the property.
     `DslVersionCodes.forVariant` matches AGP's merge (the first flavor in dimension order
     that sets a versionCode, then `defaultConfig`). A versionCode set only in the
     manifest is not offset, because AGP reads it at execution time. The
     `split_per_abi` integration test covers `enableLegacyApi=false`. See "Features that
     must break" item 3 for the effect on apps that change `versionCode` in their own
     `onVariants`.
5. **`buildModeFor` semantics.** Every variant-scope call uses the
   `(name, debuggable)` overload with the public `Component.debuggable`.
   Name-based inference is confined to the one DSL-scope case with no public
   signal (the library-plugin build-type copy in `PluginHandler`). In an
   add-to-app module the call reads the module's own variant, so the build mode
   follows the module variant that the host's `matchingFallbacks` select (see
   "Features that must break" item 6).
6. **P3 pre-spike / PR 4 (afterEvaluate DSL mutation under newDsl).** The planned scratch-app
   spike (AGP 9.1 + `newDsl=true` + custom build type, verifying that build-type
   creation from `pluginProject.afterEvaluate` still works) could not run in the
   implementation sandbox (no AGP artifact access). The `initWith` copy landed on the
   primary approach; the `android_plugin_example_app_build` integration test and a
   custom-build-type scratch build must confirm it in CI. Documented fallback if
   `afterEvaluate` mutation is rejected under newDsl: perform the copy in
   `androidComponents.finalizeDsl` on the plugin project instead.

## Replacement map

| Legacy usage | Where | Public replacement | Phase |
| --- | --- | --- | --- |
| `internal.utils.getKotlinAndroidPluginVersion` | `VersionFetcher.kt` | delete; rely on existing fallback chain (`kotlin_version` property → `KotlinAndroidPluginWrapper.pluginVersion` → reflection); null when KGP absent is OK | P1 |
| `compileSdkVersion` string compare (`"android-NN"` substring) | `FlutterPluginUtils.getCompileSdkFromProject`, `PluginHandler` warning | wrapper `compileSdk` / `compileSdkPreview`; numeric compare with defined preview semantics | P1 |
| `BaseExtension.ndkVersion` | `FlutterPluginUtils.getConfiguredNdkVersion` | wrapper `ndkVersion` | P1 |
| `buildModeFor(BuildType)` (legacy model type) | `FlutterPluginUtils.kt` | `buildModeFor(name, debuggable)` overload | P2 |
| `getLegacyAndroidExtension(project).buildTypes` loops | `PluginHandler.kt` | wrapper new-DSL `buildTypes` container | P2 |
| `internal.dsl.BuildType` live aliasing into plugin projects | `PluginHandler.kt` | `initWith`-based copy on new-DSL `BuildType`; app-specific props only when both sides are `ApplicationBuildType` | P3 |
| `BaseExtension` / `getLegacyAndroidExtension` (remaining call sites) | `FlutterPluginUtils.kt` | wrapper accessors incl. `externalNativeBuild` | P4 |
| eager `applicationVariants.configureEach` task creation; mergeAssets/processResources hooks | `FlutterPlugin.kt`, `FlutterPluginUtils.kt` | consolidated `onVariants` block; `CopyFlutterAssetsTask` + `variant.sources.assets.addGeneratedSourceDirectory` | P5 |
| `variant.outputs` + `packageApplicationProvider` + `doLast` APK copy; `versionCodeOverride` | `FlutterPluginUtils.kt` | `CopyFlutterApksTask` (`SingleArtifact.APK` + `BuiltArtifactsLoader`); `VariantOutput.versionCode` set from a `finalizeDsl` snapshot (`DslVersionCodes`) | P6 |
| `libraryVariants.all` × host `applicationVariants.all` cross-wiring | `FlutterPlugin.kt` (add-to-app) | library-side `onVariants` with `Component.debuggable`; no host-project lookup | P7 |
| `android.libraryVariants`; internal `publishing.singleVariants`; module-to-plugin `assembleAar<V>.dependsOn` | `aar_init_script.gradle` | `com.android.library` plugin check; per-variant `singleVariant` that keeps the build file's declaration; plugins publish from the task-name selector | P8 |
| `android.newDsl=false` template/migrator | templates, `disable_new_dsl_migration.dart` | drop from templates; `RemoveNewDslOptOutMigration` | P9 |
| FULL `gradle` artifact dependency | `build.gradle.kts` | `gradle-api` artifact (compile-time proof of zero internal usage) | P10 |

## Phase map

Each phase is one PR-sized change on its own branch. P8 is an independent lane
(Groovy script, disjoint files); P0/P1 are disjoint from each other; everything
else serializes through `FlutterPlugin.kt` / `FlutterPluginUtils.kt`.

| Phase | Branch | Size | Summary |
| --- | --- | --- | --- |
| P0 | `agp-api-doc` | S | this doc + website page draft |
| P1 | `agp-internal-utils` | S | VersionFetcher internal util removal; numeric compileSdk compare; ndkVersion via wrapper |
| P2 | `agp-buildmode-deps` | M | `buildModeFor` overloads; new-DSL flutter dependencies; 9.x compile axis |
| P3 | `agp-plugin-buildtypes` | M | `initWith` copy for plugin build types; drop internal import; internal-import lint |
| P4 | `agp-ndk-fallback` | S | delete `BaseExtension`; externalNativeBuild via wrapper |
| P5 | `agp-assets-onvariants` | L | lazy task registration (5a) + generated-asset-dir wiring (5b) |
| P6 | `agp-apk-copy-versioncode` | L | `CopyFlutterApksTask`; per-ABI versionCode; app path legacy-free |
| P7 | `agp-add-to-app` | L | library-side `onVariants`; delete host cross-wiring + P5a legacy fork |
| P8 | `agp-aar-script` | M | aar_init_script public-API cleanup |
| P9 | `agp-newdsl-flip` | M | templates drop opt-out; removal migrator; new error handlers |
| P10 | `agp-gradle-api` | M | dependency swap to `gradle-api`; test migration |

## Cross-cutting rules

- **R1 Lockstep:** any PR changing FGP-emitted message text updates the
  matching `gradle_errors.dart` matcher and its Dart test in the same PR.
- **R2 Revert notes:** each PR description carries "revert-safe until phase X
  lands"; once superseded, policy is fix-forward. At least one full post-submit
  CI soak between dependent phases (no same-day stacking of P2–P4).
- **R3 9.x axis:** from P2, gradle unit tests additionally compile against
  gradle-api 9.x in CI, plus the javap `CommonExtension` bytecode check.
- **R4 Config-cache:** master baseline established first; the per-phase
  assertion is "no NEW config-cache violations", not full reuse.
- **R5 Internal-import lint:** once P3 lands, a checked-in test forbids
  `com.android.build.gradle.internal.*` imports in `src/main`.
- **R6 Staged newDsl=true axis:** app flows green from end of P6; add-to-app
  from P7; aar from P8. The full matrix is the P9 gate.

## Revert-window table

| Phase | Revert window |
| --- | --- |
| P0 | always revert-safe |
| P1–P4 | each until the next phase in the chain lands; then fix-forward |
| P5 | until P6 lands |
| P6 / P7 | mutually tolerant (disjoint app/module paths) until P10 |
| P8 | revert-safe even after P10, but not after P9 |
| P9 | cleanly revertible in isolation |
| P10 | cleanly revertible in isolation |

## Features that must break (tracked; updated as implementation learns)

1. **User build scripts using legacy APIs** (`applicationVariants.all`
   APK-rename recipes) fail under newDsl — the biggest break. Mitigated by new
   error handlers (P9) and the website page.
2. **flutter-apk copy**: same names/paths (`app[-abi][-flavor]-<mode>.apk`,
   byte-matching the order `listApkPaths` in the Flutter tool expects). `CopyFlutterApksTask`
   (`copyFlutterApks<Variant>`, which `assemble<Variant>` depends on) replaces the
   `doLast` block, so `copyFlutterApks<Variant>` tasks appear in `gradlew tasks`. It reads
   `SingleArtifact.APK` through `BuiltArtifactsLoader`. Its declared outputs are the
   individual APK files rather than the shared `flutter-apk` directory, which would
   overlap between variants. The file names come from the variant's outputs (the APKs
   AGP will build), not from `target-platform`. A single naming function produces both
   the declared outputs and the copied files, and the task fails if AGP built an APK it
   did not declare.
3. **Per-ABI versionCode** (`--split-per-abi`): Flutter sets
   `VariantOutput.versionCode` in its own `onVariants` callback, from the versionCode the
   `android {}` DSL declares for the variant (captured in `finalizeDsl`). It never reads
   `output.versionCode`. AGP runs callbacks in registration order, so for an app that
   applies Flutter in its `plugins {}` block, Flutter's callback runs *before* the app's
   `androidComponents.onVariants` block.
   `ApkVariantOutput.versionCodeOverride`, which this replaces, was applied *after* that
   block. Apps that set `versionCode` only in the `android {}` DSL see no change. Two
   cases change:
   - A versionCode declared only in `AndroidManifest.xml`, with none in the DSL, is not
     offset. `versionCodeOverride` offset the merged value, which included the manifest.
     Flutter's templates set `versionCode = flutter.versionCode` in `defaultConfig`.
   - An app that transforms `output.versionCode` in its own `onVariants` transforms
     Flutter's offset value. For example, an app that multiplies by 10000, built with
     `--build-number 42`:

   | ABI (offset) | Before: `offset * 1000 + 42 * 10000` | After: `(offset * 1000 + 42) * 10000` |
   | --- | --- | --- |
   | `armeabi-v7a` (1) | 421000 | 10420000 |
   | `arm64-v8a` (2) | 422000 | 20420000 |
   | `x86_64` (4) | 424000 | 40420000 |

   In this example the values stay distinct, keep the same ABI order, and only go up, so
   Play Store upgrades keep working. Going back to an earlier Flutter release would make
   them go down. An app that needs the "Before" numbers can compute them from its own base
   instead of from `output.versionCode`, for example
   `output.versionCode.set(offset * 1000 + flutter.versionCode * 10000)` when the base is
   the template's `versionCode = flutter.versionCode` (apps with per-flavor versionCodes
   use the flavor's value). That form also works with AGP's compatibility mode off, where
   reading `output.versionCode` fails.
   No runtime divergence warning is emitted. Flutter cannot tell an intended change in
   the app's `onVariants` (the pattern AGP recommends) from an unintended one, so a
   warning would fire on correct build scripts. Flutter does warn when a split-per-abi
   variant has no DSL versionCode to offset. The snapshot is taken in Flutter's
   `finalizeDsl` callback, so a versionCode change made in a `finalizeDsl` callback
   registered after it (for example in the app's build script) is not seen: Flutter offsets
   the value from before that change.
4. **Custom build types → plugins**: live-aliased instances become `initWith`
   copies; library plugins cannot receive `isDebuggable` (no public setter on
   `LibraryBuildType`). **Warning:** If an app uses a custom build type (like `staging`),
   the plugin's `BuildConfig.DEBUG` and native (C++/JNI) code may silently compile
   in release mode instead of debug mode. Matching is preserved via `matchingFallbacks`,
   but C++ debugging will be broken for those custom build types.
5. **Asset merge**: flutter assets become a merged source dir instead of a
   post-merge overwrite; collisions resolve by AGP source-set priority.
6. **Add-to-app**: the module registers its Flutter tasks in its own `onVariants` and
   adds the staged assets and native libraries as generated source directories of each
   library variant. The host consumes them like any Android library's, so the
   host-project lookup, the `libraryVariants` × host `applicationVariants` loop and the
   `:app:merge<V>Assets.dependsOn` edge are removed.
   - `flutter.hostAppProjectName` has no effect; setting it logs a warning that names no
     removal milestone.
   - Every module variant is configured whatever the command line names, because the
     host's `matchingFallbacks`, not the task name, decide which module variant a host
     task consumes. Registration is lazy, so only that variant runs. Cost: a host build
     of only `assemble<Variant>AndroidTest` runs the module's `flutter assemble`.
   - The build mode comes from the consumed module variant, not the host build type. A
     debuggable host build type that falls back to the module's `release` gets release
     artifacts. Built as the only task, the deleted code ran the module's debug Flutter
     build for it, and the APK had no `flutter_assets` and no `libapp.so`.
   - Module assets are a generated source directory (item 5), and `copyFlutterAssets<V>`
     is a `CopyFlutterAssetsTask` (item 7).
7. **Task realization/type**: flutter tasks become lazy `TaskProvider`s, and
   `copyFlutterAssets<V>` changes type from `org.gradle.api.tasks.Copy` to a
   custom task class — `tasks.named(..., Copy::class)` casts fail.
8. **`flutter build aar`**: Flutter declares `singleVariant` publishing (with sources and
   javadoc jars) for each variant of the module and of each Android plugin. For a variant that
   the project's build file declares, the build file's declaration wins. The requested variant
   must exist in the module and in each Android plugin; otherwise the build fails, and the fix
   is to build a variant that all of them declare (`--flavor`, matching product flavors).
9. **newDsl flip**: new projects lose the opt-out; the removal migrator deletes
   only marker-tagged `android.newDsl` lines (template marker "This newDsl flag
   was added by the Flutter template"; migrator marker "This newDsl flag was
   added automatically by Flutter migrator"), anchored on the property line so
   the adjacent builtInKotlin lines are never touched; hand-added opt-outs are
   respected.
10. **compileSdk mismatch warning** becomes a numeric compare with defined
    preview-vs-numeric semantics; the message keeps a distinctive substring of
    the old phrasing for searchability.

## Verification matrix

Full matrix at P6, P7, P9, P10; targeted per-phase otherwise.

1. `cd packages/flutter_tools/gradle && ./gradlew test` (+ the R3 9.x axis)
2. Targeted `integration.shard` tests named in each phase
3. Scratch-app matrix: apk/appbundle × 3 modes; `--flavor`; `--split-per-abi`
   (+ apkanalyzer versionCode assertions, including the
   flavor-defined-versionCode case); `--deferred-components`; plugin with a
   custom build type; `flutter build aar`; add-to-app source & AAR host flows;
   `flutter run` / hot restart / `flutter attach`; Windows smoke for the copy
   tasks
4. AGP axis: current floor AND 9.1 + `newDsl=false`; staged `newDsl=true` per R6
5. Config-cache per R4
