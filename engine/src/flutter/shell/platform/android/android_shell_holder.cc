// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_shell_holder.h"

#include <pthread.h>
#include <sys/resource.h>
#include <sys/time.h>

#include <sstream>
#include <string>
#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/platform/android/platform_view_android.h"

namespace flutter {

static PlatformData GetDefaultPlatformData() {
  PlatformData platform_data;
  platform_data.lifecycle_state = "AppLifecycleState.detached";
  return platform_data;
}

bool AndroidShellHolder::use_embedded_view;

AndroidShellHolder::AndroidShellHolder(
    flutter::Settings settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    bool is_background_view)
    : settings_(std::move(settings)), jni_facade_(jni_facade) {
  static size_t shell_count = 1;
  auto thread_label = std::to_string(shell_count++);

  FML_CHECK(pthread_key_create(&thread_destruct_key_, ThreadDestructCallback) ==
            0);

  if (is_background_view) {
    thread_host_ = {thread_label, ThreadHost::Type::UI};
  } else {
    thread_host_ = {thread_label, ThreadHost::Type::UI | ThreadHost::Type::GPU |
                                      ThreadHost::Type::IO};
  }

  // Detach from JNI when the UI and raster threads exit.
  auto jni_exit_task([key = thread_destruct_key_]() {
    FML_CHECK(pthread_setspecific(key, reinterpret_cast<void*>(1)) == 0);
  });
  thread_host_.ui_thread->GetTaskRunner()->PostTask(jni_exit_task);
  if (!is_background_view) {
    thread_host_.raster_thread->GetTaskRunner()->PostTask(jni_exit_task);
  }

  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [is_background_view, &jni_facade, &weak_platform_view](Shell& shell) {
        std::unique_ptr<PlatformViewAndroid> platform_view_android;
        if (is_background_view) {
          platform_view_android = std::make_unique<PlatformViewAndroid>(
              shell,                   // delegate
              shell.GetTaskRunners(),  // task runners
              jni_facade               // JNI interop
          );
        } else {
          platform_view_android = std::make_unique<PlatformViewAndroid>(
              shell,                   // delegate
              shell.GetTaskRunners(),  // task runners
              jni_facade,              // JNI interop
              shell.GetSettings()
                  .enable_software_rendering  // use software rendering
          );
        }
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> gpu_runner;
  fml::RefPtr<fml::TaskRunner> ui_runner;
  fml::RefPtr<fml::TaskRunner> io_runner;
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  if (is_background_view) {
    auto single_task_runner = thread_host_.ui_thread->GetTaskRunner();
    gpu_runner = single_task_runner;
    ui_runner = single_task_runner;
    io_runner = single_task_runner;
  } else {
    gpu_runner = thread_host_.raster_thread->GetTaskRunner();
    ui_runner = thread_host_.ui_thread->GetTaskRunner();
    io_runner = thread_host_.io_thread->GetTaskRunner();
  }
  if (settings.use_embedded_view) {
    use_embedded_view = true;
    // Embedded views requires the gpu and the platform views to be the same.
    // The plan is to eventually dynamically merge the threads when there's a
    // platform view in the layer tree.
    // For now we use a fixed thread configuration with the same thread used as
    // the gpu and platform task runner.
    // TODO(amirh/chinmaygarde): remove this, and dynamically change the thread
    // configuration. https://github.com/flutter/flutter/issues/23975
    // https://github.com/flutter/flutter/issues/59930
    flutter::TaskRunners task_runners(thread_label,     // label
                                      platform_runner,  // platform
                                      platform_runner,  // raster
                                      ui_runner,        // ui
                                      io_runner         // io
    );

    shell_ =
        Shell::Create(task_runners,              // task runners
                      GetDefaultPlatformData(),  // window data
                      settings_,                 // settings
                      on_create_platform_view,  // platform view create callback
                      on_create_rasterizer      // rasterizer create callback
        );
  } else {
    use_embedded_view = false;
    flutter::TaskRunners task_runners(thread_label,     // label
                                      platform_runner,  // platform
                                      gpu_runner,       // raster
                                      ui_runner,        // ui
                                      io_runner         // io
    );

    shell_ =
        Shell::Create(task_runners,              // task runners
                      GetDefaultPlatformData(),  // window data
                      settings_,                 // settings
                      on_create_platform_view,  // platform view create callback
                      on_create_rasterizer      // rasterizer create callback
        );
  }

  platform_view_ = weak_platform_view;
  FML_DCHECK(platform_view_);

  is_valid_ = shell_ != nullptr;

  if (is_valid_) {
    shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask([]() {
      // Android describes -8 as "most important display threads, for
      // compositing the screen and retrieving input events". Conservatively
      // set the raster thread to slightly lower priority than it.
      if (::setpriority(PRIO_PROCESS, gettid(), -5) != 0) {
        // Defensive fallback. Depending on the OEM, it may not be possible
        // to set priority to -5.
        if (::setpriority(PRIO_PROCESS, gettid(), -2) != 0) {
          FML_LOG(ERROR) << "Failed to set GPU task runner priority";
        }
      }
    });
    shell_->GetTaskRunners().GetUITaskRunner()->PostTask([]() {
      if (::setpriority(PRIO_PROCESS, gettid(), -1) != 0) {
        FML_LOG(ERROR) << "Failed to set UI task runner priority";
      }
    });
  }
}

AndroidShellHolder::~AndroidShellHolder() {
  shell_.reset();
  thread_host_.Reset();
  FML_CHECK(pthread_key_delete(thread_destruct_key_) == 0);
}

void AndroidShellHolder::ThreadDestructCallback(void* value) {
  fml::jni::DetachFromVM();
}

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

void AndroidShellHolder::Launch(RunConfiguration config) {
  if (!IsValid()) {
    return;
  }

  shell_->RunEngine(std::move(config));
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
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(shell_);
  shell_->NotifyLowMemoryWarning();
}
}  // namespace flutter
