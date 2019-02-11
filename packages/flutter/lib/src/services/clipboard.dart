// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  final String text;
}

/// Utility methods for interacting with the system's clipboard.
class Clipboard {
  Clipboard._();

  // Constants for common [getData] [format] types.

  /// Plain text data format string.
  ///
  /// Used with [getData].
  static const String kTextPlain = 'text/plain';

  /// Whether or not the clipboard is empty.
  ///
  /// If the user has recently started their device and the user has not yet
  /// copied anything, this value will be true.
  ///
  /// By default this value is true.
  static bool get isEmpty => _isEmpty;
  static bool _isEmpty;

  /// Initializes the [isEmpty] variable with whether or not the clipboard is
  /// currently empty.
  ///
  /// Returns the value of [isEmpty].
  static Future<void> queryEmpty() async {
    final Map<String, dynamic> result = await SystemChannels.platform.invokeMethod(
      'Clipboard.getData',
      kTextPlain,
    );
    _isEmpty = result == null;
    if (result != null) {
      final String text = result['text'];
      _isEmpty = text == null || text == '';
    }
    return isEmpty;
  }

  /// Stores the given clipboard data on the clipboard.
  static Future<void> setData(ClipboardData data) async {
    await SystemChannels.platform.invokeMethod<void>(
      'Clipboard.setData',
      <String, dynamic>{
        'text': data.text,
      },
    );
    final String text = data?.text;
    if (text != null && text != '')
      _isEmpty = false;
  }

  /// Retrieves data from the clipboard that matches the given format.
  ///
  /// The `format` argument specifies the media type, such as `text/plain`, of
  /// the data to obtain.
  ///
  /// Returns a future which completes to null if the data could not be
  /// obtained, and to a [ClipboardData] object if it could.
  static Future<ClipboardData> getData(String format) async {
    final Map<String, dynamic> result = await SystemChannels.platform.invokeMethod(
      'Clipboard.getData',
      format,
    );
    if (result == null)
      return null;
    return ClipboardData(text: result['text']);
  }
}
