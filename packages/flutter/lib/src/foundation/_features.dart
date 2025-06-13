// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// The feature flags this app was built with.
///
/// Do not use this API. Flutter can and will make breaking changes to this API.
@internal
Set<String> debugEnabledFeatureFlags = <String>{
  ...const String.fromEnvironment('FLUTTER_ENABLED_FEATURE_FLAGS').split(','),
};
