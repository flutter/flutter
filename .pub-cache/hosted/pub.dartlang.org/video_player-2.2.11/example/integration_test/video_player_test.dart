// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

const Duration _playDuration = Duration(seconds: 1);

// Use WebM for web to allow CI to use Chromium.
final String _videoAssetKey =
    kIsWeb ? 'assets/Butterfly-209.webm' : 'assets/Butterfly-209.mp4';

// Returns the URL to load an asset from this example app as a network source.
String getUrlForAssetAsNetworkSource(String assetKey) {
  return 'https://github.com/flutter/plugins/blob/'
      // This hash can be rolled forward to pick up newly-added assets.
      'cba393233e559c925a4daf71b06b4bb01c606762'
      '/packages/video_player/video_player/example/'
      '$assetKey'
      '?raw=true';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late VideoPlayerController _controller;
  tearDown(() async => _controller.dispose());

  group('asset videos', () {
    setUp(() {
      _controller = VideoPlayerController.asset(_videoAssetKey);
    });

    testWidgets('can be initialized', (WidgetTester tester) async {
      await _controller.initialize();

      expect(_controller.value.isInitialized, true);
      expect(_controller.value.position, const Duration(seconds: 0));
      expect(_controller.value.isPlaying, false);
      // The WebM version has a slightly different duration than the MP4.
      expect(_controller.value.duration,
          Duration(seconds: 7, milliseconds: kIsWeb ? 544 : 540));
    });

    testWidgets(
      'live stream duration != 0',
      (WidgetTester tester) async {
        VideoPlayerController networkController = VideoPlayerController.network(
          'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
        );
        await networkController.initialize();

        expect(networkController.value.isInitialized, true);
        // Live streams should have either a positive duration or C.TIME_UNSET if the duration is unknown
        // See https://exoplayer.dev/doc/reference/com/google/android/exoplayer2/Player.html#getDuration--
        expect(networkController.value.duration,
            (Duration duration) => duration != Duration.zero);
      },
      skip: (kIsWeb),
    );

    testWidgets(
      'can be played',
      (WidgetTester tester) async {
        await _controller.initialize();
        // Mute to allow playing without DOM interaction on Web.
        // See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes
        await _controller.setVolume(0);

        await _controller.play();
        await tester.pumpAndSettle(_playDuration);

        expect(_controller.value.isPlaying, true);
        expect(_controller.value.position,
            (Duration position) => position > const Duration(seconds: 0));
      },
    );

    testWidgets(
      'can seek',
      (WidgetTester tester) async {
        await _controller.initialize();

        await _controller.seekTo(const Duration(seconds: 3));

        expect(_controller.value.position, const Duration(seconds: 3));
      },
    );

    testWidgets(
      'can be paused',
      (WidgetTester tester) async {
        await _controller.initialize();
        // Mute to allow playing without DOM interaction on Web.
        // See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes
        await _controller.setVolume(0);

        // Play for a second, then pause, and then wait a second.
        await _controller.play();
        await tester.pumpAndSettle(_playDuration);
        await _controller.pause();
        final Duration pausedPosition = _controller.value.position;
        await tester.pumpAndSettle(_playDuration);

        // Verify that we stopped playing after the pause.
        expect(_controller.value.isPlaying, false);
        expect(_controller.value.position, pausedPosition);
      },
    );

    testWidgets(
      'stay paused when seeking after video completed',
      (WidgetTester tester) async {
        await _controller.initialize();
        // Mute to allow playing without DOM interaction on Web.
        // See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes
        await _controller.setVolume(0);
        Duration tenMillisBeforeEnd =
            _controller.value.duration - const Duration(milliseconds: 10);
        await _controller.seekTo(tenMillisBeforeEnd);
        await _controller.play();
        await tester.pumpAndSettle(_playDuration);
        expect(_controller.value.isPlaying, false);
        expect(_controller.value.position, _controller.value.duration);

        await _controller.seekTo(tenMillisBeforeEnd);
        await tester.pumpAndSettle(_playDuration);

        expect(_controller.value.isPlaying, false);
        expect(_controller.value.position, tenMillisBeforeEnd);
      },
    );

    testWidgets(
      'do not exceed duration on play after video completed',
      (WidgetTester tester) async {
        await _controller.initialize();
        // Mute to allow playing without DOM interaction on Web.
        // See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes
        await _controller.setVolume(0);
        await _controller.seekTo(
            _controller.value.duration - const Duration(milliseconds: 10));
        await _controller.play();
        await tester.pumpAndSettle(_playDuration);
        expect(_controller.value.isPlaying, false);
        expect(_controller.value.position, _controller.value.duration);

        await _controller.play();
        await tester.pumpAndSettle(_playDuration);

        expect(_controller.value.position,
            lessThanOrEqualTo(_controller.value.duration));
      },
    );

    testWidgets('test video player view with local asset',
        (WidgetTester tester) async {
      Future<bool> started() async {
        await _controller.initialize();
        await _controller.play();
        return true;
      }

      await tester.pumpWidget(Material(
        elevation: 0,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: FutureBuilder<bool>(
              future: started(),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.data == true) {
                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  );
                } else {
                  return const Text('waiting for video to load');
                }
              },
            ),
          ),
        ),
      ));

      await tester.pumpAndSettle();
      expect(_controller.value.isPlaying, true);
    },
        skip: kIsWeb || // Web does not support local assets.
            // Extremely flaky on iOS: https://github.com/flutter/flutter/issues/86915
            defaultTargetPlatform == TargetPlatform.iOS);
  });

  group('file-based videos', () {
    setUp(() async {
      // Load the data from the asset.
      String tempDir = (await getTemporaryDirectory()).path;
      ByteData bytes = await rootBundle.load(_videoAssetKey);

      // Write it to a file to use as a source.
      final String filename = _videoAssetKey.split('/').last;
      File file = File('$tempDir/$filename');
      await file.writeAsBytes(bytes.buffer.asInt8List());

      _controller = VideoPlayerController.file(file);
    });

    testWidgets('test video player using static file() method as constructor',
        (WidgetTester tester) async {
      await _controller.initialize();

      await _controller.play();
      expect(_controller.value.isPlaying, true);

      await _controller.pause();
      expect(_controller.value.isPlaying, false);
    }, skip: kIsWeb);
  });

  group('network videos', () {
    setUp(() {
      // TODO(stuartmorgan): Remove this conditional and update the hash in
      // getUrlForAssetAsNetworkSource as a follow-up, once the webm asset is
      // checked in.
      final String videoUrl = kIsWeb
          ? 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.webm'
          : getUrlForAssetAsNetworkSource(_videoAssetKey);
      _controller = VideoPlayerController.network(videoUrl);
    });

    testWidgets(
      'reports buffering status',
      (WidgetTester tester) async {
        await _controller.initialize();
        // Mute to allow playing without DOM interaction on Web.
        // See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes
        await _controller.setVolume(0);
        final Completer<void> started = Completer();
        final Completer<void> ended = Completer();
        _controller.addListener(() {
          if (!started.isCompleted && _controller.value.isBuffering) {
            started.complete();
          }
          if (started.isCompleted &&
              !_controller.value.isBuffering &&
              !ended.isCompleted) {
            ended.complete();
          }
        });

        await _controller.play();
        await _controller.seekTo(const Duration(seconds: 5));
        await tester.pumpAndSettle(_playDuration);
        await _controller.pause();

        expect(_controller.value.isPlaying, false);
        expect(_controller.value.position,
            (Duration position) => position > const Duration(seconds: 0));

        await expectLater(started.future, completes);
        await expectLater(ended.future, completes);
      },
      skip: !(kIsWeb || defaultTargetPlatform == TargetPlatform.android),
    );
  });
}
