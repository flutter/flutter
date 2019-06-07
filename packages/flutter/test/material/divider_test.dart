// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Divider control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Divider(),
        ),
      ),
    );
    final RenderBox box = tester.firstRenderObject(find.byType(Divider));
    expect(box.size.height, 16.0);
    expect(find.byType(Divider), paints..path(strokeWidth: 0.0));
  });

  testWidgets('Horizontal divider custom indentation', (WidgetTester tester) async {
    RenderBox divider;
    RenderBox decoratedBox;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Divider(
            indent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.horizontal, 10.0);
    divider = tester.firstRenderObject(find.byType(Divider));
    // Container widgets wrap its child in an DecoratedBox widget, which in turn
    // is wrapped by a Padding widget. The Padding widget provides these
    // indentations.
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.width, 10.0 + decoratedBox.size.width);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Divider(
            endIndent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.horizontal, 10.0);
    divider = tester.firstRenderObject(find.byType(Divider));
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.width, decoratedBox.size.width + 10.0);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Divider(
            indent: 10.0,
            endIndent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.horizontal, 20.0);
    divider = tester.firstRenderObject(find.byType(Divider));
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.width, 10.0 + decoratedBox.size.width + 10.0);
  });

  testWidgets('Vertical Divider Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: VerticalDivider(),
        ),
      ),
    );
    final RenderBox box = tester.firstRenderObject(find.byType(VerticalDivider));
    expect(box.size.width, 16.0);
    expect(find.byType(VerticalDivider), paints..path(strokeWidth: 0.0));
  });

  testWidgets('Vertical Divider Test 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Container(
            height: 24.0,
            child: Row(
              children: const <Widget>[
                Text('Hey.'),
                VerticalDivider(),
              ],
            ),
          ),
        ),
      ),
    );
    final RenderBox box = tester.firstRenderObject(find.byType(VerticalDivider));
    final RenderBox containerBox = tester.firstRenderObject(find.byType(Container).last);

    expect(box.size.width, 16.0);
    expect(containerBox.size.height, 600.0);
    expect(find.byType(VerticalDivider), paints..path(strokeWidth: 0.0));
  });

  testWidgets('Vertical divider custom indentation', (WidgetTester tester) async {
    RenderBox divider;
    RenderBox decoratedBox;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: VerticalDivider(
            indent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.vertical, 10.0);
    divider = tester.firstRenderObject(find.byType(VerticalDivider));
    // Container widgets wrap its child in an DecoratedBox widget, which in turn
    // is wrapped by a Padding widget. The Padding widget provides these
    // indentations.
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.height, 10.0 + decoratedBox.size.height);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: VerticalDivider(
            endIndent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.vertical, 10.0);
    divider = tester.firstRenderObject(find.byType(VerticalDivider));
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.height, decoratedBox.size.height + 10.0);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: VerticalDivider(
            indent: 10.0,
            endIndent: 10.0,
          ),
        ),
      ),
    );

    expect(tester.firstWidget<Padding>(find.byType(Padding)).padding.vertical, 20.0);
    divider = tester.firstRenderObject(find.byType(VerticalDivider));
    decoratedBox = tester.firstRenderObject(find.byType(DecoratedBox));
    expect(divider.size.height, 10.0 + decoratedBox.size.height + 10.0);
  });
}
