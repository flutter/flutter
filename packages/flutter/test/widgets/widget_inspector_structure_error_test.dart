// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StructureErrorTestWidgetInspectorService.runTests();
}

typedef InspectorServiceExtensionCallback = FutureOr<Map<String, Object?>> Function(Map<String, String> parameters);

class StructureErrorTestWidgetInspectorService extends Object with WidgetInspectorService {
  final Map<String, InspectorServiceExtensionCallback> extensions = <String, InspectorServiceExtensionCallback>{};

  final Map<String, List<Map<Object, Object?>>> eventsDispatched = <String, List<Map<Object, Object?>>>{};

  @override
  void registerServiceExtension({
    required String name,
    required FutureOr<Map<String, Object?>> Function(Map<String, String> parameters) callback,
  }) {
    assert(!extensions.containsKey(name));
    extensions[name] = callback;
  }

  @override
  void postEvent(String eventKind, Map<Object, Object?> eventData) {
    getEventsDispatched(eventKind).add(eventData);
  }

  List<Map<Object, Object?>> getEventsDispatched(String eventKind) {
    return eventsDispatched.putIfAbsent(eventKind, () => <Map<Object, Object?>>[]);
  }

  Iterable<Map<Object, Object?>> getServiceExtensionStateChangedEvents(String extensionName) {
    return getEventsDispatched('Flutter.ServiceExtensionStateChanged')
      .where((Map<Object, Object?> event) => event['extension'] == extensionName);
  }

  Future<String> testBoolExtension(String name, Map<String, String> arguments) async {
    expect(extensions, contains(name));
    // Encode and decode to JSON to match behavior using a real service
    // extension where only JSON is allowed.
    return json.decode(json.encode(await extensions[name]!(arguments)))['enabled'] as String;
  }


  static void runTests() {
    final StructureErrorTestWidgetInspectorService service = StructureErrorTestWidgetInspectorService();
    WidgetInspectorService.instance = service;

    test('ext.flutter.inspector.structuredErrors reports error to _structuredExceptionHandler on error', () async {
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;

      bool usingNewHandler = false;
      // Creates a spy onError. This spy needs to be set before widgets binding
      // initializes.
      FlutterError.onError = (FlutterErrorDetails details) {
        usingNewHandler = true;
      };

      WidgetsFlutterBinding.ensureInitialized();
      try {
        // Enables structured errors.
        expect(await service.testBoolExtension(
          'structuredErrors', <String, String>{'enabled': 'true'}),
          equals('true'));

        // Creates an error.
        final FlutterErrorDetails expectedError = FlutterErrorDetails(
          library: 'rendering library',
          context: ErrorDescription('during layout'),
          exception: StackTrace.current,
        );
        FlutterError.reportError(expectedError);

        // For non-web apps, this validates the new handler did not receive an
        // error because `FlutterError.onError` was set to
        // `WidgetInspectorService._structuredExceptionHandler` when service
        // extensions were initialized. For web apps, the new handler should
        // have received an error because structured errors are disabled by
        // default on the web.
        expect(usingNewHandler, equals(kIsWeb));
      } finally {
        FlutterError.onError = oldHandler;
      }
    });
  }
}
