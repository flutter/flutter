// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Data stored on the system clip board.
///
/// The system clip board can contain data of various media types. This data
/// structure currently supports only plain text data in the [text] property.
class ClipboardData {
  /// Creates data for the system clipboard.
  const ClipboardData({ this.text });

  /// Plain text data on the clip board.
  final String text;
}

/// An interface to the system's clipboard.
class Clipboard {
  /// Constants for common [getData] [format] types.
  static final String kTextPlain = 'text/plain';

  Clipboard._();

  /// Stores the given clipboard data on the clipboard.
  static Future<Null> setData(ClipboardData data) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'Clipboard.setData',
      'args': <Map<String, dynamic>>[<String, dynamic>{
        'text': data.text,
      }],
    });
  }

  /// Retrieves data from the clipboard that matches the given format.
  ///
  ///  * `format` is a media type, such as `text/plain`.
  static Future<ClipboardData> getData(String format) async {
    Map<String, dynamic> result =
        await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'Clipboard.getData',
      'args': <String>[format],
    });
    if (result == null)
      return null;
    return new ClipboardData(text: result['text']);
  }
}
