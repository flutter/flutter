// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('DefaultTextStyle changes propagate to Text', (WidgetTester tester) async {
    const Text textWidget = const Text('Hello');
    const TextStyle s1 = const TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );

    await tester.pumpWidget(const DefaultTextStyle(
      style: s1,
      child: textWidget
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
      child: textWidget
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.text.style, s1);
    expect(text.textAlign, TextAlign.justify);
    expect(text.softWrap, false);
    expect(text.overflow, TextOverflow.fade);
    expect(text.maxLines, 3);
  });
}
