// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/assets/asset_resolver.h"
#include "flutter/common/graphics/texture.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/lib/ui/window/viewport_metrics.h"
#include "flutter/shell/common/display.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

/**
 * @brief An interface for the Android embedder (both AndroidShellHolder and
 * PlatformViewAndroid) to interact with the Flutter engine.
 *
 * This abstraction allows the Android embedder to switch in-place between the
 * internal flutter::Shell / flutter::PlatformView implementation and the
 * public embedder.h API.
 */
class AndroidEngine {
 public:
  virtual ~AndroidEngine() = default;

  virtual bool IsValid() const = 0;

  virtual bool IsSetup() const = 0;

  virtual void RunEngine(RunConfiguration run_configuration) = 0;

  virtual std::unique_ptr<AndroidEngine> Spawn(
      RunConfiguration run_configuration,
      const std::string& initial_route,
      Shell::CreateCallback<PlatformView> on_create_platform_view,
      Shell::CreateCallback<Rasterizer> on_create_rasterizer) const = 0;

  virtual Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                            bool base64_encode) = 0;

  virtual void NotifyLowMemoryWarning() = 0;

  virtual void OnDisplayUpdates(
      std::vector<std::unique_ptr<Display>> displays) = 0;

  virtual const std::shared_ptr<PlatformMessageHandler>&
  GetPlatformMessageHandler() const = 0;

  virtual void RegisterImageDecoder(ImageGeneratorFactory factory,
                                    int32_t priority) = 0;

  virtual const TaskRunners& GetTaskRunners() const = 0;

  virtual Shell& GetShell() = 0;

  virtual const std::unique_ptr<Shell>& GetShellForTesting() const = 0;

  // PlatformView / View-facing operations used by PlatformViewAndroid:

  virtual void NotifyCreated() = 0;

  virtual void NotifyDestroyed() = 0;

  virtual void ScheduleFrame() = 0;

  virtual void SetNextFrameCallback(const fml::closure& closure) = 0;

  virtual void SetViewportMetrics(int64_t view_id,
                                  const ViewportMetrics& metrics) = 0;

  virtual void DispatchPlatformMessage(
      std::unique_ptr<PlatformMessage> message) = 0;

  virtual void DispatchPointerDataPacket(
      std::unique_ptr<PointerDataPacket> packet) = 0;

  virtual void DispatchSemanticsAction(int64_t view_id,
                                       int32_t node_id,
                                       SemanticsAction action,
                                       fml::MallocMapping args) = 0;

  virtual void SetSemanticsEnabled(bool enabled) = 0;

  virtual void SetAccessibilityFeatures(int32_t flags) = 0;

  virtual bool UpdateSemantics(
      int64_t view_id,
      const flutter::SemanticsNodeUpdates& update,
      const flutter::CustomAccessibilityActionUpdates& actions) {
    return false;
  }

  virtual void RegisterTexture(std::shared_ptr<flutter::Texture> texture) = 0;

  virtual void UnregisterTexture(int64_t texture_id) = 0;

  virtual void MarkTextureFrameAvailable(int64_t texture_id) = 0;

  virtual void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) = 0;

  virtual void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                            const std::string error_message,
                                            bool transient) = 0;

  virtual void UpdateAssetResolverByType(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_ENGINE_H_
