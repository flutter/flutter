// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Priority operators control test', () async {
    Priority priority = Priority.idle + (Priority.kMaxOffset + 100);
    expect(priority.value, equals(Priority.idle.value + Priority.kMaxOffset));

    priority = Priority.animation - (Priority.kMaxOffset + 100);
    expect(priority.value, equals(Priority.animation.value - Priority.kMaxOffset));
  });
}
