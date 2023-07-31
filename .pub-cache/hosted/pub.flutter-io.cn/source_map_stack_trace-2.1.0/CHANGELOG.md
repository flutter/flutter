## 2.1.0

* Stable release for null safety.

## 2.1.0-nullsafety.4

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 2.1.0-nullsafety.3

* Allow prerelease versions of the 2.12 sdk.

## 2.1.0-nullsafety.2

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 2.1.0-nullsafety.1

* Update source_maps constraint.

## 2.1.0-nullsafety

* Migrate to null safety.

## 2.0.0

### Breaking Changes

* Removed dependency on `package_resolver` and changed the apis to accept a
  `Map<String, Uri>` which maps package names to the base uri to resolve the
  `package:` uris for those packages.
* The `sdkRoot` argument must be an `Uri`. Use `Uri.parse` for use
  cases previously passing a `String`.
* The deprecated `packageRoot` argument has been removed.

## 1.1.5

* Set max SDK version to `<3.0.0`.

## 1.1.4

* Support source maps that depend on the uri of the location to resolve spans
  correctly.

## 1.1.3

* Add a missing dependency on `path`.

## 1.1.2

* Fix a typo in the previous fix.

## 1.1.1

* Don't crash if the `SyncPackageResolver` has no package information at all.

## 1.1.0

* `mapStackTrace()` now uses a `SyncPackageResolver` object from the
  [`package_resolver` package][package_resolver] to recreate `package:` URIs.

* **Deprecation**: the `packageRoot` parameter to `mapStackTrace` is deprecated
  in favor of the `packageInfo` parameter described above. It will be removed in
  a future release.

[package_resolver]: https://pub.dartlang.org/packages/package_resolver

## 1.0.5

* Add compatibility for member names that include named arguments.

## 1.0.4

* Add compatibility for Dart 1.10-style name munging.

## 1.0.3

* Prefer "dart:" URLs to "package:" URLs.

## 1.0.2

* Fix an off-by-one bug that was causing line numbers to be slightly off.

## 1.0.1

* Don't crash when mapping stack chains.

## 1.0.0

* Initial release.
