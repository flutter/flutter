// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/embedder_android_engine.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <mutex>
#include <utility>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/display_list/geometry/dl_path_builder.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/paths.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#include "flutter/shell/platform/android/platform_message_handler_android.h"
#include "flutter/shell/platform/embedder/embedder_semantics_update.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <android/log.h>
#include "flutter/fml/platform/android/jni_util.h"
#endif

namespace flutter {

namespace {

constexpr size_t kPointerDataFieldCount = 36;
constexpr size_t kBytesPerField = 8;
constexpr size_t kBytesPerPointerEntry =
    kPointerDataFieldCount * kBytesPerField;

class EmbedderPlatformMessageResponse final : public PlatformMessageResponse {
 public:
  static fml::RefPtr<EmbedderPlatformMessageResponse> Create(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      FlutterEngineSendPlatformMessageResponseFnPtr send_response_fn,
      const FlutterPlatformMessageResponseHandle* handle) {
    return fml::AdoptRef(
        new EmbedderPlatformMessageResponse(engine, send_response_fn, handle));
  }

  void Complete(std::unique_ptr<fml::Mapping> data) override {
    if (engine_ && send_response_fn_ && handle_) {
      send_response_fn_(engine_, handle_, data ? data->GetMapping() : nullptr,
                        data ? data->GetSize() : 0);
      handle_ = nullptr;
    }
  }

  void CompleteEmpty() override {
    if (engine_ && send_response_fn_ && handle_) {
      send_response_fn_(engine_, handle_, nullptr, 0);
      handle_ = nullptr;
    }
  }

 private:
  EmbedderPlatformMessageResponse(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      FlutterEngineSendPlatformMessageResponseFnPtr send_response_fn,
      const FlutterPlatformMessageResponseHandle* handle)
      : engine_(engine), send_response_fn_(send_response_fn), handle_(handle) {}

  FLUTTER_API_SYMBOL(FlutterEngine) engine_;
  FlutterEngineSendPlatformMessageResponseFnPtr send_response_fn_;
  const FlutterPlatformMessageResponseHandle* handle_;
};

}  // namespace

class EmbedderAndroidEngine::CompositorDelegate
    : public AndroidCompositorPlatformViewDelegate {
 public:
  explicit CompositorDelegate(EmbedderAndroidEngine* engine)
      : engine_(engine) {}

  void DetachEngine() {
    std::lock_guard<std::mutex> lock(mutex_);
    engine_ = nullptr;
  }

  void OnBeginFrame() override {
    std::lock_guard<std::mutex> lock(mutex_);
    if (engine_ != nullptr) {
      engine_->OnBeginFrame();
    }
  }

  void OnPlatformViewPresented(
      int64_t view_id,
      const FlutterPoint& offset,
      const FlutterSize& size,
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations) override {
    std::lock_guard<std::mutex> lock(mutex_);
    if (engine_ != nullptr) {
      engine_->OnPlatformViewPresented(view_id, offset, size, mutations_count,
                                       mutations);
    }
  }

  void OnFramePresented() override {
    std::lock_guard<std::mutex> lock(mutex_);
    if (engine_ != nullptr) {
      engine_->OnFramePresented();
    }
  }

 private:
  std::mutex mutex_;
  EmbedderAndroidEngine* engine_ = nullptr;
};

void EmbedderAndroidEngine::InitializeSubsystems(
    const TaskRunners* existing_task_runners) {
  proc_table_.struct_size = sizeof(FlutterEngineProcTable);
  FlutterEngineResult result = FlutterEngineGetProcAddresses(&proc_table_);
  FML_CHECK(result == kSuccess)
      << "FlutterEngineGetProcAddresses failed with result: " << result;

  if (existing_task_runners != nullptr && existing_task_runners->IsValid()) {
    android_task_runners_ = std::make_shared<AndroidTaskRunners>(
        "io.flutter", existing_task_runners->GetPlatformTaskRunner(),
        existing_task_runners->GetUITaskRunner(),
        existing_task_runners->GetRasterTaskRunner());
  } else {
    bool merge_platform_and_ui = settings_.merged_platform_ui_thread !=
                                 Settings::MergedPlatformUIThread::kDisabled;
    android_task_runners_ = std::make_shared<AndroidTaskRunners>(
        "io.flutter", merge_platform_and_ui);
  }
  surface_manager_ =
      std::make_shared<AndroidSurfaceManager>(android_rendering_api_);
  vsync_waiter_ = std::make_shared<android::AndroidVsyncWaiter>();
  platform_views_controller_ =
      std::make_shared<android::AndroidPlatformViewsController>();
  surface_control_provider_ =
      std::make_shared<android::DefaultAndroidSurfaceControlProvider>();
  hardware_buffer_provider_ =
      std::make_shared<android::DefaultAndroidHardwareBufferProvider>();
  vulkan_texture_provider_ =
      std::make_shared<android::DefaultAndroidVulkanTextureProvider>();
  engine_group_ = std::make_shared<android::AndroidEngineGroup>();
  compositor_delegate_ = std::make_shared<CompositorDelegate>(this);
  compositor_ = std::make_shared<AndroidCompositor>(surface_manager_,
                                                    compositor_delegate_);
  if (jni_facade_ != nullptr && !platform_message_handler_) {
    platform_message_handler_ =
        std::make_shared<PlatformMessageHandlerAndroid>(jni_facade_);
  }
}

void EmbedderAndroidEngine::BindPlatformMessageHandler() {
  if (platform_message_handler_) {
    static_cast<PlatformMessageHandlerAndroid*>(platform_message_handler_.get())
        ->SetEmbedderEngine(GetEngineHandle(), proc_table_);
  }
}

void EmbedderAndroidEngine::SetPlatformMessageHandler(
    std::shared_ptr<PlatformMessageHandler> handler) {
  if (platform_message_handler_) {
    static_cast<PlatformMessageHandlerAndroid*>(platform_message_handler_.get())
        ->SetEmbedderEngine(nullptr, {});
  }
  platform_message_handler_ = std::move(handler);
  BindPlatformMessageHandler();
}

EmbedderAndroidEngine::EmbedderAndroidEngine(
    const TaskRunners& task_runners,
    std::unique_ptr<Shell> shell,
    const Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(std::move(jni_facade)),
      android_rendering_api_(android_rendering_api) {
  InitializeSubsystems(&task_runners);
  if (shell) {
    embedder_engine_ =
        std::make_unique<EmbedderEngine>(task_runners, std::move(shell));
    android_task_runners_->SetEngine(GetEngineHandle());
    if (vsync_waiter_ != nullptr) {
      vsync_waiter_->SetEngine(GetEngineHandle());
    }
    BindPlatformMessageHandler();
  }
}

EmbedderAndroidEngine::EmbedderAndroidEngine(
    const Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(std::move(jni_facade)),
      android_rendering_api_(android_rendering_api) {
  InitializeSubsystems(nullptr);
}

EmbedderAndroidEngine::~EmbedderAndroidEngine() {
  if (vsync_waiter_ != nullptr) {
    vsync_waiter_->SetEngine(nullptr);
  }
  if (android_task_runners_ != nullptr) {
    android_task_runners_->SetEngine(nullptr);
  }
  if (platform_message_handler_) {
    static_cast<PlatformMessageHandlerAndroid*>(platform_message_handler_.get())
        ->SetEmbedderEngine(nullptr, {});
  }
  if (compositor_delegate_ != nullptr) {
    compositor_delegate_->DetachEngine();
  }
  if (compositor_ != nullptr) {
    compositor_->SetPlatformViewDelegate(nullptr);
  }

  if (embedder_engine_) {
    embedder_engine_->CollectShell();
    embedder_engine_.reset();
  } else if (c_api_engine_ != nullptr) {
    if (surface_attached_) {
      proc_table_.NotifyDestroyed(c_api_engine_);
      surface_attached_ = false;
    }
    proc_table_.Shutdown(c_api_engine_);
    c_api_engine_ = nullptr;
  } else if (asset_resolver_.destruction_callback != nullptr) {
    asset_resolver_.destruction_callback(asset_resolver_.user_data);
    asset_resolver_.destruction_callback = nullptr;
  }
}

bool EmbedderAndroidEngine::IsValid() const {
  if (embedder_engine_) {
    return embedder_engine_->IsValid();
  }
  return c_api_is_valid_ && c_api_engine_ != nullptr;
}

bool EmbedderAndroidEngine::IsSetup() const {
  if (embedder_engine_) {
    return embedder_engine_->GetShell().IsSetup();
  }
  return IsValid();
}

void EmbedderAndroidEngine::RunEngine(RunConfiguration run_configuration) {
  if (embedder_engine_) {
    embedder_engine_->SetRunConfiguration(std::move(run_configuration));
    if (proc_table_.RunInitialized) {
      proc_table_.RunInitialized(GetEngineHandle());
    } else {
      embedder_engine_->RunRootIsolate();
    }
  }
}

std::unique_ptr<AndroidEngine> EmbedderAndroidEngine::Spawn(
    RunConfiguration run_configuration,
    const std::string& initial_route,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer) const {
  if (!embedder_engine_) {
    return nullptr;
  }
  auto spawned_shell = embedder_engine_->GetShell().Spawn(
      std::move(run_configuration), initial_route, on_create_platform_view,
      on_create_rasterizer);
  if (!spawned_shell) {
    return nullptr;
  }
  return std::make_unique<EmbedderAndroidEngine>(
      spawned_shell->GetTaskRunners(), std::move(spawned_shell), settings_,
      jni_facade_, android_rendering_api_);
}

Rasterizer::Screenshot EmbedderAndroidEngine::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  Rasterizer::Screenshot result{nullptr, DlISize(), "",
                                Rasterizer::ScreenshotFormat::kUnknown};
  if (!IsValid() || !proc_table_.Screenshot) {
    return result;
  }
  FlutterScreenshotType embedder_type = kFlutterScreenshotTypeUncompressedImage;
  if (type == Rasterizer::ScreenshotType::CompressedImage) {
    embedder_type = kFlutterScreenshotTypeCompressedImage;
  } else if (type == Rasterizer::ScreenshotType::SurfaceData) {
    embedder_type = kFlutterScreenshotTypeSurfaceData;
  }

  FlutterScreenshotRequest request = {};
  request.struct_size = sizeof(FlutterScreenshotRequest);
  request.type = embedder_type;
  request.base64_encode = base64_encode;

  FlutterScreenshot screenshot = {};
  screenshot.struct_size = sizeof(FlutterScreenshot);
  if (proc_table_.Screenshot(GetEngineHandle(), &request, &screenshot) ==
      kSuccess) {
    if (screenshot.data != nullptr && screenshot.data_length > 0) {
      result.data =
          SkData::MakeWithCopy(screenshot.data, screenshot.data_length);
      result.frame_size = DlISize(screenshot.width, screenshot.height);
    }
    if (screenshot.format_description != nullptr) {
      result.format = screenshot.format_description;
    }
    if (proc_table_.FreeScreenshot) {
      proc_table_.FreeScreenshot(&screenshot);
    }
  }
  return result;
}

void EmbedderAndroidEngine::NotifyLowMemoryWarning() {
  if (IsValid() && proc_table_.NotifyLowMemoryWarning) {
    proc_table_.NotifyLowMemoryWarning(GetEngineHandle());
  }
  PersistentCache::GetCacheForProcess()->Purge();
}

void EmbedderAndroidEngine::OnDisplayUpdates(
    std::vector<std::unique_ptr<Display>> displays) {
  if (!IsValid() || !proc_table_.NotifyDisplayUpdate) {
    return;
  }
  std::vector<FlutterEngineDisplay> c_displays;
  c_displays.reserve(displays.size());
  for (const auto& display : displays) {
    if (!display) {
      continue;
    }
    if (vsync_waiter_ != nullptr && display->GetRefreshRate() > 0.0) {
      vsync_waiter_->UpdateRefreshRate(display->GetRefreshRate());
    }
    FlutterEngineDisplay c_display = {};
    c_display.struct_size = sizeof(FlutterEngineDisplay);
    c_display.display_id = display->GetDisplayId();
    c_display.single_display = displays.size() == 1;
    c_display.refresh_rate = display->GetRefreshRate();
    c_display.width = static_cast<size_t>(display->GetWidth());
    c_display.height = static_cast<size_t>(display->GetHeight());
    c_display.device_pixel_ratio = display->GetDevicePixelRatio();
    c_displays.push_back(c_display);
  }
  proc_table_.NotifyDisplayUpdate(GetEngineHandle(),
                                  kFlutterEngineDisplaysUpdateTypeStartup,
                                  c_displays.data(), c_displays.size());
  if (embedder_engine_) {
    embedder_engine_->GetShell().OnDisplayUpdates(std::move(displays));
  }
}

const std::shared_ptr<PlatformMessageHandler>&
EmbedderAndroidEngine::GetPlatformMessageHandler() const {
  if (platform_message_handler_) {
    return platform_message_handler_;
  }
  FML_CHECK(embedder_engine_);
  return embedder_engine_->GetShell().GetPlatformMessageHandler();
}

void EmbedderAndroidEngine::RegisterImageDecoder(ImageGeneratorFactory factory,
                                                 int32_t priority) {
  if (embedder_engine_) {
    embedder_engine_->RegisterImageGenerator(std::move(factory), priority);
  }
}

const TaskRunners& EmbedderAndroidEngine::GetTaskRunners() const {
  FML_CHECK(embedder_engine_);
  return embedder_engine_->GetTaskRunners();
}

Shell& EmbedderAndroidEngine::GetShell() {
  FML_CHECK(embedder_engine_);
  return embedder_engine_->GetShell();
}

const std::unique_ptr<Shell>& EmbedderAndroidEngine::GetShellForTesting()
    const {
  return embedder_engine_->GetShellPointer();
}

void EmbedderAndroidEngine::NotifyCreated() {
  if (IsValid() && proc_table_.NotifyCreated) {
    proc_table_.NotifyCreated(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::NotifyDestroyed() {
  if (IsValid() && proc_table_.NotifyDestroyed) {
    proc_table_.NotifyDestroyed(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::ScheduleFrame() {
  if (IsValid() && proc_table_.ScheduleFrame) {
    proc_table_.ScheduleFrame(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::SetNextFrameCallback(const fml::closure& closure) {
  if (!IsValid() || !proc_table_.SetNextFrameCallback) {
    return;
  }
  {
    std::scoped_lock lock(next_frame_callback_mutex_);
    next_frame_callback_ = closure;
  }
  proc_table_.SetNextFrameCallback(
      GetEngineHandle(),
      [](void* user_data) {
        auto* self = static_cast<EmbedderAndroidEngine*>(user_data);
        fml::closure cb;
        {
          std::scoped_lock lock(self->next_frame_callback_mutex_);
          cb = std::move(self->next_frame_callback_);
        }
        if (cb) {
          cb();
        }
      },
      this);
}

EmbedderAndroidEngine::DisplayFeatures
EmbedderAndroidEngine::NormalizeDisplayFeatures(
    const ViewportMetrics& metrics) {
  DisplayFeatures features;

  // The incoming bounds array is authoritative: it carries the geometry, and a
  // feature with geometry but an unrecognized type is still worth reporting
  // because the framework lays out around its bounds either way.
  const size_t available = metrics.physical_display_features_bounds.size() / 4;
  const size_t count =
      std::min(available, static_cast<size_t>(kFlutterMaxDisplayFeatures));
  if (count < available) {
    // `SetViewportMetrics` runs on every resize, rotation and fold, and once
    // per frame while the IME animates, so a persistently malformed embedder
    // would otherwise log at refresh rate.
    static std::once_flag once;
    std::call_once(once, [available, count]() {
      FML_LOG(WARNING) << "Dropping " << (available - count)
                       << " display feature(s): the engine rejects a metrics "
                          "event reporting more than "
                       << kFlutterMaxDisplayFeatures
                       << " display features. Logged once.";
    });
  }

  features.bounds.assign(metrics.physical_display_features_bounds.begin(),
                         metrics.physical_display_features_bounds.begin() +
                             static_cast<std::ptrdiff_t>(count * 4));
  features.type.reserve(count);
  features.state.reserve(count);

  // Padding is counted separately from rewriting, because padding substitutes
  // a perfectly valid "unknown" and would otherwise be indistinguishable from
  // a feature the embedder genuinely reported as unknown -- leaving the array
  // length mismatch that caused it completely silent.
  size_t padded = 0;
  size_t rewritten = 0;
  for (size_t i = 0; i < count; i++) {
    const bool has_type = i < metrics.physical_display_features_type.size();
    const bool has_state = i < metrics.physical_display_features_state.size();
    if (!has_type || !has_state) {
      padded++;
    }
    // A short type or state array is padded rather than truncated, so that a
    // feature is never dropped merely because its classification is missing.
    const int32_t type = has_type ? metrics.physical_display_features_type[i]
                                  : kFlutterDisplayFeatureTypeUnknown;
    const int32_t state = has_state ? metrics.physical_display_features_state[i]
                                    : kFlutterDisplayFeatureStateUnknown;

    // The engine rejects the entire metrics event -- size, padding and all --
    // if any type is out of range or any state is negative, so an unusable
    // value is reported as "unknown" instead of costing the whole event. A
    // state the engine does not know yet is passed through untouched: both the
    // C API and `_decodeDisplayFeatures` in `lib/ui/hooks.dart` accept any
    // non-negative state for forward compatibility.
    const bool type_is_valid = type >= kFlutterDisplayFeatureTypeUnknown &&
                               type <= kFlutterDisplayFeatureTypeCutout;
    const bool state_is_valid = state >= kFlutterDisplayFeatureStateUnknown;
    if ((has_type && !type_is_valid) || (has_state && !state_is_valid)) {
      rewritten++;
    }
    features.type.push_back(type_is_valid ? type
                                          : kFlutterDisplayFeatureTypeUnknown);
    features.state.push_back(
        state_is_valid ? state : kFlutterDisplayFeatureStateUnknown);
  }
  if (padded > 0 || rewritten > 0) {
    static std::once_flag once;
    std::call_once(once, [padded, rewritten]() {
      FML_LOG(WARNING) << "Reported display features the engine would have "
                          "rejected as unknown. "
                       << padded << " were missing a type or state and "
                       << rewritten
                       << " had one out of range; a feature missing one field "
                          "and out of range in the other is counted in both. "
                          "Logged once.";
    });
  }
  return features;
}

FlutterWindowMetricsEvent EmbedderAndroidEngine::ToFlutterWindowMetricsEvent(
    int64_t view_id,
    const ViewportMetrics& metrics,
    const DisplayFeatures& display_features) {
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = static_cast<size_t>(std::max(0.0, metrics.physical_width));
  event.height = static_cast<size_t>(std::max(0.0, metrics.physical_height));
  event.pixel_ratio = metrics.device_pixel_ratio;
  event.left = 0;
  event.top = 0;
  event.physical_view_inset_top = metrics.physical_view_inset_top;
  event.physical_view_inset_right = metrics.physical_view_inset_right;
  event.physical_view_inset_bottom = metrics.physical_view_inset_bottom;
  event.physical_view_inset_left = metrics.physical_view_inset_left;
  event.display_id = metrics.display_id;
  event.view_id = view_id;
  event.has_constraints = true;
  event.min_width_constraint =
      static_cast<size_t>(std::max(0.0, metrics.physical_min_width_constraint));
  event.min_height_constraint = static_cast<size_t>(
      std::max(0.0, metrics.physical_min_height_constraint));
  event.max_width_constraint =
      static_cast<size_t>(std::max(0.0, metrics.physical_max_width_constraint));
  event.max_height_constraint = static_cast<size_t>(
      std::max(0.0, metrics.physical_max_height_constraint));
  event.has_extended_metrics = true;
  event.physical_padding_top = metrics.physical_padding_top;
  event.physical_padding_right = metrics.physical_padding_right;
  event.physical_padding_bottom = metrics.physical_padding_bottom;
  event.physical_padding_left = metrics.physical_padding_left;
  event.physical_system_gesture_inset_top =
      metrics.physical_system_gesture_inset_top;
  event.physical_system_gesture_inset_right =
      metrics.physical_system_gesture_inset_right;
  event.physical_system_gesture_inset_bottom =
      metrics.physical_system_gesture_inset_bottom;
  event.physical_system_gesture_inset_left =
      metrics.physical_system_gesture_inset_left;
  event.physical_touch_slop = metrics.physical_touch_slop;

  // The engine reads `display_features_count` entries from the type and state
  // arrays and `4 * display_features_count` doubles from the bounds array.
  // `NormalizeDisplayFeatures` sized all three consistently, so the count can
  // be read off any of them.
  const size_t count = display_features.type.size();
  FML_DCHECK(display_features.state.size() == count);
  FML_DCHECK(display_features.bounds.size() == count * 4);
  event.display_features_count = count;
  // The engine rejects the event if the count is non-zero and any one of the
  // three arrays is null, so they are supplied or withheld as a group.
  event.display_features_bounds =
      count == 0 ? nullptr : display_features.bounds.data();
  event.display_features_type =
      count == 0 ? nullptr : display_features.type.data();
  event.display_features_state =
      count == 0 ? nullptr : display_features.state.data();

  event.physical_display_corner_radius_top_left =
      metrics.physical_display_corner_radius_top_left;
  event.physical_display_corner_radius_top_right =
      metrics.physical_display_corner_radius_top_right;
  event.physical_display_corner_radius_bottom_right =
      metrics.physical_display_corner_radius_bottom_right;
  event.physical_display_corner_radius_bottom_left =
      metrics.physical_display_corner_radius_bottom_left;
  return event;
}

void EmbedderAndroidEngine::SetViewportMetrics(int64_t view_id,
                                               const ViewportMetrics& metrics) {
  if (!IsValid()) {
    return;
  }
  // `features` owns all three display feature arrays that `event` points at,
  // so it has to outlive the send below.
  const DisplayFeatures features = NormalizeDisplayFeatures(metrics);
  FlutterWindowMetricsEvent event =
      ToFlutterWindowMetricsEvent(view_id, metrics, features);
  proc_table_.SendWindowMetricsEvent(GetEngineHandle(), &event);
}

void EmbedderAndroidEngine::DispatchPlatformMessage(
    std::unique_ptr<PlatformMessage> message) {
  if (!IsValid() || !message) {
    return;
  }
  FlutterPlatformMessage c_message = {};
  c_message.struct_size = sizeof(FlutterPlatformMessage);
  c_message.channel = message->channel().c_str();
  static const uint8_t kEmptyByte = 0;
  if (message->hasData()) {
    const uint8_t* mapping = message->data().GetMapping();
    c_message.message = (mapping == nullptr && message->data().GetSize() == 0)
                            ? &kEmptyByte
                            : mapping;
    c_message.message_size = message->data().GetSize();
  }
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  fml::RefPtr<PlatformMessageResponse>* response_ref = nullptr;
  if (message->response() && proc_table_.PlatformMessageCreateResponseHandle) {
    response_ref =
        new fml::RefPtr<PlatformMessageResponse>(message->response());
    if (proc_table_.PlatformMessageCreateResponseHandle(
            GetEngineHandle(),
            [](const uint8_t* data, size_t data_size, void* user_data) {
              auto* resp =
                  static_cast<fml::RefPtr<PlatformMessageResponse>*>(user_data);
              if (resp && *resp) {
                if (data != nullptr && data_size > 0) {
                  (*resp)->Complete(std::make_unique<fml::MallocMapping>(
                      fml::MallocMapping::Copy(data, data_size)));
                } else {
                  (*resp)->CompleteEmpty();
                }
              }
              delete resp;
            },
            response_ref, &response_handle) != kSuccess ||
        response_handle == nullptr) {
      delete response_ref;
      response_ref = nullptr;
      response_handle = nullptr;
    }
    c_message.response_handle = response_handle;
  }
  FlutterEngineResult send_result = kInternalInconsistency;
  if (proc_table_.SendPlatformMessage) {
    send_result =
        proc_table_.SendPlatformMessage(GetEngineHandle(), &c_message);
  }
  if (send_result != kSuccess && response_ref != nullptr) {
    delete response_ref;
  }
  if (response_handle != nullptr &&
      proc_table_.PlatformMessageReleaseResponseHandle) {
    proc_table_.PlatformMessageReleaseResponseHandle(GetEngineHandle(),
                                                     response_handle);
  }
}

void EmbedderAndroidEngine::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet) {
  if (IsValid() && proc_table_.SendPointerEvent) {
    if (packet) {
      auto events =
          UnpackPointerDataPacket(packet->data().data(), packet->data().size());
      if (!events.empty()) {
        proc_table_.SendPointerEvent(GetEngineHandle(), events.data(),
                                     events.size());
      }
    }
  }
}

void EmbedderAndroidEngine::DispatchSemanticsAction(int64_t view_id,
                                                    int32_t node_id,
                                                    SemanticsAction action,
                                                    fml::MallocMapping args) {
  if (!IsValid() || !proc_table_.SendSemanticsAction) {
    return;
  }
  FlutterSendSemanticsActionInfo info = {};
  info.struct_size = sizeof(FlutterSendSemanticsActionInfo);
  info.view_id = view_id;
  info.node_id = node_id;
  info.action = static_cast<FlutterSemanticsAction>(action);
  info.data = args.GetMapping();
  info.data_length = args.GetSize();
  proc_table_.SendSemanticsAction(GetEngineHandle(), &info);
}

void EmbedderAndroidEngine::SetSemanticsEnabled(bool enabled) {
  if (IsValid() && proc_table_.UpdateSemanticsEnabled) {
    proc_table_.UpdateSemanticsEnabled(GetEngineHandle(), enabled);
  }
}

void EmbedderAndroidEngine::SetAccessibilityFeatures(int32_t flags) {
  if (IsValid() && proc_table_.UpdateAccessibilityFeatures) {
    proc_table_.UpdateAccessibilityFeatures(
        GetEngineHandle(), static_cast<FlutterAccessibilityFeature>(flags));
  }
}

bool EmbedderAndroidEngine::UpdateSemantics(
    int64_t view_id,
    const flutter::SemanticsNodeUpdates& update,
    const flutter::CustomAccessibilityActionUpdates& actions) {
  if (jni_facade_ == nullptr) {
    return false;
  }
  EmbedderSemanticsUpdate2 embedder_update(view_id, update, actions);
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;
  std::vector<uint8_t> actions_buffer;
  std::vector<std::string> action_strings;
  SerializeSemanticsUpdate(embedder_update.get(), buffer, strings,
                           string_attribute_args, actions_buffer,
                           action_strings);
  if (!actions_buffer.empty()) {
    jni_facade_->FlutterViewUpdateCustomAccessibilityActions(
        std::move(actions_buffer), std::move(action_strings));
  }
  if (!buffer.empty()) {
    jni_facade_->FlutterViewUpdateSemantics(std::move(buffer),
                                            std::move(strings),
                                            std::move(string_attribute_args));
  }
  return true;
}

void EmbedderAndroidEngine::OnVsyncCallback(intptr_t baton) {
  if (vsync_waiter_ != nullptr) {
    vsync_waiter_->AsyncWaitForVsync(baton);
  }
}

void EmbedderAndroidEngine::RegisterTexture(
    std::shared_ptr<flutter::Texture> texture) {
  if (!IsValid() || !texture) {
    return;
  }
  if (c_api_engine_ != nullptr && proc_table_.RegisterExternalTexture) {
    proc_table_.RegisterExternalTexture(GetEngineHandle(), texture->Id());
  } else if (embedder_engine_) {
    if (auto platform_view = embedder_engine_->GetShell().GetPlatformView()) {
      platform_view->RegisterTexture(std::move(texture));
    } else {
      GetDelegate().OnPlatformViewRegisterTexture(std::move(texture));
    }
  }
}

void EmbedderAndroidEngine::UnregisterTexture(int64_t texture_id) {
  if (IsValid() && proc_table_.UnregisterExternalTexture) {
    proc_table_.UnregisterExternalTexture(GetEngineHandle(), texture_id);
  }
}

void EmbedderAndroidEngine::MarkTextureFrameAvailable(int64_t texture_id) {
  if (IsValid() && proc_table_.MarkExternalTextureFrameAvailable) {
    proc_table_.MarkExternalTextureFrameAvailable(GetEngineHandle(),
                                                  texture_id);
  }
}

void EmbedderAndroidEngine::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  if (!IsValid() || !proc_table_.LoadDartDeferredLibrary) {
    return;
  }
  struct DeferredLibraryContext {
    std::unique_ptr<const fml::Mapping> data;
    std::unique_ptr<const fml::Mapping> instructions;
  };
  auto* context = new DeferredLibraryContext{std::move(snapshot_data),
                                             std::move(snapshot_instructions)};
  FlutterDartDeferredLibrary deferred = {};
  deferred.struct_size = sizeof(FlutterDartDeferredLibrary);
  deferred.loading_unit_id = loading_unit_id;
  if (context->data) {
    deferred.data = context->data->GetMapping();
    deferred.data_size = context->data->GetSize();
  }
  if (context->instructions) {
    deferred.instructions = context->instructions->GetMapping();
    deferred.instructions_size = context->instructions->GetSize();
  }
  deferred.user_data = context;
  deferred.destruction_callback = [](void* user_data) {
    delete static_cast<DeferredLibraryContext*>(user_data);
  };
  if (proc_table_.LoadDartDeferredLibrary(GetEngineHandle(), &deferred) !=
      kSuccess) {
    delete context;
  }
}

void EmbedderAndroidEngine::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  if (!IsValid() || !proc_table_.NotifyDartDeferredLibraryLoadError) {
    return;
  }
  FlutterDartDeferredLibraryLoadError error = {};
  error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  error.loading_unit_id = loading_unit_id;
  error.error_message = error_message.c_str();
  error.transient = transient;
  proc_table_.NotifyDartDeferredLibraryLoadError(GetEngineHandle(), &error);
}

void EmbedderAndroidEngine::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (!IsValid() || !updated_asset_resolver) {
    return;
  }
  if (type == AssetResolver::AssetResolverType::kApkAssetProvider &&
      proc_table_.UpdateAssetResolver) {
    auto* apk_provider =
        static_cast<APKAssetProvider*>(updated_asset_resolver.get());
    FlutterAssetResolver c_resolver = apk_provider->ToFlutterAssetResolver();
    FlutterAssetResolverRegistrationInfo info = {};
    info.struct_size = sizeof(FlutterAssetResolverRegistrationInfo);
    info.resolver = &c_resolver;
    if (proc_table_.UpdateAssetResolver(GetEngineHandle(), &info) != kSuccess &&
        c_resolver.destruction_callback != nullptr) {
      c_resolver.destruction_callback(c_resolver.user_data);
    }
  } else if (embedder_engine_) {
    GetDelegate().UpdateAssetResolverByType(std::move(updated_asset_resolver),
                                            type);
  }
}

void EmbedderAndroidEngine::PopulateRendererConfig(
    FlutterRendererConfig* config) {
  std::memset(config, 0, sizeof(FlutterRendererConfig));
  switch (android_rendering_api_) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      config->type = kSoftware;
      config->software.struct_size = sizeof(FlutterSoftwareRendererConfig);
      config->software.surface_present_callback =
          [](void* user_data, const void* allocation, size_t row_bytes,
             size_t height) -> bool {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return engine != nullptr && engine->GetSurfaceManager() != nullptr &&
               engine->GetSurfaceManager()->PresentSoftware(allocation,
                                                            row_bytes, height);
      };
      break;
    case AndroidRenderingAPI::kSkiaOpenGLES:
#endif
    case AndroidRenderingAPI::kImpellerAutoselect:
    case AndroidRenderingAPI::kImpellerOpenGLES:
    case AndroidRenderingAPI::kImpellerVulkan:
      config->type = kOpenGL;
      config->open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
      config->open_gl.make_current = [](void* user_data) -> bool {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return engine != nullptr && engine->GetSurfaceManager() != nullptr &&
               engine->GetSurfaceManager()->MakeCurrent();
      };
      config->open_gl.clear_current = [](void* user_data) -> bool {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return engine != nullptr && engine->GetSurfaceManager() != nullptr &&
               engine->GetSurfaceManager()->ClearCurrent();
      };
      config->open_gl.present = [](void* user_data) -> bool {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return engine != nullptr && engine->GetSurfaceManager() != nullptr &&
               engine->GetSurfaceManager()->Present();
      };
      config->open_gl.fbo_callback = [](void* user_data) -> uint32_t {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return (engine != nullptr && engine->GetSurfaceManager() != nullptr)
                   ? engine->GetSurfaceManager()->GetFBO()
                   : 0;
      };
      config->open_gl.make_resource_current = [](void* user_data) -> bool {
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        return engine != nullptr && engine->GetSurfaceManager() != nullptr &&
               engine->GetSurfaceManager()->MakeResourceCurrent();
      };
      config->open_gl.gl_proc_resolver = [](void*, const char* name) -> void* {
#if FML_OS_ANDROID
        static auto gles_library = []() -> fml::RefPtr<fml::NativeLibrary> {
          auto lib = fml::NativeLibrary::Create("libGLESv3.so");
          if (!lib) {
            lib = fml::NativeLibrary::Create("libGLESv2.so");
          }
          return lib;
        }();
        if (gles_library) {
          if (auto* proc = gles_library->ResolveSymbol(name)) {
            return const_cast<uint8_t*>(proc);
          }
        }
        if (auto* proc = reinterpret_cast<void*>(eglGetProcAddress(name))) {
          return proc;
        }
#endif
        static fml::RefPtr<fml::NativeLibrary> proc_library =
            fml::NativeLibrary::CreateForCurrentProcess();
        return proc_library ? static_cast<void*>(const_cast<uint8_t*>(
                                  proc_library->ResolveSymbol(name)))
                            : nullptr;
      };
      break;
  }
}

bool EmbedderAndroidEngine::Run(
    std::unique_ptr<APKAssetProvider> asset_provider,
    const std::string& entrypoint,
    const std::string& library_url,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  if (c_api_engine_ != nullptr) {
    return false;
  }

  apk_asset_provider_ = std::move(asset_provider);
  if (apk_asset_provider_ != nullptr) {
    asset_resolver_ = apk_asset_provider_->ToFlutterAssetResolver();
    asset_resolvers_array_[0] = &asset_resolver_;
  }

  PopulateRendererConfig(&renderer_config_);
  compositor_->PopulateCompositorConfig(&embedder_compositor_);

  std::memset(&project_args_, 0, sizeof(FlutterProjectArgs));
  project_args_.struct_size = sizeof(FlutterProjectArgs);
  project_args_.custom_task_runners =
      &android_task_runners_->GetCustomTaskRunners();
  project_args_.compositor = &embedder_compositor_;
  if (apk_asset_provider_ != nullptr) {
    project_args_.asset_resolvers = asset_resolvers_array_;
    project_args_.asset_resolvers_count = 1;
  }

  std::string assets_dir;
  if (!settings_.application_kernel_asset.empty()) {
    assets_dir =
        fml::paths::GetDirectoryName(settings_.application_kernel_asset);
    project_args_.assets_path = assets_dir.c_str();
  } else if (!settings_.assets_path.empty()) {
    project_args_.assets_path = settings_.assets_path.c_str();
  }
  if (!settings_.icu_data_path.empty()) {
    project_args_.icu_data_path = settings_.icu_data_path.c_str();
  }
  if (!settings_.temp_directory_path.empty()) {
    project_args_.persistent_cache_path = settings_.temp_directory_path.c_str();
  }
  if (!settings_.log_tag.empty()) {
    project_args_.log_tag = settings_.log_tag.c_str();
  }

  std::vector<std::string> cmd_strings;
  cmd_strings.push_back("flutter");
  bool impeller_active =
      (android_rendering_api_ == AndroidRenderingAPI::kImpellerAutoselect ||
       android_rendering_api_ == AndroidRenderingAPI::kImpellerOpenGLES ||
       android_rendering_api_ == AndroidRenderingAPI::kImpellerVulkan);
  if (impeller_active && settings_.enable_impeller) {
    cmd_strings.push_back("--enable-impeller=true");
  } else {
    cmd_strings.push_back("--enable-impeller=false");
  }
  if (settings_.enable_vm_service) {
    cmd_strings.push_back("--vm-service-port=" +
                          std::to_string(settings_.vm_service_port));
  }
  if (settings_.disable_service_auth_codes) {
    cmd_strings.push_back("--disable-service-auth-codes");
  }
  if (settings_.enable_service_port_fallback) {
    cmd_strings.push_back("--enable-service-port-fallback");
  }
  if (settings_.enable_dart_profiling) {
    cmd_strings.push_back("--enable-dart-profiling");
  }
  if (settings_.start_paused) {
    cmd_strings.push_back("--start-paused");
  }
  std::vector<const char*> cmd_ptrs;
  cmd_ptrs.reserve(cmd_strings.size());
  for (const auto& s : cmd_strings) {
    cmd_ptrs.push_back(s.c_str());
  }
  project_args_.command_line_argc = static_cast<int>(cmd_ptrs.size());
  project_args_.command_line_argv = cmd_ptrs.data();

  std::vector<const char*> dart_entrypoint_ptrs;
  dart_entrypoint_ptrs.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    dart_entrypoint_ptrs.push_back(arg.c_str());
  }
  if (!dart_entrypoint_ptrs.empty()) {
    project_args_.dart_entrypoint_argc =
        static_cast<int>(dart_entrypoint_ptrs.size());
    project_args_.dart_entrypoint_argv = dart_entrypoint_ptrs.data();
  }

  project_args_.custom_dart_entrypoint =
      entrypoint.empty() ? nullptr : entrypoint.c_str();
  project_args_.engine_id = engine_id;
  project_args_.log_message_callback = [](const char* tag, const char* message,
                                          void* user_data) {
#if FML_OS_ANDROID
    __android_log_print(ANDROID_LOG_INFO, tag ? tag : "flutter", "%s",
                        message ? message : "");
#endif
  };
  project_args_.platform_message_callback =
      [](const FlutterPlatformMessage* message, void* user_data) {
        if (message == nullptr || user_data == nullptr) {
          return;
        }
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        fml::RefPtr<PlatformMessageResponse> response;
        if (message->response_handle != nullptr) {
          response = EmbedderPlatformMessageResponse::Create(
              engine->GetEngineHandle(),
              engine->proc_table_.SendPlatformMessageResponse,
              message->response_handle);
        }
        std::unique_ptr<PlatformMessage> platform_msg;
        if (message->message != nullptr && message->message_size > 0) {
          platform_msg = std::make_unique<PlatformMessage>(
              message->channel ? message->channel : "",
              fml::MallocMapping::Copy(message->message, message->message_size),
              std::move(response));
        } else {
          platform_msg = std::make_unique<PlatformMessage>(
              message->channel ? message->channel : "", std::move(response));
        }
        if (engine->platform_message_handler_ != nullptr) {
          engine->platform_message_handler_->HandlePlatformMessage(
              std::move(platform_msg));
        } else if (engine->jni_facade_ != nullptr) {
          engine->jni_facade_->FlutterViewHandlePlatformMessage(
              std::move(platform_msg), 0);
        }
      };
  project_args_.update_semantics_callback2 =
      [](const FlutterSemanticsUpdate2* update, void* user_data) {
        if (update == nullptr || user_data == nullptr) {
          return;
        }
        auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
        if (engine->jni_facade_ == nullptr) {
          return;
        }
        std::vector<uint8_t> buffer;
        std::vector<std::string> strings;
        std::vector<std::vector<uint8_t>> string_attribute_args;
        std::vector<uint8_t> actions_buffer;
        std::vector<std::string> action_strings;
        SerializeSemanticsUpdate(update, buffer, strings, string_attribute_args,
                                 actions_buffer, action_strings);
        if (!actions_buffer.empty()) {
          engine->jni_facade_->FlutterViewUpdateCustomAccessibilityActions(
              std::move(actions_buffer), std::move(action_strings));
        }
        if (!buffer.empty()) {
          engine->jni_facade_->FlutterViewUpdateSemantics(
              std::move(buffer), std::move(strings),
              std::move(string_attribute_args));
        }
      };
  project_args_.vsync_callback = [](void* user_data, intptr_t baton) {
    auto* engine = static_cast<EmbedderAndroidEngine*>(user_data);
    if (engine != nullptr && engine->vsync_waiter_ != nullptr) {
      engine->vsync_waiter_->AsyncWaitForVsync(baton);
    }
  };

  FlutterEngineResult result =
      proc_table_.Initialize(FLUTTER_ENGINE_VERSION, &renderer_config_,
                             &project_args_, this, &c_api_engine_);
  if (result != kSuccess || c_api_engine_ == nullptr) {
    return false;
  }

  // FlutterEngineInitialize takes ownership of the asset resolver's destruction
  // callback via EmbedderAssetResolver. Clear our local pointer so our
  // destructor or error paths do not double-free it.
  asset_resolver_.destruction_callback = nullptr;

  android_task_runners_->SetEngine(c_api_engine_);
  if (vsync_waiter_ != nullptr) {
    vsync_waiter_->SetEngine(c_api_engine_);
  }
  BindPlatformMessageHandler();

  result = proc_table_.RunInitialized(c_api_engine_);
  if (result != kSuccess) {
    proc_table_.Shutdown(c_api_engine_);
    c_api_engine_ = nullptr;
    return false;
  }

  c_api_is_valid_ = true;
  if (surface_attached_) {
    proc_table_.NotifyCreated(c_api_engine_);
    proc_table_.ScheduleFrame(c_api_engine_);
  }
  return true;
}

std::unique_ptr<EmbedderAndroidEngine> EmbedderAndroidEngine::SpawnCAPI(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const std::string& entrypoint,
    const std::string& library_url,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  if (!IsValid()) {
    return nullptr;
  }
  TaskRunners parent_runners("io.flutter",
                             android_task_runners_->GetPlatformTaskRunner(),
                             android_task_runners_->GetRasterTaskRunner(),
                             android_task_runners_->GetUITaskRunner(),
                             android_task_runners_->GetUITaskRunner());
  auto child = std::make_unique<EmbedderAndroidEngine>(
      parent_runners, nullptr, settings_, std::move(jni_facade),
      android_rendering_api_);

  if (apk_asset_provider_ != nullptr) {
    child->apk_asset_provider_ = apk_asset_provider_->Clone();
    child->asset_resolver_ =
        child->apk_asset_provider_->ToFlutterAssetResolver();
    child->asset_resolvers_array_[0] = &child->asset_resolver_;
  }

  child->PopulateRendererConfig(&child->renderer_config_);
  child->compositor_->PopulateCompositorConfig(&child->embedder_compositor_);

  std::memset(&child->project_args_, 0, sizeof(FlutterProjectArgs));
  child->project_args_.struct_size = sizeof(FlutterProjectArgs);
  // FlutterEngineSpawn requires custom_task_runners to be nullptr because
  // spawned engines automatically share the parent's ThreadHost and
  // TaskRunners.
  child->project_args_.custom_task_runners = nullptr;
  child->project_args_.compositor = &child->embedder_compositor_;
  if (child->apk_asset_provider_ != nullptr) {
    child->project_args_.asset_resolvers = child->asset_resolvers_array_;
    child->project_args_.asset_resolvers_count = 1;
  }
  child->project_args_.custom_dart_entrypoint =
      entrypoint.empty() ? nullptr : entrypoint.c_str();
  child->project_args_.engine_id = engine_id;
  child->project_args_.log_message_callback =
      project_args_.log_message_callback;
  child->project_args_.platform_message_callback =
      project_args_.platform_message_callback;
  child->project_args_.update_semantics_callback2 =
      project_args_.update_semantics_callback2;
  child->project_args_.vsync_callback = project_args_.vsync_callback;

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &child->renderer_config_;
  spawn_config.project_args = &child->project_args_;
  spawn_config.initial_route =
      initial_route.empty() ? nullptr : initial_route.c_str();
  spawn_config.user_data = child.get();

  FlutterEngineResult result = proc_table_.Spawn(
      GetEngineHandle(), &spawn_config, &child->c_api_engine_);
  if (result != kSuccess || child->c_api_engine_ == nullptr) {
    return nullptr;
  }
  child->asset_resolver_.destruction_callback = nullptr;
  child->android_task_runners_->SetEngine(child->c_api_engine_);
  if (child->vsync_waiter_ != nullptr) {
    child->vsync_waiter_->SetEngine(child->c_api_engine_);
  }
  child->BindPlatformMessageHandler();
  child->c_api_is_valid_ = true;
  return child;
}

void EmbedderAndroidEngine::NotifySurfaceCreated(ANativeWindow* window,
                                                 bool is_fake_window) {
  if (surface_manager_ != nullptr) {
    surface_manager_->SetNativeWindow(window, is_fake_window);
  }
  surface_attached_ = true;
  if (IsValid() && proc_table_.NotifyCreated) {
    proc_table_.NotifyCreated(GetEngineHandle());
    proc_table_.ScheduleFrame(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::NotifySurfaceChanged(size_t width, size_t height) {
  if (IsValid() && proc_table_.ScheduleFrame) {
    proc_table_.ScheduleFrame(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::NotifySurfaceWindowChanged(ANativeWindow* window,
                                                       bool is_fake_window) {
  if (surface_manager_ != nullptr) {
    surface_manager_->SetNativeWindow(window, is_fake_window);
  }
  surface_attached_ = true;
  if (IsValid() && proc_table_.ScheduleFrame) {
    proc_table_.ScheduleFrame(GetEngineHandle());
  }
}

void EmbedderAndroidEngine::NotifySurfaceDestroyed() {
  if (IsValid() && surface_attached_ && proc_table_.NotifyDestroyed) {
    proc_table_.NotifyDestroyed(GetEngineHandle());
  }
  surface_attached_ = false;
  if (surface_manager_ != nullptr) {
    surface_manager_->ClearNativeWindow();
  }
}

void EmbedderAndroidEngine::SetSurfaceControlEnabled(bool enabled) {
  surface_control_enabled_ = enabled;
}

bool EmbedderAndroidEngine::IsSurfaceControlEnabled() const {
  return surface_control_enabled_;
}

void EmbedderAndroidEngine::OnBeginFrame() {
  if (jni_facade_ != nullptr && android_task_runners_ != nullptr) {
    if (!IsSurfaceControlEnabled()) {
      android_task_runners_->GetPlatformTaskRunner()->PostTask(
          [jni = jni_facade_]() { jni->FlutterViewBeginFrame(); });
    }
  }
}

DlPath EmbedderAndroidEngine::ToDlPath(const FlutterPath& path) {
  // This is the inverse of `EmbedderPathReceiver` in
  // `shell/platform/embedder/embedder_layers.cc`, which flattens a `DlPath`
  // into the `FlutterPath` handed to embedders.
  DlPathBuilder builder;
  builder.SetFillType(path.fill_type == kFlutterPathFillTypeEvenOdd
                          ? DlPathFillType::kOdd
                          : DlPathFillType::kNonZero);

  if (path.struct_size < sizeof(FlutterPath) || path.segments == nullptr) {
    return builder.TakePath();
  }

  auto to_point = [](const FlutterPoint& point) {
    return DlPoint(static_cast<DlScalar>(point.x),
                   static_cast<DlScalar>(point.y));
  };

  for (size_t i = 0; i < path.segments_count; ++i) {
    const FlutterPathSegment& segment = path.segments[i];
    switch (segment.verb) {
      case kFlutterPathVerbMove:
        builder.MoveTo(to_point(segment.points[0]));
        break;
      case kFlutterPathVerbLine:
        builder.LineTo(to_point(segment.points[0]));
        break;
      case kFlutterPathVerbQuad:
        builder.QuadraticCurveTo(to_point(segment.points[0]),
                                 to_point(segment.points[1]));
        break;
      case kFlutterPathVerbConic:
        builder.ConicCurveTo(to_point(segment.points[0]),
                             to_point(segment.points[1]),
                             static_cast<DlScalar>(segment.conic_weight));
        break;
      case kFlutterPathVerbCubic:
        builder.CubicCurveTo(to_point(segment.points[0]),
                             to_point(segment.points[1]),
                             to_point(segment.points[2]));
        break;
      case kFlutterPathVerbClose:
        builder.Close();
        break;
    }
  }

  return builder.TakePath();
}

MutatorsStack EmbedderAndroidEngine::ToMutatorsStack(
    size_t mutations_count,
    const FlutterPlatformViewMutation** mutations) {
  MutatorsStack mutators_stack;
  if (mutations == nullptr) {
    return mutators_stack;
  }

  for (size_t i = 0; i < mutations_count; ++i) {
    const FlutterPlatformViewMutation* m = mutations[i];
    if (m == nullptr) {
      continue;
    }
    switch (m->type) {
      case kFlutterPlatformViewMutationTypeTransformation: {
        const auto& t = m->transformation;
        mutators_stack.PushTransform(DlMatrix::MakeColumn(
            static_cast<float>(t.scaleX), static_cast<float>(t.skewY), 0.0f,
            static_cast<float>(t.pers0), static_cast<float>(t.skewX),
            static_cast<float>(t.scaleY), 0.0f, static_cast<float>(t.pers1),
            0.0f, 0.0f, 1.0f, 0.0f, static_cast<float>(t.transX),
            static_cast<float>(t.transY), 0.0f, static_cast<float>(t.pers2)));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRect: {
        const auto& r = m->clip_rect;
        mutators_stack.PushClipRect(DlRect::MakeLTRB(
            static_cast<float>(r.left), static_cast<float>(r.top),
            static_cast<float>(r.right), static_cast<float>(r.bottom)));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundedRect: {
        const auto& rr = m->clip_rounded_rect;
        DlRoundingRadii radii;
        radii.top_left =
            DlSize(static_cast<float>(rr.upper_left_corner_radius.width),
                   static_cast<float>(rr.upper_left_corner_radius.height));
        radii.top_right =
            DlSize(static_cast<float>(rr.upper_right_corner_radius.width),
                   static_cast<float>(rr.upper_right_corner_radius.height));
        radii.bottom_right =
            DlSize(static_cast<float>(rr.lower_right_corner_radius.width),
                   static_cast<float>(rr.lower_right_corner_radius.height));
        radii.bottom_left =
            DlSize(static_cast<float>(rr.lower_left_corner_radius.width),
                   static_cast<float>(rr.lower_left_corner_radius.height));
        mutators_stack.PushClipRRect(DlRoundRect::MakeRectRadii(
            DlRect::MakeLTRB(static_cast<float>(rr.rect.left),
                             static_cast<float>(rr.rect.top),
                             static_cast<float>(rr.rect.right),
                             static_cast<float>(rr.rect.bottom)),
            radii));
        break;
      }
      case kFlutterPlatformViewMutationTypeOpacity: {
        uint8_t alpha =
            static_cast<uint8_t>(std::clamp(m->opacity, 0.0, 1.0) * 255.0);
        mutators_stack.PushOpacity(alpha);
        break;
      }
      case kFlutterPlatformViewMutationTypeClipRoundSuperellipse: {
        const auto& rse = m->clip_round_superellipse;
        DlRoundingRadii radii;
        radii.top_left =
            DlSize(static_cast<float>(rse.upper_left_corner_radius.width),
                   static_cast<float>(rse.upper_left_corner_radius.height));
        radii.top_right =
            DlSize(static_cast<float>(rse.upper_right_corner_radius.width),
                   static_cast<float>(rse.upper_right_corner_radius.height));
        radii.bottom_right =
            DlSize(static_cast<float>(rse.lower_right_corner_radius.width),
                   static_cast<float>(rse.lower_right_corner_radius.height));
        radii.bottom_left =
            DlSize(static_cast<float>(rse.lower_left_corner_radius.width),
                   static_cast<float>(rse.lower_left_corner_radius.height));
        mutators_stack.PushClipRSE(DlRoundSuperellipse::MakeRectRadii(
            DlRect::MakeLTRB(static_cast<float>(rse.rect.left),
                             static_cast<float>(rse.rect.top),
                             static_cast<float>(rse.rect.right),
                             static_cast<float>(rse.rect.bottom)),
            radii));
        break;
      }
      case kFlutterPlatformViewMutationTypeClipPath: {
        mutators_stack.PushClipPath(ToDlPath(m->clip_path));
        break;
      }
        // No `default:` arm. Every mutation type must be handled explicitly so
        // that -Wswitch fails the build when a new one is added, rather than
        // the mutation being silently dropped.
    }
  }

  return mutators_stack;
}

void EmbedderAndroidEngine::OnPlatformViewPresented(
    int64_t view_id,
    const FlutterPoint& offset,
    const FlutterSize& size,
    size_t mutations_count,
    const FlutterPlatformViewMutation** mutations) {
  if (jni_facade_ == nullptr || android_task_runners_ == nullptr) {
    return;
  }
  int x = static_cast<int>(std::round(offset.x));
  int y = static_cast<int>(std::round(offset.y));
  int width = static_cast<int>(std::round(size.width));
  int height = static_cast<int>(std::round(size.height));
  bool is_surface_control = IsSurfaceControlEnabled();

  MutatorsStack mutators_stack = ToMutatorsStack(mutations_count, mutations);

  android_task_runners_->GetPlatformTaskRunner()->PostTask(
      [jni = jni_facade_, is_surface_control, view_id, x, y, width, height,
       mutators_stack = std::move(mutators_stack)]() mutable {
        if (is_surface_control) {
          jni->onDisplayPlatformView2(static_cast<int>(view_id), x, y, width,
                                      height, width, height,
                                      std::move(mutators_stack));
        } else {
          jni->FlutterViewOnDisplayPlatformView(static_cast<int>(view_id), x, y,
                                                width, height, width, height,
                                                std::move(mutators_stack));
        }
      });
}

void EmbedderAndroidEngine::OnFramePresented() {
  if (jni_facade_ != nullptr && android_task_runners_ != nullptr) {
    bool is_first_frame = !first_frame_presented_.exchange(true);
    bool is_surface_control = IsSurfaceControlEnabled();
    android_task_runners_->GetPlatformTaskRunner()->PostTask(
        [jni = jni_facade_, is_first_frame, is_surface_control]() {
          if (is_first_frame) {
            jni->FlutterViewOnFirstFrame();
          }
          if (is_surface_control) {
            jni->swapTransaction();
            jni->onEndFrame2();
          } else {
            jni->FlutterViewEndFrame();
          }
        });
  }
}

FlutterPointerPhase EmbedderAndroidEngine::ToFlutterPointerPhase(
    int64_t change) {
  switch (change) {
    case 0:
      return kCancel;
    case 1:
      return kAdd;
    case 2:
      return kRemove;
    case 3:
      return kHover;
    case 4:
      return kDown;
    case 5:
      return kMove;
    case 6:
      return kUp;
    case 7:
      return kPanZoomStart;
    case 8:
      return kPanZoomUpdate;
    case 9:
      return kPanZoomEnd;
    default:
      return kCancel;
  }
}

FlutterPointerDeviceKind EmbedderAndroidEngine::ToFlutterPointerDeviceKind(
    int64_t kind) {
  switch (kind) {
    case 0:
      return kFlutterPointerDeviceKindTouch;
    case 1:
      return kFlutterPointerDeviceKindMouse;
    case 2:
      return kFlutterPointerDeviceKindStylus;
    case 3:
      return kFlutterPointerDeviceKindInvertedStylus;
    case 4:
      return kFlutterPointerDeviceKindTrackpad;
    default:
      return kFlutterPointerDeviceKindTouch;
  }
}

FlutterPointerSignalKind EmbedderAndroidEngine::ToFlutterPointerSignalKind(
    int64_t signal_kind) {
  switch (signal_kind) {
    case 0:
      return kFlutterPointerSignalKindNone;
    case 1:
      return kFlutterPointerSignalKindScroll;
    case 2:
      return kFlutterPointerSignalKindScrollInertiaCancel;
    case 3:
      return kFlutterPointerSignalKindScale;
    default:
      return kFlutterPointerSignalKindNone;
  }
}

std::vector<FlutterPointerEvent> EmbedderAndroidEngine::UnpackPointerDataPacket(
    const uint8_t* buffer,
    size_t position) {
  std::vector<FlutterPointerEvent> events;
  if (buffer == nullptr || position < kBytesPerPointerEntry ||
      position % kBytesPerPointerEntry != 0) {
    return events;
  }
  size_t count = position / kBytesPerPointerEntry;
  events.reserve(count);
  for (size_t i = 0; i < count; ++i) {
    const uint8_t* entry = buffer + i * kBytesPerPointerEntry;
    const int64_t* int_fields = reinterpret_cast<const int64_t*>(entry);
    const double* double_fields = reinterpret_cast<const double*>(entry);

    FlutterPointerEvent event = {};
    event.struct_size = sizeof(FlutterPointerEvent);
    event.embedder_id = int_fields[0];
    event.timestamp = static_cast<size_t>(int_fields[1]);
    event.phase = ToFlutterPointerPhase(int_fields[2]);
    event.device_kind = ToFlutterPointerDeviceKind(int_fields[3]);
    event.signal_kind = ToFlutterPointerSignalKind(int_fields[4]);
    event.device = static_cast<int32_t>(int_fields[5]);
    event.x = double_fields[7];
    event.y = double_fields[8];
    event.buttons = int_fields[11];
    event.pressure = double_fields[14];
    event.pressure_min = double_fields[15];
    event.pressure_max = double_fields[16];
    event.distance = double_fields[17];
    event.distance_max = double_fields[18];
    event.size = double_fields[19];
    event.radius_major = double_fields[20];
    event.radius_minor = double_fields[21];
    event.radius_min = double_fields[22];
    event.radius_max = double_fields[23];
    event.orientation = double_fields[24];
    event.tilt = double_fields[25];
    event.platform_data = int_fields[26];
    event.scroll_delta_x = double_fields[27];
    event.scroll_delta_y = double_fields[28];
    event.pan_x = double_fields[29];
    event.pan_y = double_fields[30];
    event.scale = double_fields[33];
    event.rotation = double_fields[34];
    event.view_id = int_fields[35];
    events.push_back(event);
  }
  return events;
}

void EmbedderAndroidEngine::SerializeSemanticsUpdate(
    const FlutterSemanticsUpdate2* update,
    std::vector<uint8_t>& buffer,
    std::vector<std::string>& strings,
    std::vector<std::vector<uint8_t>>& string_attribute_args,
    std::vector<uint8_t>& actions_buffer,
    std::vector<std::string>& action_strings) {
  if (update == nullptr) {
    return;
  }
  android::EncodedSemanticsBatch batch =
      android::AndroidSemanticsMapper::MapSemanticsUpdate(*update);
  buffer = std::move(batch.nodes.buffer);
  strings = std::move(batch.nodes.strings);
  string_attribute_args = std::move(batch.nodes.string_attribute_args);
  actions_buffer = std::move(batch.custom_actions.buffer);
  action_strings = std::move(batch.custom_actions.strings);
}

}  // namespace flutter
