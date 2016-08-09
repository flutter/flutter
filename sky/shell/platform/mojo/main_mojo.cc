// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread.h"
#include "mojo/common/tracing_impl.h"
#include "mojo/environment/scoped_chromium_init.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_impl_base.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/run_application.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"
#include "flutter/services/icu/icu.h"
#include "flutter/sky/engine/public/platform/sky_settings.h"
#include "flutter/sky/shell/platform/mojo/content_handler_impl.h"
#include "flutter/sky/shell/shell.h"

namespace sky {
namespace shell {
namespace {

const char kEnableCheckedMode[] = "--enable-checked-mode";
const char kPauseIsolatesOnStart[] = "--pause-isolates-on-start";

}  // namespace

class MojoApp : public mojo::ApplicationImplBase {
 public:
  MojoApp() {}
  ~MojoApp() override { }

 private:
  // Overridden from ApplicationDelegate:
  void OnInitialize() override {
    mojo::ApplicationConnectorPtr application_connector =
        mojo::ApplicationConnectorPtr::Create(
            mojo::CreateApplicationConnector(shell()));
    mojo::icu::Initialize(application_connector.get());
    tracing_.Initialize(shell(), &args());

    blink::SkySettings settings;
    settings.enable_observatory = true;
    settings.enable_dart_checked_mode = HasArg(kEnableCheckedMode);
    settings.start_paused = HasArg(kPauseIsolatesOnStart);
    blink::SkySettings::Set(settings);

    Shell::Init();
  }

  bool OnAcceptConnection(
      mojo::ServiceProviderImpl* service_provider_impl) override {
    service_provider_impl->AddService<mojo::ContentHandler>(
      [](const mojo::ConnectionContext& connection_context,
         mojo::InterfaceRequest<mojo::ContentHandler> request) {
        new ContentHandlerImpl(request.Pass());
      });
    return true;
  }

  mojo::TracingImpl tracing_;

  FTL_DISALLOW_COPY_AND_ASSIGN(MojoApp);
};

}  // namespace shell
}  // namespace sky

MojoResult MojoMain(MojoHandle application_request) {
  mojo::ScopedChromiumInit init;
  sky::shell::MojoApp app;
  return mojo::RunApplication(application_request, &app);
}
