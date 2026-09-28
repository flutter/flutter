// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/windows/popup.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Calling popup main returns normally', (
    WidgetTester tester,
  ) async {
    expect(() => example.main(), returnsNormally);
  });
}
