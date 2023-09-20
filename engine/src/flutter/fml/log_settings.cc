// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/log_settings.h"

#include <fcntl.h>

#include <algorithm>
#include <cstring>
#include <iostream>
#include <limits>

#include "flutter/fml/build_config.h"
#include "flutter/fml/log_level.h"
#include "flutter/fml/logging.h"

#if defined(OS_FUCHSIA)
#include <lib/syslog/global.h>
#endif

namespace fml {
namespace state {

// Defined in log_settings_state.cc.
extern LogSettings g_log_settings;

}  // namespace state

void SetLogSettings(const LogSettings& settings) {
  // Validate the new settings as we set them.
  state::g_log_settings.min_log_level =
      std::min(kLogFatal, settings.min_log_level);
#if defined(OS_FUCHSIA)
  // Syslog should accept all logs, since filtering by severity is done by fml.
  fx_logger_t* logger = fx_log_get_logger();
  if (logger) {
    fx_logger_set_min_severity(logger,
                               std::numeric_limits<fx_log_severity_t>::min());
  }
#endif
}

LogSettings GetLogSettings() {
  return state::g_log_settings;
}

int GetMinLogLevel() {
  return std::min(state::g_log_settings.min_log_level, kLogFatal);
}

ScopedSetLogSettings::ScopedSetLogSettings(const LogSettings& settings) {
  old_settings_ = GetLogSettings();
  SetLogSettings(settings);
}

ScopedSetLogSettings::~ScopedSetLogSettings() {
  SetLogSettings(old_settings_);
}

}  // namespace fml
