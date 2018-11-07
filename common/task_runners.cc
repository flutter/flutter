// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"

#include <utility>

namespace blink {

TaskRunners::TaskRunners(std::string label,
                         fml::RefPtr<fml::TaskRunner> platform,
                         fml::RefPtr<fml::TaskRunner> gpu,
                         fml::RefPtr<fml::TaskRunner> ui,
                         fml::RefPtr<fml::TaskRunner> io)
    : label_(std::move(label)),
      platform_(std::move(platform)),
      gpu_(std::move(gpu)),
      ui_(std::move(ui)),
      io_(std::move(io)) {}

TaskRunners::~TaskRunners() = default;

const std::string& TaskRunners::GetLabel() const {
  return label_;
}

fml::RefPtr<fml::TaskRunner> TaskRunners::GetPlatformTaskRunner() const {
  return platform_;
}

fml::RefPtr<fml::TaskRunner> TaskRunners::GetUITaskRunner() const {
  return ui_;
}

fml::RefPtr<fml::TaskRunner> TaskRunners::GetIOTaskRunner() const {
  return io_;
}

fml::RefPtr<fml::TaskRunner> TaskRunners::GetGPUTaskRunner() const {
  return gpu_;
}

bool TaskRunners::IsValid() const {
  return platform_ && gpu_ && ui_ && io_;
}

}  // namespace blink
