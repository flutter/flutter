// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// A descriptor for the type of data contained in a [ClipboardData].
enum ClipboardDataType {
  /// A `text/plain` data type contained in clipboard.
  text,

  /// An image encoded as a png.
  image,
}

/// Data stored on the system clipboard.
///
/// The system clipboard can contain data of various media types. This data
/// structure currently supports only plain text data, in the [text] property.
@immutable
class ClipboardData {
  //// Deprecated? Or updated to require type.
  /// Creates data for the system clipboard.
  const ClipboardData({ this.text }) : dataType = ClipboardDataType.text, image = null;

  /// Creates image data for the system clipboard.
  const ClipboardData.image(this.image) : dataType = ClipboardDataType.image, text = null;

  /// Creates text data for the system clipboard.
  const ClipboardData.text(this.text) : dataType = ClipboardDataType.text, image = null;

  /// Plain text variant of this clipboard data.
  final String? text;

  /// Image variant of this clipboard data.
  final Uint8List? image;

  /// The type of data contained in this entity.
  final ClipboardDataType dataType;
}

/// Utility methods for interacting with the system's clipboard.
class Clipboard {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  Clipboard._();

  // Constants for common [getData] [format] types.

  /// Plain text data format string.
  ///
  /// Used with [getData].
  static const String kTextPlain = 'text/plain';

  /// A PNG encoded image.
  ///
  /// USed with [getData].
  static const String kImagePng = 'image/png';

  /// Stores the given clipboard data on the clipboard.
  static Future<void> setData(ClipboardData data) async {
    await SystemChannels.platform.invokeMethod<void>(
      'Clipboard.setData',
      <String, dynamic>{
        'text': data.text,
        'image': data.image,
      },
    );
  }

  /// Retrieves data from the clipboard that matches the given format.
  ///
  /// The `format` argument specifies the media type, such as `text/plain`, of
  /// the data to obtain.
  ///
  /// Returns a future which completes to null if the data could not be
  /// obtained, and to a [ClipboardData] object if it could.
  static Future<ClipboardData?> getData(String format) async {
    final Map<String, dynamic>? result = await SystemChannels.platform.invokeMethod(
      'Clipboard.getData',
      format,
    );
    if (result == null)
      return null;
    if (result.containsKey('text')) {
      return ClipboardData.text(result['text'] as String?);
    }
    if (result.containsKey('image')) {
      /// JSON is not good at this.
      final List<int>? data = (result['image'] as List<dynamic>?)?.cast<int>().toList();
      if (data == null) {
        return null;
      }
      return ClipboardData.image(Uint8List.fromList(data));
    }
    return null;
  }
}
