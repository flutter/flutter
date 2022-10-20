// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/macros.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      GPU tracer configuration.
///
struct GPUTracerConfiguration {
  /// This param is for metal backend.
  /// When this value is true, a gpu trace file will be saved in devices when
  /// metal frame capture finishes. Otherwise, the Xcode will automatically open
  /// and show trace result.
  ///
  bool mtl_frame_capture_save_trace_as_document = false;
};

//------------------------------------------------------------------------------
/// @brief      A GPU tracer to trace gpu workflow during rendering.
///
class GPUTracer {
 public:
  virtual ~GPUTracer();

  //----------------------------------------------------------------------------
  /// @brief      Start capturing frame. This method should only be called when
  ///             developing.
  ///
  /// @param[in]  configuration  The configuration passed in for capture.
  ///
  /// @return The operation successful or not.
  ///
  virtual bool StartCapturingFrame(GPUTracerConfiguration configuration);

  //----------------------------------------------------------------------------
  /// @brief      Stop capturing frame. This should only be called when
  ///             developing.
  ///
  /// @return The operation successful or not.
  ///
  virtual bool StopCapturingFrame();

 protected:
  GPUTracer();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(GPUTracer);
};

}  // namespace impeller
