// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// For now, we're hiding dart:js_interop's `@JS` to avoid a conflict with
// package:js' `@JS`. In the future, we should be able to remove package:js
// altogether and just import dart:js_interop.
import 'dart:js_interop' hide JS;
import 'package:js/js.dart';

// This value is set by the engine. It is used to determine if the application is
// using canvaskit.
@JS('window.flutterCanvasKit')
external JSAny? get _windowFlutterCanvasKit;

/// The web implementation of [isCanvasKit]
bool get isCanvasKit => _windowFlutterCanvasKit != null;
