// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Data stored on the system clipboard.
///
/// The system clipboard can contain data of various media types. This data
/// structure currently supports only plain text data, in the [text] property.
@immutable
class ClipboardData {
  /// Creates data for the system clipboard.
  const ClipboardData({ this.text });

  /// Plain text variant of this clipboard data.
  final String? text;
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

  /// Stores the given clipboard data on the clipboard.
  static Future<void> setData(ClipboardData data) async {
    await SystemChannels.platform.invokeMethod<void>(
      'Clipboard.setData',
      <String, dynamic>{
        'text': data.text,
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
    return ClipboardData(text: result['text'] as String?);
  }

  /// Returns a future that resolves to true iff the clipboard contains string
  /// data.
  ///
  /// See also:
  ///   * [The iOS hasStrings method](https://developer.apple.com/documentation/uikit/uipasteboard/1829416-hasstrings?language=objc).
  static Future<bool> hasStrings() async {
    final Map<String, dynamic>? result = await SystemChannels.platform.invokeMethod(
      'Clipboard.hasStrings',
      Clipboard.kTextPlain,
    );
    if (result == null) {
      return false;
    }
    return result['value'] as bool;
  }
}
