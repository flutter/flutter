// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:video_player_web/src/video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayer', () {
    late html.VideoElement video;

    setUp(() {
      // Never set "src" on the video, so this test doesn't hit the network!
      video = html.VideoElement()
        ..controls = true
        ..setAttribute('playsinline', 'false');
    });

    testWidgets('fixes critical video element config', (WidgetTester _) async {
      VideoPlayer(videoElement: video).initialize();

      expect(video.controls, isFalse,
          reason: 'Video is controlled through code');
      expect(video.getAttribute('autoplay'), 'false',
          reason: 'Cannot autoplay on the web');
      expect(video.getAttribute('playsinline'), 'true',
          reason: 'Needed by safari iOS');
    });

    testWidgets('setVolume', (WidgetTester tester) async {
      final VideoPlayer player = VideoPlayer(videoElement: video)..initialize();

      player.setVolume(0);

      expect(video.volume, isZero, reason: 'Volume should be zero');
      expect(video.muted, isTrue, reason: 'muted attribute should be true');

      expect(() {
        player.setVolume(-0.0001);
      }, throwsAssertionError, reason: 'Volume cannot be < 0');

      expect(() {
        player.setVolume(1.0001);
      }, throwsAssertionError, reason: 'Volume cannot be > 1');
    });

    testWidgets('setPlaybackSpeed', (WidgetTester tester) async {
      final VideoPlayer player = VideoPlayer(videoElement: video)..initialize();

      expect(() {
        player.setPlaybackSpeed(-1);
      }, throwsAssertionError, reason: 'Playback speed cannot be < 0');

      expect(() {
        player.setPlaybackSpeed(0);
      }, throwsAssertionError, reason: 'Playback speed cannot be == 0');
    });

    testWidgets('seekTo', (WidgetTester tester) async {
      final VideoPlayer player = VideoPlayer(videoElement: video)..initialize();

      expect(() {
        player.seekTo(const Duration(seconds: -1));
      }, throwsAssertionError, reason: 'Cannot seek into negative numbers');
    });

    // The events tested in this group do *not* represent the actual sequence
    // of events from a real "video" element. They're crafted to test the
    // behavior of the VideoPlayer in different states with different events.
    group('events', () {
      late StreamController<VideoEvent> streamController;
      late VideoPlayer player;
      late Stream<VideoEvent> timedStream;

      final Set<VideoEventType> bufferingEvents = <VideoEventType>{
        VideoEventType.bufferingStart,
        VideoEventType.bufferingEnd,
      };

      setUp(() {
        streamController = StreamController<VideoEvent>();
        player =
            VideoPlayer(videoElement: video, eventController: streamController)
              ..initialize();

        // This stream will automatically close after 100 ms without seeing any events
        timedStream = streamController.stream.timeout(
          const Duration(milliseconds: 100),
          onTimeout: (EventSink<VideoEvent> sink) {
            sink.close();
          },
        );
      });

      testWidgets('buffering dispatches only when it changes',
          (WidgetTester tester) async {
        // Take all the "buffering" events that we see during the next few seconds
        final Future<List<bool>> stream = timedStream
            .where(
                (VideoEvent event) => bufferingEvents.contains(event.eventType))
            .map((VideoEvent event) =>
                event.eventType == VideoEventType.bufferingStart)
            .toList();

        // Simulate some events coming from the player...
        player.setBuffering(true);
        player.setBuffering(true);
        player.setBuffering(true);
        player.setBuffering(false);
        player.setBuffering(false);
        player.setBuffering(true);
        player.setBuffering(false);
        player.setBuffering(true);
        player.setBuffering(false);

        final List<bool> events = await stream;

        expect(events, hasLength(6));
        expect(events, <bool>[true, false, true, false, true, false]);
      });

      testWidgets('canplay event does not change buffering state',
          (WidgetTester tester) async {
        // Take all the "buffering" events that we see during the next few seconds
        final Future<List<bool>> stream = timedStream
            .where(
                (VideoEvent event) => bufferingEvents.contains(event.eventType))
            .map((VideoEvent event) =>
                event.eventType == VideoEventType.bufferingStart)
            .toList();

        player.setBuffering(true);

        // Simulate "canplay" event...
        video.dispatchEvent(html.Event('canplay'));

        final List<bool> events = await stream;

        expect(events, hasLength(1));
        expect(events, <bool>[true]);
      });

      testWidgets('canplaythrough event does change buffering state',
          (WidgetTester tester) async {
        // Take all the "buffering" events that we see during the next few seconds
        final Future<List<bool>> stream = timedStream
            .where(
                (VideoEvent event) => bufferingEvents.contains(event.eventType))
            .map((VideoEvent event) =>
                event.eventType == VideoEventType.bufferingStart)
            .toList();

        player.setBuffering(true);

        // Simulate "canplaythrough" event...
        video.dispatchEvent(html.Event('canplaythrough'));

        final List<bool> events = await stream;

        expect(events, hasLength(2));
        expect(events, <bool>[true, false]);
      });

      testWidgets('initialized dispatches only once',
          (WidgetTester tester) async {
        // Dispatch some bogus "canplay" events from the video object
        video.dispatchEvent(html.Event('canplay'));
        video.dispatchEvent(html.Event('canplay'));
        video.dispatchEvent(html.Event('canplay'));

        // Take all the "initialized" events that we see during the next few seconds
        final Future<List<VideoEvent>> stream = timedStream
            .where((VideoEvent event) =>
                event.eventType == VideoEventType.initialized)
            .toList();

        video.dispatchEvent(html.Event('canplay'));
        video.dispatchEvent(html.Event('canplay'));
        video.dispatchEvent(html.Event('canplay'));

        final List<VideoEvent> events = await stream;

        expect(events, hasLength(1));
        expect(events[0].eventType, VideoEventType.initialized);
      });
    });
  });
}
