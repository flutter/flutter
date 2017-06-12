// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Can set opacity for an Icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      new IconTheme(
        data: new IconThemeData(
          color: Colors.green[500],
          opacity: 0.5
        ),
        child: const Icon(Icons.add)
      )
    );
    final RichText text = tester.widget(find.byType(RichText));
    expect(text.text.style.color, equals(Colors.green[500].withOpacity(0.5)));
  });
}
