// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/base/validation.h"

#include <atomic>

#include "flutter/fml/logging.h"

namespace impeller {

static std::atomic_int32_t sValidationLogsDisabledCount = 0;

ScopedValidationDisable::ScopedValidationDisable() {
  sValidationLogsDisabledCount++;
}

ScopedValidationDisable::~ScopedValidationDisable() {
  sValidationLogsDisabledCount--;
}

ValidationLog::ValidationLog() = default;

ValidationLog::~ValidationLog() {
  if (sValidationLogsDisabledCount <= 0) {
    FML_LOG(ERROR) << stream_.str();
    ImpellerValidationBreak();
  }
}

std::ostream& ValidationLog::GetStream() {
  return stream_;
}

void ImpellerValidationBreak() {
  // Nothing to do. Exists for the debugger.
  FML_LOG(ERROR) << "Break on " << __FUNCTION__
                 << " to inspect point of failure.";
}

}  // namespace impeller
