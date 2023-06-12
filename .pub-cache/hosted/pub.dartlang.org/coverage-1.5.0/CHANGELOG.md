## 1.5.0

* Support passing extra arguments to `test_with_coverage` which are then passed
  to `package:test`.

  Example: `dart run coverage:test_with_coverage -- --preset CI`


## 1.4.0 - 2022-6-16

* Added `HitMap.parseJsonSync` which takes a cache of ignored lines which can
  speedup calls when `checkIgnoredLines` is true and the function is called
  several times with overlapping files in the input json.
* Bump the version of vm_service to 9.0.0.

## 1.3.2

* Fix test_with_coverage listening to an unsupported signal on windows.
* Fix `--reportOn` on windows using incorrect path separators.

## 1.3.1

* Fix running `dart pub global run coverage:test_with_coverage` or 
  `dart run coverage:test_with_coverage`

## 1.3.0 - 2022-5-11

* Bump the minimum Dart SDK version to 2.15.0
* Add a `--package` flag, which takes the package's root directory, instead of
  the .package file. Deprecate the `--packages` flag.
* Deprecate the packagesPath parameter and add packagePath instead, in
  `HitMap.parseJson`, `HitMap.parseFiles`, `createHitmap`, and `parseCoverage`.
* Add a new executable to the package, `test_with_coverage`. This simplifies the
  most common use case of coverage, running all the tests for a package, and
  generating an lcov.info file.
* Use the `libraryFilters` option in `getSourceReport` to speed up coverage runs
  that use `scopedOutput`.

## 1.2.0 - 2022-3-24

* Support branch level coverage information, when running tests in the Dart VM.
  This is not supported for web tests yet.
* Add flag `--branch-coverage` (abbr `-b`) to collect_coverage that collects
  branch coverage information. The VM must also be run with the
  `--branch-coverage` flag.
* Add flag `--pretty-print-branch` to format_coverage that works
  similarly to pretty print, but outputs branch level coverage, rather than
  line level.
* Update `--lcov` (abbr `-l`) in format_coverage to output branch level
  coverage, in addition to line level.
* Add an optional bool flag to `collect` that controls whether branch coverage
  is collected.
* Add a `branchHits` field to `HitMap`.
* Add support for scraping the service URI from the new Dart VM service message.
* Correctly parse package_config files on Windows when the root URI is relative.

## 1.1.0 - 2022-1-18

* Support function level coverage information, when running tests in the Dart
   VM. This is not supported for web tests yet.
* Add flag `--function-coverage` (abbr `-f`) to collect_coverage that collects
  function coverage information.
* Add flag `--pretty-print-func` (abbr `-f`) to format_coverage that works
  similarly to pretty print, but outputs function level coverage, rather than
  line level.
* Update `--lcov` (abbr `-l`) in format_coverage to output function level
  coverage, in addition to line level.
* Add an optional bool flag to `collect` that controls whether function coverage
  is collected.
* Added `HitMap.parseJson`, `FileHitMaps.merge`, `HitMap.parseFiles`,
  `HitMap.toJson`, `FileHitMapsFormatter.formatLcov`, and
  `FileHitMapsFormatter.prettyPrint` that switch from using `Map<int, int>` to
  represent line coverage to using `HitMap` (which contains both line and
  function coverage). Document the old versions of these functions as
  deprecated. We will delete the old functions when we update to coverage
  version 2.0.0.
* Ensure `createHitmap` returns a sorted hitmap. This fixes a potential issue with
  ignore line annotations.
* Use the `reportLines` flag in `vm_service`'s `getSourceReport` RPC. This
  typically halves the number of RPCs that the coverage collector needs to run.
* Require Dart `>=2.14.0`

## 1.0.4 - 2021-12-20

* Updated dependency on `vm_service` package from `>=6.1.0 <8.0.0`to `>=8.1.0
  <9.0.0`.

## 1.0.3 - 2021-05-25

* Updated dependency on `vm_service` package from `^6.1.0` to `>=6.1.0 <8.0.0`.

## 1.0.2 - 2021-03-15

* Fix an issue where the `--packages` argument wasn't passed to `format_coverage`.

## 1.0.1 - 2021-02-25

* Allow the chrome `sourceUriProvider` to return `null`.

## 1.0.0 - 2021-02-25

* Migrate to null safety.
* Removed support for SDK `1.x.x`.

## 0.15.2 - 2021-02-08

* Update `args`, `logging`, and `package_config` deps to allow the latest
  stable releases.

## 0.15.1 - 2021-01-14

* Updated dependency on `vm_service` package from `>=1.0.0 < 5.0.0` to `>=1.0.0 <7.0.0`.

## 0.15.0 - 2021-01-13

* BREAKING CHANGE: Eliminate the `--package-root` option from
  `bin/run_and_collect.dart` and `bin/format_coverage.dart` as well as
  from `runAndCollect` and the `Resolver` constructor.

## 0.14.2 - 2020-11-10

* Fix an issue where `--wait-paused` with `collect` would attempt to collect coverage
  if no isolates have started.

## 0.14.1 - 2020-09-10

* Updated dependency on `vm_service` package from `>=1.0.0 < 5.0.0` to `>=1.0.0 <6.0.0`.

## 0.14.0 - 2020-06-04

* Add flag `--check-ignore` that is used to ignore lines from coverage
  depending on the comments.

  Use // coverage:ignore-line to ignore one line.
  Use // coverage:ignore-start and // coverage:ignore-end to ignore range of lines inclusive.
  Use // coverage:ignore-file to ignore the whole file.

## 0.13.11 - 2020-06-04

* Revert breaking change in 13.10

## 0.13.10 - 2020-06-03

* Add flag `--check-ignore` that is used to ignore lines from coverage
  depending on the comments.

  Use // coverage:ignore-line to ignore one line.
  Use // coverage:ignore-start and // coverage:ignore-end to ignore range of lines inclusive.
  Use // coverage:ignore-file to ignore the whole file.

## 0.13.9 - 2020-03-09

* Don't crash on empty JSON input files.
* Loosen the dependency on the `vm_service` package from `>=1.0.0 <4.0.0` to
`>=1.0.0 <5.0.0`.

## 0.13.8 - 2020-03-02

* Update to package_config `1.9.0` which supports package_config.json
  files and should be forwards compatible with `2.0.0`.
* Deprecate the `packageRoot` argument on `Resolver`.

## 0.13.7 - 2020-02-28

* Loosen the dependency on the `vm_service` package from `>=1.0.0 <3.0.0` to
`>=1.0.0 <4.0.0`.

## 0.13.6 - 2020-02-10

* Now consider all `.json` files for the `format_coverage` command.

## 0.13.5 - 2020-01-30

* Update `parseChromeCoverage` to merge coverage information for a given line.
* Handle source map parse errors in `parseChromeCoverage`. Coverage will not be
  considered for Dart files that have corresponding invalid source maps.

## 0.13.4 - 2020-01-23

* Add `parseChromeCoverage` for creating a Dart based coverage report from a
  Chrome coverage report.

## 0.13.3+3 - 2019-12-03

* Re-loosen the dependency on the `vm_service` package from `>=1.0.0 < 2.1.2`
  to `>=1.0.0 <3.0.0` now that breakage introduced in version `2.1.2` has been
  resolved. Fixed in:
  https://github.com/dart-lang/sdk/commit/7a911ce3f1e945f2cbd1967c6109127e3acbab5a.

## 0.13.3+2 - 2019-12-02

* Tighten the dependency on the `vm_service` package from `>=1.0.0 <3.0.0` down
  to `>=1.0.0 <2.1.2` in order to exclude version `2.1.2` which is broken on
  the current stable Dart VM due to a missing SDK constraint in its pubspec.yaml.
  The breakage was introduced in: https://github.com/dart-lang/sdk/commit/9e636b5ab4de850fb19bc262e0686fdf14bfbfc0.

## 0.13.3+1 - 2019-10-10

* Loosen the dependency on the `vm_service` package from `^1.0.0` to `>=1.0.0
  <3.0.0`. Ensures dependency version range compatibility with the latest
  versions of package `test`.

## 0.13.3 - 2019-09-27

 * Adds a new named argument to `collect` to filter coverage results by a set
   of VM isolate IDs.
 * Migrates implementation of VM service protocol library from
   `package:vm_service_lib`, which is no longer maintained, to
   `package:vm_service`, which is.

## 0.13.2 - 2019-07-18

 * Add new multi-flag option `--scope-output` which restricts coverage output
   so that only scripts that start with the provided path are considered.

## 0.13.1 - 2019-07-18

 * Handle scenario where the VM returns empty coverage information for a range.

## 0.13.0 - 2019-07-10

 * BREAKING CHANGE: Skips collecting coverage for `dart:` libraries by default,
   which provides a significant performance boost. To restore the previous
   behaviour and collect coverage for these libraries, use the `--include-dart`
   flag.
 * Disables WebSocket compression for coverage collection. Since almost all
   coverage collection runs happen over the loopback interface to localhost,
   this improves performance and reduces CPU usage.
 * Migrates implementation of VM service protocol library from
   `package:vm_service_client`, which is no longer maintained, to
   `package:vm_service_lib`, which is.

## 0.12.4 - 2019-01-11

 * `collect()` now immediately throws `ArgumentError` if a null URI is passed
   in the `serviceUri` parameter to avoid a less-easily debuggable null
   dereference later. See dart-lang/coverage#240 for details.

## 0.12.3 - 2018-10-19

 * Fixed dart-lang/coverage#194. During collection, we now track each script by
   its (unique) VMScriptRef. This ensures we look up the correct script when
   computing the affected line for each hit token. The hitmap remains URI
   based, since in the end, we want a single, unified set of line to hitCount
   mappings per script.

## 0.12.2 - 2018-07-25

 * Dart SDK upper bound raised to <3.0.0.

## 0.12.1 - 2018-06-26

 * Minor type, dartfmt fixes.
 * Require package:args >= 1.4.0.

## 0.12.0 - 2018-06-26

 * BREAKING CHANGE: This version requires Dart SDK 2.0.0-dev.64.1 or later.
 * Strong mode fixes as of Dart SDK 2.0.0-dev.64.1.

## 0.11.0 - 2018-04-12

 * BREAKING CHANGE: This version requires Dart SDK 2.0.0-dev.30 or later.
 * Updated to Dart 2.0 constants from dart:convert.

## 0.10.0 - 2017-12-14

 * BREAKING CHANGE: `createHitmap` and `mergeHitmaps` now specify generic types
   (`Map<String, Map<int, int>>`) on their hit map parameter/return value.
 * Updated package:args dependency to 1.0.0.

## 0.9.3 - 2017-10-02

 * Strong mode fixes as of Dart SDK 1.24.0.
 * Restrict the SDK lower version constraint to `>=1.21.0`. Required for method
   generics.
 * Eliminate dependency on package:async.

## 0.9.2 - 2017-02-03

 * Strong mode fixes as of Dart SDK 1.22.0.

## 0.9.1 - 2017-01-18

 * Temporarily add back support for the `--host` and `--port` options to
   `collect_coverage`. This is a temporary measure for backwards-compatibility
   that may stop working on Dart SDKs >= 1.22. See the related
   [breaking change note](https://groups.google.com/a/dartlang.org/forum/#!msg/announce/VxSw-V5tx8k/wPV0GfX7BwAJ)
   for the Dart VM service protocol.

## 0.9.0 - 2017-01-11

 * BREAKING CHANGE: `collect` no longer supports the `host` and `port`
   parameters. These are replaced with a `serviceUri` parameter. As of Dart SDK
   1.22, the Dart VM will emit Observatory URIs that include an authentication
   token for security reasons. Automated tools will need to scrape stdout for
   this URI and pass it to `collect_coverage`.
 * BREAKING CHANGE: `collect_coverage`: the `--host` and `--port` options have
   been replaced with a `--uri` option. See the above change for details.
 * BREAKING CHANGE: `runAndCollect` now defaults to running in checked mode.
 * Added `extractObservatoryUri`: scrapes an input string for an Observatory
   URI. Potentially useful for automated tooling after Dart SDK 1.22.

## 0.8.1

 * Added optional `checked` parameter to `runAndCollect` to run in checked
   mode.

## 0.8.0+2

 * Strong mode fixes as of Dart SDK 1.20.1.

## 0.8.0+1

 * Make strong mode clean.

## 0.8.0

 * Moved `Formatter.format` parameters `reportOn` and `basePath` to
   constructor. Eliminated `pathFilter` parameter.

## 0.7.9

 * `format_coverage`: add `--base-directory` option. Source paths in
   LCOV/pretty-print output are relative to this directory, or absolute if
   unspecified.

## 0.7.8

 * `format_coverage`: support `--packages` option for package specs.

## 0.7.7

 * Add fallback URI resolution for Bazel http(s) URIs that don't contain a
   `packages` path component.

## 0.7.6

 * Add [Bazel](http://bazel.io) support to `format_coverage`.

## 0.7.5

 * Bugfix in `collect_coverage`: prevent hang if initial VM service connection
   is slow.
 * Workaround for VM behaviour in which `evaluate:source` ranges may appear in
   the returned source report manifesting in a crash in `collect_coverage`.
   These generally correspond to source evaluations in the debugger and add
   little value to line coverage.
 * `format_coverage`: may be slower for large sets of coverage JSON input
   files. Unlikely to be an issue due to elimination of `--coverage-dir` VM
   flag.

## 0.7.4

 * Require at least Dart SDK 1.16.0.

 * Bugfix in format_coverage: if `--report-on` is not specified, emit all
   coverage, rather than none.

## 0.7.3

 * Added support for the latest Dart SDK.

## 0.7.2

 * `Formatter.format` added two optional arguments: `reportOn` and `pathFilter`.
   They can be used independently to limit the files which are included in the
   output.

 * Added `runAndCollect` API to library.

## 0.7.1

 * Added `collect` top-level method.

 * Updated support for latest `0.11.0` dev build.

 * Replaced `ServiceEvent.eventType` with `ServiceEvent.kind`.
   *  `ServiceEvent.eventType` is deprecated and will be removed in `0.8`.

## 0.7.0

 * `format_coverage` no longer emits SDK coverage unless --sdk-root is set
   explicitly.

 * Removed support for collecting coverage from old (<1.9.0) Dart SDKs.

 * Removed deprecated `Resolver.pkgRoot`.

## 0.6.5

 * Fixed early collection bug when --wait-paused is set.

## 0.6.4

 * Optimized formatters and fixed return value of `format` methods.

 * Added `Resolver.packageRoot` – deprecated `Resolver.pkgRoot`.

## 0.6.3

 * Support the latest release of `args` package.

 * Support the latest release of `logging` package.

 * Fixed error when trying to access invalid paths.

 * Require at least Dart SDK v1.9.0.

## 0.6.2
 * Support observatory protocol changes for VM >= 1.11.0.

## 0.6.1
 * Support observatory protocol changes for VM >= 1.10.0.

## 0.6.0+1
 * Add support for `pub global run`.

## 0.6.0
  * Add support for SDK versions >= 1.9.0. For Dartium/content-shell versions
    past 1.9.0, coverage collection is no longer done over the remote debugging
    port, but via the observatory port emitted on stdout. Backward
    compatibility with SDKs back to 1.5.x is provided.
