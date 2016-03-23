// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/application/application_runner_chromium.h"

#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/debug/stack_trace.h"
#include "base/message_loop/message_loop.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/cpp/system/message_pipe.h"

namespace mojo {

// static
void ApplicationImpl::Terminate() {
  if (base::MessageLoop::current()->is_running())
    base::MessageLoop::current()->Quit();
}

ApplicationRunnerChromium::ApplicationRunnerChromium(
    ApplicationDelegate* delegate)
    : delegate_(delegate),
      message_loop_type_(base::MessageLoop::TYPE_CUSTOM),
      has_run_(false) {}

ApplicationRunnerChromium::~ApplicationRunnerChromium() {}

void ApplicationRunnerChromium::set_message_loop_type(
    base::MessageLoop::Type type) {
  DCHECK_NE(base::MessageLoop::TYPE_CUSTOM, type);
  DCHECK(!has_run_);

  message_loop_type_ = type;
}

MojoResult ApplicationRunnerChromium::Run(
    MojoHandle application_request_handle) {
  DCHECK(!has_run_);
  has_run_ = true;

  base::CommandLine::Init(0, NULL);
  base::AtExitManager at_exit;

#if !defined(NDEBUG) && !defined(OS_NACL)
  base::debug::EnableInProcessStackDumping();
#endif

  {
    std::unique_ptr<base::MessageLoop> loop;
    if (message_loop_type_ == base::MessageLoop::TYPE_CUSTOM)
      loop.reset(new base::MessageLoop(common::MessagePumpMojo::Create()));
    else
      loop.reset(new base::MessageLoop(message_loop_type_));

    ApplicationImpl impl(delegate_.get(),
                         MakeRequest<Application>(MakeScopedHandle(
                             MessagePipeHandle(application_request_handle))));
    loop->Run();
  }
  delegate_.reset();
  return MOJO_RESULT_OK;
}

}  // namespace mojo
