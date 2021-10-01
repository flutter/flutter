// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SRC_LIB_UI_BASE_VIEW_MATH_H_
#define SRC_LIB_UI_BASE_VIEW_MATH_H_

#include <fuchsia/ui/gfx/cpp/fidl.h>

namespace scenic {

// Return a vec3 consisting of the component-wise sum of the two arguments.
inline fuchsia::ui::gfx::vec3 operator+(const fuchsia::ui::gfx::vec3& a,
                                        const fuchsia::ui::gfx::vec3& b) {
  return {.x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z};
}

// Return a vec3 consisting of the component-wise difference of the two args.
inline fuchsia::ui::gfx::vec3 operator-(const fuchsia::ui::gfx::vec3& a,
                                        const fuchsia::ui::gfx::vec3& b) {
  return {.x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z};
}

// Return true if |point| is contained by |box|, including when it is on the
// box boundary, and false otherwise.
inline bool ContainsPoint(const fuchsia::ui::gfx::BoundingBox& box,
                          const fuchsia::ui::gfx::vec3& point) {
  return point.x >= box.min.x && point.y >= box.min.y && point.z >= box.min.z &&
         point.x <= box.max.x && point.y <= box.max.y && point.z <= box.max.z;
}

// Similar to fuchsia::ui::gfx::ViewProperties: adds the inset to box.min, and
// subtracts it from box.max.
inline fuchsia::ui::gfx::BoundingBox InsetBy(
    const fuchsia::ui::gfx::BoundingBox& box,
    const fuchsia::ui::gfx::vec3& inset) {
  return {.min = box.min + inset, .max = box.max - inset};
}

// Similar to fuchsia::ui::gfx::ViewProperties: adds the inset to box.min, and
// subtracts it from box.max.
inline fuchsia::ui::gfx::BoundingBox InsetBy(
    const fuchsia::ui::gfx::BoundingBox& box,
    const fuchsia::ui::gfx::vec3& inset_from_min,
    const fuchsia::ui::gfx::vec3& inset_from_max) {
  return {.min = box.min + inset_from_min, .max = box.max - inset_from_max};
}

// Inset the view properties' outer box by its insets.
inline fuchsia::ui::gfx::BoundingBox ViewPropertiesLayoutBox(
    const fuchsia::ui::gfx::ViewProperties& view_properties) {
  return InsetBy(view_properties.bounding_box, view_properties.inset_from_min,
                 view_properties.inset_from_max);
}

// Return a vec3 consisting of the maximum x/y/z from the two arguments.
inline fuchsia::ui::gfx::vec3 Max(const fuchsia::ui::gfx::vec3& a,
                                  const fuchsia::ui::gfx::vec3& b) {
  return {.x = std::max(a.x, b.x),
          .y = std::max(a.y, b.y),
          .z = std::max(a.z, b.z)};
}

// Return a vec3 consisting of the maximum of the x/y/z components of |v|,
// compared with |min_val|.
inline fuchsia::ui::gfx::vec3 Max(const fuchsia::ui::gfx::vec3& v,
                                  float min_val) {
  return {.x = std::max(v.x, min_val),
          .y = std::max(v.y, min_val),
          .z = std::max(v.z, min_val)};
}

// Return a vec3 consisting of the minimum x/y/z from the two arguments.
inline fuchsia::ui::gfx::vec3 Min(const fuchsia::ui::gfx::vec3& a,
                                  const fuchsia::ui::gfx::vec3& b) {
  return {.x = std::min(a.x, b.x),
          .y = std::min(a.y, b.y),
          .z = std::min(a.z, b.z)};
}

// Return a vec3 consisting of the minimum of the x/y/z components of |v|,
// compared with |max_val|.
inline fuchsia::ui::gfx::vec3 Min(const fuchsia::ui::gfx::vec3& v,
                                  float max_val) {
  return {.x = std::min(v.x, max_val),
          .y = std::min(v.y, max_val),
          .z = std::min(v.z, max_val)};
}

}  // namespace scenic

#endif  // SRC_LIB_UI_BASE_VIEW_MATH_H_
