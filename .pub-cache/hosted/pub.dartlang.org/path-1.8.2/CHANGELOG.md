## 1.8.2

* Enable the `avoid_dynamic_calls` lint.
* Popuate the pubspec `repository` field.

## 1.8.1

* Don't crash when an empty string is passed to `toUri()`.

## 1.8.0

* Stable release for null safety.

## 1.8.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.8.0-nullsafety.2

* Allow prerelease versions of the 2.12 sdk.

## 1.8.0-nullsafety.1

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.8.0-nullsafety

* Migrate to null safety.

## 1.7.0

* Add support for multiple extension in `context.extension()`.

## 1.6.4

* Fixed a number of lints that affect the package health score.

* Added an example.

## 1.6.3

* Don't throw a FileSystemException from `current` if the working directory has
  been deleted but we have a cached one we can use.

## 1.6.2

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 1.6.1

* Drop the `retype` implementation for compatibility with the latest SDK.

## 1.6.0

* Add a `PathMap` class that uses path equality for its keys.

* Add a `PathSet` class that uses path equality for its contents.

## 1.5.1

* Fix a number of bugs that occurred when the current working directory was `/`
  on Linux or Mac OS.

## 1.5.0

* Add a `setExtension()` top-level function and `Context` method.

## 1.4.2

* Treat `package:` URLs as absolute.

* Normalize `c:\foo\.` to `c:\foo`.

## 1.4.1

* Root-relative URLs like `/foo` are now resolved relative to the drive letter
  for `file` URLs that begin with a Windows-style drive letter. This matches the
  [WHATWG URL specification][].

[WHATWG URL specification]: https://url.spec.whatwg.org/#file-slash-state

* When a root-relative URLs like `/foo` is converted to a Windows path using
  `fromUrl()`, it is now resolved relative to the drive letter. This matches
  IE's behavior.

## 1.4.0

* Add `equals()`, `hash()` and `canonicalize()` top-level functions and
  `Context` methods. These make it easier to treat paths as map keys.

* Properly compare Windows paths case-insensitively.

* Further improve the performance of `isWithin()`.

## 1.3.9

* Further improve the performance of `isWithin()` when paths contain `/.`
  sequences that aren't `/../`.

## 1.3.8

* Improve the performance of `isWithin()` when the paths don't contain
  asymmetrical `.` or `..` components.

* Improve the performance of `relative()` when `from` is `null` and the path is
  already relative.

* Improve the performance of `current` when the current directory hasn't
  changed.

## 1.3.7

* Improve the performance of `absolute()` and `normalize()`.

## 1.3.6

* Ensure that `path.toUri` preserves trailing slashes for relative paths.

## 1.3.5

* Added type annotations to top-level and static fields.

## 1.3.4

* Fix dev_compiler warnings.

## 1.3.3

* Performance improvement in `Context.relative` - don't call `current` if `from`
  is not relative.

## 1.3.2

* Fix some analyzer hints.

## 1.3.1

* Add a number of performance improvements.

## 1.3.0

* Expose a top-level `context` field that provides access to a `Context` object
  for the current system.

## 1.2.3

* Don't cache path Context based on cwd, as cwd involves a system-call to
  compute.

## 1.2.2

* Remove the documentation link from the pubspec so this is linked to
  pub.dev by default.

# 1.2.1

* Many members on `Style` that provided access to patterns and functions used
  internally for parsing paths have been deprecated.

* Manually parse paths (rather than using RegExps to do so) for better
  performance.

# 1.2.0

* Added `path.prettyUri`, which produces a human-readable representation of a
  URI.

# 1.1.0

* `path.fromUri` now accepts strings as well as `Uri` objects.
