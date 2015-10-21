// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See platform_task_runner.h.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_IMPL_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_IMPL_H_

#include "base/callback_forward.h"
#include "base/memory/ref_counted.h"

namespace base {
class TaskRunner;
}

namespace mojo {
namespace embedder {

using PlatformTaskRunner = base::TaskRunner;

// TODO(vtl): base::TaskRunner -> base::SingleThreadTaskRunner?
using PlatformTaskRunnerRefPtr = scoped_refptr<base::TaskRunner>;

void PlatformPostTask(PlatformTaskRunner* task_runner,
                      const base::Closure& closure);

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_IMPL_H_
