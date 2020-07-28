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
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

namespace flutter {

class PlatformViewEmbedder final : public PlatformView {
 public:
  using UpdateSemanticsNodesCallback =
      std::function<void(flutter::SemanticsNodeUpdates update)>;
  using UpdateSemanticsCustomActionsCallback =
      std::function<void(flutter::CustomAccessibilityActionUpdates actions)>;
  using PlatformMessageResponseCallback =
      std::function<void(fml::RefPtr<flutter::PlatformMessage>)>;
  using ComputePlatformResolvedLocaleCallback =
      std::function<std::unique_ptr<std::vector<std::string>>(
          const std::vector<std::string>& supported_locale_data)>;

  struct PlatformDispatchTable {
    UpdateSemanticsNodesCallback update_semantics_nodes_callback;  // optional
    UpdateSemanticsCustomActionsCallback
        update_semantics_custom_actions_callback;  // optional
    PlatformMessageResponseCallback
        platform_message_response_callback;             // optional
    VsyncWaiterEmbedder::VsyncCallback vsync_callback;  // optional
    ComputePlatformResolvedLocaleCallback
        compute_platform_resolved_locale_callback;
  };

  // Creates a platform view that sets up an OpenGL rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      flutter::TaskRunners task_runners,
      EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table,
      bool fbo_reset_after_present,
      PlatformDispatchTable platform_dispatch_table,
      std::unique_ptr<EmbedderExternalViewEmbedder> external_view_embedder);

  // Create a platform view that sets up a software rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      flutter::TaskRunners task_runners,
      EmbedderSurfaceSoftware::SoftwareDispatchTable software_dispatch_table,
      PlatformDispatchTable platform_dispatch_table,
      std::unique_ptr<EmbedderExternalViewEmbedder> external_view_embedder);

  ~PlatformViewEmbedder() override;

  // |PlatformView|
  void UpdateSemantics(
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // |PlatformView|
  void HandlePlatformMessage(
      fml::RefPtr<flutter::PlatformMessage> message) override;

 private:
  std::unique_ptr<EmbedderSurface> embedder_surface_;
  PlatformDispatchTable platform_dispatch_table_;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
