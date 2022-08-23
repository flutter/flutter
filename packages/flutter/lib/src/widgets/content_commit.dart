import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A class representing data for the `onContentCommitted` callback on text fields.
///
/// This will be used when content is inserted into a text field. The class holds
/// information for the mime type, URI (location), and bytedata for the inserted
/// content.
@immutable
class CommittedContent {
  /// Creates an object to represent content that is committed from a text field
  ///
  /// Any parameters can be null.
  const CommittedContent({this.mimeType, this.uri, this.data});

  /// Converts Map received from Flutter Engine into the Dart class.
  CommittedContent.fromMap(Map<String, dynamic>? metadata):
        mimeType = metadata != null && metadata.isNotEmpty ? metadata['mimeType'] as String? : null,
        uri = metadata != null && metadata.isNotEmpty ? metadata['uri'] as String? : null,
        data = metadata != null && metadata.isNotEmpty ? Uint8List.fromList(
            List<int>.from(metadata['data'] as Iterable<dynamic>)) : null;

  /// Mime type of inserted content.
  final String? mimeType;

  /// URI (location) of inserted content.
  final String? uri;

  /// Bytedata of inserted content.
  final Uint8List? data;

  /// Convenience getter to check if bytedata is available for the inserted content.
  bool get hasData => data != null && data!.isNotEmpty;

  @override
  String toString() => '${objectRuntimeType(this, 'CommittedContent')}($mimeType, $uri, $data)';

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CommittedContent
        && other.mimeType == mimeType
        && other.uri == uri
        && other.data == data;
  }

  @override
  int get hashCode => hashValues(mimeType, uri, data);
}
