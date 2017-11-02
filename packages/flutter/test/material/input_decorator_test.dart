// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildInputDecorator({InputDecoration decoration = const InputDecoration(), Widget child = const Text('Test')}) {
    return new MaterialApp(
      home: new Material(
        child: new DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
          child: new Center(
            child: new InputDecorator(
              decoration: decoration,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Finder findInputDecoratorChildContainer() {
    return find.byWidgetPredicate(
            (Widget w) {
          return w is AnimatedContainer && (w as dynamic).decoration != null;
        });
  }

  double getBoxDecorationThickness(WidgetTester tester) {
    final AnimatedContainer container = tester.widget(findInputDecoratorChildContainer());
    final BoxDecoration decoration = container.decoration;
    final Border border = decoration.border;
    return border.bottom.width;
  }

  double getDividerY(WidgetTester tester) {
    final Finder animatedContainerFinder = find.byWidgetPredicate(
            (Widget w) {
          return w is AnimatedContainer && (w as dynamic).decoration != null;
        });
    return tester.getRect(animatedContainerFinder).bottom;
  }

  double getDividerWidth(WidgetTester tester) {
    final Finder animatedContainerFinder = find.byWidgetPredicate(
            (Widget w) {
          return w is AnimatedContainer && (w as dynamic).decoration != null;
        });
    return tester.getRect(animatedContainerFinder).size.width;
  }

  testWidgets('InputDecorator always expands horizontally', (WidgetTester tester) async {
    final Key key = new UniqueKey();

    await tester.pumpWidget(
      buildInputDecorator(
        child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
      ),
    );

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));

    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          icon: const Icon(Icons.add_shopping_cart),
        ),
        child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
      ),
    );

    expect(tester.element(find.byKey(key)).size, equals(const Size(752.0, 60.0)));

    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration.collapsed(
          hintText: 'Hint text',
        ),
        child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
      ),
    );

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));
  });

  testWidgets('InputDecorator draws the divider correctly in the right place.', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          counterText: 'Counter',
        ),
      ),
    );

    expect(getBoxDecorationThickness(tester), equals(1.0));
    expect(getDividerY(tester), equals(316.5));
    expect(getDividerWidth(tester), equals(800.0));
  });

  testWidgets('InputDecorator draws the divider correctly in the right place for dense layout.', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          counterText: 'Counter',
          isDense: true,
        ),
      ),
    );

    expect(getBoxDecorationThickness(tester), equals(1.0));
    expect(getDividerY(tester), equals(312.5));
    expect(getDividerWidth(tester), equals(800.0));
  });

  testWidgets('InputDecorator does not draw the underline when hideDivider is true.', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          counterText: 'Counter',
          hideDivider: true,
        ),
      ),
    );

    expect(findInputDecoratorChildContainer(), findsNothing);
  });

  testWidgets('InputDecorator uses proper padding for dense mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          counterText: 'Counter',
          isDense: true,
        ),
      ),
    );

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(278.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(294.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(716.0, 12.0), const Size(715.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(317.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(716.0, 715.0));
    expect(tester.getRect(find.text('Counter')).top, equals(317.5));
  });

  testWidgets('InputDecorator uses proper padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          counterText: 'Counter',
        ),
      ),
    );

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
        tester.getRect(find.text('Label')).size,
        anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(278.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(298.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(325.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(325.5));
  });

  testWidgets('InputDecorator uses proper padding when error is set', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          hintText: 'Hint',
          labelText: 'Label',
          helperText: 'Helper',
          errorText: 'Error',
          counterText: 'Counter',
        ),
      ),
    );

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(278.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(298.5));
    expect(
      tester.getRect(find.text('Error')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Error')).left, equals(0.0));
    expect(tester.getRect(find.text('Error')).top, equals(325.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(325.5));
  });

  testWidgets('InputDecorator animates properly', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: const Material(
        child: const DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
          child: const Center(
            child: const TextField(
              decoration: const InputDecoration(
                suffixText: 'S',
                prefixText: 'P',
                hintText: 'Hint',
                labelText: 'Label',
                helperText: 'Helper',
                counterText: 'Counter',
              ),
            ),
          ),
        ),
      ),
    ));

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(80.0, 16.0), const Size(81.0, 16.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(295.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(295.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(328.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(328.5));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(295.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(295.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(328.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(328.5));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(275.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(295.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(328.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(328.5));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Test');
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(275.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(295.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(328.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(328.5));
    expect(
      tester.getRect(find.text('P')).size,
      anyOf(<Size>[const Size(17.0, 16.0), const Size(16.0, 16.0)]),
    );
    expect(tester.getRect(find.text('P')).left, equals(0.0));
    expect(tester.getRect(find.text('P')).top, equals(295.5));
    expect(
      tester.getRect(find.text('S')).size,
      anyOf(<Size>[const Size(17.0, 16.0), const Size(16.0, 16.0)]),
    );
    expect(tester.getRect(find.text('S')).left, anyOf(783.0, 784.0));
    expect(tester.getRect(find.text('S')).top, equals(295.5));

    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getRect(find.text('Label')).size,
      anyOf(<Size>[const Size(60.0, 12.0), const Size(61.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Label')).left, equals(0.0));
    expect(tester.getRect(find.text('Label')).top, equals(275.5));
    expect(tester.getRect(find.text('Hint')).size, equals(const Size(800.0, 16.0)));
    expect(tester.getRect(find.text('Hint')).left, equals(0.0));
    expect(tester.getRect(find.text('Hint')).top, equals(295.5));
    expect(
      tester.getRect(find.text('Helper')).size,
      anyOf(<Size>[const Size(715.0, 12.0), const Size(716.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Helper')).left, equals(0.0));
    expect(tester.getRect(find.text('Helper')).top, equals(328.5));
    expect(
      tester.getRect(find.text('Counter')).size,
      anyOf(<Size>[const Size(84.0, 12.0), const Size(85.0, 12.0)]),
    );
    expect(tester.getRect(find.text('Counter')).left, anyOf(715.0, 716.0));
    expect(tester.getRect(find.text('Counter')).top, equals(328.5));
    expect(
      tester.getRect(find.text('P')).size,
      anyOf(<Size>[const Size(17.0, 16.0), const Size(16.0, 16.0)]),
    );
    expect(tester.getRect(find.text('P')).left, equals(0.0));
    expect(tester.getRect(find.text('P')).top, equals(295.5));
    expect(
      tester.getRect(find.text('S')).size,
      anyOf(<Size>[const Size(17.0, 16.0), const Size(16.0, 16.0)]),
    );
    expect(tester.getRect(find.text('S')).left, anyOf(783.0, 784.0));
    expect(tester.getRect(find.text('S')).top, equals(295.5));
  });

  testWidgets('InputDecorator animates properly', (WidgetTester tester) async {
    final Widget child = const InputDecorator(
      key: const Key('key'),
      decoration: const InputDecoration(),
      baseStyle: const TextStyle(),
      textAlign: TextAlign.center,
      isFocused: false,
      isEmpty: false,
      child: const Placeholder(),
    );
    expect(
      child.toString(),
      'InputDecorator-[<\'key\'>](decoration: InputDecoration(), baseStyle: TextStyle(<all styles inherited>), isFocused: false, isEmpty: false)',
    );
  });

  testWidgets('InputDecorator works with partially specified styles', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: const Material(
        child: const DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
          child: const Center(
            child: const TextField(
              decoration: const InputDecoration(
                labelText: 'label',
                labelStyle: const TextStyle(),
                helperText: 'helper',
                helperStyle: const TextStyle(),
                hintText: 'hint',
                hintStyle: const TextStyle(),
                errorText: 'error',
                errorStyle: const TextStyle(),
                prefixText: 'prefix',
                prefixStyle: const TextStyle(),
                suffixText: 'suffix',
                suffixStyle: const TextStyle(),
                counterText: 'counter',
                counterStyle: const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.text('label'), findsOneWidget);

    // Tap to make the hint show up.
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('hint'), findsOneWidget);

    // Enter text to make the text style get used.
    await tester.enterText(find.byType(TextField), 'Test');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('prefix'), findsOneWidget);
    expect(find.text('suffix'), findsOneWidget);

    // Test again without error, so helper style gets used.
    await tester.pumpWidget(new MaterialApp(
      home: const Material(
        child: const DefaultTextStyle(
          style: const TextStyle(),
          child: const Center(
            child: const TextField(
              decoration: const InputDecoration(
                labelText: 'label',
                labelStyle: const TextStyle(),
                helperText: 'helper',
                helperStyle: const TextStyle(),
                hintText: 'hint',
                hintStyle: const TextStyle(),
                prefixText: 'prefix',
                prefixStyle: const TextStyle(),
                suffixText: 'suffix',
                suffixStyle: const TextStyle(),
                counterText: 'counter',
                counterStyle: const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    ));

    expect(find.text('label'), findsOneWidget);
    expect(find.text('helper'), findsOneWidget);
  });
}
