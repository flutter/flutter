// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/flow/surface_frame.h"
#include "flutter/testing/testing.h"

namespace flutter {

TEST(FlowTest, SurfaceFrameDoesNotSubmitInDtor) {
  SurfaceFrame::FramebufferInfo framebuffer_info;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/
      [](const SurfaceFrame&, DlCanvas*) {
        EXPECT_FALSE(true);
        return true;
      },
      SkISize::Make(800, 600));
  surface_frame.reset();
}

#if IMPELLER_SUPPORTS_RENDERING
TEST(FlowTest, SurfaceFrameDoesNotHaveEmptyCanvas) {
  SurfaceFrame::FramebufferInfo framebuffer_info;
  SurfaceFrame frame(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600),
      /*context_result=*/nullptr, /*display_list_fallback=*/true);

  EXPECT_FALSE(frame.Canvas()->GetLocalClipBounds().isEmpty());
  EXPECT_FALSE(frame.Canvas()->QuickReject(SkRect::MakeLTRB(10, 10, 50, 50)));
}
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace flutter
