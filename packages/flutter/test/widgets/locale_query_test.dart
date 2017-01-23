// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestLocaleQueryData extends LocaleQueryData {
  @override
  String toString() => 'Test data';
}

void main() {
  testWidgets('LocaleQuery control test', (WidgetTester tester) async {
    await tester.pumpWidget(new Container());

    expect(LocaleQuery.of(tester.element(find.byType(Container))), isNull);

    LocaleQueryData data = new TestLocaleQueryData();
    Widget widget = new LocaleQuery(
      data: data,
      child: new Container(),
    );

    expect(widget, hasOneLineDescription);
    expect(widget.toString(), contains('Test data'));

    await tester.pumpWidget(widget);

    expect(LocaleQuery.of(tester.element(find.byType(Container))), equals(data));
  });
}
