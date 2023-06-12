## 3.0.1

* Require Dart `2.14`.
* Update the pubspec `repository` field.

## 3.0.0

* Migrate to null safety.

## 2.0.1

* Allow the latest (null-safe) version of `pkg:shelf`.

## 2.0.0

### Breaking changes

* Dropped the dependency on `package_resolver`.
    * All `PackageResolver` apis now take a `Map<String, Uri>` of package name to the base uri for resolving `package:`
      uris for that package.
    * Named arguments have been renamed from `resolver` to `packageMap`.

## 1.0.4

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.0.3

* Require Dart SDK 1.22.0
* Support `package:async` v2

## 1.0.2

* Fix Strong mode errors with `package:shelf` v0.7.x

## 1.0.1

* Allow dependencies on `package:shelf` v0.7.x

## 0.0.1

* Initial version
