// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_VIEW_SLICER_H_
#define FLUTTER_FLOW_VIEW_SLICER_H_

#include <unordered_map>
#include "display_list/dl_canvas.h"
#include "flow/embedded_views.h"

namespace flutter {

/// @brief Compute the required overlay layers and clip the view slices
///        according to the size and position of the platform views.
///
/// `extra_overlay_rects` forces the given region of a view's slice into that
/// view's overlay layer, even where it does not intersect a platform view. This
/// is used to keep content that must composite above a native backdrop effect
/// (for example the children of a backdrop filter) out of the background layer.
std::unordered_map<int64_t, DlRect> SliceViews(
    DlCanvas* background_canvas,
    const std::vector<int64_t>& composition_order,
    const std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>>&
        slices,
    const std::unordered_map<int64_t, DlRect>& view_rects,
    const std::unordered_map<int64_t, DlRect>& extra_overlay_rects = {});

}  // namespace flutter

#endif  // FLUTTER_FLOW_VIEW_SLICER_H_
