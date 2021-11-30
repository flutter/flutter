// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/base/validation.h"

#include "flutter/fml/logging.h"

namespace impeller {

ValidationLog::ValidationLog() = default;

ValidationLog::~ValidationLog() {
  FML_LOG(ERROR) << stream_.str();
  ImpellerValidationBreak();
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
