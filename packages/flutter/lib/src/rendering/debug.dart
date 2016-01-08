// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

export 'package:flutter/services.dart' show debugPrint;

/// Causes each RenderBox to paint a box around its bounds.
bool debugPaintSizeEnabled = false;

/// The color to use when painting RenderObject bounds.
ui.Color debugPaintSizeColor = const ui.Color(0xFF00FFFF);

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// The color to use when painting alphabetic baselines.
ui.Color debugPaintAlphabeticBaselineColor = const ui.Color(0xFF00FF00);

/// The color ot use when painting ideographic baselines.
ui.Color debugPaintIdeographicBaselineColor = const ui.Color(0xFFFFD000);

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// The color to use when painting Layer borders.
ui.Color debugPaintLayerBordersColor = const ui.Color(0xFFFF9800);

/// Causes RenderBox objects to flash while they are being tapped
bool debugPaintPointersEnabled = false;

/// The color to use when reporting pointers.
int debugPaintPointersColorValue = 0x00BBBB;

/// The color to use when painting RenderError boxes in checked mode.
ui.Color debugErrorBoxColor = const ui.Color(0xFFFF0000);

/// Overlay a rotating set of colors when repainting layers in checked mode.
bool debugEnableRepaintRainbox = false;

/// The current color to overlay when repainting a layer.
HSVColor debugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

/// The amount to increment the hue of the current repaint color.
double debugRepaintRainboxHueIncrement = 2.0;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the call stacks that mark render objects as needing layout.
bool debugPrintMarkNeedsLayoutStacks = false;

List<String> debugDescribeTransform(Matrix4 transform) {
  List<String> matrix = transform.toString().split('\n').map((String s) => '  $s').toList();
  matrix.removeLast();
  return matrix;
}

bool _extensionsInitialized = false;

void initServiceExtensions() {
  if (_extensionsInitialized)
    return;

  _extensionsInitialized = true;

  assert(() {
    developer.registerExtension('flutter', _flutter);
    developer.registerExtension('flutter.debugPaint', _debugPaint);
    developer.registerExtension('flutter.timeDilation', _timeDilation);

    // Emit an info level log message; this tells the debugger that the Flutter
    // service extensions are registered.
    developer.log('Flutter initialized', name: 'flutter', level: 800);

    return true;
  });
}

/// Just respond to the request. Clients can use the existence of this call to
/// know that the debug client is a Flutter app.
Future<developer.ServiceExtensionResponse> _flutter(String method, Map<String, String> parameters) {
  return new Future<developer.ServiceExtensionResponse>.value(
    new developer.ServiceExtensionResponse.result(JSON.encode({
      'type': '_extensionType',
      'method': method
    }))
  );
}

/// Toggle the [debugPaintSizeEnabled] setting.
Future<developer.ServiceExtensionResponse> _debugPaint(String method, Map<String, String> parameters) {
  if (parameters.containsKey('enabled')) {
    debugPaintSizeEnabled = parameters['enabled'] == 'true';

    // Redraw everything - mark the world as dirty.
    RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    Renderer.instance?.renderView?.visitChildren(visitor);
  }

  return new Future<developer.ServiceExtensionResponse>.value(
    new developer.ServiceExtensionResponse.result(JSON.encode({
      'type': '_extensionType',
      'method': method,
      'enabled': debugPaintSizeEnabled
    }))
  );
}

/// Manipulate the scheduler's [timeDilation] field.
Future<developer.ServiceExtensionResponse> _timeDilation(String method, Map<String, String> parameters) {
  if (parameters.containsKey('timeDilation')) {
    timeDilation = double.parse(parameters['timeDilation']);
  }

  return new Future<developer.ServiceExtensionResponse>.value(
    new developer.ServiceExtensionResponse.result(JSON.encode({
      'type': '_extensionType',
      'method': method,
      'timeDilation': '$timeDilation'
    }))
  );
}
