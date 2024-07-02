// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// This file hosts a test that requires the binding is not initialized at the
// beginning of the test.

// If the binding is initialized, trigger an expectation error.
void ensureBindingIsNotInitialized() {
  late final bool hasInstance;
  try {
    ServicesBinding.instance;
    hasInstance = true;
  } on FlutterError catch (_) {
    hasInstance = false;
  } finally {
    expect(hasInstance, false);
  }
}

// Serialized ui.KeyEventType to its ID.
int eventTypeToInt(ui.KeyEventType type) {
  switch(type) {
    case ui.KeyEventType.down:
      return 0;
    case ui.KeyEventType.up:
      return 1;
    case ui.KeyEventType.repeat:
      return 2;
  }
}

// Serialize a `KeyData`.
//
// For simplicity, `character` is not processed and is asserted empty.
ByteData packKeyData(KeyData key) {
  const int kStride = Int64List.bytesPerElement;
  const int numStrides = 6;
  const Endian kFakeHostEndian = Endian.little;
  int offset = 0;

  final ByteData buffer = ByteData(numStrides * kStride);
  assert((key.character?.length ?? 0) == 0); // This test doesn't deal with character.
  buffer.setUint64(kStride * offset++, 0, kFakeHostEndian); // charDataSize
  // character: none
  buffer.setUint64(kStride * offset++, key.timeStamp.inMicroseconds, kFakeHostEndian);
  buffer.setUint64(kStride * offset++, eventTypeToInt(key.type), kFakeHostEndian);
  buffer.setUint64(kStride * offset++, key.physical, kFakeHostEndian);
  buffer.setUint64(kStride * offset++, key.logical, kFakeHostEndian);
  buffer.setUint64(kStride * offset++, key.synthesized ? 1 : 0, kFakeHostEndian);
  assert(offset == numStrides);
  return buffer;
}

// Serialize a `RawKeyData`.
//
// For simplicity, only the `type` is processed.
ByteData packRawKeyEvent(KeyData key) {
  final Map<String, Object?> message = <String, Object?>{
    'keymap': 'macos',
    'type': key.type == ui.KeyEventType.up ? 'keyup' : 'keydown',
    // Leave the rest empty.
  };
  return const JSONMessageCodec().encodeMessage(message)!;
}

// Constructs a `KeyData` with the given type and timestamp.
KeyData fakeKeyData(ui.KeyEventType type, int timestampInMicroseconds) {
  return KeyData(
    timeStamp: Duration(microseconds: timestampInMicroseconds),
    type: type,
    physical: PhysicalKeyboardKey.keyA.usbHidUsage,
    logical: LogicalKeyboardKey.keyA.keyId,
    character: null,
    synthesized: false,
  );
}

// Send the given key data to both key chanels.
void sendKeyData(KeyData key, {
  PlatformMessageResponseCallback? keyDataCallback,
  PlatformMessageResponseCallback? rawKeyEventCallback,
}) {
  ui.channelBuffers.push(
    'flutter/keydata',
    packKeyData(key),
    keyDataCallback ?? (_){},
  );
  ui.channelBuffers.push(
    'flutter/keyevent',
    packRawKeyEvent(key),
    rawKeyEventCallback ?? (_){},
  );
}

void main() {
  test('Key events before binding is initialized should be ignored', () async {
    // This test constructs a case where if key events before binding
    // initialization are not ignored, the event stream will not conform the
    // event rule (downs and ups must alternate) and thus causes an error.

    FlutterError.onError = (FlutterErrorDetails details) {
      // Throws if the event rule is broken.
      expect(true, false);
    };

    ensureBindingIsNotInitialized();

    // Send event #1, a key down event. This event should be ignored.
    sendKeyData(
      fakeKeyData(ui.KeyEventType.down, 1),
      keyDataCallback: (ByteData? response) { expect(response, null); },
      rawKeyEventCallback: (ByteData? response) { expect(response, null); },
    );
    // Send event #2, a key up event. This event should be ignored, too.
    //
    // The reason to send two events before binding is initialized is to prevent
    // the case where the first event is stored in the message queue (the
    // default behavior) and therefore the event rule is still conformed even if
    // pre-initialization events are not ignored (as described in
    // https://github.com/flutter/flutter/issues/125975 ).
    sendKeyData(
      fakeKeyData(ui.KeyEventType.up, 2),
      keyDataCallback: (ByteData? response) { expect(response, null); },
      rawKeyEventCallback: (ByteData? response) { expect(response, null); },
    );

    ensureBindingIsNotInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    // Wait until the binding starts listening to the event callbacks.
    //
    // There isn't an elegant way to listen to this, so this test has to poll.
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (ui.PlatformDispatcher.instance.onKeyData != null) {
        break;
      }
    }

    bool receivedKeyData3 = false;
    HardwareKeyboard.instance.addHandler((KeyEvent event) {
      expect(event.timeStamp.inMicroseconds, 3);
      receivedKeyData3 = true;
      return true;
    });

    // The first event after binding initialization.
    final Completer<void> rawEvent3Processed = Completer<void>();
    sendKeyData(fakeKeyData(ui.KeyEventType.down, 3),
      rawKeyEventCallback: (ByteData? response) {
        rawEvent3Processed.complete();
      },
    );
    await rawEvent3Processed.future;

    // The 3rd event is received without breaking the event rule.
    expect(receivedKeyData3, true);
  });
}
