// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "glue/task_runner_adaptor.h"

#include <utility>

#include "base/bind.h"
#include "base/location.h"
#include "base/task_runner.h"

namespace glue {
namespace {

void RunClosure(ftl::Closure task) {
  task();
}

}  // namespace

TaskRunnerAdaptor::TaskRunnerAdaptor(scoped_refptr<base::TaskRunner> runner)
    : runner_(std::move(runner)) {}

TaskRunnerAdaptor::~TaskRunnerAdaptor() {}

void TaskRunnerAdaptor::PostTask(ftl::Closure task) {
  runner_->PostTask(FROM_HERE, base::Bind(RunClosure, task));
}

void TaskRunnerAdaptor::PostDelayedTask(ftl::Closure task,
                                        ftl::TimeDelta delay) {
  runner_->PostDelayedTask(
      FROM_HERE, base::Bind(RunClosure, task),
      base::TimeDelta::FromMicroseconds(delay.ToMicroseconds()));
}

}  // namespace glue
