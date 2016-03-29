// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:developer' as developer;

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

export 'package:flutter/services.dart' show debugPrint;

/// Causes each RenderBox to paint a box around its bounds, and some extra
/// boxes, such as RenderPadding, to draw construction lines.
bool debugPaintSizeEnabled = false;

/// The color to use when painting RenderObject bounds.
Color debugPaintSizeColor = const Color(0xFF00FFFF);

/// The color to use when painting some boxes that just add space (e.g. an empty
/// RenderConstrainedBox or RenderPadding).
Color debugPaintSpacingColor = const Color(0x90909090);

/// The color to use when painting RenderPadding edges.
Color debugPaintPaddingColor = const Color(0x900090FF);

/// The color to use when painting RenderPadding edges.
Color debugPaintPaddingInnerEdgeColor = const Color(0xFF0090FF);

/// The color to use when painting the arrows used to show RenderPositionedBox alignment.
Color debugPaintArrowColor = const Color(0xFFFFFF00);

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// The color to use when painting alphabetic baselines.
Color debugPaintAlphabeticBaselineColor = const Color(0xFF00FF00);

/// The color ot use when painting ideographic baselines.
Color debugPaintIdeographicBaselineColor = const Color(0xFFFFD000);

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// The color to use when painting Layer borders.
Color debugPaintLayerBordersColor = const Color(0xFFFF9800);

/// Causes RenderBox objects to flash while they are being tapped.
bool debugPaintPointersEnabled = false;

/// The color to use when reporting pointers.
int debugPaintPointersColorValue = 0x00BBBB;

/// Overlay a rotating set of colors when repainting layers in checked mode.
bool debugRepaintRainbowEnabled = false;

/// The current color to overlay when repainting a layer.
HSVColor debugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

/// The amount to increment the hue of the current repaint color.
double debugRepaintRainbowHueIncrement = 2.0;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the call stacks that mark render objects as needing layout.
bool debugPrintMarkNeedsLayoutStacks = false;

/// Check the intrinsic sizes of each [RenderBox] during layout.
bool debugCheckIntrinsicSizes = false;

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
    developer.registerExtension('ext.flutter.debugPaint', _debugPaint);
    developer.registerExtension('ext.flutter.timeDilation', _timeDilation);

    return true;
  });
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
