// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <sstream>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"

namespace impeller {
namespace compiler {

class AutoLogger {
 public:
  AutoLogger(std::stringstream& logger) : logger_(logger) {}

  ~AutoLogger() {
    logger_ << std::endl;
    logger_.flush();
  }

  template <class T>
  AutoLogger& operator<<(const T& object) {
    logger_ << object;
    return *this;
  }

 private:
  std::stringstream& logger_;

  AutoLogger(const AutoLogger&) = delete;

  AutoLogger& operator=(const AutoLogger&) = delete;
};

#define COMPILER_ERROR(stream) \
  ::impeller::compiler::AutoLogger(stream) << GetSourcePrefix()

#define COMPILER_ERROR_NO_PREFIX(stream) \
  ::impeller::compiler::AutoLogger(stream)

}  // namespace compiler
}  // namespace impeller
