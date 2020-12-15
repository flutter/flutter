// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_tree_id_mojom_traits.h"

namespace mojo {

// static
bool UnionTraits<ax::mojom::AXTreeIDDataView, ui::AXTreeID>::Read(
    ax::mojom::AXTreeIDDataView data,
    ui::AXTreeID* out) {
  switch (data.tag()) {
    case ax::mojom::AXTreeIDDataView::Tag::UNKNOWN:
      out->type_ = ax::mojom::AXTreeIDType::kUnknown;
      return true;
    case ax::mojom::AXTreeIDDataView::Tag::TOKEN:
      out->type_ = ax::mojom::AXTreeIDType::kToken;
      if (!data.ReadToken(&out->token_))
        return false;
      return true;
  }

  NOTREACHED();
  return false;
}

}  // namespace mojo
