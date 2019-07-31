// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_engine.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

namespace flutter {

EmbedderEngine::EmbedderEngine(
    std::unique_ptr<EmbedderThreadHost> thread_host,
    flutter::TaskRunners task_runners,
    flutter::Settings settings,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer,
    EmbedderExternalTextureGL::ExternalTextureCallback
        external_texture_callback)
    : thread_host_(std::move(thread_host)),
      task_runners_(task_runners),
      shell_(Shell::Create(task_runners_,
                           std::move(settings),
                           on_create_platform_view,
                           on_create_rasterizer)),
      external_texture_callback_(external_texture_callback) {
  if (!shell_) {
    return;
  }

  is_valid_ = true;
}

EmbedderEngine::~EmbedderEngine() = default;

bool EmbedderEngine::IsValid() const {
  return is_valid_;
}

const TaskRunners& EmbedderEngine::GetTaskRunners() const {
  return task_runners_;
}

bool EmbedderEngine::NotifyCreated() {
  if (!IsValid()) {
    return false;
  }

  shell_->GetPlatformView()->NotifyCreated();
  return true;
}

bool EmbedderEngine::NotifyDestroyed() {
  if (!IsValid()) {
    return false;
  }

  shell_->GetPlatformView()->NotifyDestroyed();
  return true;
}

bool EmbedderEngine::Run(RunConfiguration run_configuration) {
  if (!IsValid() || !run_configuration.IsValid()) {
    return false;
  }
  shell_->RunEngine(std::move(run_configuration));
  return true;
}

bool EmbedderEngine::SetViewportMetrics(flutter::ViewportMetrics metrics) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetViewportMetrics(std::move(metrics));
  return true;
}

bool EmbedderEngine::DispatchPointerDataPacket(
    std::unique_ptr<flutter::PointerDataPacket> packet) {
  if (!IsValid() || !packet) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->DispatchPointerDataPacket(std::move(packet));
  return true;
}

bool EmbedderEngine::SendPlatformMessage(
    fml::RefPtr<flutter::PlatformMessage> message) {
  if (!IsValid() || !message) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }

  platform_view->DispatchPlatformMessage(message);
  return true;
}

bool EmbedderEngine::RegisterTexture(int64_t texture) {
  if (!IsValid() || !external_texture_callback_) {
    return false;
  }
  shell_->GetPlatformView()->RegisterTexture(
      std::make_unique<EmbedderExternalTextureGL>(texture,
                                                  external_texture_callback_));
  return true;
}

bool EmbedderEngine::UnregisterTexture(int64_t texture) {
  if (!IsValid() || !external_texture_callback_) {
    return false;
  }
  shell_->GetPlatformView()->UnregisterTexture(texture);
  return true;
}

bool EmbedderEngine::MarkTextureFrameAvailable(int64_t texture) {
  if (!IsValid() || !external_texture_callback_) {
    return false;
  }
  shell_->GetPlatformView()->MarkTextureFrameAvailable(texture);
  return true;
}

bool EmbedderEngine::SetSemanticsEnabled(bool enabled) {
  if (!IsValid()) {
    return false;
  }

  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetSemanticsEnabled(enabled);
  return true;
}

bool EmbedderEngine::SetAccessibilityFeatures(int32_t flags) {
  if (!IsValid()) {
    return false;
  }
  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->SetAccessibilityFeatures(flags);
  return true;
}

bool EmbedderEngine::DispatchSemanticsAction(int id,
                                             flutter::SemanticsAction action,
                                             std::vector<uint8_t> args) {
  if (!IsValid()) {
    return false;
  }
  auto platform_view = shell_->GetPlatformView();
  if (!platform_view) {
    return false;
  }
  platform_view->DispatchSemanticsAction(id, action, std::move(args));
  return true;
}

bool EmbedderEngine::OnVsyncEvent(intptr_t baton,
                                  fml::TimePoint frame_start_time,
                                  fml::TimePoint frame_target_time) {
  if (!IsValid()) {
    return false;
  }

  return VsyncWaiterEmbedder::OnEmbedderVsync(baton, frame_start_time,
                                              frame_target_time);
}

bool EmbedderEngine::PostRenderThreadTask(fml::closure task) {
  if (!IsValid()) {
    return false;
  }

  shell_->GetTaskRunners().GetGPUTaskRunner()->PostTask(task);
  return true;
}

bool EmbedderEngine::RunTask(const FlutterTask* task) {
  if (!IsValid() || task == nullptr) {
    return false;
  }
  return thread_host_->PostTask(reinterpret_cast<int64_t>(task->runner),
                                task->task);
}

}  // namespace flutter
