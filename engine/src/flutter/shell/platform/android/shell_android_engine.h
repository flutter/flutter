// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_SHELL_ANDROID_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_SHELL_ANDROID_ENGINE_H_

#include "flutter/shell/platform/android/android_engine.h"

namespace flutter {

/**
 * @brief An implementation of AndroidEngine that wraps the internal
 * flutter::Shell and flutter::PlatformView.
 */
class ShellAndroidEngine final : public AndroidEngine {
 public:
  explicit ShellAndroidEngine(std::unique_ptr<Shell> shell);

  ~ShellAndroidEngine() override;

  // |AndroidEngine|
  bool IsValid() const override;

  // |AndroidEngine|
  bool IsSetup() const override;

  // |AndroidEngine|
  void RunEngine(RunConfiguration run_configuration) override;

  // |AndroidEngine|
  std::unique_ptr<AndroidEngine> Spawn(
      RunConfiguration run_configuration,
      const std::string& initial_route,
      Shell::CreateCallback<PlatformView> on_create_platform_view,
      Shell::CreateCallback<Rasterizer> on_create_rasterizer) const override;

  // |AndroidEngine|
  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode) override;

  // |AndroidEngine|
  void NotifyLowMemoryWarning() override;

  // |AndroidEngine|
  void OnDisplayUpdates(
      std::vector<std::unique_ptr<Display>> displays) override;

  // |AndroidEngine|
  const std::shared_ptr<PlatformMessageHandler>& GetPlatformMessageHandler()
      const override;

  // |AndroidEngine|
  void RegisterImageDecoder(ImageGeneratorFactory factory,
                            int32_t priority) override;

  // |AndroidEngine|
  const TaskRunners& GetTaskRunners() const override;

  // |AndroidEngine|
  Shell& GetShell() override;

  // |AndroidEngine|
  const std::unique_ptr<Shell>& GetShellForTesting() const override;

  // |AndroidEngine|
  void NotifyCreated() override;

  // |AndroidEngine|
  void NotifyDestroyed() override;

  // |AndroidEngine|
  void ScheduleFrame() override;

  // |AndroidEngine|
  void SetNextFrameCallback(const fml::closure& closure) override;

  // |AndroidEngine|
  void SetViewportMetrics(int64_t view_id,
                          const ViewportMetrics& metrics) override;

  // |AndroidEngine|
  void DispatchPlatformMessage(
      std::unique_ptr<PlatformMessage> message) override;

  // |AndroidEngine|
  void DispatchPointerDataPacket(
      std::unique_ptr<PointerDataPacket> packet) override;

  // |AndroidEngine|
  void DispatchSemanticsAction(int64_t view_id,
                               int32_t node_id,
                               SemanticsAction action,
                               fml::MallocMapping args) override;

  // |AndroidEngine|
  void SetSemanticsEnabled(bool enabled) override;

  // |AndroidEngine|
  void SetAccessibilityFeatures(int32_t flags) override;

  // |AndroidEngine|
  void RegisterTexture(std::shared_ptr<flutter::Texture> texture) override;

  // |AndroidEngine|
  void UnregisterTexture(int64_t texture_id) override;

  // |AndroidEngine|
  void MarkTextureFrameAvailable(int64_t texture_id) override;

  // |AndroidEngine|
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) override;

  // |AndroidEngine|
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) override;

  // |AndroidEngine|
  void UpdateAssetResolverByType(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type) override;

 private:
  std::unique_ptr<Shell> shell_;

  PlatformView::Delegate& GetDelegate() const {
    return static_cast<PlatformView::Delegate&>(*shell_);
  }

  FML_DISALLOW_COPY_AND_ASSIGN(ShellAndroidEngine);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_SHELL_ANDROID_ENGINE_H_
