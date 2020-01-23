// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import '../rendering/src/sector_layout.dart';
import '../widgets/sectors.dart';

void main() {
  test('SectorConstraints', () {
    expect(const SectorConstraints().isTight, isFalse);
  });

  testWidgets('Sector Sixes', (WidgetTester tester) async {
    await tester.pumpWidget(SectorApp());
  });
}
