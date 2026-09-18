// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/commands/generate.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  late BufferLogger logger;
  late FakeToolContext toolContext;

  setUp(() {
    logger = BufferLogger.test();
    toolContext = FakeToolContext(logger: logger);
  });

  testWithoutContext('generate command prints deprecation error and returns fail', () async {
    final command = GenerateCommand(toolContext: toolContext);
    final FlutterCommandResult result = await command.runCommand();
    expect(result.exitStatus, ExitStatus.fail);
    expect(
      logger.errorText,
      contains('"flutter generate" is deprecated, use "dart run build_runner" instead.'),
    );
  });

  testWithoutContext('generate command is hidden', () {
    final command = GenerateCommand(toolContext: toolContext);
    expect(command.hidden, isTrue);
  });
}
