// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NetworkImage non-null url test', () {
    expect(() {
      new NetworkImage(nonconst(null));
    }, throwsAssertionError);
  });
}
