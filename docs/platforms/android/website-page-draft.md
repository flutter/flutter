# Android builds use the new Android Gradle Plugin DSL and Variant APIs

*Draft breaking-change page for `docs.flutter.dev/release/breaking-changes/`.
This file is the source of truth until the page is published to
flutter/website; publishing must complete before the newDsl flip reaches the
beta channel. The page MUST be published at
`https://docs.flutter.dev/release/breaking-changes/android-agp-new-dsl` —
that URL is hard-coded as `kNewDslBreakingChangeDocsUrl` in
`packages/flutter_tools/lib/src/android/gradle_errors.dart` and is printed by
the legacy-variant-API error handler and the opt-out removal migrator.
Contributor-facing details live in
[Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md](Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md).*

## Summary

The Flutter Gradle Plugin now uses only the public Android Gradle Plugin (AGP)
API, and new and migrated Flutter projects build with AGP's new DSL enabled
(`android.newDsl` is no longer set to `false` by Flutter). Gradle build
scripts that use the legacy AGP APIs — most commonly
`android.applicationVariants` — fail to configure and must be migrated to the
AGP Variant API.

## Background

AGP 9 deprecated the legacy DSL and Variant APIs behind the
`android.newDsl=false` flag. AGP 10 removes them entirely. Flutter previously
added `android.newDsl=false` to your `gradle.properties` (via the project
templates and an automatic migration) to keep legacy builds working. That
opt-out stops working with AGP 10, so Flutter has migrated its own Gradle
plugin to the public API and removed the opt-out from templates. A migration
now *removes* the opt-out lines that Flutter previously added — it only touches
lines carrying Flutter's marker comments, and prints a message when it does.
Opt-outs you added by hand are left alone.

`android.builtInKotlin=false` is **not** affected by this change. It is owned
by the separate built-in-Kotlin migration (tracked in <!-- TODO: link
built-in-Kotlin tracking issue -->), which means one more (smaller)
`gradle.properties` change later.

## Migration guide

### Renaming APKs (`applicationVariants.all`)

Before:

```groovy
android {
    applicationVariants.all { variant ->
        variant.outputs.all { output ->
            outputFileName = "myapp-${variant.versionName}.apk"
        }
    }
}
```

After (Variant API, `build.gradle` / `build.gradle.kts`):

```kotlin
androidComponents {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            // Use variant.name / output.filters and your own naming scheme.
        }
    }
}
```

For output *file* renames, prefer consuming the built APKs from
`SingleArtifact.APK` with a task wired through
`variant.artifacts.use(...)`, or copy/rename in a finalizer task. Flutter's
own copy step already places APKs at
`build/app/outputs/flutter-apk/app[-abi][-flavor]-<mode>.apk` with unchanged
names and paths.

### Setting per-ABI or per-variant versionCode

Before:

```groovy
android.applicationVariants.all { variant ->
    variant.outputs.each { output ->
        output.versionCodeOverride = abiCodes.get(output.getFilter(OutputFile.ABI)) * 1000 + variant.versionCode
    }
}
```

After:

```kotlin
androidComponents {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            val abi = output.filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier
            val base = output.versionCode.get() ?: 1
            output.versionCode.set((abiCodes[abi] ?: 0) * 1000 + base)
        }
    }
}
```

Note: Flutter itself sets per-ABI version codes for `--split-per-abi` inside
`onVariants`. If your CI mutates version codes in `afterEvaluate`, that runs at
a different time than before; Flutter prints a warning when it detects a
divergence between the DSL value and the final output value.

### Custom build types and plugins

Flutter copies your app's custom build types onto Flutter plugin projects so
they resolve. With the new DSL these are `initWith` copies rather than live
aliases:

- Set `matchingFallbacks` on custom build types so dependent Android libraries
  resolve, for example:

  ```kotlin
  android {
      buildTypes {
          create("staging") {
              initWith(getByName("debug"))
              matchingFallbacks += listOf("debug", "release")
          }
      }
  }
  ```

- Library (plugin) projects cannot be marked debuggable through the public
  API, so a plugin's `BuildConfig.DEBUG` and native (JNI) debuggability can
  differ from before for custom *debuggable* build types. Variant matching
  still works via `matchingFallbacks`.

### Add-to-app (Flutter module in a host app)

- Flutter no longer looks up or configures the host `:app` project from the
  module. The dependency between your host's asset merging and Flutter's asset
  copy is expressed through the Variant API instead of an explicit
  `merge<Variant>Assets.dependsOn(...)` edge. Build scripts that reference
  Flutter's `copyFlutterAssets<Variant>` tasks by name or type may break: the
  tasks are now registered lazily and are no longer of type
  `org.gradle.api.tasks.Copy`.
- `flutter.hostAppProjectName` in `gradle.properties` is now a no-op. Flutter
  prints a deprecation warning naming the removal milestone. It was only used
  for the host-project lookup, which no longer exists.
- Flutter maps host build types to Flutter build modes using the public
  "debuggable" flag: `profile` stays `profile`, debuggable build types map to
  `debug`, everything else maps to `release`. If your host has no `profile`
  build type, add `matchingFallbacks`:

  ```kotlin
  create("staging") {
      initWith(getByName("debug"))
      isDebuggable = true            // staging gets debug Flutter artifacts
      matchingFallbacks += listOf("debug", "release")
  }
  ```

### Flutter plugin authors

- Do not read `android.applicationVariants` / `android.libraryVariants` in
  plugin build scripts; use `androidComponents.onVariants`.
- Do not assume Flutter's tasks exist at configuration time or have specific
  types; look tasks up lazily (`tasks.named`) without a type, or better, wire
  through Variant API artifacts.
- Test your plugin's example app with AGP 9+ **without** `android.newDsl=false`.

### `flutter build aar`

Variant enumeration for AAR builds now uses the public `components` API. If
your module's build script declares `singleVariant(...)` publishing itself,
Flutter detects the overlap and reports it with an actionable error instead of
failing inside AGP.

## Escape hatch (temporary)

If you cannot migrate immediately, add the opt-out by hand to
`android/gradle.properties`:

```properties
android.newDsl=false
```

**This stops working with AGP 10** (removal of the legacy APIs). Treat it as a
short-term unblock only; hand-added opt-outs are never touched by Flutter's
migrator.

## Timeline

Landed in version: TBD<br>
In stable release: TBD

## References

- AGP 9 release notes (new DSL):
  https://developer.android.com/build/releases/agp-9-0-0-release-notes
- Flutter umbrella issues:
  [flutter/flutter#180137](https://github.com/flutter/flutter/issues/180137),
  [flutter/flutter#166550](https://github.com/flutter/flutter/issues/166550)
