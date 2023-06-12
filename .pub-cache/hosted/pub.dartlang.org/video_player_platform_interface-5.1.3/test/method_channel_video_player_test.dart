// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/messages.dart';
import 'package:video_player_platform_interface/method_channel_video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test.dart';

class _ApiLogger implements TestHostVideoPlayerApi {
  final List<String> log = <String>[];
  TextureMessage? textureMessage;
  CreateMessage? createMessage;
  PositionMessage? positionMessage;
  LoopingMessage? loopingMessage;
  VolumeMessage? volumeMessage;
  PlaybackSpeedMessage? playbackSpeedMessage;
  MixWithOthersMessage? mixWithOthersMessage;

  @override
  TextureMessage create(CreateMessage arg) {
    log.add('create');
    createMessage = arg;
    return TextureMessage()..textureId = 3;
  }

  @override
  void dispose(TextureMessage arg) {
    log.add('dispose');
    textureMessage = arg;
  }

  @override
  void initialize() {
    log.add('init');
  }

  @override
  void pause(TextureMessage arg) {
    log.add('pause');
    textureMessage = arg;
  }

  @override
  void play(TextureMessage arg) {
    log.add('play');
    textureMessage = arg;
  }

  @override
  void setMixWithOthers(MixWithOthersMessage arg) {
    log.add('setMixWithOthers');
    mixWithOthersMessage = arg;
  }

  @override
  PositionMessage position(TextureMessage arg) {
    log.add('position');
    textureMessage = arg;
    return PositionMessage()..position = 234;
  }

  @override
  void seekTo(PositionMessage arg) {
    log.add('seekTo');
    positionMessage = arg;
  }

  @override
  void setLooping(LoopingMessage arg) {
    log.add('setLooping');
    loopingMessage = arg;
  }

  @override
  void setVolume(VolumeMessage arg) {
    log.add('setVolume');
    volumeMessage = arg;
  }

  @override
  void setPlaybackSpeed(PlaybackSpeedMessage arg) {
    log.add('setPlaybackSpeed');
    playbackSpeedMessage = arg;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Store the initial instance before any tests change it.
  final VideoPlayerPlatform initialInstance = VideoPlayerPlatform.instance;

  group('$VideoPlayerPlatform', () {
    test('$MethodChannelVideoPlayer() is the default instance', () {
      expect(initialInstance, isInstanceOf<MethodChannelVideoPlayer>());
    });
  });

  group('$MethodChannelVideoPlayer', () {
    final MethodChannelVideoPlayer player = MethodChannelVideoPlayer();
    late _ApiLogger log;

    setUp(() {
      log = _ApiLogger();
      TestHostVideoPlayerApi.setup(log);
    });

    test('init', () async {
      await player.init();
      expect(
        log.log.last,
        'init',
      );
    });

    test('dispose', () async {
      await player.dispose(1);
      expect(log.log.last, 'dispose');
      expect(log.textureMessage?.textureId, 1);
    });

    test('create with asset', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.asset,
        asset: 'someAsset',
        package: 'somePackage',
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, 'someAsset');
      expect(log.createMessage?.packageName, 'somePackage');
      expect(textureId, 3);
    });

    test('create with network', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        formatHint: VideoFormat.dash,
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, null);
      expect(log.createMessage?.uri, 'someUri');
      expect(log.createMessage?.packageName, null);
      expect(log.createMessage?.formatHint, 'dash');
      expect(log.createMessage?.httpHeaders, <Object?, Object?>{});
      expect(textureId, 3);
    });

    test('create with network (some headers)', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.network,
        uri: 'someUri',
        httpHeaders: <String, String>{'Authorization': 'Bearer token'},
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.asset, null);
      expect(log.createMessage?.uri, 'someUri');
      expect(log.createMessage?.packageName, null);
      expect(log.createMessage?.formatHint, null);
      expect(log.createMessage?.httpHeaders,
          <String, String>{'Authorization': 'Bearer token'});
      expect(textureId, 3);
    });

    test('create with file', () async {
      final int? textureId = await player.create(DataSource(
        sourceType: DataSourceType.file,
        uri: 'someUri',
      ));
      expect(log.log.last, 'create');
      expect(log.createMessage?.uri, 'someUri');
      expect(textureId, 3);
    });

    test('setLooping', () async {
      await player.setLooping(1, true);
      expect(log.log.last, 'setLooping');
      expect(log.loopingMessage?.textureId, 1);
      expect(log.loopingMessage?.isLooping, true);
    });

    test('play', () async {
      await player.play(1);
      expect(log.log.last, 'play');
      expect(log.textureMessage?.textureId, 1);
    });

    test('pause', () async {
      await player.pause(1);
      expect(log.log.last, 'pause');
      expect(log.textureMessage?.textureId, 1);
    });

    test('setMixWithOthers', () async {
      await player.setMixWithOthers(true);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthersMessage?.mixWithOthers, true);

      await player.setMixWithOthers(false);
      expect(log.log.last, 'setMixWithOthers');
      expect(log.mixWithOthersMessage?.mixWithOthers, false);
    });

    test('setVolume', () async {
      await player.setVolume(1, 0.7);
      expect(log.log.last, 'setVolume');
      expect(log.volumeMessage?.textureId, 1);
      expect(log.volumeMessage?.volume, 0.7);
    });

    test('setPlaybackSpeed', () async {
      await player.setPlaybackSpeed(1, 1.5);
      expect(log.log.last, 'setPlaybackSpeed');
      expect(log.playbackSpeedMessage?.textureId, 1);
      expect(log.playbackSpeedMessage?.speed, 1.5);
    });

    test('seekTo', () async {
      await player.seekTo(1, const Duration(milliseconds: 12345));
      expect(log.log.last, 'seekTo');
      expect(log.positionMessage?.textureId, 1);
      expect(log.positionMessage?.position, 12345);
    });

    test('getPosition', () async {
      final Duration position = await player.getPosition(1);
      expect(log.log.last, 'position');
      expect(log.textureMessage?.textureId, 1);
      expect(position, const Duration(milliseconds: 234));
    });

    test('videoEventsFor', () async {
      _ambiguate(ServicesBinding.instance)
          ?.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter.io/videoPlayer/videoEvents123',
        (ByteData? message) async {
          final MethodCall methodCall =
              const StandardMethodCodec().decodeMethodCall(message);
          if (methodCall.method == 'listen') {
            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                    }),
                    (ByteData? data) {});

            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'initialized',
                      'duration': 98765,
                      'width': 1920,
                      'height': 1080,
                      'rotationCorrection': 180,
                    }),
                    (ByteData? data) {});

            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'completed',
                    }),
                    (ByteData? data) {});

            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingUpdate',
                      'values': <List<dynamic>>[
                        <int>[0, 1234],
                        <int>[1235, 4000],
                      ],
                    }),
                    (ByteData? data) {});

            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingStart',
                    }),
                    (ByteData? data) {});

            await _ambiguate(ServicesBinding.instance)
                ?.defaultBinaryMessenger
                .handlePlatformMessage(
                    'flutter.io/videoPlayer/videoEvents123',
                    const StandardMethodCodec()
                        .encodeSuccessEnvelope(<String, dynamic>{
                      'event': 'bufferingEnd',
                    }),
                    (ByteData? data) {});

            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else if (methodCall.method == 'cancel') {
            return const StandardMethodCodec().encodeSuccessEnvelope(null);
          } else {
            fail('Expected listen or cancel');
          }
        },
      );
      expect(
          player.videoEventsFor(123),
          emitsInOrder(<dynamic>[
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
              rotationCorrection: 0,
            ),
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(milliseconds: 98765),
              size: const Size(1920, 1080),
              rotationCorrection: 180,
            ),
            VideoEvent(eventType: VideoEventType.completed),
            VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                buffered: <DurationRange>[
                  DurationRange(
                    const Duration(milliseconds: 0),
                    const Duration(milliseconds: 1234),
                  ),
                  DurationRange(
                    const Duration(milliseconds: 1235),
                    const Duration(milliseconds: 4000),
                  ),
                ]),
            VideoEvent(eventType: VideoEventType.bufferingStart),
            VideoEvent(eventType: VideoEventType.bufferingEnd),
          ]));
    });
  });
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
