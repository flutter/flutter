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

SyncSwitch::SyncSwitch(bool value)
    : mutex_(std::unique_ptr<fml::SharedMutex>(fml::SharedMutex::Create())),
      value_(value) {}

void SyncSwitch::Execute(const SyncSwitch::Handlers& handlers) const {
  fml::SharedLock lock(*mutex_);
  if (value_) {
    handlers.true_handler();
  } else {
    handlers.false_handler();
  }
}

void SyncSwitch::SetSwitch(bool value) {
  fml::UniqueLock lock(*mutex_);
  value_ = value;
}

}  // namespace fml
