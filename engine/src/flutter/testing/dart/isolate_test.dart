// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  test('Invalid isolate URI', () async {
    final Future<Isolate> isolate = Isolate.spawnUri(Uri.parse('http://127.0.0.1/foo.dart'), <String>[], null);
    expect(() async => isolate, throwsA(const TypeMatcher<IsolateSpawnException>()));
  });
}
