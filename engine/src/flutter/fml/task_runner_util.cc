// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/task_runner_util.h"

namespace fml {

WrapperBasicTaskRunner::WrapperBasicTaskRunner(
    fml::RefPtr<fml::TaskRunner> task_runner)
    : task_runner_(std::move(task_runner)) {}

void WrapperBasicTaskRunner::PostTask(const fml::closure& task) {
  task_runner_->PostTask(task);
}

ConditionalBasicTaskRunner::ConditionalBasicTaskRunner(
    fml::RefPtr<fml::TaskRunner> task_runner,
    std::function<bool()> is_usable)
    : task_runner_(std::move(task_runner)),
      is_usable_(
          std::make_shared<std::function<bool()>>(std::move(is_usable))) {}

void ConditionalBasicTaskRunner::PostTask(const fml::closure& task) {
  auto task_wrapper = [task, weak_is_usable = std::weak_ptr(is_usable_)] {
    std::shared_ptr<std::function<bool()>> is_usable = weak_is_usable.lock();
    if (is_usable && (*is_usable)()) {
      task();
    }
  };
  task_runner_->PostTask(task_wrapper);
}

}  // namespace fml
