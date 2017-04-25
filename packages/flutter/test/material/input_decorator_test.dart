// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('InputDecorator always expands horizontally', (WidgetTester tester) async {
    final Key key = new UniqueKey();

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new InputDecorator(
          decoration: const InputDecoration(),
          child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new InputDecorator(
          decoration: const InputDecoration(
            icon: const Icon(Icons.add_shopping_cart),
          ),
          child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(752.0, 60.0)));

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new InputDecorator(
          decoration: const InputDecoration.collapsed(
            hintText: 'Hint text',
          ),
          child: new Container(key: key, width: 50.0, height: 60.0, color: Colors.blue),
        ),
      ),
    ));

    expect(tester.element(find.byKey(key)).size, equals(const Size(800.0, 60.0)));
  });
}
