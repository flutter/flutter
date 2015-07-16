// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/application_runner.h"

#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/utility/run_loop.h"

namespace mojo {

// static
void ApplicationImpl::Terminate() {
  RunLoop::current()->Quit();
}

ApplicationRunner::ApplicationRunner(ApplicationDelegate* delegate)
    : delegate_(delegate) {
}
ApplicationRunner::~ApplicationRunner() {
  assert(!delegate_);
}

MojoResult ApplicationRunner::Run(MojoHandle app_request_handle) {
  Environment env;
  {
    RunLoop loop;
    ApplicationImpl app(delegate_, MakeRequest<Application>(MakeScopedHandle(
                                       MessagePipeHandle(app_request_handle))));
    loop.Run();
  }

  delete delegate_;
  delegate_ = nullptr;
  return MOJO_RESULT_OK;
}

}  // namespace mojo
