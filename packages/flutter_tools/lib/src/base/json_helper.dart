// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../convert.dart';

/// A helper class for working with raw json objects returned by [jsonDecode].
/// Avoids the hassle of parsing dynamic objects. Intended to be used for
/// one-off json parsing that does not need [json_serializer]. It will simply
/// throw exceptions if any of the traversing steps failed.
class JsonHelper {
  const JsonHelper(this._jsonObject);

  /// Create a JsonHelper by parsing a json [String].
  factory JsonHelper.fromJson(String str) {
    return JsonHelper(jsonDecode(str));
  }

  final dynamic _jsonObject;

  /// Traverse the underlying object by [String] key if such object is a
  /// [Map], or [int] index if such object is a [List].
  ///
  /// Throws [TypeError] if the underlying object is not a [List] and an [int]
  /// index is given, or such object is not a [Map] and a [String] key is given.
  /// Throws a [JsonHelperException] if keyOrIndex is neither an int or a String.
  ///
  /// A convenient but non-typesafe shorthand for [get] and [at].
  JsonHelper operator [](dynamic keyOrIndex) {
    if (keyOrIndex is int) {
      return _at(keyOrIndex);
    }
    if (keyOrIndex is String) {
      return _get(keyOrIndex);
    }
    throw const JsonHelperException('keyOrIndex must be int or String');
  }

  /// Filters the underlying object as a [List] by its elements.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterByElement(bool Function(dynamic) func) {
    final List<dynamic> arr = asList;
    return JsonHelper(arr.where(_wrapTypeErrorToFalse<dynamic>(func)));
  }

  /// Filters the underlying object as a [Map] by its entries.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterByEntry(bool Function(MapEntry<String, dynamic>) func) {
    final Map<String, dynamic> map = asMap;
    return JsonHelper(
      Map<String, dynamic>.fromEntries(map.entries.where(
        _wrapTypeErrorToFalse<MapEntry<String, dynamic>>(func),
      )),
    );
  }

  /// Filters the underlying object as a [List] by its indices.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterByIndex(bool Function(int) func) {
    final List<dynamic> arr = <dynamic>[];
    final bool Function(int) f = _wrapTypeErrorToFalse<int>(func);
    for (int i = 0; i < asList.length; i++) {
      if (f(i)) {
        arr.add(asList[i]);
      }
    }
    return JsonHelper(arr);
  }

  /// Filters the underlying object as a [Map] by its keys.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterByKey(bool Function(String) func) {
    final Map<String, dynamic> map = asMap;
    final bool Function(String) wrappedFunc =
        _wrapTypeErrorToFalse<String>(func);
    bool f(MapEntry<String, dynamic> mn) => wrappedFunc(mn.key);
    return JsonHelper(
      Map<String, dynamic>.fromEntries(map.entries.where(f)),
    );
  }

  /// Wraps func such that if func throws a [TypeError], return false
  /// instead of throwing.
  bool Function(T) _wrapTypeErrorToFalse<T>(bool Function(T) func) {
    return (T t) {
      try {
        return func(t);
      } on TypeError {
        return false;
      }
    };
  }

  /// Traverse the underlying object by an [int] index.
  ///
  /// Throws [TypeError] if the underlying object is not a [List].
  JsonHelper at(int index) {
    return _at(index);
  }

  /// Traverse the underlying object by a [String] key.
  ///
  /// Throws [TypeError] if the underlying object is not a [Map].
  JsonHelper get(String key) {
    return _get(key);
  }

  JsonHelper _at(int index) {
    final List<dynamic> l = asList;
    return JsonHelper(l[index]);
  }

  JsonHelper _get(String key) {
    final Map<String, dynamic> m = asMap;
    return JsonHelper(m[key]);
  }

  /// Try to cast the underlying object into an [int].
  ///
  /// Throws [TypeError] if the underlying object is not an [int].
  int get asInt => _jsonObject as int;

  /// Try to cast the underlying object into a [double].
  ///
  /// Throws [TypeError] if the underlying object is not a [double].
  double get asDouble => _jsonObject as double;

  /// Try to cast the underlying object into a [num].
  ///
  /// Throws [TypeError] if the underlying object is not a [num].
  num get asNum => _jsonObject as num;

  /// Try to cast the underlying object into a [String].
  ///
  /// Throws [TypeError] if the underlying object is not a [String].
  String get asString => _jsonObject as String;

  /// Try to cast the underlying object into a [bool].
  ///
  /// Throws [TypeError] if the underlying object is not a [bool].
  bool get asBool => _jsonObject as bool;

  /// Try to cast the underlying object into a [List].
  ///
  /// Throws [TypeError] if the underlying object is not a [List].
  List<dynamic> get asList {
    if (_jsonObject is List<dynamic>) {
      return _jsonObject as List<dynamic>;
    }
    if (_jsonObject is Iterable<dynamic>) {
      final Iterable<dynamic> iter = _jsonObject as Iterable<dynamic>;
      return iter.toList();
    }
    throw const JsonHelperException('jsonObject cannot be converted to List');
  }

  /// Try to cast the underlying object into a [Map].
  ///
  /// Throws [TypeError] if the underlying object is not a [Map].
  Map<String, dynamic> get asMap => _jsonObject as Map<String, dynamic>;

  /// Returns whether the underlying object is null.
  bool get isNull => _jsonObject == null;

  /// Returns the underlying object.
  dynamic get asDynamic => _jsonObject;
}

/// An [Exception] that can be thrown by [JsonHelper]. Used when there is a
/// condition that should throw an [Exception] but does not involve casting.
class JsonHelperException implements Exception {
  const JsonHelperException(this.msg);

  /// Error message of such exception
  final String msg;

  @override
  String toString() => 'JsonHelper parsing failed: $msg';
}
