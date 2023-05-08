// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:macrobenchmarks/common.dart';

import 'util.dart';

void main() {
  macroPerfTest(
    'simple_animation_perf',
    kSimpleAnimationRouteName,
    pageDelay: const Duration(seconds: 10),
    duration: const Duration(seconds: 10),
  );
}
