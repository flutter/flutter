// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_APPLICATION_RUN_APPLICATION_OPTIONS_CHROMIUM_H_
#define MOJO_APPLICATION_RUN_APPLICATION_OPTIONS_CHROMIUM_H_

#include "base/message_loop/message_loop.h"
#include "mojo/public/cpp/application/run_application.h"

namespace mojo {

// Options for the "chromium" implementation of |RunApplication()|.
class RunApplicationOptionsChromium : public RunApplicationOptions {
 public:
  explicit RunApplicationOptionsChromium(
      base::MessageLoop::Type message_loop_type)
      : message_loop_type(message_loop_type) {}
  ~RunApplicationOptionsChromium() {}

  base::MessageLoop::Type message_loop_type;
};

}  // namespace mojo

#endif  // MOJO_APPLICATION_RUN_APPLICATION_OPTIONS_CHROMIUM_H_
