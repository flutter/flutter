// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Whether the multi-window feature  is enabled for the current application.
///
/// Do not use this API. Flutter can and will make breaking changes to this API.
@internal
bool isMultiWindowEnabled = debugEnabledFeatureFlags.contains('multi_window');

/// The feature flags this app was built with.
///
/// Do not use this API. Flutter can and will make breaking changes to this API.
@internal
Set<String> debugEnabledFeatureFlags = <String>{
  ...const String.fromEnvironment('FLUTTER_ENABLED_FEATURE_FLAGS').split(','),
};
