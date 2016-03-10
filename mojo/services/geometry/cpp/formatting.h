// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GEOMETRY_CPP_FORMATTING_H_
#define MOJO_SERVICES_GEOMETRY_CPP_FORMATTING_H_

#include "mojo/public/cpp/bindings/formatting.h"
#include "mojo/services/geometry/interfaces/geometry.mojom.h"

namespace mojo {

std::ostream& operator<<(std::ostream& os, const mojo::Point& value);
std::ostream& operator<<(std::ostream& os, const mojo::PointF& value);
std::ostream& operator<<(std::ostream& os, const mojo::Rect& value);
std::ostream& operator<<(std::ostream& os, const mojo::RectF& value);
std::ostream& operator<<(std::ostream& os, const mojo::RRectF& value);
std::ostream& operator<<(std::ostream& os, const mojo::Size& value);
std::ostream& operator<<(std::ostream& os, const mojo::Transform& value);

}  // namespace mojo

#endif  // MOJO_SERVICES_GEOMETRY_CPP_FORMATTING_H_
