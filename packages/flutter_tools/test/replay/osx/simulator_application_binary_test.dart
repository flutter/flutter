// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/run.dart';
import 'package:path/path.dart' as p;

import '../common.dart';

void main() {
  testReplay('runsWithoutError', () async {
    final String replay = p.join(replayBase, 'osx', 'simulator_application_binary');
    expectProcessExits(
      new RunCommand(),
      args: <String>[
        '--no-hot',
        '--no-resident',
        '--device-id=iPhone',
        '--use-application-binary=hello_flutter.ipa',
        '--replay-from=$replay',
      ],
    );
  });
}
