// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import 'layer_painting.dart';

/// A virtual canvas that applies operations to multiple canvases at once.
class NWayCanvas {
  final List<LayerCanvas> _canvases = <LayerCanvas>[];

  void addCanvas(LayerCanvas canvas) {
    _canvases.add(canvas);
  }

  /// Calls [save] on all canvases.
  void save() {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].save();
    }
  }

  /// Calls [saveLayer] on all canvases.
  void saveLayer(ui.Rect bounds, ui.Paint? paint) {
    paint ??= ui.Paint();
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].saveLayer(bounds, paint);
    }
  }

  /// Calls [saveLayerWithFilter] on all canvases.
  void saveLayerWithFilter(ui.Rect bounds, ui.ImageFilter filter, [ui.Paint? paint]) {
    paint ??= ui.Paint();
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].saveLayerWithFilter(bounds, paint, filter);
    }
  }

  /// Calls [restore] on all canvases.
  void restore() {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].restore();
    }
  }

  /// Calls [restoreToCount] on all canvases.
  void restoreToCount(int count) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].restoreToCount(count);
    }
  }

  /// Calls [translate] on all canvases.
  void translate(double dx, double dy) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].translate(dx, dy);
    }
  }

  /// Calls [transform] on all canvases.
  void transform(Float32List matrix) {
    final matrix64 = Float64List.fromList(matrix);
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].transform(matrix64);
    }
  }

  /// Calls [clear] on all canvases.
  void clear(ui.Color color) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].clear(color);
    }
  }

  /// Calls [clipPath] on all canvases.
  void clipPath(ui.Path path, bool doAntiAlias) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].clipPath(path, doAntiAlias: doAntiAlias);
    }
  }

  /// Calls [clipRect] on all canvases.
  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
    }
  }

  /// Calls [clipRRect] on all canvases.
  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    for (var i = 0; i < _canvases.length; i++) {
      _canvases[i].clipRRect(rrect, doAntiAlias: doAntiAlias);
    }
  }

  /// Calls [clipRSuperellipse] on all canvases.
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, bool doAntiAlias) {
    // RSuperellipse ops in PlatformView are approximated by RRect because they
    // are expensive.
    return clipRRect(rsuperellipse.toApproximateRRect(), doAntiAlias);
  }
}
