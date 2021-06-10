// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js' as js;

import 'package:ui/src/engine.dart' show registerHotRestartListener;

/// A bag of all experiment flags in the web engine.
///
/// This class also handles platform messages that can be sent to enable/disable
/// certain experiments at runtime without the need to access engine internals.
class WebExperiments {
  WebExperiments._() {
    js.context['_flutter_internal_update_experiment'] = updateExperiment;
    registerHotRestartListener(() {
      js.context['_flutter_internal_update_experiment'] = null;
    });
  }

  static WebExperiments ensureInitialized() {
    return WebExperiments.instance ?? (WebExperiments.instance = WebExperiments._());
  }

  static WebExperiments? instance;

  /// Experiment flag for using canvas-based text measurement.
  bool get useCanvasText => _useCanvasText;
  set useCanvasText(bool? enabled) {
    _useCanvasText = enabled ?? _defaultUseCanvasText;
  }

  static const bool _defaultUseCanvasText = const bool.fromEnvironment(
    'FLUTTER_WEB_USE_EXPERIMENTAL_CANVAS_TEXT',
    defaultValue: true,
  );

  bool _useCanvasText = _defaultUseCanvasText;

  // TODO(mdebbar): Clean up https://github.com/flutter/flutter/issues/71952
  /// Experiment flag for using canvas-based measurement for rich text.
  bool get useCanvasRichText => _useCanvasRichText;
  set useCanvasRichText(bool? enabled) {
    _useCanvasRichText = enabled ?? _defaultUseCanvasRichText;
  }

  static const bool _defaultUseCanvasRichText = const bool.fromEnvironment(
    'FLUTTER_WEB_USE_EXPERIMENTAL_CANVAS_RICH_TEXT',
    defaultValue: true,
  );

  bool _useCanvasRichText = _defaultUseCanvasRichText;

  /// Reset all experimental flags to their default values.
  void reset() {
    _useCanvasText = _defaultUseCanvasText;
    _useCanvasRichText = _defaultUseCanvasRichText;
  }

  /// Used to enable/disable experimental flags in the web engine.
  void updateExperiment(String name, bool? enabled) {
    switch (name) {
      case 'useCanvasText':
        useCanvasText = enabled;
        break;
      case 'useCanvasRichText':
        useCanvasRichText = enabled;
        break;
    }
  }
}
