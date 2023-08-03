// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_GPU_H_
#define FLUTTER_LIB_GPU_GPU_H_

#include <cstdint>

#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/dart_wrapper_info.h"

#if FML_OS_WIN
#define FLUTTER_EXPORT __declspec(dllexport)
#else  // FML_OS_WIN
#define FLUTTER_EXPORT __attribute__((visibility("default")))
#endif  // FML_OS_WIN

namespace flutter {

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
class FlutterGpuTestClass
    : public RefCountedDartWrappable<FlutterGpuTestClass> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(FlutterGpuTestClass);

 public:
  ~FlutterGpuTestClass() override;
};

}  // namespace flutter

extern "C" {

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
FLUTTER_EXPORT
extern uint32_t InternalFlutterGpuTestProc();

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
FLUTTER_EXPORT
extern Dart_Handle InternalFlutterGpuTestProcWithCallback(Dart_Handle callback);

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
FLUTTER_EXPORT
extern void InternalFlutterGpuTestClass_Create(Dart_Handle wrapper);

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
FLUTTER_EXPORT
extern void InternalFlutterGpuTestClass_Method(
    flutter::FlutterGpuTestClass* self,
    int something);

}  // extern "C"

#endif  // FLUTTER_LIB_GPU_GPU_H_
