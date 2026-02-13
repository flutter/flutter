// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world/german.dart' as hello_world;

void main() {
  testWidgets('Hallo Welt test', (WidgetTester tester) async {
    hello_world
        .main(); // startet die App und bereitet einen Fram vor
    await tester.pump(); // Führt den vorbereiteten Frame aus

    expect(
      find.byKey(const Key('title')), // sucht für ein Widget mit den Schlüssel 'title'
      findsOneWidget, // Der Test besteht, sofern ein Widget mit folgendem Schlüssel gefunden wurde
    ); 
    
  });
}
