// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_TRACING_CONTROLLER_H_
#define SHELL_COMMON_TRACING_CONTROLLER_H_

#include <string>

#include "lib/fxl/macros.h"

namespace shell {

class TracingController {
 public:
  TracingController();

  ~TracingController();

  void StartTracing();

  void StopTracing();

  bool tracing_active() const { return tracing_active_; }

 private:
  bool tracing_active_;

  FXL_DISALLOW_COPY_AND_ASSIGN(TracingController);
};

}  // namespace shell

#endif  //  SHELL_COMMON_TRACING_CONTROLLER_H_
