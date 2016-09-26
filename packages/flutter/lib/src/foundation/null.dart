// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'assertions.dart';

/// A mixin that can be used to create "helpful null" objects.
///
/// A "helpful null" is a class whose instances are equal to null,
/// and for which all method calls throw an error with the given
/// error message.
///
/// To use this mixin class, use the following pattern:
///
/// ```dart
/// class _NullX extends DebugHelpfulNullMixin implements X {
///   const _NullX(String message) : super(message);
/// }
/// ```
///
/// To use a helpful null, return a value that might be null as follows:
///
/// ```dart
/// X get something => _something ?? debugHelpfulNull<_NullX>(const _NullX('...'));
/// ```
///
/// ...where the "..." string explains how to make sure that `something` is
/// initialized correctly.
abstract class DebugHelpfulNullMixin {
  /// Creates a "helpful null" object with the given message.
  const DebugHelpfulNullMixin(this.message);

  /// A message that will be shown when this object is dereferenced.
  final String message;

  @override
  void noSuchMethod(Invocation invocation) => throw new FlutterError(message);

  @override
  int get hashCode => null.hashCode();

  @override
  operator ==(dynamic other) {
    return null == other;
  }
}

/// Returns the given object in debug mode, and null in release mode.
///
/// The given object must be a class that mixes in the [DebugHelpfulNullMixin] class.
dynamic/*=T*/ debugHelpfulNull/*<T extends DebugHelpfulNullMixin>*/(DebugHelpfulNullMixin/*=T*/ instance) {
  dynamic/*=T*/ result;
  assert(() {
    result = instance;
    return true;
  });
  return result;
}
