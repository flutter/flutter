// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_android_engine.h"

#include <utility>
#include <vector>

#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "third_party/skia/include/core/SkData.h"

namespace flutter {

EmbedderAndroidEngine::EmbedderAndroidEngine(const TaskRunners& task_runners,
                                             std::unique_ptr<Shell> shell)
    : embedder_engine_(
          std::make_unique<EmbedderEngine>(task_runners, std::move(shell))) {
  proc_table_.struct_size = sizeof(FlutterEngineProcTable);
  FlutterEngineResult result = FlutterEngineGetProcAddresses(&proc_table_);
  FML_CHECK(result == kSuccess);
  FML_DCHECK(embedder_engine_ && embedder_engine_->IsValid());
}

EmbedderAndroidEngine::~EmbedderAndroidEngine() {
  if (embedder_engine_) {
    embedder_engine_->CollectShell();
  }
}

bool EmbedderAndroidEngine::IsValid() const {
  return embedder_engine_ && embedder_engine_->IsValid();
}

bool EmbedderAndroidEngine::IsSetup() const {
  return IsValid() && embedder_engine_->GetShell().IsSetup();
}

void EmbedderAndroidEngine::RunEngine(RunConfiguration run_configuration) {
  FML_DCHECK(IsValid());
  embedder_engine_->GetShell().RunEngine(std::move(run_configuration));
}

std::unique_ptr<AndroidEngine> EmbedderAndroidEngine::Spawn(
    RunConfiguration run_configuration,
    const std::string& initial_route,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer) const {
  FML_DCHECK(IsValid());
  auto spawned_shell = embedder_engine_->GetShell().Spawn(
      std::move(run_configuration), initial_route, on_create_platform_view,
      on_create_rasterizer);
  if (!spawned_shell) {
    return nullptr;
  }
  const auto& task_runners = spawned_shell->GetTaskRunners();
  return std::make_unique<EmbedderAndroidEngine>(task_runners,
                                                 std::move(spawned_shell));
}

Rasterizer::Screenshot EmbedderAndroidEngine::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  Rasterizer::Screenshot result{nullptr, DlISize(), "",
                                Rasterizer::ScreenshotFormat::kUnknown};
  if (!IsValid()) {
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
          kSuccess &&
      screenshot.data != nullptr && screenshot.data_length > 0) {
    result.frame_size = DlISize(screenshot.width, screenshot.height);
    result.data = SkData::MakeWithCopy(screenshot.data, screenshot.data_length);
    proc_table_.FreeScreenshot(&screenshot);
  }
  return result;
}

void EmbedderAndroidEngine::NotifyLowMemoryWarning() {
  if (!IsValid()) {
    return;
  }
  // Note: Do not use proc_table_.NotifyLowMemoryWarning here because it also
  // sends a {"type": "memoryPressure"} message on the "flutter/system" channel,
  // which Android's SystemChannel.java already sends during onTrimMemory.
  embedder_engine_->GetShell().NotifyLowMemoryWarning();
}

void EmbedderAndroidEngine::OnDisplayUpdates(
    std::vector<std::unique_ptr<Display>> displays) {
  if (!IsValid()) {
    return;
  }
  std::vector<FlutterEngineDisplay> embedder_displays;
  embedder_displays.reserve(displays.size());
  for (const auto& display : displays) {
    if (!display) {
      continue;
    }
    FlutterEngineDisplay d = {};
    d.struct_size = sizeof(FlutterEngineDisplay);
    d.display_id = display->GetDisplayId();
    d.single_display = displays.size() == 1;
    d.refresh_rate = display->GetRefreshRate();
    d.width = static_cast<size_t>(display->GetWidth());
    d.height = static_cast<size_t>(display->GetHeight());
    d.device_pixel_ratio = display->GetDevicePixelRatio();
    embedder_displays.push_back(d);
  }
  if (!embedder_displays.empty()) {
    proc_table_.NotifyDisplayUpdate(
        GetEngineHandle(), kFlutterEngineDisplaysUpdateTypeStartup,
        embedder_displays.data(), embedder_displays.size());
  }
}

const std::shared_ptr<PlatformMessageHandler>&
EmbedderAndroidEngine::GetPlatformMessageHandler() const {
  FML_CHECK(IsValid());
  return embedder_engine_->GetShell().GetPlatformMessageHandler();
}

void EmbedderAndroidEngine::RegisterImageDecoder(ImageGeneratorFactory factory,
                                                 int32_t priority) {
  if (!IsValid()) {
    return;
  }
  embedder_engine_->RegisterImageGenerator(std::move(factory), priority);
}

const TaskRunners& EmbedderAndroidEngine::GetTaskRunners() const {
  FML_CHECK(embedder_engine_);
  return embedder_engine_->GetTaskRunners();
}

Shell& EmbedderAndroidEngine::GetShell() {
  FML_CHECK(IsValid());
  return embedder_engine_->GetShell();
}

const std::unique_ptr<Shell>& EmbedderAndroidEngine::GetShellForTesting()
    const {
  return embedder_engine_->GetShellPointer();
}

void EmbedderAndroidEngine::NotifyCreated() {
  if (!IsValid()) {
    return;
  }
  proc_table_.NotifyCreated(GetEngineHandle());
}

void EmbedderAndroidEngine::NotifyDestroyed() {
  if (!IsValid()) {
    return;
  }
  proc_table_.NotifyDestroyed(GetEngineHandle());
}

void EmbedderAndroidEngine::ScheduleFrame() {
  if (!IsValid()) {
    return;
  }
  proc_table_.ScheduleFrame(GetEngineHandle());
}

void EmbedderAndroidEngine::SetNextFrameCallback(const fml::closure& closure) {
  if (!IsValid()) {
    return;
  }
  auto* closure_ptr = new fml::closure(closure);
  if (proc_table_.SetNextFrameCallback(
          GetEngineHandle(),
          [](void* user_data) {
            std::unique_ptr<fml::closure> cb(
                static_cast<fml::closure*>(user_data));
            if (*cb) {
              (*cb)();
            }
          },
          closure_ptr) != kSuccess) {
    delete closure_ptr;
  }
}

void EmbedderAndroidEngine::SetViewportMetrics(int64_t view_id,
                                               const ViewportMetrics& metrics) {
  if (!IsValid()) {
    return;
  }
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
  event.display_features_count = metrics.physical_display_features_type.size();
  event.display_features_bounds =
      metrics.physical_display_features_bounds.empty()
          ? nullptr
          : metrics.physical_display_features_bounds.data();
  event.display_features_type =
      metrics.physical_display_features_type.empty()
          ? nullptr
          : metrics.physical_display_features_type.data();
  event.display_features_state =
      metrics.physical_display_features_state.empty()
          ? nullptr
          : metrics.physical_display_features_state.data();
  event.physical_display_corner_radius_top_left =
      metrics.physical_display_corner_radius_top_left;
  event.physical_display_corner_radius_top_right =
      metrics.physical_display_corner_radius_top_right;
  event.physical_display_corner_radius_bottom_right =
      metrics.physical_display_corner_radius_bottom_right;
  event.physical_display_corner_radius_bottom_left =
      metrics.physical_display_corner_radius_bottom_left;

  proc_table_.SendWindowMetricsEvent(GetEngineHandle(), &event);
}

void EmbedderAndroidEngine::DispatchPlatformMessage(
    std::unique_ptr<PlatformMessage> message) {
  if (!IsValid()) {
    return;
  }
  embedder_engine_->SendPlatformMessage(std::move(message));
}

void EmbedderAndroidEngine::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet) {
  if (!IsValid()) {
    return;
  }
  embedder_engine_->DispatchPointerDataPacket(std::move(packet));
}

void EmbedderAndroidEngine::DispatchSemanticsAction(int64_t view_id,
                                                    int32_t node_id,
                                                    SemanticsAction action,
                                                    fml::MallocMapping args) {
  if (!IsValid()) {
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
  if (!IsValid()) {
    return;
  }
  proc_table_.UpdateSemanticsEnabled(GetEngineHandle(), enabled);
}

void EmbedderAndroidEngine::SetAccessibilityFeatures(int32_t flags) {
  if (!IsValid()) {
    return;
  }
  proc_table_.UpdateAccessibilityFeatures(
      GetEngineHandle(), static_cast<FlutterAccessibilityFeature>(flags));
}

void EmbedderAndroidEngine::RegisterTexture(
    std::shared_ptr<flutter::Texture> texture) {
  if (!IsValid()) {
    return;
  }
  if (auto platform_view = embedder_engine_->GetShell().GetPlatformView()) {
    platform_view->RegisterTexture(std::move(texture));
  } else {
    GetDelegate().OnPlatformViewRegisterTexture(std::move(texture));
  }
}

void EmbedderAndroidEngine::UnregisterTexture(int64_t texture_id) {
  if (!IsValid()) {
    return;
  }
  // Note: FlutterRenderer.java starts external texture IDs at 0, which
  // proc_table_.UnregisterExternalTexture rejects as invalid. Delegate directly
  // to EmbedderEngine::UnregisterTexture so texture_id == 0 is supported.
  embedder_engine_->UnregisterTexture(texture_id);
}

void EmbedderAndroidEngine::MarkTextureFrameAvailable(int64_t texture_id) {
  if (!IsValid()) {
    return;
  }
  // Note: FlutterRenderer.java starts external texture IDs at 0, which
  // proc_table_.MarkExternalTextureFrameAvailable rejects as invalid. Delegate
  // directly to EmbedderEngine::MarkTextureFrameAvailable so texture_id == 0 is
  // supported.
  embedder_engine_->MarkTextureFrameAvailable(texture_id);
}

void EmbedderAndroidEngine::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  if (!IsValid()) {
    return;
  }
  FlutterDartDeferredLibrary lib = {};
  lib.struct_size = sizeof(FlutterDartDeferredLibrary);
  lib.loading_unit_id = loading_unit_id;
  lib.data = snapshot_data ? snapshot_data->GetMapping() : nullptr;
  lib.data_size = snapshot_data ? snapshot_data->GetSize() : 0;
  lib.instructions =
      snapshot_instructions ? snapshot_instructions->GetMapping() : nullptr;
  lib.instructions_size =
      snapshot_instructions ? snapshot_instructions->GetSize() : 0;

  struct LibraryContext {
    std::unique_ptr<const fml::Mapping> data;
    std::unique_ptr<const fml::Mapping> instructions;
  };
  auto* context = new LibraryContext{std::move(snapshot_data),
                                     std::move(snapshot_instructions)};
  lib.user_data = context;
  lib.destruction_callback = [](void* user_data) {
    delete static_cast<LibraryContext*>(user_data);
  };

  if (proc_table_.LoadDartDeferredLibrary(GetEngineHandle(), &lib) !=
      kSuccess) {
    delete context;
  }
}

void EmbedderAndroidEngine::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  if (!IsValid()) {
    return;
  }
  FlutterDartDeferredLibraryLoadError err = {};
  err.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  err.loading_unit_id = loading_unit_id;
  err.error_message = error_message.c_str();
  err.transient = transient;
  proc_table_.NotifyDartDeferredLibraryLoadError(GetEngineHandle(), &err);
}

void EmbedderAndroidEngine::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (!IsValid()) {
    return;
  }
  if (type == AssetResolver::AssetResolverType::kApkAssetProvider &&
      updated_asset_resolver != nullptr) {
    auto* apk_provider =
        static_cast<APKAssetProvider*>(updated_asset_resolver.get());
    FlutterAssetResolver resolver = apk_provider->ToFlutterAssetResolver();
    FlutterAssetResolverRegistrationInfo info = {};
    info.struct_size = sizeof(FlutterAssetResolverRegistrationInfo);
    info.resolver = &resolver;
    proc_table_.UpdateAssetResolver(GetEngineHandle(), &info);
    return;
  }
  embedder_engine_->UpdateAssetResolver(std::move(updated_asset_resolver),
                                        type);
}

}  // namespace flutter
