// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_engine.h"

#include "flutter/fml/make_copyable.h"

#ifdef ERROR
#undef ERROR
#endif

namespace shell {

EmbedderEngine::EmbedderEngine(
    ThreadHost thread_host,
    blink::TaskRunners task_runners,
    blink::Settings settings,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer)
    : thread_host_(std::move(thread_host)),
      shell_(Shell::Create(std::move(task_runners),
                           std::move(settings),
                           on_create_platform_view,
                           on_create_rasterizer)) {
  is_valid_ = shell_ != nullptr;
}

EmbedderEngine::~EmbedderEngine() = default;

bool EmbedderEngine::IsValid() const {
  return is_valid_;
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
  if (!IsValid()) {
    return false;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fml::MakeCopyable([engine = shell_->GetEngine(),          // engine
                         config = std::move(run_configuration)  // config
  ]() mutable {
        if (engine) {
          auto result = engine->Run(std::move(config));
          if (result == shell::Engine::RunStatus::Failure) {
            FML_LOG(ERROR) << "Could not launch the engine with configuration.";
          }
        }
      }));

  return true;
}

bool EmbedderEngine::SetViewportMetrics(blink::ViewportMetrics metrics) {
  if (!IsValid()) {
    return false;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(), metrics = std::move(metrics)]() {
        if (engine) {
          engine->SetViewportMetrics(std::move(metrics));
        }
      });
  return true;
}

bool EmbedderEngine::DispatchPointerDataPacket(
    std::unique_ptr<blink::PointerDataPacket> packet) {
  if (!IsValid() || !packet) {
    return false;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(fml::MakeCopyable(
      [engine = shell_->GetEngine(), packet = std::move(packet)] {
        if (engine) {
          engine->DispatchPointerDataPacket(*packet);
        }
      }));

  return true;
}

bool EmbedderEngine::SendPlatformMessage(
    fml::RefPtr<blink::PlatformMessage> message) {
  if (!IsValid() || !message) {
    return false;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(), message] {
        if (engine) {
          engine->DispatchPlatformMessage(message);
        }
      });

  return true;
}

}  // namespace shell
