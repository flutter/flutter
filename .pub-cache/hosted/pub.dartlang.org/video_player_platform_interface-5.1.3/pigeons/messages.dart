// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9

import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  int textureId;
}

class LoopingMessage {
  int textureId;
  bool isLooping;
}

class VolumeMessage {
  int textureId;
  double volume;
}

class PlaybackSpeedMessage {
  int textureId;
  double speed;
}

class PositionMessage {
  int textureId;
  int position;
}

class CreateMessage {
  String asset;
  String uri;
  String packageName;
  String formatHint;
  Map<String, String> httpHeaders;
}

class MixWithOthersMessage {
  bool mixWithOthers;
}

@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class VideoPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setLooping(LoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  void play(TextureMessage msg);
  PositionMessage position(TextureMessage msg);
  void seekTo(PositionMessage msg);
  void pause(TextureMessage msg);
  void setMixWithOthers(MixWithOthersMessage msg);
}

void configurePigeon(PigeonOptions opts) {
  opts.dartOut = 'lib/messages.dart';
  opts.dartTestOut = 'test/test.dart';
}
