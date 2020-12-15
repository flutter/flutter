// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_assistant_structure.h"

#include <string>

#include "base/logging.h"
#include "base/optional.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/accessibility/ax_node.h"
#include "ui/accessibility/ax_role_properties.h"
#include "ui/accessibility/ax_serializable_tree.h"
#include "ui/accessibility/platform/ax_android_constants.h"
#include "ui/gfx/geometry/rect_conversions.h"
#include "ui/gfx/range/range.h"
#include "ui/gfx/transform.h"

namespace ui {

namespace {

bool HasFocusableChild(const AXNode* node) {
  for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
    AXNode* child = node->GetUnignoredChildAtIndex(i);
    if (child->data().HasState(ax::mojom::State::kFocusable) ||
        HasFocusableChild(child)) {
      return true;
    }
  }
  return false;
}

bool HasOnlyTextChildren(const AXNode* node) {
  for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
    AXNode* child = node->GetUnignoredChildAtIndex(i);
    if (!child->IsText())
      return false;
  }
  return true;
}

// TODO(muyuanli): share with BrowserAccessibility.
bool IsSimpleTextControl(const AXNode* node, uint32_t state) {
  return (node->data().role == ax::mojom::Role::kTextField ||
          node->data().role == ax::mojom::Role::kTextFieldWithComboBox ||
          node->data().role == ax::mojom::Role::kSearchBox ||
          node->data().HasBoolAttribute(
              ax::mojom::BoolAttribute::kEditableRoot)) &&
         !node->data().HasState(ax::mojom::State::kRichlyEditable);
}

bool IsRichTextEditable(const AXNode* node) {
  const AXNode* parent = node->GetUnignoredParent();
  return node->data().HasState(ax::mojom::State::kRichlyEditable) &&
         (!parent ||
          !parent->data().HasState(ax::mojom::State::kRichlyEditable));
}

bool IsNativeTextControl(const AXNode* node) {
  const std::string& html_tag =
      node->data().GetStringAttribute(ax::mojom::StringAttribute::kHtmlTag);
  if (html_tag == "input") {
    std::string input_type;
    if (!node->data().GetHtmlAttribute("type", &input_type))
      return true;
    return input_type.empty() || input_type == "email" ||
           input_type == "password" || input_type == "search" ||
           input_type == "tel" || input_type == "text" || input_type == "url" ||
           input_type == "number";
  }
  return html_tag == "textarea";
}

bool IsLeaf(const AXNode* node) {
  if (node->children().empty())
    return true;

  if (IsNativeTextControl(node) || node->IsText()) {
    return true;
  }

  switch (node->data().role) {
    case ax::mojom::Role::kImage:
    case ax::mojom::Role::kMeter:
    case ax::mojom::Role::kScrollBar:
    case ax::mojom::Role::kSlider:
    case ax::mojom::Role::kSplitter:
    case ax::mojom::Role::kProgressIndicator:
    case ax::mojom::Role::kDate:
    case ax::mojom::Role::kDateTime:
    case ax::mojom::Role::kInputTime:
      return true;
    default:
      return false;
  }
}

base::string16 GetInnerText(const AXNode* node) {
  if (node->IsText()) {
    return node->data().GetString16Attribute(ax::mojom::StringAttribute::kName);
  }
  base::string16 text;
  for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
    AXNode* child = node->GetUnignoredChildAtIndex(i);
    text += GetInnerText(child);
  }
  return text;
}

base::string16 GetValue(const AXNode* node, bool show_password) {
  base::string16 value =
      node->data().GetString16Attribute(ax::mojom::StringAttribute::kValue);

  if (value.empty() &&
      (IsSimpleTextControl(node, node->data().state) ||
       IsRichTextEditable(node)) &&
      !IsNativeTextControl(node)) {
    value = GetInnerText(node);
  }

  if (node->data().HasState(ax::mojom::State::kProtected)) {
    if (!show_password) {
      value = base::string16(value.size(), kSecurePasswordBullet);
    }
  }

  return value;
}

bool HasOnlyTextAndImageChildren(const AXNode* node) {
  for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
    AXNode* child = node->GetUnignoredChildAtIndex(i);
    if (!child->IsText() && !ui::IsImage(child->data().role)) {
      return false;
    }
  }
  return true;
}

bool IsFocusable(const AXNode* node) {
  if (node->data().role == ax::mojom::Role::kIframe ||
      node->data().role == ax::mojom::Role::kIframePresentational ||
      (node->data().role == ax::mojom::Role::kRootWebArea &&
       node->GetUnignoredParent())) {
    return node->data().HasStringAttribute(ax::mojom::StringAttribute::kName);
  }
  return node->data().HasState(ax::mojom::State::kFocusable);
}

base::string16 GetText(const AXNode* node, bool show_password) {
  if (node->data().role == ax::mojom::Role::kWebArea ||
      node->data().role == ax::mojom::Role::kIframe ||
      node->data().role == ax::mojom::Role::kIframePresentational) {
    return base::string16();
  }

  ax::mojom::NameFrom name_from = static_cast<ax::mojom::NameFrom>(
      node->data().GetIntAttribute(ax::mojom::IntAttribute::kNameFrom));
  if (ui::IsListItem(node->data().role) &&
      name_from == ax::mojom::NameFrom::kContents) {
    if (!node->children().empty() && !HasOnlyTextChildren(node))
      return base::string16();
  }

  base::string16 value = GetValue(node, show_password);

  if (!value.empty()) {
    if (node->data().HasState(ax::mojom::State::kEditable))
      return value;

    switch (node->data().role) {
      case ax::mojom::Role::kComboBoxMenuButton:
      case ax::mojom::Role::kTextFieldWithComboBox:
      case ax::mojom::Role::kPopUpButton:
      case ax::mojom::Role::kTextField:
        return value;
      default:
        break;
    }
  }

  if (node->data().role == ax::mojom::Role::kColorWell) {
    unsigned int color = static_cast<unsigned int>(
        node->data().GetIntAttribute(ax::mojom::IntAttribute::kColorValue));
    unsigned int red = color >> 16 & 0xFF;
    unsigned int green = color >> 8 & 0xFF;
    unsigned int blue = color >> 0 & 0xFF;
    return base::UTF8ToUTF16(
        base::StringPrintf("#%02X%02X%02X", red, green, blue));
  }

  base::string16 text =
      node->data().GetString16Attribute(ax::mojom::StringAttribute::kName);
  base::string16 description = node->data().GetString16Attribute(
      ax::mojom::StringAttribute::kDescription);
  if (!description.empty()) {
    if (!text.empty())
      text += base::ASCIIToUTF16(" ");
    text += description;
  }

  if (text.empty())
    text = value;

  if (node->data().role == ax::mojom::Role::kRootWebArea)
    return text;

  if (text.empty() &&
      (HasOnlyTextChildren(node) ||
       (IsFocusable(node) && HasOnlyTextAndImageChildren(node)))) {
    for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
      AXNode* child = node->GetUnignoredChildAtIndex(i);
      text += GetText(child, show_password);
    }
  }

  if (text.empty() && (ui::IsLink(node->data().role) ||
                       node->data().role == ax::mojom::Role::kImage)) {
    base::string16 url =
        node->data().GetString16Attribute(ax::mojom::StringAttribute::kUrl);
    text = AXUrlBaseText(url);
  }
  return text;
}

// Get string representation of ax::mojom::Role. We are not using ToString() in
// ax_enums.h since the names are subject to change in the future and
// we are only interested in a subset of the roles.
base::Optional<std::string> AXRoleToString(ax::mojom::Role role) {
  switch (role) {
    case ax::mojom::Role::kArticle:
      return base::Optional<std::string>("article");
    case ax::mojom::Role::kBanner:
      return base::Optional<std::string>("banner");
    case ax::mojom::Role::kCaption:
      return base::Optional<std::string>("caption");
    case ax::mojom::Role::kComplementary:
      return base::Optional<std::string>("complementary");
    case ax::mojom::Role::kDate:
      return base::Optional<std::string>("date");
    case ax::mojom::Role::kDateTime:
      return base::Optional<std::string>("date_time");
    case ax::mojom::Role::kDefinition:
      return base::Optional<std::string>("definition");
    case ax::mojom::Role::kDetails:
      return base::Optional<std::string>("details");
    case ax::mojom::Role::kDocument:
      return base::Optional<std::string>("document");
    case ax::mojom::Role::kFeed:
      return base::Optional<std::string>("feed");
    case ax::mojom::Role::kHeading:
      return base::Optional<std::string>("heading");
    case ax::mojom::Role::kIframe:
      return base::Optional<std::string>("iframe");
    case ax::mojom::Role::kIframePresentational:
      return base::Optional<std::string>("iframe_presentational");
    case ax::mojom::Role::kList:
      return base::Optional<std::string>("list");
    case ax::mojom::Role::kListItem:
      return base::Optional<std::string>("list_item");
    case ax::mojom::Role::kMain:
      return base::Optional<std::string>("main");
    case ax::mojom::Role::kParagraph:
      return base::Optional<std::string>("paragraph");
    default:
      return base::Optional<std::string>();
  }
}

AssistantNode* AddChild(AssistantTree* tree) {
  auto node = std::make_unique<AssistantNode>();
  tree->nodes.push_back(std::move(node));
  return tree->nodes.back().get();
}

struct WalkAXTreeConfig {
  bool should_select_leaf;
  const bool show_password;
};

void WalkAXTreeDepthFirst(const AXNode* node,
                          const gfx::Rect& rect,
                          const AXTreeUpdate& update,
                          const AXTree* tree,
                          WalkAXTreeConfig* config,
                          AssistantTree* assistant_tree,
                          AssistantNode* result) {
  result->text = GetText(node, config->show_password);
  result->class_name =
      AXRoleToAndroidClassName(node->data().role, node->GetUnignoredParent());
  result->role = AXRoleToString(node->data().role);

  result->text_size = -1.0;
  result->bgcolor = 0;
  result->color = 0;
  result->bold = 0;
  result->italic = 0;
  result->line_through = 0;
  result->underline = 0;

  if (node->data().HasFloatAttribute(ax::mojom::FloatAttribute::kFontSize)) {
    gfx::RectF text_size_rect(
        0, 0, 1,
        node->data().GetFloatAttribute(ax::mojom::FloatAttribute::kFontSize));
    gfx::Rect scaled_text_size_rect =
        gfx::ToEnclosingRect(tree->RelativeToTreeBounds(node, text_size_rect));
    result->text_size = scaled_text_size_rect.height();

    result->color =
        node->data().GetIntAttribute(ax::mojom::IntAttribute::kColor);
    result->bgcolor =
        node->data().GetIntAttribute(ax::mojom::IntAttribute::kBackgroundColor);
    result->bold = node->data().HasTextStyle(ax::mojom::TextStyle::kBold);
    result->italic = node->data().HasTextStyle(ax::mojom::TextStyle::kItalic);
    result->line_through =
        node->data().HasTextStyle(ax::mojom::TextStyle::kLineThrough);
    result->underline =
        node->data().HasTextStyle(ax::mojom::TextStyle::kUnderline);
  }

  const gfx::Rect& absolute_rect =
      gfx::ToEnclosingRect(tree->GetTreeBounds(node));
  gfx::Rect parent_relative_rect = absolute_rect;
  bool is_root = !node->GetUnignoredParent();
  if (!is_root) {
    parent_relative_rect.Offset(-rect.OffsetFromOrigin());
  }
  result->rect = gfx::Rect(parent_relative_rect.x(), parent_relative_rect.y(),
                           absolute_rect.width(), absolute_rect.height());

  if (IsLeaf(node) && update.has_tree_data) {
    int start_selection = 0;
    int end_selection = 0;
    AXTree::Selection unignored_selection = tree->GetUnignoredSelection();
    if (unignored_selection.anchor_object_id == node->id()) {
      start_selection = unignored_selection.anchor_offset;
      config->should_select_leaf = true;
    }

    if (config->should_select_leaf) {
      end_selection =
          static_cast<int32_t>(GetText(node, config->show_password).length());
    }

    if (unignored_selection.focus_object_id == node->id()) {
      end_selection = unignored_selection.focus_offset;
      config->should_select_leaf = false;
    }
    if (end_selection > 0)
      result->selection =
          base::make_optional<gfx::Range>(start_selection, end_selection);
  }

  for (size_t i = 0; i < node->GetUnignoredChildCount(); ++i) {
    AXNode* child = node->GetUnignoredChildAtIndex(i);
    auto* n = AddChild(assistant_tree);
    result->children_indices.push_back(assistant_tree->nodes.size() - 1);
    WalkAXTreeDepthFirst(child, absolute_rect, update, tree, config,
                         assistant_tree, n);
  }
}

}  // namespace

AssistantNode::AssistantNode() = default;
AssistantNode::AssistantNode(const AssistantNode& other) = default;
AssistantNode::~AssistantNode() = default;

AssistantTree::AssistantTree() = default;
AssistantTree::~AssistantTree() = default;

AssistantTree::AssistantTree(const AssistantTree& other) {
  for (const auto& node : other.nodes)
    nodes.emplace_back(std::make_unique<AssistantNode>(*node));
}

std::unique_ptr<AssistantTree> CreateAssistantTree(const AXTreeUpdate& update,
                                                   bool show_password) {
  auto tree = std::make_unique<AXSerializableTree>();
  auto assistant_tree = std::make_unique<AssistantTree>();
  auto* root = AddChild(assistant_tree.get());
  if (!tree->Unserialize(update))
    LOG(FATAL) << tree->error();
  WalkAXTreeConfig config{
      false,         // should_select_leaf
      show_password  // show_password
  };
  WalkAXTreeDepthFirst(tree->root(), gfx::Rect(), update, tree.get(), &config,
                       assistant_tree.get(), root);
  return assistant_tree;
}

base::string16 AXUrlBaseText(base::string16 url) {
  // Given a url like http://foo.com/bar/baz.png, just return the
  // base text, e.g., "baz".
  int trailing_slashes = 0;
  while (url.size() - trailing_slashes > 0 &&
         url[url.size() - trailing_slashes - 1] == '/') {
    trailing_slashes++;
  }
  if (trailing_slashes)
    url = url.substr(0, url.size() - trailing_slashes);
  size_t slash_index = url.rfind('/');
  if (slash_index != std::string::npos)
    url = url.substr(slash_index + 1);
  size_t dot_index = url.rfind('.');
  if (dot_index != std::string::npos)
    url = url.substr(0, dot_index);
  return url;
}

const char* AXRoleToAndroidClassName(ax::mojom::Role role, bool has_parent) {
  switch (role) {
    case ax::mojom::Role::kSearchBox:
    case ax::mojom::Role::kSpinButton:
    case ax::mojom::Role::kTextField:
    case ax::mojom::Role::kTextFieldWithComboBox:
      return kAXEditTextClassname;
    case ax::mojom::Role::kSlider:
      return kAXSeekBarClassname;
    case ax::mojom::Role::kColorWell:
    case ax::mojom::Role::kComboBoxMenuButton:
    case ax::mojom::Role::kDate:
    case ax::mojom::Role::kPopUpButton:
    case ax::mojom::Role::kInputTime:
      return kAXSpinnerClassname;
    case ax::mojom::Role::kButton:
    case ax::mojom::Role::kPdfActionableHighlight:
      return kAXButtonClassname;
    case ax::mojom::Role::kCheckBox:
    case ax::mojom::Role::kSwitch:
      return kAXCheckBoxClassname;
    case ax::mojom::Role::kRadioButton:
      return kAXRadioButtonClassname;
    case ax::mojom::Role::kToggleButton:
      return kAXToggleButtonClassname;
    case ax::mojom::Role::kCanvas:
    case ax::mojom::Role::kImage:
    case ax::mojom::Role::kSvgRoot:
      return kAXImageClassname;
    case ax::mojom::Role::kMeter:
    case ax::mojom::Role::kProgressIndicator:
      return kAXProgressBarClassname;
    case ax::mojom::Role::kTabList:
      return kAXTabWidgetClassname;
    case ax::mojom::Role::kGrid:
    case ax::mojom::Role::kTreeGrid:
    case ax::mojom::Role::kTable:
      return kAXGridViewClassname;
    case ax::mojom::Role::kList:
    case ax::mojom::Role::kListBox:
    case ax::mojom::Role::kDescriptionList:
      return kAXListViewClassname;
    case ax::mojom::Role::kDialog:
      return kAXDialogClassname;
    case ax::mojom::Role::kRootWebArea:
      return has_parent ? kAXViewClassname : kAXWebViewClassname;
    case ax::mojom::Role::kMenuItem:
    case ax::mojom::Role::kMenuItemCheckBox:
    case ax::mojom::Role::kMenuItemRadio:
      return kAXMenuItemClassname;
    case ax::mojom::Role::kStaticText:
      return kAXTextViewClassname;
    default:
      return kAXViewClassname;
  }
}

}  // namespace ui
