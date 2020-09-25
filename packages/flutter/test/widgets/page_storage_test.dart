// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('PageStorage read and write', (WidgetTester tester) async {
    const Key builderKey = PageStorageKey<String>('builderKey');
    StateSetter setState;
    int storedValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          key: builderKey,
          builder: (BuildContext context, StateSetter setter) {
            PageStorage.of(context).writeState(context, storedValue);
            setState = setter;
            return Center(
              child: Text('storedValue: $storedValue'),
            );
          },
        ),
      ),
    );

    final Element builderElement = tester.element(find.byKey(builderKey));
    expect(PageStorage.of(builderElement), isNotNull);
    expect(PageStorage.of(builderElement).readState(builderElement), equals(storedValue));

    setState(() {
      storedValue = 1;
    });
    await tester.pump();
    expect(PageStorage.of(builderElement).readState(builderElement), equals(storedValue));
  });

  testWidgets('PageStorage read and write by identifier', (WidgetTester tester) async {
    StateSetter setState;
    int storedValue = 0;

    Widget buildWidthKey(Key key) {
      return MaterialApp(
        home: StatefulBuilder(
          key: key,
          builder: (BuildContext context, StateSetter setter) {
            PageStorage.of(context).writeState(context, storedValue, identifier: 123);
            setState = setter;
            return Center(
              child: Text('storedValue: $storedValue'),
            );
          },
        ),
      );
    }

    Key key = const Key('Key one');
    await tester.pumpWidget(buildWidthKey(key));
    Element builderElement = tester.element(find.byKey(key));
    expect(PageStorage.of(builderElement), isNotNull);
    expect(PageStorage.of(builderElement).readState(builderElement), isNull);
    expect(PageStorage.of(builderElement).readState(builderElement, identifier: 123), equals(storedValue));

    // New StatefulBuilder widget - different key - but the same PageStorage identifier.

    key = const Key('Key two');
    await tester.pumpWidget(buildWidthKey(key));
    builderElement = tester.element(find.byKey(key));
    expect(PageStorage.of(builderElement), isNotNull);
    expect(PageStorage.of(builderElement).readState(builderElement), isNull);
    expect(PageStorage.of(builderElement).readState(builderElement, identifier: 123), equals(storedValue));

    setState(() {
      storedValue = 1;
    });
    await tester.pump();
    expect(PageStorage.of(builderElement).readState(builderElement, identifier: 123), equals(storedValue));
  });

  testWidgets('Data can be stored without overwriting each other When multiple widgets share one [PageStorageKey]', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/62332
    const Key key0 = Key('key0');
    const Key key1 = Key('key1');
    StateSetter setState;
    int storedValue0 = 0;
    int storedValue1 = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          key: const PageStorageKey<String>('storageKey'),
          child: StatefulBuilder(
            key: key0,
            builder: (BuildContext context, StateSetter setter) {
              PageStorage.of(context).writeState(context, storedValue0);
              setState = setter;
              return StatefulBuilder(
                key: key1,
                builder: (BuildContext context, StateSetter setter) {
                  PageStorage.of(context).writeState(context, storedValue1);
                  return Center(
                    child: Text('storedValues: $storedValue0 $storedValue1'),
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    final Element builderElement0 = tester.element(find.byKey(key0));
    final Element builderElement1 = tester.element(find.byKey(key1));

    // Store data normally
    expect(PageStorage.of(builderElement0).readState(builderElement0), storedValue0);
    expect(PageStorage.of(builderElement1).readState(builderElement1), storedValue1);

    setState(() {
      storedValue0 = 10;
      storedValue1 = 11;
    });

    await tester.pump();
    // The stored data is updated normally
    expect(PageStorage.of(builderElement0).readState(builderElement0), storedValue0);
    expect(PageStorage.of(builderElement1).readState(builderElement1), storedValue1);
  });
}
