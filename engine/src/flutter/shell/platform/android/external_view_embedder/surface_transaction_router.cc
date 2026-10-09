// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/surface_transaction_router.h"

namespace flutter {

SurfaceTransactionRouter::SurfaceTransactionRouter() = default;

SurfaceTransactionRouter::~SurfaceTransactionRouter() = default;

void SurfaceTransactionRouter::SetFrameRoute(Route route) {
  frame_route_ = route;
}

SurfaceTransactionRouter::Route SurfaceTransactionRouter::GetFrameRoute()
    const {
  return frame_route_;
}

void SurfaceTransactionRouter::OnPlatformFrameSubmitted() {
  uncommitted_platform_frames_.fetch_add(1, std::memory_order_acq_rel);
}

void SurfaceTransactionRouter::OnPlatformFrameCommitted() {
  // Saturate at zero rather than trusting every caller to be paired: a stray
  // commit must not let the count go negative and mask a later submission.
  int32_t current =
      uncommitted_platform_frames_.load(std::memory_order_acquire);
  while (current > 0 && !uncommitted_platform_frames_.compare_exchange_weak(
                            current, current - 1, std::memory_order_acq_rel,
                            std::memory_order_acquire)) {
  }
}

bool SurfaceTransactionRouter::HasUncommittedPlatformFrames() const {
  return uncommitted_platform_frames_.load(std::memory_order_acquire) > 0;
}

}  // namespace flutter
