// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugCheckHasMaterial control test', (WidgetTester tester) async {
    await tester.pumpWidget(const ListTile());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), startsWith('ListTile widgets require a Material widget ancestor, but we couldn\'t find any.\n'));
    expect(exception.toString(), endsWith(':\n  ListTile\nThe ancestors of this widget were:\n  [root]'));
  });
}
