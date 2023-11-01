// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_playground.h"

#include "flutter/testing/testing.h"
#include "impeller/aiks/aiks_context.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/imgui/imgui.h"
#include "third_party/skia/include/core/SkData.h"

namespace impeller {

DlPlayground::DlPlayground() = default;

DlPlayground::~DlPlayground() = default;

bool DlPlayground::OpenPlaygroundHere(flutter::DisplayListBuilder& builder) {
  return OpenPlaygroundHere(builder.Build());
}

bool DlPlayground::OpenPlaygroundHere(sk_sp<flutter::DisplayList> list) {
  return OpenPlaygroundHere([&list]() { return list; });
}

bool DlPlayground::OpenPlaygroundHere(DisplayListPlaygroundCallback callback) {
  if (!switches_.enable_playground) {
    return true;
  }

  AiksContext context(GetContext(), TypographerContextSkia::Make());
  if (!context.IsValid()) {
    return false;
  }
  return Playground::OpenPlaygroundHere(
      [&context, &callback](RenderTarget& render_target) -> bool {
        static bool wireframe = false;
        if (ImGui::IsKeyPressed(ImGuiKey_Z)) {
          wireframe = !wireframe;
          context.GetContentContext().SetWireframe(wireframe);
        }

        auto list = callback();

        DlDispatcher dispatcher;
        list->Dispatch(dispatcher);
        auto picture = dispatcher.EndRecordingAsPicture();

        return context.Render(picture, render_target);
      });
}

SkFont DlPlayground::CreateTestFontOfSize(SkScalar scalar) {
  static constexpr const char* kTestFontFixture = "Roboto-Regular.ttf";
  auto mapping = flutter::testing::OpenFixtureAsSkData(kTestFontFixture);
  FML_CHECK(mapping);
  return SkFont{SkTypeface::MakeFromData(mapping), scalar};
}

SkFont DlPlayground::CreateTestFont() {
  return CreateTestFontOfSize(50);
}

}  // namespace impeller
