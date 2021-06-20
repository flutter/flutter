// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'dart:io' as io;

import 'package:githooks/githooks.dart';
import 'package:litetest/litetest.dart';

void main() {
  test('Fails gracefully without a command', () async {
    int? result;
    try {
      result = await run(<String>[]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully with an unknown command', () async {
    int? result;
    try {
      result = await run(<String>['blah']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully without --flutter', () async {
    int? result;
    try {
      result = await run(<String>['pre-push']);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter is not an absolute path', () async {
    int? result;
    try {
      result = await run(<String>[
        'pre-push',
        '--flutter',
        'non/absolute',
      ]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });

  test('Fails gracefully when --flutter does not exist', () async {
    int? result;
    try {
      result = await run(<String>[
        'pre-push',
        '--flutter',
        if (io.Platform.isWindows) r'C:\does\not\exist'
        else '/does/not/exist',
      ]);
    } catch (e, st) {
      fail('Unexpected exception: $e\n$st');
    }
    expect(result, equals(1));
  });
}
