// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/file_system.dart';
import 'base/platform.dart';
import 'cache.dart';

// Only launch or display desktop embedding devices if there is a sibling
// FDE repository or a `FLUTTER_DESKTOP_EMBEDDING` environment variable which
// contains a FDE repo.
bool get hasFlutterDesktopRepository {
  if (_hasFlutterDesktopRepository == null) {
    final String desktopLocation = platform.environment['FLUTTER_DESKTOP_EMBEDDING'];
    if (desktopLocation != null && desktopLocation.isNotEmpty) {
      _hasFlutterDesktopRepository = fs.directory(desktopLocation)
        .existsSync();
    } else {
      final Directory parent = fs.directory(Cache.flutterRoot).parent;
      _hasFlutterDesktopRepository = parent
        .childDirectory('flutter-desktop-embedding')
        .existsSync();
    }
  }
  return _hasFlutterDesktopRepository;
}
bool _hasFlutterDesktopRepository;
