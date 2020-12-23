// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Manages the installation and loading of dynamic feature modules.
///
/// Dynamic features allow Flutter applications to download precompiled AOT
/// dart code and assets at runtime, reducing the install size of apps and
/// avoiding installing unnessecary code/assets on end user devices. Common
/// use cases include deferring installation of advanced or infrequently
/// used features and limiting locale specific features to users of matching
/// locales.
class DynamicFeatures {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  DynamicFeatures._();

  static Future<void> installDynamicFeature({@required String moduleName}) async {
    await SystemChannels.dynamicfeature.invokeMethod<void>(
      'installDynamicFeature',
      moduleName,
    );
  }
}