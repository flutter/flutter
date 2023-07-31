[![Dart CI](https://github.com/dart-lang/collection/actions/workflows/ci.yml/badge.svg)](https://github.com/dart-lang/collection/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/collection.svg)](https://pub.dev/packages/collection)
[![package publisher](https://img.shields.io/pub/publisher/collection.svg)](https://pub.dev/packages/collection/publisher)

Contains utility functions and classes in the style of `dart:collection` to make
working with collections easier.

## Algorithms

The package contains functions that operate on lists.

It contains ways to shuffle a `List`, do binary search on a sorted `List`, and
various sorting algorithms.

## Equality

The package provides a way to specify the equality of elements and collections.

Collections in Dart have no inherent equality. Two sets are not equal, even
if they contain exactly the same objects as elements.

The `Equality` interface provides a way to define such an equality. In this
case, for example, `const SetEquality(IdentityEquality())` is an equality
that considers two sets equal exactly if they contain identical elements.

Equalities are provided for `Iterable`s, `List`s, `Set`s, and `Map`s, as well as
combinations of these, such as:

```dart
const MapEquality(IdentityEquality(), ListEquality());
```

This equality considers maps equal if they have identical keys, and the
corresponding values are lists with equal (`operator==`) values.

## Iterable Zip

Utilities for "zipping" a list of iterables into an iterable of lists.

## Priority Queue

An interface and implementation of a priority queue.

## Wrappers

The package contains classes that "wrap" a collection.

A wrapper class contains an object of the same type, and it forwards all
methods to the wrapped object.

Wrapper classes can be used in various ways, for example to restrict the type
of an object to that of a supertype, or to change the behavior of selected
functions on an existing object.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/collection/issues

## Publishing automation

For information about our publishing automation and release process, see
https://github.com/dart-lang/ecosystem/wiki/Publishing-automation.
