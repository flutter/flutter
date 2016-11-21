// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SizedBox - no child', (WidgetTester tester) async {
    GlobalKey patient = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(0.0, 0.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          height: 0.0,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(0.0, 0.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 0.0,
          height: 0.0,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(0.0, 0.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 100.0,
          height: 100.0,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(100.0, 100.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 1000.0,
          height: 1000.0,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 600.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox.expand(
          key: patient,
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 600.0)));
  });

  testWidgets('SizedBox - container child', (WidgetTester tester) async {
    GlobalKey patient = new GlobalKey();

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 600.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          height: 0.0,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 0.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 0.0,
          height: 0.0,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(0.0, 0.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 100.0,
          height: 100.0,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(100.0, 100.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox(
          key: patient,
          width: 1000.0,
          height: 1000.0,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 600.0)));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox.expand(
          key: patient,
          child: new Container(),
        )
      )
    );
    expect(patient.currentContext.size, equals(const Size(800.0, 600.0)));
  });
}
