// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/thread_host.h"

#include <algorithm>
#include <memory>
#include <optional>
#include <string>
#include <utility>

namespace flutter {

std::string ThreadHost::ThreadHostConfig::MakeThreadName(
    Type type,
    const std::string& prefix) {
  switch (type) {
    case Type::Platform:
      return prefix + ".platform";
    case Type::UI:
      return prefix + ".ui";
    case Type::IO:
      return prefix + ".io";
    case Type::RASTER:
      return prefix + ".raster";
    case Type::Profiler:
      return prefix + ".profiler";
  }
}

void ThreadHost::ThreadHostConfig::SetIOConfig(const ThreadConfig& config) {
  type_mask |= ThreadHost::Type::IO;
  io_config = config;
}

void ThreadHost::ThreadHostConfig::SetUIConfig(const ThreadConfig& config) {
  type_mask |= ThreadHost::Type::UI;
  ui_config = config;
}

void ThreadHost::ThreadHostConfig::SetPlatformConfig(
    const ThreadConfig& config) {
  type_mask |= ThreadHost::Type::Platform;
  platform_config = config;
}

void ThreadHost::ThreadHostConfig::SetRasterConfig(const ThreadConfig& config) {
  type_mask |= ThreadHost::Type::RASTER;
  raster_config = config;
}

void ThreadHost::ThreadHostConfig::SetProfilerConfig(
    const ThreadConfig& config) {
  type_mask |= ThreadHost::Type::Profiler;
  profiler_config = config;
}

std::unique_ptr<fml::Thread> ThreadHost::CreateThread(
    Type type,
    std::optional<ThreadConfig> thread_config,
    const ThreadHostConfig& host_config) const {
  /// if not specified ThreadConfig, create a ThreadConfig.
  if (!thread_config.has_value()) {
    thread_config = ThreadConfig(
        ThreadHostConfig::MakeThreadName(type, host_config.name_prefix));
  }
  return std::make_unique<fml::Thread>(host_config.config_setter,
                                       thread_config.value());
}

ThreadHost::ThreadHost() = default;

ThreadHost::ThreadHost(ThreadHost&&) = default;

ThreadHost::ThreadHost(const std::string name_prefix, uint64_t mask)
    : ThreadHost(ThreadHostConfig(name_prefix, mask)) {}

ThreadHost::ThreadHost(const ThreadHostConfig& host_config)
    : name_prefix(host_config.name_prefix) {
  if (host_config.isThreadNeeded(ThreadHost::Type::Platform)) {
    platform_thread =
        CreateThread(Type::Platform, host_config.platform_config, host_config);
  }

  if (host_config.isThreadNeeded(ThreadHost::Type::UI)) {
    ui_thread = CreateThread(Type::UI, host_config.ui_config, host_config);
  }

  if (host_config.isThreadNeeded(ThreadHost::Type::RASTER)) {
    raster_thread =
        CreateThread(Type::RASTER, host_config.raster_config, host_config);
  }

  if (host_config.isThreadNeeded(ThreadHost::Type::IO)) {
    io_thread = CreateThread(Type::IO, host_config.io_config, host_config);
  }

  if (host_config.isThreadNeeded(ThreadHost::Type::Profiler)) {
    profiler_thread =
        CreateThread(Type::Profiler, host_config.profiler_config, host_config);
  }
}

ThreadHost::~ThreadHost() = default;

}  // namespace flutter
