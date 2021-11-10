// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/rect.h"
#include "impeller/image/decompressed_image.h"

namespace impeller {

class Entity {
 public:
  Entity();

  ~Entity();

  const Matrix& GetTransformation() const;

  void SetTransformation(const Matrix& transformation);

  const Color& GetBackgroundColor() const;

  void SetBackgroundColor(const Color& backgroundColor);

  const Color& GetStrokeColor() const;

  void SetStrokeColor(const Color& strokeColor);

  double GetStrokeSize() const;

  void SetStrokeSize(double strokeSize);

  const Path& GetPath() const;

  void SetPath(Path path);

  void SetIsClip(bool is_clip);

  bool IsClip() const;

  void SetContents(std::shared_ptr<Contents> contents);

  const std::shared_ptr<Contents>& GetContents() const;

 private:
  Matrix transformation_;
  Color background_color_;
  std::shared_ptr<Contents> contents_;

  Path path_;
  Color stroke_color_;
  double stroke_size_ = 1.0;
  bool is_clip_ = false;
};

}  // namespace impeller
