// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_web/video_player_web.dart';

import 'utils.dart';

// Use WebM to allow CI to run tests in Chromium.
const String _videoAssetKey = 'assets/Butterfly-209.webm';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayerWeb plugin (hits network)', () {
    late Future<int> textureId;

    setUp(() {
      VideoPlayerPlatform.instance = VideoPlayerPlugin();
      textureId = VideoPlayerPlatform.instance
          .create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: getUrlForAssetAsNetworkSource(_videoAssetKey),
            ),
          )
          .then((int? textureId) => textureId!);
    });

    testWidgets('can init', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.init(), completes);
    });

    testWidgets('can create from network', (WidgetTester tester) async {
      expect(
          VideoPlayerPlatform.instance.create(
            DataSource(
              sourceType: DataSourceType.network,
              uri: getUrlForAssetAsNetworkSource(_videoAssetKey),
            ),
          ),
          completion(isNonZero));
    });

    testWidgets('can create from asset', (WidgetTester tester) async {
      expect(
          VideoPlayerPlatform.instance.create(
            DataSource(
              sourceType: DataSourceType.asset,
              asset: 'videos/bee.mp4',
              package: 'bee_vids',
            ),
          ),
          completion(isNonZero));
    });

    testWidgets('cannot create from file', (WidgetTester tester) async {
      expect(
          VideoPlayerPlatform.instance.create(
            DataSource(
              sourceType: DataSourceType.file,
              uri: '/videos/bee.mp4',
            ),
          ),
          throwsUnimplementedError);
    });

    testWidgets('cannot create from content URI', (WidgetTester tester) async {
      expect(
          VideoPlayerPlatform.instance.create(
            DataSource(
              sourceType: DataSourceType.contentUri,
              uri: 'content://video',
            ),
          ),
          throwsUnimplementedError);
    });

    testWidgets('can dispose', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.dispose(await textureId), completes);
    });

    testWidgets('can set looping', (WidgetTester tester) async {
      expect(
        VideoPlayerPlatform.instance.setLooping(await textureId, true),
        completes,
      );
    });

    testWidgets('can play', (WidgetTester tester) async {
      // Mute video to allow autoplay (See https://goo.gl/xX8pDD)
      await VideoPlayerPlatform.instance.setVolume(await textureId, 0);
      expect(VideoPlayerPlatform.instance.play(await textureId), completes);
    });

    testWidgets('throws PlatformException when playing bad media',
        (WidgetTester tester) async {
      final int videoPlayerId = (await VideoPlayerPlatform.instance.create(
        DataSource(
          sourceType: DataSourceType.network,
          uri: getUrlForAssetAsNetworkSource('assets/__non_existent.webm'),
        ),
      ))!;

      final Stream<VideoEvent> eventStream =
          VideoPlayerPlatform.instance.videoEventsFor(videoPlayerId);

      // Mute video to allow autoplay (See https://goo.gl/xX8pDD)
      await VideoPlayerPlatform.instance.setVolume(videoPlayerId, 0);
      await VideoPlayerPlatform.instance.play(videoPlayerId);

      expect(() async {
        await eventStream.timeout(const Duration(seconds: 5)).last;
      }, throwsA(isA<PlatformException>()));
    });

    testWidgets('can pause', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.pause(await textureId), completes);
    });

    testWidgets('can set volume', (WidgetTester tester) async {
      expect(
        VideoPlayerPlatform.instance.setVolume(await textureId, 0.8),
        completes,
      );
    });

    testWidgets('can set playback speed', (WidgetTester tester) async {
      expect(
        VideoPlayerPlatform.instance.setPlaybackSpeed(await textureId, 2.0),
        completes,
      );
    });

    testWidgets('can seek to position', (WidgetTester tester) async {
      expect(
        VideoPlayerPlatform.instance.seekTo(
          await textureId,
          const Duration(seconds: 1),
        ),
        completes,
      );
    });

    testWidgets('can get position', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.getPosition(await textureId),
          completion(isInstanceOf<Duration>()));
    });

    testWidgets('can get video event stream', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.videoEventsFor(await textureId),
          isInstanceOf<Stream<VideoEvent>>());
    });

    testWidgets('can build view', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.buildView(await textureId),
          isInstanceOf<Widget>());
    });

    testWidgets('ignores setting mixWithOthers', (WidgetTester tester) async {
      expect(VideoPlayerPlatform.instance.setMixWithOthers(true), completes);
      expect(VideoPlayerPlatform.instance.setMixWithOthers(false), completes);
    });

    testWidgets('video playback lifecycle', (WidgetTester tester) async {
      final int videoPlayerId = await textureId;
      final Stream<VideoEvent> eventStream =
          VideoPlayerPlatform.instance.videoEventsFor(videoPlayerId);

      final Future<List<VideoEvent>> stream = eventStream.timeout(
        const Duration(seconds: 1),
        onTimeout: (EventSink<VideoEvent> sink) {
          sink.close();
        },
      ).toList();

      await VideoPlayerPlatform.instance.setVolume(videoPlayerId, 0);
      await VideoPlayerPlatform.instance.play(videoPlayerId);

      // Let the video play, until we stop seeing events for a second
      final List<VideoEvent> events = await stream;

      await VideoPlayerPlatform.instance.pause(videoPlayerId);

      // The expected list of event types should look like this:
      // 1. bufferingStart,
      // 2. bufferingUpdate (videoElement.onWaiting),
      // 3. initialized (videoElement.onCanPlay),
      // 4. bufferingEnd (videoElement.onCanPlayThrough),
      expect(
          events.map((VideoEvent e) => e.eventType),
          equals(<VideoEventType>[
            VideoEventType.bufferingStart,
            VideoEventType.bufferingUpdate,
            VideoEventType.initialized,
            VideoEventType.bufferingEnd
          ]));
    });
  });
}
