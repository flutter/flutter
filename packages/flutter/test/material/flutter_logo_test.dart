// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('Flutter Logo golden test', (WidgetTester tester) async {
    final Key logo = UniqueKey();
    await tester.pumpWidget(FlutterLogo(key: logo));

    await expectLater(
      find.byKey(logo),
      matchesGoldenFile('flutter_logo.png'),
    );
  });
}
