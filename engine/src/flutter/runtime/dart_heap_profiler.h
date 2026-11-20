// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_
#define FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_

#include "flutter/fml/macros.h"

namespace flutter {

/// Bridges Dart's sampling heap profiler (`Dart_*HeapSampling*` C API) with
/// Android's system Perfetto daemon (`/dev/socket/traced_producer`) using
/// Perfetto's `SharedMemoryABI` and `protozero`.
class DartHeapProfiler {
 public:
  /// Registers Dart heap sampling callbacks and starts the background
  /// `traced_producer` client thread on supported Android devices.
  static void OnDartVMInitialized();

  /// Disables Dart heap sampling before `Dart_Cleanup()` tears down the VM.
  static void OnDartVMCleanup();

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(DartHeapProfiler);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_
