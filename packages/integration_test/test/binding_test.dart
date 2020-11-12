// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:integration_test/integration_test.dart';
import 'package:integration_test/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart' as vm;

vm.Timeline _kTimelines = vm.Timeline(
  traceEvents: <vm.TimelineEvent>[],
  timeOriginMicros: 100,
  timeExtentMicros: 200,
);

Future<void> main() async {
  Future<Map<String, dynamic>> request;

  group('Test Integration binding', () {
    final WidgetsBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    assert(binding is IntegrationTestWidgetsFlutterBinding);
    final IntegrationTestWidgetsFlutterBinding integrationBinding = binding as IntegrationTestWidgetsFlutterBinding;

    MockVM mockVM;
    final List<int> clockTimes = <int>[100, 200];

    setUp(() {
      request = integrationBinding.callback(<String, String>{
        'command': 'request_data',
      });
      mockVM = MockVM();
      when(mockVM.getVMTimeline(
        timeOriginMicros: anyNamed('timeOriginMicros'),
        timeExtentMicros: anyNamed('timeExtentMicros'),
      )).thenAnswer((_) => Future<vm.Timeline>.value(_kTimelines));
      when(mockVM.getVMTimelineMicros()).thenAnswer(
        (_) => Future<vm.Timestamp>.value(vm.Timestamp(timestamp: clockTimes.removeAt(0))),
      );
    });

    testWidgets('Run Integration app', (WidgetTester tester) async {
      runApp(const MaterialApp(
        home: Text('Test'),
      ));
      expect(tester.binding, integrationBinding);
      integrationBinding.reportData = <String, dynamic>{'answer': 42};
    });

    testWidgets('setSurfaceSize works', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Center(child: Text('Test'))));

      final Size windowCenter = tester.binding.window.physicalSize /
          tester.binding.window.devicePixelRatio /
          2;
      final double windowCenterX = windowCenter.width;
      final double windowCenterY = windowCenter.height;

      Offset widgetCenter = tester.getRect(find.byType(Text)).center;
      expect(widgetCenter.dx, windowCenterX);
      expect(widgetCenter.dy, windowCenterY);

      await tester.binding.setSurfaceSize(const Size(200, 300));
      await tester.pump();
      widgetCenter = tester.getRect(find.byType(Text)).center;
      expect(widgetCenter.dx, 100);
      expect(widgetCenter.dy, 150);

      await tester.binding.setSurfaceSize(null);
      await tester.pump();
      widgetCenter = tester.getRect(find.byType(Text)).center;
      expect(widgetCenter.dx, windowCenterX);
      expect(widgetCenter.dy, windowCenterY);
    });

    testWidgets('Test traceAction', (WidgetTester tester) async {
      await integrationBinding.enableTimeline(vmService: mockVM);
      await integrationBinding.traceAction(() async {});
      expect(integrationBinding.reportData, isNotNull);
      expect(integrationBinding.reportData.containsKey('timeline'), true);
      expect(
        json.encode(integrationBinding.reportData['timeline']),
        json.encode(_kTimelines),
      );
    });

    group('defaultTestTimeout', () {
      final Timeout originalTimeout = integrationBinding.defaultTestTimeout;
      tearDown(() {
        integrationBinding.defaultTestTimeout = originalTimeout;
      });

      test('can be configured', () {
        const Timeout newTimeout = Timeout(Duration(seconds: 17));
        integrationBinding.defaultTestTimeout = newTimeout;
        expect(integrationBinding.defaultTestTimeout, newTimeout);
      });
    });

    // TODO(jiahaog): Remove when https://github.com/flutter/flutter/issues/66006 is fixed.
    testWidgets('root widgets are wrapped with a RepaintBoundary', (WidgetTester tester) async {
      await tester.pumpWidget(const Placeholder());

      expect(find.byType(RepaintBoundary), findsOneWidget);
    });
  });

  tearDownAll(() async {
    // This part is outside the group so that `request` has been compeleted as
    // part of the `tearDownAll` registerred in the group during
    // `IntegrationTestWidgetsFlutterBinding` initialization.
    final Map<String, dynamic> response =
        (await request)['response'] as Map<String, dynamic>;
    final String message = response['message'] as String;
    final Response result = Response.fromJson(message);
    assert(result.data['answer'] == 42);
  });
}

class MockVM extends Mock implements vm.VmService {}
