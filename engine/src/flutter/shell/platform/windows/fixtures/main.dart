// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data' show ByteData, Float64List, Int32List, Uint8List;
import 'dart:ui' as ui;

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
  ui.channelBuffers.setListener('hi', (
    ByteData? data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    ui.PlatformDispatcher.instance.sendPlatformMessage('hi', data, (ByteData? reply) {
      ui.PlatformDispatcher.instance.sendPlatformMessage('hi', reply, (ByteData? reply) {});
    });
    callback(data);
  });
}

/// Returns a future that completes when
/// `PlatformDispatcher.instance.onSemanticsEnabledChanged` fires.
Future<void> get semanticsChanged {
  final semanticsChanged = Completer<void>();
  ui.PlatformDispatcher.instance.onSemanticsEnabledChanged = semanticsChanged.complete;
  return semanticsChanged.future;
}

@pragma('vm:entry-point')
Future<void> sendAccessibilityAnnouncement() async {
  // Wait until semantics are enabled.
  if (!ui.PlatformDispatcher.instance.semanticsEnabled) {
    await semanticsChanged;
  }

  // Standard message codec magic number identifiers.
  // See: https://github.com/flutter/flutter/blob/ee94fe262b63b0761e8e1f889ae52322fef068d2/packages/flutter/lib/src/services/message_codecs.dart#L262
  const valueMap = 13, valueString = 7, valueInt64 = 4;

  // Corresponds to: {"type": "announce", "data": {"viewId": 0, "message": "hello"}}
  // See: https://github.com/flutter/flutter/blob/b781da9b5822de1461a769c3b245075359f5464d/packages/flutter/lib/src/semantics/semantics_event.dart#L86
  final data = Uint8List.fromList([
    // Map with 2 entries
    valueMap, 2,
    // Map key: "type"
    valueString, 'type'.length, ...'type'.codeUnits,
    // Map value: "announce"
    valueString, 'announce'.length, ...'announce'.codeUnits,
    // Map key: "data"
    valueString, 'data'.length, ...'data'.codeUnits,
    // Map value: map with 2 entries
    valueMap, 2,
    // Map key: "viewId"
    valueString, 'viewId'.length, ...'viewId'.codeUnits,
    // Map value: 0
    valueInt64, 0, 0, 0, 0, 0, 0, 0, 0,
    // Map key: "message"
    valueString, 'message'.length, ...'message'.codeUnits,
    // Map value: "hello"
    valueString, 'hello'.length, ...'hello'.codeUnits,
  ]);
  final ByteData byteData = data.buffer.asByteData();

  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/accessibility',
    byteData,
    (ByteData? _) => signal(),
  );
}

@pragma('vm:entry-point')
Future<void> sendAccessibilityTooltipEvent() async {
  // Wait until semantics are enabled.
  if (!ui.PlatformDispatcher.instance.semanticsEnabled) {
    await semanticsChanged;
  }

  // Standard message codec magic number identifiers.
  // See: https://github.com/flutter/flutter/blob/ee94fe262b63b0761e8e1f889ae52322fef068d2/packages/flutter/lib/src/services/message_codecs.dart#L262
  const valueMap = 13, valueString = 7;

  // Corresponds to: {"type": "tooltip", "data": {"message": "hello"}}
  // See: https://github.com/flutter/flutter/blob/b781da9b5822de1461a769c3b245075359f5464d/packages/flutter/lib/src/semantics/semantics_event.dart#L120
  final data = Uint8List.fromList([
    // Map with 2 entries
    valueMap, 2,
    // Map key: "type"
    valueString, 'type'.length, ...'type'.codeUnits,
    // Map value: "tooltip"
    valueString, 'tooltip'.length, ...'tooltip'.codeUnits,
    // Map key: "data"
    valueString, 'data'.length, ...'data'.codeUnits,
    // Map value: map with 1 entry
    valueMap, 1,
    // Map key: "message"
    valueString, 'message'.length, ...'message'.codeUnits,
    // Map value: "hello"
    valueString, 'hello'.length, ...'hello'.codeUnits,
  ]);
  final ByteData byteData = data.buffer.asByteData();

  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/accessibility',
    byteData,
    (ByteData? _) => signal(),
  );
}

@pragma('vm:entry-point')
Future<void> exitTestExit() async {
  final closed = Completer<ByteData?>();
  ui.channelBuffers.setListener('flutter/platform', (
    ByteData? data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    final String jsonString = json.encode(<Map<String, String>>[
      {'response': 'exit'},
    ]);
    final responseData = ByteData.sublistView(utf8.encode(jsonString));
    callback(responseData);
    closed.complete(data);
  });
  await closed.future;
}

@pragma('vm:entry-point')
Future<void> exitTestCancel() async {
  final closed = Completer<ByteData?>();
  ui.channelBuffers.setListener('flutter/platform', (
    ByteData? data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    final String jsonString = json.encode(<Map<String, String>>[
      {'response': 'cancel'},
    ]);
    final responseData = ByteData.sublistView(utf8.encode(jsonString));
    callback(responseData);
    closed.complete(data);
  });
  await closed.future;

  // Because the request was canceled, the below shall execute.
  final exited = Completer<ByteData?>();
  final String jsonString = json.encode(<String, dynamic>{
    'method': 'System.exitApplication',
    'args': <String, dynamic>{'type': 'required', 'exitCode': 0},
  });
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform',
    ByteData.sublistView(utf8.encode(jsonString)),
    (ByteData? reply) {
      exited.complete(reply);
    },
  );
  await exited.future;
}

@pragma('vm:entry-point')
Future<void> enableLifecycleTest() async {
  final finished = Completer<ByteData?>();
  ui.channelBuffers.setListener('flutter/lifecycle', (
    ByteData? data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    if (data != null) {
      ui.PlatformDispatcher.instance.sendPlatformMessage('flutter/unittest', data, (
        ByteData? reply,
      ) {
        finished.complete();
      });
    }
  });
  await finished.future;
}

@pragma('vm:entry-point')
Future<void> enableLifecycleToFrom() async {
  ui.channelBuffers.setListener('flutter/lifecycle', (
    ByteData? data,
    ui.PlatformMessageResponseCallback callback,
  ) async {
    if (data != null) {
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/unittest',
        data,
        (ByteData? reply) {},
      );
    }
  });
  final enabledLifecycle = Completer<ByteData?>();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform',
    ByteData.sublistView(utf8.encode('{"method":"System.initializationComplete"}')),
    (ByteData? data) {
      enabledLifecycle.complete(data);
    },
  );
}

@pragma('vm:entry-point')
Future<void> sendCreatePlatformViewMethod() async {
  // The platform view method channel uses the standard method codec.
  // See https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/services/message_codecs.dart#L262
  // for the implementation of the encoding and magic number identifiers.
  const valueString = 7;
  const valueMap = 13;
  const valueInt32 = 3;
  const method = 'create';
  const typeKey = 'viewType';
  const typeValue = 'type';
  const idKey = 'id';
  final data = <int>[
    // Method name
    valueString, method.length, ...utf8.encode(method),
    // Method arguments: {'type': 'type':, 'id': 0}
    valueMap, 2,
    valueString, typeKey.length, ...utf8.encode(typeKey),
    valueString, typeValue.length, ...utf8.encode(typeValue),
    valueString, idKey.length, ...utf8.encode(idKey),
    valueInt32, 0, 0, 0, 0,
  ];

  final completed = Completer<ByteData?>();
  final bytes = ByteData.sublistView(Uint8List.fromList(data));
  ui.PlatformDispatcher.instance.sendPlatformMessage('flutter/platform_views', bytes, (
    ByteData? response,
  ) {
    completed.complete(response);
  });
  await completed.future;
}

@pragma('vm:entry-point')
Future<void> sendGetKeyboardState() async {
  // The keyboard method channel uses the standard method codec.
  // See https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/services/message_codecs.dart#L262
  // for the implementation of the encoding and magic number identifiers.
  const valueNull = 0;
  const valueString = 7;
  const valueMap = 13;

  const method = 'getKeyboardState';
  final data = <int>[
    // Method name
    valueString, method.length, ...utf8.encode(method),
    // Method arguments: null
    valueNull, 2,
  ];

  final completer = Completer<void>();
  final bytes = ByteData.sublistView(Uint8List.fromList(data));
  ui.PlatformDispatcher.instance.sendPlatformMessage('flutter/keyboard', bytes, (
    ByteData? response,
  ) {
    // For magic numbers for decoding a reply envelope, see:
    // https://github.com/flutter/flutter/blob/67271f69f7f88a4edba6d8023099e3bd27a072d2/packages/flutter/lib/src/services/message_codecs.dart#L577-L587
    const replyEnvelopeSuccess = 0;

    // Ensure the response is a success containing a map of keyboard states.
    if (response == null) {
      signalStringValue('Unexpected null response');
    } else if (response.lengthInBytes < 2) {
      signalStringValue('Unexpected response length of ${response.lengthInBytes} bytes');
    } else if (response.getUint8(0) != replyEnvelopeSuccess) {
      signalStringValue('Unexpected response envelope status: ${response.getUint8(0)}');
    } else if (response.getUint8(1) != valueMap) {
      signalStringValue('Unexpected response value magic number: ${response.getUint8(1)}');
    } else {
      signalStringValue('Success');
    }
    completer.complete();
  });
  await completer.future;
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
  final bool value = signalBoolReturn();
  signalBoolValue(value);
}

@pragma('vm:entry-point')
void readPlatformExecutable() {
  signalStringValue(io.Platform.executable);
}

@pragma('vm:entry-point')
void drawHelloWorld() {
  ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())..addText('Hello world');
    final ui.Paragraph paragraph = paragraphBuilder.build();

    paragraph.layout(const ui.ParagraphConstraints(width: 800.0));

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawParagraph(paragraph, ui.Offset.zero);

    final ui.Picture picture = recorder.endRecording();
    final sceneBuilder = ui.SceneBuilder()
      ..addPicture(ui.Offset.zero, picture)
      ..pop();

    ui.PlatformDispatcher.instance.implicitView?.render(sceneBuilder.build());
  };

  ui.PlatformDispatcher.instance.scheduleFrame();
  notifyFirstFrameScheduled();
}

ui.Picture _createColoredBox(ui.Color color, ui.Size size) {
  final paint = ui.Paint();
  paint.color = color;
  final baseRecorder = ui.PictureRecorder();
  final canvas = ui.Canvas(baseRecorder);
  canvas.drawRect(ui.Rect.fromLTRB(0.0, 0.0, size.width, size.height), paint);
  return baseRecorder.endRecording();
}

@pragma('vm:entry-point')
void renderImplicitView() {
  ui.PlatformDispatcher.instance.onBeginFrame = (Duration duration) {
    const size = ui.Size(800.0, 600.0);
    const red = ui.Color.fromARGB(127, 255, 0, 0);

    final builder = ui.SceneBuilder();

    builder.pushOffset(0.0, 0.0);

    builder.addPicture(ui.Offset.zero, _createColoredBox(red, size));

    builder.pop();

    ui.PlatformDispatcher.instance.implicitView?.render(builder.build());
  };
  ui.PlatformDispatcher.instance.scheduleFrame();
}

@pragma('vm:entry-point')
void signalViewIds() {
  final Iterable<ui.FlutterView> views = ui.PlatformDispatcher.instance.views;
  final List<int> viewIds = views.map((ui.FlutterView view) => view.viewId).toList();

  viewIds.sort();

  signalStringValue('View IDs: [${viewIds.join(', ')}]');
}

@pragma('vm:entry-point')
void onMetricsChangedSignalViewIds() {
  ui.PlatformDispatcher.instance.onMetricsChanged = () {
    signalViewIds();
  };

  signal();
}

@pragma('vm:entry-point')
void mergedUIThread() {
  signal();
}

@pragma('vm:external-name', 'NotifyEngineId')
external void notifyEngineId(int? handle);

@pragma('vm:entry-point')
void testEngineId() {
  notifyEngineId(ui.PlatformDispatcher.instance.engineId);
}

@pragma('vm:entry-point')
void testWindowController() {
  signal();
}

@pragma('vm:entry-point')
Future<void> sendSemanticsTreeInfo() async {
  // Wait until semantics are enabled.
  if (!ui.PlatformDispatcher.instance.semanticsEnabled) {
    await semanticsChanged;
  }

  final Iterable<ui.FlutterView> views = ui.PlatformDispatcher.instance.views;
  final ui.FlutterView view1 = views.firstWhere(
    (final ui.FlutterView view) => view != ui.PlatformDispatcher.instance.implicitView,
  );
  final ui.FlutterView view2 = views.firstWhere(
    (final ui.FlutterView view) =>
        view != view1 && view != ui.PlatformDispatcher.instance.implicitView,
  );

  ui.SemanticsUpdate createSemanticsUpdate(int nodeId) {
    final builder = ui.SemanticsUpdateBuilder();
    final transform = Float64List(16);
    final hitTestTransform = Float64List(16);
    final childrenInTraversalOrder = Int32List(0);
    final childrenInHitTestOrder = Int32List(0);
    final additionalActions = Int32List(0);
    // Identity matrix 4x4.
    transform[0] = 1;
    transform[5] = 1;
    transform[10] = 1;
    builder.updateNode(
      id: nodeId,
      flags: ui.SemanticsFlags.none,
      actions: 0,
      maxValueLength: 0,
      currentValueLength: 0,
      textSelectionBase: -1,
      textSelectionExtent: -1,
      platformViewId: -1,
      scrollChildren: 0,
      scrollIndex: 0,
      traversalParent: -1,
      scrollPosition: 0,
      scrollExtentMax: 0,
      scrollExtentMin: 0,
      rect: const ui.Rect.fromLTRB(0, 0, 10, 10),
      identifier: 'identifier',
      label: 'label',
      labelAttributes: const <ui.StringAttribute>[],
      value: 'value',
      valueAttributes: const <ui.StringAttribute>[],
      increasedValue: 'increasedValue',
      increasedValueAttributes: const <ui.StringAttribute>[],
      decreasedValue: 'decreasedValue',
      decreasedValueAttributes: const <ui.StringAttribute>[],
      hint: 'hint',
      hintAttributes: const <ui.StringAttribute>[],
      tooltip: 'tooltip',
      textDirection: ui.TextDirection.ltr,
      transform: transform,
      hitTestTransform: hitTestTransform,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: additionalActions,
      role: ui.SemanticsRole.tab,
      controlsNodes: null,
      inputType: ui.SemanticsInputType.none,
      locale: null,
      minValue: '0',
      maxValue: '0',
    );
    return builder.build();
  }

  ui.PlatformDispatcher.instance.setSemanticsTreeEnabled(true);
  view1.updateSemantics(createSemanticsUpdate(view1.viewId + 1));
  view2.updateSemantics(createSemanticsUpdate(view2.viewId + 1));
  signal();
}
