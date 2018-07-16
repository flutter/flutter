// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextField works correctly when changing helperText', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: const Material(child: const TextField(decoration: const InputDecoration(helperText: 'Awesome')))));
    expect(find.text('Awesome'), findsNWidgets(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Awesome'), findsNWidgets(1));
    await tester.pumpWidget(new MaterialApp(home: const Material(child: const TextField(decoration: const InputDecoration(errorText: 'Awesome')))));
    expect(find.text('Awesome'), findsNWidgets(2));
  });
}