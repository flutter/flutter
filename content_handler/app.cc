// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/app.h"

#include <thread>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/sky/engine/platform/fonts/fuchsia/FontCacheFuchsia.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/tasks/task_runner.h"
#include "lib/icu_data/cpp/icu_data.h"
#include "lib/mtl/tasks/message_loop.h"

namespace flutter_runner {
namespace {

static App* g_app = nullptr;

void QuitMessageLoop() {
  mtl::MessageLoop::GetCurrent()->QuitNow();
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

  gpu_thread_ = std::make_unique<mtl::Thread>();
  io_thread_ = std::make_unique<mtl::Thread>();

  auto gpu_thread_success = gpu_thread_->Run();
  auto io_thread_success = io_thread_->Run();

  FTL_CHECK(gpu_thread_success) << "Must be able to create the GPU thread";
  FTL_CHECK(io_thread_success) << "Must be able to create the IO thread";

  auto ui_task_runner = mtl::MessageLoop::GetCurrent()->task_runner();
  auto gpu_task_runner = gpu_thread_->TaskRunner();
  auto io_task_runner = io_thread_->TaskRunner();

  // Notice that the Platform and UI threads are actually the same.
  blink::Threads::Set(blink::Threads(ui_task_runner,   // Platform
                                     gpu_task_runner,  // GPU
                                     ui_task_runner,   // UI
                                     io_task_runner    // IO
                                     ));

  if (!icu_data::Initialize(context_.get())) {
    FTL_LOG(ERROR) << "Could not initialize ICU data.";
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
  FTL_DCHECK(g_app);
  return *g_app;
}

void App::WaitForPlatformViewIds(
    std::vector<PlatformViewInfo>* platform_view_ids) {
  ftl::AutoResetWaitableEvent latch;

  blink::Threads::UI()->PostTask([this, platform_view_ids, &latch]() {
    WaitForPlatformViewsIdsUIThread(platform_view_ids, &latch);
  });

  latch.Wait();
}

void App::WaitForPlatformViewsIdsUIThread(
    std::vector<PlatformViewInfo>* platform_view_ids,
    ftl::AutoResetWaitableEvent* latch) {
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
    if (base_label_.size() + suffix.size() <= MX_MAX_NAME_LEN - 1) {
      label = base_label_ + suffix;
    } else {
      label = base_label_.substr(0, MX_MAX_NAME_LEN - 1 - suffix.size() - 3) +
              "..." + suffix;
    }
  }
  mx::process::self().set_property(MX_PROP_NAME, label.c_str(), label.size());
}

}  // namespace flutter_runner
