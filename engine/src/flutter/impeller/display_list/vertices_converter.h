// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_vertices.h"
#include "impeller/geometry/vertices.h"

namespace impeller {

/// Convert DlVertices into impeller Vertices.
Vertices ToVertices(const flutter::DlVertices* vertices);

}  // namespace impeller
