// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEXTCHILDPROVIDER_WIN_H_
#define UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEXTCHILDPROVIDER_WIN_H_

#include <wrl/client.h>

#include "ui/accessibility/ax_export.h"
#include "ui/accessibility/platform/ax_platform_node_win.h"

namespace ui {
class AX_EXPORT AXPlatformNodeTextChildProviderWin
    : public CComObjectRootEx<CComMultiThreadModel>,
      public ITextChildProvider {
 public:
  BEGIN_COM_MAP(AXPlatformNodeTextChildProviderWin)
  COM_INTERFACE_ENTRY(ITextChildProvider)
  END_COM_MAP()

  AXPlatformNodeTextChildProviderWin();
  ~AXPlatformNodeTextChildProviderWin();

  static AXPlatformNodeTextChildProviderWin* Create(
      ui::AXPlatformNodeWin* owner);
  static void CreateIUnknown(AXPlatformNodeWin* owner, IUnknown** unknown);

  // Retrieves this element's nearest ancestor provider that supports the Text
  // control pattern. If the element does not have an ancestor which supports
  // the Text control pattern, nullptr is returned. Note, an element which
  // supports the Text control pattern is not an ancestor of itself.
  IFACEMETHODIMP get_TextContainer(
      IRawElementProviderSimple** pRetVal) override;

  // Retrieves a text range that encloses this child element. If the element
  // does not have an ancestor which supports the Text control pattern, nullptr
  // is returned. Note, an element which supports the Text control pattern is
  // not an ancestor of itself.
  IFACEMETHODIMP get_TextRange(ITextRangeProvider** pRetVal) override;

  // Helper function to get_TextContainer().
  static AXPlatformNodeWin* GetTextContainer(AXPlatformNodeWin* descendant);

 private:
  AXPlatformNodeWin* owner() const;

  Microsoft::WRL::ComPtr<AXPlatformNodeWin> owner_;
};

}  // namespace ui

#endif  // UI_ACCESSIBILITY_PLATFORM_AX_PLATFORM_NODE_TEXTCHILDPROVIDER_WIN_H_
