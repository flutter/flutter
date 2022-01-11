// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/variable_refresh_rate_display.h"
#include "flutter/fml/logging.h"

namespace flutter {

VariableRefreshRateDisplay::VariableRefreshRateDisplay(
    DisplayId display_id,
    const VariableRefreshRateReporter& refresh_rate_reporter)
    : Display(display_id, refresh_rate_reporter.GetRefreshRate()),
      refresh_rate_reporter_(refresh_rate_reporter) {}

VariableRefreshRateDisplay::VariableRefreshRateDisplay(
    const VariableRefreshRateReporter& refresh_rate_reporter)
    : Display(refresh_rate_reporter.GetRefreshRate()),
      refresh_rate_reporter_(refresh_rate_reporter) {}

double VariableRefreshRateDisplay::GetRefreshRate() const {
  return refresh_rate_reporter_.GetRefreshRate();
}

}  // namespace flutter
