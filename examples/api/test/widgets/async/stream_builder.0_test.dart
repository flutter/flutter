// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/async/stream_builder.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamBuilderExampleApp', () {
    testWidgets(
      'listens to the internal stream events and rebuilds according them',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const example.StreamBuilderExampleApp(),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Awaiting bids...'), findsOneWidget);

        await tester.pump(example.StreamBuilderExampleApp.delay);

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.text(r'$1'), findsOneWidget);

        await tester.pump(example.StreamBuilderExampleApp.delay);

        expect(find.byIcon(Icons.info), findsOneWidget);
        expect(find.text(r'$1 (closed)'), findsOneWidget);
      },
    );

    group('BidsStatus', () {
      testWidgets(
        'correctly displays error state',
        (WidgetTester tester) async {
          final StreamController<int> controller = StreamController<int>();
          addTearDown(controller.close);

          controller.onListen = () {
            controller.addError('Unexpected error!', StackTrace.current);
          };

          await tester.pumpWidget(
            MaterialApp(
              home: example.BidsStatus(bids: controller.stream),
            ),
          );
          await tester.pump();

          expect(find.byIcon(Icons.error_outline), findsOneWidget);
          expect(find.text('Error: Unexpected error!'), findsOneWidget);
          expect(find.text('Stack trace: ${StackTrace.empty}'), findsOneWidget);
        },
      );

      testWidgets(
        'correctly displays none state',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: example.BidsStatus(bids: null),
            ),
          );

          expect(find.byIcon(Icons.info), findsOneWidget);
          expect(find.text('Select a lot'), findsOneWidget);
        },
      );

      testWidgets(
        'correctly displays waiting state',
        (WidgetTester tester) async {
          final StreamController<int> controller = StreamController<int>();
          addTearDown(controller.close);

          await tester.pumpWidget(
            MaterialApp(
              home: example.BidsStatus(bids: controller.stream),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Awaiting bids...'), findsOneWidget);
        },
      );

      testWidgets(
        'correctly displays active state',
        (WidgetTester tester) async {
          final StreamController<int> controller = StreamController<int>();
          addTearDown(controller.close);

          controller.onListen = () {
            controller.add(1);
          };

          await tester.pumpWidget(
            MaterialApp(
              home: example.BidsStatus(bids: controller.stream),
            ),
          );
          await tester.pump();

          expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
          expect(find.text(r'$1'), findsOneWidget);
        },
      );

      testWidgets(
        'correctly displays done state',
        (WidgetTester tester) async {
          final StreamController<int> controller = StreamController<int>();
          controller.close();

          await tester.pumpWidget(
            MaterialApp(
              home: example.BidsStatus(bids: controller.stream),
            ),
          );
          await tester.pump();

          expect(find.byIcon(Icons.info), findsOneWidget);
          expect(find.text('(closed)'), findsOneWidget);
        },
      );
    });
  });
}
