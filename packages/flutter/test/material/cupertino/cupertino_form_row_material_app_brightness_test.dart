// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoFormRow adapts to MaterialApp dark mode', (WidgetTester tester) async {
    const Widget prefix = Text('Prefix');
    const Widget helper = Text('Helper');

    Widget buildFormRow(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Center(
          child: CupertinoFormRow(prefix: prefix, helper: helper, child: CupertinoTextField()),
        ),
      );
    }

    // CupertinoFormRow with light theme.
    await tester.pumpWidget(buildFormRow(Brightness.light));
    RenderParagraph helperParagraph = tester.renderObject(find.text('Helper'));
    expect(helperParagraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(helperParagraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
    RenderParagraph prefixParagraph = tester.renderObject(find.text('Prefix'));
    expect(prefixParagraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(prefixParagraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoFormRow with light theme.
    await tester.pumpWidget(buildFormRow(Brightness.dark));
    helperParagraph = tester.renderObject(find.text('Helper'));
    expect(helperParagraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(helperParagraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
    prefixParagraph = tester.renderObject(find.text('Prefix'));
    expect(prefixParagraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(prefixParagraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });
}
