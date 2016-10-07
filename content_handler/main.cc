// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <mojo/system/main.h>

#include <thread>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/content_handler/content_handler_impl.h"
#include "flutter/runtime/runtime_init.h"
#include "flutter/sky/engine/platform/fonts/fuchsia/FontCacheFuchsia.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/tasks/task_runner.h"
#include "lib/mtl/tasks/message_loop.h"
#include "lib/mtl/threading/create_thread.h"
#include "mojo/public/cpp/application/application_impl_base.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/run_application.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"

namespace flutter_content_handler {
namespace {

void QuitMessageLoop() {
  mtl::MessageLoop::GetCurrent()->QuitNow();
}

class App : public mojo::ApplicationImplBase {
 public:
  App() {}
  ~App() override {
    if (initialized_)
      StopThreads();
  }

  // Overridden from ApplicationDelegate:
  void OnInitialize() override {
    FTL_DCHECK(!initialized_);
    initialized_ = true;

    ftl::RefPtr<ftl::TaskRunner> gpu_task_runner;
    gpu_thread_ = mtl::CreateThread(&gpu_task_runner);

    ftl::RefPtr<ftl::TaskRunner> ui_task_runner(
        mtl::MessageLoop::GetCurrent()->task_runner());

    ftl::RefPtr<ftl::TaskRunner> io_task_runner;
    io_thread_ = mtl::CreateThread(&io_task_runner);

    // Notice that the Platform and UI threads are actually the same.
    blink::Threads::Set(blink::Threads(ui_task_runner, gpu_task_runner,
                                       ui_task_runner, io_task_runner));
    blink::Settings::Set(blink::Settings());
    blink::InitRuntime();

    mojo::FontProviderPtr font_provider;
    mojo::ConnectToService(shell(), "mojo:fonts",
                           mojo::GetProxy(&font_provider));
    blink::SetFontProvider(std::move(font_provider));
  }

  bool OnAcceptConnection(
      mojo::ServiceProviderImpl* service_provider_impl) override {
    service_provider_impl->AddService<mojo::ContentHandler>(
        [](const mojo::ConnectionContext& connection_context,
           mojo::InterfaceRequest<mojo::ContentHandler> request) {
          new ContentHandlerImpl(std::move(request));
        });
    return true;
  }

 private:
  void StopThreads() {
    FTL_DCHECK(initialized_);
    blink::Threads::Gpu()->PostTask(QuitMessageLoop);
    blink::Threads::IO()->PostTask(QuitMessageLoop);
    gpu_thread_.join();
    io_thread_.join();
  }

  bool initialized_ = false;
  std::thread gpu_thread_;
  std::thread io_thread_;

  FTL_DISALLOW_COPY_AND_ASSIGN(App);
};

}  // namespace
}  // namespace flutter_content_handler

MojoResult MojoMain(MojoHandle request) {
  flutter_content_handler::App app;
  return mojo::RunApplication(request, &app);
}
