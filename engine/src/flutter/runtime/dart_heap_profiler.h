// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_
#define FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string_view>

#include "flutter/fml/macros.h"

namespace flutter {

/// Platform-implemented backend receiving sampled Dart heap allocation and GC
/// deallocation events from `DartHeapProfiler`.
///
/// Implementations must be thread-safe: `OnSampleCreated` is invoked
/// synchronously on whichever mutator thread triggered a sampled Dart
/// allocation, and `OnSampleDestroyed` is invoked on Dart GC sweeper/scavenger
/// threads.
class DartHeapProfilerDelegate {
 public:
  virtual ~DartHeapProfilerDelegate() = default;

  /// Invoked when the Dart VM finishes initializing (or immediately inside
  /// `DartHeapProfiler::SetDelegate` if the VM is already initialized).
  virtual void OnDartVMInitialized() {}

  /// Invoked when the Dart VM is about to shut down (`Dart_Cleanup`).
  virtual void OnDartVMCleanup() {}

  /// Invoked when the Dart VM samples a heap allocation of `size` bytes for
  /// `class_name` in `isolate_group_id`. Returns an opaque context pointer
  /// later passed to `OnSampleDestroyed` when the object is collected, or
  /// `nullptr` to ignore the sample.
  virtual void* OnSampleCreated(uintptr_t isolate_group_id,
                                std::string_view class_name,
                                size_t size) = 0;

  /// Invoked when a previously sampled object is reclaimed by Dart GC.
  virtual void OnSampleDestroyed(void* sample_context) = 0;
};

/// Platform-agnostic bridge between the Dart VM's sampling heap profiler C API
/// (`Dart_*HeapSampling*`) and a platform `DartHeapProfilerDelegate`.
class DartHeapProfiler {
 public:
  /// Installs (or clears when `nullptr`) the active platform delegate.
  /// Safe to call before or after `OnDartVMInitialized()`.
  static void SetDelegate(std::unique_ptr<DartHeapProfilerDelegate> delegate);

  /// Enables Dart VM heap allocation sampling at `sampling_interval_bytes`.
  /// If called before the Dart VM is initialized, sampling starts automatically
  /// once `OnDartVMInitialized()` runs. Safe to call from any thread.
  static void StartSampling(intptr_t sampling_interval_bytes);

  /// Disables Dart VM heap allocation sampling. Safe to call from any thread.
  static void StopSampling();

  /// Invoked by `DartVMInitializer::Initialize()` after `Dart_Initialize()`.
  static void OnDartVMInitialized();

  /// Invoked by `DartVMInitializer::Cleanup()` before `Dart_Cleanup()`.
  static void OnDartVMCleanup();

 private:
  FML_DISALLOW_IMPLICIT_CONSTRUCTORS(DartHeapProfiler);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_HEAP_PROFILER_H_
