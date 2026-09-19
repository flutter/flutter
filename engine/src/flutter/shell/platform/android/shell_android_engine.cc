// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/shell_android_engine.h"

#include <utility>

namespace flutter {

ShellAndroidEngine::ShellAndroidEngine(std::unique_ptr<Shell> shell)
    : shell_(std::move(shell)) {
  FML_DCHECK(shell_);
}

ShellAndroidEngine::~ShellAndroidEngine() = default;

bool ShellAndroidEngine::IsValid() const {
  return shell_ != nullptr;
}

bool ShellAndroidEngine::IsSetup() const {
  return shell_ && shell_->IsSetup();
}

void ShellAndroidEngine::RunEngine(RunConfiguration run_configuration) {
  FML_DCHECK(shell_);
  shell_->RunEngine(std::move(run_configuration));
}

std::unique_ptr<AndroidEngine> ShellAndroidEngine::Spawn(
    RunConfiguration run_configuration,
    const std::string& initial_route,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer) const {
  FML_DCHECK(shell_);
  auto spawned_shell =
      shell_->Spawn(std::move(run_configuration), initial_route,
                    on_create_platform_view, on_create_rasterizer);
  if (!spawned_shell) {
    return nullptr;
  }
  return std::make_unique<ShellAndroidEngine>(std::move(spawned_shell));
}

Rasterizer::Screenshot ShellAndroidEngine::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!shell_) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  return shell_->Screenshot(type, base64_encode);
}

void ShellAndroidEngine::NotifyLowMemoryWarning() {
  if (shell_) {
    shell_->NotifyLowMemoryWarning();
  }
}

void ShellAndroidEngine::OnDisplayUpdates(
    std::vector<std::unique_ptr<Display>> displays) {
  if (shell_) {
    shell_->OnDisplayUpdates(std::move(displays));
  }
}

const std::shared_ptr<PlatformMessageHandler>&
ShellAndroidEngine::GetPlatformMessageHandler() const {
  FML_CHECK(shell_);
  return shell_->GetPlatformMessageHandler();
}

void ShellAndroidEngine::RegisterImageDecoder(ImageGeneratorFactory factory,
                                              int32_t priority) {
  if (shell_) {
    shell_->RegisterImageDecoder(std::move(factory), priority);
  }
}

const TaskRunners& ShellAndroidEngine::GetTaskRunners() const {
  FML_CHECK(shell_);
  return shell_->GetTaskRunners();
}

Shell& ShellAndroidEngine::GetShell() {
  FML_CHECK(shell_);
  return *shell_;
}

const std::unique_ptr<Shell>& ShellAndroidEngine::GetShellForTesting() const {
  return shell_;
}

void ShellAndroidEngine::NotifyCreated() {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->NotifyCreated();
  }
}

void ShellAndroidEngine::NotifyDestroyed() {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->NotifyDestroyed();
  }
}

void ShellAndroidEngine::ScheduleFrame() {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->ScheduleFrame();
  } else {
    GetDelegate().OnPlatformViewScheduleFrame();
  }
}

void ShellAndroidEngine::SetNextFrameCallback(const fml::closure& closure) {
  if (!shell_) {
    return;
  }
  GetDelegate().OnPlatformViewSetNextFrameCallback(closure);
}

void ShellAndroidEngine::SetViewportMetrics(int64_t view_id,
                                            const ViewportMetrics& metrics) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->SetViewportMetrics(view_id, metrics);
  } else {
    GetDelegate().OnPlatformViewSetViewportMetrics(view_id, metrics);
  }
}

void ShellAndroidEngine::DispatchPlatformMessage(
    std::unique_ptr<PlatformMessage> message) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->DispatchPlatformMessage(std::move(message));
  } else {
    GetDelegate().OnPlatformViewDispatchPlatformMessage(std::move(message));
  }
}

void ShellAndroidEngine::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->DispatchPointerDataPacket(std::move(packet));
  } else {
    GetDelegate().OnPlatformViewDispatchPointerDataPacket(std::move(packet));
  }
}

void ShellAndroidEngine::DispatchSemanticsAction(int64_t view_id,
                                                 int32_t node_id,
                                                 SemanticsAction action,
                                                 fml::MallocMapping args) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->DispatchSemanticsAction(view_id, node_id, action,
                                           std::move(args));
  } else {
    GetDelegate().OnPlatformViewDispatchSemanticsAction(
        view_id, node_id, action, std::move(args));
  }
}

void ShellAndroidEngine::SetSemanticsEnabled(bool enabled) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->SetSemanticsEnabled(enabled);
  } else {
    GetDelegate().OnPlatformViewSetSemanticsEnabled(enabled);
  }
}

void ShellAndroidEngine::SetAccessibilityFeatures(int32_t flags) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->SetAccessibilityFeatures(flags);
  } else {
    GetDelegate().OnPlatformViewSetAccessibilityFeatures(flags);
  }
}

void ShellAndroidEngine::RegisterTexture(
    std::shared_ptr<flutter::Texture> texture) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->RegisterTexture(std::move(texture));
  } else {
    GetDelegate().OnPlatformViewRegisterTexture(std::move(texture));
  }
}

void ShellAndroidEngine::UnregisterTexture(int64_t texture_id) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->UnregisterTexture(texture_id);
  } else {
    GetDelegate().OnPlatformViewUnregisterTexture(texture_id);
  }
}

void ShellAndroidEngine::MarkTextureFrameAvailable(int64_t texture_id) {
  if (!shell_) {
    return;
  }
  if (auto platform_view = shell_->GetPlatformView()) {
    platform_view->MarkTextureFrameAvailable(texture_id);
  } else {
    GetDelegate().OnPlatformViewMarkTextureFrameAvailable(texture_id);
  }
}

void ShellAndroidEngine::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  if (!shell_) {
    return;
  }
  GetDelegate().LoadDartDeferredLibrary(loading_unit_id,
                                        std::move(snapshot_data),
                                        std::move(snapshot_instructions));
}

void ShellAndroidEngine::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string error_message,
    bool transient) {
  if (!shell_) {
    return;
  }
  GetDelegate().LoadDartDeferredLibraryError(loading_unit_id, error_message,
                                             transient);
}

void ShellAndroidEngine::UpdateAssetResolverByType(
    std::unique_ptr<AssetResolver> updated_asset_resolver,
    AssetResolver::AssetResolverType type) {
  if (!shell_) {
    return;
  }
  GetDelegate().UpdateAssetResolverByType(std::move(updated_asset_resolver),
                                          type);
}

}  // namespace flutter
