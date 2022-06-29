// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"
#include "impeller/base/validation.h"
#include "impeller/compiler/compiler.h"
#include "impeller/compiler/source_options.h"
#include "impeller/compiler/types.h"

namespace impeller {
namespace compiler {
namespace testing {

class CompilerTest : public ::testing::TestWithParam<TargetPlatform> {
 public:
  CompilerTest();

  ~CompilerTest();

  bool CanCompileAndReflect(
      const char* fixture_name,
      SourceType source_type = SourceType::kUnknown) const;

 private:
  fml::UniqueFD intermediates_directory_;

  FML_DISALLOW_COPY_AND_ASSIGN(CompilerTest);
};

}  // namespace testing
}  // namespace compiler
}  // namespace impeller
