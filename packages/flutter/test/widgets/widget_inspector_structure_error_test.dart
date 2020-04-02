import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_inspector_test.dart';

void main() {
  StructureErrorTestWidgetInspectorService.runTests();
}

class StructureErrorTestWidgetInspectorService extends TestWidgetInspectorService {

  static void runTests() {
    final TestWidgetInspectorService service = TestWidgetInspectorService();
    WidgetInspectorService.instance = service;

    test('ext.flutter.inspector.structuredErrors still report error to original on error', () async {
      final FlutterExceptionHandler oldHandler = FlutterError.onError;

      FlutterErrorDetails actualError;
      // Creates a spy onError. This spy needs to be set before widgets binding
      // initializes.
      FlutterError.onError = (FlutterErrorDetails details) {
        actualError = details;
      };

      WidgetsFlutterBinding.ensureInitialized();
      try {
        // Enable structured errors.
        expect(await service.testBoolExtension(
          'structuredErrors', <String, String>{'enabled': 'true'}),
          equals('true'));

        // Create an error.
        final FlutterErrorDetails expectedError = FlutterErrorDetailsForRendering(
          library: 'rendering library',
          context: ErrorDescription('during layout'),
          exception: StackTrace.current,
        );
        FlutterError.reportError(expectedError);

        // Validate the spy still received an error.
        expect(actualError, expectedError);
      } finally {
        FlutterError.onError = oldHandler;
      }
    });
  }
}