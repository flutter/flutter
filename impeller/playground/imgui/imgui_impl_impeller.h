// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "third_party/imgui/imgui.h"

namespace impeller {

class Context;
class RenderPass;

}  // namespace impeller

IMGUI_IMPL_API bool ImGui_ImplImpeller_Init(
    std::shared_ptr<impeller::Context> context);

IMGUI_IMPL_API void ImGui_ImplImpeller_Shutdown();

IMGUI_IMPL_API void ImGui_ImplImpeller_RenderDrawData(
    ImDrawData* draw_data,
    impeller::RenderPass& renderpass);
