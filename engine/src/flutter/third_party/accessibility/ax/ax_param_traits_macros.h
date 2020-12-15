// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_
#define UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_

#include "build/build_config.h"
#include "ipc/ipc_message_macros.h"
#include "ui/accessibility/ax_enums.mojom-shared.h"
#include "ui/accessibility/ax_event.h"
#include "ui/accessibility/ax_event_intent.h"
#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/ax_tree_id.h"
#include "ui/accessibility/ax_tree_update.h"
#include "ui/gfx/ipc/geometry/gfx_param_traits.h"
#include "ui/gfx/ipc/skia/gfx_skia_param_traits.h"

#undef IPC_MESSAGE_EXPORT
#define IPC_MESSAGE_EXPORT AX_EXPORT

IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::Event, ax::mojom::Event::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::Role, ax::mojom::Role::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::BoolAttribute,
                          ax::mojom::BoolAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::FloatAttribute,
                          ax::mojom::FloatAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::IntAttribute,
                          ax::mojom::IntAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::IntListAttribute,
                          ax::mojom::IntListAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::StringListAttribute,
                          ax::mojom::StringListAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::StringAttribute,
                          ax::mojom::StringAttribute::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::TextAffinity,
                          ax::mojom::TextAffinity::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::EventFrom, ax::mojom::EventFrom::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::Command, ax::mojom::Command::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::TextBoundary,
                          ax::mojom::TextBoundary::kMaxValue)
IPC_ENUM_TRAITS_MAX_VALUE(ax::mojom::MoveDirection,
                          ax::mojom::MoveDirection::kMaxValue)

IPC_STRUCT_TRAITS_BEGIN(ui::AXRelativeBounds)
  IPC_STRUCT_TRAITS_MEMBER(offset_container_id)
  IPC_STRUCT_TRAITS_MEMBER(bounds)
  IPC_STRUCT_TRAITS_MEMBER(transform)
IPC_STRUCT_TRAITS_END()

IPC_STRUCT_TRAITS_BEGIN(ui::AXEvent)
  IPC_STRUCT_TRAITS_MEMBER(event_type)
  IPC_STRUCT_TRAITS_MEMBER(id)
  IPC_STRUCT_TRAITS_MEMBER(event_from)
  IPC_STRUCT_TRAITS_MEMBER(event_intents)
  IPC_STRUCT_TRAITS_MEMBER(action_request_id)
IPC_STRUCT_TRAITS_END()

IPC_STRUCT_TRAITS_BEGIN(ui::AXEventIntent)
  IPC_STRUCT_TRAITS_MEMBER(command)
  IPC_STRUCT_TRAITS_MEMBER(text_boundary)
  IPC_STRUCT_TRAITS_MEMBER(move_direction)
IPC_STRUCT_TRAITS_END()

IPC_STRUCT_TRAITS_BEGIN(ui::AXNodeData)
  IPC_STRUCT_TRAITS_MEMBER(id)
  IPC_STRUCT_TRAITS_MEMBER(role)
  IPC_STRUCT_TRAITS_MEMBER(state)
  IPC_STRUCT_TRAITS_MEMBER(actions)
  IPC_STRUCT_TRAITS_MEMBER(string_attributes)
  IPC_STRUCT_TRAITS_MEMBER(int_attributes)
  IPC_STRUCT_TRAITS_MEMBER(float_attributes)
  IPC_STRUCT_TRAITS_MEMBER(bool_attributes)
  IPC_STRUCT_TRAITS_MEMBER(intlist_attributes)
  IPC_STRUCT_TRAITS_MEMBER(stringlist_attributes)
  IPC_STRUCT_TRAITS_MEMBER(html_attributes)
  IPC_STRUCT_TRAITS_MEMBER(child_ids)
  IPC_STRUCT_TRAITS_MEMBER(relative_bounds)
IPC_STRUCT_TRAITS_END()

IPC_STRUCT_TRAITS_BEGIN(ui::AXTreeData)
  IPC_STRUCT_TRAITS_MEMBER(tree_id)
  IPC_STRUCT_TRAITS_MEMBER(parent_tree_id)
  IPC_STRUCT_TRAITS_MEMBER(focused_tree_id)
  IPC_STRUCT_TRAITS_MEMBER(url)
  IPC_STRUCT_TRAITS_MEMBER(title)
  IPC_STRUCT_TRAITS_MEMBER(mimetype)
  IPC_STRUCT_TRAITS_MEMBER(doctype)
  IPC_STRUCT_TRAITS_MEMBER(loaded)
  IPC_STRUCT_TRAITS_MEMBER(loading_progress)
  IPC_STRUCT_TRAITS_MEMBER(focus_id)
  IPC_STRUCT_TRAITS_MEMBER(sel_is_backward)
  IPC_STRUCT_TRAITS_MEMBER(sel_anchor_object_id)
  IPC_STRUCT_TRAITS_MEMBER(sel_anchor_offset)
  IPC_STRUCT_TRAITS_MEMBER(sel_anchor_affinity)
  IPC_STRUCT_TRAITS_MEMBER(sel_focus_object_id)
  IPC_STRUCT_TRAITS_MEMBER(sel_focus_offset)
  IPC_STRUCT_TRAITS_MEMBER(sel_focus_affinity)
IPC_STRUCT_TRAITS_END()

IPC_STRUCT_TRAITS_BEGIN(ui::AXTreeUpdate)
  IPC_STRUCT_TRAITS_MEMBER(has_tree_data)
  IPC_STRUCT_TRAITS_MEMBER(tree_data)
  IPC_STRUCT_TRAITS_MEMBER(node_id_to_clear)
  IPC_STRUCT_TRAITS_MEMBER(root_id)
  IPC_STRUCT_TRAITS_MEMBER(nodes)
  IPC_STRUCT_TRAITS_MEMBER(event_from)
  IPC_STRUCT_TRAITS_MEMBER(event_intents)
IPC_STRUCT_TRAITS_END()

#undef IPC_MESSAGE_EXPORT
#define IPC_MESSAGE_EXPORT

#endif  // UI_ACCESSIBILITY_AX_PARAM_TRAITS_MACROS_H_
