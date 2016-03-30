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
                         const mojo::ui::ViewProperties& value) {
  return os << "{display_metrics=" << value.display_metrics
            << ", view_layout=" << value.view_layout << "}";
}

std::ostream& operator<<(std::ostream& os,
                         const mojo::ui::DisplayMetrics& value) {
  return os << "{device_pixel_ratio=" << value.device_pixel_ratio << "}";
}

std::ostream& operator<<(std::ostream& os, const mojo::ui::ViewLayout& value) {
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
