// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/ui/views/cpp/formatting.h"

#include <ostream>

namespace mojo {
namespace ui {

std::ostream& operator<<(std::ostream& os, const mojo::ui::ViewToken& value) {
  return os << "{value=" << value.value << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewTreeToken& value) {
  return os << "{value=" << value.value << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::ui::ViewInfo& value) {
  return os << "{scene_token=" << value.scene_token << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::BoxConstraints& value) {
  return os << "{min_width=" << value.min_width
            << ", max_width=" << value.max_width
            << ", min_height=" << value.min_height
            << ", max_height=" << value.max_height << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutParams& value) {
  return os << "{constraints=" << value.constraints
            << ", device_pixel_ratio=" << value.device_pixel_ratio << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutInfo& value) {
  return os << "{size=" << value.size << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewLayoutResult& value) {
  return os << "{size=" << value.size << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::ViewAssociateInfo& value) {
  return os << "{view_service_names=" << value.view_service_names
            << ", view_tree_service_names=" << value.view_tree_service_names
            << "}";
}

}  // namespace ui
}  // namespace mojo
