// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_inspector_test_utils.dart';

void main() {
  StructuredErrorTestService.runTests();
}

class StructuredErrorTestService extends TestWidgetInspectorService {
  @override
  bool isStructuredErrorsEnabled() {
    return true;
  }

  static void runTests() {
    final StructuredErrorTestService service = StructuredErrorTestService();
    WidgetInspectorService.instance = service;
    FlutterExceptionHandler testHandler;
    FlutterExceptionHandler inspectorServiceErrorHandler;

    setUpAll(() {
      inspectorServiceErrorHandler = FlutterError.onError;
    });

    setUp(() {
      testHandler = FlutterError.onError;
    });

    testWidgets('ext.flutter.inspector.setStructuredErrors',
        (WidgetTester tester) async {
      // The test framework resets FlutterError.onError, so we set it back to
      // what it was after WidgetInspectorService::initServiceExtensions ran.
      FlutterError.onError = inspectorServiceErrorHandler;

      List<Map<Object, Object>> flutterErrorEvents =
          service.getEventsDispatched('Flutter.Error');
      expect(flutterErrorEvents, hasLength(0));

      // Create an error.
      FlutterError.reportError(FlutterErrorDetails(
        library: 'rendering library',
        context: ErrorDescription('during layout'),
        exception: StackTrace.current,
      ));

      // Validate that we received an error.
      flutterErrorEvents = service.getEventsDispatched('Flutter.Error');
      expect(flutterErrorEvents, hasLength(1));
    });

    tearDown(() {
      FlutterError.onError = testHandler;
    });
  }
}
