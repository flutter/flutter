// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/platform.dart';

// Only launch or display desktop embedding devices if
// `FLUTTER_DESKTOP_EMBEDDING` environment variable is set to true.
bool get flutterDesktopEnabled {
  _flutterDesktopEnabled ??= platform.environment['FLUTTER_DESKTOP_EMBEDDING']?.toLowerCase() == 'true';
  return _flutterDesktopEnabled;
}
bool _flutterDesktopEnabled;
