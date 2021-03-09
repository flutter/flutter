// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_FRAGMENT_ROOT_WIN_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_FRAGMENT_ROOT_WIN_H_

#include "ui/accessibility/platform/ax_platform_node_delegate_base.h"

#include <wrl/client.h>

namespace ui {

class AXFragmentRootDelegateWin;
class AXFragmentRootPlatformNodeWin;

// UI Automation on Windows requires the root of a multi-element provider to
// implement IRawElementProviderFragmentRoot. Our internal accessibility trees
// may not know their roots for right away; for example, web content may
// deserialize the document for an iframe before the host document. Because of
// this, and because COM rules require that the list of interfaces returned by
// QueryInterface remain static over the lifetime of an object instance, we
// implement IRawElementProviderFragmentRoot on its own node for each HWND, with
// the root of our internal accessibility tree for that HWND as its sole child.
//
// Since UIA derives some information from the underlying HWND hierarchy, we
// expose one fragment root per HWND. The class that owns the HWND is expected
// to own the corresponding AXFragmentRootWin.
class AX_EXPORT AXFragmentRootWin : public ui::AXPlatformNodeDelegateBase {
 public:
  AXFragmentRootWin(gfx::AcceleratedWidget widget,
                    AXFragmentRootDelegateWin* delegate);
  ~AXFragmentRootWin() override;

  // Fragment roots register themselves in a map upon creation and unregister
  // upon destruction. This method provides a lookup, which allows the internal
  // accessibility root to navigate back to the corresponding fragment root.
  static AXFragmentRootWin* GetForAcceleratedWidget(
      gfx::AcceleratedWidget widget);

  // If the given NativeViewAccessible is the direct descendant of a fragment
  // root, return the corresponding fragment root.
  static AXFragmentRootWin* GetFragmentRootParentOf(
      gfx::NativeViewAccessible accessible);

  // Returns the NativeViewAccessible for this fragment root.
  gfx::NativeViewAccessible GetNativeViewAccessible() override;

  // Assistive technologies will typically use UI Automation's control or
  // content view rather than the raw view.
  // Returns true if the fragment root should be included in the control and
  // content views or false if it should be excluded.
  bool IsControlElement();

  // If a child node is available, return its delegate.
  AXPlatformNodeDelegate* GetChildNodeDelegate() const;

 private:
  // AXPlatformNodeDelegate overrides.
  gfx::NativeViewAccessible GetParent() override;
  int GetChildCount() const override;
  gfx::NativeViewAccessible ChildAtIndex(int index) override;
  gfx::NativeViewAccessible GetNextSibling() override;
  gfx::NativeViewAccessible GetPreviousSibling() override;
  gfx::NativeViewAccessible HitTestSync(int x, int y) const override;
  gfx::NativeViewAccessible GetFocus() override;
  const ui::AXUniqueId& GetUniqueId() const override;
  gfx::AcceleratedWidget GetTargetForNativeAccessibilityEvent() override;
  AXPlatformNode* GetFromTreeIDAndNodeID(const ui::AXTreeID& ax_tree_id,
                                         int32_t id) override;

  // A fragment root does not correspond to any node in the platform neutral
  // accessibility tree. Rather, the fragment root's child is a child of the
  // fragment root's parent. This helper computes the child's index in the
  // parent's array of children.
  int GetIndexInParentOfChild() const;

  // If a parent node is available, return its delegate.
  AXPlatformNodeDelegate* GetParentNodeDelegate() const;

  gfx::AcceleratedWidget widget_;
  AXFragmentRootDelegateWin* const delegate_;
  Microsoft::WRL::ComPtr<ui::AXFragmentRootPlatformNodeWin> platform_node_;
  ui::AXUniqueId unique_id_;
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_FRAGMENT_ROOT_WIN_H_
