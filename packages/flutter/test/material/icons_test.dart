// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IconData object test', (WidgetTester tester) async {
    expect(Icons.account_balance, isNot(equals(Icons.account_box)));
    expect(Icons.account_balance.hashCode, isNot(equals(Icons.account_box.hashCode)));
    expect(Icons.account_balance, hasOneLineDescription);
  });

  testWidgets('Icons specify the material font', (WidgetTester tester) async {
    expect(Icons.clear.fontFamily, 'MaterialIcons');
    expect(Icons.search.fontFamily, 'MaterialIcons');
  });

  testWidgets('Adaptive icons are correct on cupertino platforms',
      (WidgetTester tester) async {
    expect(Icons.adaptive.arrow_back, Icons.arrow_back_ios);
    expect(Icons.adaptive.arrow_back_outlined, Icons.arrow_back_ios_outlined);
  },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }));

  testWidgets(
    'Adaptive icons are correct on non-cupertino platforms',
    (WidgetTester tester) async {
      expect(Icons.adaptive.arrow_back, Icons.arrow_back);
      expect(Icons.adaptive.arrow_back_outlined, Icons.arrow_back_outlined);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.fuchsia,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );
}
