// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import '../../../services/isolate.dart' as demo;

void main() {
  testWidgets('layers smoketest for services/isolate.dart', (WidgetTester tester) async {
    demo.main();
  });
}
