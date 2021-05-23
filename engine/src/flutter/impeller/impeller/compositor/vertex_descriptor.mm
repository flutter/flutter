// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/vertex_descriptor.h"

#include "flutter/fml/logging.h"

namespace impeller {

VertexDescriptor::VertexDescriptor() = default;

VertexDescriptor::~VertexDescriptor() = default;

// |Comparable<VertexDescriptor>|
std::size_t VertexDescriptor::GetHash() const {
  FML_CHECK(false);
  return 0;
}

// |Comparable<VertexDescriptor>|
bool VertexDescriptor::IsEqual(const VertexDescriptor& other) const {
  FML_CHECK(false);
  return false;
}

}  // namespace impeller
