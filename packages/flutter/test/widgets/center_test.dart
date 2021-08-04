// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TODO(Piinks): Remove this after testWidgets'
  //   - state leaks/test dependencies have been fixed.
  //   - or tests are refactored for platform specific behaviors
  defaultPlatformVariant = null;

  testWidgets('Can be placed in an infinite box', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(children: const <Widget>[Center()]),
      ),
    );
  });
}
