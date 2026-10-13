// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_

#include <functional>

#include "flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/status_or.h"
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

class PlatformViewEmbedder : public PlatformView {
 public:
  using UpdateSemanticsCallback =
      std::function<void(int64_t view_id,
                         flutter::SemanticsNodeUpdates update,
                         flutter::CustomAccessibilityActionUpdates actions)>;
  using PlatformMessageResponseCallback =
      std::function<void(std::unique_ptr<PlatformMessage>)>;
  using ComputePlatformResolvedLocaleCallback =
      std::function<std::unique_ptr<std::vector<std::string>>(
          const std::vector<std::string>& supported_locale_data)>;
  using OnPreEngineRestartCallback = std::function<void()>;
  using ChanneUpdateCallback = std::function<void(const std::string&, bool)>;
  using ViewFocusChangeRequestCallback =
      std::function<void(const ViewFocusChangeRequest&)>;
  using SetApplicationLocaleCallback = std::function<void(std::string locale)>;
  using SetSemanticsTreeEnabledCallback = std::function<void(bool enabled)>;
  using RequestDartDeferredLibraryCallback =
      std::function<void(intptr_t loading_unit_id)>;
  using GetScaledFontSizeCallback =
      std::function<double(double unscaled_font_size, int configuration_id)>;
  using CreateRenderingSurfaceCallback =
      std::function<std::unique_ptr<Surface>()>;
  using CreateExternalViewEmbedderCallback =
      std::function<std::shared_ptr<ExternalViewEmbedder>()>;
  using CreateSnapshotSurfaceProducerCallback =
      std::function<std::unique_ptr<SnapshotSurfaceProducer>()>;
  using CreateResourceContextCallback = std::function<sk_sp<GrDirectContext>()>;
  using MakeResourceCurrentCallback = std::function<bool()>;
  using ReleaseResourceContextCallback = std::function<void()>;
  using GetImpellerContextCallback =
      std::function<std::shared_ptr<impeller::Context>()>;
  using SetupImpellerContextCallback = std::function<void()>;

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
        view_focus_change_request_callback;                        // optional
    SetApplicationLocaleCallback set_application_locale_callback;  // optional
    SetSemanticsTreeEnabledCallback
        set_semantics_tree_enabled_callback;  // optional
    RequestDartDeferredLibraryCallback
        request_dart_deferred_library_callback;               // optional
    GetScaledFontSizeCallback get_scaled_font_size_callback;  // optional
    CreateRenderingSurfaceCallback
        create_rendering_surface_callback;  // optional
    CreateExternalViewEmbedderCallback
        create_external_view_embedder_callback;  // optional
    CreateSnapshotSurfaceProducerCallback
        create_snapshot_surface_producer_callback;                   // optional
    CreateResourceContextCallback create_resource_context_callback;  // optional
    MakeResourceCurrentCallback make_resource_current_callback;      // optional
    ReleaseResourceContextCallback
        release_resource_context_callback;                         // optional
    GetImpellerContextCallback get_impeller_context_callback;      // optional
    SetupImpellerContextCallback setup_impeller_context_callback;  // optional
    // If true, `platform_message_response_callback` runs on the thread that
    // sends each message (the UI thread or a background isolate's thread)
    // instead of on the platform thread. See
    // `FlutterProjectArgs.platform_message_callback_on_sending_thread`.
    bool platform_message_callback_on_sending_thread = false;
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

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Creates a platform view for an embedding that renders on its
  ///             own. There is no embedder surface and no external view
  ///             embedder; everything comes from `platform_dispatch_table`,
  ///             including any surface, external view embedder, and rendering
  ///             context callbacks.
  ///
  PlatformViewEmbedder(PlatformView::Delegate& delegate,
                       const flutter::TaskRunners& task_runners,
                       PlatformDispatchTable platform_dispatch_table,
                       std::shared_ptr<PlatformMessageHandler>
                           platform_message_handler = nullptr);

 private:
  class EmbedderPlatformMessageHandler;
  class SendingThreadPlatformMessageHandler;
  std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder_;
  std::unique_ptr<EmbedderSurface> embedder_surface_;
  // Set when the dispatch table asks for messages on the sending thread. The
  // same object as `platform_message_handler_`; kept typed so that the
  // destructor can detach it.
  std::shared_ptr<SendingThreadPlatformMessageHandler>
      sending_thread_message_handler_;
  std::shared_ptr<PlatformMessageHandler> platform_message_handler_;
  PlatformDispatchTable platform_dispatch_table_;

  // Creates the handler that delivers platform messages according to
  // `platform_dispatch_table`, and sets `sending_thread_message_handler_` if
  // it delivers them on the sending thread.
  std::shared_ptr<PlatformMessageHandler> CreatePlatformMessageHandler(
      const PlatformDispatchTable& platform_dispatch_table,
      const flutter::TaskRunners& task_runners);

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
  void SetApplicationLocale(std::string locale) override;

  // |PlatformView|
  void SetSemanticsTreeEnabled(bool enabled) override;

  // |PlatformView|
  void RequestDartDeferredLibrary(intptr_t loading_unit_id) override;

  // |PlatformView|
  double GetScaledFontSize(double unscaled_font_size,
                           int configuration_id) const override;

  // |PlatformView|
  void SendChannelUpdate(const std::string& name, bool listening) override;

  // |PlatformView|
  void RequestViewFocusChange(const ViewFocusChangeRequest& request) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformViewEmbedder);
};

//------------------------------------------------------------------------------
/// @brief      Builds the dispatch table that `FlutterEngineInitialize` derives
///             from the callbacks in `args`: semantics updates, platform
///             messages, vsync, locale resolution, pre-restart, channel
///             updates, view focus and deferred libraries. Every callback
///             receives `user_data`. The rendering entries stay empty.
///
///             An embedding that creates its own `PlatformViewEmbedder` uses
///             this to answer the same callbacks the same way.
///
/// @param[in]  args       The project arguments. May be null, which yields an
///                        empty table.
/// @param[in]  user_data  Passed through to every callback.
///
/// @return     The dispatch table, or `kInvalidArgument` if `args` sets more
///             than one kind of semantics update callback.
///
fml::StatusOr<PlatformViewEmbedder::PlatformDispatchTable>
PlatformDispatchTableFromProjectArgs(const FlutterProjectArgs* args,
                                     void* user_data);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_PLATFORM_VIEW_EMBEDDER_H_
