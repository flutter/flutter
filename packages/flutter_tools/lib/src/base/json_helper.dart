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

  /// Transverse the object by [String] key if such object is a [Map], or [int]
  /// index if such object is a [List].
  JsonHelper operator [](dynamic keyOrIndex) {
    if (keyOrIndex is int) {
      final List<dynamic> l = _jsonObject as List<dynamic>;
      return JsonHelper(l[keyOrIndex]);
    }
    if (keyOrIndex is String) {
      final Map<String, dynamic> l = _jsonObject as Map<String, dynamic>;
      return JsonHelper(l[keyOrIndex]);
    }
    throw const JsonHelperException('keyOrIndex must be int or String');
  }

  /// Filter a [List] by its elements.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterList(bool Function(dynamic) func) {
    final List<dynamic> arr = asList;
    return JsonHelper(arr.where(_wrapTypeErrorToFalse<dynamic>(func)));
  }

  /// Filter a [Map] by its entries.
  ///
  /// If func throws a TypeError, it is treated as if it returns false.
  JsonHelper filterMap(bool Function(MapEntry<String, dynamic>) func) {
    final Map<String, dynamic> map = asMap;
    return JsonHelper(
      Map<String, dynamic>.fromEntries(map.entries.where(
        _wrapTypeErrorToFalse<MapEntry<String, dynamic>>(func),
      )),
    );
  }

  /// Filter a [List] by its indices.
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

  /// Filter a [Map] by its keys.
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

  bool Function(T) _wrapTypeErrorToFalse<T>(bool Function(T) func) {
    return (T t) {
      try {
        return func(t);
      } on TypeError {
        return false;
      }
    };
  }

  int get asInt => _jsonObject as int;

  double get asDouble => _jsonObject as double;

  num get asNum => _jsonObject as num;

  String get asString => _jsonObject as String;

  bool get asBool => _jsonObject as bool;

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

  Map<String, dynamic> get asMap => _jsonObject as Map<String, dynamic>;

  bool get isNull => _jsonObject == null;

  dynamic get asDynamic => _jsonObject;
}

class JsonHelperException implements Exception {
  const JsonHelperException(this.msg);

  final String msg;

  @override
  String toString() => 'JsonHelper parsing failed: $msg';
}
