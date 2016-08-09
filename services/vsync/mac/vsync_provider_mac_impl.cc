// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/services/vsync/mac/vsync_provider_mac_impl.h"
#include "base/trace_event/trace_event.h"

#include <mach/mach_time.h>
#include <CoreVideo/CoreVideo.h>

namespace sky {
namespace services {
namespace vsync {

#define link_ (reinterpret_cast<CVDisplayLinkRef>(opaque_))

VsyncProviderMacImpl::VsyncProviderMacImpl(
    mojo::InterfaceRequest<::vsync::VSyncProvider> request)
    : binding_(this, request.Pass()), opaque_(nullptr), trace_level_(false) {
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

VsyncProviderMacImpl::~VsyncProviderMacImpl() {
  CVDisplayLinkRelease(link_);
}

static inline uint64_t CurrentTimeMicroseconds() {
  static mach_timebase_info_data_t timebase = {0};

  if (timebase.denom == 0) {
    (void)mach_timebase_info(&timebase);
  }

  return (mach_absolute_time() * 1e-3 * timebase.numer) / timebase.denom;
}

void VsyncProviderMacImpl::OnDisplayLink(void* thiz) {
  reinterpret_cast<VsyncProviderMacImpl*>(thiz)->OnDisplayLink();
}

void VsyncProviderMacImpl::OnDisplayLink() {
  TRACE_COUNTER1("vsync", "PlatformVSync", trace_level_ = !trace_level_);

  // Stop the link.
  CVDisplayLinkStop(link_);

  // Fire all callbacks and clear.
  uint64_t micros = CurrentTimeMicroseconds();
  for (const auto& callback : pending_callbacks_) {
    callback.Run(micros);
  }

  pending_callbacks_.clear();
}

void VsyncProviderMacImpl::AwaitVSync(const AwaitVSyncCallback& callback) {
  pending_callbacks_.push_back(callback);
  CVDisplayLinkStart(link_);
}

}  // namespace vsync
}  // namespace services
}  // namespace sky
