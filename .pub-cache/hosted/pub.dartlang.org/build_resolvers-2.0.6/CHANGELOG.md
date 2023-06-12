## 2.0.6

- Allow the latest analyzer.

## 2.0.5

- Consider files without a `.dart` extension as not Dart libraries. Previously
  the `isLibrary` getter was behaving like `isNotDartPartFile` which included
  many assets that weren't Dart at all. This is potentially breaking if any
  builders were intentionally resolving files with different extensions, but
  will give a more predictable result for the majority of cases.
- Update usages of deprecated analyzer apis.
- Require at least analyzer `2.1.0`.
- Support upcoming analyzer changes to `UriResolver`.

## 2.0.4

- Allow analyzer version 2.x.x.

## 2.0.3

- Fix an issue where the build process would hang if the resolver fails to
  properly initialize.

## 2.0.2

- Add more context to the outdated analyzer version message. It now provides
  different suggestions depending on if you are on the latest analyzer.

## 2.0.1

- Update to allow package:graphs 2.0.0.

## 2.0.0

- Migrate to null-safety
- Update to build `2.x`.

## 1.5.4

- Allow analyzer 1.0.0.

## 1.5.3

- Allow the null safe pre-release of `package_config`.

## 1.5.2

- Allow the null safe pre-releases of all migrated deps.

## 1.5.1

- Fix a potential nullability issue in the `astNodeFor` api.

## 1.5.0

- Support the latest `build` package (`1.6.x`).
  - Implements the new `Future<AstNode> astNodeFor(Element, {bool resolve})`
    method.

## 1.4.4

- Allow the latest analyzer verion `0.41.x`.

## 1.4.3

- Change the error to a warning when enabling experiments with mismatched
  analyzer/sdk versions since this will still work for experiments with release
  versions (such as null safety).

## 1.4.2

- Fix a bug around assets that appear missing to the analyzer even when they
  should be visible to the build step using the resolver.

## 1.4.1

- Update the exception thrown when using experiments without an exactly
  matching analyzer version to instead ensure that the sdk version is not
  ahead of the analyzer version.

## 1.4.0

- Support versions `1.5.x` of the `build` package.
  - Implements the `compilationUnitFor` method on `Resolver`.

## 1.3.11

- Use the public `buildSdkSummary` api from the analyzer instead of the
  private one.
- Migrate off of other deprecated analyzer apis.

## 1.3.10

- Migrate to new analyzer API for creating an SDK summary after the old approach
  was broken.

## 1.3.9

- Fix `isLibrary` for unreadable assets to return `false`.
- Fix `libraryFor` to do an explicit `canRead` check and throw an
  `AssetNotFound` exception if it cannot be read.

## 1.3.8

- Enables the `non-nullable` experiment when summarizing the SDK, see
  https://github.com/dart-lang/sdk/issues/41820.
- Reverts the `enableExperiments` option on `AnalyzerResolvers`.
  - To enable experiments you should instead run your code in an experiment
    Zone using the `withEnabledExperiments` function from
    `package:build/experiments.dart`.

## 1.3.7

- Pass an explicit `FeatureSet` to the analyzer based on the current sdk
  version.
- ~Add an extra option `enableExperiments` to `AnalyzerResolvers`.~
  - This was reverted in `1.3.8` and replaced with a different mechanism.
- Added a warning if the current analyzers language version does not support
  the current SDK language version.

## 1.3.6

- Fix bug when a package has no language version (as a result of having no sdk
  constraint).

## 1.3.5

- Create and pass a correct `Packages` argument to analysis driver, this
  enables getting the proper language version for a given `LibraryElement`
  using the `languageVersionMajor` and `languageVersionMinor` getters.

## 1.3.4

- Remove dependency on `package_resolver`.
- Add new required `featureSet` argument to `SummaryBuilder.build` call.

## 1.3.3

- Fix an issue where non-existing Dart assets weren't visible to the analyzer, even
  when they are created later.

## 1.3.2

- Improve detection of the flutter SDK for older flutter versions.

## 1.3.1

- Add an exception on trying to resolve an `AssetId` that is not a Dart
  library with `libraryFor` to fit the contract expressed by the doc comment on
  `Resolver`.

## 1.3.0

### New feature

You can now resolve additional libraries other than those imported by the
primary entrypoint.

  - This is supported through the `isLibrary` and `libraryFor` methods on
    `Resolver`, which will now resolve the provided asset if it is not already
    resolved.
  - **Note**: Doing this may affect the result of subsequent calls to
    `resolver.libraries` and `resolver.findLibraryByName` if new libraries are
    discovered.

**Note**: If using `build_runner` then this will also require you to upgrade
to version `4.2.0` of `build_runner_core` .

### Other

- Changed a `hide` declaration to a `show` declaration to support a
`package:analyzer` change.

## 1.2.2

- Update to `package:analyzer` version `0.39.0`.

## 1.2.1

Check the build_resolvers version as a part of sdk summary invalidation.

## 1.2.0

Add flutters embedded sdk to the summary if available. This has the effect of
making `dart:ui` and any future libraries available if using the flutter sdk
instead of the dart sdk.

## 1.1.1

### Bug Fix

Check the analyzer path before reading cached summaries in addition to the
SDK version.

## 1.1.0

### Bug Fix: #38499

Update the `AnalysisResolvers` class to no longer use the SDK summary that is
shipped with the SDK by default. This is not guaranteed compatible with
analyzer versions shipped on pub and should not be used by any non-sdk code.

In order to fix this the `AnalysisResolvers` class now takes an optional method
that returns the path to an arbitrary SDK summary. By default it will lazily
generate a summary under `.dart_tool/build_resolvers` which is invalidated
based on the `Platform.version` from `dart:io`.

## 1.0.8

- Allow `build` version 1.2.x.

## 1.0.7

- Allow analyzer version 0.38.0.

## 1.0.6

- Allow analyzer version 0.37.0.

## 1.0.5

- Fix a race condition where some assets may be resolved with missing
  dependencies. This was likely to have only manifested in tests using
  `resolveSource`.

## 1.0.4

- Increase lower bound sdk constraint to 2.1.0.
- Increased the upper bound for `package:analyzer` to `<0.37.0`.

## 1.0.3

- Fixes a bug where transitive `dart-ext:` imports would cause the resolver
  to fail. These uris will now be ignored.

## 1.0.2

- Ensure that `BuildAssetUriResolver.restoreAbsolute` never returns null.
  - Fixes a crash when a resolver is requested but not all transitive sources
    are available yet.

## 1.0.1

- Fix a bug causing crashes on windows.

## 1.0.0

- Migrate to `AnalysisDriver`. There are behavior changes which may be breaking.
  The `LibraryElement` instances returned by the resolver will now:
  - Have non-working `context` fields.
  - Have no source offsets for annotations or their errors.
  - Have working `session` fields.
  - Have `Source` instances with different URIs than before.
  - Not include missing libraries in the `importedLibraries` getter. You can
    instead use the `imports` getter to see all the imports.

## 0.2.3

- Update to `build` `1.1.0` and add `assetIdForElement`.

## 0.2.2+7

- Updated _AssetUriResolver to prepare for a future release of the analyzer.
- Increased the upper bound for `package:analyzer` to `<0.35.0`.

## 0.2.2+6

- Increased the upper bound for `package:analyzer` to `<0.34.0`.

## 0.2.2+5

- Increased the upper bound for the `build` to `<1.1.0`.

## 0.2.2+4

- Removed dependency on cli_util.
- Increased the upper bound for the `build` to `<0.12.9`.

## 0.2.2+3

- Don't log a severe message when a URI cannot be resolved. Just return `null`.

## 0.2.2+2

- Use sdk summaries for the analysis context, which makes getting the initial
  resolver faster (reapplied).

## 0.2.2+1

- Restore `new` keyword for a working release on Dart 1 VM.

## 0.2.2

- Use sdk summaries for the analysis context, which makes getting the initial
  resolver faster.
- Release broken on Dart 1 VM.

## 0.2.1+1

- Increased the upper bound for the sdk to `<3.0.0`.

## 0.2.1

- Allow passing in custom `AnalysisOptions`.

## 0.2.0+2

- Support `package:analyzer` `0.32.0`.

## 0.2.0+1

- Switch to `firstWhere(orElse)` for compatibility with the SDK dev.45

## 0.2.0

- Removed locking between uses of the Resolver and added a mandatory `reset`
  call to indicate that a complete build is finished.

## 0.1.1

- Support the latest `analyzer` package.

## 0.1.0

- Initial release as a migration from `code_transformers` with a near-identical
  implementation.
