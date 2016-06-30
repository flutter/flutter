// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_MONITOR_H_
#define FLUTTER_TONIC_DART_MONITOR_H_

#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"

namespace blink {

class Monitor {
 public:
  Monitor() {
    lock_ = new base::Lock();
    condition_variable_ = new base::ConditionVariable(lock_);
  }

  ~Monitor() {
    delete condition_variable_;
    delete lock_;
  }

  void Enter() {
    lock_->Acquire();
  }

  void Exit() {
    lock_->Release();
  }

  void Notify() {
    condition_variable_->Signal();
  }

  void Wait() {
    condition_variable_->Wait();
  }

 private:
  base::Lock* lock_;
  base::ConditionVariable* condition_variable_;
  DISALLOW_COPY_AND_ASSIGN(Monitor);
};

class MonitorLocker {
 public:
  explicit MonitorLocker(Monitor* monitor) : monitor_(monitor) {
    CHECK(monitor_);
    monitor_->Enter();
  }

  virtual ~MonitorLocker() {
    monitor_->Exit();
  }

  void Wait() {
    return monitor_->Wait();
  }

  void Notify() {
    monitor_->Notify();
  }

 private:
  Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLocker);
};

}  // namespace blink


#endif  // FLUTTER_TONIC_DART_MONITOR_H_
