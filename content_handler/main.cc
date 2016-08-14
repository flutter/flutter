// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <mojo/system/main.h>

#include <thread>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/content_handler/content_handler_impl.h"
#include "flutter/runtime/dart_init.h"
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

class App : public mojo::ApplicationImplBase {
 public:
  App() {}

  ~App() override {}

  // Overridden from ApplicationDelegate:
  void OnInitialize() override {
    ftl::RefPtr<ftl::TaskRunner> ui_task_runner(
        mtl::MessageLoop::GetCurrent()->task_runner());

    // TODO(abarth): Currently we're using one thread for everything, but we
    // should use separate threads for GPU, UI, and IO tasks. However, there
    // appears to be some issue with running multiple message loops at the same
    // time, potentially related to TLS.
    blink::Threads::Set(
        blink::Threads(ui_task_runner, ui_task_runner, ui_task_runner));
    blink::Settings::Set(blink::Settings());
    blink::InitDartVM();
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
  FTL_DISALLOW_COPY_AND_ASSIGN(App);
};

}  // namespace
}  // namespace flutter_content_handler

MojoResult MojoMain(MojoHandle request) {
  flutter_content_handler::App app;
  return mojo::RunApplication(request, &app);
}
