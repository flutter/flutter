// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/headings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('HeadingsUseCase renders headings at different levels', (WidgetTester tester) async {
    await pumpsUseCase(tester, HeadingsUseCase());
    expect(find.text('Heading level 1'), findsExactly(1));
    expect(find.text('Heading level 2'), findsExactly(1));
    expect(find.text('Heading level 3'), findsExactly(1));
    expect(find.text('Heading level 4'), findsExactly(1));
    expect(find.text('Heading level 5'), findsExactly(1));
    expect(find.text('Heading level 6'), findsExactly(1));
    expect(find.text('This is not a heading'), findsExactly(1));
  });
}
