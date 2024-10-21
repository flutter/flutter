// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('when receiving an unsupported message', () async {
    // Make sure Scribe is initialized and listening.
    final ScribeClient scribeClient = _TestScribeWidgetState();
    Scribe.client = scribeClient;

    final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'Scribe.unsupportedMessage',
    });

    final ByteData? response = await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/scribe',
      messageBytes,
      null,
    );

    // When a MissingPluginException is thrown, it is caught and a null response
    // is returned.
    expect(response, isNull);
  }, skip: kIsWeb); // [intended]

  test('Scribe.isStylusHandwritingAvailable calls through to platform channel', () async {
    final List<MethodCall> calls = <MethodCall>[];
    binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.scribe, (MethodCall methodCall) {
        calls.add(methodCall);
        return Future<void>.value();
      });

    await Scribe.isStylusHandwritingAvailable();

    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.isStylusHandwritingAvailable');
  }, skip: kIsWeb); // [intended]

  test('Scribe.isFeatureAvailable calls through to platform channel', () async {
    final List<MethodCall> calls = <MethodCall>[];
    binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.scribe, (MethodCall methodCall) {
        calls.add(methodCall);
        return Future<void>.value();
      });

    await Scribe.isFeatureAvailable();

    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.isFeatureAvailable');
  }, skip: kIsWeb); // [intended]

  test('Scribe.startStylusHandwriting calls through to platform channel', () async {
    final List<MethodCall> calls = <MethodCall>[];
    binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.scribe, (MethodCall methodCall) {
        calls.add(methodCall);
        return Future<void>.value();
      });

    Scribe.startStylusHandwriting();
    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.startStylusHandwriting');
  }, skip: kIsWeb); // [intended]
}

// A widget that uses ScribeClient.
class _TestScribeWidget extends StatefulWidget {
  const _TestScribeWidget();

  @override
  State<_TestScribeWidget> createState() => _TestScribeWidgetState();
}

class _TestScribeWidgetState extends State<_TestScribeWidget> implements ScribeClient {
  // Begin ScribeClient.

  @override
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(context);

  @override
  bool get isActive => true;

  // End ScribeClient.

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
