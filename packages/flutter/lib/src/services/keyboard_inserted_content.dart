// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A class representing rich content (such as a PNG image) inserted via the
/// system input method.
///
/// The following data is represented in this class:
///  - MIME Type
///  - Bytes
///  - URI
@immutable
class KeyboardInsertedContent {
  /// Creates an object to represent content that is inserted from the virtual
  /// keyboard.
  ///
  /// Any parameters can be null.
  const KeyboardInsertedContent({this.mimeType, this.uri, this.data});

  /// Converts JSON received from Flutter Engine into the Dart class.
  KeyboardInsertedContent.fromJson(Map<String, dynamic>? metadata):
      mimeType = metadata != null && metadata.isNotEmpty ? metadata['mimeType'] as String? : null,
      uri = metadata != null && metadata.isNotEmpty ? metadata['uri'] as String? : null,
      data = metadata != null && metadata.isNotEmpty ? Uint8List.fromList(
          List<int>.from(metadata['data'] as Iterable<dynamic>)) : null;

  /// The mime type of inserted content.
  final String? mimeType;

  /// The URI (location) of inserted content, usually a "content://" URI.
  final String? uri;

  /// The bytedata of inserted content.
  final Uint8List? data;

  /// Convenience getter to check if bytedata is available for the inserted content.
  bool get hasData => data?.isNotEmpty ?? false;

  @override
  String toString() => '${objectRuntimeType(this, 'KeyboardInsertedContent')}($mimeType, $uri, $data)';

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is KeyboardInsertedContent
        && other.mimeType == mimeType
        && other.uri == uri
        && other.data == data;
  }

  @override
  int get hashCode => Object.hash(mimeType, uri, data);
}
