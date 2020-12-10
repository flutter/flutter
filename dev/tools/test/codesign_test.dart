// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dev_tools/codesign.dart';
import 'package:dev_tools/repository.dart';

import './common.dart';

void main() {
  group('codesign command', () {
    CommandRunner<void> runner;
    setUp(() {
      runner = CommandRunner<void>('codesign-test', '');
      runner.addCommand(
        CodesignCommand(),
      );
    });

    test('blah', () {
    });
  });
}
