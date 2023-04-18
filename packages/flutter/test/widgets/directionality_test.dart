// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Directionality', (final WidgetTester tester) async {
    final List<TextDirection> log = <TextDirection>[];
    final Widget inner = Builder(
      builder: (final BuildContext context) {
        log.add(Directionality.of(context));
        return const Placeholder();
      },
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: inner,
      ),
    );
    expect(log, <TextDirection>[TextDirection.ltr]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: inner,
      ),
    );
    expect(log, <TextDirection>[TextDirection.ltr]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: inner,
      ),
    );
    expect(log, <TextDirection>[TextDirection.ltr, TextDirection.rtl]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: inner,
      ),
    );
    expect(log, <TextDirection>[TextDirection.ltr, TextDirection.rtl]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: inner,
      ),
    );
    expect(log, <TextDirection>[TextDirection.ltr, TextDirection.rtl, TextDirection.ltr]);
  });

  testWidgets('Directionality default', (final WidgetTester tester) async {
    bool good = false;
    await tester.pumpWidget(Builder(
      builder: (final BuildContext context) {
        expect(Directionality.maybeOf(context), isNull);
        good = true;
        return const Placeholder();
      },
    ));
    expect(good, isTrue);
  });

  testWidgets('Directionality.maybeOf', (final WidgetTester tester) async {
    final GlobalKey hasDirectionality = GlobalKey();
    final GlobalKey noDirectionality = GlobalKey();
    await tester.pumpWidget(
      Container(
        key: noDirectionality,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            key: hasDirectionality,
          ),
        ),
      ),
    );
    expect(Directionality.maybeOf(noDirectionality.currentContext!), isNull);
    expect(Directionality.maybeOf(hasDirectionality.currentContext!), TextDirection.rtl);
  });

  testWidgets('Directionality.of', (final WidgetTester tester) async {
    final GlobalKey hasDirectionality = GlobalKey();
    final GlobalKey noDirectionality = GlobalKey();
    await tester.pumpWidget(
      Container(
        key: noDirectionality,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            key: hasDirectionality,
          ),
        ),
      ),
    );
    expect(() => Directionality.of(noDirectionality.currentContext!), throwsA(isAssertionError.having(
      (final AssertionError e) => e.message,
      'message',
      contains('No Directionality widget found.'),
    )));
    expect(Directionality.of(hasDirectionality.currentContext!), TextDirection.rtl);
  });
}
