// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformNodeDelegateMac.h"

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"

#include "flutter/shell/platform/common/accessibility_bridge.h"
#include "flutter/third_party/accessibility/ax/ax_action_data.h"
#include "flutter/third_party/accessibility/ax/ax_node_position.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_base.h"
#include "flutter/third_party/accessibility/base/string_utils.h"
#include "flutter/third_party/accessibility/gfx/geometry/rect_conversions.h"

namespace flutter {  // namespace

FlutterPlatformNodeDelegateMac::FlutterPlatformNodeDelegateMac(FlutterEngine* engine)
    : engine_(engine) {
  ax_platform_node_ = ui::AXPlatformNode::Create(this);
  NSCAssert(ax_platform_node_, @"Failed to create platform node.");
}

FlutterPlatformNodeDelegateMac::~FlutterPlatformNodeDelegateMac() {
  ax_platform_node_->Destroy();
}

gfx::NativeViewAccessible FlutterPlatformNodeDelegateMac::GetNativeViewAccessible() {
  NSCAssert(ax_platform_node_, @"Platform node does not exist.");
  return ax_platform_node_->GetNativeViewAccessible();
}

gfx::NativeViewAccessible FlutterPlatformNodeDelegateMac::GetParent() {
  gfx::NativeViewAccessible parent = FlutterPlatformNodeDelegate::GetParent();
  if (!parent) {
    NSCAssert(engine_, @"Flutter engine should not be deallocated");
    return engine_.viewController.view;
  }
  return parent;
}

gfx::Rect FlutterPlatformNodeDelegateMac::GetBoundsRect(
    const ui::AXCoordinateSystem coordinate_system,
    const ui::AXClippingBehavior clipping_behavior,
    ui::AXOffscreenResult* offscreen_result) const {
  gfx::Rect local_bounds = FlutterPlatformNodeDelegate::GetBoundsRect(
      coordinate_system, clipping_behavior, offscreen_result);
  gfx::RectF local_bounds_f(local_bounds);
  gfx::RectF screen_bounds = ConvertBoundsFromLocalToScreen(local_bounds_f);
  return gfx::ToEnclosingRect(ConvertBoundsFromScreenToGlobal(screen_bounds));
}

gfx::NativeViewAccessible FlutterPlatformNodeDelegateMac::GetNSWindow() {
  FlutterAppDelegate* appDelegate = (FlutterAppDelegate*)[NSApp delegate];
  return appDelegate.mainFlutterWindow;
}

std::string FlutterPlatformNodeDelegateMac::GetLiveRegionText() const {
  if (GetAXNode()->IsIgnored()) {
    return "";
  }

  std::string text = GetData().GetStringAttribute(ax::mojom::StringAttribute::kName);
  if (!text.empty()) {
    return text;
  };
  NSCAssert(engine_, @"Flutter engine should not be deallocated");
  auto bridge_ptr = engine_.accessibilityBridge.lock();
  NSCAssert(bridge_ptr, @"Accessibility bridge in flutter engine must not be null.");
  for (int32_t child : GetData().child_ids) {
    auto delegate_child = bridge_ptr->GetFlutterPlatformNodeDelegateFromID(child).lock();
    if (!delegate_child) {
      continue;
    }
    text += std::static_pointer_cast<FlutterPlatformNodeDelegateMac>(delegate_child)
                ->GetLiveRegionText();
  }
  return text;
}

gfx::RectF FlutterPlatformNodeDelegateMac::ConvertBoundsFromLocalToScreen(
    const gfx::RectF& local_bounds) const {
  // Converts to NSRect to use NSView rect conversion.
  NSRect ns_local_bounds =
      NSMakeRect(local_bounds.x(), local_bounds.y(), local_bounds.width(), local_bounds.height());
  // The macOS XY coordinates start at bottom-left and increase toward top-right,
  // which is different from the Flutter's XY coordinates that start at top-left
  // increasing to bottom-right. Therefore, We need to flip the y coordinate when
  // we convert from flutter coordinates to macOS coordinates.
  ns_local_bounds.origin.y = -ns_local_bounds.origin.y - ns_local_bounds.size.height;
  __strong FlutterEngine* strong_engine = engine_;
  NSCAssert(strong_engine, @"Flutter engine should not be deallocated");
  NSRect ns_view_bounds =
      [strong_engine.viewController.view convertRectFromBacking:ns_local_bounds];
  NSRect ns_window_bounds = [strong_engine.viewController.view convertRect:ns_view_bounds
                                                                    toView:nil];
  NSRect ns_screen_bounds =
      [[strong_engine.viewController.view window] convertRectToScreen:ns_window_bounds];
  gfx::RectF screen_bounds(ns_screen_bounds.origin.x, ns_screen_bounds.origin.y,
                           ns_screen_bounds.size.width, ns_screen_bounds.size.height);
  return screen_bounds;
}

gfx::RectF FlutterPlatformNodeDelegateMac::ConvertBoundsFromScreenToGlobal(
    const gfx::RectF& screen_bounds) const {
  // The voiceover seems to only accept bounds that are relative to primary screen.
  // Thus, we use [[NSScreen screens] firstObject] instead of [NSScreen mainScreen].
  NSScreen* screen = [[NSScreen screens] firstObject];
  NSRect primary_screen_bounds = [screen frame];
  // The screen is flipped against y axis.
  float flipped_y = primary_screen_bounds.size.height - screen_bounds.y() - screen_bounds.height();
  return {screen_bounds.x(), flipped_y, screen_bounds.width(), screen_bounds.height()};
}

}  // namespace flutter
