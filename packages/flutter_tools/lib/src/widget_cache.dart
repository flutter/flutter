// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'features.dart';

/// The widget cache determines if the body of a single widget was modified since
/// the last scan of the token stream.
class WidgetCache {
  WidgetCache({
    @required FeatureFlags featureFlags,
  }) : _featureFlags = featureFlags;

  final FeatureFlags _featureFlags;

  /// If the build method of a single widget was modified, return the widget name.
  ///
  /// If any other changes were made, or there is an error scanning the file,
  /// return `null`.
  Future<String> validateLibrary(Uri libraryUri) async {
    if (!_featureFlags.isSingleWidgetReloadEnabled) {
      return null;
    }
    return null;
  }
}
