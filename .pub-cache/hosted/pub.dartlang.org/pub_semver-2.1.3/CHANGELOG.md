# 2.1.3

- Add type parameters to the signatures of the `Version.preRelease` and
  `Version.build` fields (`List` ==> `List<Object>`).
  [#74](https://github.com/dart-lang/pub_semver/pull/74).
- Require Dart 2.17.

# 2.1.2

- Add markdown badges to the readme.

# 2.1.1

- Fixed the version parsing pattern to only accept dots between version
  components.

# 2.1.0
- Added `Version.canonicalizedVersion` to help scrub leading zeros and highlight
  that `Version.toString()` preserves leading zeros.
- Annotated `Version` with `@sealed` to discourage users from implementing the
  interface.

# 2.0.0

- Stable null safety release.
- `Version.primary` now throws `StateError` if the `versions` argument is empty.

# 1.4.4

- Fix a bug of `VersionRange.union` where ranges bounded at infinity would get
  combined wrongly.

# 1.4.3

- Update Dart SDK constraint to `>=2.0.0 <3.0.0`.
- Update `package:collection` constraint to `^1.0.0`.

# 1.4.2

* Set max SDK version to `<3.0.0`.

# 1.4.1

* Fix a bug where there upper bound of a version range with a build identifier
  could accidentally be rewritten.

# 1.4.0

* Add a `Version.firstPreRelease` getter that returns the first possible
  pre-release of a version.

* Add a `Version.isFirstPreRelease` getter that returns whether a version is the
  first possible pre-release.

* `new VersionRange()` with an exclusive maximum now replaces the maximum with
  its first pre-release version. This matches the existing semantics, where an
  exclusive maximum would exclude pre-release versions of that maximum.

  Explicitly representing this by changing the maximum version ensures that all
  operations behave correctly with respect to the special pre-release semantics.
  In particular, it fixes bugs where, for example,
  `(>=1.0.0 <2.0.0-dev).union(>=2.0.0-dev <2.0.0)` and
  `(>=1.0.0 <3.0.0).difference(^1.0.0)` wouldn't include `2.0.0-dev`.

* Add an `alwaysIncludeMaxPreRelease` parameter to `new VersionRange()`, which
  disables the replacement described above and allows users to create ranges
  that do include the pre-release versions of an exclusive max version.

# 1.3.7

* Fix more bugs with `VersionRange.intersect()`, `VersionRange.difference()`,
  and `VersionRange.union()` involving version ranges with pre-release maximums.

# 1.3.6

* Fix a bug where constraints that only allowed pre-release versions would be
  parsed as empty constraints.

# 1.3.5

* Fix a bug where `VersionRange.intersect()` would return incorrect results for
  pre-release versions with the same base version number as release versions.

# 1.3.4

* Fix a bug where `VersionRange.allowsAll()`, `VersionRange.allowsAny()`, and
  `VersionRange.difference()` would return incorrect results for pre-release
  versions with the same base version number as release versions.

# 1.3.3

* Fix a bug where `VersionRange.difference()` with a union constraint that
  covered the entire range would crash.

# 1.3.2

* Fix a checked-mode error in `VersionRange.difference()`.

# 1.3.1

* Fix a new strong mode error.

# 1.3.0

* Make the `VersionUnion` class public. This was previously used internally to
  implement `new VersionConstraint.unionOf()` and `VersionConstraint.union()`.
  Now it's public so you can use it too.

* Added `VersionConstraint.difference()`. This returns a constraint matching all
  versions matched by one constraint but not another.

* Make `VersionRange` implement `Comparable<VersionRange>`. Ranges are ordered
  first by lower bound, then by upper bound.

# 1.2.4

* Fix all remaining strong mode warnings.

# 1.2.3

* Addressed three strong mode warnings.

# 1.2.2

* Make the package analyze under strong mode and compile with the DDC (Dart Dev
  Compiler). Fix two issues with a private subclass of `VersionConstraint`
  having different types for overridden methods.

# 1.2.1

* Allow version ranges like `>=1.2.3-dev.1 <1.2.3` to match pre-release versions
  of `1.2.3`. Previously, these didn't match, since the pre-release versions had
  the same major, minor, and patch numbers as the max; now an exception has been
  added if they also have the same major, minor, and patch numbers as the min
  *and* the min is also a pre-release version.

# 1.2.0

* Add a `VersionConstraint.union()` method and a `new
  VersionConstraint.unionOf()` constructor. These each return a constraint that
  matches multiple existing constraints.

* Add a `VersionConstraint.allowsAll()` method, which returns whether one
  constraint is a superset of another.

* Add a `VersionConstraint.allowsAny()` method, which returns whether one
  constraint overlaps another.

* `Version` now implements `VersionRange`.

# 1.1.0

* Add support for the `^` operator for compatible versions according to pub's
  notion of compatibility. `^1.2.3` is equivalent to `>=1.2.3 <2.0.0`; `^0.1.2`
  is equivalent to `>=0.1.2 <0.2.0`.

* Add `Version.nextBreaking`, which returns the next version that introduces
  breaking changes after a given version.

* Add `new VersionConstraint.compatibleWith()`, which returns a range covering
  all versions compatible with a given version.

* Add a custom `VersionRange.hashCode` to make it properly hashable.

# 1.0.0

* Initial release.
