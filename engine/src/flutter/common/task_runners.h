// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_TASK_RUNNERS_H_
#define FLUTTER_COMMON_TASK_RUNNERS_H_

#include <string>

#include "lib/fxl/macros.h"
#include "lib/fxl/tasks/task_runner.h"

namespace blink {

class TaskRunners {
 public:
  TaskRunners(std::string label,
              fxl::RefPtr<fxl::TaskRunner> platform,
              fxl::RefPtr<fxl::TaskRunner> gpu,
              fxl::RefPtr<fxl::TaskRunner> ui,
              fxl::RefPtr<fxl::TaskRunner> io);

  ~TaskRunners();

  const std::string& GetLabel() const;

  fxl::RefPtr<fxl::TaskRunner> GetPlatformTaskRunner() const;

  fxl::RefPtr<fxl::TaskRunner> GetUITaskRunner() const;

  fxl::RefPtr<fxl::TaskRunner> GetIOTaskRunner() const;

  fxl::RefPtr<fxl::TaskRunner> GetGPUTaskRunner() const;

  bool IsValid() const;

 private:
  const std::string label_;
  fxl::RefPtr<fxl::TaskRunner> platform_;
  fxl::RefPtr<fxl::TaskRunner> gpu_;
  fxl::RefPtr<fxl::TaskRunner> ui_;
  fxl::RefPtr<fxl::TaskRunner> io_;
};
}  // namespace blink

#endif  // FLUTTER_COMMON_TASK_RUNNERS_H_
