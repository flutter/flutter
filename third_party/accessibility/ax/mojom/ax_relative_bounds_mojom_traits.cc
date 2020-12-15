// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "ui/accessibility/mojom/ax_relative_bounds_mojom_traits.h"

namespace mojo {

// static
gfx::Transform
StructTraits<ax::mojom::AXRelativeBoundsDataView,
             ui::AXRelativeBounds>::transform(const ui::AXRelativeBounds& p) {
  if (p.transform)
    return *p.transform;
  else
    return gfx::Transform();
}

// static
bool StructTraits<ax::mojom::AXRelativeBoundsDataView, ui::AXRelativeBounds>::
    Read(ax::mojom::AXRelativeBoundsDataView data, ui::AXRelativeBounds* out) {
  out->offset_container_id = data.offset_container_id();

  gfx::Transform transform;
  if (!data.ReadTransform(&transform))
    return false;
  if (!transform.IsIdentity())
    out->transform = std::make_unique<gfx::Transform>(transform);

  if (!data.ReadBounds(&out->bounds))
    return false;

  return true;
}

}  // namespace mojo
