// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class JsonParsingContext {
  // A list of indices into maps and lists pointing to the current root.
  final List<String> _path = <String>[];
  final bool ignoreUnknownFields;
  final bool supportNamesWithUnderscores;
  final bool permissiveEnums;

  JsonParsingContext(this.ignoreUnknownFields, this.supportNamesWithUnderscores,
      this.permissiveEnums);

  void addMapIndex(String index) {
    _path.add(index);
  }

  void addListIndex(int index) {
    _path.add(index.toString());
  }

  void popIndex() {
    _path.removeLast();
  }

  /// Creates a [FormatException] indicating the indices to the current path.
  Exception parseException(String message, Object? source) {
    var formattedPath = _path.map((s) => '["$s"]').join();
    return FormatException(
        'Protobuf JSON decoding failed at: root$formattedPath. $message',
        source);
  }
}
