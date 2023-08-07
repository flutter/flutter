// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/smoketest.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/dart_wrappable.h"
#include "third_party/tonic/dart_wrapper_info.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
IMPLEMENT_WRAPPERTYPEINFO(gpu, FlutterGpuTestClass);

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
FlutterGpuTestClass::~FlutterGpuTestClass() = default;

}  // namespace flutter

//----------------------------------------------------------------------------
/// Exports
///

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
uint32_t InternalFlutterGpuTestProc() {
  return 1;
}

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
Dart_Handle InternalFlutterGpuTestProcWithCallback(Dart_Handle callback) {
  flutter::UIDartState::ThrowIfUIOperationsProhibited();
  if (!Dart_IsClosure(callback)) {
    return tonic::ToDart("Callback must be a function");
  }

  tonic::DartInvoke(callback, {tonic::ToDart(1234)});

  return Dart_Null();
}

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
void InternalFlutterGpuTestClass_Create(Dart_Handle wrapper) {
  auto res = fml::MakeRefCounted<flutter::FlutterGpuTestClass>();
  res->AssociateWithDartWrapper(wrapper);
  FML_LOG(INFO) << "FlutterGpuTestClass Wrapped.";
}

// TODO(131346): Remove this once we migrate the Dart GPU API into this space.
void InternalFlutterGpuTestClass_Method(flutter::FlutterGpuTestClass* self,
                                        int something) {
  FML_LOG(INFO) << "Something: " << something;
}
