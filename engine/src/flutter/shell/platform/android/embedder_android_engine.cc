// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_android_engine.h"

#include <utility>

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
  if (!IsValid()) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  return embedder_engine_->GetShell().Screenshot(type, base64_encode);
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
  embedder_engine_->GetShell().OnDisplayUpdates(std::move(displays));
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
  embedder_engine_->GetShell().RegisterImageDecoder(std::move(factory),
                                                    priority);
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
  embedder_engine_->NotifyCreated();
}

void EmbedderAndroidEngine::NotifyDestroyed() {
  if (!IsValid()) {
    return;
  }
  embedder_engine_->NotifyDestroyed();
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
  GetDelegate().OnPlatformViewSetNextFrameCallback(closure);
}

void EmbedderAndroidEngine::SetViewportMetrics(int64_t view_id,
                                               const ViewportMetrics& metrics) {
  if (!IsValid()) {
    return;
  }
  embedder_engine_->SetViewportMetrics(view_id, metrics);
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
  embedder_engine_->DispatchSemanticsAction(view_id, node_id, action,
                                            std::move(args));
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
  GetDelegate().LoadDartDeferredLibrary(loading_unit_id,
                                        std::move(snapshot_data),
                                        std::move(snapshot_instructions));
}

void EmbedderAndroidEngine::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  if (!IsValid()) {
    return;
  }
  GetDelegate().LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                             transient);
}

void EmbedderAndroidEngine::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (!IsValid()) {
    return;
  }
  GetDelegate().UpdateAssetResolverByType(std::move(updated_asset_resolver),
                                          type);
}

}  // namespace flutter
