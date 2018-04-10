// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/desktop/vsync_waiter_mac.h"

#include <CoreVideo/CoreVideo.h>

#include "lib/fxl/logging.h"

namespace shell {

#define link_ (reinterpret_cast<CVDisplayLinkRef>(opaque_))

VsyncWaiterMac::VsyncWaiterMac(blink::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)), opaque_(nullptr) {
  // Create the link.
  CVDisplayLinkRef link = nullptr;
  CVDisplayLinkCreateWithActiveCGDisplays(&link);
  opaque_ = link;

  // Set the output callback.
  CVDisplayLinkSetOutputCallback(
      link_,
      [](CVDisplayLinkRef link, const CVTimeStamp* now,
         const CVTimeStamp* output, CVOptionFlags flags_in,
         CVOptionFlags* flags_out, void* context) -> CVReturn {
        OnDisplayLink(context);
        return kCVReturnSuccess;
      },
      this);
}

VsyncWaiterMac::~VsyncWaiterMac() {
  CVDisplayLinkRelease(link_);
}

void VsyncWaiterMac::OnDisplayLink(void* context) {
  reinterpret_cast<VsyncWaiterMac*>(context)->OnDisplayLink();
}

void VsyncWaiterMac::OnDisplayLink() {
  fxl::TimePoint frame_start_time = fxl::TimePoint::Now();
  fxl::TimePoint frame_target_time =
      frame_start_time +
      fxl::TimeDelta::FromSecondsF(
          CVDisplayLinkGetActualOutputVideoRefreshPeriod(link_));

  CVDisplayLinkStop(link_);

  FireCallback(frame_start_time, frame_target_time);
}

void VsyncWaiterMac::AwaitVSync() {
  CVDisplayLinkStart(link_);
}

}  // namespace shell
