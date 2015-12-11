// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an implementation of |mojo::platform::TaskRunner| that
// wraps a |base::TaskRunner|.

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/task_runner.h"
#include "mojo/edk/platform/task_runner.h"

namespace base_edk {

class PlatformTaskRunnerImpl : public mojo::platform::TaskRunner {
 public:
  explicit PlatformTaskRunnerImpl(
      scoped_refptr<base::TaskRunner>&& base_task_runner);
  ~PlatformTaskRunnerImpl() override;

  // |mojo::platform::TaskRunner| implementation:
  void PostTask(std::function<void()>&& task) override;
  bool RunsTasksOnCurrentThread() const override;

 private:
  const scoped_refptr<base::TaskRunner> base_task_runner_;

  DISALLOW_COPY_AND_ASSIGN(PlatformTaskRunnerImpl);
};

}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_
