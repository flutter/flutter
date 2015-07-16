// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/user_metrics.h"

#include <vector>

#include "base/lazy_instance.h"
#include "base/threading/thread_checker.h"

namespace base {
namespace {

// A helper class for tracking callbacks and ensuring thread-safety.
class Callbacks {
 public:
  Callbacks() {}

  // Records the |action|.
  void Record(const std::string& action) {
    DCHECK(thread_checker_.CalledOnValidThread());
    for (size_t i = 0; i < callbacks_.size(); ++i) {
      callbacks_[i].Run(action);
    }
  }

  // Adds |callback| to the list of |callbacks_|.
  void AddCallback(const ActionCallback& callback) {
    DCHECK(thread_checker_.CalledOnValidThread());
    callbacks_.push_back(callback);
  }

  // Removes the first instance of |callback| from the list of |callbacks_|, if
  // there is one.
  void RemoveCallback(const ActionCallback& callback) {
    DCHECK(thread_checker_.CalledOnValidThread());
    for (size_t i = 0; i < callbacks_.size(); ++i) {
      if (callbacks_[i].Equals(callback)) {
        callbacks_.erase(callbacks_.begin() + i);
        return;
      }
    }
  }

 private:
  base::ThreadChecker thread_checker_;
  std::vector<ActionCallback> callbacks_;

  DISALLOW_COPY_AND_ASSIGN(Callbacks);
};

base::LazyInstance<Callbacks> g_callbacks = LAZY_INSTANCE_INITIALIZER;

}  // namespace

void RecordAction(const UserMetricsAction& action) {
  g_callbacks.Get().Record(action.str_);
}

void RecordComputedAction(const std::string& action) {
  g_callbacks.Get().Record(action);
}

void AddActionCallback(const ActionCallback& callback) {
  g_callbacks.Get().AddCallback(callback);
}

void RemoveActionCallback(const ActionCallback& callback) {
  g_callbacks.Get().RemoveCallback(callback);

}

}  // namespace base
