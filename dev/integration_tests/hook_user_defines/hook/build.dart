// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    final Object? magicValue = input.userDefines['magic_value'];
    if (magicValue is! int) {
      throw ArgumentError('User-define `magic_value` must be an integer, found: $magicValue.');
    }
    final String packageName = input.packageName;
    final CBuilder cbuilder = CBuilder.library(
      name: packageName,
      assetName: '$packageName.dart',
      sources: <String>['src/$packageName.c'],
      defines: <String, String>{'MAGIC_VALUE': magicValue.toString()},
    );
    await cbuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((LogRecord record) => print(record.message)),
    );
  });
}
