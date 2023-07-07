// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../protobuf.dart' show BuilderInfo;

/// Note that this class does not claim to implement [Map]. Instead, this needs
/// to be specified using a dart_options.imports clause specifying MapMixin as a
/// parent mixin to PbMapMixin.
///
/// Since PbMapMixin is built in, this is done automatically, so this mixin can
/// be enabled by specifying only a dart_options.mixin option.
abstract class PbMapMixin {
  // GeneratedMessage properties and methods used by this mixin.

  BuilderInfo get info_;
  void clear();
  int? getTagNumber(String fieldName);
  dynamic getField(int tagNumber);
  void setField(int tagNumber, Object value);

  dynamic operator [](key) {
    if (key is! String) return null;
    var tag = getTagNumber(key);
    if (tag == null) return null;
    return getField(tag);
  }

  operator []=(key, val) {
    var tag = getTagNumber(key as String);
    if (tag == null) {
      throw ArgumentError.value(key, 'key',
          "field '$key' not found in ${info_.qualifiedMessageName}");
    }
    setField(tag, val);
  }

  Iterable<String> get keys => info_.byName.keys;

  bool containsKey(Object? key) => info_.byName.containsKey(key);

  int get length => info_.byName.length;

  dynamic remove(key) {
    throw UnsupportedError(
        'remove() not supported by ${info_.qualifiedMessageName}');
  }
}
