// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../src/common.dart';
import 'transition_test_utils.dart';

void main() {
  testWithoutContext('runFlutter forcefully kills a hung process on timeout', () async {
    final stopwatch = Stopwatch()..start();
    
    // We run 'daemon' which will hang indefinitely because it does not exit
    // when receiving 'q' on stdin.
    // We set expectedMaxDuration to 1 second. The force-kill grace period is 5 seconds.
    // So the total execution time must be around 6-7 seconds, and it must throw a TestFailure.
    bool threwTestFailure = false;
    try {
      await runFlutter(
        <String>['daemon'],
        // run in the directory containing packages/flutter_tools
        '../../', 
        <Transition>[Barrier('This will never appear')], // Missed transition ensures failure
        expectedMaxDuration: const Duration(seconds: 1),
      );
    } on TestFailure catch (e) {
      threwTestFailure = true;
      expect(e.message, contains('Missed some expected transitions'));
    }
    
    expect(threwTestFailure, isTrue);
    
    final elapsedSeconds = stopwatch.elapsed.inSeconds;
    print('Test completed in $elapsedSeconds seconds.');
    
    // It must have taken more than the 1s timeout + 5s force kill grace period (6s total)
    // but significantly less than a hang (which would be 10+ minutes).
    expect(elapsedSeconds, greaterThanOrEqualTo(5));
    expect(elapsedSeconds, lessThan(15));
  });
}
