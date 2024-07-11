// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:a11y_assessments/use_cases/text_button.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('text button can run', (WidgetTester tester) async {
    await pumpsUseCase(tester, TextButtonUseCase());
    expect(find.text('Action'), findsExactly(2));
  });
}
