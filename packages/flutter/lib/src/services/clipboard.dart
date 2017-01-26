// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Data stored on the system clipboard.
///
/// The system clipboard can contain data of various media types. This data
/// structure currently supports only plain text data, in the [text] property.
class ClipboardData {
  /// Creates data for the system clipboard.
  const ClipboardData({ this.text });

  /// Plain text variant of this clipboard data.
  final String text;
}

const String _kChannelName = 'flutter/platform';

/// Utility methods for interacting with the system's clipboard.
class Clipboard {
  Clipboard._();

  // Constants for common [getData] [format] types.

  /// Plain text data format string.
  ///
  /// Used with [getData].
  static const String kTextPlain = 'text/plain';

  /// Stores the given clipboard data on the clipboard.
  static Future<Null> setData(ClipboardData data) async {
    await PlatformMessages.invokeMethod(
       _kChannelName,
      'Clipboard.setData',
      <Map<String, dynamic>>[<String, dynamic>{
        'text': data.text,
      }],
    );
  }

  /// Retrieves data from the clipboard that matches the given format.
  ///
  /// The `format` argument specifies the media type, such as `text/plain`, of
  /// the data to obtain.
  ///
  /// Returns a future which completes to null if the data could not be
  /// obtained, and to a [ClipboardData] object if it could.
  static Future<ClipboardData> getData(String format) async {
    Map<String, dynamic> result = await PlatformMessages.invokeMethod(
      _kChannelName,
      'Clipboard.getData',
      <String>[format]
    );
    if (result == null)
      return null;
    return new ClipboardData(text: result['text']);
  }
}
