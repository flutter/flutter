// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/common/tracing_impl.h"
#include "mojo/icu/icu.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_connection.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/shell/shell.h"
#include "sky/shell/platform/mojo/content_handler_impl.h"

namespace sky {
namespace shell {
namespace {

// Instruct the DartVM to report type errors.
const char kEnableCheckedMode[] = "--enable-checked-mode";

}  // namespace

class MojoApp : public mojo::ApplicationDelegate,
                public mojo::InterfaceFactory<mojo::ContentHandler> {
 public:
  MojoApp() {}
  ~MojoApp() override { }

 private:
  // Overridden from ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override {
    mojo::icu::Initialize(app);
    tracing_.Initialize(app);

    blink::SkySettings settings;
    settings.enable_observatory = true;
    settings.enable_dart_checked_mode = app->HasArg(kEnableCheckedMode);
    blink::SkySettings::Set(settings);

    Shell::Init();
  }

  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->AddService<mojo::ContentHandler>(this);
    return true;
  }

  // Overridden from InterfaceFactory<ContentHandler>
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<mojo::ContentHandler> request) override {
    new ContentHandlerImpl(request.Pass());
  }

  mojo::TracingImpl tracing_;

  DISALLOW_COPY_AND_ASSIGN(MojoApp);
};

}  // namespace shell
}  // namespace sky

MojoResult MojoMain(MojoHandle application_request) {
  mojo::ApplicationRunnerChromium runner(new sky::shell::MojoApp);
  return runner.Run(application_request);
}
