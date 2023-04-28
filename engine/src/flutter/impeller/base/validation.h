// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#ifndef IMPELLER_ENABLE_VALIDATION
#ifdef IMPELLER_DEBUG
#define IMPELLER_ENABLE_VALIDATION 1
#endif
#endif

#include <sstream>

#include "flutter/fml/macros.h"

namespace impeller {

class ValidationLog {
 public:
  ValidationLog();

  ~ValidationLog();

  std::ostream& GetStream();

 private:
  std::ostringstream stream_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(ValidationLog);
};

void ImpellerValidationBreak(const char* message);

void ImpellerValidationErrorsSetFatal(bool fatal);

struct ScopedValidationDisable {
  ScopedValidationDisable();

  ~ScopedValidationDisable();

  FML_DISALLOW_COPY_AND_ASSIGN(ScopedValidationDisable);
};

}  // namespace impeller

//------------------------------------------------------------------------------
/// Get a stream to the log Impeller uses for all validation errors. The
/// behavior of these logs is as follows:
///
/// * Validation error are completely ignored in the Flutter release
///   runtime-mode.
/// * In non-release runtime-modes, validation logs are redirected to the
///   Flutter `INFO` log. These logs typically show up when verbose logging is
///   enabled.
/// * If `ImpellerValidationErrorsSetFatal` is set to `true`, validation logs
///   are fatal. The runtime-mode restriction still applies. This usually
///   happens in test environments.
///
#define VALIDATION_LOG ::impeller::ValidationLog{}.GetStream()
