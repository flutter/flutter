// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test/src/callback.dart' as driver_actions;

/// A [CallbackManager] written before `click` existed, implementing only the
/// members that were abstract at that time.
class _PreexistingCallbackManager extends CallbackManager {
  @override
  Future<Map<String, dynamic>> callback(
    Map<String, String> params,
    IntegrationTestResults testRunner,
  ) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> takeScreenshot(
    String screenshot, [
    Map<String, Object?>? args,
  ]) async => <String, dynamic>{};

  @override
  Future<void> convertFlutterSurfaceToImage() async {}

  @override
  void cleanup() {}
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WebDriverCommand.click', () {
    test('carries the click type and viewport coordinates', () {
      final command = WebDriverCommand.click(12.5, 34.25);

      expect(command.type, WebDriverCommandType.click);
      expect(command.values, <String, dynamic>{'x': 12.5, 'y': 34.25});
    });

    test('serializes to the web_driver_command message the host driver reads', () {
      final command = WebDriverCommand.click(12.5, 34.25);
      final data = Map<String, dynamic>.of(command.values)
        ..addAll(WebDriverCommand.typeToMap(command.type));

      final Response received = Response.fromJson(Response.webDriverCommand(data: data).toJson());

      expect(received.data, <String, dynamic>{
        'x': 12.5,
        'y': 34.25,
        'web_driver_command': 'WebDriverCommandType.click',
      });
    });
  });

  group('CallbackManager.click', () {
    test('returns Future<void> rather than a response map', () {
      final CallbackManager manager = _PreexistingCallbackManager();

      expect(manager.click, isA<Future<void> Function(double, double)>());
      expect(manager.click, isNot(isA<Future<Map<String, dynamic>> Function(double, double)>()));
    });

    test('defaults to UnsupportedError for implementations that predate it', () async {
      final CallbackManager manager = _PreexistingCallbackManager();

      await expectLater(() => manager.click(1, 2), throwsUnsupportedError);
    });

    test('throws UnsupportedError off the web', () async {
      await expectLater(
        () => driver_actions.callbackManager.click(1, 2),
        throwsA(
          isUnsupportedError.having(
            (UnsupportedError error) => error.message,
            'message',
            'webDriverClick is only supported on the web',
          ),
        ),
      );
    });
  });

  testWidgets('webDriverClick throws UnsupportedError off the web', (WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.expand());

    await expectLater(
      () => binding.webDriverClick(const Offset(10, 20)),
      throwsA(
        isUnsupportedError.having(
          (UnsupportedError error) => error.message,
          'message',
          contains('webDriverClick'),
        ),
      ),
    );
    expect(binding.shouldPropagateDevicePointerEvents, isFalse);
  });
}
