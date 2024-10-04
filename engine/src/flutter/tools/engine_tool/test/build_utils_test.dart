// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/build_utils.dart';
import 'package:engine_tool/src/commands/flags.dart';
import 'package:test/test.dart';

void main() {
  test('makeRbeConfig local selects local strategy', () {
    expect(makeRbeConfig(buildStrategyFlagValueLocal),
        equals(const RbeConfig(execStrategy: RbeExecStrategy.local)));
  });

  test('makeRbeConfig remote selects remote strategy', () {
    expect(makeRbeConfig(buildStrategyFlagValueRemote),
        equals(const RbeConfig(execStrategy: RbeExecStrategy.remote)));
  });

  test('makeRbeConfig auto selects racing strategy', () {
    expect(makeRbeConfig(buildStrategyFlagValueAuto).execStrategy,
        equals(RbeExecStrategy.racing));
  });
}
