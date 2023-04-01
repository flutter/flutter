// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

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

#define VALIDATION_LOG ::impeller::ValidationLog{}.GetStream()
