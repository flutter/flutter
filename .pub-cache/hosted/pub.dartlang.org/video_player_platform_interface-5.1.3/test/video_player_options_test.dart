// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  test(
    'VideoPlayerOptions allowBackgroundPlayback defaults to false',
    () {
      final VideoPlayerOptions options = VideoPlayerOptions();
      expect(options.allowBackgroundPlayback, false);
    },
  );
  test(
    'VideoPlayerOptions mixWithOthers defaults to false',
    () {
      final VideoPlayerOptions options = VideoPlayerOptions();
      expect(options.mixWithOthers, false);
    },
  );
}
