// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/platform_view_embedder.h"

#include <mutex>
#include <shared_mutex>
#include <utility>

#include "flutter/fml/make_copyable.h"

#if !SLIMPELLER && defined(SHELL_ENABLE_GL)
#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#endif  // !SLIMPELLER && defined(SHELL_ENABLE_GL)

namespace flutter {

class PlatformViewEmbedder::EmbedderPlatformMessageHandler
    : public PlatformMessageHandler {
 public:
  EmbedderPlatformMessageHandler(
      fml::WeakPtr<PlatformView> parent,
      fml::RefPtr<fml::TaskRunner> platform_task_runner)
      : parent_(std::move(parent)),
        platform_task_runner_(std::move(platform_task_runner)) {}

  virtual void HandlePlatformMessage(std::unique_ptr<PlatformMessage> message) {
    platform_task_runner_->PostTask(fml::MakeCopyable(
        [parent = parent_, message = std::move(message)]() mutable {
          if (parent) {
            parent->HandlePlatformMessage(std::move(message));
          } else {
            FML_DLOG(WARNING) << "Deleted engine dropping message on channel "
                              << message->channel();
          }
        }));
  }

  virtual bool DoesHandlePlatformMessageOnPlatformThread() const {
    return true;
  }

  virtual void InvokePlatformMessageResponseCallback(
      int response_id,
      std::unique_ptr<fml::Mapping> mapping) {}
  virtual void InvokePlatformMessageEmptyResponseCallback(int response_id) {}

 private:
  fml::WeakPtr<PlatformView> parent_;
  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
};

// Calls the platform message callback on the thread that sends each message:
// the UI thread for the root isolate, or a background isolate's thread. A
// background isolate can hold this handler after the platform view is gone,
// so the platform view detaches it on destruction; detaching waits for calls
// in progress, and later messages are dropped.
class PlatformViewEmbedder::SendingThreadPlatformMessageHandler
    : public PlatformMessageHandler {
 public:
  explicit SendingThreadPlatformMessageHandler(
      PlatformMessageResponseCallback callback)
      : callback_(std::move(callback)) {}

  // |PlatformMessageHandler|
  void HandlePlatformMessage(
      std::unique_ptr<PlatformMessage> message) override {
    std::shared_lock lock(mutex_);
    if (detached_) {
      FML_DLOG(WARNING) << "Deleted engine dropping message on channel "
                        << message->channel();
      return;
    }
    if (!callback_) {
      if (message->response()) {
        message->response()->CompleteEmpty();
      }
      return;
    }
    callback_(std::move(message));
  }

  // |PlatformMessageHandler|
  bool DoesHandlePlatformMessageOnPlatformThread() const override {
    return false;
  }

  // |PlatformMessageHandler|
  void InvokePlatformMessageResponseCallback(
      int response_id,
      std::unique_ptr<fml::Mapping> mapping) override {}

  // |PlatformMessageHandler|
  void InvokePlatformMessageEmptyResponseCallback(int response_id) override {}

  // Waits for calls in progress and stops later ones from reaching the
  // callback.
  void Detach() {
    std::unique_lock lock(mutex_);
    detached_ = true;
    callback_ = nullptr;
  }

 private:
  // Held shared while the callback runs and exclusively by Detach.
  std::shared_mutex mutex_;
  bool detached_ = false;
  PlatformMessageResponseCallback callback_;
};

std::shared_ptr<PlatformMessageHandler>
PlatformViewEmbedder::CreatePlatformMessageHandler(
    const PlatformDispatchTable& platform_dispatch_table,
    const flutter::TaskRunners& task_runners) {
  if (platform_dispatch_table.platform_message_callback_on_sending_thread) {
    sending_thread_message_handler_ =
        std::make_shared<SendingThreadPlatformMessageHandler>(
            platform_dispatch_table.platform_message_response_callback);
    return sending_thread_message_handler_;
  }
  return std::make_shared<EmbedderPlatformMessageHandler>(
      GetWeakPtr(), task_runners.GetPlatformTaskRunner());
}

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    const EmbedderSurfaceSoftware::SoftwareDispatchTable&
        software_dispatch_table,
    PlatformDispatchTable platform_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, task_runners),
      external_view_embedder_(std::move(external_view_embedder)),
      embedder_surface_(
          std::make_unique<EmbedderSurfaceSoftware>(software_dispatch_table,
                                                    external_view_embedder_)),
      platform_message_handler_(
          CreatePlatformMessageHandler(platform_dispatch_table, task_runners)),
      platform_dispatch_table_(std::move(platform_dispatch_table)) {}

#ifdef SHELL_ENABLE_GL
PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    std::unique_ptr<EmbedderSurface> embedder_surface,
    PlatformDispatchTable platform_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, task_runners),
      external_view_embedder_(std::move(external_view_embedder)),
      embedder_surface_(std::move(embedder_surface)),
      platform_message_handler_(
          CreatePlatformMessageHandler(platform_dispatch_table, task_runners)),
      platform_dispatch_table_(std::move(platform_dispatch_table)) {}
#endif

#ifdef SHELL_ENABLE_METAL
PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    std::unique_ptr<EmbedderSurface> embedder_surface,
    PlatformDispatchTable platform_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, task_runners),
      external_view_embedder_(std::move(external_view_embedder)),
      embedder_surface_(std::move(embedder_surface)),
      platform_message_handler_(
          CreatePlatformMessageHandler(platform_dispatch_table, task_runners)),
      platform_dispatch_table_(std::move(platform_dispatch_table)) {}
#endif

#ifdef SHELL_ENABLE_VULKAN
PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    std::unique_ptr<EmbedderSurfaceVulkan> embedder_surface,
    PlatformDispatchTable platform_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, task_runners),
      external_view_embedder_(std::move(external_view_embedder)),
      embedder_surface_(std::move(embedder_surface)),
      platform_message_handler_(
          CreatePlatformMessageHandler(platform_dispatch_table, task_runners)),
      platform_dispatch_table_(std::move(platform_dispatch_table)) {}
#endif

PlatformViewEmbedder::PlatformViewEmbedder(
    PlatformView::Delegate& delegate,
    const flutter::TaskRunners& task_runners,
    PlatformDispatchTable platform_dispatch_table,
    std::shared_ptr<EmbedderExternalViewEmbedder> external_view_embedder)
    : PlatformView(delegate, task_runners),
      external_view_embedder_(std::move(external_view_embedder)),
      platform_message_handler_(
          CreatePlatformMessageHandler(platform_dispatch_table, task_runners)),
      platform_dispatch_table_(std::move(platform_dispatch_table)) {}

PlatformViewEmbedder::~PlatformViewEmbedder() {
  if (sending_thread_message_handler_) {
    sending_thread_message_handler_->Detach();
  }
}

void PlatformViewEmbedder::UpdateSemantics(
    int64_t view_id,
    flutter::SemanticsNodeUpdates update,
    flutter::CustomAccessibilityActionUpdates actions) {
  if (platform_dispatch_table_.update_semantics_callback != nullptr) {
    platform_dispatch_table_.update_semantics_callback(
        view_id, std::move(update), std::move(actions));
  }
}

void PlatformViewEmbedder::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  if (!message) {
    return;
  }

  if (platform_dispatch_table_.platform_message_response_callback == nullptr) {
    if (message->response()) {
      message->response()->CompleteEmpty();
    }
    return;
  }

  platform_dispatch_table_.platform_message_response_callback(
      std::move(message));
}

// |PlatformView|
std::unique_ptr<Surface> PlatformViewEmbedder::CreateRenderingSurface() {
  if (platform_dispatch_table_.create_rendering_surface_callback != nullptr) {
    return platform_dispatch_table_.create_rendering_surface_callback();
  }
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateGPUSurface();
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder>
PlatformViewEmbedder::CreateExternalViewEmbedder() {
  if (platform_dispatch_table_.create_external_view_embedder_callback !=
      nullptr) {
    return platform_dispatch_table_.create_external_view_embedder_callback();
  }
  return external_view_embedder_;
}

// |PlatformView|
std::unique_ptr<SnapshotSurfaceProducer>
PlatformViewEmbedder::CreateSnapshotSurfaceProducer() {
  if (platform_dispatch_table_.create_snapshot_surface_producer_callback !=
      nullptr) {
    return platform_dispatch_table_.create_snapshot_surface_producer_callback();
  }
  return PlatformView::CreateSnapshotSurfaceProducer();
}

std::shared_ptr<impeller::Context> PlatformViewEmbedder::GetImpellerContext()
    const {
  if (platform_dispatch_table_.get_impeller_context_callback != nullptr) {
    return platform_dispatch_table_.get_impeller_context_callback();
  }
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateImpellerContext();
}

// |PlatformView|
void PlatformViewEmbedder::SetupImpellerContext() {
  if (platform_dispatch_table_.setup_impeller_context_callback != nullptr) {
    platform_dispatch_table_.setup_impeller_context_callback();
  }
}

// |PlatformView|
sk_sp<GrDirectContext> PlatformViewEmbedder::CreateResourceContext() const {
  if (platform_dispatch_table_.create_resource_context_callback != nullptr) {
    return platform_dispatch_table_.create_resource_context_callback();
  }
  if (platform_dispatch_table_.make_resource_current_callback != nullptr) {
#if !SLIMPELLER && defined(SHELL_ENABLE_GL)
    sk_sp<GrDirectContext> resource_context;
    if (platform_dispatch_table_.make_resource_current_callback()) {
      resource_context = ShellIOManager::CreateCompatibleResourceLoadingContext(
          GrBackendApi::kOpenGL,
          GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface());
    } else {
      FML_DLOG(ERROR) << "Could not make the resource context current.";
    }
    return resource_context;
#else
    platform_dispatch_table_.make_resource_current_callback();
    return nullptr;
#endif  // !SLIMPELLER && defined(SHELL_ENABLE_GL)
  }
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return nullptr;
  }
  return embedder_surface_->CreateResourceContext();
}

// |PlatformView|
void PlatformViewEmbedder::ReleaseResourceContext() const {
  if (platform_dispatch_table_.release_resource_context_callback != nullptr) {
    platform_dispatch_table_.release_resource_context_callback();
    return;
  }
  if (embedder_surface_ == nullptr) {
    FML_LOG(ERROR) << "Embedder surface was null.";
    return;
  }
  embedder_surface_->ReleaseResourceContext();
}

// |PlatformView|
std::unique_ptr<VsyncWaiter> PlatformViewEmbedder::CreateVSyncWaiter() {
  if (!platform_dispatch_table_.vsync_callback) {
    // Superclass implementation creates a timer based fallback.
    return PlatformView::CreateVSyncWaiter();
  }

  return std::make_unique<VsyncWaiterEmbedder>(
      platform_dispatch_table_.vsync_callback, task_runners_);
}

// |PlatformView|
std::unique_ptr<std::vector<std::string>>
PlatformViewEmbedder::ComputePlatformResolvedLocales(
    const std::vector<std::string>& supported_locale_data) {
  if (platform_dispatch_table_.compute_platform_resolved_locale_callback !=
      nullptr) {
    return platform_dispatch_table_.compute_platform_resolved_locale_callback(
        supported_locale_data);
  }
  std::unique_ptr<std::vector<std::string>> out =
      std::make_unique<std::vector<std::string>>();
  return out;
}

// |PlatformView|
void PlatformViewEmbedder::SetApplicationLocale(std::string locale) {
  if (platform_dispatch_table_.set_application_locale_callback != nullptr) {
    platform_dispatch_table_.set_application_locale_callback(std::move(locale));
  }
}

// |PlatformView|
void PlatformViewEmbedder::SetSemanticsTreeEnabled(bool enabled) {
  if (platform_dispatch_table_.set_semantics_tree_enabled_callback != nullptr) {
    platform_dispatch_table_.set_semantics_tree_enabled_callback(enabled);
  }
}

// |PlatformView|
void PlatformViewEmbedder::RequestDartDeferredLibrary(
    intptr_t loading_unit_id) {
  if (platform_dispatch_table_.request_dart_deferred_library_callback !=
      nullptr) {
    platform_dispatch_table_.request_dart_deferred_library_callback(
        loading_unit_id);
  }
}

// |PlatformView|
void PlatformViewEmbedder::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  delegate_.LoadDartDeferredLibrary(loading_unit_id, std::move(snapshot_data),
                                    std::move(snapshot_instructions));
}

// |PlatformView|
void PlatformViewEmbedder::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  delegate_.LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                         transient);
}

// |PlatformView|
double PlatformViewEmbedder::GetScaledFontSize(double unscaled_font_size,
                                               int configuration_id) const {
  if (platform_dispatch_table_.get_scaled_font_size_callback != nullptr) {
    return platform_dispatch_table_.get_scaled_font_size_callback(
        unscaled_font_size, configuration_id);
  }
  return PlatformView::GetScaledFontSize(unscaled_font_size, configuration_id);
}

// |PlatformView|
void PlatformViewEmbedder::OnPreEngineRestart() const {
  if (platform_dispatch_table_.on_pre_engine_restart_callback != nullptr) {
    platform_dispatch_table_.on_pre_engine_restart_callback();
  }
}

// |PlatformView|
void PlatformViewEmbedder::SendChannelUpdate(const std::string& name,
                                             bool listening) {
  if (platform_dispatch_table_.on_channel_update != nullptr) {
    platform_dispatch_table_.on_channel_update(name, listening);
  }
}

void PlatformViewEmbedder::RequestViewFocusChange(
    const ViewFocusChangeRequest& request) {
  if (platform_dispatch_table_.view_focus_change_request_callback != nullptr) {
    platform_dispatch_table_.view_focus_change_request_callback(request);
  }
}

std::shared_ptr<PlatformMessageHandler>
PlatformViewEmbedder::GetPlatformMessageHandler() const {
  return platform_message_handler_;
}

}  // namespace flutter
