// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file "provides" abstractions for "task runners" and posting tasks to
// them. The embedder is required to actually declare/define them in
// platform_task_runner_impl.h. See below for details.

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/task_runner.h"
#include "mojo/edk/embedder/platform_task_runner.h"

namespace base_edk {

class PlatformTaskRunnerImpl : public mojo::embedder::PlatformTaskRunner {
 public:
  explicit PlatformTaskRunnerImpl(
      scoped_refptr<base::TaskRunner>&& base_task_runner);
  ~PlatformTaskRunnerImpl() override;

  // |mojo::embedder::PlatformTaskRunner| implementation:
  void PostTask(const base::Closure& task) override;
  bool RunsTasksOnCurrentThread() const override;

 private:
  const scoped_refptr<base::TaskRunner> base_task_runner_;

  DISALLOW_COPY_AND_ASSIGN(PlatformTaskRunnerImpl);
};

}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_TASK_RUNNER_IMPL_H_
