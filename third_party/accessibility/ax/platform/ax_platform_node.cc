// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_node.h"

#include "base/debug/crash_logging.h"
#include "base/lazy_instance.h"
#include "build/build_config.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/platform/ax_platform_node_delegate.h"
#include "ui/base/buildflags.h"

namespace ui {

// static
base::LazyInstance<base::ObserverList<AXModeObserver>::Unchecked>::Leaky
    AXPlatformNode::ax_mode_observers_ = LAZY_INSTANCE_INITIALIZER;

// static
base::LazyInstance<AXPlatformNode::NativeWindowHandlerCallback>::Leaky
    AXPlatformNode::native_window_handler_ = LAZY_INSTANCE_INITIALIZER;

// static
AXMode AXPlatformNode::ax_mode_;

// static
gfx::NativeViewAccessible AXPlatformNode::popup_focus_override_ = nullptr;

// static
AXPlatformNode* AXPlatformNode::FromNativeWindow(
    gfx::NativeWindow native_window) {
  if (native_window_handler_.Get())
    return native_window_handler_.Get().Run(native_window);
  return nullptr;
}

#if !BUILDFLAG_INTERNAL_HAS_NATIVE_ACCESSIBILITY()
// static
AXPlatformNode* AXPlatformNode::FromNativeViewAccessible(
    gfx::NativeViewAccessible accessible) {
  return nullptr;
}
#endif  // !BUILDFLAG_INTERNAL_HAS_NATIVE_ACCESSIBILITY()

// static
void AXPlatformNode::RegisterNativeWindowHandler(
    AXPlatformNode::NativeWindowHandlerCallback handler) {
  native_window_handler_.Get() = handler;
}

AXPlatformNode::AXPlatformNode() {}

AXPlatformNode::~AXPlatformNode() {
}

void AXPlatformNode::Destroy() {
}

int32_t AXPlatformNode::GetUniqueId() const {
  DCHECK(GetDelegate()) << "|GetUniqueId| must be called after |Init|.";
  return GetDelegate() ? GetDelegate()->GetUniqueId().Get() : -1;
}

void AXPlatformNode::SetIsPrimaryWebContentsForWindow(bool is_primary) {
  is_primary_web_contents_for_window_ = is_primary;
}

bool AXPlatformNode::IsPrimaryWebContentsForWindow() const {
  return is_primary_web_contents_for_window_;
}

std::string AXPlatformNode::ToString() {
  return GetDelegate() ? GetDelegate()->ToString() : "No delegate";
}

std::string AXPlatformNode::SubtreeToString() {
  return GetDelegate() ? GetDelegate()->SubtreeToString() : "No delegate";
}

std::ostream& operator<<(std::ostream& stream, AXPlatformNode& node) {
  return stream << node.ToString();
}

// static
void AXPlatformNode::AddAXModeObserver(AXModeObserver* observer) {
  ax_mode_observers_.Get().AddObserver(observer);
}

// static
void AXPlatformNode::RemoveAXModeObserver(AXModeObserver* observer) {
  ax_mode_observers_.Get().RemoveObserver(observer);
}

// static
void AXPlatformNode::NotifyAddAXModeFlags(AXMode mode_flags) {
  // Note: this is only called on Windows.
  AXMode new_ax_mode(ax_mode_);
  new_ax_mode |= mode_flags;

  if (new_ax_mode == ax_mode_)
    return;  // No change.

  ax_mode_ = new_ax_mode;
  for (auto& observer : ax_mode_observers_.Get())
    observer.OnAXModeAdded(mode_flags);
}

// static
void AXPlatformNode::SetPopupFocusOverride(
    gfx::NativeViewAccessible popup_focus_override) {
  popup_focus_override_ = popup_focus_override;
}

// static
gfx::NativeViewAccessible AXPlatformNode::GetPopupFocusOverride() {
  return popup_focus_override_;
}

}  // namespace ui
