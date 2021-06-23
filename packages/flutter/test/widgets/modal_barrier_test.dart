// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart' show kSecondaryButton, PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  late bool tapped;
  late bool hovered;
  late Widget tapTarget;
  late Widget hoverTarget;

  setUp(() {
    tapped = false;
    tapTarget = GestureDetector(
      onTap: () {
        tapped = true;
      },
      child: const SizedBox(
        width: 10.0,
        height: 10.0,
        child: Text('target', textDirection: TextDirection.ltr),
      ),
    );

    hovered = false;
    hoverTarget = MouseRegion(
      onHover: (_) { hovered = true; },
      onEnter: (_) { hovered = true; },
      onExit: (_) { hovered = true; },
      child: const SizedBox(
        width: 10.0,
        height: 10.0,
        child: Text('target', textDirection: TextDirection.ltr),
      ),
    );
  });

  testWidgets('ModalBarrier prevents interactions with widgets behind it', (WidgetTester tester) async {
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        tapTarget,
        const ModalBarrier(dismissible: false),
      ],
    );

    await tester.pumpWidget(subject);
    await tester.tap(find.text('target'), warnIfMissed: false);
    await tester.pumpWidget(subject);
    expect(tapped, isFalse, reason: 'because the tap is not prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier prevents hover interactions with widgets behind it', (WidgetTester tester) async {
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        hoverTarget,
        const ModalBarrier(dismissible: false),
      ],
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    // Start out of hoverTarget
    await gesture.moveTo(const Offset(100, 100));

    await tester.pumpWidget(subject);
    // Move into hoverTarget and tap
    await gesture.down(const Offset(5, 5));
    await tester.pumpWidget(subject);
    await gesture.up();
    await tester.pumpWidget(subject);

    // Move out
    await gesture.moveTo(const Offset(100, 100));
    await tester.pumpWidget(subject);

    expect(hovered, isFalse, reason: 'because the hover is not prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier does not prevent interactions with widgets in front of it', (WidgetTester tester) async {
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const ModalBarrier(dismissible: false),
        tapTarget,
      ],
    );

    await tester.pumpWidget(subject);
    await tester.tap(find.text('target'));
    await tester.pumpWidget(subject);
    expect(tapped, isTrue, reason: 'because the tap is prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier does not prevent interactions with translucent widgets in front of it', (WidgetTester tester) async {
    bool dragged = false;
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const ModalBarrier(dismissible: false),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            dragged = true;
          },
          child: const Center(
            child: Text('target', textDirection: TextDirection.ltr),
          ),
        ),
      ],
    );

    await tester.pumpWidget(subject);
    await tester.dragFrom(
      tester.getBottomRight(find.byType(GestureDetector)) - const Offset(10, 10),
      const Offset(-20, 0),
    );
    await tester.pumpWidget(subject);
    expect(dragged, isTrue, reason: 'because the drag is prevented by ModalBarrier');
  });

  testWidgets('ModalBarrier does not prevent hover interactions with widgets in front of it', (WidgetTester tester) async {
    final Widget subject = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const ModalBarrier(dismissible: false),
        hoverTarget,
      ],
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    // Start out of hoverTarget
    await gesture.moveTo(const Offset(100, 100));
    await tester.pumpWidget(subject);
    expect(hovered, isFalse);

    // Move into hoverTarget
    await gesture.moveTo(const Offset(5, 5));
    await tester.pumpWidget(subject);
    expect(hovered, isTrue, reason: 'because the hover is prevented by ModalBarrier');
    hovered = false;

    // Move out
    await gesture.moveTo(const Offset(100, 100));
    await tester.pumpWidget(subject);
    expect(hovered, isTrue, reason: 'because the hover is prevented by ModalBarrier');
    hovered = false;
  });

  testWidgets('ModalBarrier plays system alert sound when user tries to dismiss it', (WidgetTester tester) async {
    final List<String> playedSystemSounds = <String>[];
    try {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'SystemSound.play')
          playedSystemSounds.add(methodCall.arguments as String);
      });

      final Widget subject = Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          tapTarget,
          const ModalBarrier(dismissible: false),
        ],
      );

      await tester.pumpWidget(subject);
      await tester.tap(find.text('target'), warnIfMissed: false);
      await tester.pumpWidget(subject);
    } finally {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
    expect(playedSystemSounds, hasLength(1));
    expect(playedSystemSounds[0], SystemSoundType.alert.toString());
  });

  testWidgets('ModalBarrier pops the Navigator when dismissed by primary tap', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(),
      '/modal': (BuildContext context) => const SecondWidget(),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    // Press the barrier; it shouldn't dismiss yet
    final TestGesture gesture = await tester.press(
      find.byKey(const ValueKey<String>('barrier')),
    );
    await tester.pumpAndSettle(); // begin transition
    expect(find.byKey(const ValueKey<String>('barrier')), findsOneWidget);

    // Release the pointer; the barrier should be dismissed
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 1)); // end transition
    expect(
      find.byKey(const ValueKey<String>('barrier')),
      findsNothing,
      reason: 'The route should have been dismissed by tapping the barrier.',
    );
  });

  testWidgets('ModalBarrier pops the Navigator when dismissed by non-primary tap', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(),
      '/modal': (BuildContext context) => const SecondWidget(),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    // Press the barrier; it shouldn't dismiss yet
    final TestGesture gesture = await tester.press(
      find.byKey(const ValueKey<String>('barrier')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle(); // begin transition
    expect(find.byKey(const ValueKey<String>('barrier')), findsOneWidget);

    // Release the pointer; the barrier should be dismissed
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 1)); // end transition
    expect(
      find.byKey(const ValueKey<String>('barrier')),
      findsNothing,
      reason: 'The route should have been dismissed by tapping the barrier.',
    );
  });

  testWidgets('ModalBarrier may pop the Navigator when competing with other gestures', (WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(),
      '/modal': (BuildContext context) => const SecondWidgetWithCompetence(),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    // Tap on the barrier to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(
      find.byKey(const ValueKey<String>('barrier')),
      findsNothing,
      reason: 'The route should have been dismissed by tapping the barrier.',
    );
  });

  testWidgets('ModalBarrier does not pop the Navigator with a WillPopScope that returns false', (WidgetTester tester) async {
    bool willPopCalled = false;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(),
      '/modal': (BuildContext context) => Stack(
        children: <Widget>[
          const SecondWidget(),
          WillPopScope(
            child: const SizedBox(),
            onWillPop: () async {
              willPopCalled = true;
              return false;
            },
          ),
        ],
      ),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(willPopCalled, isFalse);

    // Tap on the barrier to attempt to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(
      find.byKey(const ValueKey<String>('barrier')),
      findsOneWidget,
      reason: 'The route should still be present if the pop is vetoed.',
    );

    expect(willPopCalled, isTrue);
  });

  testWidgets('ModalBarrier pops the Navigator with a WillPopScope that returns true', (WidgetTester tester) async {
    bool willPopCalled = false;
    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      '/': (BuildContext context) => const FirstWidget(),
      '/modal': (BuildContext context) => Stack(
        children: <Widget>[
          const SecondWidget(),
          WillPopScope(
            child: const SizedBox(),
            onWillPop: () async {
              willPopCalled = true;
              return true;
            },
          ),
        ],
      ),
    };

    await tester.pumpWidget(MaterialApp(routes: routes));

    // Initially the barrier is not visible
    expect(find.byKey(const ValueKey<String>('barrier')), findsNothing);

    // Tapping on X routes to the barrier
    await tester.tap(find.text('X'));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(willPopCalled, isFalse);

    // Tap on the barrier to attempt to dismiss it
    await tester.tap(find.byKey(const ValueKey<String>('barrier')));
    await tester.pump(); // begin transition
    await tester.pump(const Duration(seconds: 1)); // end transition

    expect(
      find.byKey(const ValueKey<String>('barrier')),
      findsNothing,
      reason: 'The route should not be present if the pop is permitted.',
    );

    expect(willPopCalled, isTrue);
  });

  testWidgets('Undismissible ModalBarrier hidden in semantic tree', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: false));

    final TestSemantics expectedSemantics = TestSemantics.root();
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('Dismissible ModalBarrier includes button in semantic tree on iOS', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ModalBarrier(
        dismissible: true,
        semanticsLabel: 'Dismiss',
      ),
    ));

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: TestSemantics.fullScreen,
          actions: <SemanticsAction>[SemanticsAction.tap, SemanticsAction.dismiss],
          label: 'Dismiss',
          textDirection: TextDirection.ltr,
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreId: true));

    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Dismissible ModalBarrier is hidden on Android (back button is used to dismiss)', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const ModalBarrier(dismissible: true));

    final TestSemantics expectedSemantics = TestSemantics.root();
    expect(semantics, hasSemantics(expectedSemantics));

    semantics.dispose();
  });

  testWidgets('ModalBarrier uses default mouse cursor', (WidgetTester tester) async {
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: const <Widget>[
        MouseRegion(cursor: SystemMouseCursors.click),
        ModalBarrier(dismissible: false),
      ],
    ));

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(ModalBarrier)));
    addTearDown(gesture.removePointer);

    await tester.pump();

    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });
}

class FirstWidget extends StatelessWidget {
  const FirstWidget({ Key? key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/modal');
      },
      child: const Text('X'),
    );
  }
}

class SecondWidget extends StatelessWidget {
  const SecondWidget({ Key? key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const ModalBarrier(
      key: ValueKey<String>('barrier'),
      dismissible: true,
    );
  }
}

class SecondWidgetWithCompetence extends StatelessWidget {
  const SecondWidgetWithCompetence({ Key? key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const ModalBarrier(
          key: ValueKey<String>('barrier'),
          dismissible: true,
        ),
        GestureDetector(
          onVerticalDragStart: (_) {},
          behavior: HitTestBehavior.translucent,
          child: Container(),
        ),
      ],
    );
  }
}
