// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include "flutter/fml/logging.h"

namespace impeller {

Canvas::Canvas() {
  xformation_stack_.push(Matrix{});
}

Canvas::~Canvas() = default;

void Canvas::Save() {
  FML_DCHECK(xformation_stack_.size() > 0);
  xformation_stack_.push(xformation_stack_.top());
}

bool Canvas::Restore() {
  FML_DCHECK(xformation_stack_.size() > 0);
  if (xformation_stack_.size() == 1) {
    return false;
  }
  xformation_stack_.pop();
  return true;
}

void Canvas::Concat(const Matrix& xformation) {
  xformation_stack_.top() = xformation_stack_.top() * xformation;
}

void Canvas::Translate(const Size& offset) {
  Concat(Matrix::MakeTranslation(offset));
}

void Canvas::Scale(const Size& scale) {
  Concat(Matrix::MakeScale(scale));
}

void Canvas::Rotate(Radians radians) {
  Concat(Matrix::MakeRotationZ(radians));
}

void Canvas::DrawPath(Path path, Paint paint) {}

}  // namespace impeller
