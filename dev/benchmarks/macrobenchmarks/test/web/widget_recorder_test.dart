// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobenchmarks/src/web/recorder.dart';

void main() {
  test('startup failures release engine benchmark listeners', () async {
    final recorder = _FailingRecorder();
    await recorder.setUpAll();
    addTearDown(() {
      stopListeningToEngineBenchmarkValues(kProfilePresentationDuration);
      stopListeningToEngineBenchmarkValues(kProfilePrerollFrame);
      stopListeningToEngineBenchmarkValues(kProfileApplyFrame);
    });

    for (var attempt = 0; attempt < 2; attempt++) {
      await expectLater(recorder.run(), throwsA(same(recorder.failure)));
    }
    expect(recorder.profile, isNull);
  });
}

class _FailingRecorder extends WidgetRecorder {
  _FailingRecorder() : super(name: 'startup_failure');

  final failure = StateError('Recording startup failed');

  @override
  Widget createWidget() => const SizedBox();

  @override
  void registerDidStop(VoidCallback cb) {
    throw failure;
  }
}
