// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:ui/src/engine.dart';

/// Whether we are running on iOS Safari.
// TODO: https://github.com/flutter/flutter/issues/60040
bool get isIosSafari => browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs;
