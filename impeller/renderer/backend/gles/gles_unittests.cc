// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/backend/gles/gles_test.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {
namespace testing {

TEST_F(GLESTest, CanCreateProcTable) {
  ProcTableGLES gl(GetResolver());
  ASSERT_TRUE(gl.IsValid());
}

}  // namespace testing
}  // namespace impeller
