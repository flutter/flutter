// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NetworkImage non-null url test', () {
    expect(() {
      final String url = null; // we don't want this instance to be const because otherwise it would throw at compile time.
      new NetworkImage(url);
    }, throwsAssertionError);
  });
}
