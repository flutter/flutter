// @dart = 2.6
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

void main() {}

@pragma('vm:entry-point')
void frameCallback(FrameInfo info) {
  print('called back');
}
