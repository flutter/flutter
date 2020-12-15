// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_ACCESSIBILITY_MOJOM_AX_RELATIVE_BOUNDS_MOJOM_TRAITS_H_
#define UI_ACCESSIBILITY_MOJOM_AX_RELATIVE_BOUNDS_MOJOM_TRAITS_H_

#include "ui/accessibility/ax_relative_bounds.h"
#include "ui/accessibility/mojom/ax_relative_bounds.mojom-shared.h"
#include "ui/gfx/geometry/mojom/geometry_mojom_traits.h"
#include "ui/gfx/mojom/transform.mojom.h"
#include "ui/gfx/mojom/transform_mojom_traits.h"

namespace mojo {

template <>
struct StructTraits<ax::mojom::AXRelativeBoundsDataView, ui::AXRelativeBounds> {
  static int32_t offset_container_id(const ui::AXRelativeBounds& p) {
    return p.offset_container_id;
  }

  static gfx::RectF bounds(const ui::AXRelativeBounds& p) { return p.bounds; }

  static gfx::Transform transform(const ui::AXRelativeBounds& p);

  static bool Read(ax::mojom::AXRelativeBoundsDataView data,
                   ui::AXRelativeBounds* out);
};

}  // namespace mojo

#endif  // UI_ACCESSIBILITY_MOJOM_AX_RELATIVE_BOUNDS_MOJOM_TRAITS_H_
