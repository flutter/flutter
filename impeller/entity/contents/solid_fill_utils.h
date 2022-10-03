// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

class Tessellator;
class Path;
class HostBuffer;

/**
 * @brief Populate a VertexBuffer with solid fill vertices created by
 * tessellating an input path.
 *
 * @param tessellator    The tessellator
 * @param path           The path to be tessellated
 * @param buffer         The transient buffer
 * @return VertexBuffer  A populated vertex buffer if successful, otherwise
 * empty.
 */
VertexBuffer CreateSolidFillVertices(std::shared_ptr<Tessellator> tessellator,
                                     const Path& path,
                                     HostBuffer& buffer);

}  // namespace impeller
