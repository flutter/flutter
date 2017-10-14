// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/app.h"

#include <thread>
#include <utility>

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/sky/engine/platform/fonts/fuchsia/FontCacheFuchsia.h"
#include "lib/fsl/tasks/message_loop.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/tasks/task_runner.h"
#include "lib/icu_data/cpp/icu_data.h"

namespace flutter_runner {
namespace {

static App* g_app = nullptr;

void QuitMessageLoop() {
  fsl::MessageLoop::GetCurrent()->QuitNow();
}

std::string GetLabelFromURL(const std::string& url) {
  size_t last_slash = url.rfind('/');
  if (last_slash == std::string::npos || last_slash + 1 == url.length())
    return url;
  return url.substr(last_slash + 1);
}

}  // namespace

App::App() {
  g_app = this;
  context_ = app::ApplicationContext::CreateFromStartupInfo();

  gpu_thread_ = std::make_unique<fsl::Thread>();
  io_thread_ = std::make_unique<fsl::Thread>();

  auto gpu_thread_success = gpu_thread_->Run();
  auto io_thread_success = io_thread_->Run();

  FXL_CHECK(gpu_thread_success) << "Must be able to create the GPU thread";
  FXL_CHECK(io_thread_success) << "Must be able to create the IO thread";

  auto ui_task_runner = fsl::MessageLoop::GetCurrent()->task_runner();
  auto gpu_task_runner = gpu_thread_->TaskRunner();
  auto io_task_runner = io_thread_->TaskRunner();

  // Notice that the Platform and UI threads are actually the same.
  blink::Threads::Set(blink::Threads(ui_task_runner,   // Platform
                                     gpu_task_runner,  // GPU
                                     ui_task_runner,   // UI
                                     io_task_runner    // IO
                                     ));

  if (!icu_data::Initialize(context_.get())) {
    FXL_LOG(ERROR) << "Could not initialize ICU data.";
  }

  blink::Settings settings;
  settings.enable_observatory = true;
  settings.enable_dart_profiling = true;
  blink::Settings::Set(settings);

  blink::SetFontProvider(
      context_->ConnectToEnvironmentService<fonts::FontProvider>());

  context_->outgoing_services()->AddService<app::ApplicationRunner>(
      [this](fidl::InterfaceRequest<app::ApplicationRunner> request) {
        runner_bindings_.AddBinding(this, std::move(request));
      });
}

App::~App() {
  icu_data::Release();
  blink::Threads::Gpu()->PostTask(QuitMessageLoop);
  blink::Threads::IO()->PostTask(QuitMessageLoop);
  g_app = nullptr;
}

App& App::Shared() {
  FXL_DCHECK(g_app);
  return *g_app;
}

void App::WaitForPlatformViewIds(
    std::vector<PlatformViewInfo>* platform_view_ids) {
  fxl::AutoResetWaitableEvent latch;

  blink::Threads::UI()->PostTask([this, platform_view_ids, &latch]() {
    WaitForPlatformViewsIdsUIThread(platform_view_ids, &latch);
  });

  latch.Wait();
}

void App::WaitForPlatformViewsIdsUIThread(
    std::vector<PlatformViewInfo>* platform_view_ids,
    fxl::AutoResetWaitableEvent* latch) {
  for (auto it = controllers_.begin(); it != controllers_.end(); it++) {
    ApplicationControllerImpl* controller = it->first;

    if (!controller) {
      continue;
    }

    PlatformViewInfo info;
    // TODO(zra): We should create real IDs for these instead of relying on the
    // address of the controller. Maybe just use the UI Isolate main port?
    info.view_id = reinterpret_cast<uintptr_t>(controller);
    info.isolate_id = controller->GetUIIsolateMainPort();
    info.isolate_name = controller->GetUIIsolateName();
    platform_view_ids->push_back(info);
  }
  latch->Signal();
}

void App::StartApplication(
    app::ApplicationPackagePtr application,
    app::ApplicationStartupInfoPtr startup_info,
    fidl::InterfaceRequest<app::ApplicationController> controller) {
  if (controllers_.empty()) {
    // Name this process after the url of the first application being launched.
    base_label_ = "flutter:" + GetLabelFromURL(startup_info->launch_info->url);
  }

  std::unique_ptr<ApplicationControllerImpl> impl =
      std::make_unique<ApplicationControllerImpl>(this, std::move(application),
                                                  std::move(startup_info),
                                                  std::move(controller));
  ApplicationControllerImpl* key = impl.get();
  controllers_.emplace(key, std::move(impl));

  UpdateProcessLabel();
}

void App::Destroy(ApplicationControllerImpl* controller) {
  auto it = controllers_.find(controller);
  if (it == controllers_.end())
    return;
  controllers_.erase(it);
  UpdateProcessLabel();
}

void App::UpdateProcessLabel() {
  std::string label;
  if (controllers_.size() < 2) {
    label = base_label_;
  } else {
    std::string suffix = " (+" + std::to_string(controllers_.size() - 1) + ")";
    if (base_label_.size() + suffix.size() <= ZX_MAX_NAME_LEN - 1) {
      label = base_label_ + suffix;
    } else {
      label = base_label_.substr(0, ZX_MAX_NAME_LEN - 1 - suffix.size() - 3) +
              "..." + suffix;
    }
  }
  zx::process::self().set_property(ZX_PROP_NAME, label.c_str(), label.size());
}

}  // namespace flutter_runner
