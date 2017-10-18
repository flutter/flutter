// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_CONTROLLER_H_
#define FLUTTER_RUNTIME_DART_CONTROLLER_H_

#include <memory>
#include <vector>

#include "dart/runtime/include/dart_api.h"
#include "lib/fxl/macros.h"
#include "lib/tonic/logging/dart_error.h"

namespace blink {
class UIDartState;

class DartController {
 public:
  DartController();
  ~DartController();

  tonic::DartErrorHandleType RunFromKernel(
      const std::vector<uint8_t>& kernel,
      const std::string& entrypoint = main_entrypoint_);
  tonic::DartErrorHandleType RunFromPrecompiledSnapshot(
      const std::string& entrypoint = main_entrypoint_);
  tonic::DartErrorHandleType RunFromScriptSnapshot(
      const uint8_t* buffer,
      size_t size,
      const std::string& entrypoint = main_entrypoint_);
  tonic::DartErrorHandleType RunFromSource(const std::string& main,
                                           const std::string& packages);

  void CreateIsolateFor(const std::string& script_uri,
                        const uint8_t* isolate_snapshot_data,
                        const uint8_t* isolate_snapshot_instr,
                        const std::vector<uint8_t>& platform_kernel,
                        std::unique_ptr<UIDartState> ui_dart_state);

  UIDartState* dart_state() const { return ui_dart_state_; }

  void IsolateShuttingDown();

 private:
  bool SendStartMessage(Dart_Handle root_library,
                        const std::string& entrypoint = main_entrypoint_);

  static const std::string main_entrypoint_;

  // The DartState associated with the main isolate.  This is not deleted
  // during isolate shutdown, instead it is deleted when the controller
  // object is deleted.
  UIDartState* ui_dart_state_;

  // Kernel binary image of platform core libraries. This is copied and
  // maintained for dart script lifespan, so that kernel loading mechanism can
  // incrementally build the dart objects from it.
  uint8_t* platform_kernel_bytes;

  FXL_DISALLOW_COPY_AND_ASSIGN(DartController);
};
}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_CONTROLLER_H_
