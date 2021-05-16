// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/compiler/reflector.h"

#include <sstream>

#include "flutter/fml/logging.h"

namespace impeller {
namespace compiler {

Reflector::Reflector(const spirv_cross::CompilerMSL& compiler) {
  is_valid_ = true;
}

Reflector::~Reflector() = default;

bool Reflector::IsValid() const {
  return is_valid_;
}

}  // namespace compiler
}  // namespace impeller
