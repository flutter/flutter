// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'video_player_test.dart' show FakeVideoPlayerPlatform;

void main() {
  // This test needs to run first and therefore needs to be the only test
  // in this file.
  test('plugin initialized', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FakeVideoPlayerPlatform fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlayerPlatform;

    final VideoPlayerController controller = VideoPlayerController.network(
      'https://127.0.0.1',
    );
    await controller.initialize();
    expect(fakeVideoPlayerPlatform.calls.first, 'init');
  });
}
