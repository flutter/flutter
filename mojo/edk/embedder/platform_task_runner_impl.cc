// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_task_runner_impl.h"

#include "base/location.h"
#include "base/logging.h"
#include "base/task_runner.h"

namespace mojo {
namespace embedder {

void PlatformPostTask(PlatformTaskRunner* task_runner,
                      const base::Closure& closure) {
  bool result = task_runner->PostTask(tracked_objects::Location(), closure);
  DCHECK(result);
}

}  // namespace embedder
}  // namespace mojo
