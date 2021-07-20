// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"

#include "impeller/geometry/color.h"

namespace impeller {

class Paint {
 public:
  Paint();

  ~Paint();

  void SetColor(Color color);

 private:
  Color color_;

  FML_DISALLOW_COPY_AND_ASSIGN(Paint);
};

}  // namespace impeller
