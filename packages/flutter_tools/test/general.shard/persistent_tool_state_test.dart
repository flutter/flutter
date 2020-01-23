// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('state can be set and persists', () => testbed.run(() {
    final File stateFile = globals.fs.file('.flutter_tool_state');
    final PersistentToolState state1 = PersistentToolState(stateFile);
    expect(state1.redisplayWelcomeMessage, null);
    state1.redisplayWelcomeMessage = true;
    expect(stateFile.existsSync(), true);
    expect(state1.redisplayWelcomeMessage, true);
    state1.redisplayWelcomeMessage = false;
    expect(state1.redisplayWelcomeMessage, false);

    final PersistentToolState state2 = PersistentToolState(stateFile);
    expect(state2.redisplayWelcomeMessage, false);
  }));
}
