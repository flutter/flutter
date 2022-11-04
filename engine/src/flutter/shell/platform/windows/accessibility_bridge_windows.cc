// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_bridge_windows.h"

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_windows.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_delegate_base.h"

namespace flutter {

AccessibilityBridgeWindows::AccessibilityBridgeWindows(
    FlutterWindowsEngine* engine,
    FlutterWindowsView* view)
    : engine_(engine), view_(view) {
  assert(engine_);
  assert(view_);
}

void AccessibilityBridgeWindows::OnAccessibilityEvent(
    ui::AXEventGenerator::TargetedEvent targeted_event) {
  ui::AXNode* ax_node = targeted_event.node;
  ui::AXEventGenerator::Event event_type = targeted_event.event_params.event;

  auto node_delegate =
      GetFlutterPlatformNodeDelegateFromID(ax_node->id()).lock();
  assert(node_delegate);
  std::shared_ptr<FlutterPlatformNodeDelegateWindows> win_delegate =
      std::static_pointer_cast<FlutterPlatformNodeDelegateWindows>(
          node_delegate);

  switch (event_type) {
    case ui::AXEventGenerator::Event::ALERT:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_SYSTEM_ALERT);
      break;
    case ui::AXEventGenerator::Event::CHECKED_STATE_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_VALUECHANGE);
      break;
    case ui::AXEventGenerator::Event::CHILDREN_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_REORDER);
      break;
    case ui::AXEventGenerator::Event::FOCUS_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_FOCUS);
      SetFocus(win_delegate);
      break;
    case ui::AXEventGenerator::Event::IGNORED_CHANGED:
      if (ax_node->IsIgnored()) {
        DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_HIDE);
      }
      break;
    case ui::AXEventGenerator::Event::IMAGE_ANNOTATION_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_NAMECHANGE);
      break;
    case ui::AXEventGenerator::Event::LIVE_REGION_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate,
                                    EVENT_OBJECT_LIVEREGIONCHANGED);
      break;
    case ui::AXEventGenerator::Event::NAME_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_NAMECHANGE);
      break;
    case ui::AXEventGenerator::Event::SCROLL_HORIZONTAL_POSITION_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_SYSTEM_SCROLLINGEND);
      break;
    case ui::AXEventGenerator::Event::SCROLL_VERTICAL_POSITION_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_SYSTEM_SCROLLINGEND);
      break;
    case ui::AXEventGenerator::Event::SELECTED_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_VALUECHANGE);
      break;
    case ui::AXEventGenerator::Event::SELECTED_CHILDREN_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_SELECTIONWITHIN);
      break;
    case ui::AXEventGenerator::Event::SUBTREE_CREATED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_SHOW);
      break;
    case ui::AXEventGenerator::Event::VALUE_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_VALUECHANGE);
      break;
    case ui::AXEventGenerator::Event::WIN_IACCESSIBLE_STATE_CHANGED:
      DispatchWinAccessibilityEvent(win_delegate, EVENT_OBJECT_STATECHANGE);
      break;
    case ui::AXEventGenerator::Event::ACCESS_KEY_CHANGED:
    case ui::AXEventGenerator::Event::ACTIVE_DESCENDANT_CHANGED:
    case ui::AXEventGenerator::Event::ATK_TEXT_OBJECT_ATTRIBUTE_CHANGED:
    case ui::AXEventGenerator::Event::ATOMIC_CHANGED:
    case ui::AXEventGenerator::Event::AUTO_COMPLETE_CHANGED:
    case ui::AXEventGenerator::Event::BUSY_CHANGED:
    case ui::AXEventGenerator::Event::CLASS_NAME_CHANGED:
    case ui::AXEventGenerator::Event::COLLAPSED:
    case ui::AXEventGenerator::Event::CONTROLS_CHANGED:
    case ui::AXEventGenerator::Event::DESCRIBED_BY_CHANGED:
    case ui::AXEventGenerator::Event::DESCRIPTION_CHANGED:
    case ui::AXEventGenerator::Event::DOCUMENT_SELECTION_CHANGED:
    case ui::AXEventGenerator::Event::DOCUMENT_TITLE_CHANGED:
    case ui::AXEventGenerator::Event::DROPEFFECT_CHANGED:
    case ui::AXEventGenerator::Event::ENABLED_CHANGED:
    case ui::AXEventGenerator::Event::EXPANDED:
    case ui::AXEventGenerator::Event::FLOW_FROM_CHANGED:
    case ui::AXEventGenerator::Event::FLOW_TO_CHANGED:
    case ui::AXEventGenerator::Event::GRABBED_CHANGED:
    case ui::AXEventGenerator::Event::HASPOPUP_CHANGED:
    case ui::AXEventGenerator::Event::HIERARCHICAL_LEVEL_CHANGED:
    case ui::AXEventGenerator::Event::INVALID_STATUS_CHANGED:
    case ui::AXEventGenerator::Event::KEY_SHORTCUTS_CHANGED:
    case ui::AXEventGenerator::Event::LABELED_BY_CHANGED:
    case ui::AXEventGenerator::Event::LANGUAGE_CHANGED:
    case ui::AXEventGenerator::Event::LAYOUT_INVALIDATED:
    case ui::AXEventGenerator::Event::LIVE_REGION_CREATED:
    case ui::AXEventGenerator::Event::LIVE_REGION_NODE_CHANGED:
    case ui::AXEventGenerator::Event::LIVE_RELEVANT_CHANGED:
    case ui::AXEventGenerator::Event::LIVE_STATUS_CHANGED:
    case ui::AXEventGenerator::Event::LOAD_COMPLETE:
    case ui::AXEventGenerator::Event::LOAD_START:
    case ui::AXEventGenerator::Event::MENU_ITEM_SELECTED:
    case ui::AXEventGenerator::Event::MULTILINE_STATE_CHANGED:
    case ui::AXEventGenerator::Event::MULTISELECTABLE_STATE_CHANGED:
    case ui::AXEventGenerator::Event::OBJECT_ATTRIBUTE_CHANGED:
    case ui::AXEventGenerator::Event::OTHER_ATTRIBUTE_CHANGED:
    case ui::AXEventGenerator::Event::PLACEHOLDER_CHANGED:
    case ui::AXEventGenerator::Event::PORTAL_ACTIVATED:
    case ui::AXEventGenerator::Event::POSITION_IN_SET_CHANGED:
    case ui::AXEventGenerator::Event::READONLY_CHANGED:
    case ui::AXEventGenerator::Event::RELATED_NODE_CHANGED:
    case ui::AXEventGenerator::Event::REQUIRED_STATE_CHANGED:
    case ui::AXEventGenerator::Event::ROLE_CHANGED:
    case ui::AXEventGenerator::Event::ROW_COUNT_CHANGED:
    case ui::AXEventGenerator::Event::SET_SIZE_CHANGED:
    case ui::AXEventGenerator::Event::SORT_CHANGED:
    case ui::AXEventGenerator::Event::STATE_CHANGED:
    case ui::AXEventGenerator::Event::TEXT_ATTRIBUTE_CHANGED:
    case ui::AXEventGenerator::Event::VALUE_MAX_CHANGED:
    case ui::AXEventGenerator::Event::VALUE_MIN_CHANGED:
    case ui::AXEventGenerator::Event::VALUE_STEP_CHANGED:
      // Unhandled event type.
      break;
  }
}

void AccessibilityBridgeWindows::DispatchAccessibilityAction(
    AccessibilityNodeId target,
    FlutterSemanticsAction action,
    fml::MallocMapping data) {
  engine_->DispatchSemanticsAction(target, action, std::move(data));
}

std::shared_ptr<FlutterPlatformNodeDelegate>
AccessibilityBridgeWindows::CreateFlutterPlatformNodeDelegate() {
  return std::make_shared<FlutterPlatformNodeDelegateWindows>(
      shared_from_this(), view_);
}

void AccessibilityBridgeWindows::DispatchWinAccessibilityEvent(
    std::shared_ptr<FlutterPlatformNodeDelegateWindows> node_delegate,
    DWORD event_type) {
  node_delegate->DispatchWinAccessibilityEvent(event_type);
}

void AccessibilityBridgeWindows::SetFocus(
    std::shared_ptr<FlutterPlatformNodeDelegateWindows> node_delegate) {
  node_delegate->SetFocus();
}

}  // namespace flutter
