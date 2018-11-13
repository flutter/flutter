// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_TASK_RUNNERS_H_
#define FLUTTER_COMMON_TASK_RUNNERS_H_

#include <string>

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"

namespace blink {

class TaskRunners {
 public:
  TaskRunners(std::string label,
              fml::RefPtr<fml::TaskRunner> platform,
              fml::RefPtr<fml::TaskRunner> gpu,
              fml::RefPtr<fml::TaskRunner> ui,
              fml::RefPtr<fml::TaskRunner> io);

  TaskRunners(const TaskRunners& other);

  ~TaskRunners();

  const std::string& GetLabel() const;

  fml::RefPtr<fml::TaskRunner> GetPlatformTaskRunner() const;

  fml::RefPtr<fml::TaskRunner> GetUITaskRunner() const;

  fml::RefPtr<fml::TaskRunner> GetIOTaskRunner() const;

  fml::RefPtr<fml::TaskRunner> GetGPUTaskRunner() const;

  bool IsValid() const;

 private:
  const std::string label_;
  fml::RefPtr<fml::TaskRunner> platform_;
  fml::RefPtr<fml::TaskRunner> gpu_;
  fml::RefPtr<fml::TaskRunner> ui_;
  fml::RefPtr<fml::TaskRunner> io_;
};

}  // namespace blink

#endif  // FLUTTER_COMMON_TASK_RUNNERS_H_
