// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_inspector_test_utils.dart';

void main() {
  StructureErrorTestWidgetInspectorService.runTests();
}

class StructureErrorTestWidgetInspectorService extends TestWidgetInspectorService {
  static void runTests() {
    final StructureErrorTestWidgetInspectorService service = StructureErrorTestWidgetInspectorService();
    WidgetInspectorService.instance = service;

    test('ext.flutter.inspector.structuredErrors - custom FlutterError.onError', () async {
      // Regression test for https://github.com/flutter/flutter/issues/41540

      final FlutterExceptionHandler? oldHandler = FlutterError.onError;

      try {
        expect(service.getEventsDispatched('Flutter.Error'), isEmpty);

        // Set callback that doesn't call presentError.
        bool onErrorCalled = false;
        FlutterError.onError = (FlutterErrorDetails details) {
          onErrorCalled = true;
        };

        // Get the service registered.
        WidgetsFlutterBinding.ensureInitialized();

        final FlutterErrorDetails expectedError = FlutterErrorDetails(
          library: 'rendering library',
          context: ErrorDescription('during layout'),
          exception: StackTrace.current,
        );
        FlutterError.reportError(expectedError);

        // Verify structured errors are not shown.
        expect(onErrorCalled, true);
        expect(service.getEventsDispatched('Flutter.Error'), isEmpty);

        // Set callback that calls presentError.
        onErrorCalled = false;
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          onErrorCalled = true;
        };

        FlutterError.reportError(expectedError);

        // Verify structured errors are shown.
        expect(onErrorCalled, true);
        expect(service.getEventsDispatched('Flutter.Error'), hasLength(1));
      } finally {
        FlutterError.onError = oldHandler;
      }
    });
  }
}
