// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

const Duration _playDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'can substitute one controller by another without crashing',
    (WidgetTester tester) async {
      // Use WebM for web to allow CI to use Chromium.
      final String videoAssetKey =
          kIsWeb ? 'assets/Butterfly-209.webm' : 'assets/Butterfly-209.mp4';

      VideoPlayerController controller = VideoPlayerController.asset(
        videoAssetKey,
      );
      VideoPlayerController another = VideoPlayerController.asset(
        videoAssetKey,
      );
      await controller.initialize();
      await another.initialize();
      await controller.setVolume(0);
      await another.setVolume(0);

      final Completer<void> started = Completer();
      final Completer<void> ended = Completer();
      bool startedBuffering = false;
      bool endedBuffering = false;

      another.addListener(() {
        if (another.value.isBuffering && !startedBuffering) {
          startedBuffering = true;
          started.complete();
        }
        if (startedBuffering && !another.value.isBuffering && !endedBuffering) {
          endedBuffering = true;
          ended.complete();
        }
      });

      // Inject a widget with `controller`...
      await tester.pumpWidget(renderVideoWidget(controller));
      await controller.play();
      await tester.pumpAndSettle(_playDuration);
      await controller.pause();

      // Disposing controller causes the Widget to crash in the next line
      // (Issue https://github.com/flutter/flutter/issues/90046)
      await controller.dispose();

      // Now replace it with `another` controller...
      await tester.pumpWidget(renderVideoWidget(another));
      await another.play();
      await another.seekTo(const Duration(seconds: 5));
      await tester.pumpAndSettle(_playDuration);
      await another.pause();

      // Expect that `another` played.
      expect(another.value.position,
          (Duration position) => position > const Duration(seconds: 0));

      await started;
      expect(startedBuffering, true);

      await ended;
      expect(endedBuffering, true);
    },
    skip: !(kIsWeb || defaultTargetPlatform == TargetPlatform.android),
  );
}

Widget renderVideoWidget(VideoPlayerController controller) {
  return Material(
    elevation: 0,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: AspectRatio(
          key: Key('same'),
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    ),
  );
}
