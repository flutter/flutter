// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_APPLICATION_APPLICATION_RUNNER_CHROMIUM_H_
#define MOJO_APPLICATION_APPLICATION_RUNNER_CHROMIUM_H_

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {

class ApplicationDelegate;

// A utility for running a chromium based mojo Application. The typical use
// case is to use when writing your MojoMain:
//
//  MojoResult MojoMain(MojoHandle application_request) {
//    mojo::ApplicationRunnerChromium runner(new MyDelegate());
//    return runner.Run(application_request);
//  }
//
// ApplicationRunnerChromium takes care of chromium environment initialization
// and shutdown, and starting a MessageLoop from which your application can run
// and ultimately Quit().
class ApplicationRunnerChromium {
 public:
  // Takes ownership of |delegate|.
  explicit ApplicationRunnerChromium(ApplicationDelegate* delegate);
  ~ApplicationRunnerChromium();

  void set_message_loop_type(base::MessageLoop::Type type);

  // Once the various parameters have been set above, use Run to initialize an
  // ApplicationImpl wired to the provided delegate, and run a MessageLoop until
  // the application exits.
  MojoResult Run(MojoHandle application_request);

 private:
  scoped_ptr<ApplicationDelegate> delegate_;

  // MessageLoop type. TYPE_CUSTOM is default (MessagePumpMojo will be used as
  // the underlying message pump).
  base::MessageLoop::Type message_loop_type_;
  // Whether Run() has been called.
  bool has_run_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ApplicationRunnerChromium);
};

}  // namespace mojo

#endif  // MOJO_APPLICATION_APPLICATION_RUNNER_CHROMIUM_H_
