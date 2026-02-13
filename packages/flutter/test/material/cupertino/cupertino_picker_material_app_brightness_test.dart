// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoPicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildCupertinoPicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 300.0,
            width: 300.0,
            child: CupertinoPicker(
              itemExtent: 50.0,
              onSelectedItemChanged: (_) {},
              children: List<Widget>.generate(3, (int index) {
                return SizedBox(height: 50.0, width: 300.0, child: Text(index.toString()));
              }),
            ),
          ),
        ),
      );
    }

    // CupertinoPicker with light theme.
    await tester.pumpWidget(buildCupertinoPicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('1'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoPicker with dark theme.
    await tester.pumpWidget(buildCupertinoPicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('1'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });

  testWidgets('CupertinoDatePicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildDatePicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime neData) {},
          initialDateTime: DateTime(2018, 10, 10),
        ),
      );
    }

    // CupertinoDatePicker with light theme.
    await tester.pumpWidget(buildDatePicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('October').first);
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoDatePicker with dark theme.
    await tester.pumpWidget(buildDatePicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('October').first);
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });

  testWidgets('CupertinoTimerPicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildTimerPicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.hm,
          onTimerDurationChanged: (Duration newDuration) {},
          initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
        ),
      );
    }

    // CupertinoTimerPicker with light theme.
    await tester.pumpWidget(buildTimerPicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('hours'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoTimerPicker with light theme.
    await tester.pumpWidget(buildTimerPicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('hours'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });
}
