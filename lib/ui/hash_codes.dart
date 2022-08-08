// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
part of dart.ui;

// Examples can assume:
// // ignore_for_file: deprecated_member_use
// int foo = 0;
// int bar = 0;
// List<int> quux = <int>[];
// int baz = 0;

class _HashEnd { const _HashEnd(); }
const _HashEnd _hashEnd = _HashEnd();

// ignore: avoid_classes_with_only_static_members
/// Jenkins hash function, optimized for small integers.
//
// Borrowed from the dart sdk: sdk/lib/math/jenkins_smi_hash.dart.
class _Jenkins {
  static int combine(int hash, Object? o) {
    assert(o is! Iterable);
    hash = 0x1fffffff & (hash + o.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Combine up to twenty objects' hash codes into one value.
///
/// If you only need to handle one object's hash code, then just refer to its
/// [Object.hashCode] getter directly.
///
/// If you need to combine an arbitrary number of objects from a [List] or other
/// [Iterable], use [hashList]. The output of [hashList] can be used as one of
/// the arguments to this function.
///
/// For example:
///
/// ```dart
/// int get hashCode => hashValues(foo, bar, hashList(quux), baz);
/// ```
///
/// ## Deprecation
///
/// This function has been replaced by [Object.hash], so that it can be used
/// outside of Flutter as well. The new function is a drop-in replacement.
///
/// The [hashList] function has also been replaced, [Object.hashAll] is the new
/// function. The example above therefore is better written as:
///
/// ```dart
/// int get hashCode => Object.hash(foo, bar, Object.hashAll(quux), baz);
/// ```
///
/// If `quux` in this example was nullable, then it would need special handling,
/// because [Object.hashAll]'s argument is not nullable:
///
/// ```dart
/// int get hashCode => Object.hash(foo, bar, quux == null ? null : Object.hashAll(quux), baz);
/// ```
@Deprecated(
  'Use Object.hash() instead. '
  'This feature was deprecated in v3.1.0-0.0.pre.897'
)
int hashValues(
  Object? arg01,            Object? arg02,          [ Object? arg03 = _hashEnd,
  Object? arg04 = _hashEnd, Object? arg05 = _hashEnd, Object? arg06 = _hashEnd,
  Object? arg07 = _hashEnd, Object? arg08 = _hashEnd, Object? arg09 = _hashEnd,
  Object? arg10 = _hashEnd, Object? arg11 = _hashEnd, Object? arg12 = _hashEnd,
  Object? arg13 = _hashEnd, Object? arg14 = _hashEnd, Object? arg15 = _hashEnd,
  Object? arg16 = _hashEnd, Object? arg17 = _hashEnd, Object? arg18 = _hashEnd,
  Object? arg19 = _hashEnd, Object? arg20 = _hashEnd ]) {
  int result = 0;
  result = _Jenkins.combine(result, arg01);
  result = _Jenkins.combine(result, arg02);
  if (!identical(arg03, _hashEnd)) {
    result = _Jenkins.combine(result, arg03);
    if (!identical(arg04, _hashEnd)) {
      result = _Jenkins.combine(result, arg04);
      if (!identical(arg05, _hashEnd)) {
        result = _Jenkins.combine(result, arg05);
        if (!identical(arg06, _hashEnd)) {
          result = _Jenkins.combine(result, arg06);
          if (!identical(arg07, _hashEnd)) {
            result = _Jenkins.combine(result, arg07);
            if (!identical(arg08, _hashEnd)) {
              result = _Jenkins.combine(result, arg08);
              if (!identical(arg09, _hashEnd)) {
                result = _Jenkins.combine(result, arg09);
                if (!identical(arg10, _hashEnd)) {
                  result = _Jenkins.combine(result, arg10);
                  if (!identical(arg11, _hashEnd)) {
                    result = _Jenkins.combine(result, arg11);
                    if (!identical(arg12, _hashEnd)) {
                      result = _Jenkins.combine(result, arg12);
                      if (!identical(arg13, _hashEnd)) {
                        result = _Jenkins.combine(result, arg13);
                        if (!identical(arg14, _hashEnd)) {
                          result = _Jenkins.combine(result, arg14);
                          if (!identical(arg15, _hashEnd)) {
                            result = _Jenkins.combine(result, arg15);
                            if (!identical(arg16, _hashEnd)) {
                              result = _Jenkins.combine(result, arg16);
                              if (!identical(arg17, _hashEnd)) {
                                result = _Jenkins.combine(result, arg17);
                                if (!identical(arg18, _hashEnd)) {
                                  result = _Jenkins.combine(result, arg18);
                                  if (!identical(arg19, _hashEnd)) {
                                    result = _Jenkins.combine(result, arg19);
                                    if (!identical(arg20, _hashEnd)) {
                                      result = _Jenkins.combine(result, arg20);
                                      // I can see my house from here!
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  return _Jenkins.finish(result);
}

/// Combine the [Object.hashCode] values of an arbitrary number of objects from
/// an [Iterable] into one value. This function will return the same value if
/// given null as if given an empty list.
///
/// ## Deprecation
///
/// This function has been replaced by [Object.hashAll], so that it can be used
/// outside of Flutter as well. The new function is a drop-in replacement, except
/// that the argument must not be null.
///
/// There is also a new function, [Object.hashAllUnordered], which is similar
/// but returns the same hash code regardless of the order of the elements in
/// the provided iterable.
@Deprecated(
  'Use Object.hashAll() or Object.hashAllUnordered() instead. '
  'This feature was deprecated in v3.1.0-0.0.pre.897'
)
int hashList(Iterable<Object?>? arguments) {
  int result = 0;
  if (arguments != null) {
    for (final Object? argument in arguments) {
      result = _Jenkins.combine(result, argument);
    }
  }
  return _Jenkins.finish(result);
}
