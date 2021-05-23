// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/compositor/comparable.h"

namespace impeller {

class VertexDescriptor : public Comparable<VertexDescriptor> {
 public:
  VertexDescriptor();

  virtual ~VertexDescriptor();

  //| Comparable<VertexDescriptor>|
  std::size_t GetHash() const override;

  // |Comparable<VertexDescriptor>|
  bool IsEqual(const VertexDescriptor& other) const override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(VertexDescriptor);
};

}  // namespace impeller
