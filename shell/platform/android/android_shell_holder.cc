// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_shell_holder.h"

#include <sys/resource.h>
#include <sys/time.h>

#include <sstream>
#include <string>
#include <utility>

#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "lib/fxl/functional/make_copyable.h"

namespace shell {

AndroidShellHolder::AndroidShellHolder(
    blink::Settings settings,
    fml::jni::JavaObjectWeakGlobalRef java_object)
    : settings_(std::move(settings)), java_object_(java_object) {
  static size_t shell_count = 1;
  auto thread_label = std::to_string(shell_count++);

  thread_host_ = {thread_label, ThreadHost::Type::UI | ThreadHost::Type::GPU |
                                    ThreadHost::Type::IO};

  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [java_object, &weak_platform_view](Shell& shell) {
        auto platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            java_object,             // java object handle for JNI interop
            shell.GetSettings()
                .enable_software_rendering  // use software rendering
        );
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell.GetTaskRunners());
  };

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();

  blink::TaskRunners task_runners(
      thread_label,                                    // label
      fml::MessageLoop::GetCurrent().GetTaskRunner(),  // platform
      thread_host_.gpu_thread->GetTaskRunner(),        // gpu
      thread_host_.ui_thread->GetTaskRunner(),         // ui
      thread_host_.io_thread->GetTaskRunner()          // io
  );

  shell_ =
      Shell::Create(task_runners,             // task runners
                    settings_,                // settings
                    on_create_platform_view,  // platform view create callback
                    on_create_rasterizer      // rasterizer create callback
      );

  platform_view_ = weak_platform_view;
  FXL_DCHECK(platform_view_);

  is_valid_ = shell_ != nullptr;

  if (is_valid_) {
    task_runners.GetGPUTaskRunner()->PostTask(
        []() { ::setpriority(PRIO_PROCESS, gettid(), -2); });
    task_runners.GetUITaskRunner()->PostTask(
        []() { ::setpriority(PRIO_PROCESS, gettid(), -1); });
  }
}

AndroidShellHolder::~AndroidShellHolder() = default;

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const blink::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

void AndroidShellHolder::Launch(RunConfiguration config) {
  if (!IsValid()) {
    return;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fxl::MakeCopyable([engine = shell_->GetEngine(),  //
                         config = std::move(config)     //
  ]() mutable {
        if (engine) {
          if (!engine->Run(std::move(config))) {
            FXL_LOG(ERROR) << "Could not launch engine in configuration.";
          }
        }
      }));
}

void AndroidShellHolder::SetViewportMetrics(
    const blink::ViewportMetrics& metrics) {
  if (!IsValid()) {
    return;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(), metrics]() {
        if (engine) {
          engine->SetViewportMetrics(metrics);
        }
      });
}

void AndroidShellHolder::DispatchPointerDataPacket(
    std::unique_ptr<blink::PointerDataPacket> packet) {
  if (!IsValid()) {
    return;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(fxl::MakeCopyable(
      [engine = shell_->GetEngine(), packet = std::move(packet)] {
        if (engine) {
          engine->DispatchPointerDataPacket(*packet);
        }
      }));
}

Rasterizer::Screenshot AndroidShellHolder::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!IsValid()) {
    return {nullptr, SkISize::MakeEmpty()};
  }
  return shell_->Screenshot(type, base64_encode);
}

fml::WeakPtr<PlatformViewAndroid> AndroidShellHolder::GetPlatformView() {
  FXL_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::UpdateAssetManager(
    fxl::RefPtr<blink::AssetManager> asset_manager) {
  if (!IsValid() || !asset_manager) {
    return;
  }

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = shell_->GetEngine(),
       asset_manager = std::move(asset_manager)]() {
        if (engine) {
          if (!engine->UpdateAssetManager(std::move(asset_manager))) {
            FXL_DLOG(ERROR) << "Could not update asset asset manager.";
          }
        }
      });
}

}  // namespace shell
