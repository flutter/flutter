// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_view_embedder.h"

#include <memory>
#include <vector>

#include "flutter/common/constants.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter {
namespace testing {
namespace {

class MockImpellerContext final
    : public impeller::testing::MockImpellerContext {
 public:
  MOCK_METHOD(void, DisposeThreadLocalCachedResources, (), (override));
};

std::unique_ptr<SurfaceFrame> MakeSurfaceFrame(bool& submitted) {
  return std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr,
      /*framebuffer_info=*/SurfaceFrame::FramebufferInfo{},
      /*encode_callback=*/[](SurfaceFrame&, DlCanvas*) { return true; },
      /*submit_callback=*/
      [&submitted](SurfaceFrame&) {
        submitted = true;
        return true;
      },
      /*frame_size=*/DlISize(1, 1),
      /*context_result=*/nullptr,
      /*display_list_fallback=*/true);
}

std::unique_ptr<ExternalViewEmbedder> MakeExternalViewEmbedder(
    const EmbedderExternalViewEmbedder::PresentCallback& present_callback) {
  return std::make_unique<EmbedderExternalViewEmbedder>(
      /*avoid_backing_store_cache=*/false,
      /*create_render_target_callback=*/
      [](GrDirectContext*, const std::shared_ptr<impeller::AiksContext>&,
         const FlutterBackingStoreConfig&)
          -> std::unique_ptr<EmbedderRenderTarget> {
        ADD_FAILURE() << "A render target was unexpectedly requested.";
        return nullptr;
      },
      present_callback);
}

TEST(EmbedderExternalViewEmbedderTest,
     DisposesThreadLocalResourcesBeforePresentation) {
  auto context = std::make_shared<MockImpellerContext>();
  EXPECT_CALL(*context, IsValid()).WillOnce(::testing::Return(false));
  auto aiks_context = std::make_shared<impeller::AiksContext>(context, nullptr);

  bool disposed = false;
  EXPECT_CALL(*context, DisposeThreadLocalCachedResources())
      .WillOnce([&disposed] { disposed = true; });

  bool presented = false;
  auto external_view_embedder = MakeExternalViewEmbedder(
      [&disposed, &presented](FlutterViewId view_id,
                              const std::vector<const FlutterLayer*>& layers) {
        EXPECT_TRUE(disposed);
        EXPECT_EQ(view_id, kFlutterImplicitViewId);
        EXPECT_TRUE(layers.empty());
        presented = true;
        return true;
      });

  bool submitted = false;
  external_view_embedder->PrepareFlutterView(DlISize(1, 1), 1.0);
  external_view_embedder->SubmitFlutterView(kFlutterImplicitViewId, nullptr,
                                            aiks_context,
                                            MakeSurfaceFrame(submitted));

  EXPECT_TRUE(presented);
  EXPECT_TRUE(submitted);
}

TEST(EmbedderExternalViewEmbedderTest, HandlesNullImpellerContext) {
  auto aiks_context = std::make_shared<impeller::AiksContext>(nullptr, nullptr);
  ASSERT_EQ(aiks_context->GetContext(), nullptr);

  bool presented = false;
  auto external_view_embedder = MakeExternalViewEmbedder(
      [&presented](FlutterViewId, const std::vector<const FlutterLayer*>&) {
        presented = true;
        return true;
      });

  bool submitted = false;
  external_view_embedder->PrepareFlutterView(DlISize(1, 1), 1.0);
  external_view_embedder->SubmitFlutterView(kFlutterImplicitViewId, nullptr,
                                            aiks_context,
                                            MakeSurfaceFrame(submitted));

  EXPECT_TRUE(presented);
  EXPECT_TRUE(submitted);
}

}  // namespace
}  // namespace testing
}  // namespace flutter
