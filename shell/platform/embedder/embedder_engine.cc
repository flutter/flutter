// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_engine.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

namespace shell {

EmbedderEngine::EmbedderEngine(
    ThreadHost thread_host,
    blink::TaskRunners task_runners,
    blink::Settings settings,
    Shell::CreateCallback<PlatformView> on_create_platform_view,
    Shell::CreateCallback<Rasterizer> on_create_rasterizer,
    EmbedderExternalTextureGL::ExternalTextureCallback
        external_texture_callback)
    : thread_host_(std::move(thread_host)),
      shell_(Shell::Create(std::move(task_runners),
                           std::move(settings),
                           on_create_platform_view,
                           on_create_rasterizer)),
      external_texture_callback_(external_texture_callback) {
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
  if (!IsValid() || !run_configuration.IsValid()) {
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

  TRACE_EVENT0("flutter", "EmbedderEngine::DispatchPointerDataPacket");
  TRACE_FLOW_BEGIN("flutter", "PointerEvent", next_pointer_flow_id_);

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(fml::MakeCopyable(
      [engine = shell_->GetEngine(), packet = std::move(packet),
       flow_id = next_pointer_flow_id_] {
        if (engine) {
          engine->DispatchPointerDataPacket(*packet, flow_id);
        }
      }));
  next_pointer_flow_id_++;

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
  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(), enabled] {
        if (engine) {
          engine->SetSemanticsEnabled(enabled);
        }
      });
  return true;
}

bool EmbedderEngine::SetAccessibilityFeatures(int32_t flags) {
  if (!IsValid()) {
    return false;
  }
  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(), flags] {
        if (engine) {
          engine->SetAccessibilityFeatures(flags);
        }
      });
  return true;
}

bool EmbedderEngine::DispatchSemanticsAction(int id,
                                             blink::SemanticsAction action,
                                             std::vector<uint8_t> args) {
  if (!IsValid()) {
    return false;
  }
  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fml::MakeCopyable([engine = shell_->GetEngine(),  // engine
                         id,                            // id
                         action,                        // action
                         args = std::move(args)         // args
  ]() mutable {
        if (engine) {
          engine->DispatchSemanticsAction(id, action, std::move(args));
        }
      }));
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

}  // namespace shell
