# 2.0.3

- fix: revert `EquatableMixin` == to use `Object` ([#122](https://github.com/felangel/equatable/issues/122))

# 2.0.2

- fix: `Map` prop with non-comparable key

# 2.0.1

- fix: `hashCode` should be the same for equal objects (`Map` fix)

# 2.0.0

- **BREAKING**: opt into null safety
  - feat!: upgrade Dart SDK constraints to `>=2.12.0-0 <3.0.0`
- **BREAKING**: stringify prints "null" for null properties instead of ""
- feat: `EquatableConfig.stringify` defaults to `true` in debug mode.
- fix: support legacy equality overrides with `EquatableMixin`
- fix: iterable equality comparisons ([#101](https://github.com/felangel/equatable/issues/101))
- fix: stringify instance with long properties ([#94](https://github.com/felangel/equatable/issues/94))
- chore: update dependencies
  - `collection: ^1.15.0`
  - `meta: ^1.3.0`
- docs: minor updates to `README` and `example`

# 2.0.0-nullsafety.4

- feat: `EquatableConfig.stringify` defaults to `true` in debug mode.
- fix: support legacy equality overrides with `EquatableMixin`

# 2.0.0-nullsafety.3

- chore: update dependencies
  - `collection: ^1.15.0`
  - `meta: ^1.3.0`

# 2.0.0-nullsafety.2

- fix: iterable equality comparisons ([#101](https://github.com/felangel/equatable/issues/101))
- fix: stringify instance with long properties ([#94](https://github.com/felangel/equatable/issues/94))

# 2.0.0-nullsafety.1

- **BREAKING**: stringify prints "null" for null properties instead of ""

# 2.0.0-nullsafety.0

- **BREAKING**: opt into null safety
- feat!: upgrade Dart SDK constraints to `>=2.12.0-0 <3.0.0`
- docs: minor updates to `README` and `example`

# 1.2.6

- fix: iterable equality comparisons ([#101](https://github.com/felangel/equatable/issues/101))
- fix: stringify instance with long properties ([#94](https://github.com/felangel/equatable/issues/94))

# 1.2.5

- docs: dartdoc improvements ([#80](https://github.com/felangel/equatable/issues/80))
- docs: minor inline documentation improvements

# 1.2.4

- fix: `EquatableMixin` stringify respects `EquatableConfig.stringify` ([#81](https://github.com/felangel/equatable/issues/81))

# 1.2.3

- docs: inline, public documentation improvements ([#78](https://github.com/felangel/equatable/pull/78)).
- refactor: stricter analysis/lint rules

# 1.2.2

- Documentation badge fixes and updates

# 1.2.1

- Fix `hashCode` computation for `Iterables` ([#74](https://github.com/felangel/equatable/issues/74))
- Minor documentation improvements

# 1.2.0

- Added `EquatableConfig` for global `stringify` configuration ([#69](https://github.com/felangel/equatable/pull/69))

# 1.1.1

- Updates to `EquatableUtils` documentation

# 1.1.0

- Fix `hashCode` error when `props` is `null` ([#45](https://github.com/felangel/equatable/pull/45))
- Added `stringify` feature (optional `toString` override) ([#45](https://github.com/felangel/equatable/pull/45))

# 1.0.3

- Fix `hashCode` collisions for lists within props ([#53](https://github.com/felangel/equatable/pull/53))

# 1.0.2

- Fix internal lint warnings

# 1.0.1

- Fix `hashCode` collisions with `Map` properties ([#43](https://github.com/felangel/equatable/issues/43))

# 1.0.0

- Update hashCode implementation to use `Jenkins Hash` ([#39](https://github.com/felangel/equatable/issues/39))
- Documentation Updates

# 0.6.1

- Minor documentation updates

# 0.6.0

- The `props` getter override is required for both `Equatable` and `EquatableMixin`
- Performance Improvements

# 0.5.1

- Allow const constructors on `Equatable` class

# 0.5.0

- Removed `EquatableMixinBase` (now covered by `EquatableMixin`).
- Typed `EquatableMixin` from `List<dynamic>` to `List<Object>` to fix linter
  issues with `implicit-dynamic: false`.

# 0.4.0

Update `toString` to default to `runtimeType` ([#27](https://github.com/felangel/equatable/issues/27))

# 0.3.0

Enforce Immutability ([#25](https://github.com/felangel/equatable/issues/25))

# 0.2.6

Improved support for collection types ([#19](https://github.com/felangel/equatable/issues/19))

# 0.2.5

Improved support for `Iterable`, `List`, `Map`, and `Set` props ([#17](https://github.com/felangel/equatable/issues/17))

# 0.2.4

Additional Minor Documentation Updates

# 0.2.3

Documentation Updates

# 0.2.2

Bug Fixes:

- `Equatable` instances that are equal now have the same `hashCode` ([#8](https://github.com/felangel/equatable/issues/8))

# 0.2.1

Update Dart support to `>=2.0.0 <3.0.0`

# 0.2.0

Add `EquatableMixin` and `EquatableMixinBase`

# 0.1.10

Enhancements to `toString` override

# 0.1.9

equatable has 0 dependencies

# 0.1.8

Support `Iterable` props

# 0.1.7

Added `toString` override

# 0.1.6

Documentation Updates

- Performance Tests

# 0.1.5

Additional Performance Optimizations & Documentation Updates

# 0.1.4

Performance Optimizations

# 0.1.3

Bug Fixes

# 0.1.2

Additional Updates to Documentation.

- Logo Added

# 0.1.1

Minor Updates to Documentation.

# 0.1.0

Initial Version of the library.

- Includes the ability to extend `Equatable` and not have to override `==` and `hashCode`.
