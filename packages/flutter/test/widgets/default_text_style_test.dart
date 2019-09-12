// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('DefaultTextStyle changes propagate to Text', (WidgetTester tester) async {
    const Text textWidget = Text('Hello', textDirection: TextDirection.ltr);
    const TextStyle s1 = TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );

    await tester.pumpWidget(const DefaultTextStyle(
      style: s1,
      child: textWidget,
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.text.style, s1);

    await tester.pumpWidget(const DefaultTextStyle(
      style: s1,
      textAlign: TextAlign.justify,
      softWrap: false,
      overflow: TextOverflow.fade,
      maxLines: 3,
      child: textWidget,
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.text.style, s1);
    expect(text.textAlign, TextAlign.justify);
    expect(text.softWrap, false);
    expect(text.overflow, TextOverflow.fade);
    expect(text.maxLines, 3);
  });

  testWidgets('AnimatedDefaultTextStyle changes propagate to Text', (WidgetTester tester) async {
    const Text textWidget = Text('Hello', textDirection: TextDirection.ltr);
    const TextStyle s1 = TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );
    const TextStyle s2 = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w200,
      height: 1.0,
    );

    await tester.pumpWidget(const AnimatedDefaultTextStyle(
      style: s1,
      child: textWidget,
      duration: Duration(milliseconds: 1000),
    ));

    final RichText text1 = tester.firstWidget(find.byType(RichText));
    expect(text1, isNotNull);
    expect(text1.text.style, s1);
    expect(text1.textAlign, TextAlign.start);
    expect(text1.softWrap, isTrue);
    expect(text1.overflow, TextOverflow.clip);
    expect(text1.maxLines, isNull);

    await tester.pumpWidget(const AnimatedDefaultTextStyle(
      style: s2,
      textAlign: TextAlign.justify,
      softWrap: false,
      overflow: TextOverflow.fade,
      maxLines: 3,
      child: textWidget,
      duration: Duration(milliseconds: 1000),
    ));

    final RichText text2 = tester.firstWidget(find.byType(RichText));
    expect(text2, isNotNull);
    expect(text2.text.style, s1); // animation hasn't started yet
    expect(text2.textAlign, TextAlign.justify);
    expect(text2.softWrap, false);
    expect(text2.overflow, TextOverflow.fade);
    expect(text2.maxLines, 3);

    await tester.pump(const Duration(milliseconds: 1000));

    final RichText text3 = tester.firstWidget(find.byType(RichText));
    expect(text3, isNotNull);
    expect(text3.text.style, s2); // animation has now finished
    expect(text3.textAlign, TextAlign.justify);
    expect(text3.softWrap, false);
    expect(text3.overflow, TextOverflow.fade);
    expect(text3.maxLines, 3);
  });
}
