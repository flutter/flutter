// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>

#include "gtest/gtest.h"

#include "impeller/entity/contents/checkerboard_contents.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/test/recording_render_pass.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/renderer/render_target.h"

namespace impeller {
namespace testing {

using EntityTest = EntityPlayground;

#ifdef IMPELLER_DEBUG
TEST(EntityTest, HasNulloptCoverage) {
  auto contents = std::make_shared<CheckerboardContents>();

  Entity entity;
  ASSERT_EQ(contents->GetCoverage(entity), std::nullopt);
}

TEST_P(EntityTest, RendersWithoutError) {
  auto contents = std::make_shared<CheckerboardContents>();
  contents->SetColor(Color::Aqua());
  contents->SetSquareSize(10);

  auto content_context = GetContentContext();
  auto buffer = content_context->GetContext()->CreateCommandBuffer();
  auto render_target =
      GetContentContext()->GetRenderTargetCache()->CreateOffscreenMSAA(
          *content_context->GetContext(), {100, 100},
          /*mip_count=*/1);
  auto render_pass = buffer->CreateRenderPass(render_target);
  auto recording_pass = std::make_shared<RecordingRenderPass>(
      render_pass, GetContext(), render_target);

  Entity entity;

  ASSERT_TRUE(recording_pass->GetCommands().empty());
  ASSERT_TRUE(contents->Render(*content_context, entity, *recording_pass));
  ASSERT_FALSE(recording_pass->GetCommands().empty());

  if (GetParam() == PlaygroundBackend::kMetal) {
    recording_pass->EncodeCommands();
  }
}
#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace impeller
