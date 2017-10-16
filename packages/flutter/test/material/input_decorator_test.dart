// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InputDecorator always expands horizontally', (WidgetTester tester) async {
    final Key key = new UniqueKey();

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new InputDecorator(
            decoration: const InputDecoration(),
            child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
          ),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new InputDecorator(
            decoration: const InputDecoration(
              icon: const Icon(Icons.add_shopping_cart),
            ),
            child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
          ),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(752.0, 60.0)));

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new InputDecorator(
            decoration: const InputDecoration.collapsed(
              hintText: 'Hint text',
            ),
            child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
          ),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));
  });

  testWidgets('InputDecorator uses proper padding', (WidgetTester tester) async {
    final TextStyle style = const TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new DefaultTextStyle(
          style: style,
          child: const Center(
            child: const InputDecorator(
              decoration: const InputDecoration(hintText: 'Hint', labelText: 'Label', helperText: 'Helper'),
              child: const Text('Test'),
            ),
          ),
        ),
      ),
    ));

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
        tester.getRect(find.text('Label')),
        anyOf(<Rect>[
          new Rect.fromLTWH(0.0, 281.0, 60.0, 12.0),
          new Rect.fromLTWH(0.0, 281.0, 61.0, 12.0),
        ])
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 297.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 330.0, 800.0, 12.0)));

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new DefaultTextStyle(
          style: style,
          child: const Center(
            child: const InputDecorator(
              decoration: const InputDecoration(hintText: 'Hint', labelText: 'Label', errorText: 'Error'),
              child: const Text('Test'),
            ),
          ),
        ),
      ),
    ));

    expect(
        tester.getRect(find.text('Label')),
        anyOf(<Rect>[
          new Rect.fromLTWH(0.0, 281.0, 60.0, 12.0),
          new Rect.fromLTWH(0.0, 281.0, 61.0, 12.0),
        ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 297.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Error')), equals(new Rect.fromLTWH(0.0, 330.0, 800.0, 12.0)));
  });

  testWidgets('InputDecorator animates properly', (WidgetTester tester) async {
    final TextStyle style = const TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new DefaultTextStyle(
          style: style,
          child: const Center(
            child: const TextField(
              decoration: const InputDecoration(
                suffixText: 'S',
                prefixText: 'P',
                hintText: 'Hint',
                labelText: 'Label',
                helperText: 'Helper',
              ),
            ),
          ),
        ),
      ),
    ));

    // TODO(#12357): Update this test when the font metric bug is fixed to remove the anyOfs.
    expect(
      tester.getRect(find.text('Label')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 294.0, 80.0, 16.0),
        new Rect.fromLTWH(0.0, 294.0, 81.0, 16.0),
      ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 294.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 327.0, 800.0, 12.0)));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getRect(find.text('Label')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 294.0, 60.0, 12.0),
        new Rect.fromLTWH(0.0, 294.0, 61.0, 12.0),
      ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 294.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 327.0, 800.0, 12.0)));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getRect(find.text('Label')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 278.0, 60.0, 12.0),
        new Rect.fromLTWH(0.0, 278.0, 61.0, 12.0),
      ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 294.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 327.0, 800.0, 12.0)));
    expect(find.text('P'), findsNothing);
    expect(find.text('S'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Test');
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.getRect(find.text('Label')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 278.0, 60.0, 12.0),
        new Rect.fromLTWH(0.0, 278.0, 61.0, 12.0),
      ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 294.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 327.0, 800.0, 12.0)));
    expect(
      tester.getRect(find.text('P')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 294.0, 16.0, 16.0),
        new Rect.fromLTWH(0.0, 294.0, 17.0, 16.0),
      ]),
    );
    expect(
      tester.getRect(find.text('S')),
      anyOf(<Rect>[
        new Rect.fromLTWH(784.0, 294.0, 16.0, 16.0),
        new Rect.fromLTWH(783.0, 294.0, 17.0, 16.0),
      ]),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getRect(find.text('Label')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 278.0, 60.0, 12.0),
        new Rect.fromLTWH(0.0, 278.0, 61.0, 12.0),
      ]),
    );
    expect(tester.getRect(find.text('Hint')), equals(new Rect.fromLTWH(0.0, 294.0, 800.0, 16.0)));
    expect(tester.getRect(find.text('Helper')), equals(new Rect.fromLTWH(0.0, 327.0, 800.0, 12.0)));
    expect(
      tester.getRect(find.text('P')),
      anyOf(<Rect>[
        new Rect.fromLTWH(0.0, 294.0, 16.0, 16.0),
        new Rect.fromLTWH(0.0, 294.0, 17.0, 16.0),
      ]),
    );
    expect(
      tester.getRect(find.text('S')),
      anyOf(<Rect>[
        new Rect.fromLTWH(784.0, 294.0, 16.0, 16.0),
        new Rect.fromLTWH(783.0, 294.0, 17.0, 16.0),
      ]),
    );
  });
}
