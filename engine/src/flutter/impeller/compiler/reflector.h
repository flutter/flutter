// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "third_party/spirv_cross/spirv_msl.hpp"

namespace impeller {
namespace compiler {

class Reflector {
 public:
  Reflector(const spirv_cross::CompilerMSL& compiler);

  ~Reflector();

  bool IsValid() const;

 private:
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(Reflector);
};

}  // namespace compiler
}  // namespace impeller
