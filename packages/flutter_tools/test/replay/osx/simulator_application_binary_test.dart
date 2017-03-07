// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../common.dart';

void main() {
  testReplay('runsWithoutError', () async {
    expectProcessExits(<String>[
      'run',
      '--no-hot',
      '--no-resident',
      '--device-id=iPhone',
      '--use-application-binary=hello_flutter.ipa',
      '--replay-from=test/replay/osx/simulator_application_binary',
    ]);
  });
}
