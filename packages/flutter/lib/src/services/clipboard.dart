// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/editing.dart' as mojom;

import 'shell.dart';

export 'package:flutter_services/editing.dart' show ClipboardData;

mojom.ClipboardProxy _initClipboardProxy() {
  return shell.connectToApplicationService('mojo:clipboard', mojom.Clipboard.connectToService);
}

final mojom.ClipboardProxy _clipboardProxy = _initClipboardProxy();

/// An interface to the system's clipboard. Wraps the mojo interface.
class Clipboard {
  /// Constants for common [getClipboardData] [format] types.
  static final String kTextPlain = 'text/plain';

  Clipboard._();

  /// Stores the given clipboard data on the clipboard.
  static void setClipboardData(mojom.ClipboardData clip) {
    _clipboardProxy.setClipboardData(clip);
  }

  /// Retrieves data from the clipboard that matches the given format.
  ///
  ///  * `format` is a media type, such as `text/plain`.
  static Future<mojom.ClipboardData> getClipboardData(String format) {
    Completer<mojom.ClipboardData> completer = new Completer<mojom.ClipboardData>();
    _clipboardProxy.getClipboardData(format, (mojom.ClipboardData clip) {
      completer.complete(clip);
    });
    return completer.future;
  }
}
