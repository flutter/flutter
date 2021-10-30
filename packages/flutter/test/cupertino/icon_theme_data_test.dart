// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IconTheme.of works', (WidgetTester tester) async {
    const IconThemeData data = IconThemeData(color: Color(0xAAAAAAAA), opacity: 0.5, size: 16.0);

    late IconThemeData retrieved;
    await tester.pumpWidget(
      IconTheme(data: data, child: Builder(builder: (BuildContext context) {
        retrieved = IconTheme.of(context);
        return const SizedBox();
      })),
    );

    expect(retrieved, data);

    await tester.pumpWidget(
      IconTheme(
        data: const CupertinoIconThemeData(color: CupertinoColors.systemBlue),
        child: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Builder(builder: (BuildContext context) {
              retrieved = IconTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(retrieved.color, isSameColorAs(CupertinoColors.systemBlue.darkColor));
  });
}
