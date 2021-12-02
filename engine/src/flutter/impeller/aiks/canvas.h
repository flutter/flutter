// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <deque>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/aiks/image.h"
#include "impeller/aiks/paint.h"
#include "impeller/aiks/picture.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"

namespace impeller {

class Entity;

class Canvas {
 public:
  Canvas();

  ~Canvas();

  void Save();

  void SaveLayer(Paint paint, std::optional<Rect> bounds = std::nullopt);

  bool Restore();

  size_t GetSaveCount() const;

  void RestoreToCount(size_t count);

  const Matrix& GetCurrentTransformation() const;

  void Concat(const Matrix& xformation);

  void Translate(const Vector3& offset);

  void Scale(const Vector3& scale);

  void Skew(Scalar sx, Scalar sy);

  void Rotate(Radians radians);

  void DrawPath(Path path, Paint paint);

  void DrawRect(Rect rect, Paint paint);

  void DrawCircle(Point center, Scalar radius, Paint paint);

  void DrawImage(std::shared_ptr<Image> image, Point offset, Paint paint);

  void DrawImageRect(std::shared_ptr<Image> image,
                     IRect source,
                     Rect dest,
                     Paint paint);

  void ClipPath(Path path);

  void DrawShadow(Path path, Color color, Scalar elevation);

  void DrawPicture(Picture picture);

  Picture EndRecordingAsPicture();

 private:
  std::unique_ptr<EntityPass> base_pass_;
  EntityPass* current_pass_ = nullptr;
  std::deque<CanvasStackEntry> xformation_stack_;

  void Initialize();

  void Reset();

  EntityPass& GetCurrentPass();

  void IncrementStencilDepth();

  size_t GetStencilDepth() const;

  void Save(bool create_subpass);

  FML_DISALLOW_COPY_AND_ASSIGN(Canvas);
};

}  // namespace impeller
