// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_

#include <functional>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"
#include "flutter/shell/platform/embedder/embedder_surface_gl.h"
#include "flutter/shell/platform/embedder/embedder_surface_software.h"

namespace shell {

class PlatformViewEmbedder final : public PlatformView {
 public:
  using PlatformMessageResponseCallback =
      std::function<void(fml::RefPtr<blink::PlatformMessage>)>;

  struct PlatformDispatchTable {
    PlatformMessageResponseCallback
        platform_message_response_callback;  // optional
  };

  // Creates a platform view that sets up an OpenGL rasterizer.
  PlatformViewEmbedder(PlatformView::Delegate& delegate,
                       blink::TaskRunners task_runners,
                       EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table,
                       bool fbo_reset_after_present,
                       PlatformDispatchTable platform_dispatch_table);

  // Create a platform view that sets up a software rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      blink::TaskRunners task_runners,
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table,
      PlatformDispatchTable platform_dispatch_table);

  ~PlatformViewEmbedder() override;

  // |shell::PlatformView|
  void HandlePlatformMessage(
      fml::RefPtr<blink::PlatformMessage> message) override;

 private:
  std::unique_ptr<EmbedderSurface> embedder_surface_;
  PlatformDispatchTable platform_dispatch_table_;

  // |shell::PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  sk_sp<GrContext> CreateResourceContext() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
