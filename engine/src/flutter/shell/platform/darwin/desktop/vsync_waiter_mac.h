// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_DESKTOP_VSYNC_WAITER_MAC_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_DESKTOP_VSYNC_WAITER_MAC_H_

#include "flutter/shell/common/vsync_waiter.h"
#include "lib/fxl/macros.h"

namespace shell {

class VsyncWaiterMac final : public VsyncWaiter {
 public:
  VsyncWaiterMac(blink::TaskRunners task_runners);

  ~VsyncWaiterMac() override;

 private:
  void* opaque_;

  void AwaitVSync() override;

  static void OnDisplayLink(void* context);

  void OnDisplayLink();

  FXL_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterMac);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_DESKTOP_VSYNC_WAITER_MAC_H_
