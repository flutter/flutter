// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import '../../lib/gpu/lib/gpu.dart' as gpu;

void main() {}

@pragma('vm:entry-point')
void sayHi() {
  print('Hi');
}

@pragma('vm:entry-point')
void instantiateDefaultContext() {
  // ignore: unused_local_variable
  final gpu.GpuContext context = gpu.gpuContext;
}
