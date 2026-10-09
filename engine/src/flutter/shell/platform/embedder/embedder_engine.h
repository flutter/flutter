// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_resolver.h"
#include "flutter/shell/platform/embedder/embedder_thread_host.h"
namespace flutter {

struct ShellArgs;

// The object that is returned to the embedder as an opaque pointer to the
// instance of the Flutter engine.
class EmbedderEngine {
 public:
  //----------------------------------------------------------------------------
  /// @param[in]  thread_host  The threads and custom task runners of the
  ///             engine. May be null when the embedder owns the threads behind
  ///             |task_runners|; RunTask() then fails.
  /// @param[in]  run_configuration  What RunRootIsolate() runs. May be
  ///             std::nullopt when the embedder starts the root isolate some
  ///             other way; RunRootIsolate() then fails.
  /// @param[in]  external_texture_resolver  May be null; RegisterTexture()
  ///             then fails.
  ///
  EmbedderEngine(
      std::unique_ptr<EmbedderThreadHost> thread_host,
      const TaskRunners& task_runners,
      const Settings& settings,
      std::optional<RunConfiguration> run_configuration,
      const Shell::CreateCallback<PlatformView>& on_create_platform_view,
      const Shell::CreateCallback<Rasterizer>& on_create_rasterizer,
      std::unique_ptr<EmbedderExternalTextureResolver>
          external_texture_resolver);

  ~EmbedderEngine();

  bool LaunchShell();

  //----------------------------------------------------------------------------
  /// @brief      Same as LaunchShell(), with |platform_data| as the initial
  ///             state of ui.PlatformDispatcher instead of the defaults.
  ///
  bool LaunchShell(const PlatformData& platform_data);

  //----------------------------------------------------------------------------
  /// @brief      Creates an engine from this one with Shell::Spawn. Must be
  ///             called on the platform thread.
  ///
  ///             The new engine shares this engine's task runners, and its
  ///             root isolate is already running |run_configuration| when this
  ///             returns. It owns no threads, run configuration or texture
  ///             resolver, so RunTask(), RunRootIsolate() and
  ///             RegisterTexture() fail on it. It does not keep this engine
  ///             alive, and it must be destroyed before the threads behind the
  ///             shared task runners are.
  ///
  /// @return     The new engine, or nullptr if this engine has no shell or the
  ///             spawn failed.
  ///
  std::unique_ptr<EmbedderEngine> Spawn(
      RunConfiguration run_configuration,
      const std::string& initial_route,
      const Shell::CreateCallback<PlatformView>& on_create_platform_view,
      const Shell::CreateCallback<Rasterizer>& on_create_rasterizer) const;

  bool CollectShell();

  void CollectThreadHost();

  const TaskRunners& GetTaskRunners() const;

  bool NotifyCreated();

  bool NotifyDestroyed();

  bool RunRootIsolate();

  bool IsValid() const;

  bool SetViewportMetrics(int64_t view_id,
                          const flutter::ViewportMetrics& metrics);

  bool DispatchPointerDataPacket(
      std::unique_ptr<flutter::PointerDataPacket> packet);

  bool SendPlatformMessage(std::unique_ptr<PlatformMessage> message);

  bool RegisterTexture(int64_t texture);

  bool UnregisterTexture(int64_t texture);

  bool MarkTextureFrameAvailable(int64_t texture);

  bool SetSemanticsEnabled(bool enabled);

  bool SetAccessibilityFeatures(int32_t flags);

  bool DispatchSemanticsAction(int64_t view_id,
                               int node_id,
                               flutter::SemanticsAction action,
                               fml::MallocMapping args);

  bool OnVsyncEvent(intptr_t baton,
                    fml::TimePoint frame_start_time,
                    fml::TimePoint frame_target_time);

  bool ReloadSystemFonts();

  bool PostRenderThreadTask(const fml::closure& task);

  bool RunTask(const FlutterTask* task);

  bool PostTaskOnEngineManagedNativeThreads(
      const std::function<void(FlutterNativeThreadType)>& closure) const;

  bool ScheduleFrame();

  bool UpdateAssetResolver(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type);

  bool LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions);

  bool LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string& error_message,
                                    bool transient);

  Shell& GetShell();

 private:
  // Adopts |spawned_shell|, a running shell returned by Shell::Spawn.
  EmbedderEngine(const TaskRunners& task_runners,
                 std::unique_ptr<Shell> spawned_shell);

  std::unique_ptr<EmbedderThreadHost> thread_host_;
  TaskRunners task_runners_;
  std::optional<RunConfiguration> run_configuration_;
  std::unique_ptr<ShellArgs> shell_args_;
  std::unique_ptr<Shell> shell_;
  std::unique_ptr<EmbedderExternalTextureResolver> external_texture_resolver_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderEngine);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_
