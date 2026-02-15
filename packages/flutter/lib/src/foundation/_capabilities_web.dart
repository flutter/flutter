// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

// These values are set by the engine. They are used to determine if the
// application is using canvaskit or skwasm.
@JS('window.flutterCanvasKit')
external JSAny? get _windowFlutterCanvasKit;

@JS('window._flutter_skwasmInstance')
external JSAny? get _skwasmInstance;

/// The web implementation of [isCanvasKit]
bool get isCanvasKit => _windowFlutterCanvasKit != null;

/// The web implementation of [isSkwasm]
bool get isSkwasm => _skwasmInstance != null;
