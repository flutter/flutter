#### 3.1.0 - 2022-05-03

  * Fix: Make Cache.get ifAbsent parameter nullable. The parameter was always
    optional; this just corrects the type.
  * Fix: Remove documentation links to the (previously removed) mirrors library.

#### 3.0.1+2 - 2022-03-09

  * Remove broken references to the defunct mirrors library.

#### 3.0.1+1 - 2021-10-14

  * Add documentation to `Optional` suggesting that adding new uses be avoided
    and existing uses should be migrated to nullable types in codebases where
    non-null by default has been enabled.

#### 3.0.1 - 2021-04-06

  * Fix: Eliminate null check error on removal of root node of
    `AVLTree`.
  * Fix: Eliminate null check in partition internal iterator `current` getter.
  * Minor documentation typo corrections.

#### 3.0.0 - 2021-02-16

  * BREAKING CHANGE: This version requires Dart SDK 2.12.0 or later.
  * BREAKING CHANGE: Remove `assertCheckedMode`. This was deprecated in 2.1.2.
    Checked mode no longer exists in Dart 2.0 since the vast majority of what
    checked mode did is now done in the type system itself.
  * BREAKING CHANGE: Remove `doWhileAsync`. This was deprecated in 2.1.1.
    Existing callers should migrate to `Future.doWhile()`.
  * BREAKING CHANGE: Remove IO library. This was deprecated in 2.1.4.
  * BREAKING CHANGE: Remove mirrors library. This was deprecated in 2.1.4.
  * BREAKING CHANGE: forEachAsync now returns Future<void> instead of
    Future<Null>.
  * BREAKING CHANGE: BiMap no longer throws ArgumentError on insertion
    of a null key or value, if the corresponding K or V type is
    nullable. As before, values in the map must be unique and
    ArgumentError is thrown on attempts to add a key-value pair whose
    value is already in the map.
  * BREAKING CHANGE: `TreeSet.first` and `TreeSet.last` now throw
    StateError if no element exists, as specified by the Set API
    contract both with null safety enabled or disabled.
  * BREAKING CHANGE: `TreeSet` iterators now throw if `Iterator.current`
    is called before `moveNext` is called, or after `moveNext` has
    returned false when running with null safety enabled.
  * Deprecate `checkNotNull`. Users of this function should migrate to
    `ArgumentError.checkNotNull`. This will be removed in 4.0.0.
  * Deprecate `firstNonNull`. Users of this function should migrate to
    `var v = o1 ?? o2 ?? o3 ?? o4; ArgumentError.checkNotNull(v);`. This will be
    removed in 4.0.0
  * Eliminate dependency on package:meta.

#### 2.1.5 - 2020-11-05

  * Deprecate `forEachAsync`, `reduceAsync`. Existing callers should
    migrate to `Future.forEach`. Migration examples have been added to
    the documentation for these methods. This will be removed in Quiver
    3.0.0.

#### 2.1.4+1 - 2020-10-26

  * Fix: Add dart:async import to async/string.dart. Stream wasn't
    exported from dart:core until Dart 2.1 but Quiver supports back to
    Dart 2.0.

#### 2.1.4 - 2020-10-26

  * Move `stringFromByteStream` from the IO library to the async library. The
    original in IO has been deprecated and will be removed in 3.0.0. Users
    should update their code to import this function from `quiver/async.dart`.
    If both `quiver/io.dart` and `quiver.async.dart` are imported in the same
    file, users should hide the symbol from IO as described here:
    https://dart.dev/guides/language/language-tour#importing-only-part-of-a-library
  * Deprecate `getFullPath`. Users should use
    `File(path).resolveSymbolicLinksSync`. This will be removed in 3.0.0.
  * Deprecate `visitDirectory`. This will be removed in 3.0.0. The source can be
    copied under the terms of the Apache 2.0 license.
  * Deprecate mirrors library. This will be removed in 3.0.0. This library was
    written prior to Dart 1.0 and in the interim, mirrors have been found to be
    problematic for production code.  The primary Dart runtimes today are
    Flutter and the web. Flutter disables dart:mirrors altogether. On the web,
    the use of mirrors disables tree-shaking since in theory almost any symbol
    could be used reflectively; this can't be solved through static analysis --
    one could imagine the situation where a user of a web app inputs the name of
    a method to be reflectively invoked at runtime. Users of this code can
    rewrite this code, or copy it into their own projects under the terms of the
    Apache 2.0 license.
  * Fix: Eliminate a set literal inadvertently introduced in
    https://github.com/google/quiver-dart/pull/359. Set literals are only
    supported starting in Dart 2.2, but Quiver supports back to Dart 2.0.
  * Switched from using part/part of to re-exporting the underlying libraries.
    We weren't making use of private symbols across files within lib/src. This
    improves readability by keeping imports with the code that's using them. It
    also allows for cross-imports within lib/src if necessary.

#### 2.1.3 - 2020-02-28

  * Fix: revert const constructor change to `Optional.transform`,
    `Optional.transformNull` which causes type errors when used in combination
    with certain operations that trigger an implicit type check. The error in
    question was introduced in 2.1.2.

#### 2.1.2+1 - 2019-11-05

   * Minor linter fix: added curly brackets on flow-control structures to make
     Pana package scoring happier.

#### 2.1.2 - 2019-11-05

   * Deprecate `assertCheckedMode`. Checked mode no longer exists in Dart 2.0
     since the vast majority of what checked mode did is now done in the type
     system itself. This will be removed in Quiver 3.0.0.
   * TreeSet.isEmpty/isNotEmpty are now constant-time checks.
   * Large amounts of linter-related cleanups.

#### 2.1.1 - 2019-11-03

   * Deprecate `doWhileAsync`. Existing callers should migrate to
     `Future.doWhile()` from `dart:async`. This will be removed in Quiver
     3.0.0.
   * Fix: Eliminate a crash in `LruMap.putIfAbsent` when `maximumSize` is 1.
   * Add return types on any function that didn't include one.

#### 2.1.0 - 2019-10-28

   * Upgraded matcher dependency lower-bound from 0.10.0 to 0.12.5 to migrate
     from `isInstanceOf` to `isA` in tests.
   * Style cleanups.

#### 2.0.5 - 2019-08-06

   * Added `isNotBlank` to strings library.

#### 2.0.4 - 2019-08-01

   * Added `FakeAsync.pendingTimersDebugInfo`.

#### 2.0.3 - 2019-04-11

   * Do not cache failed `ifAbsent` calls in `MapCache`.

#### 2.0.2 - 2019-03-19

   * `partition` is now a generic function.
   * New: Optional now includes an `isNotPresent` getter alongside the existing
     `isPresent` getter.

#### 2.0.1 - 2018-10-22

   * New: Optional now includes `transformNullable` to pass maybe present
     values through a transformer with a nullable return value.

#### 2.0.0+1 - 2017-07-18

   * Updated Dart SDK constraint to >=2.0.0-dev.61 < 3.0.0.

#### 2.0.0 - 2018-07-18

   * BREAKING CHANGE: This version requires Dart SDK 2.0.0-dev.61 or later.

#### 1.0.0 - 2018-07-18

   * BREAKING CHANGE: StreamBuffer has been changed from implementing
     `StreamConsumer<T>` to `StreamConsumer<List<T>>`. Users of
     `StreamBuffer<List<T>>` can simply change declarations to
     `StreamBuffer<T>`. In cases where the generic type is already not a list
     type, inputs to the list may need to be wrapped in a list.

#### 0.29.0+1 - 2018-03-29

   * BREAKING CHANGE: This version requires Dart SDK 2.0.0-dev.30 or later.
     Bugfixes will be backported to the 0.28.x series for Dart 1 users.
   * New: BiMap now includes a real implementation of `addEntries`, `get
     entries`, `map`, `removeWhere`, `update`, and `updateAll`.
   * New: DelegatingIterable now includes a real implementation of
     `followedBy`, and accepts the `orElse` parameter on `singleWhere`.
   * New: DelegatingList now includes real implementations of `operator +`,
     `indexWhere`, and `lastIndexWhere`.
   * New: LruMap now includes a real implementation of `addEntries`, `get
     entries`, `removeWhere`, `update`, and `updateAll`.
   * New: The map returned by `Multimap.asMap()` now includes real
     implementations of `get entries` and `removeWhere`. This class also has
     "real" implementations of `addEntries`, `map`, `update`, and `updateAll`,
     which just throw an `UnsupportedError`, as inserts and updates are not
     allowed on map views.
   * New: The list keys of `ListMultimap` now include real implementations of
     `operator +`, `indexWhere`, and `lastIndexWhere`.
   * New: The iterable keys of `ListMultimap` and `SetMultimap` now include a
     real implementation of `followedBy`, and accept the `orElse` parameter on
     `singleWhere`.

#### 0.29.0 - 2018-03-28

   * BREAKING CHANGE: Deleted `createTimer` and `createTimerPeriodic`, which
     were deprecated in 0.26.0.
   * BREAKING CHANGE: Deleted `reverse`, which was deprecated in 0.25.0.
   * BREAKING CHANGE: Deleted `FutureGroup`, which was deprecated in 0.25.0.
   * BREAKING CHANGE: `InfiniteIterable.singleWhere` now throws
     `UnsupportedError`.

#### 0.28.2 - 2018-03-24

   * Fix: Eliminate a bug where `LruMap` linkage is incorrectly preserved when
     items are removed.

#### 0.28.1 - 2018-03-22

   * Remove use of `Maps.mapToString` in `LruMap`.
   * Add `@visibleForTesting` annotation in `AvlTreeSet`.

#### 0.28.0 - 2018-01-19

   * BREAKING CHANGE: The signature of `MultiMap`'s `update` stub has changed
     from `V update(K key, C update(C value), {C ifAbsent()})` to
     `C update(K key, C update(C value), {C ifAbsent()})`.

#### 0.27.0 - 2018-01-03

   * BREAKING CHANGE: all classes that implement `Iterable`, `List`, `Map`,
     `Queue`, `Set`, or `Timer` now implement stubs of upcoming Dart 2.0
     methods. Any class that reimplements these classes also needs new method
     implementations. The classes with these breaking changes include:
     `HashBiMap`, `DelegatingIterable`, `DelegatingList`,
     `DelegatingMap`,`DelegatingQueue`, `DelegatingSet`, `LinkedLruHashMap`,
     `TreeSet`, and `AvlTreeSet`.
   * Fix: Use FIFO ordering in `FakeAsync`. PR
     [#265](https://github.com/google/quiver-dart/pull/265)

#### 0.26.2 - 2017-11-16

   * Fix: re-adding the most-recently-used entry to a `LinkedLruHashMap`
     previously introduced a loop in the internal linked list.
   * Fix: when removing an entry in the middle of the `LinkedLruHashMap`, the
     recency list was not correctly re-linked.

#### 0.26.1 - 2017-11-16

   * Fix: when removing the last item, `LinkedLruHashMap` was put into a state
     such that the next cache eviction could cause a null-pointer exception.
     Issue [#385](https://github.com/google/quiver-dart/issues/385).
   * Fix: strong mode fix when calling `merge` on the empty set of iterables.
     PR [#384](https://github.com/google/quiver-dart/pull/384).

#### 0.26.0 - 2017-11-01
   * BREAKING CHANGE: eliminated deprecated `flip`. Replaced by `reverse` in
     0.25.0.
   * BREAKING CHANGE: eliminated deprecated `repeat`. Deprecated in 0.25.0.
     Callers should use `String`'s `*` operator.
   * BREAKING CHANGE: `collect`, `concat`, `doWhileAsync`, `enumerate`,
     `extent`, `forEachAsync`, `max`, `merge`, `min`, `reduceAsync`, and `zip`
     are now type parameterized. Depending on the inferred value of each type
     parameter, the return type of each function may change in existing code.
   * BREAKING CHANGE: `Optional`'s `==` operator now takes into account `T`,
     the type of the value. This changes, e.g. `Optional<int>.absent()` to no
     longer be equal to `Optional<String>.absent()`.
   * BREAKING CHANGE: stronger generics added in `Cache` and `MapCache`.
   * Deprecated: `reverse` in the `strings` library. No replacement is
     provided.
   * Deprecated: `createTimer`, `createTimerPeriodic` in the `async` library.
     These were originally written to support FakeTimer, which is superseded
     by FakeAsync.
   * New: Added `isLeapYear`, `daysInMonth`, `clampDayOfMonth` APIs in the
     `time` library.
   * Multimap is now backed by a LinkedHashMap rather than HashMap.
   * Multimap: added `contains` to know if an association key/value exists.

#### 0.25.0 - 2017-03-28
   * BREAKING CHANGE: minimum SDK constraint increased to 1.21.0. This allows
     use of async-await and generic function in Quiver.
   * BREAKING CHANGE: eliminated deprecated `FakeTimer`.
   * BREAKING CHANGE: `StreamBuffer<T>` now implements `StreamConsumer<T>` as
     opposed to `StreamConsumer<T|List<T>>`.
   * Deprecated: `FutureGroup`. Use the replacement in `package:async` which
     requires a `close()` call to trigger auto-completion when the count of
     pending tasks drops to 0.
   * Deprecated: `repeat` in the `strings` library. Use the `*` operator on
     the String class.
   * Deprecated: in the strings library, `flip` has been renamed `reverse`.
     `flip` is deprecated and will be removed in the next release.
   * Iterables: `enumerate` is now generic.
   * Collection: added `indexOf`.

#### 0.24.0 - 2016-10-31
   * BREAKING CHANGE: eliminated deprecated `nullToEmpty`, `emptyToNull`.
   * Fix: Strong mode: As of Dart SDK 1.21.0, `Set.difference` takes a
     `Set<Object>` parameter.

#### 0.23.0 - 2016-09-21
   * Strings: `nullToEmpty`, `emptyToNull` deprecated. Removal in 0.24.0.
   * BREAKING CHANGE: eliminated deprecated multimap `toMap`.
   * BREAKING CHANGE: eliminated deprecated `pad*`, `trim*` string functions.

#### 0.22.0 - 2015-04-21
   * BREAKING CHANGE: `streams` and `async` libraries have been [merged](https://github.com/google/quiver-dart/commit/671f1bc75742b4393e203c9520a3bf1e031967dc) into one `async` library
   * BREAKING CHANGE: Pre-1.8.0 SDKs are no longer supported.
   * Quiver is now [strong mode](https://github.com/dart-lang/dev_compiler/blob/master/STRONG_MODE.md) compliant
   * New: `Optional` now implements `Iterable` and its methods are generic (using temporary syntax)
   * New: `isNotEmpty` and `isDigit` in `strings.dart`
   * New: `Multimap.fromIterable`
   * Fix: Change `TreeSearch` from `class` to `enum`.
   * Fix: `fake_async.dart` timers are now active while executing the callback

#### 0.21.4 - 2015-05-15
   * Add stats reporting for fake async tests. You can query the number of
     pending microtasks and timers via `microtaskCount`, `periodicTimerCount`,
     `nonPeriodicTimerCount`.

#### 0.21.3+1 - 2015-05-11
   * Switch from unittest to test.

#### 0.21.3 - 2015-03-03
   * Bugfix: fixed return type on some methods (e.g. `where` of `Iterable`s
     returned by Multimap.

#### 0.21.2 - 2015-03-03
   * Bugfix: fix drifting times in `Metronome`.
   * Add `LruMap` to quiver/collection.
   * Un-deprecate Glob; feedback was that package:glob was not a suitable
     replacement in many cases. Key reasons: dependency on dart:io and
     significantly poorer performance.

#### 0.21.1 - 2015-02-05
   * Add optional start param to `Glob.allMatches()` to match superclass
     method signature.
   * Add optional start param to `Pattern` returned by `matchesAny()` to match
     superclass method signature.
   * Deprecate Glob. Use package:glob. Will be removed in 0.22.0.

#### 0.21.0+3 - 2015-02-04
   * Travis CI integration support added.
   * Document that the deprecated functions `padLeft`, `padRight`, `trimLeft`,
     `trimRight` will be removed in 0.22.0.

#### 0.21.0+2 - 2015-02-04
   * Fix hanging `FakeAsync` unit test.

#### 0.21.0+1 - 2015-02-03
   * Replace `equalsTester` dependency on `unittest` with finer-grained
     dependency on `matcher`.
   * `path` is now a dev dependency.

#### 0.21.0 - 2015-02-02
   * Multimap: `toMap()` is deprecated and replaced with `asMap()`. `toMap()`
     will be removed in v0.22.0.
   * Cleanup method signatures that were inconsistent with the core library.
   * Added `areEqualityGroups` matcher for testing `operator==` and `hashCode`.
   * CONTRIBUTING.md added.

#### 0.20.0 - 2014-12-10
   * Multimap: better `toString()` on returned collections.
   * Multimap: Bugfix: support edits on empty value collections.
   * Multimap: Added missing return statement in `fold`.
   * Added isEmpty() in `strings`.
   * Added max SDK constraint <2.0.0
   * Minor updates to README.md.
   * CHANGELOG.md added

#### 0.19.0+1 - 2014-11-12
   * Corrected version constraint suggestion in README.md.
