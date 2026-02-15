// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests error.dart's usage via ErrorWidget.
void main() {
  const errorMessage = 'Some error message';

  testWidgets('test draw error paragraph', (WidgetTester tester) async {
    await tester.pumpWidget(ErrorWidget(Exception(errorMessage)));
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 600.0))
        ..paragraph(offset: const Offset(64.0, 96.0)),
    );

    final Widget error = Builder(builder: (BuildContext context) => throw 'pillow');

    await tester.pumpWidget(Center(child: SizedBox(width: 100.0, child: error)));
    expect(tester.takeException(), 'pillow');
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(rect: const Rect.fromLTWH(0.0, 0.0, 100.0, 600.0))
        ..paragraph(offset: const Offset(0.0, 96.0)),
    );

    await tester.pumpWidget(Center(child: SizedBox(height: 100.0, child: error)));
    expect(tester.takeException(), null);

    await tester.pumpWidget(
      Center(
        child: SizedBox(key: UniqueKey(), height: 100.0, child: error),
      ),
    );
    expect(tester.takeException(), 'pillow');
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 100.0))
        ..paragraph(offset: const Offset(64.0, 0.0)),
    );

    RenderErrorBox.minimumWidth = 800.0;
    await tester.pumpWidget(Center(child: error));
    expect(tester.takeException(), 'pillow');
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 600.0))
        ..paragraph(offset: const Offset(0.0, 96.0)),
    );

    await tester.pumpWidget(Center(child: error));
    expect(tester.takeException(), null);
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(color: const Color(0xF0900000))
        ..paragraph(),
    );

    RenderErrorBox.backgroundColor = const Color(0xFF112233);
    await tester.pumpWidget(Center(child: error));
    expect(tester.takeException(), null);
    expect(
      find.byType(ErrorWidget),
      paints
        ..rect(color: const Color(0xFF112233))
        ..paragraph(),
    );
  });
}
