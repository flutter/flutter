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


  factory JsonHelper.fromJson(String str){
    return JsonHelper(jsonDecode(str));
  }

  final dynamic _jsonObject;

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

  int get asInt => _jsonObject as int;

  double get asDouble => _jsonObject as double;

  num get asNum => _jsonObject as num;

  String get asString => _jsonObject as String;

  bool get asBool => _jsonObject as bool;

  List<dynamic> get asList => _jsonObject as List<dynamic>;

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
