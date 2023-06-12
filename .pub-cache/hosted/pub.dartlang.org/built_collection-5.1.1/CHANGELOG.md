# Changelog

## 5.1.1

- Test fix for new analyzer hint.

## 5.1.0

- Allow collections with nullable types, for example `BuiltList<T?>`.
- Allow key/value types to be `dynamic`. This can be useful occasionally, and
  with Dart 2 and null safety it's much harder to use `dynamic` by accident.

## 5.0.0

- Stable null safe release.

## 5.0.0-nullsafety.0

- Migrate to NNBD.
- Deps on `package:collection` and `package:quiver` have been removed.
- Multimap builders no longer have `addAll` methods that accept multimaps from
  quiver. But, the constructors still work with quiver multimaps.

## 4.3.2

- Add an `example` folder with some example code.

## 4.3.1

- Internal: cleanup for pedantic v1.9.0 lints.

## 4.3.0

- Add extensions methods: `List.build`, `Set.build`, `Map.build`,
  `Iterable.toBuiltList` and `Iterable.toBuiltSet`. Requires SDK 2.6.0.
- Cleanup: remove unnecessary `new` and `const`.

## 4.2.2

- Bug fix: `ListMultimapBuilder.[]` no longer ignores modifications under some
  circumstances.

## 4.2.1

- Bug fix: `ListBuilder` `first` and `last` setters can no longer modify the
  underlying collection.

## 4.2.0

- Add benchmark for VM and dart2js.
- Stop doing explicit type checks on elements; in Dart 2 these are implied.
- Modify methods on `ListBuilder` and `SetBuilder` that take `Iterable`
  elements so they only iterate over the iterable once. Improves performance
  when the iterable are slow/lazy.

## 4.1.0

- Add return val to `SetBuilder.add()` to match `Set.add()`.
- Expand `ListMultimapBuilder`: implement `[]` and add return values to
  `remove` and `removeAll`.

## 4.0.0

- Many changes following Dart 2 improvements to collections:
  - Implement `Iterable` methods: `cast`, `followedBy` and `whereType`.
  - Remove obsolete `Iterable` method: `retype`.
  - Support `orElse` in `singleWhere`.
  - Add `BuiltList` methods: `+`, `indexWhere`, `lastIndexWhere`.
  - Add `ListBuilder` setters and getters: `first`, `last`.
  - Add `BuiltMap` methods: `entries`, `map`.
  - Add `MapBuilder` methods: `addEntries`, `updateValue`, `updateAllValues`.
  - Implement Dart 2 methods in internal collections used by `toList`, `toMap`
    and `toSet`.
- Add `from` and `of` constructors to `BuiltList`, `BuiltMap` and `BuiltSet`.
  The `from` constructors, like the current constructors, take collections
  of any type and check each element. The `of` constructors, like the SDK `of`
  constructors, take a collection of the correct type. This means they can be
  used for type inference, allowing you to omit the explicit type.
- Make `remove`, `removeAt` and `removeLast` methods on builders return values
  like their SDK collection equivalents.

## 3.2.0

- Add length, isEmpty and isNotEmpty to ListBuilder, MapBuilder and SetBuilder

## 3.1.3

- Allow SDK 2.0.0.

## 3.1.2

- Allow quiver 2.0.0, use test version 1.

## 3.1.1

- Allow quiver 0.29.

## 3.1.0

- Implement `followedBy` on `BuiltList` and `BuiltSet`.

## 3.0.5

- Type fixes for DDC. Stop using a `Map` as a `Map<K, V>` in `MapBuilder`.

## 3.0.4

- Tweaks to tests.

## 3.0.3

- Allow quiver 0.28.

## 3.0.2

- Stop using `Function()` syntax for `Set` and `Map` factories. It causes
  problems for the analyzer when using a pre-Dart-2 SDK.

## 3.0.1

- Improve package description.

## 3.0.0

- Prepare for Dart 2; add methods that will appear in `Iterable`.
- Allow quiver 0.27.

## 2.1.3

- Revert changes for Dart 2; they will be re-released as v3.0.0 as they are
  break libraries that provide their own implementations of built collections.

## 2.1.2

- Fix changes for Dart 2.

## 2.1.1

- Prepare for Dart 2; add methods that will appear in `Iterable`.

## 2.1.0

- `BuiltSet` and `BuiltMap` now allow you to specify the underlying collection
  type. For example, you can construct a `BuiltSet` using a `SplayTreeSet`.
  This results in a set that is always in sorted order instead of
  preserving insertion order. Another useful possibility is to use a
  `HashSet`, which leads to a random order but improves performance over
  the default. See `SetBuilder.withBase` and `MapBuilder.withBase`.

## 2.0.0

- Split collection classes into abstract interfaces and concrete, private,
  implementations. This allows new implementations of the interfaces. Note that
  this change is invisible _unless_ you rely on the exact `runtimeType` of the
  collections.

## 1.6.2

- Fix a bug whereby `ListBuilder` and `MapBuilder` allowed nulls to be
  introduced via `map` and `expand`.

## 1.6.1

- Allow quiver 0.26.

## 1.6.0

- The addIterable method is now generic. This allows the types of the functions
  passed in to be inferred.

## 1.5.0

- Add BuiltIterable interface for when you want to accept a BuiltList or BuiltSet.

## 1.4.1

- Use real generic syntax, drop comment-based syntax.

## 1.4.0

- Add operator[] to ListBuilder and MapBuilder for easier inline updates.

## 1.3.1

- Allow quiver 0.25.

## 1.3.0

- Widen parameter of BuiltSet.difference and BuiltSet.intersection to
  `BuiltSet<Object>` to match Set.

## 1.2.0

- Update for Set.difference change in SDK 1.21.0.
- Add `asList`, `asMap`, and `asSet` to the built collection classes.

## 1.1.0

- Remove runtime checks that are unnecessary if the project using
  built_collection is "strong mode clean", that is, if it has no errors with
  strong mode. See note in `README.md` about strong mode.

## 1.0.6

- Allow quiver 0.23.

## 1.0.5

- Strong mode clean.

## 1.0.4

- Add reference identity check to equals operators.

## 1.0.3

- Fix factories when iterable generic type is subtype of requested type.

## 1.0.2

- Add generic type information to map, fold and expand methods.

## 1.0.1

- Make map operator[] take Object instead of K, as SDK collections do.
- Fix toString for result of toList, toSet, toMap.

## 1.0.0

- Fix missing generics on some return types.
- Fix BuiltList and BuiltSet "contains" method, should take Object, not E.
- Add removeAll and retainAll methods to SetBuilder.
- Add BuiltList.toBuiltSet() and BuiltSet.toBuiltList().
- Add addIterable methods to Map and Multimap builders.

## 0.4.0

- Add BuiltSetMultimap.

## 0.3.1

- Fix "part of" statement.

## 0.3.0

- Bug fix: fix Iterable "update in place" methods of BuiltList and BuiltSet so they discard original list or set.
- Make keys and values stable for BuiltMap and BuiltMultimap.
- Make repeated builds return identical instances for BuiltList, BuiltMap, BuiltSet.
- Add 'replace' methods.

## 0.2.0

- Add BuiltListMultimap.

## 0.1.1

- Fix comments.

## 0.1.0

- Add build and rebuild methods to BuiltList, BuiltMap, BuiltSet.
- Add update methods to ListBuilder, MapBuilder, SetBuilder.

## 0.0.1

- Initial version.
