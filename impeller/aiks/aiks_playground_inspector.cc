// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/aiks_playground_inspector.h"

#include <initializer_list>

#include "impeller/core/capture.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/renderer/context.h"
#include "third_party/imgui/imgui.h"
#include "third_party/imgui/imgui_internal.h"

namespace impeller {

static const char* kElementsWindowName = "Elements";
static const char* kPropertiesWindowName = "Properties";

static const std::initializer_list<std::string> kSupportedDocuments = {
    EntityPass::kCaptureDocumentName};

AiksInspector::AiksInspector() = default;

const std::optional<Picture>& AiksInspector::RenderInspector(
    AiksContext& aiks_context,
    const std::function<std::optional<Picture>()>& picture_callback) {
  //----------------------------------------------------------------------------
  /// Configure the next frame.
  ///

  RenderCapture(aiks_context.GetContext()->capture);

  //----------------------------------------------------------------------------
  /// Configure the next frame.
  ///

  if (ImGui::IsKeyPressed(ImGuiKey_Z)) {
    wireframe_ = !wireframe_;
    aiks_context.GetContentContext().SetWireframe(wireframe_);
  }

  if (ImGui::IsKeyPressed(ImGuiKey_C)) {
    capturing_ = !capturing_;
    if (capturing_) {
      aiks_context.GetContext()->capture =
          CaptureContext::MakeAllowlist({kSupportedDocuments});
    }
  }
  if (!capturing_) {
    hovered_element_ = nullptr;
    selected_element_ = nullptr;
    aiks_context.GetContext()->capture = CaptureContext::MakeInactive();
    std::optional<Picture> new_picture = picture_callback();

    // If the new picture doesn't have a pass, that means it was already moved
    // into the inspector. Simply re-emit the last received valid picture.
    if (!new_picture.has_value() || new_picture->pass) {
      last_picture_ = std::move(new_picture);
    }
  }

  return last_picture_;
}

static const auto kPropertiesProcTable = CaptureProcTable{
    .boolean =
        [](CaptureBooleanProperty& p) {
          ImGui::Checkbox(p.label.c_str(), &p.value);
        },
    .integer =
        [](CaptureIntegerProperty& p) {
          if (p.options.range.has_value()) {
            ImGui::SliderInt(p.label.c_str(), &p.value,
                             static_cast<int>(p.options.range->min),
                             static_cast<int>(p.options.range->max));
            return;
          }
          ImGui::InputInt(p.label.c_str(), &p.value);
        },
    .scalar =
        [](CaptureScalarProperty& p) {
          if (p.options.range.has_value()) {
            ImGui::SliderFloat(p.label.c_str(), &p.value, p.options.range->min,
                               p.options.range->max);
            return;
          }
          ImGui::DragFloat(p.label.c_str(), &p.value, 0.01);
        },
    .point =
        [](CapturePointProperty& p) {
          if (p.options.range.has_value()) {
            ImGui::SliderFloat2(p.label.c_str(),
                                reinterpret_cast<float*>(&p.value),
                                p.options.range->min, p.options.range->max);
            return;
          }
          ImGui::DragFloat2(p.label.c_str(), reinterpret_cast<float*>(&p.value),
                            0.01);
        },
    .vector3 =
        [](CaptureVector3Property& p) {
          if (p.options.range.has_value()) {
            ImGui::SliderFloat3(p.label.c_str(),
                                reinterpret_cast<float*>(&p.value),
                                p.options.range->min, p.options.range->max);
            return;
          }
          ImGui::DragFloat3(p.label.c_str(), reinterpret_cast<float*>(&p.value),
                            0.01);
        },
    .rect =
        [](CaptureRectProperty& p) {
          ImGui::DragFloat4(p.label.c_str(), reinterpret_cast<float*>(&p.value),
                            0.01);
        },
    .color =
        [](CaptureColorProperty& p) {
          ImGui::ColorEdit4(p.label.c_str(),
                            reinterpret_cast<float*>(&p.value));
        },
    .matrix =
        [](CaptureMatrixProperty& p) {
          float* pointer = reinterpret_cast<float*>(&p.value);
          ImGui::DragFloat4((p.label + " X basis").c_str(), pointer, 0.001);
          ImGui::DragFloat4((p.label + " Y basis").c_str(), pointer + 4, 0.001);
          ImGui::DragFloat4((p.label + " Z basis").c_str(), pointer + 8, 0.001);
          ImGui::DragFloat4((p.label + " Translation").c_str(), pointer + 12,
                            0.001);
        },
    .string =
        [](CaptureStringProperty& p) {
          ImGui::InputTextEx(p.label.c_str(), "",
                             // Fine as long as it's read-only.
                             const_cast<char*>(p.value.c_str()), p.value.size(),
                             ImVec2(0, 0), ImGuiInputTextFlags_ReadOnly);
        },
};

void AiksInspector::RenderCapture(CaptureContext& capture_context) {
  if (!capturing_) {
    return;
  }

  auto document = capture_context.GetDocument(EntityPass::kCaptureDocumentName);

  //----------------------------------------------------------------------------
  /// Setup a shared dockspace to collect the capture windows.
  ///

  ImGui::SetNextWindowBgAlpha(0.5);
  ImGui::Begin("Capture");
  auto dockspace_id = ImGui::GetID("CaptureDockspace");
  if (!ImGui::DockBuilderGetNode(dockspace_id)) {
    ImGui::SetWindowSize(ImVec2(370, 680));
    ImGui::SetWindowPos(ImVec2(640, 55));

    ImGui::DockBuilderRemoveNode(dockspace_id);
    ImGui::DockBuilderAddNode(dockspace_id);

    ImGuiID opposite_id;
    ImGuiID up_id = ImGui::DockBuilderSplitNode(dockspace_id, ImGuiDir_Up, 0.6,
                                                nullptr, &opposite_id);
    ImGuiID down_id = ImGui::DockBuilderSplitNode(opposite_id, ImGuiDir_Down,
                                                  0.0, nullptr, nullptr);
    ImGui::DockBuilderDockWindow(kElementsWindowName, up_id);
    ImGui::DockBuilderDockWindow(kPropertiesWindowName, down_id);

    ImGui::DockBuilderFinish(dockspace_id);
  }
  ImGui::DockSpace(dockspace_id);
  ImGui::End();  // Capture window.

  //----------------------------------------------------------------------------
  /// Element hierarchy window.
  ///

  ImGui::Begin(kElementsWindowName);
  auto root_element = document.GetElement();
  hovered_element_ = nullptr;
  if (root_element) {
    RenderCaptureElement(*root_element);
  }
  ImGui::End();  // Hierarchy window.

  if (selected_element_) {
    //----------------------------------------------------------------------------
    /// Properties window.
    ///

    ImGui::Begin(kPropertiesWindowName);
    {
      selected_element_->properties.Iterate([&](CaptureProperty& property) {
        property.Invoke(kPropertiesProcTable);
      });
    }
    ImGui::End();  // Inspector window.

    //----------------------------------------------------------------------------
    /// Selected coverage highlighting.
    ///

    auto coverage_property =
        selected_element_->properties.FindFirstByLabel("Coverage");
    if (coverage_property) {
      auto coverage = coverage_property->AsRect();
      if (coverage.has_value()) {
        Scalar scale = ImGui::GetWindowDpiScale();
        ImGui::GetBackgroundDrawList()->AddRect(
            ImVec2(coverage->GetLeft() / scale,
                   coverage->GetTop() / scale),  // p_min
            ImVec2(coverage->GetRight() / scale,
                   coverage->GetBottom() / scale),  // p_max
            0x992222FF,                             // col
            0.0,                                    // rounding
            ImDrawFlags_None,                       // flags
            8.0);                                   // thickness
      }
    }
  }

  //----------------------------------------------------------------------------
  /// Hover coverage highlight.
  ///

  if (hovered_element_) {
    auto coverage_property =
        hovered_element_->properties.FindFirstByLabel("Coverage");
    if (coverage_property) {
      auto coverage = coverage_property->AsRect();
      if (coverage.has_value()) {
        Scalar scale = ImGui::GetWindowDpiScale();
        ImGui::GetBackgroundDrawList()->AddRect(
            ImVec2(coverage->GetLeft() / scale,
                   coverage->GetTop() / scale),  // p_min
            ImVec2(coverage->GetRight() / scale,
                   coverage->GetBottom() / scale),  // p_max
            0x66FF2222,                             // col
            0.0,                                    // rounding
            ImDrawFlags_None,                       // flags
            8.0);                                   // thickness
      }
    }
  }
}

void AiksInspector::RenderCaptureElement(CaptureElement& element) {
  ImGui::PushID(&element);

  bool is_selected = selected_element_ == &element;
  bool has_children = element.children.Count() > 0;

  bool opened = ImGui::TreeNodeEx(
      element.label.c_str(), (is_selected ? ImGuiTreeNodeFlags_Selected : 0) |
                                 (has_children ? 0 : ImGuiTreeNodeFlags_Leaf) |
                                 ImGuiTreeNodeFlags_SpanFullWidth |
                                 ImGuiTreeNodeFlags_OpenOnArrow |
                                 ImGuiTreeNodeFlags_DefaultOpen);
  if (ImGui::IsItemClicked()) {
    selected_element_ = &element;
  }
  if (ImGui::IsItemHovered()) {
    hovered_element_ = &element;
  }
  if (opened) {
    element.children.Iterate(
        [&](CaptureElement& child) { RenderCaptureElement(child); });
    ImGui::TreePop();
  }
  ImGui::PopID();
}

}  // namespace impeller
