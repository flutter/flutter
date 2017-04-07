// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('toString control test', (WidgetTester tester) async {
    final Widget widget = new FadeTransition(
      opacity: kAlwaysCompleteAnimation,
      child: const Text('Ready'),
    );
    expect(widget.toString, isNot(throwsException));
  });
}
