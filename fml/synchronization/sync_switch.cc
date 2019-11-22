// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/sync_switch.h"

namespace fml {

SyncSwitch::Handlers& SyncSwitch::Handlers::SetIfTrue(
    const std::function<void()>& handler) {
  true_handler = std::move(handler);
  return *this;
}

SyncSwitch::Handlers& SyncSwitch::Handlers::SetIfFalse(
    const std::function<void()>& handler) {
  false_handler = std::move(handler);
  return *this;
}

SyncSwitch::SyncSwitch() : SyncSwitch(false) {}

SyncSwitch::SyncSwitch(bool value) : value_(value) {}

void SyncSwitch::Execute(const SyncSwitch::Handlers& handlers) {
  std::scoped_lock guard(mutex_);
  if (value_) {
    handlers.true_handler();
  } else {
    handlers.false_handler();
  }
}

void SyncSwitch::SetSwitch(bool value) {
  std::scoped_lock guard(mutex_);
  value_ = value;
}

}  // namespace fml
