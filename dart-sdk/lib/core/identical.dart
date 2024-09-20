// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Check whether two object references are to the same object.
///
/// Dart *values*, what is stored in variables, are *object references*.
/// There can be multiple references to the same object.
///
/// A Dart object has an identity, which separates it from other objects,
/// even ones with otherwise identical state.
/// The `identical` function exposes whether two object references
/// refer to the *same* object.
///
/// If an `identical` call returns `true`, it is guaranteed that there is no
/// way to distinguish the two arguments.
/// If it returns `false`, the arguments are only known
/// to not be the same object.
///
/// A non-constant invocation of a generative (non-factory) constructor,
/// or evaluating a non-constant list, set or map literal,
/// always creates a *new* object,
/// which is not identical to any existing object.
///
/// *Constant canonicalization* ensures that the result of two compile-time
/// constant expressions which create objects with the same state,
/// also evaluate to references to the same, canonical, instance.
/// Example:
/// ```dart
/// print(identical(const <int>[1], const <int>[1])); // true
/// ```
///
/// Integers and doubles are special, they do not allow creating new instances
/// at all. If two integers are equal, they are also always identical.
/// If two doubles have the same binary representation, they are identical
/// (with caveats around [double.nan] and `-0.0` on web platforms).
///
/// [Record] values do not have a _persistent_ identity.
/// This allows compilers to split a record into its parts and rebuild it later,
/// without having to worry about creating an object with the same identity.
/// A record *may* be identical to another record with the same shape,
/// if all the corresponding fields are identical, or it may not,
/// but it is never identical to anything else.
///
/// Example:
/// ```dart
/// var o = new Object();
/// var isIdentical = identical(o, new Object()); // false, different objects.
/// isIdentical = identical(o, o); // true, same object.
/// isIdentical = identical(const Object(), const Object()); // true, const canonicalizes.
/// isIdentical = identical([1], [1]); // false, different new objects.
/// isIdentical = identical(const [1], const [1]); // true.
/// isIdentical = identical(const [1], const [2]); // false.
/// isIdentical = identical(2, 1 + 1); // true, integers canonicalize.
///
/// var pair = (1, "a"); // Create a record.
/// isIdentical = identical(pair, pair); // true or false, can be either.
///
/// var pair2 = (1, "a"); // Create another(?) record.
/// isIdentical = identical(pair, pair2); // true or false, can be either.
///
/// isIdentical = identical(pair, (2, "a")); // false, not identical values.
/// isIdentical = identical(pair, (1, "a", more: true)); // false, wrong shape.
/// ```
external bool identical(Object? a, Object? b);

/// The identity hash code of [object].
///
/// Returns the value that the original [Object.hashCode] would return
/// on this object, even if `hashCode` has been overridden.
///
/// This hash code is compatible with [identical],
/// which means that it's guaranteed to give the same result every time
/// it's passed the same argument, throughout a single program execution,
/// for any *non-record* object.
///
/// The identity hash code of a [Record] is undefined,
/// because a record doesn't have a guranteed persistent identity.
/// A record values identity and identity hash code can change at any time.
///
/// ```dart import:dart:collection
/// var identitySet = HashSet(equals: identical, hashCode: identityHashCode);
/// var dt1 = DateTime.now();
/// var dt2 = DateTime.fromMicrosecondsSinceEpoch(dt1.microsecondsSinceEpoch);
/// assert(dt1 == dt2);
/// identitySet.add(dt1);
/// print(identitySet.contains(dt1)); // true
/// print(identitySet.contains(dt2)); // false
/// ```
@pragma("vm:entry-point")
external int identityHashCode(Object? object);
