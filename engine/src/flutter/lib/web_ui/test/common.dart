// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';

/// Whether the current browser is Safari.
bool get isSafari => browserEngine == BrowserEngine.webkit;

/// Whether the current browser is Safari on iOS.
// TODO(yjbanov): https://github.com/flutter/flutter/issues/60040
bool get isIosSafari => isSafari && operatingSystem == OperatingSystem.iOs;

/// Whether the current browser is Firefox.
bool get isFirefox => browserEngine == BrowserEngine.firefox;
