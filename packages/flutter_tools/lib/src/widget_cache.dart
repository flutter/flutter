// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:meta/meta.dart';

import 'features.dart';

/// The widget cache determines if the body of a single widget was modified since
/// the last scan of the token stream.
class WidgetCache {
  WidgetCache({
    @required FeatureFlags featureFlags,
  }) : _featureFlags = featureFlags;

  final FeatureFlags _featureFlags;

  set outFile(File file) => _outFile = file;

  File _outFile;

  /// If the build method of a single widget was modified, return the widget name.
  ///
  /// If any other changes were made, or there is an error scanning the file,
  /// return `null`.
  String validateLibrary() {
    if (!_featureFlags.isSingleWidgetReloadEnabled) {
      return null;
    }
    if (_outFile != null && _outFile.existsSync()) {
      final String widget = _outFile.readAsStringSync().trim();
      if (widget.isNotEmpty) {
        return widget;
      }
    }
    return null;
  }
}
