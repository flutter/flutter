// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle, Color;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show DragStartBehavior, PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

class MockClipboard {
  Object _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments! as Object;
        break;
    }
  }
}

class PathBoundsMatcher extends Matcher {
  const PathBoundsMatcher({
    this.rectMatcher,
    this.topMatcher,
    this.leftMatcher,
    this.rightMatcher,
    this.bottomMatcher,
  }) : super();

  final Matcher? rectMatcher;
  final Matcher? topMatcher;
  final Matcher? leftMatcher;
  final Matcher? rightMatcher;
  final Matcher? bottomMatcher;

  @override
  bool matches(covariant Path item, Map<dynamic, dynamic> matchState) {
    final Rect bounds = item.getBounds();

    final List<Matcher?> matchers = <Matcher?>[
      rectMatcher,
      topMatcher,
      leftMatcher,
      rightMatcher,
      bottomMatcher
    ];
    final List<dynamic> values = <dynamic>[
      bounds,
      bounds.top,
      bounds.left,
      bounds.right,
      bounds.bottom
    ];
    final Map<Matcher, dynamic> failedMatcher = <Matcher, dynamic>{};

    for (int idx = 0; idx < matchers.length; idx++) {
      if (!(matchers[idx]?.matches(values[idx], matchState) != false)) {
        failedMatcher[matchers[idx]!] = values[idx];
      }
    }

    matchState['failedMatcher'] = failedMatcher;
    return failedMatcher.isEmpty;
  }

  @override
  Description describe(Description description) =>
      description.add('The actual Rect does not match');

  @override
  Description describeMismatch(
      covariant Path item,
      Description mismatchDescription,
      Map<dynamic, dynamic> matchState,
      bool verbose) {
    final Description description =
        super.describeMismatch(item, mismatchDescription, matchState, verbose);
    final Map<Matcher, dynamic> map =
        matchState['failedMatcher'] as Map<Matcher, dynamic>;
    final Iterable<String> descriptions = map.entries.map<String>(
        (MapEntry<Matcher, dynamic> entry) => entry.key
            .describeMismatch(
                entry.value, StringDescription(), matchState, verbose)
            .toString());

    // description is guaranteed to be non-null.
    return description
      ..add('mismatch Rect: ${item.getBounds()}')
          .addAll(': ', ', ', '. ', descriptions);
  }
}

class PathPointsMatcher extends Matcher {
  const PathPointsMatcher({
    this.includes = const <Offset>[],
    this.excludes = const <Offset>[],
  }) : super();

  final Iterable<Offset> includes;
  final Iterable<Offset> excludes;

  @override
  bool matches(covariant Path item, Map<dynamic, dynamic> matchState) {
    final Offset? notIncluded = includes.cast<Offset?>().firstWhere(
        (Offset? offset) => !item.contains(offset!),
        orElse: () => null);
    final Offset? notExcluded = excludes.cast<Offset?>().firstWhere(
        (Offset? offset) => item.contains(offset!),
        orElse: () => null);

    matchState['notIncluded'] = notIncluded;
    matchState['notExcluded'] = notExcluded;
    return (notIncluded ?? notExcluded) == null;
  }

  @override
  Description describe(Description description) => description.add(
      'must include these points $includes and must not include $excludes');

  @override
  Description describeMismatch(
      covariant Path item,
      Description mismatchDescription,
      Map<dynamic, dynamic> matchState,
      bool verbose) {
    final Offset? notIncluded = matchState['notIncluded'] as Offset?;
    final Offset? notExcluded = matchState['notExcluded'] as Offset?;
    final Description desc =
        super.describeMismatch(item, mismatchDescription, matchState, verbose);

    if ((notExcluded ?? notIncluded) != null) {
      desc.add('Within the bounds of the path ${item.getBounds()}: ');
    }

    if (notIncluded != null) {
      desc.add('$notIncluded is not included. ');
    }
    if (notExcluded != null) {
      desc.add('$notExcluded is not excluded. ');
    }
    return desc;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform
      .setMockMethodCallHandler(mockClipboard.handleMethodCall);

  // Returns the first RenderEditable.
  RenderEditable findRenderEditable(WidgetTester tester) {
    final RenderObject root = tester.renderObject(find.byType(EditableText));
    expect(root, isNotNull);

    RenderEditable? renderEditable;
    void recursiveFinder(RenderObject child) {
      if (child is RenderEditable) {
        renderEditable = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }

    root.visitChildren(recursiveFinder);
    expect(renderEditable, isNotNull);
    return renderEditable!;
  }

  List<TextSelectionPoint> globalize(
      Iterable<TextSelectionPoint> points, RenderBox box) {
    return points.map<TextSelectionPoint>((TextSelectionPoint point) {
      return TextSelectionPoint(
        box.localToGlobal(point.point),
        point.direction,
      );
    }).toList();
  }

  Offset textOffsetToBottomLeftPosition(WidgetTester tester, int offset) {
    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = globalize(
      renderEditable.getEndpointsForSelection(
        TextSelection.collapsed(offset: offset),
      ),
      renderEditable,
    );
    expect(endpoints.length, 1);
    return endpoints[0].point;
  }

  Offset textOffsetToPosition(WidgetTester tester, int offset) =>
      textOffsetToBottomLeftPosition(tester, offset) + const Offset(0, -2);

  setUp(() async {
    EditableText.debugDeterministicCursor = false;
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets(
    'default search field has a border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(),
          ),
        ),
      );

      final BoxDecoration decoration = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(CupertinoSearchTextField),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;

      expect(
        decoration.borderRadius,
        BorderRadius.circular(5),
      );
    },
  );

  testWidgets(
    'decoration can be overrriden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              decoration: null,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CupertinoSearchTextField),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'text entries are padded by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: TextEditingController(text: 'initial'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('initial')) -
            tester.getTopLeft(find.byType(CupertinoSearchTextField)),
        const Offset(3.8, 8.0),
      );
    },
  );

  testWidgets(
    'can control text content via controller',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
            ),
          ),
        ),
      );

      controller.text = 'controller text';
      await tester.pump();

      expect(find.text('controller text'), findsOneWidget);

      controller.text = '';
      await tester.pump();

      expect(find.text('controller text'), findsNothing);
    },
  );

  testWidgets('placeholder dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.dark),
        home: Center(
          child: CupertinoSearchTextField(
            placeholder: 'placeholder',
          ),
        ),
      ),
    );

    final Text placeholder = tester.widget(find.text('placeholder'));
    expect(placeholder.style!.color!.value,
        CupertinoColors.placeholderText.darkColor.value);
  });

  testWidgets(
    "placeholderStyle modifies placeholder's style and doesn't affect text's style",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              placeholder: 'placeholder',
              style: TextStyle(
                color: Color(0x00FFFFFF),
                fontWeight: FontWeight.w300,
              ),
              placeholderStyle: TextStyle(
                color: Color(0xAAFFFFFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

      final Text placeholder = tester.widget(find.text('placeholder'));
      expect(placeholder.style!.color, const Color(0xAAFFFFFF));
      expect(placeholder.style!.fontWeight, FontWeight.w600);

      await tester.enterText(find.byType(CupertinoSearchTextField), 'input');
      await tester.pump();

      final EditableText inputText = tester.widget(find.text('input'));
      expect(inputText.style.color, const Color(0x00FFFFFF));
      expect(inputText.style.fontWeight, FontWeight.w300);
    },
  );

  testWidgets(
    'prefix widget is in front of the text',
    (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              focusNode: focusNode,
              controller: TextEditingController(text: 'input'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.search)).dx +
            6.0, // 6px standard padding around input.
        tester.getTopLeft(find.byType(EditableText)).dx,
      );

      expect(
        tester.getTopLeft(find.byType(EditableText)).dx,
        tester.getTopLeft(find.byType(CupertinoSearchTextField)).dx +
            tester.getSize(find.byIcon(CupertinoIcons.search)).width +
            6.0,
      );
    },
  );

  testWidgets(
    'suffix widget is after the text',
    (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              focusNode: focusNode,
            ),
          ),
        ),
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx + 6.0,
        tester
            .getTopLeft(find.byIcon(CupertinoIcons.xmark_circle_fill))
            .dx, // 6px standard padding around input.
      );

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        tester.getTopRight(find.byType(CupertinoSearchTextField)).dx -
            tester
                .getSize(find.byIcon(CupertinoIcons.xmark_circle_fill))
                .width -
            6.0,
      );
    },
  );

  testWidgets(
    'suffix widget respects visibility mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              suffixMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

      await tester.enterText(
          find.byType(CupertinoSearchTextField), 'text input');
      await tester.pump();

      expect(find.text('text input'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
    },
  );

  testWidgets(
    'can customize padding',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(EditableText)),
        tester.getSize(find.byType(CupertinoSearchTextField)),
      );
    },
  );

  testWidgets(
    'clear button shows with right visibility mode',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 30.0 /* size of button */ - 6.0 /* padding */,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              suffixMode: OverlayVisibilityMode.editing,
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 6.0 /* padding */,
      );

      await tester.enterText(
          find.byType(CupertinoSearchTextField), 'text input');
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
      expect(find.text('text input'), findsOneWidget);
      expect(
        tester.getTopRight(find.byType(EditableText)).dx,
        800.0 - 30.0 - 6.0,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder does not affect clear button',
              suffixMode: OverlayVisibilityMode.notEditing,
            ),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);

      controller.text = '';
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
    },
  );

  testWidgets(
    'clear button removes text',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder',
            ),
          ),
        ),
      );

      controller.text = 'text entry';
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(controller.text, '');
      expect(find.text('placeholder'), findsOneWidget);
      expect(find.text('text entry'), findsNothing);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
    },
  );

  testWidgets(
    'tapping clear button also calls onChanged when text not empty',
    (WidgetTester tester) async {
      String value = 'text entry';
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: 'placeholder',
              onChanged: (String newValue) => value = newValue,
              suffixMode: OverlayVisibilityMode.always,
            ),
          ),
        ),
      );

      controller.text = value;
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.text('text entry'), findsNothing);
      expect(value, isEmpty);
    },
  );

  testWidgets(
    'RTL puts attachments to the right places',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: CupertinoSearchTextField(
                padding: EdgeInsets.all(20.0),
                suffixMode: OverlayVisibilityMode.always,
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byIcon(CupertinoIcons.search)).dx,
        800.0 - 24.0,
      );

      expect(
        tester.getTopRight(find.byIcon(CupertinoIcons.xmark_circle_fill)).dx,
        24.0,
      );
    },
  );
}
