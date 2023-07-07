Quiver
======

Quiver is a set of utility libraries for Dart that makes using many Dart
libraries easier and more convenient, or adds additional functionality.

[![Build Status](https://travis-ci.org/google/quiver-dart.svg?branch=master)](https://travis-ci.org/google/quiver-dart)
[![Coverage Status](https://img.shields.io/coveralls/google/quiver-dart.svg)](https://coveralls.io/r/google/quiver-dart)

## Documentation

[API Docs](https://pub.dev/documentation/quiver/latest/) are available.


Main Libraries
--------------

## [quiver.async][]

Utilities for working with Futures, Streams and async computations.

`collect` collects the completion events of an `Iterable` of `Future`s into a
`Stream`.

`enumerate` and `concat` represent `Stream` versions of the same-named
[quiver.iterables][] methods.

`StreamBuffer` allows for the orderly reading of elements from a stream, such
as a socket.

`FutureStream` turns a `Future<Stream>` into a `Stream` which emits the same
events as the stream returned from the future.

`StreamRouter` splits a Stream into multiple streams based on a set of
predicates.

`CountdownTimer` is a simple countdown timer that fires events in regular
increments.

`Metronome` is a self-correcting alternative to `Timer.periodic`. It provides
a simple, tracking periodic stream of `DateTime` events with optional anchor
time.

`stringFromByteStream` constructs a string from a stream of byte lists.

[quiver.async]: https://pub.dev/documentation/quiver/latest/quiver.async/quiver.async-library.html

## [quiver.cache][]

`Cache` is a semi-persistent, asynchronously accessed, mapping of keys to
values. Caches are similar to Maps, except that the cache implementation might
store values in a remote system, so all operations are asynchronous, and caches
might have eviction policies.

`MapCache` is a Cache implementation backed by a Map.

[quiver.cache]: https://pub.dev/documentation/quiver/latest/quiver.cache/quiver.cache-library.html

## [quiver.check][]

`checkArgument` throws `ArgumentError` if the specified argument check expression
is false.

`checkListIndex` throws `RangeError` if the specified index is out of bounds.

`checkState` throws `StateError` if the specified state check expression is
false.

[quiver.check]: https://pub.dev/documentation/quiver/latest/quiver.check/quiver.check-library.html

## [quiver.collection][]

`listsEqual`, `mapsEqual` and `setsEqual` check collections for equality.

`indexOf` finds the first index of an item satisfying a predicate.

`LruMap` is a map that removes the least recently used item when a threshold
length is exceeded.

`Multimap` is an associative collection that maps keys to collections of
values.

`BiMap` is a bidirectional map and provides an inverse view, allowing
lookup of key by value.

`TreeSet` is a balanced binary tree that offers a bidirectional iterator,
the ability to iterate from an arbitrary anchor, and 'nearest' search.

[quiver.collection]: https://pub.dev/documentation/quiver/latest/quiver.collection/quiver.collection-library.html

## [quiver.core][]

`Optional` is a way to represent optional values without allowing `null`.

`hashObjects`, `hash2`, `hash3`, and `hash4` generate high-quality hashCodes for
a list of objects, or 2, 3, or 4 arguments respectively.

[quiver.core]: https://pub.dev/documentation/quiver/latest/quiver.core/quiver.core-library.html

## [quiver.iterables][]

`concat`, `count`, `cycle`, `enumerate`, `merge`, `partition`, `range`, and
`zip` create, transform, or combine Iterables in different ways, similar to
Python's itertools.

`min`, `max`, and `extent` retrieve the minimum and maximum elements from an
iterable.

`GeneratingIterable` is an easy way to create lazy iterables that produce
elements by calling a function. A common use-case is to traverse properties in
an object graph, like the parent relationship in a tree.

`InfiniteIterable` is a base class for Iterables that throws on operations that
require a finite length.

[quiver.iterables]: https://pub.dev/documentation/quiver/latest/quiver.iterables/quiver.iterables-library.html

## [quiver.pattern][]

pattern.dart container utilities for work with `Pattern`s and `RegExp`s.

`Glob` implements glob patterns that are commonly used with filesystem paths.

`matchesAny` combines multiple Patterns into one, and allows for exclusions.

`matchesFull` returns true if a Pattern matches an entire String.

`escapeRegex` escapes special regex characters in a String so that it can be
used as a literal match inside of a RegExp.

[quiver.pattern]: https://pub.dev/documentation/quiver/latest/quiver.pattern/quiver.pattern-library.html

## [quiver.strings][]

`isBlank` checks if a string is `null`, empty or made of whitespace characters.

`isNotBlank` checks if a string is not `null`, and not blank.

`isEmpty` checks if a string is `null` or empty.

`isNotEmpty` checks if a string is not `null` and not empty.

`equalsIgnoreCase` checks if two strings are equal, ignoring case.

`compareIgnoreCase` compares two strings, ignoring case.

`loop` allows you to loop through characters in a string starting and ending at
arbitrary indices. Out of bounds indices allow you to wrap around the string,
supporting a number of use-cases, including:

  * Rotating: `loop('lohel', -3, 2) => 'hello'`
  * Repeating, like `String`'s `operator*`, but with better character-level
    control, e.g.: `loop('la ', 0, 8) => 'la la la'  // no trailing space`
  * Tailing: `loop('/path/to/some/file.txt', -3) => 'txt'`
  * Reversing: `loop('top', 3, 0) => 'pot'`

[quiver.strings]: https://pub.dev/documentation/quiver/latest/quiver.strings/quiver.strings-library.html

## [quiver.time][]

`Clock` provides points in time relative to the current point in time, for
example: now, 2 days ago, 4 weeks from now, etc. For testability, use Clock
rather than other ways of accessing time, like `new DateTime()`, so that you
can use a fake time function in your tests to control time.

`Now` is a typedef for functions that return the current time in microseconds,
since Clock deals in DateTime which only have millisecond accuracy.

`aMicrosecond`, `aMillisecond`, `aSecond`, `aMinute`, `anHour`, `aDay`, and
`aWeek` are unit duration constants to allow writing for example:

* `aDay` vs. `const Duration(days: 1)`
* `aSecond * 30` vs. `const Duration(seconds: 30)`

[quiver.time]: https://pub.dev/documentation/quiver/latest/quiver.time/quiver.time-library.html


Testing Libraries
-----------------

The Quiver testing libraries are intended to be used in testing code, not
production code. It currently consists of fake implementations of some Quiver
interfaces.

## [quiver.testing.async][]

`FakeAsync` enables testing of units which depend upon timers and microtasks.
It supports fake advancements of time and the microtask queue, which cause fake
timers and microtasks to be processed. A `Clock` is provided from which to read
the current fake time.  Faking synchronous or blocking time advancement is also
supported.

[quiver.testing.async]: https://pub.dev/documentation/quiver/latest/quiver.testing.async/quiver.testing.async-library.html

## [quiver.testing.equality][]

`areEqualityGroups` is a matcher that supports testing `operator==` and
`hashCode` implementations.

[quiver.testing.equality]: https://pub.dev/documentation/quiver/latest/quiver.testing.equality/quiver.testing.equality-library.html

## [quiver.testing.time][]

`FakeStopwatch` is a Stopwatch that uses a provided `now()` function to get the
current time.

[quiver.testing.time]: https://pub.dev/documentation/quiver/latest/quiver.testing.time/quiver.testing.time-library.html
