// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <stack>

#include "flutter/fml/macros.h"
#include "impeller/aiks/paint.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"

namespace impeller {

class Canvas {
 public:
  Canvas();

  ~Canvas();

  void Save();

  bool Restore();

  size_t GetSaveCount() const;

  void Concat(const Matrix& xformation);

  void Translate(const Size& offset);

  void Scale(const Size& scale);

  void Rotate(Radians radians);

  void DrawPath(Path path, Paint paint);

 private:
  std::stack<Matrix> xformation_stack_;

  FML_DISALLOW_COPY_AND_ASSIGN(Canvas);
};

}  // namespace impeller
