// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/gpu_tracer_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

#ifdef IMPELLER_DEBUG
TEST(GPUTracerGLES, CanFormatFramebufferErrorMessage) {
  auto const extensions = std::vector<const unsigned char*>{
      reinterpret_cast<const unsigned char*>("GL_KHR_debug"),                 //
      reinterpret_cast<const unsigned char*>("GL_EXT_disjoint_timer_query"),  //
  };
  auto mock_gles = MockGLES::Init(extensions);
  auto tracer =
      std::make_shared<GPUTracerGLES>(mock_gles->GetProcTable(), true);
  tracer->RecordRasterThread();
  tracer->MarkFrameStart(mock_gles->GetProcTable());
  tracer->MarkFrameEnd(mock_gles->GetProcTable());

  auto calls = mock_gles->GetCapturedCalls();

  std::vector<std::string> expected = {"glGenQueriesEXT", "glBeginQueryEXT",
                                       "glEndQueryEXT"};
  for (auto i = 0; i < 3; i++) {
    EXPECT_EQ(calls[i], expected[i]);
  }

  // Begin second frame, which prompts the tracer to query the result
  // from the previous frame.
  tracer->MarkFrameStart(mock_gles->GetProcTable());

  calls = mock_gles->GetCapturedCalls();
  std::vector<std::string> expected_b = {"glGetQueryObjectuivEXT",
                                         "glGetQueryObjectui64vEXT",
                                         "glDeleteQueriesEXT"};
  for (auto i = 0; i < 3; i++) {
    EXPECT_EQ(calls[i], expected_b[i]);
  }
}

#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
