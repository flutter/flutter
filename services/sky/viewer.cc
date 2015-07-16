// Copyright 2014 The Chromium Authors. All rights reserved.
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
#include "mojo/services/content_handler/public/interfaces/content_handler.mojom.h"
#include "services/sky/content_handler_impl.h"
#include "services/sky/document_view.h"
#include "services/sky/platform_impl.h"
#include "services/sky/runtime_flags.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/engine/public/web/WebRuntimeFeatures.h"

namespace sky {

class Viewer : public mojo::ApplicationDelegate,
               public mojo::InterfaceFactory<mojo::ContentHandler> {
 public:
  Viewer() {}

  ~Viewer() override { blink::shutdown(); }

 private:
  // Overridden from ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override {
    RuntimeFlags::Initialize(app);

    blink::WebRuntimeFeatures::enableObservatory(
        !RuntimeFlags::Get().testing());

    platform_impl_.reset(new PlatformImpl());
    blink::initialize(platform_impl_.get());

    mojo::icu::Initialize(app);
    tracing_.Initialize(app);
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

  scoped_ptr<PlatformImpl> platform_impl_;
  mojo::TracingImpl tracing_;

  DISALLOW_COPY_AND_ASSIGN(Viewer);
};

}  // namespace sky

MojoResult MojoMain(MojoHandle application_request) {
  mojo::ApplicationRunnerChromium runner(new sky::Viewer);
  return runner.Run(application_request);
}
