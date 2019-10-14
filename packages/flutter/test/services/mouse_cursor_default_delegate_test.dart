// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';

void main() {
  test('MouseCursorDefaultDelegate correctly send legal requests', () async {
    const String channelName = 'test_flutter/mousecursor';
    final _TestBinaryMessenger messenger = _TestBinaryMessenger(channelName);
    final MethodChannel channel = MethodChannel(channelName , const JSONMethodCodec(),
      messenger);

    Map<String, dynamic> valueInJson;
    messenger.methodHandlers['setCursors'] = (dynamic args) async {
      final List<dynamic> argList = args;
      valueInJson = argList[0];
      return <dynamic>[true];
    };

    final MouseCursorDefaultDelegate delegate =
      MouseCursorDefaultDelegate(channel);

    await delegate.setCursors(<int, int>{1: 1, 2: 3});
    expect(valueInJson, <String, int>{'1': 1, '2': 3});
  });
}

// A Messenger that only supports one channel in JSON message codec, and allows
// arbitrary message handlers.
class _TestBinaryMessenger extends BinaryMessenger {
  _TestBinaryMessenger(this.channelName);

  static const MessageCodec<dynamic> _jsonMessage = JSONMessageCodec();

  final String channelName;

  // A map from method name to handlers.
  //
  // Each handler's first parameter is the arguments, which have be decoded.
  //
  // Each handler's return value should be a reply envelop of [JSONMethodCodec]
  // without encoding.
  Map<String, Future<dynamic> Function(dynamic)> methodHandlers =
    <String, Future<dynamic> Function(dynamic)>{};

  @override
  Future<void> handlePlatformMessage(String channel, ByteData data, ui.PlatformMessageResponseCallback callback) async {
    throw UnimplementedError();
  }

  @override
  Future<ByteData> send(String channel, ByteData message) async {
    if (channel != channelName)
      return null;
    final Map<String, dynamic> messageObject = _jsonMessage.decodeMessage(message);
    return _jsonMessage.encodeMessage(
      await methodHandlers[messageObject['method']](messageObject['args']),
    );
  }

  @override
  void setMessageHandler(String channel, Future<ByteData> Function(ByteData message) handler) {
    throw UnimplementedError();
  }

  @override
  void setMockMessageHandler(String channel, Future<ByteData> Function(ByteData message) handler) {
    throw UnimplementedError();
  }
}
