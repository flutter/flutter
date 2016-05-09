// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky_services/editing/editing.mojom.dart' as mojom;

import 'shell.dart';

export 'package:sky_services/editing/editing.mojom.dart' show ClipboardData;

mojom.ClipboardProxy _initClipboardProxy() {
  mojom.ClipboardProxy proxy = new mojom.ClipboardProxy.unbound();
  shell.connectToService('mojo:clipboard', proxy);
  return proxy;
}

final mojom.ClipboardProxy _clipboardProxy = _initClipboardProxy();

/// An interface to the system's clipboard. Wraps the mojo interface.
class Clipboard {
  /// Constants for common [getClipboardData] [format] types.
  static final String kTextPlain = 'text/plain';

  Clipboard._();

  Clipboard(this._service);
  final mojom.Clipboard _service;

  static void setClipboardData(mojom.ClipboardData clip) {
    _clipboardProxy.ptr.setClipboardData(clip);
  }

  static Future<mojom.ClipboardData> getClipboardData(String format) async {
    return (await _clipboardProxy.ptr.getClipboardData(format)).clip;
  }
}
