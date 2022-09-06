// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

class MockOnPressedFunction {
  int called = 0;

  void handler() {
    called++;
  }
}

void main() {
  late MockOnPressedFunction mockOnPressedFunction;
  const ColorScheme colorScheme = ColorScheme.light();
  final ThemeData theme = ThemeData.from(colorScheme: colorScheme);
  setUp(() {
    mockOnPressedFunction = MockOnPressedFunction();
  });

  testWidgets('test icon is findable by key', (WidgetTester tester) async {
    const ValueKey<String> key = ValueKey<String>('icon-button');
    await tester.pumpWidget(
      wrap(
        useMaterial3: true,
        child: IconButton(
          key: key,
          onPressed: () {},
          icon: const Icon(Icons.link),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('test default icon buttons are sized up to 48', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(48.0, 48.0));

    await tester.tap(find.byType(IconButton));
    expect(mockOnPressedFunction.called, 1);
  });

  testWidgets('test small icons are sized up to 48dp', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconButton(
          iconSize: 10.0,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      )
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(48.0, 48.0));
  });

  testWidgets('test icons can be small when total size is >48dp', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconButton(
          iconSize: 10.0,
          padding: const EdgeInsets.all(30.0),
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
        ),
      )
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    expect(iconButton.size, const Size(70.0, 70.0));
  });

  testWidgets('when both iconSize and IconTheme.of(context).size are null, size falls back to 24.0', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconTheme(
          data: const IconThemeData(),
          child: IconButton(
            focusNode: FocusNode(debugLabel: 'Ink Focus'),
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
          ),
        )
      )
    );

    final RenderBox icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(24.0, 24.0));
  });

  testWidgets('when null, iconSize is overridden by closest IconTheme', (WidgetTester tester) async {
    RenderBox icon;
    final bool material3 = theme.useMaterial3;

    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconTheme(
          data: const IconThemeData(size: 10),
          child: IconButton(
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
          ),
        )
      )
    );

    icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(10.0, 10.0));

    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: Theme(
          data: ThemeData(
            useMaterial3: material3,
            iconTheme: const IconThemeData(size: 10),
          ),
          child: IconButton(
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
          ),
        )
      )
    );

    icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(10.0, 10.0));

    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: Theme(
          data: ThemeData(
            useMaterial3: material3,
            iconTheme: const IconThemeData(size: 20),
          ),
          child: IconTheme(
            data: const IconThemeData(size: 10),
            child: IconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.link),
            ),
          ),
        )
      ),
    );

    icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(10.0, 10.0));

    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconTheme(
          data: const IconThemeData(size: 20),
          child: Theme(
            data: ThemeData(
              useMaterial3: material3,
              iconTheme: const IconThemeData(size: 10),
            ),
            child: IconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.link),
            ),
          ),
        )
      ),
    );

    icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(10.0, 10.0));
  });

  testWidgets('when non-null, iconSize precedes IconTheme.of(context).size', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconTheme(
          data: const IconThemeData(size: 30.0),
          child: IconButton(
            iconSize: 10.0,
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
          ),
        )
      ),
    );

    final RenderBox icon = tester.renderObject(find.byType(Icon));
    expect(icon.size, const Size(10.0, 10.0));
  });

  testWidgets('Small icons with non-null constraints can be <48dp for M2, but =48dp for M3', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconButton(
          iconSize: 10.0,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
          constraints: const BoxConstraints(),
        )
      )
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    final RenderBox icon = tester.renderObject(find.byType(Icon));

    // By default IconButton has a padding of 8.0 on all sides, so both
    // width and height are 10.0 + 2 * 8.0 = 26.0
    // M3 IconButton is a subclass of ButtonStyleButton which has a minimum
    // Size(48.0, 48.0).
    expect(iconButton.size, material3 ? const Size(48.0, 48.0) : const Size(26.0, 26.0));
    expect(icon.size, const Size(10.0, 10.0));
  });

  testWidgets('Small icons with non-null constraints and custom padding can be <48dp', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: IconButton(
          iconSize: 10.0,
          padding: const EdgeInsets.all(3.0),
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link),
          constraints: const BoxConstraints(),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));
    final RenderBox icon = tester.renderObject(find.byType(Icon));

    // This IconButton has a padding of 3.0 on all sides, so both
    // width and height are 10.0 + 2 * 3.0 = 16.0
    // M3 IconButton is a subclass of ButtonStyleButton which has a minimum
    // Size(48.0, 48.0).
    expect(iconButton.size, material3 ? const Size(48.0, 48.0) : const Size(16.0, 16.0));
    expect(icon.size, const Size(10.0, 10.0));
  });

  testWidgets('Small icons comply with VisualDensity requirements', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    final ThemeData themeDataM2 = ThemeData(
      useMaterial3: material3,
      visualDensity: const VisualDensity(horizontal: 1, vertical: -1),
    );
    final ThemeData themeDataM3 = ThemeData(
      useMaterial3: material3,
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              visualDensity: const VisualDensity(horizontal: 1, vertical: -1)
          )
      ),
    );
    await tester.pumpWidget(
      wrap(
        useMaterial3: material3,
        child: Theme(
          data: material3 ? themeDataM3 : themeDataM2,
          child: IconButton(
            iconSize: 10.0,
            onPressed: mockOnPressedFunction.handler,
            icon: const Icon(Icons.link),
            constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
          ),
        ),
      ),
    );

    final RenderBox iconButton = tester.renderObject(find.byType(IconButton));

    // VisualDensity(horizontal: 1, vertical: -1) increases the icon's
    // width by 4 pixels and decreases its height by 4 pixels, giving
    // final width 32.0 + 4.0 = 36.0 and
    // final height 32.0 - 4.0 = 28.0
    expect(iconButton.size, material3 ? const Size(52.0, 44.0) : const Size(36.0, 28.0));
  });

  testWidgets('test default icon buttons are constrained', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.ac_unit),
          iconSize: 80.0,
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(80.0, 80.0));
  });

  testWidgets('test default icon buttons can be stretched if specified', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget> [
              IconButton(
                onPressed: mockOnPressedFunction.handler,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(48.0, 600.0));

    // Test for Material 3
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colorScheme, useMaterial3: true),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget> [
              IconButton(
                onPressed: mockOnPressedFunction.handler,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      )
    );

    final RenderBox boxM3 = tester.renderObject(find.byType(IconButton));
    expect(boxM3.size, const Size(48.0, 600.0));
  });

  testWidgets('test default padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: IconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.ac_unit),
          iconSize: 80.0,
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(IconButton));
    expect(box.size, const Size(96.0, 96.0));
  });

  testWidgets('test default alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: IconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.ac_unit),
          iconSize: 80.0,
        ),
      ),
    );

    final Align align = tester.firstWidget<Align>(find.ancestor(of: find.byIcon(Icons.ac_unit), matching: find.byType(Align)));
    expect(align.alignment, Alignment.center);
  });

  testWidgets('test tooltip', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: IconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);

    // Clear the widget tree.
    await tester.pumpWidget(Container(key: UniqueKey()));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: IconButton(
              onPressed: mockOnPressedFunction.handler,
              icon: const Icon(Icons.ac_unit),
              tooltip: 'Test tooltip',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.byTooltip('Test tooltip'), findsOneWidget);

    await tester.tap(find.byTooltip('Test tooltip'));
    expect(mockOnPressedFunction.called, 1);
  });

  testWidgets('IconButton AppBar size', (WidgetTester tester) async {
    final bool material3 = theme.useMaterial3;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: mockOnPressedFunction.handler,
                icon: const Icon(Icons.ac_unit),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox barBox = tester.renderObject(find.byType(AppBar));
    final RenderBox iconBox = tester.renderObject(find.byType(IconButton));
    expect(iconBox.size.height, material3 ? 48 : equals(barBox.size.height));
    expect(tester.getCenter(find.byType(IconButton)).dy, 28);
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in buttons_test.dart. If you change this one, you may want to also change that one.
  testWidgets('IconButton with explicit splashColor and highlightColor - M2', (WidgetTester tester) async {
    const Color directSplashColor = Color(0xFF00000F);
    const Color directHighlightColor = Color(0xFF0000F0);

    Widget buttonWidget = wrap(
      useMaterial3: false,
      child: IconButton(
        icon: const Icon(Icons.android),
        splashColor: directSplashColor,
        highlightColor: directHighlightColor,
        onPressed: () { /* enable the button */ },
      ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(useMaterial3: false),
        child: buttonWidget,
      ),
    );

    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: directSplashColor)
        ..circle(color: directHighlightColor),
    );

    const Color themeSplashColor1 = Color(0xFF000F00);
    const Color themeHighlightColor1 = Color(0xFF00FF00);

    buttonWidget = wrap(
      useMaterial3: false,
      child: IconButton(
        icon: const Icon(Icons.android),
        onPressed: () { /* enable the button */ },
      ),
    );

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor1,
          splashColor: themeSplashColor1,
          useMaterial3: false,
        ),
        child: buttonWidget,
      ),
    );

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: themeSplashColor1)
        ..circle(color: themeHighlightColor1),
    );

    const Color themeSplashColor2 = Color(0xFF002200);
    const Color themeHighlightColor2 = Color(0xFF001100);

    await tester.pumpWidget(
      Theme(
        data: ThemeData(
          highlightColor: themeHighlightColor2,
          splashColor: themeSplashColor2,
          useMaterial3: false,
        ),
        child: buttonWidget, // same widget, so does not get updated because of us
      ),
    );

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..circle(color: themeHighlightColor2),
    );

    await gesture.up();
  });

  testWidgets('IconButton with explicit splash radius - M2', (WidgetTester tester) async {
    const double splashRadius = 30.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Material(
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.android),
              splashRadius: splashRadius,
              onPressed: () { /* enable the button */ },
            ),
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // Start gesture.
    await tester.pump(const Duration(milliseconds: 1000)); // Wait for splash to be well under way.

    expect(
      Material.of(tester.element(find.byType(IconButton))),
      paints
        ..circle(radius: splashRadius),
    );

    await gesture.up();
  });

  testWidgets('IconButton Semantics (enabled) - M2', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        useMaterial3: false,
        child: IconButton(
          onPressed: mockOnPressedFunction.handler,
          icon: const Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: const Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          flags: <SemanticsFlag>[
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isButton,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
          ],
          label: 'link',
        ),
      ],
    ), ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('IconButton Semantics (disabled) - M2', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        useMaterial3: false,
        child: const IconButton(
          onPressed: null,
          icon: Icon(Icons.link, semanticLabel: 'link'),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            rect: const Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton,
            ],
            label: 'link',
          ),
        ],
    ), ignoreId: true, ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('IconButton loses focus when disabled.', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'IconButton');
    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: IconButton(
          focusNode: focusNode,
          autofocus: true,
          onPressed: () {},
          icon: const Icon(Icons.link),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: IconButton(
          focusNode: focusNode,
          autofocus: true,
          onPressed: null,
          icon: const Icon(Icons.link),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('IconButton keeps focus when disabled in directional navigation mode.', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'IconButton');
    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: IconButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () {},
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: IconButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: null,
            icon: const Icon(Icons.link),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("Disabled IconButton can't be traversed to when disabled.", (WidgetTester tester) async {
    final FocusNode focusNode1 = FocusNode(debugLabel: 'IconButton 1');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'IconButton 2');

    await tester.pumpWidget(
      wrap(
        useMaterial3: theme.useMaterial3,
        child: Column(
          children: <Widget>[
            IconButton(
              focusNode: focusNode1,
              autofocus: true,
              onPressed: () {},
              icon: const Icon(Icons.link),
            ),
            IconButton(
              focusNode: focusNode2,
              onPressed: null,
              icon: const Icon(Icons.link),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);

    expect(focusNode1.nextFocus(), isTrue);
    await tester.pump();

    expect(focusNode1.hasPrimaryFocus, isTrue);
    expect(focusNode2.hasPrimaryFocus, isFalse);
  });

  group('feedback', () {
    late FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback.dispose();
    });

    testWidgets('IconButton with disabled feedback', (WidgetTester tester) async {
      final Widget button = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconButton(
            onPressed: () {},
            enableFeedback: false,
            icon: const Icon(Icons.link),
          ),
        ),
      );

      await tester.pumpWidget(
        theme.useMaterial3
          ? MaterialApp(theme: theme, home: button)
          : Material(child: button)
      );
      await tester.tap(find.byType(IconButton), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('IconButton with enabled feedback', (WidgetTester tester) async {
      final Widget button = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.link),
          ),
        ),
      );

      await tester.pumpWidget(
        theme.useMaterial3
          ? MaterialApp(theme: theme, home: button)
          : Material(child: button),
      );
      await tester.tap(find.byType(IconButton), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('IconButton with enabled feedback by default', (WidgetTester tester) async {
      final Widget button = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.link),
          ),
        ),
      );

      await tester.pumpWidget(
        theme.useMaterial3
          ? MaterialApp(theme: theme, home: button)
          : Material(child: button),
      );
      await tester.tap(find.byType(IconButton), pointer: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });
  });

  testWidgets('IconButton responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    final bool material3 = theme.useMaterial3;
    Future<void> buildTest(VisualDensity visualDensity) async {
      return tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Material(
            child: Center(
              child: IconButton(
                visualDensity: visualDensity,
                key: key,
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(material3 ? const Size(64, 64) : const Size(60, 60)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    // IconButton is a subclass of ButtonStyleButton in Material 3, so the negative
    // visualDensity cannot be applied to horizontal padding.
    // The size of the Button with padding is (24 + 8 + 8, 24) -> (40, 24)
    // minSize of M3 IconButton is (48 - 12, 48 - 12) -> (36, 36)
    // So, the button size in Material 3 is (40, 36)
    expect(box.size, equals(material3 ? const Size(40, 36) : const Size(40, 40)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(material3 ? const Size(64, 36) : const Size(60, 40)));
  });

  testWidgets('IconButton.mouseCursor changes cursor on hover', (WidgetTester tester) async {
    // Test argument works
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: IconButton(
                onPressed: () {},
                mouseCursor: SystemMouseCursors.forbidden,
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(IconButton)));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);

    // Test default is click
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
  });

  testWidgets('disabled IconButton has basic mouse cursor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: IconButton(
                onPressed: null, // null value indicates IconButton is disabled
                icon: Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(IconButton)));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });

  testWidgets('IconButton.mouseCursor overrides implicit setting of mouse cursor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: IconButton(
                onPressed: null,
                mouseCursor: SystemMouseCursors.none,
                icon: Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(IconButton)));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: IconButton(
                onPressed: () {},
                mouseCursor: SystemMouseCursors.none,
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.none);
  });

  testWidgets('IconTheme opacity test', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.from(colorScheme: colorScheme, useMaterial3: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: IconButton(
              icon: const Icon(Icons.add),
              color: Colors.purple,
              onPressed: () {},
            )
          ),
        ),
      )
    );

    Color? iconColor() => _iconStyle(tester, Icons.add)?.color;
    expect(iconColor(), Colors.purple);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: IconTheme.merge(
              data: const IconThemeData(opacity: 0.5),
              child: IconButton(
                icon: const Icon(Icons.add),
                color: Colors.purple,
                onPressed: () {},
              ),
            )
          ),
        ),
      )
    );

    Color? iconColorWithOpacity() => _iconStyle(tester, Icons.add)?.color;
    expect(iconColorWithOpacity(), Colors.purple.withOpacity(0.5));
  });

  testWidgets('IconButton defaults - M3', (WidgetTester tester) async {
    final ThemeData themeM3 = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);

    // Enabled IconButton
    await tester.pumpWidget(
      MaterialApp(
        theme: themeM3,
        home: Center(
          child: IconButton(
            onPressed: () { },
            icon: const Icon(Icons.ac_unit),
          ),
        ),
      ),
    );

    final Finder buttonMaterial = find.descendant(
      of: find.byType(IconButton),
      matching: find.byType(Material),
    );

    Material material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.shape, const StadiumBorder());
    expect(material.textStyle, null);
    expect(material.type, MaterialType.button);

    final Align align = tester.firstWidget<Align>(find.ancestor(of: find.byIcon(Icons.ac_unit), matching: find.byType(Align)));
    expect(align.alignment, Alignment.center);
    expect(tester.getSize(find.byIcon(Icons.ac_unit)), const Size(24.0, 24.0));

    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start the splash animation
    await tester.pump(const Duration(milliseconds: 100)); // splash is underway

    await gesture.up();
    await tester.pumpAndSettle();
    material = tester.widget<Material>(buttonMaterial);
    // No change vs enabled and not pressed.
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.shape, const StadiumBorder());
    expect(material.textStyle, null);
    expect(material.type, MaterialType.button);

    // Disabled IconButton
    await tester.pumpWidget(
      MaterialApp(
        theme: themeM3,
        home: const Center(
          child: IconButton(
            onPressed: null,
            icon: Icon(Icons.ac_unit),
          ),
        ),
      ),
    );

    material = tester.widget<Material>(buttonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, null);
    expect(material.shape, const StadiumBorder());
    expect(material.textStyle, null);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default IconButton meets a11y contrast guidelines - M3', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: IconButton(
              onPressed: () { },
              focusNode: focusNode,
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Hovered.
    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await gesture.removePointer();
  },
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44115
  );

  testWidgets('IconButton uses stateful color for icon color in different states - M3', (WidgetTester tester) async {
    bool isSelected = false;
    final FocusNode focusNode = FocusNode();

    const Color pressedColor = Color(0x00000001);
    const Color hoverColor = Color(0x00000002);
    const Color focusedColor = Color(0x00000003);
    const Color defaultColor = Color(0x00000004);
    const Color selectedColor = Color(0x00000005);

    Color getIconColor(Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return pressedColor;
      }
      if (states.contains(MaterialState.hovered)) {
        return hoverColor;
      }
      if (states.contains(MaterialState.focused)) {
        return focusedColor;
      }
      if (states.contains(MaterialState.selected)) {
        return selectedColor;
      }
      return defaultColor;
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: Center(
                child: IconButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(getIconColor),
                  ),
                  isSelected: isSelected,
                  onPressed: () {
                    setState(() {
                      isSelected = !isSelected;
                    });
                  },
                  focusNode: focusNode,
                  icon: const Icon(Icons.ac_unit),
                ),
              ),
            );
          }
        ),
      ),
    );

    Color? iconColor() => _iconStyle(tester, Icons.ac_unit)?.color;

    // Default, not disabled.
    expect(iconColor(), equals(defaultColor));

    // Selected
    final Finder button = find.byType(IconButton);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(iconColor(), selectedColor);

    // Focused.
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(iconColor(), focusedColor);

    // Hovered.
    final Offset center = tester.getCenter(find.byType(IconButton));
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer();
    await gesture.moveTo(center);
    await tester.pumpAndSettle();
    expect(iconColor(), hoverColor);

    // Highlighted (pressed).
    await gesture.down(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    expect(iconColor(), pressedColor);
  });

  testWidgets('Does IconButton contribute semantics - M3', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Theme(
            data: ThemeData(useMaterial3: true),
            child: IconButton(
              style: const ButtonStyle(
                // Specifying minimumSize to mimic the original minimumSize for
                // RaisedButton so that the semantics tree's rect and transform
                // match the original version of this test.
                minimumSize: MaterialStatePropertyAll<Size>(Size(88, 36)),
              ),
              onPressed: () { },
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            rect: const Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
            transform: Matrix4.translationValues(356.0, 276.0, 0.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton,
              SemanticsFlag.isEnabled,
              SemanticsFlag.isFocusable,
            ],
          ),
        ],
      ),
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('IconButton size is configurable by ThemeData.materialTapTargetSize - M3', (WidgetTester tester) async {
    Widget buildFrame(MaterialTapTargetSize tapTargetSize) {
      return Theme(
        data: ThemeData(materialTapTargetSize: tapTargetSize, useMaterial3: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: IconButton(
              style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
              icon: const Icon(Icons.ac_unit),
              onPressed: () { },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.padded));
    expect(tester.getSize(find.byType(IconButton)), const Size(48.0, 48.0));

    await tester.pumpWidget(buildFrame(MaterialTapTargetSize.shrinkWrap));
    expect(tester.getSize(find.byType(IconButton)), const Size(40.0, 40.0));
  });

  testWidgets('Override IconButton default padding - M3', (WidgetTester tester) async {
    // Use [IconButton]'s padding property to override default value.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: IconButton(
              padding: const EdgeInsets.all(20),
              onPressed: () {},
              icon: const Icon(Icons.ac_unit),
            ),
          ),
        ),
      )
    );

    final Padding paddingWidget1 = tester.widget<Padding>(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget1.padding, const EdgeInsets.all(20));

    // Use [IconButton.style]'s padding property to override default value.
    await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: IconButton(
                style: IconButton.styleFrom(padding: const EdgeInsets.all(20)),
                onPressed: () {},
                icon: const Icon(Icons.ac_unit),
              ),
            ),
          ),
        )
    );

    final Padding paddingWidget2 = tester.widget<Padding>(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget2.padding, const EdgeInsets.all(20));

    // [IconButton.style]'s padding will override [IconButton]'s padding if both
    // values are not null.
    await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
          home: Scaffold(
            body: Center(
              child: IconButton(
                padding: const EdgeInsets.all(15),
                style: IconButton.styleFrom(padding: const EdgeInsets.all(22)),
                onPressed: () {},
                icon: const Icon(Icons.ac_unit),
              ),
            ),
          ),
        )
    );

    final Padding paddingWidget3 = tester.widget<Padding>(
      find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget3.padding, const EdgeInsets.all(22));
  });

  testWidgets('Default IconButton is not selectable - M3', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: IconButton(icon: const Icon(Icons.ac_unit), onPressed: (){},)
      )
    );

    final Finder button = find.byType(IconButton);
    IconButton buttonWidget() => tester.widget<IconButton>(button);

    Material buttonMaterial() {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        )
      );
    }

    Color? iconColor() => _iconStyle(tester, Icons.ac_unit)?.color;

    expect(buttonWidget().isSelected, null);
    expect(iconColor(), equals(const ColorScheme.light().onSurfaceVariant));
    expect(buttonMaterial().color, Colors.transparent);

    await tester.tap(button); // The non-toggle IconButton should not change appearance after clicking
    await tester.pumpAndSettle();

    expect(buttonWidget().isSelected, null);
    expect(iconColor(), equals(const ColorScheme.light().onSurfaceVariant));
    expect(buttonMaterial().color, Colors.transparent);
  });

  testWidgets('Icon button is selectable when isSelected is not null - M3', (WidgetTester tester) async {
    bool isSelected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IconButton(
              isSelected: isSelected,
              icon: const Icon(Icons.ac_unit),
              onPressed: (){
                setState(() {
                  isSelected = !isSelected;
                });
              },
            );
          }
        )
      )
    );

    final Finder button = find.byType(IconButton);
    IconButton buttonWidget() => tester.widget<IconButton>(button);
    Color? iconColor() => _iconStyle(tester, Icons.ac_unit)?.color;

    Material buttonMaterial() {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        )
      );
    }

    expect(buttonWidget().isSelected, false);
    expect(iconColor(), equals(const ColorScheme.light().onSurfaceVariant));
    expect(buttonMaterial().color, Colors.transparent);

    await tester.tap(button); // The toggle IconButton should change appearance after clicking
    await tester.pumpAndSettle();

    expect(buttonWidget().isSelected, true);
    expect(iconColor(), equals(const ColorScheme.light().primary));
    expect(buttonMaterial().color, Colors.transparent);

    await tester.tap(button); // The IconButton should be unselected if it's clicked again
    await tester.pumpAndSettle();

    expect(buttonWidget().isSelected, false);
    expect(iconColor(), equals(const ColorScheme.light().onSurfaceVariant));
    expect(buttonMaterial().color, Colors.transparent);
  });

  testWidgets('The IconButton is in selected status if isSelected is true by default - M3', (WidgetTester tester) async {
    bool isSelected = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IconButton(
              isSelected: isSelected,
              icon: const Icon(Icons.ac_unit),
              onPressed: (){
                setState(() {
                  isSelected = !isSelected;
                });
              },
            );
          }
        )
      )
    );

    final Finder button = find.byType(IconButton);
    IconButton buttonWidget() => tester.widget<IconButton>(button);
    Color? iconColor() => _iconStyle(tester, Icons.ac_unit)?.color;

    Material buttonMaterial() {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        )
      );
    }

    expect(buttonWidget().isSelected, true);
    expect(iconColor(), equals(const ColorScheme.light().primary));
    expect(buttonMaterial().color, Colors.transparent);

    await tester.tap(button); // The IconButton becomes unselected if it's clicked
    await tester.pumpAndSettle();

    expect(buttonWidget().isSelected, false);
    expect(iconColor(), equals(const ColorScheme.light().onSurfaceVariant));
    expect(buttonMaterial().color, Colors.transparent);
  });

  testWidgets("The selectedIcon is used if it's not null and the button is clicked" , (WidgetTester tester) async {
    bool isSelected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IconButton(
              isSelected: isSelected,
              selectedIcon: const Icon(Icons.account_box),
              icon: const Icon(Icons.account_box_outlined),
              onPressed: (){
                setState(() {
                  isSelected = !isSelected;
                });
              },
            );
          }
        )
      )
    );

    final Finder button = find.byType(IconButton);

    expect(find.byIcon(Icons.account_box_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_box), findsNothing);

    await tester.tap(button); // The icon becomes to selectedIcon
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.account_box), findsOneWidget);
    expect(find.byIcon(Icons.account_box_outlined), findsNothing);

    await tester.tap(button); // The icon becomes the original icon when it's clicked again
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.account_box_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_box), findsNothing);
  });

  testWidgets('The original icon is used for selected and unselected status when selectedIcon is null' , (WidgetTester tester) async {
    bool isSelected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IconButton(
              isSelected: isSelected,
              icon: const Icon(Icons.account_box),
              onPressed: (){
                setState(() {
                  isSelected = !isSelected;
                });
              },
            );
          }
        )
      )
    );

    final Finder button = find.byType(IconButton);
    IconButton buttonWidget() => tester.widget<IconButton>(button);

    expect(buttonWidget().isSelected, false);
    expect(buttonWidget().selectedIcon, null);
    expect(find.byIcon(Icons.account_box), findsOneWidget);

    await tester.tap(button); // The icon becomes the original icon when it's clicked again
    await tester.pumpAndSettle();

    expect(buttonWidget().isSelected, true);
    expect(buttonWidget().selectedIcon, null);
    expect(find.byIcon(Icons.account_box), findsOneWidget);
  });

  testWidgets('The selectedIcon is used for disabled button if isSelected is true - M3' , (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: const IconButton(
          isSelected: true,
          icon: Icon(Icons.account_box),
          selectedIcon: Icon(Icons.ac_unit),
          onPressed: null,
        )
      )
    );

    final Finder button = find.byType(IconButton);
    IconButton buttonWidget() => tester.widget<IconButton>(button);

    expect(buttonWidget().isSelected, true);
    expect(find.byIcon(Icons.account_box), findsNothing);
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
  });

  testWidgets('The visualDensity of M3 IconButton can be configured by IconButtonTheme, '
      'but cannot be configured by ThemeData - M3' , (WidgetTester tester) async {
    Future<void> buildTest({VisualDensity? iconButtonThemeVisualDensity, VisualDensity? themeVisualDensity}) async {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
              iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(visualDensity: iconButtonThemeVisualDensity)
              ),
              visualDensity: themeVisualDensity
          ),
          home: Material(
            child: Center(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(iconButtonThemeVisualDensity: VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(iconButtonThemeVisualDensity: VisualDensity.compact);
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(40, 40)));

    await buildTest(iconButtonThemeVisualDensity: const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(64, 64)));

    // ThemeData.visualDensity will be ignored because useMaterial3 is true
    await buildTest(themeVisualDensity: VisualDensity.standard);
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(themeVisualDensity: VisualDensity.compact);
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));

    await buildTest(themeVisualDensity: const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(48, 48)));
  });

  group('IconTheme tests in Material 3', () {
    testWidgets('IconTheme overrides default values in M3', (WidgetTester tester) async {
      // Theme's IconTheme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.light(),
            useMaterial3: true,
          ).copyWith(
            iconTheme: const IconThemeData(color: Colors.red, size: 37),
          ),
          home: IconButton(
            icon: const Icon(Icons.account_box),
            onPressed: () {},
          )
        )
      );

      Color? iconColor0() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor0(), Colors.red);
      expect(tester.getSize(find.byIcon(Icons.account_box)), equals(const Size(37, 37)),);

      // custom IconTheme outside of IconButton
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.light(),
            useMaterial3: true,
          ),
          home: IconTheme.merge(
            data: const IconThemeData(color: Colors.pink, size: 35),
            child: IconButton(
              icon: const Icon(Icons.account_box),
              onPressed: () {},
            ),
          )
        )
      );

      Color? iconColor1() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor1(), Colors.pink);
      expect(tester.getSize(find.byIcon(Icons.account_box)), equals(const Size(35, 35)),);
    });

    testWidgets('Theme IconButtonTheme overrides IconTheme in Material3', (WidgetTester tester) async {
      // When IconButtonTheme and IconTheme both exist in ThemeData, the IconButtonTheme can override IconTheme.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.light(),
            useMaterial3: true,
          ).copyWith(
            iconTheme: const IconThemeData(color: Colors.red, size: 25),
            iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: Colors.green, iconSize: 27),)
          ),
          home: IconButton(
            icon: const Icon(Icons.account_box),
            onPressed: () {},
          )
        )
      );

      Color? iconColor() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor(), Colors.green);
      expect(tester.getSize(find.byIcon(Icons.account_box)), equals(const Size(27, 27)),);
    });

    testWidgets('Button IconButtonTheme always overrides IconTheme in Material3', (WidgetTester tester) async {
      // When IconButtonTheme is closer to IconButton, IconButtonTheme overrides IconTheme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.light(),
            useMaterial3: true,
          ),
          home: IconTheme.merge(
            data: const IconThemeData(color: Colors.orange, size: 36),
            child: IconButtonTheme(
              data: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: Colors.blue, iconSize: 35)),
              child: IconButton(
                icon: const Icon(Icons.account_box),
                onPressed: () {},
              ),
            ),
          )
        )
      );

      Color? iconColor0() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor0(), Colors.blue);
      expect(tester.getSize(find.byIcon(Icons.account_box)), equals(const Size(35, 35)),);

      // When IconTheme is closer to IconButton, IconButtonTheme still overrides IconTheme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.light(),
            useMaterial3: true,
          ),
          home: IconTheme.merge(
            data: const IconThemeData(color: Colors.blue, size: 35),
            child: IconButtonTheme(
              data: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: Colors.orange, iconSize: 36)),
              child: IconButton(
                icon: const Icon(Icons.account_box),
                onPressed: () {},
              ),
            ),
          )
        )
      );

      Color? iconColor1() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor1(), Colors.orange);
      expect(tester.getSize(find.byIcon(Icons.account_box)), equals(const Size(36, 36)),);
    });

    testWidgets('White icon color defined by users shows correctly in Material3', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.from(
            colorScheme: const ColorScheme.dark(),
            useMaterial3: true,
          ).copyWith(
              iconTheme: const IconThemeData(color: Colors.white),
          ),
          home: IconButton(
            icon: const Icon(Icons.account_box),
            onPressed: () {},
          )
        )
      );

      Color? iconColor1() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor1(), Colors.white);
    });

    testWidgets('In light mode, icon color is M3 default color instead of IconTheme.of(context).color, '
        'if only setting color in IconTheme', (WidgetTester tester) async {
      final ColorScheme darkScheme = const ColorScheme.dark().copyWith(onSurfaceVariant: const Color(0xffe91e60));
      // Brightness.dark
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: darkScheme, useMaterial3: true,),
          home: Scaffold(
            body: IconTheme.merge(
              data: const IconThemeData(size: 26),
              child: IconButton(
                icon: const Icon(Icons.account_box),
                onPressed: () {},
              ),
            ),
          )
        )
      );

      Color? iconColor0() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor0(), darkScheme.onSurfaceVariant); // onSurfaceVariant
    });

    testWidgets('In dark mode, icon color is M3 default color instead of IconTheme.of(context).color, '
        'if only setting color in IconTheme', (WidgetTester tester) async {
      final ColorScheme lightScheme = const ColorScheme.light().copyWith(onSurfaceVariant: const Color(0xffe91e60));
      // Brightness.dark
      await tester.pumpWidget(
          MaterialApp(
              theme: ThemeData(colorScheme: lightScheme, useMaterial3: true,),
              home: Scaffold(
                body: IconTheme.merge(
                  data: const IconThemeData(size: 26),
                  child: IconButton(
                    icon: const Icon(Icons.account_box),
                    onPressed: () {},
                  ),
                ),
              )
          )
      );

      Color? iconColor0() => _iconStyle(tester, Icons.account_box)?.color;
      expect(iconColor0(), lightScheme.onSurfaceVariant); // onSurfaceVariant
    });

    testWidgets('black87 icon color defined by users shows correctly in Material3', (WidgetTester tester) async {

    });
  });
}

Widget wrap({required Widget child, required bool useMaterial3}) {
  return useMaterial3
      ? MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.light(), useMaterial3: true),
        home: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(child: child),
            )),
      )
      : FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Material(
              child: Center(child: child),
            ),
          ),
      );
}

TextStyle? _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}
