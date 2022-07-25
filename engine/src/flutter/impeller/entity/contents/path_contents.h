// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/path.h"

namespace impeller {

class PathContents : public Contents {
 public:
  PathContents();

  ~PathContents() override;

  virtual void SetPath(Path path) = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(PathContents);
};

}  // namespace impeller
