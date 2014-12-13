// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_path.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread.h"
#include "mojo/application/application_runner_chromium.h"
#include "mojo/common/tracing_impl.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_connection.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/services/content_handler/public/interfaces/content_handler.mojom.h"
#include "sky/compositor/display_delegate_bitmap.h"
#include "sky/compositor/display_delegate_ganesh.h"
#include "sky/engine/public/web/Sky.h"
#include "sky/viewer/content_handler_impl.h"
#include "sky/viewer/document_view.h"
#include "sky/viewer/platform/platform_impl.h"

#if !defined(COMPONENT_BUILD)
#include "base/i18n/icu_util.h"
#endif

namespace sky {

// Load the viewer in testing mode so we can dump pixels.
const char kTesting[] = "--testing";

class Viewer : public mojo::ApplicationDelegate,
               public mojo::InterfaceFactory<mojo::ContentHandler> {
 public:
  Viewer() {}

  virtual ~Viewer() { blink::shutdown(); }

 private:
  // Overridden from ApplicationDelegate:
  virtual void Initialize(mojo::ApplicationImpl* app) override {
    if (app->HasArg(kTesting)) {
      DisplayDelegate::setDisplayDelegateCreateFunction(
          DisplayDelegateBitmap::create);
    } else {
      DisplayDelegate::setDisplayDelegateCreateFunction(
          DisplayDelegateGanesh::create);
    }

    platform_impl_.reset(new PlatformImpl(app));
    blink::initialize(platform_impl_.get());
    base::i18n::InitializeICU();

    mojo::TracingImpl::Create(app);
  }

  virtual bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->AddService<mojo::ContentHandler>(this);
    return true;
  }

  // Overridden from InterfaceFactory<ContentHandler>
  virtual void Create(mojo::ApplicationConnection* connection,
                      mojo::InterfaceRequest<mojo::ContentHandler> request) override {
    mojo::BindToRequest(new ContentHandlerImpl(), &request);
  }

  scoped_ptr<PlatformImpl> platform_impl_;

  DISALLOW_COPY_AND_ASSIGN(Viewer);
};

}  // namespace mojo

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::Viewer);
  return runner.Run(shell_handle);
}
