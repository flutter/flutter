// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_NDK_NDK_PROC_TABLE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_NDK_NDK_PROC_TABLE_H_

#include <android/choreographer.h>
#include <android/hardware_buffer.h>
#include <android/surface_control.h>
#include <android/trace.h>
#include <jni.h>

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The NDK functions that the Android embedding calls outside of
///             rendering. Each exists only from some API level on, so they
///             are resolved from libandroid.so at runtime, and a function the
///             device does not have is null.
///
struct NDKProcTable {
  //----------------------------------------------------------------------------
  /// @brief      Resolves every function from `library`. A null library
  ///             leaves every function null.
  ///
  explicit NDKProcTable(const fml::RefPtr<fml::NativeLibrary>& library);

  //----------------------------------------------------------------------------
  /// @return     Whether ATrace reports tracing as enabled. False where
  ///             ATrace_isEnabled is not available.
  ///
  bool TraceIsEnabled() const;

  // The functions are declared with their own pointer types rather than with
  // decltype of the NDK declarations, which carry availability attributes for
  // API levels above the minimum this library is built for.

  // API level 24.
  AChoreographer* (*AChoreographer_getInstance)() = nullptr;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  // API level 24, deprecated at 29. Null where postFrameCallback64 exists,
  // and on 32-bit devices, where the `long` frame time in nanoseconds
  // overflows.
  void (*AChoreographer_postFrameCallback)(
      AChoreographer* choreographer,
      AChoreographer_frameCallback callback,
      void* data) = nullptr;
#pragma GCC diagnostic pop

  // API level 29.
  void (*AChoreographer_postFrameCallback64)(
      AChoreographer* choreographer,
      AChoreographer_frameCallback64 callback,
      void* data) = nullptr;

  // API level 26.
  AHardwareBuffer* (*AHardwareBuffer_fromHardwareBuffer)(
      JNIEnv* env,
      jobject hardware_buffer) = nullptr;

  // API level 34.
  ASurfaceTransaction* (*ASurfaceTransaction_fromJava)(JNIEnv* env,
                                                       jobject transaction) =
      nullptr;

  // API level 23.
  bool (*ATrace_isEnabled)() = nullptr;

 private:
  // Keeps the functions above loaded.
  fml::RefPtr<fml::NativeLibrary> library_;
};

//------------------------------------------------------------------------------
/// @return     The process-wide table, resolved from libandroid.so on first
///             use.
///
const NDKProcTable& GetNDKProcTable();

//------------------------------------------------------------------------------
/// @return     The process-wide table, for tests that swap in fake functions.
///
NDKProcTable& GetMutableNDKProcTableForTesting();

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_NDK_NDK_PROC_TABLE_H_
