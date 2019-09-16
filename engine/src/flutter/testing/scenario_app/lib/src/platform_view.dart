// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'scenario.dart';

List<int> _to32(int value) {
  final Uint8List temp = Uint8List(4);
  temp.buffer.asByteData().setInt32(0, value, Endian.little);
  return temp;
}

List<int> _to64(num value) {
  final Uint8List temp = Uint8List(15);
  if (value is double) {
    temp.buffer.asByteData().setFloat64(7, value, Endian.little);
  } else if (value is int) {
    temp.buffer.asByteData().setInt64(7, value, Endian.little);
  }
  return temp;
}

/// A simple platform view.
class PlatformViewScenario extends Scenario {
  /// Creates the PlatformView scenario.
  ///
  /// The [window] parameter must not be null.
  PlatformViewScenario(Window window, String text, {int id = 0})
      : assert(window != null),
        super(window) {
    const int _valueInt32 = 3;
    const int _valueFloat64 = 6;
    const int _valueString = 7;
    const int _valueUint8List = 8;
    const int _valueMap = 13;
    final Uint8List message = Uint8List.fromList(<int>[
      _valueString,
      'create'.length, // this is safe as long as these are all single byte characters.
      ...utf8.encode('create'),
      _valueMap,
      if (Platform.isIOS)
        3, // 3 entries in map for iOS.
      if (Platform.isAndroid)
        6, // 6 entries in map for Android.
      _valueString,
      'id'.length,
      ...utf8.encode('id'),
      _valueInt32,
      ..._to32(id),
      _valueString,
      'viewType'.length,
      ...utf8.encode('viewType'),
      _valueString,
      'scenarios/textPlatformView'.length,
      ...utf8.encode('scenarios/textPlatformView'),
      if (Platform.isAndroid) ...<int>[
        _valueString,
        'width'.length,
        ...utf8.encode('width'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'height'.length,
        ...utf8.encode('height'),
        _valueFloat64,
        ..._to64(500.0),
        _valueString,
        'direction'.length,
        ...utf8.encode('direction'),
        _valueInt32,
        ..._to32(0), // LTR
      ],
      _valueString,
      'params'.length,
      ...utf8.encode('params'),
      _valueUint8List,
      text.length,
      ...utf8.encode(text),
    ]);

    window.sendPlatformMessage(
      'flutter/platform_views',
      message.buffer.asByteData(),
      (ByteData response) {
        if (Platform.isAndroid) {
          _textureId = response.getInt64(2);
        }
      },
    );
  }

  int _textureId;

  @override
  void onBeginFrame(Duration duration) {
    final SceneBuilder builder = SceneBuilder();

    builder.pushOffset(0, 0);

    if (Platform.isIOS) {
      builder.addPlatformView(0, width: 500, height: 500);
    } else if (Platform.isAndroid && _textureId != null) {
      builder.addTexture(_textureId, offset: const Offset(150, 300), width: 500, height: 500);
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawCircle(const Offset(50, 50), 50, Paint()..color = const Color(0xFFABCDEF));
    final Picture picture = recorder.endRecording();
    builder.addPicture(const Offset(300, 300), picture);

    final Scene scene = builder.build();
    window.render(scene);
    scene.dispose();
  }
}
