// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_APPLICATION_APPLICATION_RUNNER_H_
#define MOJO_PUBLIC_APPLICATION_APPLICATION_RUNNER_H_

#include "mojo/public/cpp/system/core.h"

namespace mojo {

class ApplicationDelegate;

// A utility for running an Application. The typical use case is to use
// when writing your MojoMain:
//
//  MojoResult MojoMain(MojoHandle application_request) {
//    mojo::ApplicationRunner runner(new MyApplicationDelegate());
//    return runner.Run(application_request);
//  }
//
// ApplicationRunner takes care of mojo environment initialization and
// shutdown, and starting a RunLoop from which your application can run and
// ultimately Quit().
class ApplicationRunner {
 public:
  // Takes ownership of |delegate|.
  explicit ApplicationRunner(ApplicationDelegate* delegate);
  ~ApplicationRunner();

  // Once the various parameters have been set above, use Run to initialize an
  // ApplicationImpl wired to the provided delegate, and run a RunLoop until
  // the application exits.
  MojoResult Run(MojoHandle application_request);

 private:
  ApplicationDelegate* delegate_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ApplicationRunner);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_APPLICATION_APPLICATION_RUNNER_H_
