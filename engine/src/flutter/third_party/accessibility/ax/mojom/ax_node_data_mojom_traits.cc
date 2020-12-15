// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_node_data_mojom_traits.h"
#include "ui/accessibility/mojom/ax_relative_bounds.mojom-shared.h"
#include "ui/accessibility/mojom/ax_relative_bounds_mojom_traits.h"

namespace mojo {

// static
std::unordered_map<ax::mojom::StringAttribute, std::string>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::string_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::StringAttribute, std::string> result;
  for (const auto& iter : p.string_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<ax::mojom::IntAttribute, int32_t>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::int_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::IntAttribute, int32_t> result;
  for (const auto& iter : p.int_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<ax::mojom::FloatAttribute, float>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::float_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::FloatAttribute, float> result;
  for (const auto& iter : p.float_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<ax::mojom::BoolAttribute, bool>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::bool_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::BoolAttribute, bool> result;
  for (const auto& iter : p.bool_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<ax::mojom::IntListAttribute, std::vector<int32_t>>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::intlist_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::IntListAttribute, std::vector<int32_t>> result;
  for (const auto& iter : p.intlist_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<ax::mojom::StringListAttribute, std::vector<std::string>>
StructTraits<ax::mojom::AXNodeDataDataView,
             ui::AXNodeData>::stringlist_attributes(const ui::AXNodeData& p) {
  std::unordered_map<ax::mojom::StringListAttribute, std::vector<std::string>>
      result;
  for (const auto& iter : p.stringlist_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
std::unordered_map<std::string, std::string>
StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::html_attributes(
    const ui::AXNodeData& p) {
  std::unordered_map<std::string, std::string> result;
  for (const auto& iter : p.html_attributes)
    result[iter.first] = iter.second;
  return result;
}

// static
bool StructTraits<ax::mojom::AXNodeDataDataView, ui::AXNodeData>::Read(
    ax::mojom::AXNodeDataDataView data,
    ui::AXNodeData* out) {
  out->id = data.id();
  out->role = data.role();
  out->state = data.state();
  out->actions = data.actions();

  std::unordered_map<ax::mojom::StringAttribute, std::string> string_attributes;
  if (!data.ReadStringAttributes(&string_attributes))
    return false;
  for (const auto& iter : string_attributes)
    out->AddStringAttribute(iter.first, iter.second);

  std::unordered_map<ax::mojom::IntAttribute, int32_t> int_attributes;
  if (!data.ReadIntAttributes(&int_attributes))
    return false;
  for (const auto& iter : int_attributes)
    out->AddIntAttribute(iter.first, iter.second);

  std::unordered_map<ax::mojom::FloatAttribute, float> float_attributes;
  if (!data.ReadFloatAttributes(&float_attributes))
    return false;
  for (const auto& iter : float_attributes)
    out->AddFloatAttribute(iter.first, iter.second);

  std::unordered_map<ax::mojom::BoolAttribute, bool> bool_attributes;
  if (!data.ReadBoolAttributes(&bool_attributes))
    return false;
  for (const auto& iter : bool_attributes)
    out->AddBoolAttribute(iter.first, iter.second);

  std::unordered_map<ax::mojom::IntListAttribute, std::vector<int32_t>>
      intlist_attributes;
  if (!data.ReadIntlistAttributes(&intlist_attributes))
    return false;
  for (const auto& iter : intlist_attributes)
    out->AddIntListAttribute(iter.first, iter.second);

  std::unordered_map<ax::mojom::StringListAttribute, std::vector<std::string>>
      stringlist_attributes;
  if (!data.ReadStringlistAttributes(&stringlist_attributes))
    return false;
  for (const auto& iter : stringlist_attributes)
    out->AddStringListAttribute(iter.first, iter.second);

  std::unordered_map<std::string, std::string> html_attributes;
  if (!data.ReadHtmlAttributes(&html_attributes))
    return false;
  for (const auto& iter : html_attributes)
    out->html_attributes.push_back(std::make_pair(iter.first, iter.second));

  if (!data.ReadChildIds(&out->child_ids))
    return false;

  if (!data.ReadRelativeBounds(&out->relative_bounds))
    return false;

  return true;
}

}  // namespace mojo
