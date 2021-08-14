// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js' as js;

import '../engine.dart' show registerHotRestartListener;

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
    return WebExperiments.instance ??
        (WebExperiments.instance = WebExperiments._());
  }

  static WebExperiments? instance;

  /// Reset all experimental flags to their default values.
  void reset() {}

  /// Used to enable/disable experimental flags in the web engine.
  void updateExperiment(String name, bool? enabled) {}
}
