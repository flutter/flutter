## 1.16.0

* Add an `Iterable.slices` extension method.
* Add `BoolList` class for space-efficient lists of boolean values.
* Use a stable sort algorithm in the `IterableExtension.sortedBy` method.
* Add `min`, `max`, `minOrNull` and `maxOrNull` getters to
  `IterableDoubleExtension`, `IterableNumberExtension` and
  `IterableIntegerExtension`
* Change `UnorderedIterableEquality` and `SetEquality` to implement `Equality`
  with a non-nullable generic to allows assignment to variables with that type.
  Assignment to `Equality` with a nullable type is still allowed because of
  covariance. The `equals` and `hash` methods continue to accept nullable
  arguments.
* Enable the `avoid_dynamic_calls` lint.

## 1.15.0

* Stable release for null safety.

## 1.15.0-nullsafety.5

* Fix typo in extension method `expandIndexed`.
* Update sdk constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.15.0-nullsafety.4

* Allow prerelease versions of the `2.12.x` sdk.

* Remove the unusable setter `UnionSetController.set=`. This was mistakenly
  added to the public API but could never be called.

* Add extra optional `Random` argument to `shuffle`.

* Add a large number of extension methods on `Iterable` and `List` types,
  and on a few other types.
  These either provide easy access to the operations from `algorithms.dart`,
  or provide convenience variants of existing `Iterable` and `List` methods
  like `singleWhereOrNull` or `forEachIndexed`.

## 1.15.0-nullsafety.3

* Allow 2.10 stable and 2.11.0 dev SDK versions.
* Add `toUnorderedList` method on `PriorityQueue`.
* Make `HeapPriorityQueue`'s `remove` and `contains` methods
  use `==` for equality checks.
  Previously used `comparison(a, b) == 0` as criteria, but it's possible
  to have multiple elements with the same priority in a queue, so that
  could remove the wrong element.
  Still requires that objects that are `==` also have the same priority.

## 1.15.0-nullsafety.2

Update for the 2.10 dev sdk.

## 1.15.0-nullsafety.1

* Allow the <=2.9.10 stable sdks.

## 1.15.0-nullsafety

Pre-release for the null safety migration of this package.

Note that `1.15.0` may not be the final stable null safety release version,
we reserve the right to release it as a `2.0.0` breaking change.

This release will be pinned to only allow pre-release sdk versions starting
from `2.9.0-dev.18.0`, which is the first version where this package will
appear in the null safety allow list.

## 1.14.13

* Deprecate `mapMap`. The Map interface has a `map` call and map literals can
  use for-loop elements which supersede this method.

## 1.14.12

* Fix `CombinedMapView.keys`, `CombinedMapView.length`,
  `CombinedMapView.forEach`, and `CombinedMapView.values` to work as specified
  and not repeat duplicate items from the maps.
  * As a result of this fix the `length` getter now must iterate all maps in
    order to remove duplicates and return an accurate length, so it is no
    longer `O(maps)`.

## 1.14.11

* Set max SDK version to `<3.0.0`.

## 1.14.10

* Fix the parameter names in overridden methods to match the source.
* Make tests Dart 2 type-safe.
* Stop depending on SDK `retype` and deprecate methods.

## 1.14.9

* Fixed bugs where `QueueList`, `MapKeySet`, and `MapValueSet` did not adhere to
  the contract laid out by `List.cast`, `Set.cast` and `Map.cast` respectively.
  The returned instances of these methods now correctly forward to the existing
  instance instead of always creating a new copy.

## 1.14.8

* Deprecated `Delegating{Name}.typed` static methods in favor of the new Dart 2
  `cast` methods. For example, `DelegatingList.typed<String>(list)` can now be
  written as `list.cast<String>()`.

## 1.14.7

* Only the Dart 2 dev SDK (`>=2.0.0-dev.22.0`) is now supported.
* Added support for all Dart 2 SDK methods that threw `UnimplementedError`.

## 1.14.6

* Make `DefaultEquality`'s `equals()` and `hash()` methods take any `Object`
  rather than objects of type `E`. This makes `const DefaultEquality<Null>()`
  usable as `Equality<E>` for any `E`, which means it can be used in a const
  context which expects `Equality<E>`.

  This makes the default arguments of various other const equality constructors
  work in strong mode.

## 1.14.5

* Fix issue with `EmptyUnmodifiableSet`'s stubs that were introduced in 1.14.4.

## 1.14.4

* Add implementation stubs of upcoming Dart 2.0 core library methods, namely
  new methods for classes that implement `Iterable`, `List`, `Map`, `Queue`,
  and `Set`.

## 1.14.3

* Fix `MapKeySet.lookup` to be a valid override in strong mode.

## 1.14.2

* Add type arguments to `SyntheticInvocation`.

## 1.14.1

* Make `Equality` implementations accept `null` as argument to `hash`.

## 1.14.0

* Add `CombinedListView`, a view of several lists concatenated together.
* Add `CombinedIterableView`, a view of several iterables concatenated together.
* Add `CombinedMapView`, a view of several maps concatenated together.

## 1.13.0

* Add `EqualityBy`

## 1.12.0

* Add `CaseInsensitiveEquality`.

* Fix bug in `equalsIgnoreAsciiCase`.

## 1.11.0

* Add `EqualityMap` and `EqualitySet` classes which use `Equality` objects for
  key and element equality, respectively.

## 1.10.1

* `Set.difference` now takes a `Set<Object>` as argument.

## 1.9.1

* Fix some documentation bugs.

## 1.9.0

* Add a top-level `stronglyConnectedComponents()` function that returns the
  strongly connected components in a directed graph.

## 1.8.0

* Add a top-level `mapMap()` function that works like `Iterable.map()` on a
  `Map`.

* Add a top-level `mergeMaps()` function that creates a new map with the
  combined contents of two existing maps.

* Add a top-level `groupBy()` function that converts an `Iterable` to a `Map` by
  grouping its elements using a function.

* Add top-level `minBy()` and `maxBy()` functions that return the minimum and
  maximum values in an `Iterable`, respectively, ordered by a derived value.

* Add a top-level `transitiveClosure()` function that returns the transitive
  closure of a directed graph.

## 1.7.0

* Add a `const UnmodifiableSetView.empty()` constructor.

## 1.6.0

* Add a `UnionSet` class that provides a view of the union of a set of sets.

* Add a `UnionSetController` class that provides a convenient way to manage the
  contents of a `UnionSet`.

* Fix another incorrectly-declared generic type.

## 1.5.1

* Fix an incorrectly-declared generic type.

## 1.5.0

* Add `DelegatingIterable.typed()`, `DelegatingList.typed()`,
  `DelegatingSet.typed()`, `DelegatingMap.typed()`, and
  `DelegatingQueue.typed()` static methods. These wrap untyped instances of
  these classes with the correct type parameter, and assert the types of values
  as they're accessed.

* Fix the types for `binarySearch()` and `lowerBound()` so they no longer
  require all arguments to be comparable.

* Add generic annotations to `insertionSort()` and `mergeSort()`.

## 1.4.1

* Fix all strong mode warnings.

## 1.4.0

* Add a `new PriorityQueue()` constructor that forwards to `new
  HeapPriorityQueue()`.

* Deprecate top-level libraries other than `package:collection/collection.dart`,
  which exports these libraries' interfaces.

## 1.3.0

* Add `lowerBound` to binary search for values that might not be present.

* Verify that the is valid for `CanonicalMap.[]`.

## 1.2.0

* Add string comparators that ignore ASCII case and sort numbers numerically.

## 1.1.3

* Fix type inconsistencies with `Map` and `Set`.

## 1.1.2

* Export `UnmodifiableMapView` from the Dart core libraries.

## 1.1.1

* Bug-fix for signatures of `isValidKey` arguments of `CanonicalizedMap`.

## 1.1.0

* Add a `QueueList` class that implements both `Queue` and `List`.

## 0.9.4

* Add a `CanonicalizedMap` class that canonicalizes its keys to provide a custom
  equality relation.

## 0.9.3+1

* Fix all analyzer hints.

## 0.9.3

* Add a `MapKeySet` class that exposes an unmodifiable `Set` view of a `Map`'s
  keys.

* Add a `MapValueSet` class that takes a function from values to keys and uses
  it to expose a `Set` view of a `Map`'s values.
