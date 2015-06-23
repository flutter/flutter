// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "sky/shell/platform_view.h"
#include "sky/shell/service_provider.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"

namespace sky {
namespace shell {

void Init() {
  Shell::Init(make_scoped_ptr(new ServiceProviderContext(
      base::MessageLoop::current()->task_runner())));

  // TODO(abarth): Currently we leak the ShellView.
  ShellView* shell_view = new ShellView(Shell::Shared());

  ViewportObserverPtr viewport_observer;
  shell_view->view()->ConnectToViewportObserver(GetProxy(&viewport_observer));

  // TODO(abarth): At this point we should load some content into the view.
  // viewport_observer->LoadURL("https://domokit.github.io/home.dart");
}

} // namespace shell
} // namespace sky

int main(int argc, const char* argv[]) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);

  base::MessageLoop message_loop;

  base::i18n::InitializeICU();

  message_loop.PostTask(FROM_HERE, base::Bind(&sky::shell::Init));
  message_loop.Run();

  return 0;
}
