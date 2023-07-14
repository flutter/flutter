// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data' show ByteData, Uint8List;
import 'dart:ui' as ui;
import 'dart:convert';

// Signals a waiting latch in the native test.
@pragma('vm:external-name', 'Signal')
external void signal();

// Signals a waiting latch in the native test, passing a boolean value.
@pragma('vm:external-name', 'SignalBoolValue')
external void signalBoolValue(bool value);

// Signals a waiting latch in the native test, passing a string value.
@pragma('vm:external-name', 'SignalStringValue')
external void signalStringValue(String value);

// Signals a waiting latch in the native test, which returns a value to the fixture.
@pragma('vm:external-name', 'SignalBoolReturn')
external bool signalBoolReturn();

// Notify the native test that the first frame has been scheduled.
@pragma('vm:external-name', 'NotifyFirstFrameScheduled')
external void notifyFirstFrameScheduled();

void main() {}

@pragma('vm:entry-point')
void hiPlatformChannels() {
  ui.channelBuffers.setListener('hi',
      (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
    ui.PlatformDispatcher.instance.sendPlatformMessage('hi', data,
        (ByteData? reply) {
      ui.PlatformDispatcher.instance
          .sendPlatformMessage('hi', reply, (ByteData? reply) {});
    });
    callback(data);
  });
}

@pragma('vm:entry-point')
void alertPlatformChannel() async {
  // Serializers for data types are in the framework, so this will be hardcoded.
  const int valueMap = 13, valueString = 7;
  // Corresponds to:
  // Map<String, Object> data =
  // {"type": "announce", "data": {"message": ""}};
  final Uint8List data = Uint8List.fromList([
    valueMap, // _valueMap
    2, // Size
    // key: "type"
    valueString,
    'type'.length,
    ...'type'.codeUnits,
    // value: "announce"
    valueString,
    'announce'.length,
    ...'announce'.codeUnits,
    // key: "data"
    valueString,
    'data'.length,
    ...'data'.codeUnits,
    // value: map
    valueMap, // _valueMap
    1, // Size
    // key: "message"
    valueString,
    'message'.length,
    ...'message'.codeUnits,
    // value: ""
    valueString,
    0, // Length of empty string == 0.
  ]);
  final ByteData byteData = data.buffer.asByteData();

  final Completer<ByteData?> enabled = Completer<ByteData?>();
  ui.PlatformDispatcher.instance.sendPlatformMessage('semantics', ByteData(0), (ByteData? reply){
    enabled.complete(reply);
  });
  await enabled.future;

  ui.PlatformDispatcher.instance.sendPlatformMessage('flutter/accessibility', byteData, (ByteData? _){});
}

@pragma('vm:entry-point')
void exitTestExit() async {
  final Completer<ByteData?> closed = Completer<ByteData?>();
  ui.channelBuffers.setListener('flutter/platform', (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
    final String jsonString = json.encode(<Map<String, String>>[{'response': 'exit'}]);
    final ByteData responseData = ByteData.sublistView(utf8.encode(jsonString));
    callback(responseData);
    closed.complete(data);
  });
  await closed.future;
}

@pragma('vm:entry-point')
void exitTestCancel() async {
  final Completer<ByteData?> closed = Completer<ByteData?>();
  ui.channelBuffers.setListener('flutter/platform', (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
    final String jsonString = json.encode(<Map<String, String>>[{'response': 'cancel'}]);
    final ByteData responseData = ByteData.sublistView(utf8.encode(jsonString));
    callback(responseData);
    closed.complete(data);
  });
  await closed.future;

  // Because the request was canceled, the below shall execute.
  final Completer<ByteData?> exited = Completer<ByteData?>();
  final String jsonString = json.encode(<String, dynamic>{
    'method': 'System.exitApplication',
    'args': <String, dynamic>{
      'type': 'required', 'exitCode': 0
      }
    });
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform',
    ByteData.sublistView(utf8.encode(jsonString)),
    (ByteData? reply) {
      exited.complete(reply);
    });
  await exited.future;
}

@pragma('vm:entry-point')
void customEntrypoint() {}

@pragma('vm:entry-point')
void verifyNativeFunction() {
  signal();
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithParameters() {
  signalBoolValue(true);
}

@pragma('vm:entry-point')
void verifyNativeFunctionWithReturn() {
  bool value = signalBoolReturn();
  signalBoolValue(value);
}

@pragma('vm:entry-point')
void readPlatformExecutable() {
  signalStringValue(io.Platform.executable);
}

@pragma('vm:entry-point')
void drawHelloWorld() {
  ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    final ui.ParagraphBuilder paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle())..addText('Hello world');
    final ui.Paragraph paragraph = paragraphBuilder.build();

    paragraph.layout(const ui.ParagraphConstraints(width: 800.0));

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    canvas.drawParagraph(paragraph, ui.Offset.zero);

    final ui.Picture picture = recorder.endRecording();
    final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
      ..addPicture(ui.Offset.zero, picture)
      ..pop();

    ui.window.render(sceneBuilder.build());
  };

  ui.PlatformDispatcher.instance.scheduleFrame();
  notifyFirstFrameScheduled();
}
