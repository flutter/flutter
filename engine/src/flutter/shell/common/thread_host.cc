// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/thread_host.h"

namespace flutter {

ThreadHost::ThreadHost() = default;

ThreadHost::ThreadHost(ThreadHost&&) = default;

ThreadHost::ThreadHost(std::string name_prefix, uint64_t mask) {
  if (mask & ThreadHost::Type::Platform) {
    platform_thread = std::make_unique<fml::Thread>(name_prefix + ".platform");
  }

  if (mask & ThreadHost::Type::UI) {
    ui_thread = std::make_unique<fml::Thread>(name_prefix + ".ui");
  }

  if (mask & ThreadHost::Type::GPU) {
    raster_thread = std::make_unique<fml::Thread>(name_prefix + ".raster");
  }

  if (mask & ThreadHost::Type::IO) {
    io_thread = std::make_unique<fml::Thread>(name_prefix + ".io");
  }

  if (mask & ThreadHost::Type::Profiler) {
    profiler_thread = std::make_unique<fml::Thread>(name_prefix + ".profiler");
  }
}

ThreadHost::~ThreadHost() = default;

void ThreadHost::Reset() {
  platform_thread.reset();
  ui_thread.reset();
  raster_thread.reset();
  io_thread.reset();
  profiler_thread.reset();
}

}  // namespace flutter
