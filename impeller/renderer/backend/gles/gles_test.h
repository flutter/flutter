// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

class GLESTest : public ::testing::Test {
 public:
  GLESTest();

  ~GLESTest();

  ProcTableGLES::Resolver GetResolver() const;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(GLESTest);
};

}  // namespace impeller
