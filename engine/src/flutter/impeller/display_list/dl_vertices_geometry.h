// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/dl_vertices.h"

#include "impeller/entity/geometry/vertices_geometry.h"

namespace impeller {

std::shared_ptr<VerticesGeometry> MakeVertices(
    const flutter::DlVertices* vertices);

}  // namespace impeller
