// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPOSITOR_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPOSITOR_CONTEXT_H_

#include <memory>

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/scene_update_context.h"
#include "flutter/fml/macros.h"

#include "session_connection.h"
#include "vulkan_surface_producer.h"

namespace flutter_runner {

// Holds composition specific state and bindings specific to composition on
// Fuchsia.
class CompositorContext final : public flutter::CompositorContext {
 public:
  CompositorContext(
      SessionConnection& session_connection,
      VulkanSurfaceProducer& surface_producer,
      std::shared_ptr<flutter::SceneUpdateContext> scene_update_context);

  ~CompositorContext() override;
  void WarmupSkp(sk_sp<SkPicture> picture);

 private:
  SessionConnection& session_connection_;
  VulkanSurfaceProducer& surface_producer_;
  std::shared_ptr<flutter::SceneUpdateContext> scene_update_context_;
  sk_sp<SkSurface> skp_warmup_surface_;

  // |flutter::CompositorContext|
  std::unique_ptr<ScopedFrame> AcquireFrame(
      GrDirectContext* gr_context,
      SkCanvas* canvas,
      flutter::ExternalViewEmbedder* view_embedder,
      const SkMatrix& root_surface_transformation,
      bool instrumentation_enabled,
      bool surface_supports_readback,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flutter_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_COMPOSITOR_CONTEXT_H_
