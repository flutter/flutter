// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/platform.dart';
import 'version.dart';

// Only launch or display desktop embedding devices if
// `ENABLE_FLUTTER_DESKTOP` environment variable is set to true.
bool get flutterDesktopEnabled {
  _flutterDesktopEnabled ??= platform.environment['ENABLE_FLUTTER_DESKTOP']?.toLowerCase() == 'true';
  return _flutterDesktopEnabled && !FlutterVersion.instance.isStable;
}
bool _flutterDesktopEnabled;
