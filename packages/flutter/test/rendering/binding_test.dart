// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('handleMetricsChanged does not scheduleForcedFrame unless there is a child to the renderView', () async {
    expect(SchedulerBinding.instance.hasScheduledFrame, false);
    RendererBinding.instance.handleMetricsChanged();
    expect(SchedulerBinding.instance.hasScheduledFrame, false);

    RendererBinding.instance.renderView.child = RenderLimitedBox();
    RendererBinding.instance.handleMetricsChanged();
    expect(SchedulerBinding.instance.hasScheduledFrame, true);
  });

  test('debugDumpSemantics prints explanation when semantics are unavailable', () {
    final List<String?> log = <String?>[];
    debugPrint = (String? message, {int? wrapWidth}) {
      log.add(message);
    };
    debugDumpSemanticsTree();
    expect(log, hasLength(1));
    expect(
      log.single,
      'Semantics not generated.\n'
        'For performance reasons, the framework only generates semantics when asked to do so by the platform.\n'
        'Usually, platforms only ask for semantics when assistive technologies (like screen readers) are running.\n'
        'To generate semantics, try turning on an assistive technology (like VoiceOver or TalkBack) on your device.'
    );
  });
}
