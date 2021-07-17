// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A helper class for working with raw json objects returned by [jsonDecode].
/// Avoids the hassle of parsing dynamic objects. Intended to be used for
/// one-off json parsing that does not need [json_serializer]. It will simply
/// throw exceptions if any of the traversing steps failed.
class JsonHelper {
  const JsonHelper(this._jsonObject);

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

}

class JsonHelperException implements Exception {
  const JsonHelperException(this.msg);
  final String msg;
  @override
  String toString() => 'JsonHelper parsing failed: $msg';
}
