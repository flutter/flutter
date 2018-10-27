// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

/// Unit tests error.dart's usage via ErrorWidget.
void main() {
  const String errorMessage = 'Some error message';

  testWidgets('test draw error paragraph', (WidgetTester tester) async {
    await tester.pumpWidget(ErrorWidget(Exception(errorMessage)));

    expect(find.byType(ErrorWidget), paints
        ..rect(rect: Rect.fromLTWH(0.0, 0.0, 800.0, 600.0))
        ..paragraph(offset: Offset.zero));
  });
}
