// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_

#include <functional>

#include "flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_surface.h"
#include "flutter/shell/platform/embedder/embedder_surface_software.h"
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/shell/platform/embedder/embedder_surface_gl_impeller.h"
#include "flutter/shell/platform/embedder/embedder_surface_gl_skia.h"
#endif

#ifdef SHELL_ENABLE_METAL
#include "flutter/shell/platform/embedder/embedder_surface_metal_skia.h"
#endif

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/shell/platform/embedder/embedder_surface_vulkan.h"
#ifdef IMPELLER_SUPPORTS_RENDERING
#include "flutter/shell/platform/embedder/embedder_surface_vulkan_impeller.h"
#endif  // IMPELLER_SUPPORTS_RENDERING
#endif

namespace flutter {

class PlatformViewEmbedder final : public PlatformView {
 public:
  using UpdateSemanticsCallback =
      std::function<void(int64_t view_id,
                         flutter::SemanticsNodeUpdates update,
                         flutter::CustomAccessibilityActionUpdates actions)>;
  using PlatformMessageResponseCallback =
      std::function<void(std::unique_ptr<PlatformMessage>)>;
  using PlatformMessageResponseCompletionCallback =
      std::function<void(int response_id,
                         std::unique_ptr<fml::Mapping> mapping)>;
  using PlatformMessageEmptyResponseCompletionCallback =
      std::function<void(int response_id)>;
  using ComputePlatformResolvedLocaleCallback =
      std::function<std::unique_ptr<std::vector<std::string>>(
          const std::vector<std::string>& supported_locale_data)>;
  using OnPreEngineRestartCallback = std::function<void()>;
  using ChanneUpdateCallback = std::function<void(const std::string&, bool)>;
  using ViewFocusChangeRequestCallback =
      std::function<void(const ViewFocusChangeRequest&)>;
  using RequestDartDeferredLibraryCallback =
      std::function<void(intptr_t loading_unit_id)>;
  using DartDeferredLibraryLoadingUnitCallback =
      std::function<void(int64_t loading_unit_id)>;
  using GetScaledFontSizeCallback =
      std::function<double(double unscaled_font_size, int configuration_id)>;
  using CreateVSyncWaiterCallback =
      std::function<std::unique_ptr<VsyncWaiter>()>;

  struct PlatformDispatchTable {
    UpdateSemanticsCallback update_semantics_callback;  // optional
    PlatformMessageResponseCallback
        platform_message_response_callback;             // optional
    VsyncWaiterEmbedder::VsyncCallback vsync_callback;  // optional
    ComputePlatformResolvedLocaleCallback
        compute_platform_resolved_locale_callback;
    OnPreEngineRestartCallback on_pre_engine_restart_callback;  // optional
    ChanneUpdateCallback on_channel_update;                     // optional
    ViewFocusChangeRequestCallback
        view_focus_change_request_callback;  // optional
    DartDeferredLibraryLoadingUnitCallback
        dart_deferred_library_loading_unit_callback;          // optional
    GetScaledFontSizeCallback get_scaled_font_size_callback;  // optional
    VoidCallback raster_context_setup_callback = nullptr;     // optional
    VoidCallback raster_context_teardown_callback = nullptr;  // optional
    void* raster_context_user_data = nullptr;                 // optional
    PlatformMessageResponseCompletionCallback
        platform_message_response_completion_callback;  // optional
    PlatformMessageEmptyResponseCompletionCallback
        platform_message_empty_response_completion_callback;  // optional
    RequestDartDeferredLibraryCallback
        request_dart_deferred_library_callback;              // optional
    CreateVSyncWaiterCallback create_vsync_waiter_callback;  // optional
    std::function<void(std::string)>
        set_application_locale_callback;                            // optional
    std::function<void(bool)> set_semantics_tree_enabled_callback;  // optional
    std::shared_ptr<PlatformMessageHandler>
        custom_platform_message_handler;  // optional
  };

  // Create a platform view that sets up a software rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      const EmbedderSurfaceSoftware::SoftwareDispatchTable&
          software_dispatch_table,
      PlatformDispatchTable platform_dispatch_table,
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder);

#ifdef SHELL_ENABLE_GL
  // Creates a platform view that sets up an OpenGL rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      std::unique_ptr<EmbedderSurface> embedder_surface,
      PlatformDispatchTable platform_dispatch_table,
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder);
#endif

#ifdef SHELL_ENABLE_METAL
  // Creates a platform view that sets up an metal rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      std::unique_ptr<EmbedderSurface> embedder_surface,
      PlatformDispatchTable platform_dispatch_table,
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder);
#endif

#ifdef SHELL_ENABLE_VULKAN
  // Creates a platform view that sets up an Vulkan rasterizer.
  PlatformViewEmbedder(
      PlatformView::Delegate& delegate,
      const flutter::TaskRunners& task_runners,
      std::unique_ptr<EmbedderSurfaceVulkan> embedder_surface,
      PlatformDispatchTable platform_dispatch_table,
      std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder);
#endif

  ~PlatformViewEmbedder() override;

  // |PlatformView|
  void NotifyCreated() override;

  // |PlatformView|
  void NotifyDestroyed() override;

  // |PlatformView|
  void UpdateSemantics(
      int64_t view_id,
      flutter::SemanticsNodeUpdates update,
      flutter::CustomAccessibilityActionUpdates actions) override;

  // |PlatformView|
  void HandlePlatformMessage(std::unique_ptr<PlatformMessage> message) override;

  // |PlatformView|
  std::shared_ptr<PlatformMessageHandler> GetPlatformMessageHandler()
      const override;

  // |PlatformView|
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) override;

  // |PlatformView|
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) override;

  void InvokePlatformMessageResponseCallback(
      int response_id,
      std::unique_ptr<fml::Mapping> mapping);

  void InvokePlatformMessageEmptyResponseCallback(int response_id);

 private:
  class EmbedderPlatformMessageHandler;
  std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder_;
  std::unique_ptr<EmbedderSurface> embedder_surface_;
  std::shared_ptr<PlatformMessageHandler> platform_message_handler_;
  PlatformDispatchTable platform_dispatch_table_;

  // |PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |PlatformView|
  std::shared_ptr<ExternalViewEmbedder> CreateExternalViewEmbedder() override;

  // |PlatformView|
  std::unique_ptr<SnapshotSurfaceProducer> CreateSnapshotSurfaceProducer()
      override;

  // |PlatformView|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

  // |PlatformView|
  void SetupImpellerContext() override;

  // |PlatformView|
  sk_sp<GrDirectContext> CreateResourceContext() const override;

  // |PlatformView|
  void ReleaseResourceContext() const override;

  // |PlatformView|
  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  // |PlatformView|
  void OnPreEngineRestart() const override;

  // |PlatformView|
  std::unique_ptr<std::vector<std::string>> ComputePlatformResolvedLocales(
      const std::vector<std::string>& supported_locale_data) override;

  // |PlatformView|
  void RequestDartDeferredLibrary(intptr_t loading_unit_id) override;

  // |PlatformView|
  double GetScaledFontSize(double unscaled_font_size,
                           int configuration_id) const override;

  // |PlatformView|
  void SetApplicationLocale(std::string locale) override;

  // |PlatformView|
  void SetSemanticsTreeEnabled(bool enabled) override;

  // |PlatformView|
  void SendChannelUpdate(const std::string& name, bool listening) override;

  // |PlatformView|
  void RequestViewFocusChange(const ViewFocusChangeRequest& request) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
