// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('MasonryGridView', () {
    testWidgets('the size of each child', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getSize(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Size(400.0, 50.0),
      );

      expect(tester.getSize(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Size(400.0, 70.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Size(400.0, 90.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '3.Who scream')),
        const Size(400.0, 60.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Size(400.0, 80.0),
      );

      expect(
        tester.getSize(find.widgetWithText(Container, '5.Revolution, they...')),
        const Size(400.0, 100.0),
      );
    });

    testWidgets('the position of each child at TextDirection.ltr',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr,
      ));

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(400.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(0.0, 140.0),
      );
    });

    testWidgets('the position of each child at TextDirection.rtl',
      (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.rtl),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, "0.He'd have you all unravel at the")),
        const Offset(400.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1.Heed not the rabble')),
        const Offset(0.0, 0.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(0.0, 70.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '4.Revolution is coming...')),
        const Offset(0.0, 130.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '5.Revolution, they...')),
        const Offset(400.0, 140.0),
      );
    });

    testWidgets('crossAxisCount change test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(crossAxisCount: 2),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(crossAxisCount: 4),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('crossAxisSpacing test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(405.0, 70.0),
      );
    });

    testWidgets('mainAxisSpacing test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(
          crossAxisCount: 2,
          mainAxisSpacing: 10.0,
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 60.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(400.0, 80.0),
      );
    });

    testWidgets('crossAxisSpacing test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
        ),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '3.Who scream')),
        const Offset(405.0, 70.0),
      );
    });

    testWidgets('maxCrossAxisExtent change test', (WidgetTester tester) async {
      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(maxCrossAxisExtent: 400),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(0.0, 50.0),
      );

      await tester.pumpWidget(materialAppBoilerplate(
        child: masonryGridViewBoilerplate(maxCrossAxisExtent: 200),
        textDirection: TextDirection.ltr),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '2.Sound of screams but the')),
        const Offset(400.0, 0.0),
      );
    });

    testWidgets('Vertical are primary by default', (WidgetTester tester) async {
      final MasonryGridView view = MasonryGridView(
        scrollDirection: Axis.vertical,
        gridDelegate: const SliverMasonryGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      );
      expect(view.primary, isTrue);
    });

    testWidgets('with controllers are non-primary by default', (WidgetTester tester) async {
      final MasonryGridView view = MasonryGridView(
        controller: ScrollController(),
        scrollDirection: Axis.vertical,
        gridDelegate: const SliverMasonryGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      );
      expect(view.primary, isFalse);
    });

    testWidgets('sets PrimaryScrollController when primary', (WidgetTester tester) async {
      final ScrollController primaryScrollController = ScrollController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PrimaryScrollController(
            controller: primaryScrollController,
            child: MasonryGridView(
              primary: true,
              gridDelegate: const SliverMasonryGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            ),
          ),
        ),
      );
      final Scrollable scrollable = tester.widget(find.byType(Scrollable));
      expect(scrollable.controller, primaryScrollController);
    });

    testWidgets('dismiss keyboard onDrag test', (WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView(
          padding: const EdgeInsets.all(0),
          gridDelegate: const SliverMasonryGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
       ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isFalse);
    });

    testWidgets('count dismiss keyboard onDrag test',(WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView.count(
          padding: const EdgeInsets.all(0),
          crossAxisCount: 2,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
        ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isFalse);
    });

    testWidgets('extent dismiss keyboard onDrag test',(WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView.extent(
          padding: const EdgeInsets.all(0),
          maxCrossAxisExtent: 300,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
        ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isFalse);
    });

    testWidgets('dismiss keyboard manual test', (WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView(
          padding: const EdgeInsets.all(0),
          gridDelegate: const SliverMasonryGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
        ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isTrue);
    });

    testWidgets('count dismiss keyboard manual test', (WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView.count(
          padding: const EdgeInsets.all(0),
          crossAxisCount: 2,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
        ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isTrue);
    });

    testWidgets('extend dismiss keyboard manual test', (WidgetTester tester) async {
      final List<FocusNode> focusNodes = List<FocusNode>.generate(50, (int i) => FocusNode());
      await tester.pumpWidget(textFieldBoilerplate(
        child: MasonryGridView.extent(
          padding: const EdgeInsets.all(0),
          maxCrossAxisExtent: 300,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          children: focusNodes.map((FocusNode focusNode) {
            return Container(
              height: 50,
              color: Colors.green,
              child: TextField(
                focusNode: focusNode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            );
          }).toList(),
        ),
      ));

      final Finder finder = find.byType(TextField).first;
      final TextField textField = tester.widget(finder);
      await tester.showKeyboard(finder);
      expect(textField.focusNode.hasFocus, isTrue);

      await tester.drag(finder, const Offset(0.0, -40.0));
      await tester.pumpAndSettle();
      expect(textField.focusNode.hasFocus, isTrue);
    });
  });
}

Widget masonryGridViewBoilerplate({
  int crossAxisCount = 2,
  double crossAxisSpacing = 0.0,
  double mainAxisSpacing = 0.0,
  double maxCrossAxisExtent,
}) {
  final List<Widget> children = <Widget> [
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text("0.He'd have you all unravel at the"),
      color: Colors.teal[100],
      height: 50.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('1.Heed not the rabble'),
      color: Colors.teal[200],
      height: 70.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('2.Sound of screams but the'),
      color: Colors.teal[300],
      height: 90.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('3.Who scream'),
      color: Colors.teal[400],
      height: 60.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('4.Revolution is coming...'),
      color: Colors.teal[500],
      height: 80.0,
    ),
    Container(
      padding: const EdgeInsets.all(8),
      child: const Text('5.Revolution, they...'),
      color: Colors.teal[600],
      height: 100.0,
    ),
  ];

  if(maxCrossAxisExtent != null) {
    return MasonryGridView.extent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
  }

  return MasonryGridView.count(
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    children: children,
  );
}

Widget materialAppBoilerplate(
    {Widget child, TextDirection textDirection = TextDirection.ltr}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Material(
          child: child,
        ),
      ),
    ),
  );
}

Widget textFieldBoilerplate({Widget child}) {
  return MaterialApp(
    home: Localizations(
      locale: const Locale('en', 'US'),
      delegates: <LocalizationsDelegate<dynamic>>[
        WidgetsLocalizationsDelegate(),
        MaterialLocalizationsDelegate(),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800.0, 600.0)),
          child: Center(
            child: Material(
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class MaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(MaterialLocalizationsDelegate old) => false;
}

class WidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(WidgetsLocalizationsDelegate old) => false;
}