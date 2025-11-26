// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/effects/image_filters/dl_combine_image_filter.h"

#include "flutter/display_list/utils/dl_comparable.h"

namespace flutter {

std::shared_ptr<DlImageFilter> DlCombineImageFilter::Make(
    const std::shared_ptr<DlImageFilter>& first,
    const std::shared_ptr<DlImageFilter>& second,
    const std::shared_ptr<DlImageFilter>& combiner) {
  if (!combiner) {
    // If there is no combiner, we can't really combine anything.
    // Returning null seems appropriate as "no filter".
    // Or should we return first? or second?
    // Without a combiner, the operation is undefined.
    return nullptr;
  }
  return std::make_shared<DlCombineImageFilter>(first, second, combiner);
}

bool DlCombineImageFilter::modifies_transparent_black() const {
  // If the combiner modifies transparent black, then the whole thing likely does.
  if (combiner_ && combiner_->modifies_transparent_black()) {
    return true;
  }
  // If the combiner doesn't modify transparent black, it might still produce
  // non-transparent output if its inputs are non-transparent.
  // But if inputs are transparent black (which they are by definition of this check),
  // and they don't modify it...
  // Actually, if first_ or second_ modifies transparent black, they produce
  // something from nothing.
  // Then combiner sees that something.
  // If combiner is transparent-preserving (like srcOver), it will preserve that something.
  // So if ANY of them modifies transparent black, we should return true?
  // Wait, if combiner is "SrcIn", and first produces color but second is transparent,
  // SrcIn might result in transparent.
  // But we must be conservative.
  if (first_ && first_->modifies_transparent_black()) {
    return true;
  }
  if (second_ && second_->modifies_transparent_black()) {
    return true;
  }
  return false;
}

DlRect* DlCombineImageFilter::map_local_bounds(const DlRect& input_bounds,
                                               DlRect& output_bounds) const {
  DlRect bounds1 = input_bounds;
  DlRect bounds2 = input_bounds;
  bool has_bounds1 = true;
  bool has_bounds2 = true;

  if (first_) {
    if (!first_->map_local_bounds(input_bounds, bounds1)) {
      has_bounds1 = false;
    }
  }
  if (second_) {
    if (!second_->map_local_bounds(input_bounds, bounds2)) {
      has_bounds2 = false;
    }
  }

  DlRect combined_inputs;
  if (has_bounds1 && has_bounds2) {
    combined_inputs = bounds1.Union(bounds2);
  } else if (has_bounds1) {
    combined_inputs = bounds1;
  } else if (has_bounds2) {
    combined_inputs = bounds2;
  } else {
    // Both failed to map bounds, or both are null (which means identity).
    // If both are null, bounds are input_bounds.
    // If one failed, we might want to be conservative and return nullptr?
    // But map_local_bounds returns nullptr on failure.
    // If first_ failed, it means it can't compute bounds.
    // We should probably propagate failure if we can't compute bounds for inputs.
    // But wait, if first_ is null, it's identity, so bounds1 = input_bounds.
    // map_local_bounds returns pointer to output_bounds on success.
    // If it returns nullptr, it means "can't compute".
    // If we can't compute bounds for one input, we can't compute union reliably?
    // Let's assume if map_local_bounds returns nullptr, it might be infinite or unknown.
    // Safest is to return nullptr.
    return nullptr;
  }

  if (combiner_) {
    return combiner_->map_local_bounds(combined_inputs, output_bounds);
  }
  
  // Should be unreachable if Make checks for combiner, but for safety:
  output_bounds = combined_inputs;
  return &output_bounds;
}

DlIRect* DlCombineImageFilter::map_device_bounds(const DlIRect& input_bounds,
                                                 const DlMatrix& ctm,
                                                 DlIRect& output_bounds) const {
  DlIRect bounds1 = input_bounds;
  DlIRect bounds2 = input_bounds;
  bool has_bounds1 = true;
  bool has_bounds2 = true;

  if (first_) {
    if (!first_->map_device_bounds(input_bounds, ctm, bounds1)) {
      has_bounds1 = false;
    }
  }
  if (second_) {
    if (!second_->map_device_bounds(input_bounds, ctm, bounds2)) {
      has_bounds2 = false;
    }
  }

  DlIRect combined_inputs;
  if (has_bounds1 && has_bounds2) {
    combined_inputs = bounds1.Union(bounds2);
  } else if (has_bounds1) {
    combined_inputs = bounds1;
  } else if (has_bounds2) {
    combined_inputs = bounds2;
  } else {
    return nullptr;
  }

  if (combiner_) {
    return combiner_->map_device_bounds(combined_inputs, ctm, output_bounds);
  }

  output_bounds = combined_inputs;
  return &output_bounds;
}

DlIRect* DlCombineImageFilter::get_input_device_bounds(
    const DlIRect& output_bounds,
    const DlMatrix& ctm,
    DlIRect& input_bounds) const {
  
  DlIRect req_combined;
  if (combiner_) {
    if (!combiner_->get_input_device_bounds(output_bounds, ctm, req_combined)) {
      return nullptr;
    }
  } else {
    req_combined = output_bounds;
  }

  DlIRect req1 = req_combined;
  DlIRect req2 = req_combined;
  bool has_req1 = true;
  bool has_req2 = true;

  if (first_) {
    if (!first_->get_input_device_bounds(req_combined, ctm, req1)) {
      has_req1 = false;
    }
  }
  if (second_) {
    if (!second_->get_input_device_bounds(req_combined, ctm, req2)) {
      has_req2 = false;
    }
  }

  if (has_req1 && has_req2) {
    input_bounds = req1.Union(req2);
    return &input_bounds;
  } else if (has_req1) {
    input_bounds = req1;
    return &input_bounds;
  } else if (has_req2) {
    input_bounds = req2;
    return &input_bounds;
  }

  return nullptr;
}

DlImageFilter::MatrixCapability DlCombineImageFilter::matrix_capability()
    const {
  // Conservative intersection of capabilities.
  auto cap = combiner_ ? combiner_->matrix_capability() : MatrixCapability::kComplex;
  if (first_) {
    cap = std::min(cap, first_->matrix_capability());
  }
  if (second_) {
    cap = std::min(cap, second_->matrix_capability());
  }
  return cap;
}

bool DlCombineImageFilter::equals_(const DlImageFilter& other) const {
  FML_DCHECK(other.type() == DlImageFilterType::kCombine);
  auto that = static_cast<const DlCombineImageFilter*>(&other);
  return (Equals(first_, that->first_) && Equals(second_, that->second_) &&
          Equals(combiner_, that->combiner_));
}

}  // namespace flutter
