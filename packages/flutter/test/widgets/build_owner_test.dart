// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('BuildOwner.isBuilding is true when the widget tree builds, and false otherwise',
    (WidgetTester tester) async {
      expect(tester.binding.buildOwner.isBuilding, isFalse);

      await tester.pumpWidget(Builder(builder: (BuildContext _) {
        expect(tester.binding.buildOwner.isBuilding, isTrue);
        return Container();
      }));

      expect(tester.binding.buildOwner.isBuilding, isFalse);
    },
  );
}
