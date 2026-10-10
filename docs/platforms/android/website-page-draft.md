# Android builds use the new Android Gradle Plugin DSL and Variant APIs

*Draft breaking-change page for `docs.flutter.dev/release/breaking-changes/`.
This file is the source of truth until the page is published to
flutter/website; publishing must complete before the newDsl flip reaches the
beta channel. Contributor-facing details live in
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
by the separate built-in-Kotlin migration (tracked in
[flutter/flutter#184836](https://github.com/flutter/flutter/issues/184836)),
which means one more (smaller) `gradle.properties` change later.

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
// Note: androidComponents is a top-level block, peer to android {}
androidComponents {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            // WARNING: VariantOutput in the new API does not have an outputFileName property.
            // You cannot mutate the filename here.
        }
    }
}
```

For output *file* renames, you must copy or rename the built APKs using a Gradle task.
(Note: Flutter's own copy step already places APKs at `build/app/outputs/flutter-apk/app[-abi][-flavor]-<mode>.apk` with unchanged names and paths.)

Example of a simple finalizer task in `build.gradle` (Groovy):
```groovy
androidComponents {
    onVariants(selector().all()) { variant ->
        def copyTask = tasks.register("copy${variant.name.capitalize()}Apk", Copy) {
            from(variant.artifacts.get(com.android.build.api.artifact.SingleArtifact.APK.INSTANCE))
            into(layout.buildDirectory.dir("custom-outputs"))
            rename { String fileName -> fileName.replace("app", "myapp") }
        }
        tasks.matching { it.name == "assemble${variant.name.capitalize()}" }.configureEach {
            dependsOn(copyTask)
        }
    }
}
```

Flutter's copy step reads the APK artifact (`SingleArtifact.APK`) and its
`output-metadata.json` file. If a plugin or your build script transforms that
artifact, the transform must keep the metadata and the APKs' ABI filters:

- Use `toTransformMany(SingleArtifact.APK)` with
  `ArtifactTransformationRequest`, which writes the metadata for you, or write
  it with `BuiltArtifacts.save()` from a `toTransform` task.
- Produce one APK for each variant output, with the same ABI filter.

Otherwise the build fails with a Flutter error that names `SingleArtifact.APK`.
Fix the transform, or contact the maintainer of the plugin that does it.
Plugins that only read the APK, or that write extra APKs elsewhere after
`assemble`, are not affected.

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
import com.android.build.api.variant.FilterConfiguration

androidComponents {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            val abi = output.filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier
            output.versionCode.set((abiCodes[abi] ?: 0) * 1000 + flutter.versionCode)
        }
    }
}
```

Compute the value from a base you already know rather than by reading
`output.versionCode`. AGP disallows reading `output.versionCode` during
configuration when its compatibility mode
(`android.compatibility.enableLegacyApi`) is off. `flutter.versionCode` is the
value Flutter's templates set in `defaultConfig`. If your product flavors set
their own `versionCode`, use the flavor's value for those variants.

Note: For `--split-per-abi` builds, Flutter sets per-ABI version codes
(`abiOffset * 1000 + versionCode`, with offsets 1 for `armeabi-v7a`, 2 for
`arm64-v8a`, and 4 for `x86_64`) in its own `onVariants` callback. It takes
`versionCode` from your `android {}` block (`defaultConfig` or a product
flavor). A versionCode set only in `AndroidManifest.xml` is not offset.
When the Flutter plugin is applied in the `plugins {}` block, as in Flutter's
templates, that callback runs before an `androidComponents.onVariants` block
in your app's build script, and a value your block sets replaces Flutter's.
Flutter releases that set `versionCodeOverride` applied the offset after your
block, so if your block derives `versionCode` from Flutter's value, the result
differs from those releases. For example, multiplying by 10000 with
`--build-number 42` gives `arm64-v8a` the versionCode `20420000`, where those
releases gave `422000`. To keep the `422000`-style numbers, set the value from
`flutter.versionCode` instead:

```kotlin
import com.android.build.api.variant.FilterConfiguration

val flutterAbiOffsets = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 4)

androidComponents {
    onVariants(selector().all()) { variant ->
        variant.outputs.forEach { output ->
            val abi = output.filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier
            val offset = flutterAbiOffsets[abi] ?: 0
            output.versionCode.set(offset * 1000 + flutter.versionCode * 10000)
        }
    }
}
```

To verify the result, inspect the built APK:
`apkanalyzer manifest print versionCode build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Custom build types and plugins

Flutter copies your app's custom build types onto Flutter plugin projects so
they resolve. With the new DSL these are `initWith` copies rather than live
aliases:

- Set `matchingFallbacks` on custom build types so dependent Android libraries
  resolve. If a third-party plugin does not define your app's custom `staging`
  build type, AGP needs to know to safely fall back to compiling the plugin's
  `debug` variant rather than failing the build. For example:

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

- **Warning for Plugin Authors / JNI Developers:** Library (plugin) projects cannot
  be explicitly marked debuggable through the public AGP API. If an app uses a
  custom build type (like `staging`), the plugin's `BuildConfig.DEBUG` and native (C++/JNI)
  code may silently compile in release mode instead of debug mode. Variant matching
  still works via `matchingFallbacks`, but C++ debugging will be broken for those
  custom build types.

### Add-to-app (Flutter module in a host app)

- The Flutter module adds its assets and native libraries to its own variants
  through the Variant API. Your host app consumes them like the assets of any
  Android library. Flutter does not look up or configure the host `:app`
  project, and adds no `merge<Variant>Assets.dependsOn(...)` edge to it.
- `flutter.hostAppProjectName` in `gradle.properties` has no effect. If it is
  set, Flutter prints a warning that says so. You can remove it.
- The Flutter module's `copyFlutterAssets<Variant>` tasks are of type
  `CopyFlutterAssetsTask`, not `org.gradle.api.tasks.Copy`. Build scripts that
  look them up with the `Copy` type fail.
- The Flutter build mode comes from the module variant your host build
  consumes: the module's `debug` variant builds debug Flutter artifacts,
  `profile` builds profile, and `release` builds release. Host `debug`,
  `profile` and `release` build types consume the module variant of the same
  name. For a custom host build type, AGP picks the module variant through the
  build type's `matchingFallbacks`, so list the module build type you want
  first:

  ```kotlin
  create("staging") {
      initWith(getByName("debug"))
      matchingFallbacks += listOf("debug", "release") // staging gets debug Flutter artifacts
  }
  ```

### Flutter plugin authors

- Do not read `android.applicationVariants` / `android.libraryVariants` in
  plugin build scripts; use `androidComponents.onVariants`. (We are tracking
  an audit of the top 200 plugins for this legacy usage in
  [flutter/flutter#190845](https://github.com/flutter/flutter/issues/190845)).
- Do not assume Flutter's tasks exist at configuration time or have specific
  types; look up tasks lazily (`tasks.named`) without a type, or better, wire
  through Variant API artifacts.
- Test your plugin's example app with AGP 9+ **without** `android.newDsl=false`.

### `flutter build aar`

- If your module's or a plugin's build file declares
  `android.publishing.singleVariant(...)` for a variant, Flutter uses that
  declaration for that variant and declares publishing (with sources and javadoc
  jars) for the other variants.
- The variant you build must exist in the module and in each Android plugin
  that it uses. If it doesn't, the build fails. Build a variant that all of them
  declare: pass `--flavor` for a module with product flavors, and use plugins
  that declare the same product flavors as the module.

## Escape hatch (temporary)

If you cannot migrate immediately, add the opt-out by hand to
`android/gradle.properties`:

```properties
android.newDsl=false
```

**AGP 10 is expected to remove the legacy APIs**, meaning this opt-out will
stop working. Treat it as a short-term unblock only; hand-added opt-outs are
never touched by Flutter's migrator.

## References

- AGP 9 release notes (new DSL):
  https://developer.android.com/build/releases/agp-9-0-0-release-notes
- Flutter umbrella issues:
  [flutter/flutter#180137](https://github.com/flutter/flutter/issues/180137),
  [flutter/flutter#166550](https://github.com/flutter/flutter/issues/166550)
