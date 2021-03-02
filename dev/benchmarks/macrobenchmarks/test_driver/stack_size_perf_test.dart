// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JsonEncoder;

import 'package:flutter_driver/flutter_driver.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:macrobenchmarks/common.dart';

import 'util.dart';

const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

void main() {
  test('stack_size', () async {
    int stackSizeInBytes;
    await runDriverTestForRoute(kStackSizeRouteName, (FlutterDriver driver) async {
      final String stackSize = await driver.getText(find.byValueKey(kStackSizeKey));
      expect(stackSize.isNotEmpty, isTrue);
      stackSizeInBytes = int.parse(stackSize);
    });

    expect(stackSizeInBytes > 0, isTrue);

    await fs.directory(testOutputsDirectory).create(recursive: true);
    final File file = fs.file(path.join(testOutputsDirectory, 'stack_size.json'));
    await file.writeAsString(_encodeJson(<String, dynamic>{
      'stack_size': stackSizeInBytes,
    }));
  }, timeout: const Timeout(kTimeout));
}

String _encodeJson(Map<String, dynamic> jsonObject) {
  return _prettyEncoder.convert(jsonObject);
}
