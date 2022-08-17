// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"

namespace impeller {

class ColorSourceContents : public Contents {
 public:
  ColorSourceContents();

  ~ColorSourceContents() override;

  void SetPath(Path path);

  void SetMatrix(Matrix matrix);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 protected:
  const Path& GetPath() const;

  const Matrix& GetInverseMatrix() const;

 private:
  Path path_;
  Matrix inverse_matrix_;

  FML_DISALLOW_COPY_AND_ASSIGN(ColorSourceContents);
};

}  // namespace impeller
