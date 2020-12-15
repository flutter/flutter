// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/platform/ax_platform_node_textchildprovider_win.h"

#include <UIAutomationClient.h>
#include <UIAutomationCoreApi.h>

#include "ui/accessibility/platform/ax_platform_node_textprovider_win.h"
#include "ui/base/win/atl_module.h"

#define UIA_VALIDATE_TEXTCHILDPROVIDER_CALL() \
  if (!owner()->GetDelegate())                \
    return UIA_E_ELEMENTNOTAVAILABLE;

namespace ui {

namespace {

AXPlatformNodeWin* GetParentAXPlatformNodeWin(AXPlatformNodeWin* node) {
  gfx::NativeViewAccessible native_parent = node->GetParent();

  DCHECK(native_parent != node->GetNativeViewAccessible());

  return static_cast<AXPlatformNodeWin*>(
      AXPlatformNode::FromNativeViewAccessible(native_parent));
}

}  // namespace

AXPlatformNodeTextChildProviderWin::AXPlatformNodeTextChildProviderWin() {
  DVLOG(1) << __func__;
}

AXPlatformNodeTextChildProviderWin::~AXPlatformNodeTextChildProviderWin() {}

// static
AXPlatformNodeTextChildProviderWin* AXPlatformNodeTextChildProviderWin::Create(
    AXPlatformNodeWin* owner) {
  CComObject<AXPlatformNodeTextChildProviderWin>* text_child_provider = nullptr;
  if (SUCCEEDED(CComObject<AXPlatformNodeTextChildProviderWin>::CreateInstance(
          &text_child_provider))) {
    DCHECK(text_child_provider);
    text_child_provider->owner_ = owner;
    text_child_provider->AddRef();
    return text_child_provider;
  }

  return nullptr;
}

// static
void AXPlatformNodeTextChildProviderWin::CreateIUnknown(
    AXPlatformNodeWin* owner,
    IUnknown** unknown) {
  Microsoft::WRL::ComPtr<AXPlatformNodeTextChildProviderWin>
      text_child_provider(Create(owner));
  if (text_child_provider)
    *unknown = text_child_provider.Detach();
}

HRESULT AXPlatformNodeTextChildProviderWin::get_TextContainer(
    IRawElementProviderSimple** result) {
  WIN_ACCESSIBILITY_API_HISTOGRAM(UMA_API_TEXTCHILD_GET_TEXTCONTAINER);
  UIA_VALIDATE_TEXTCHILDPROVIDER_CALL();

  *result = nullptr;

  AXPlatformNodeWin* container = GetTextContainer(owner_.Get());
  if (container)
    container->QueryInterface(IID_PPV_ARGS(result));

  return S_OK;
}

HRESULT AXPlatformNodeTextChildProviderWin::get_TextRange(
    ITextRangeProvider** result) {
  WIN_ACCESSIBILITY_API_HISTOGRAM(UMA_API_TEXTCHILD_GET_TEXTRANGE);
  UIA_VALIDATE_TEXTCHILDPROVIDER_CALL();

  *result = nullptr;

  AXPlatformNodeWin* container = GetTextContainer(owner_.Get());
  if (container && container->IsDescendant(owner())) {
    *result =
        AXPlatformNodeTextProviderWin::GetRangeFromChild(container, owner());
  }

  return S_OK;
}

AXPlatformNodeWin* AXPlatformNodeTextChildProviderWin::GetTextContainer(
    AXPlatformNodeWin* descendant) {
  for (AXPlatformNodeWin* parent = GetParentAXPlatformNodeWin(descendant);
       parent; parent = GetParentAXPlatformNodeWin(parent)) {
    if (parent->IsPatternProviderSupported(UIA_TextPatternId)) {
      return parent;
    }
  }

  return nullptr;
}

AXPlatformNodeWin* AXPlatformNodeTextChildProviderWin::owner() const {
  return owner_.Get();
}

}  // namespace ui
