// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_TREE_ID_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_TREE_ID_MOJOM_TRAITS_H_

#include "mojo/public/cpp/base/unguessable_token_mojom_traits.h"
#include "ui/accessibility/ax_tree_id.h"
#include "ui/accessibility/mojom/ax_tree_id.mojom-shared.h"

namespace mojo {

template <>
struct UnionTraits<ax::mojom::AXTreeIDDataView, ui::AXTreeID> {
  static ax::mojom::AXTreeIDDataView::Tag GetTag(const ui::AXTreeID& p) {
    switch (p.type()) {
      case ax::mojom::AXTreeIDType::kUnknown:
        return ax::mojom::AXTreeIDDataView::Tag::UNKNOWN;
      case ax::mojom::AXTreeIDType::kToken:
        return ax::mojom::AXTreeIDDataView::Tag::TOKEN;
    }
  }
  static uint8_t unknown(const ui::AXTreeID& p) { return 0; }
  static const base::UnguessableToken token(const ui::AXTreeID& p) {
    DCHECK_EQ(p.type(), ax::mojom::AXTreeIDType::kToken);
    return *p.token();
  }

  static bool Read(ax::mojom::AXTreeIDDataView data, ui::AXTreeID* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_TREE_ID_MOJOM_TRAITS_H_
