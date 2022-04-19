// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

MaterialApp _buildAppWithDialog(Widget dialog, { ThemeData? theme, double textScaleFactor = 1.0 }) {
  return MaterialApp(
    theme: theme,
    home: Material(
      child: Builder(
        builder: (BuildContext context) {
          return Center(
            child: ElevatedButton(
              child: const Text('X'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: dialog,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

Material _getMaterialFromDialog(WidgetTester tester) {
  return tester.widget<Material>(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)));
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.descendant(of: find.byType(Dialog), matching: find.text(text))).renderObject! as RenderParagraph;
}

// What was the AlertDialog's ButtonBar when many of these tests were written,
// is now a Padding widget with an OverflowBar child. The Padding widget's size
// and location  match the original ButtonBar's size and location.
Finder _findButtonBar() {
  return find.ancestor(of: find.byType(OverflowBar), matching: find.byType(Padding)).first;
}

const ShapeBorder _defaultM2DialogShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));
final ShapeBorder _defaultM3DialogShape =  RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0));

void main() {

  final ThemeData material3Theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  final ThemeData material2Theme = ThemeData(useMaterial3: false, brightness: Brightness.dark);

  testWidgets('Dialog is scrollable', (WidgetTester tester) async {
    bool didPressOk = false;
    final AlertDialog dialog = AlertDialog(
      content: Container(
        height: 5000.0,
        width: 300.0,
        color: Colors.green[500],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              didPressOk = true;
            },
            child: const Text('OK'),
        ),
      ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(didPressOk, false);
    await tester.tap(find.text('OK'));
    expect(didPressOk, true);
  });

  testWidgets('Dialog background color from AlertDialog', (WidgetTester tester) async {
    const Color customColor = Colors.pink;
    const AlertDialog dialog = AlertDialog(
      backgroundColor: customColor,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog, theme: ThemeData(brightness: Brightness.dark)));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, customColor);
  });

  testWidgets('Dialog Defaults', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      title: Text('Title'),
      content: Text('Y'),
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog, theme: material2Theme));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.color, Colors.grey[800]);
    expect(materialWidget.shape, _defaultM2DialogShape);
    expect(materialWidget.elevation, 24.0);

    final Offset bottomLeft = tester.getBottomLeft(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)),
    );
    expect(bottomLeft.dy, 360.0);

    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_buildAppWithDialog(dialog, theme: material3Theme));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material material3Widget = _getMaterialFromDialog(tester);
    expect(material3Widget.color, const Color(0xff424242));
    expect(material3Widget.shape, _defaultM3DialogShape);
    expect(material3Widget.elevation, 6.0);
  });

  testWidgets('Custom dialog elevation', (WidgetTester tester) async {
    const double customElevation = 12.0;
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      elevation: customElevation,
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.elevation, customElevation);
  });

  testWidgets('Custom Title Text Style', (WidgetTester tester) async {
    const String titleText = 'Title';
    const TextStyle titleTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      title: Text(titleText),
      titleTextStyle: titleTextStyle,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph title = _getTextRenderObjectFromDialog(tester, titleText);
    expect(title.text.style, titleTextStyle);
  });

  testWidgets('Custom Content Text Style', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    const AlertDialog dialog = AlertDialog(
      content: Text(contentText),
      contentTextStyle: contentTextStyle,
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(content.text.style, contentTextStyle);
  });

  testWidgets('AlertDialog custom clipBehavior', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[],
      clipBehavior: Clip.antiAlias,
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.clipBehavior, Clip.antiAlias);
  });

  testWidgets('SimpleDialog custom clipBehavior', (WidgetTester tester) async {
    const SimpleDialog dialog = SimpleDialog(
      clipBehavior: Clip.antiAlias,
      children: <Widget>[],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.clipBehavior, Clip.antiAlias);
  });

  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      shape: customBorder,
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Null dialog shape', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, _defaultM2DialogShape);
  });

  testWidgets('Rectangular dialog shape', (WidgetTester tester) async {
    const ShapeBorder customBorder = Border();
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      shape: customBorder,
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Material materialWidget = _getMaterialFromDialog(tester);
    expect(materialWidget.shape, customBorder);
  });

  testWidgets('Custom dialog alignment', (WidgetTester tester) async {
    const AlertDialog dialog = AlertDialog(
      actions: <Widget>[ ],
      alignment: Alignment.bottomLeft,
    );
    await tester.pumpWidget(_buildAppWithDialog(dialog));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Offset bottomLeft = tester.getBottomLeft(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)),
    );
    expect(bottomLeft.dx, 40.0);
    expect(bottomLeft.dy, 576.0);
  });

  testWidgets('Simple dialog control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    final Future<int?> result = showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 42);
              },
              child: const Text('First option'),
            ),
            const SimpleDialogOption(
              child: Text('Second option'),
            ),
          ],
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('First option'));

    expect(await result, equals(42));
  });

  testWidgets('Can show dialog using navigator global key', (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Material(
          child: Center(
            child: Text('Go'),
          ),
        ),
      ),
    );

    final Future<int?> result = showDialog<int>(
      context: navigator.currentContext!,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 42);
              },
              child: const Text('First option'),
            ),
            const SimpleDialogOption(
              child: Text('Second option'),
            ),
          ],
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('First option'));

    expect(await result, equals(42));
  });

  testWidgets('Custom padding on SimpleDialogOption', (WidgetTester tester) async {
    const EdgeInsets customPadding = EdgeInsets.fromLTRB(4, 10, 8, 6);
    final SimpleDialog dialog = SimpleDialog(
      title: const Text('Title'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () {},
          padding: customPadding,
          child: const Text('First option'),
        ),
      ],
    );

    await tester.pumpWidget(_buildAppWithDialog(dialog));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Rect dialogRect = tester.getRect(find.byType(SimpleDialogOption));
    final Rect textRect = tester.getRect(find.text('First option'));

    expect(textRect.left, dialogRect.left + customPadding.left);
    expect(textRect.top, dialogRect.top + customPadding.top);
    expect(textRect.right, dialogRect.right - customPadding.right);
    expect(textRect.bottom, dialogRect.bottom - customPadding.bottom);
  });

  testWidgets('Barrier dismissible', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog1'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsNothing);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog2'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

    // Tap on the barrier, which shouldn't do anything this time.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

  });

  testWidgets('Barrier color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: Text('Test')),
      ),
    );
    final BuildContext context = tester.element(find.text('Test'));

    // Test default barrier color
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const Text('Dialog');
      },
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color, Colors.black54);

    // Dismiss it and test a custom barrier color
    await tester.tapAt(const Offset(10.0, 10.0));
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const Text('Dialog');
      },
      barrierColor: Colors.pink,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color, Colors.pink);
  });

  testWidgets('Dialog hides underlying semantics tree', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const String buttonText = 'A button covered by dialog overlay';
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text(buttonText),
            ),
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: buttonText));

    final BuildContext context = tester.element(find.text(buttonText));

    const String alertText = 'A button in an overlay alert';
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(title: Text(alertText));
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(label: alertText));
    expect(semantics, isNot(includesNodeWith(label: buttonText)));

    semantics.dispose();
  });

  testWidgets('AlertDialog.actionsPadding defaults', (WidgetTester tester) async {
    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {},
          child: const Text('button'),
        ),
      ],
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // The [AlertDialog] is the entire screen, since it also contains the scrim.
    // The first [Material] child of [AlertDialog] is the actual dialog
    // itself.
    final Size dialogSize = tester.getSize(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Material),
      ).first,
    );
    final Size actionsSize = tester.getSize(_findButtonBar());

    expect(actionsSize.width, dialogSize.width);
  });

  testWidgets('AlertDialog.actionsPadding surrounds actions with padding', (WidgetTester tester) async {
    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {},
          child: const Text('button'),
        ),
      ],
      // The OverflowBar is inset by the buttonPadding/2 + actionsPadding
      buttonPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.all(30.0), // custom padding value
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // The [AlertDialog] is the entire screen, since it also contains the scrim.
    // The first [Material] child of [AlertDialog] is the actual dialog
    // itself.
    final Size dialogSize = tester.getSize(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Material),
      ).first,
    );
    final Size actionsSize = tester.getSize(find.byType(OverflowBar));

    expect(actionsSize.width, dialogSize.width - (30.0 * 2));
  });

  testWidgets('AlertDialog.buttonPadding defaults', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('button 2'),
        ),
      ],
    );

    await tester.pumpWidget(_buildAppWithDialog(dialog, theme: material2Theme));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // Padding between both buttons
    expect(
      tester.getBottomLeft(find.byKey(key2)).dx,
      tester.getBottomRight(find.byKey(key1)).dx + 8.0,
    );

    // Padding between button and edges of the button bar
    // First button
    expect(
      tester.getTopRight(find.byKey(key1)).dy,
      tester.getTopRight(_findButtonBar()).dy + 8.0,
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key1)).dy,
      tester.getBottomRight(_findButtonBar()).dy - 8.0,
    ); // bottom

    // Second button
    expect(
      tester.getTopRight(find.byKey(key2)).dy,
      tester.getTopRight(_findButtonBar()).dy + 8.0,
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key2)).dy,
      tester.getBottomRight(_findButtonBar()).dy - 8.0,
    ); // bottom
    expect(
      tester.getBottomRight(find.byKey(key2)).dx,
      tester.getBottomRight(_findButtonBar()).dx - 8.0,
    ); // right

    // Dismiss it and test materail 3 dialog
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_buildAppWithDialog(dialog, theme: material3Theme));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // Padding between both buttons
    expect(
      tester.getBottomLeft(find.byKey(key2)).dx,
      tester.getBottomRight(find.byKey(key1)).dx + 8.0,
    );

    // Padding between button and edges of the button bar
    // First button
    expect(
      tester.getTopRight(find.byKey(key1)).dy,
      tester.getTopRight(_findButtonBar()).dy + 8.0,
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key1)).dy,
      tester.getBottomRight(_findButtonBar()).dy - 20.0,
    ); // bottom

    // // Second button
    expect(
      tester.getTopRight(find.byKey(key2)).dy,
      tester.getTopRight(_findButtonBar()).dy + 8.0,
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key2)).dy,
      tester.getBottomRight(_findButtonBar()).dy - 20.0,
    ); // bottom
    expect(
      tester.getBottomRight(find.byKey(key2)).dx,
      tester.getBottomRight(_findButtonBar()).dx - 26.0,
    ); // right
  });

  testWidgets('AlertDialog.buttonPadding custom values', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('button 2'),
        ),
      ],
      buttonPadding: const EdgeInsets.only(
        left: 10.0,
        right: 20.0,
      ),
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    // Padding between both buttons
    expect(
      tester.getBottomLeft(find.byKey(key2)).dx,
      tester.getBottomRight(find.byKey(key1)).dx + ((10.0 + 20.0) / 2),
    );

    // Padding between button and edges of the button bar
    // First button
    expect(
      tester.getTopRight(find.byKey(key1)).dy,
      tester.getTopRight(_findButtonBar()).dy + ((10.0 + 20.0) / 2),
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key1)).dy,
      tester.getBottomRight(_findButtonBar()).dy - ((10.0 + 20.0) / 2),
    ); // bottom

    // Second button
    expect(
      tester.getTopRight(find.byKey(key2)).dy,
      tester.getTopRight(_findButtonBar()).dy + ((10.0 + 20.0) / 2),
    ); // top
    expect(
      tester.getBottomRight(find.byKey(key2)).dy,
      tester.getBottomRight(_findButtonBar()).dy - ((10.0 + 20.0) / 2),
    ); // bottom
    expect(
      tester.getBottomRight(find.byKey(key2)).dx,
      tester.getBottomRight(_findButtonBar()).dx - ((10.0 + 20.0) / 2),
    ); // right
  });

  group('Dialog children padding is correct', () {
    final List<double> textScaleFactors = <double>[0.5, 1.0, 1.5, 2.0, 3.0];
    final Map<double, double> paddingScaleFactors = <double, double>{
      0.5: 1.0,
      1.0: 1.0,
      1.5: 2.0 / 3.0,
      2.0: 1.0 / 3.0,
      3.0: 1.0 / 3.0,
    };

    final GlobalKey titleKey = GlobalKey();
    final GlobalKey contentKey = GlobalKey();
    final GlobalKey childrenKey = GlobalKey();

    final Finder dialogFinder = find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first;
    final Finder titleFinder = find.byKey(titleKey);
    final Finder contentFinder = find.byKey(contentKey);
    final Finder actionsFinder = _findButtonBar();
    final Finder childrenFinder = find.byKey(childrenKey);

    Future<void> openDialog(WidgetTester tester, Widget dialog, double textScaleFactor) async {
      await tester.pumpWidget(
        _buildAppWithDialog(dialog, textScaleFactor: textScaleFactor),
      );

      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
    }

    void expectLeftEdgePadding(
      WidgetTester tester, {
      required Finder finder,
      required double textScaleFactor,
      required double unscaledValue,
    }) {
      expect(
        tester.getTopLeft(dialogFinder).dx,
        moreOrLessEquals(tester.getTopLeft(finder).dx - unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
      expect(
        tester.getBottomLeft(dialogFinder).dx,
        moreOrLessEquals(tester.getBottomLeft(finder).dx - unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
    }

    void expectRightEdgePadding(
      WidgetTester tester, {
      required Finder finder,
      required double textScaleFactor,
      required double unscaledValue,
    }) {
      expect(
        tester.getTopRight(dialogFinder).dx,
        moreOrLessEquals(tester.getTopRight(finder).dx + unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
      expect(
        tester.getBottomRight(dialogFinder).dx,
        moreOrLessEquals(tester.getBottomRight(finder).dx + unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
    }

    void expectTopEdgePadding(
      WidgetTester tester, {
      required Finder finder,
      required double textScaleFactor,
      required double unscaledValue,
    }) {
      expect(
        tester.getTopLeft(dialogFinder).dy,
        moreOrLessEquals(tester.getTopLeft(finder).dy - unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
      expect(
        tester.getTopRight(dialogFinder).dy,
        moreOrLessEquals(tester.getTopRight(finder).dy - unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
    }

    void expectBottomEdgePadding(
      WidgetTester tester, {
      required Finder finder,
      required double textScaleFactor,
      required double unscaledValue,
    }) {
      expect(
        tester.getBottomLeft(dialogFinder).dy,
        moreOrLessEquals(tester.getBottomRight(finder).dy + unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
      expect(
        tester.getBottomRight(dialogFinder).dy,
        moreOrLessEquals(tester.getBottomRight(finder).dy + unscaledValue * paddingScaleFactors[textScaleFactor]!),
      );
    }

    void expectVerticalInnerPadding(
    WidgetTester tester, {
      required Finder top,
      required Finder bottom,
      required double value,
    }) {
      expect(
        tester.getBottomLeft(top).dy,
        tester.getTopLeft(bottom).dy - value,
      );
      expect(
        tester.getBottomRight(top).dy,
        tester.getTopRight(bottom).dy - value,
      );
    }

    final Widget title = Text(
      'title',
      key: titleKey,
    );
    final Widget content = Text(
      'content',
      key: contentKey,
    );
    final List<Widget> actions = <Widget>[
      ElevatedButton(
        onPressed: () {},
        child: const Text('button'),
      ),
    ];
    final List<Widget> children = <Widget>[
      SimpleDialogOption(
        key: childrenKey,
        child: const Text('child'),
        onPressed: () { },
      ),
    ];

    for (final double textScaleFactor in textScaleFactors) {
      testWidgets('AlertDialog padding is correct when only title and actions are specified [textScaleFactor]=$textScaleFactor}', (WidgetTester tester) async {
        final AlertDialog dialog = AlertDialog(
          title: title,
          actions: actions,
        );

        await openDialog(tester, dialog, textScaleFactor);

        expectTopEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectRightEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectVerticalInnerPadding(
          tester,
          top: titleFinder,
          bottom: actionsFinder,
          value: 20.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectRightEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectBottomEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
      });

      testWidgets('AlertDialog padding is correct when only content and actions are specified [textScaleFactor]=$textScaleFactor}', (WidgetTester tester) async {
        final AlertDialog dialog = AlertDialog(
          content: content,
          actions: actions,
        );

        await openDialog(tester, dialog, textScaleFactor);

        expectTopEdgePadding(
          tester,
          finder: contentFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 20.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: contentFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectRightEdgePadding(
          tester,
          finder: contentFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectVerticalInnerPadding(
          tester,
          top: contentFinder,
          bottom: actionsFinder,
          value: 24.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectRightEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectBottomEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
      });

      testWidgets('AlertDialog padding is correct when title, content, and actions are specified [textScaleFactor]=$textScaleFactor}', (WidgetTester tester) async {
        final AlertDialog dialog = AlertDialog(
          title: title,
          content: content,
          actions: actions,
        );

        await openDialog(tester, dialog, textScaleFactor);

        expectTopEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectRightEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectVerticalInnerPadding(
          tester,
          top: titleFinder,
          bottom: contentFinder,
          value: 20.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: contentFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectRightEdgePadding(
          tester,
          finder: contentFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectVerticalInnerPadding(
          tester,
          top: contentFinder,
          bottom: actionsFinder,
          value: 24.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectRightEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectBottomEdgePadding(
          tester,
          finder: actionsFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
      });

      testWidgets('SimpleDialog padding is correct when only children are specified [textScaleFactor]=$textScaleFactor}', (WidgetTester tester) async {
        final SimpleDialog dialog = SimpleDialog(
          children: children,
        );

        await openDialog(tester, dialog, textScaleFactor);

        expectTopEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 12.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectRightEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectBottomEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 16.0,
        );
      });

      testWidgets('SimpleDialog padding is correct when title and children are specified [textScaleFactor]=$textScaleFactor}', (WidgetTester tester) async {
        final SimpleDialog dialog = SimpleDialog(
          title: title,
          children: children,
        );

        await openDialog(tester, dialog, textScaleFactor);

        expectTopEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectRightEdgePadding(
          tester,
          finder: titleFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 24.0,
        );
        expectVerticalInnerPadding(
          tester,
          top: titleFinder,
          bottom: childrenFinder,
          value: 12.0,
        );
        expectLeftEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectRightEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 0.0,
        );
        expectBottomEdgePadding(
          tester,
          finder: childrenFinder,
          textScaleFactor: textScaleFactor,
          unscaledValue: 16.0,
        );
      });
    }
  });

  testWidgets('Dialogs can set the vertical direction of overflowing actions', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 2'),
        ),
      ],
      actionsOverflowDirection: VerticalDirection.up,
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Rect buttonOneRect = tester.getRect(find.byKey(key1));
    final Rect buttonTwoRect = tester.getRect(find.byKey(key2));
    // Second [ElevatedButton] should appear above the first.
    expect(buttonTwoRect.bottom, lessThanOrEqualTo(buttonOneRect.top));
  });

  testWidgets('Dialogs have no spacing by default for overflowing actions', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 2'),
        ),
      ],
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Rect buttonOneRect = tester.getRect(find.byKey(key1));
    final Rect buttonTwoRect = tester.getRect(find.byKey(key2));
    expect(buttonOneRect.bottom, buttonTwoRect.top);
  });

  testWidgets('Dialogs can set the button spacing of overflowing actions', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('Looooooooooooooong button 2'),
        ),
      ],
      actionsOverflowButtonSpacing: 10.0,
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Rect buttonOneRect = tester.getRect(find.byKey(key1));
    final Rect buttonTwoRect = tester.getRect(find.byKey(key2));
    expect(buttonOneRect.bottom, buttonTwoRect.top - 10.0);
  });

  testWidgets('Dialogs can set the alignment of the OverflowBar', (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();

    final AlertDialog dialog = AlertDialog(
      title: const Text('title'),
      content: const Text('content'),
      actions: <Widget>[
        ElevatedButton(
          key: key1,
          onPressed: () {},
          child: const Text('Loooooooooog button 1'),
        ),
        ElevatedButton(
          key: key2,
          onPressed: () {},
          child: const Text('Loooooooooooooonger button 2'),
        ),
      ],
      actionsOverflowAlignment: OverflowBarAlignment.center,
    );

    await tester.pumpWidget(
      _buildAppWithDialog(dialog),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    final Rect buttonOneRect = tester.getRect(find.byKey(key1));
    final Rect buttonTwoRect = tester.getRect(find.byKey(key2));
    expect(buttonOneRect.center.dx, buttonTwoRect.center.dx);
  });

  testWidgets('Dialogs removes MediaQuery padding and view insets', (WidgetTester tester) async {
    late BuildContext outerContext;
    late BuildContext routeContext;
    late BuildContext dialogContext;

    await tester.pumpWidget(Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
          viewInsets: EdgeInsets.only(left: 25.0, bottom: 75.0),
        ),
        child: Navigator(
          onGenerateRoute: (_) {
            return PageRouteBuilder<void>(
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                outerContext = context;
                return Container();
              },
            );
          },
        ),
      ),
    ));

    showDialog<void>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        routeContext = context;
        return Dialog(
          child: Builder(
            builder: (BuildContext context) {
              dialogContext = context;
              return const Placeholder();
            },
          ),
        );
      },
    );

    await tester.pump();

    expect(MediaQuery.of(outerContext).padding, const EdgeInsets.all(50.0));
    expect(MediaQuery.of(routeContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(dialogContext).padding, EdgeInsets.zero);
    expect(MediaQuery.of(outerContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(routeContext).viewInsets, const EdgeInsets.only(left: 25.0, bottom: 75.0));
    expect(MediaQuery.of(dialogContext).viewInsets, EdgeInsets.zero);
  });

  testWidgets('Dialog widget insets by viewInsets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          viewInsets: EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0),
        ),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(Placeholder)),
      const Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Dialog(
          child: Placeholder(),
        ),
      ),
    );
    expect( // no change because this is an animation
      tester.getRect(find.byType(Placeholder)),
      const Rect.fromLTRB(10.0 + 40.0, 20.0 + 24.0, 800.0 - (40.0 + 30.0), 600.0 - (24.0 + 40.0)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect( // animation finished
      tester.getRect(find.byType(Placeholder)),
      const Rect.fromLTRB(40.0, 24.0, 800.0 - 40.0, 600.0 - 24.0),
    );
  });

  testWidgets('Dialog insetPadding added to outside of dialog', (WidgetTester tester) async {
    // The default testing screen (800, 600)
    const Rect screenRect = Rect.fromLTRB(0.0, 0.0, 800.0, 600.0);

    // Test with no padding
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Dialog(
          insetPadding: null,
          child: Placeholder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Placeholder)), screenRect);

    // Test with an insetPadding
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Dialog(
          insetPadding: EdgeInsets.fromLTRB(10.0, 20.0, 30.0, 40.0),
          child: Placeholder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(Placeholder)),
      Rect.fromLTRB(
        screenRect.left + 10.0,
        screenRect.top + 20.0,
        screenRect.right - 30.0,
        screenRect.bottom - 40.0,
      ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/78229.
  testWidgets('AlertDialog has correct semantics for content in iOS', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const AlertDialog(
          title: Text('title'),
          content: Text('content'),
          actions: <Widget>[ TextButton(onPressed: null, child: Text('action')) ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          textDirection: TextDirection.ltr,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              children: <TestSemantics>[
                TestSemantics(
                  id: 3,
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 4,
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 5,
                          label: 'title',
                          textDirection: TextDirection.ltr,
                        ),
                        // The content semantics does not merge into the semantics
                        // node 4.
                        TestSemantics(
                          id: 6,
                          label: 'content',
                          textDirection: TextDirection.ltr,
                        ),
                        TestSemantics(
                          id: 7,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isButton,
                            SemanticsFlag.hasEnabledState,
                          ],
                          label: 'action',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('AlertDialog widget always contains alert route semantics for android', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(semantics, isNot(includesNodeWith(
      label: 'Title',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    )));
    expect(semantics, isNot(includesNodeWith(
      label: 'Alert',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute, SemanticsFlag.scopesRoute],
    )));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    // It does not use 'Title' as route semantics
    expect(semantics, isNot(includesNodeWith(
      label: 'Title',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    )));
    expect(semantics, includesNodeWith(
      label: 'Alert',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute, SemanticsFlag.scopesRoute],
    ));

    semantics.dispose();
  });

  testWidgets('SimpleDialog does not introduce additional node', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const SimpleDialog(
                          title: Text('Title'),
                          semanticLabel: 'label',
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    // A scope route is not focusable in accessibility service.
    expect(semantics, includesNodeWith(
      label: 'label',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute, SemanticsFlag.scopesRoute],
    ));

    semantics.dispose();
  });

  // Regression test for https://github.com/flutter/flutter/issues/78229.
  testWidgets('SimpleDialog has correct semantics for title in iOS', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: const SimpleDialog(
          title: Text('title'),
          children: <Widget>[
            Text('content'),
            TextButton(onPressed: null, child: Text('action')),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          textDirection: TextDirection.ltr,
          children: <TestSemantics>[
            TestSemantics(
              id: 2,
              children: <TestSemantics>[
                TestSemantics(
                  id: 3,
                  flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 4,
                      children: <TestSemantics>[
                        // Title semantics does not merge into the semantics
                        // node 4.
                        TestSemantics(
                          id: 5,
                          label: 'title',
                          textDirection: TextDirection.ltr,
                        ),
                        TestSemantics(
                          id: 6,
                          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                          children: <TestSemantics>[
                            TestSemantics(
                              id: 7,
                              label: 'content',
                              textDirection: TextDirection.ltr,
                            ),
                            TestSemantics(
                              id: 8,
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isButton,
                                SemanticsFlag.hasEnabledState,
                              ],
                              label: 'action',
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreId: true, ignoreRect: true));

    semantics.dispose();
  });

  testWidgets('Dismissible.confirmDismiss defers to an AlertDialog', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final List<int> dismissedItems = <int>[];

    // Dismiss is confirmed IFF confirmDismiss() returns true.
    Future<bool?> confirmDismiss (DismissDirection dismissDirection) async {
      return showDialog<bool>(
        context: scaffoldKey.currentContext!,
        barrierDismissible: true, // showDialog() returns null if tapped outside the dialog
        builder: (BuildContext context) {
          return AlertDialog(
            actions: <Widget>[
              TextButton(
                child: const Text('TRUE'),
                onPressed: () {
                  Navigator.pop(context, true); // showDialog() returns true
                },
              ),
              TextButton(
                child: const Text('FALSE'),
                onPressed: () {
                  Navigator.pop(context, false); // showDialog() returns false
                },
              ),
            ],
          );
        },
      );
    }

    Widget buildDismissibleItem(int item, StateSetter setState) {
      return Dismissible(
        key: ValueKey<int>(item),
        confirmDismiss: confirmDismiss,
        onDismissed: (DismissDirection direction) {
          setState(() {
            expect(dismissedItems.contains(item), isFalse);
            dismissedItems.add(item);
          });
        },
        child: SizedBox(
          height: 100.0,
          child: Text(item.toString()),
        ),
      );
    }

    Widget buildFrame() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              key: scaffoldKey,
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  itemExtent: 100.0,
                  children: <int>[0, 1, 2, 3, 4]
                    .where((int i) => !dismissedItems.contains(i))
                    .map<Widget>((int item) => buildDismissibleItem(item, setState)).toList(),
                ),
              ),
            );
          },
        ),
      );
    }

    Future<void> dismissItem(WidgetTester tester, int item) async {
      await tester.fling(find.text(item.toString()), const Offset(300.0, 0.0), 1000.0); // fling to the right
      await tester.pump(); // start the slide
      await tester.pump(const Duration(seconds: 1)); // finish the slide and start shrinking...
      await tester.pump(); // first frame of shrinking animation
      await tester.pump(const Duration(seconds: 1)); // finish the shrinking and call the callback...
      await tester.pump(); // rebuild after the callback removes the entry
    }

    // Dismiss item 0 is confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, isEmpty);
    await dismissItem(tester, 0); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);

    // Dismiss item 1 is not confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('FALSE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    // Dismiss item 1 is not confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    expect(find.text('FALSE'), findsOneWidget);
    expect(find.text('TRUE'), findsOneWidget);
    await tester.tapAt(Offset.zero); // Tap outside of the AlertDialog
    await tester.pumpAndSettle();
    expect(dismissedItems, <int>[0]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);

    // Dismiss item 1 is confirmed via the AlertDialog
    await tester.pumpWidget(buildFrame());
    expect(dismissedItems, <int>[0]);
    await dismissItem(tester, 1); // Causes the AlertDialog to appear per confirmDismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUE')); // AlertDialog action
    await tester.pumpAndSettle();
    expect(find.text('TRUE'), findsNothing); // Dialog was dismissed
    expect(find.text('FALSE'), findsNothing);
    expect(dismissedItems, <int>[0, 1]);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/28505.
  testWidgets('showDialog only gets Theme from context on the first call', (WidgetTester tester) async {
    Widget buildFrame(Key builderKey) {
      return MaterialApp(
        home: Center(
          child: Builder(
            key: builderKey,
            builder: (BuildContext outerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: outerContext,
                    builder: (BuildContext innerContext) {
                      return const AlertDialog(title: Text('Title'));
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(UniqueKey()));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Force the Builder to be recreated (new key) which causes outerContext to
    // be deactivated. If showDialog()'s implementation were to refer to
    // outerContext again, it would crash.
    await tester.pumpWidget(buildFrame(UniqueKey()));
    await tester.pump();
  });

  testWidgets('showDialog safe area', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            // Set up the safe area to be 20 pixels in from each side
            data: const MediaQueryData(padding: EdgeInsets.all(20.0)),
            child: child!,
          );
        },
        home: const Center(child: Text('Test')),
      ),
    );
    final BuildContext context = tester.element(find.text('Test'));

    // By default it should honor the safe area
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const Placeholder();
      },
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));

    // Dismiss it and test with useSafeArea off
    await tester.tapAt(const Offset(10.0, 10.0));
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const Placeholder();
      },
      useSafeArea: false,
    );
    await tester.pumpAndSettle();
    // Should take up the whole screen
    expect(tester.getTopLeft(find.byType(Placeholder)), Offset.zero);
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(800.0, 600.0));
  });

  testWidgets('showDialog uses root navigator by default', (WidgetTester tester) async {
    final DialogObserver rootObserver = DialogObserver();
    final DialogObserver nestedObserver = DialogObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext innerContext) {
                      return const AlertDialog(title: Text('Title'));
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.dialogCount, 1);
    expect(nestedObserver.dialogCount, 0);
  });

  testWidgets('showDialog uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final DialogObserver rootObserver = DialogObserver();
    final DialogObserver nestedObserver = DialogObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    useRootNavigator: false,
                    builder: (BuildContext innerContext) {
                      return const AlertDialog(title: Text('Title'));
                    },
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(ElevatedButton));

    expect(rootObserver.dialogCount, 0);
    expect(nestedObserver.dialogCount, 1);
  });

  group('showDialog avoids overlapping display features', () {
    testWidgets('positioning with anchorPoint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              // Display has a vertical hinge down the middle
              data: const MediaQueryData(
                size: Size(800, 600),
                displayFeatures: <DisplayFeature>[
                  DisplayFeature(
                    bounds: Rect.fromLTRB(390, 0, 410, 600),
                    type: DisplayFeatureType.hinge,
                    state: DisplayFeatureState.unknown,
                  ),
                ],
              ),
              child: child!,
            );
          },
          home: const Center(child: Text('Test')),
        ),
      );
      final BuildContext context = tester.element(find.text('Test'));

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return const Placeholder();
        },
        anchorPoint: const Offset(1000, 0),
      );
      await tester.pumpAndSettle();

      // Should take the right side of the screen
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(410.0, 0.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(800.0, 600.0));
    });

    testWidgets('positioning with Directionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              // Display has a vertical hinge down the middle
              data: const MediaQueryData(
                size: Size(800, 600),
                displayFeatures: <DisplayFeature>[
                  DisplayFeature(
                    bounds: Rect.fromLTRB(390, 0, 410, 600),
                    type: DisplayFeatureType.hinge,
                    state: DisplayFeatureState.unknown,
                  ),
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            );
          },
          home: const Center(child: Text('Test')),
        ),
      );
      final BuildContext context = tester.element(find.text('Test'));

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return const Placeholder();
        },
      );
      await tester.pumpAndSettle();

      // Since this is RTL, it should place the dialog on the right screen
      expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(410.0, 0.0));
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(800.0, 600.0));
    });

    testWidgets('positioning by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              // Display has a vertical hinge down the middle
              data: const MediaQueryData(
                size: Size(800, 600),
                displayFeatures: <DisplayFeature>[
                  DisplayFeature(
                    bounds: Rect.fromLTRB(390, 0, 410, 600),
                    type: DisplayFeatureType.hinge,
                    state: DisplayFeatureState.unknown,
                  ),
                ],
              ),
              child: child!,
            );
          },
          home: const Center(child: Text('Test')),
        ),
      );
      final BuildContext context = tester.element(find.text('Test'));

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return const Placeholder();
        },
      );
      await tester.pumpAndSettle();

      // By default it should place the dialog on the left screen
      expect(tester.getTopLeft(find.byType(Placeholder)), Offset.zero);
      expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(390.0, 600.0));
    });
  });

  group('AlertDialog.scrollable: ', () {
    testWidgets('Title is scrollable', (WidgetTester tester) async {
      final Key titleKey = UniqueKey();
      final AlertDialog dialog = AlertDialog(
        title: Container(
          key: titleKey,
          color: Colors.green,
          height: 1000,
        ),
        scrollable: true,
      );
      await tester.pumpWidget(_buildAppWithDialog(dialog));
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();

      final RenderBox box = tester.renderObject(find.byKey(titleKey));
      final Offset originalOffset = box.localToGlobal(Offset.zero);
      await tester.drag(find.byKey(titleKey), const Offset(0.0, -200.0));
      expect(box.localToGlobal(Offset.zero), equals(originalOffset.translate(0.0, -200.0)));
    });

    testWidgets('Content is scrollable', (WidgetTester tester) async {
      final Key contentKey = UniqueKey();
      final AlertDialog dialog = AlertDialog(
        content: Container(
          key: contentKey,
          color: Colors.orange,
          height: 1000,
        ),
        scrollable: true,
      );
      await tester.pumpWidget(_buildAppWithDialog(dialog));
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();

      final RenderBox box = tester.renderObject(find.byKey(contentKey));
      final Offset originalOffset = box.localToGlobal(Offset.zero);
      await tester.drag(find.byKey(contentKey), const Offset(0.0, -200.0));
      expect(box.localToGlobal(Offset.zero), equals(originalOffset.translate(0.0, -200.0)));
    });

    testWidgets('Title and content are scrollable', (WidgetTester tester) async {
      final Key titleKey = UniqueKey();
      final Key contentKey = UniqueKey();
      final AlertDialog dialog = AlertDialog(
        title: Container(
          key: titleKey,
          color: Colors.green,
          height: 400,
        ),
        content: Container(
          key: contentKey,
          color: Colors.orange,
          height: 400,
        ),
        scrollable: true,
      );
      await tester.pumpWidget(_buildAppWithDialog(dialog));
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();

      final RenderBox title = tester.renderObject(find.byKey(titleKey));
      final RenderBox content = tester.renderObject(find.byKey(contentKey));
      final Offset titleOriginalOffset = title.localToGlobal(Offset.zero);
      final Offset contentOriginalOffset = content.localToGlobal(Offset.zero);

      // Dragging the title widget should scroll both the title
      // and the content widgets.
      await tester.drag(find.byKey(titleKey), const Offset(0.0, -200.0));
      expect(title.localToGlobal(Offset.zero), equals(titleOriginalOffset.translate(0.0, -200.0)));
      expect(content.localToGlobal(Offset.zero), equals(contentOriginalOffset.translate(0.0, -200.0)));

      // Dragging the content widget should scroll both the title
      // and the content widgets.
      await tester.drag(find.byKey(contentKey), const Offset(0.0, 200.0));
      expect(title.localToGlobal(Offset.zero), equals(titleOriginalOffset));
      expect(content.localToGlobal(Offset.zero), equals(contentOriginalOffset));
    });
  });

  testWidgets('Dialog with RouteSettings', (WidgetTester tester) async {
    late RouteSettings currentRouteSetting;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[
          _ClosureNavigatorObserver(onDidChange: (Route<dynamic> newRoute) {
            currentRouteSetting = newRoute.settings;
          }),
        ],
        home: const Material(
          child: Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));
    const RouteSettings exampleSetting = RouteSettings(name: 'simple');

    final Future<int?> result = showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            SimpleDialogOption(
              child: const Text('X'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
      routeSettings: exampleSetting,
    );

    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);
    expect(currentRouteSetting, exampleSetting);

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(await result, isNull);
    await tester.pumpAndSettle();
    expect(currentRouteSetting.name, '/');
  });

  testWidgets('showDialog - custom barrierLabel', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: ElevatedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierLabel: 'Custom label',
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(semantics, isNot(includesNodeWith(
      label: 'Custom label',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    )));
  });

  testWidgets('DialogRoute is state restorable', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: _RestorableDialogTestWidget(),
      ),
    );

    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    final TestRestorationData restorationData = await tester.getRestorationData();

    await tester.restartAndRestore();

    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    await tester.restoreFrom(restorationData);
    expect(find.byType(AlertDialog), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/33615

  testWidgets('AlertDialog.actionsAlignment', (WidgetTester tester) async {
    final Key actionKey = UniqueKey();

    Widget buildFrame(MainAxisAlignment? alignment) {
      return MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            content: const SizedBox(width: 800),
            actionsAlignment: alignment,
            actions: <Widget>[SizedBox(key: actionKey, width: 20, height: 20)],
            buttonPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // Default configuration
    await tester.pumpWidget(buildFrame(null));
    expect(tester.getTopLeft(find.byType(AlertDialog)).dx, 0);
    expect(tester.getTopRight(find.byType(AlertDialog)).dx, 800);
    expect(tester.getSize(find.byType(OverflowBar)).width, 800);
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, 800 - 20);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, 800);

    // All possible alginment values

    await tester.pumpWidget(buildFrame(MainAxisAlignment.start));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, 0);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, 20);

    await tester.pumpWidget(buildFrame(MainAxisAlignment.center));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, (800 - 20) / 2);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, (800 - 20) / 2 + 20);

    await tester.pumpWidget(buildFrame(MainAxisAlignment.end));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, 800 - 20);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, 800);

    await tester.pumpWidget(buildFrame(MainAxisAlignment.spaceBetween));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, 0);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, 20);

    await tester.pumpWidget(buildFrame(MainAxisAlignment.spaceAround));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, (800 - 20) / 2);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, (800 - 20) / 2 + 20);

    await tester.pumpWidget(buildFrame(MainAxisAlignment.spaceEvenly));
    expect(tester.getTopLeft(find.byKey(actionKey)).dx, (800 - 20) / 2);
    expect(tester.getTopRight(find.byKey(actionKey)).dx, (800 - 20) / 2 + 20);
  });
}

class _RestorableDialogTestWidget extends StatelessWidget {
  static Route<Object?> _materialDialogBuilder(BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) => const AlertDialog(title: Text('Material Alert!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).restorablePush(_materialDialogBuilder);
          },
          child: const Text('X'),
        ),
      ),
    );
  }
}

class DialogObserver extends NavigatorObserver {
  int dialogCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is DialogRoute) {
      dialogCount++;
    }
    super.didPush(route, previousRoute);
  }
}

class _ClosureNavigatorObserver extends NavigatorObserver {
  _ClosureNavigatorObserver({required this.onDidChange});

  final void Function(Route<dynamic> newRoute) onDidChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onDidChange(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onDidChange(previousRoute!);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => onDidChange(previousRoute!);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => onDidChange(newRoute!);
}
