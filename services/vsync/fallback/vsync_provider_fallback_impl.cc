// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/services/vsync/fallback/vsync_provider_fallback_impl.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/message_loop/message_loop.h"

namespace sky {
namespace services {
namespace vsync {

VsyncProviderFallbackImpl::VsyncProviderFallbackImpl(
    mojo::InterfaceRequest<::vsync::VSyncProvider> request)
    : binding_(this, request.Pass()),
      phase_(base::TimeTicks::Now()),
      armed_(false),
      weak_factory_(this) {}

VsyncProviderFallbackImpl::~VsyncProviderFallbackImpl() = default;

void VsyncProviderFallbackImpl::AwaitVSync(const AwaitVSyncCallback& callback) {
  pending_.emplace_back(std::move(callback));
  ArmIfNecessary();
}

void VsyncProviderFallbackImpl::ArmIfNecessary() {
  if (armed_) {
    return;
  }

  armed_ = true;

  const base::TimeDelta interval = base::TimeDelta::FromSecondsD(1.0 / 60.0);

  const base::TimeTicks now = base::TimeTicks::Now();
  const base::TimeTicks next = now.SnappedToNextTick(phase_, interval);

  auto callback = base::Bind(&VsyncProviderFallbackImpl::OnFakeVSync,
                             weak_factory_.GetWeakPtr());

  base::MessageLoop::current()->PostDelayedTask(FROM_HERE, callback,
                                                next - now);
}

void VsyncProviderFallbackImpl::OnFakeVSync() {
  DCHECK(armed_);

  armed_ = false;

  auto now = base::TimeTicks::Now().ToInternalValue();

  for (const auto& callback : pending_) {
    callback.Run(now);
  }

  pending_.clear();
}

}  // namespace vsync
}  // namespace services
}  // namespace sky
