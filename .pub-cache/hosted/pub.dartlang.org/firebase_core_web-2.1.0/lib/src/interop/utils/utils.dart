// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as util;

import 'es6_interop.dart';
import 'func.dart';
import 'js_interop.dart' as js;

/// Returns Dart representation from JS Object.
///
/// The optional [customDartify] function may return `null` to indicate,
/// that it could not handle the given JS Object.
dynamic dartify(
  Object? jsObject, [
  Object? Function(Object? object)? customDartify,
]) {
  if (_isBasicType(jsObject)) {
    return jsObject;
  }

  // Handle list
  if (jsObject is Iterable) {
    return jsObject.map((item) => dartify(item, customDartify)).toList();
  }

  var jsDate = js.dartifyDate(jsObject!);
  if (jsDate != null) {
    return jsDate;
  }

  Object? value = customDartify?.call(jsObject);

  if (value == null) {
    var keys = js.objectKeys(jsObject);
    var map = <String, dynamic>{};
    for (final key in keys) {
      map[key] = dartify(util.getProperty(jsObject, key), customDartify);
    }
    return map;
  }

  return value;
}

// Converts an Iterable into a JS Array
dynamic jsifyList(
  Iterable list, [
  Object? Function(Object? object)? customJsify,
]) {
  return js.toJSArray(list.map((item) => jsify(item, customJsify)).toList());
}

/// Returns the JS implementation from Dart Object.
///
/// The optional [customJsify] function may return `null` to indicate,
/// that it could not handle the given Dart Object.
dynamic jsify(
  Object? dartObject, [
  Object? Function(Object? object)? customJsify,
]) {
  if (_isBasicType(dartObject)) {
    if (dartObject == null) {
      return null;
    }
    return dartObject;
  }

  if (dartObject is Iterable) {
    return jsifyList(dartObject, customJsify);
  }

  if (dartObject is Map) {
    var jsMap = util.newObject();
    dartObject.forEach((key, value) {
      util.setProperty(jsMap, key, jsify(value, customJsify));
    });
    return jsMap;
  }

  if (dartObject is Function) {
    return allowInterop(dartObject);
  }

  Object? value = customJsify?.call(dartObject);

  if (value == null) {
    throw ArgumentError.value(dartObject, 'dartObject', 'Could not convert');
  }

  return value;
}

/// Calls [method] on JavaScript object [jsObject].
dynamic callMethod(Object jsObject, String method, List<dynamic> args) =>
    util.callMethod(jsObject, method, args);

/// Returns `true` if the [value] is a very basic built-in type - e.g.
/// `null`, [num], [bool] or [String]. It returns `false` in the other case.
bool _isBasicType(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return true;
  }
  return false;
}

/// Handles the [PromiseJsImpl] object.
Future<T> handleThenable<T>(PromiseJsImpl<T> thenable) async {
  return util.promiseToFuture(thenable);
}

/// Handles the [Future] object with the provided [mapper] function.
PromiseJsImpl<S> handleFutureWithMapper<T, S>(
  Future<T> future,
  Func1<T, S> mapper,
) {
  return PromiseJsImpl<S>(allowInterop((
    Function(S) resolve,
    Function(Object) reject,
  ) {
    future.then((value) {
      var mappedValue = mapper(value);
      resolve(mappedValue);
    }).catchError((error) => reject(error));
  }));
}
