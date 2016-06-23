// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.resetEpoch();
  });

  test('toString control test', () {
    expect(kAlwaysCompleteAnimation.toString(), isOneLineDescription);
    expect(kAlwaysDismissedAnimation.toString(), isOneLineDescription);
  });

  test('toString control test', () {
    ProxyAnimation animation = new ProxyAnimation();
    expect(animation.value, 0.0);
    expect(animation.status, AnimationStatus.dismissed);
    expect(animation.toString(), isOneLineDescription);
    animation.parent = kAlwaysDismissedAnimation;
    expect(animation.toString(), isOneLineDescription);
  });
}
