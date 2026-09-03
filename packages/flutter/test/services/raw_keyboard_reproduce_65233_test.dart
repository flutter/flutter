// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OK/Select on IR Remotes (scan code 97, key code 23) does not cause Exception', (
    WidgetTester _,
  ) async {
    final keyEventMessage = <String, Object?>{
      'type': 'keydown',
      'keymap': 'android',
      'productId': 1,
      'flags': 8,
      'vendorId': 1,
      'source': 769,
      'deviceId': 3,
      'scanCode': 97,
      'keyCode': 23,
      'plainCodePoint': 0,
      'metaState': 0,
      'codePoint': 0,
      'repeatCount': 0,
    };

    // We expect this to run without throwing an AssertionError.
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(keyEventMessage),
      (ByteData? data) {},
    );

    expect(RawKeyboard.instance.keysPressed, contains(LogicalKeyboardKey.select));
    expect(HardwareKeyboard.instance.physicalKeysPressed, contains(PhysicalKeyboardKey.select));
    expect(HardwareKeyboard.instance.logicalKeysPressed, contains(LogicalKeyboardKey.select));

    final keyUpEventMessage = <String, Object?>{
      'type': 'keyup',
      'keymap': 'android',
      'productId': 1,
      'flags': 8,
      'vendorId': 1,
      'source': 769,
      'deviceId': 3,
      'scanCode': 97,
      'keyCode': 23,
      'plainCodePoint': 0,
      'metaState': 0,
      'codePoint': 0,
      'repeatCount': 0,
    };

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(keyUpEventMessage),
      (ByteData? data) {},
    );

    expect(RawKeyboard.instance.keysPressed, isNot(contains(LogicalKeyboardKey.select)));
    expect(
      HardwareKeyboard.instance.physicalKeysPressed,
      isNot(contains(PhysicalKeyboardKey.select)),
    );
    expect(
      HardwareKeyboard.instance.logicalKeysPressed,
      isNot(contains(LogicalKeyboardKey.select)),
    );
  });
}
