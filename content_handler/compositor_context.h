// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/flow/compositor_context.h"
#include "garnet/public/lib/ui/scenic/fidl/scenic.fidl-common.h"
#include "lib/fxl/macros.h"
#include "session_connection.h"

namespace flutter {

// Holds composition specific state and bindings specific to composition on
// Fuchsia.
class CompositorContext final : public flow::CompositorContext {
 public:
  CompositorContext(const ui::ScenicPtr& scenic,
                    std::string debug_label,
                    zx::eventpair import_token,
                    OnMetricsUpdate session_metrics_did_change_callback,
                    fxl::Closure session_error_callback);

  ~CompositorContext() override;

 private:
  const std::string debug_label_;
  SessionConnection session_connection_;

  // |flow::CompositorContext|
  std::unique_ptr<ScopedFrame> AcquireFrame(
      GrContext* gr_context,
      SkCanvas* canvas,
      bool instrumentation_enabled) override;

  FXL_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flutter
