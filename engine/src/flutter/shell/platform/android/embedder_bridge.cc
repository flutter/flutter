// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_bridge.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"

namespace flutter {

EmbedderBridge::EmbedderBridge(
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const flutter::Settings& settings,
    AndroidRenderingAPI rendering_api)
    : task_runners_(task_runners),
      jni_facade_(jni_facade),
      settings_(settings),
      rendering_api_(rendering_api) {
  auto on_create_platform_view =
      [this](Shell& shell) -> std::unique_ptr<PlatformView> {
    auto platform_view = std::make_unique<PlatformViewAndroid>(
        shell, task_runners_, jni_facade_, rendering_api_);
    platform_view_ = platform_view->GetWeakPtr();
    return platform_view;
  };

  auto on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  // TODO(justinmc): What should the thread host be?
  embedder_engine_ = std::make_unique<EmbedderEngine>(
      nullptr, task_runners_, settings_, RunConfiguration(),
      on_create_platform_view, on_create_rasterizer, nullptr);
}

EmbedderBridge::~EmbedderBridge() = default;

bool EmbedderBridge::IsValid() const {
  return embedder_engine_ && embedder_engine_->IsValid();
}

void EmbedderBridge::Run(const std::string& entrypoint) {
  FML_LOG(ERROR) << "Running";
  if (!embedder_engine_) {
    return;
  }
  RunConfiguration config;
  config.SetEntrypoint(entrypoint);
  embedder_engine_->RunRootIsolate();
}

shell::Shell& EmbedderBridge::GetShell() {
  return embedder_engine_->GetShell();
}

fml::WeakPtr<PlatformViewAndroid> EmbedderBridge::GetPlatformView() {
  return platform_view_;
}

void EmbedderBridge::OnVsync(int64_t baton,
                             fml::TimePoint frame_start_time,
                             fml::TimePoint frame_target_time) {
  embedder_engine_->OnVsyncEvent(baton, frame_start_time, frame_target_time);
}

}  // namespace flutter
