// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/run_application.h"

#include <memory>

#include "base/at_exit.h"
#include "base/command_line.h"
#include "base/debug/stack_trace.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/threading/thread_local.h"
#include "build/build_config.h"
#include "mojo/application/run_application_options_chromium.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "mojo/public/cpp/application/application_impl_base.h"
#include "mojo/public/cpp/system/message_pipe.h"

namespace mojo {

namespace {

// We store a pointer to a |ResultHolder|, which just stores a |MojoResult|, in
// TLS so that |TerminateApplication()| can provide the result that
// |RunApplication()| will return. (The |ResultHolder| is just on
// |RunApplication()|'s stack.)
struct ResultHolder {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  bool is_set = false;
#endif
  // TODO(vtl): The default result should probably be |MOJO_RESULT_UNKNOWN|, but
  // |ApplicationRunnerChromium| always returned |MOJO_RESULT_OK|.
  MojoResult result = MOJO_RESULT_OK;
};

base::LazyInstance<base::ThreadLocalPointer<ResultHolder>>::Leaky
    g_current_result_holder = LAZY_INSTANCE_INITIALIZER;

}  // namespace

MojoResult RunApplication(MojoHandle application_request_handle,
                          ApplicationImplBase* application_impl,
                          const RunApplicationOptions* options) {
  DCHECK(!g_current_result_holder.Pointer()->Get());

  ResultHolder result_holder;
  g_current_result_holder.Pointer()->Set(&result_holder);

  // Note: If |options| is non-null, it better point to a
  // |RunApplicationOptionsChromium|.
  base::MessageLoop::Type message_loop_type =
      options
          ? static_cast<const RunApplicationOptionsChromium*>(options)
                ->message_loop_type
          : base::MessageLoop::TYPE_CUSTOM;
  std::unique_ptr<base::MessageLoop> loop(
      (message_loop_type == base::MessageLoop::TYPE_CUSTOM)
          ? new base::MessageLoop(common::MessagePumpMojo::Create())
          : new base::MessageLoop(message_loop_type));
  application_impl->Bind(InterfaceRequest<Application>(
      MakeScopedHandle(MessagePipeHandle(application_request_handle))));
  loop->Run();

  g_current_result_holder.Pointer()->Set(nullptr);

  // TODO(vtl): We'd like to enable the following assertion, but we quit the
  // current message loop directly in various places.
  // DCHECK(result_holder.is_set);

  return result_holder.result;
}

void TerminateApplication(MojoResult result) {
  // TODO(vtl): Rather than asserting |...->is_running()|, just assert that we
  // have one, since we may be called during message loop teardown. (The
  // HandleWatcher is notified of the message loop's pending destruction, and
  // triggers connection errors.) I should think about this some more.
  DCHECK(base::MessageLoop::current());
  if (!base::MessageLoop::current()->is_running()) {
    DLOG(WARNING) << "TerminateApplication() with message loop not running";
    return;
  }
  base::MessageLoop::current()->Quit();

  ResultHolder* result_holder = g_current_result_holder.Pointer()->Get();
  DCHECK(result_holder);
  result_holder->result = result;
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(!result_holder->is_set);
  result_holder->is_set = true;
#endif
}

}  // namespace mojo
