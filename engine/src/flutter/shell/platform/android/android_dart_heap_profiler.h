// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_H_

namespace flutter {

/// Installs the Android Perfetto (`traced_producer` / `"android.heapprofd"`)
/// `DartHeapProfilerDelegate` when enabled at build time and supported by
/// `api_level`.
void InitializeAndroidDartHeapProfiler(int api_level);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_DART_HEAP_PROFILER_H_
