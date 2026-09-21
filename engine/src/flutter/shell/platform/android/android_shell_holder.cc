// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <pthread.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <memory>
#include <optional>
#include <string>
#include <utility>

#include "common/settings.h"
#include "flutter/fml/cpu_affinity.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_display.h"
#include "flutter/shell/platform/android/android_image_generator.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/embedder_android_engine.h"
#include "flutter/shell/platform/android/platform_view_android.h"

namespace flutter {

namespace {

class BasicTaskRunnerAdapter final : public fml::BasicTaskRunner {
 public:
  explicit BasicTaskRunnerAdapter(fml::RefPtr<fml::TaskRunner> runner)
      : runner_(std::move(runner)) {}

  void PostTask(const fml::closure& task) override {
    if (runner_) {
      runner_->PostTask(task);
    }
  }

 private:
  fml::RefPtr<fml::TaskRunner> runner_;
};

}  // namespace

AndroidShellHolder::AndroidShellHolder(
    const flutter::Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      android_rendering_api_(android_rendering_api) {
  static size_t thread_host_count = 1;
  auto thread_label = std::to_string(thread_host_count++);

  auto mask = ThreadHost::Type::kRaster | ThreadHost::Type::kIo;
  if (settings.merged_platform_ui_thread !=
      Settings::MergedPlatformUIThread::kEnabled) {
    mask |= ThreadHost::Type::kUi;
  }

  flutter::ThreadHost::ThreadHostConfig host_config(
      thread_label, mask, AndroidPlatformThreadConfigSetter);
  host_config.ui_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kUi, thread_label),
      fml::Thread::ThreadPriority::kDisplay);
  host_config.raster_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kRaster, thread_label),
      fml::Thread::ThreadPriority::kRaster);
  host_config.io_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kIo, thread_label),
      fml::Thread::ThreadPriority::kNormal);

  thread_host_ = std::make_shared<ThreadHost>(host_config);

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> raster_runner;
  fml::RefPtr<fml::TaskRunner> ui_runner;
  fml::RefPtr<fml::TaskRunner> io_runner;
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  raster_runner = thread_host_->raster_thread->GetTaskRunner();
  if (settings.merged_platform_ui_thread ==
      Settings::MergedPlatformUIThread::kEnabled) {
    ui_runner = platform_runner;
  } else {
    ui_runner = thread_host_->ui_thread->GetTaskRunner();
  }
  io_runner = thread_host_->io_thread->GetTaskRunner();

  flutter::TaskRunners task_runners(thread_label,     // label
                                    platform_runner,  // platform
                                    raster_runner,    // raster
                                    ui_runner,        // ui
                                    io_runner         // io
  );

  auto io_task_runner_adapter =
      std::make_shared<BasicTaskRunnerAdapter>(task_runners.GetIOTaskRunner());
  std::shared_ptr<AndroidContext> android_context =
      PlatformViewAndroid::CreateAndroidContext(
          task_runners, android_rendering_api_,
          settings_.enable_opengl_gpu_tracing,
          PlatformViewAndroid::CreateContextSettings(settings_),
          io_task_runner_adapter);

  platform_view_android_ = std::make_unique<PlatformViewAndroid>(
      task_runners, jni_facade_, android_context);
  platform_view_ = platform_view_android_->GetWeakPtr();

  auto embedder_engine = std::make_unique<EmbedderAndroidEngine>(
      task_runners, settings_, jni_facade_, android_rendering_api_);
  embedder_engine->SetPlatformMessageHandler(
      platform_view_android_->GetPlatformMessageHandler());
  engine_ = std::move(embedder_engine);

  platform_view_android_->SetEngine(engine_.get());

  engine_->RegisterImageDecoder(
      [runner = task_runners.GetIOTaskRunner()](sk_sp<SkData> buffer) {
        return AndroidImageGenerator::MakeFromData(std::move(buffer), runner);
      },
      -1);
  FML_DLOG(INFO) << "Registered Android SDK image decoder (API level 28+)";

  is_valid_ = engine_ && engine_->IsValid();
}

AndroidShellHolder::AndroidShellHolder(
    const Settings& settings,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<ThreadHost>& thread_host,
    std::unique_ptr<AndroidEngine> engine,
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const fml::WeakPtr<PlatformViewAndroid>& platform_view,
    std::unique_ptr<PlatformViewAndroid> platform_view_android,
    AndroidRenderingAPI rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      platform_view_(platform_view),
      platform_view_android_(std::move(platform_view_android)),
      thread_host_(thread_host),
      engine_(std::move(engine)),
      apk_asset_provider_(std::move(apk_asset_provider)),
      android_rendering_api_(rendering_api) {
  FML_DCHECK(jni_facade);
  FML_DCHECK(engine_);
  FML_DCHECK(engine_->IsSetup());
  FML_DCHECK(platform_view_);
  FML_DCHECK(platform_view_android_);
  FML_DCHECK(thread_host_);
  is_valid_ = engine_ && engine_->IsValid();
}

AndroidShellHolder::~AndroidShellHolder() {
  if (platform_view_android_) {
    platform_view_android_->SetEngine(nullptr);
  }
  engine_.reset();
  platform_view_android_.reset();
  thread_host_.reset();
}

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

std::unique_ptr<AndroidShellHolder> AndroidShellHolder::Spawn(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  FML_DCHECK(engine_ && engine_->IsSetup())
      << "A new Shell can only be spawned "
         "if the current Shell is properly constructed";

  // Take out the old AndroidContext to reuse inside the PlatformViewAndroid
  // of the new Shell.
  PlatformViewAndroid* android_platform_view = platform_view_.get();
  FML_DCHECK(android_platform_view);
  std::shared_ptr<flutter::AndroidContext> android_context =
      android_platform_view->GetAndroidContext();
  FML_DCHECK(android_context);

  std::unique_ptr<AndroidEngine> spawned_engine =
      engine_->Spawn(jni_facade, entrypoint, libraryUrl, initial_route,
                     entrypoint_args, engine_id);
  if (!spawned_engine) {
    return nullptr;
  }

  auto spawned_platform_view_android = std::make_unique<PlatformViewAndroid>(
      spawned_engine->GetTaskRunners(), jni_facade, android_context);
  fml::WeakPtr<PlatformViewAndroid> weak_platform_view =
      spawned_platform_view_android->GetWeakPtr();

  static_cast<EmbedderAndroidEngine*>(spawned_engine.get())
      ->SetPlatformMessageHandler(
          spawned_platform_view_android->GetPlatformMessageHandler());

  spawned_platform_view_android->SetEngine(spawned_engine.get());

  std::unique_ptr<APKAssetProvider> cloned_asset_provider;
  if (apk_asset_provider_ != nullptr) {
    cloned_asset_provider = apk_asset_provider_->Clone();
  }

  return std::unique_ptr<AndroidShellHolder>(new AndroidShellHolder(
      GetSettings(), jni_facade, thread_host_, std::move(spawned_engine),
      std::move(cloned_asset_provider), weak_platform_view,
      std::move(spawned_platform_view_android),
      android_context->RenderingApi()));
}

void AndroidShellHolder::Launch(
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  if (!IsValid()) {
    return;
  }

  UpdateDisplayMetrics();

  apk_asset_provider_ = std::move(apk_asset_provider);
  engine_->Run(std::move(apk_asset_provider_), entrypoint, libraryUrl,
               entrypoint_args, engine_id);
}

Rasterizer::Screenshot AndroidShellHolder::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!IsValid()) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  return engine_->Screenshot(type, base64_encode);
}

fml::WeakPtr<PlatformViewAndroid> AndroidShellHolder::GetPlatformView() {
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(engine_);
  engine_->NotifyLowMemoryWarning();
}

void AndroidShellHolder::UpdateDisplayMetrics() {
  std::vector<std::unique_ptr<Display>> displays;
  displays.push_back(std::make_unique<AndroidDisplay>(jni_facade_));
  engine_->OnDisplayUpdates(std::move(displays));
}

bool AndroidShellHolder::IsSurfaceControlEnabled() {
  return GetPlatformView()->IsSurfaceControlEnabled();
}

}  // namespace flutter
