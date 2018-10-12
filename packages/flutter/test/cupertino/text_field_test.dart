// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'takes available space horizontally and takes intrinsic space vertically',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 29), // 29 is the height of the default font + padding etc.
      );
    },
  );

  testWidgets(
    'multi-lined text fields are intrinsically taller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(const Size(200, 200)),
              child: const CupertinoTextField(maxLines: 3),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(CupertinoTextField)),
        const Size(200, 63),
      );
    },
  );

  testWidgets(
    'default text field has a border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(),
          ),
        ),
      );

      final BoxDecoration decoration = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CupertinoTextField),
          matching: find.byType(DecoratedBox)
        ),
      ).decoration;

      expect(
        decoration.borderRadius,
        BorderRadius.circular(4.0),
      );
      expect(
        decoration.border.bottom.color,
        CupertinoColors.lightBackgroundGray,
      );
    },
  );

  testWidgets(
    'decoration can be overrriden',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              decoration: null,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CupertinoTextField),
          matching: find.byType(DecoratedBox)
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'text entries are padded by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              controller: TextEditingController(text: 'initial'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('initial')) - tester.getTopLeft(find.byType(CupertinoTextField)),
        const Offset(6.0, 6.0),
      );
    },
  );

  testWidgets(
    'placeholders are lightly colored and disappears once typing starts',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              placeholder: 'placeholder',
            ),
          ),
        ),
      );

      final Text placeholder = tester.widget(find.text('placeholder'));
      expect(placeholder.style.color, const Color(0xFFC2C2C2));

      await tester.enterText(find.byType(CupertinoTextField), 'input');
      await tester.pump();
      expect(find.text('placeholder'), findsNothing);
    },
  );

  testWidgets(
    'leading widget is in front of the text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoTextField(
              leading: const Icon(CupertinoIcons.add),
              placeholder: 'placeholder',
              controller: TextEditingController(text: 'input'),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('placeholder')),
        tester.getTopLeft(find.byType(RenderEditable)),
      );
    },
  );
}
