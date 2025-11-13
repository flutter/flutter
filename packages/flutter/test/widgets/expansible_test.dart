// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Controller expands and collapses the widget', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          bodyBuilder: (BuildContext context, Animation<double> animation) => const Text('Body'),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);
    controller.expand();
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);

    controller.dispose();
  });

  testWidgets('Can listen to the expansion state', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    bool? expansionState;
    controller.addListener(() {
      expansionState = controller.isExpanded;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          bodyBuilder: (BuildContext context, Animation<double> animation) => const Text('Body'),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    // Tap on the header to toggle the expansion.
    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(expansionState, true);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(expansionState, false);

    // Use the controller to toggle the expansion.
    controller.expand();
    await tester.pumpAndSettle();
    expect(expansionState, true);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(expansionState, false);

    controller.dispose();
  });

  testWidgets('Can set expansible to be initially expanded', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    controller.expand();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Expansible(
                controller: controller,
                bodyBuilder: (BuildContext context, Animation<double> animation) =>
                    const Text('Body'),
                headerBuilder: (BuildContext context, Animation<double> animation) =>
                    GestureDetector(
                      onTap: controller.isExpanded ? controller.collapse : controller.expand,
                      child: const Text('Header'),
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsOneWidget);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsNothing);

    controller.dispose();
  });

  testWidgets('Can compose header and body with expansibleBuilder', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          bodyBuilder: (BuildContext context, Animation<double> animation) => const Text('Body'),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
          expansibleBuilder:
              (BuildContext context, Widget header, Widget body, Animation<double> animation) {
                return header;
              },
        ),
      ),
    );

    // Tap on the header to toggle the expansion.
    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Body'), findsNothing);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Body'), findsNothing);

    // Use the controller to toggle the expansion.
    controller.expand();
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Body'), findsNothing);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Body'), findsNothing);

    controller.dispose();
  });

  testWidgets('Respects maintainState', (WidgetTester tester) async {
    final ExpansibleController controller1 = ExpansibleController();
    final ExpansibleController controller2 = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Expansible(
                controller: controller1,
                maintainState: false,
                bodyBuilder: (BuildContext context, Animation<double> animation) =>
                    const Text('Maintaining State'),
                headerBuilder: (BuildContext context, Animation<double> animation) =>
                    GestureDetector(
                      onTap: controller1.isExpanded ? controller1.collapse : controller1.expand,
                      child: const Text('Header'),
                    ),
              ),
              Expansible(
                controller: controller2,
                bodyBuilder: (BuildContext context, Animation<double> animation) =>
                    const Text('Discarding State'),
                headerBuilder: (BuildContext context, Animation<double> animation) =>
                    GestureDetector(
                      onTap: controller2.isExpanded ? controller2.collapse : controller2.expand,
                      child: const Text('Header'),
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    // This text is not offstage while the expansible widget is collapsed.
    expect(find.text('Maintaining State', skipOffstage: false), findsNothing);
    expect(find.text('Maintaining State'), findsNothing);
    // This text is not displayed while the expansible widget is collapsed.
    expect(find.text('Discarding State'), findsNothing);

    controller1.dispose();
    controller2.dispose();
  });

  testWidgets('Respects animation duration and curves', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
          bodyBuilder: (BuildContext context, Animation<double> animation) =>
              const SizedBox(height: 50.0, child: Placeholder()),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);

    await tester.tap(find.text('Header'));

    // Check that the curve is respected.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 90.08984375);

    // The animation has completed.
    await tester.pump(const Duration(milliseconds: 60) + const Duration(microseconds: 1));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 98.0);

    // Since the animation has completed, the vertical position doesn't change.
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 98.0);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Header'));

    // Check that the reverse curve is respected.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 80.91015625);

    // The animation has completed.
    await tester.pump(const Duration(milliseconds: 60) + const Duration(microseconds: 1));
    expect(find.byType(Placeholder), findsNothing);

    controller.dispose();
  });

  testWidgets('ExpansionTile can accept a new controller', (WidgetTester tester) async {
    final ExpansibleController controller1 = ExpansibleController();
    final ExpansibleController controller2 = ExpansibleController();
    addTearDown(() {
      controller1.dispose();
      controller2.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Expansible(
            controller: controller1,
            headerBuilder: (_, _) => const Text('Header'),
            bodyBuilder: (_, _) => const Text('Body'),
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);
    expect(controller1.isExpanded, isFalse);

    controller1.expand();
    expect(controller1.isExpanded, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOne);

    controller1.collapse();
    expect(controller1.isExpanded, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Expansible(
            controller: controller2,
            headerBuilder: (_, _) => const Text('Header'),
            bodyBuilder: (_, _) => const Text('Body'),
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);
    expect(controller2.isExpanded, isFalse);

    controller2.expand();
    expect(controller2.isExpanded, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOne);

    controller2.collapse();
    expect(controller2.isExpanded, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('Expansible can accept a new controller with a different state', (
    WidgetTester tester,
  ) async {
    final ExpansibleController controller1 = ExpansibleController();
    final ExpansibleController controller2 = ExpansibleController();
    addTearDown(() {
      controller1.dispose();
      controller2.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Expansible(
            controller: controller1,
            headerBuilder: (_, _) => const Text('Header'),
            bodyBuilder: (_, _) => const Text('Body'),
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);
    expect(controller1.isExpanded, isFalse);

    controller1.expand();
    expect(controller1.isExpanded, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOne);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Expansible(
            controller: controller2,
            headerBuilder: (_, _) => const Text('Header'),
            bodyBuilder: (_, _) => const Text('Body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller2.isExpanded, isFalse);
    expect(find.text('Body'), findsNothing);

    controller2.expand();
    expect(controller2.isExpanded, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOne);

    controller2.collapse();
    expect(controller2.isExpanded, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('Respects animationStyle duration and curves', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          animationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 120),
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          bodyBuilder: (BuildContext context, Animation<double> animation) =>
              const SizedBox(height: 50.0, child: Placeholder()),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);

    await tester.tap(find.text('Header'));

    // Check that the curve is respected.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 90.08984375);

    // The animation has completed.
    await tester.pump(const Duration(milliseconds: 60) + const Duration(microseconds: 1));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 98.0);

    // Since the animation has completed, the vertical position doesn't change.
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 98.0);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Header'));

    // Check that the reverse curve is respected.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 80.91015625);

    // The animation has completed.
    await tester.pump(const Duration(milliseconds: 60) + const Duration(microseconds: 1));
    expect(find.byType(Placeholder), findsNothing);

    controller.dispose();
  });

  testWidgets('AnimationStyle takes precedence over deprecated properties', (
    WidgetTester tester,
  ) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          animationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 100),
            curve: Curves.linear,
          ),
          bodyBuilder: (BuildContext context, Animation<double> animation) =>
              const SizedBox(height: 50.0, child: Placeholder()),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);

    await tester.tap(find.text('Header'));

    // Check that the animationStyle duration (100ms) is used
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // With linear curve at 50ms out of 100ms, should be at approximately 50% height
    final double midAnimationY = tester.getBottomLeft(find.byType(Placeholder)).dy;
    // Should be more than base (48.0) and less than fully expanded (98.0)
    expect(midAnimationY, greaterThan(48.0));
    expect(midAnimationY, lessThan(98.0));

    // Animation should complete at 100ms
    await tester.pump(const Duration(milliseconds: 50) + const Duration(microseconds: 1));
    expect(tester.getBottomLeft(find.byType(Placeholder)).dy, 98.0);

    controller.dispose();
  });

  testWidgets('AnimationStyle.noAnimation disables animation', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Expansible(
          controller: controller,
          animationStyle: AnimationStyle.noAnimation,
          bodyBuilder: (BuildContext context, Animation<double> animation) => const Text('Body'),
          headerBuilder: (BuildContext context, Animation<double> animation) => GestureDetector(
            onTap: controller.isExpanded ? controller.collapse : controller.expand,
            child: const Text('Header'),
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);

    controller.expand();
    await tester.pump();

    expect(find.text('Body'), findsOneWidget);

    controller.collapse();
    await tester.pump();

    expect(find.text('Body'), findsNothing);

    controller.dispose();
  });
}
