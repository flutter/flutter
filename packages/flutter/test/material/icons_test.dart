// Copyright 2016 The Chromium Authors. All rights reserved.
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
}
