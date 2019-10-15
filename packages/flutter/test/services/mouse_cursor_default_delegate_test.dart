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

    final List<int> logDevices = <int>[];
    final List<int> logCursors = <int>[];
    messenger.methodHandlers['setCursor'] = (dynamic args) async {
      final List<dynamic> argList = args;
      logDevices.add(argList[0]);
      logCursors.add(argList[1]);
      return <dynamic>[true];
    };

    final MouseCursorDefaultDelegate delegate =
      MouseCursorDefaultDelegate(channel);

    await delegate.setCursor(1, 2);
    expect(logDevices, <int>{1});
    expect(logCursors, <int>{2});
    logDevices.clear();
    logCursors.clear();

    await delegate.setCursor(3, 4);
    expect(logDevices, <int>{3});
    expect(logCursors, <int>{4});
    logDevices.clear();
    logCursors.clear();
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
