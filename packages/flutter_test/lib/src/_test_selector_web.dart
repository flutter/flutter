// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:stream_channel/stream_channel.dart';
import 'package:test_api/backend.dart';

import '_goldens_web.dart';
import 'goldens.dart';
import 'web.dart' as web;

// This file contains APIs that are used by the generated test harness for
// running flutter unit tests.

/// A `main` entry point for a test.
typedef EntryPoint = FutureOr<void> Function();

/// An entry point runner provided by a test config file
typedef EntryPointRunner = Future<void> Function(EntryPoint);

/// Metadata about a web test to run
typedef WebTest = ({EntryPoint entryPoint, EntryPointRunner? entryPointRunner, Uri goldensUri});

/// Gets the test selector set by the test bootstrapping logic
String get testSelector {
  final JSString? jsTestSelector = web.window.testSelector;
  if (jsTestSelector == null) {
    throw Exception('Test selector not set');
  }
  return jsTestSelector.toDart;
}

/// Runs a specific web test
Future<void> runWebTest(WebTest test) async {
  print('DEBUG: runWebTest started');
  ui_web.TestEnvironment.setUp(const ui_web.TestEnvironment.flutterTester());
  final completer = Completer<void>();
  print('DEBUG: calling bootstrapEngine');
  await ui_web.bootstrapEngine(runApp: () => completer.complete());
  print('DEBUG: bootstrapEngine returned, waiting for runApp callback');
  await completer.future;
  print('DEBUG: runApp callback received');

  goldenFileComparator = HttpProxyGoldenComparator(test.goldensUri);

  /// This hard-codes the device pixel ratio to 3.0 and a 2400 x 1800 window
  /// size for the purposes of testing.
  ui_web.debugOverrideDevicePixelRatio(3.0);
  ui.window.debugPhysicalSizeOverride = const ui.Size(2400, 1800);

  final EntryPointRunner? entryPointRunner = test.entryPointRunner;
  final EntryPoint entryPoint = test.entryPoint;
  _internalBootstrapBrowserTest(() {
    return entryPointRunner != null ? () => entryPointRunner(entryPoint) : entryPoint;
  });
}

void _internalBootstrapBrowserTest(EntryPoint Function() getMain) {
  print('DEBUG: _internalBootstrapBrowserTest started');
  final StreamChannel<Object?> channel = _serializeSuite(getMain, hidePrints: false);
  print('DEBUG: _serializeSuite returned');
  _postMessageChannel().pipe(channel);
  print('DEBUG: _postMessageChannel piped');
}

StreamChannel<Object?> _serializeSuite(EntryPoint Function() getMain, {bool hidePrints = true}) =>
    RemoteListener.start(getMain, hidePrints: hidePrints);

StreamChannel<Object?> _postMessageChannel() {
  print('DEBUG: _postMessageChannel started');
  final controller = StreamChannelController<Object?>(sync: true);
  final channel = web.MessageChannel();
  print('DEBUG: sending port message to parent');
  web.window.parent!.postMessage(
    'port'.toJS,
    web.window.location.origin,
    <JSObject>[channel.port2].toJS,
  );
  print('DEBUG: port message sent');

  final JSFunction eventCallback = (web.Event event) {
    controller.local.sink.add(event.data.dartify());
  }.toJS;
  channel.port1.addEventListener('message'.toJS, eventCallback);
  channel.port1.start();
  controller.local.stream.listen(
    (Object? message) => channel.port1.postMessage(message.jsify()),
    onDone: () => channel.port1.removeEventListener('message'.toJS, eventCallback),
  );

  return controller.foreign;
}
