// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, FlutterErrorDetails> errors = <String, FlutterErrorDetails>{};
  reportTestException = (FlutterErrorDetails details, String testDescription) {
    errors[testDescription] = details;
  };

  tearDownAll(() async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runTest(() async {
      throw 'test error';
    }, () {});

    //print(flutterErrorDetails == null ? 'null!!!' : 'got it!');
    binding.postTest();
  });

  test('empty', () {
    print('test');
  });
}
