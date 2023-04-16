// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <deque>
#include <functional>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/aiks/image.h"
#include "impeller/aiks/paint.h"
#include "impeller/aiks/picture.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/entity/geometry.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class Entity;

class Canvas {
 public:
  struct DebugOptions {
    /// When enabled, layers that are rendered to an offscreen texture
    /// internally get a translucent checkerboard pattern painted over them.
    ///
    /// Requires the `IMPELLER_DEBUG` preprocessor flag.
    bool offscreen_texture_checkerboard = false;
  } debug_options;

  Canvas();

  ~Canvas();

  void Save();

  void SaveLayer(const Paint& paint,
                 std::optional<Rect> bounds = std::nullopt,
                 const std::optional<Paint::ImageFilterProc>& backdrop_filter =
                     std::nullopt);

  bool Restore();

  size_t GetSaveCount() const;

  void RestoreToCount(size_t count);

  const Matrix& GetCurrentTransformation() const;

  void ResetTransform();

  void Transform(const Matrix& xformation);

  void Concat(const Matrix& xformation);

  void PreConcat(const Matrix& xformation);

  void Translate(const Vector3& offset);

  void Scale(const Vector2& scale);

  void Scale(const Vector3& scale);

  void Skew(Scalar sx, Scalar sy);

  void Rotate(Radians radians);

  void DrawPath(const Path& path, const Paint& paint);

  void DrawPaint(const Paint& paint);

  void DrawRect(Rect rect, const Paint& paint);

  void DrawRRect(Rect rect, Scalar corner_radius, const Paint& paint);

  void DrawCircle(Point center, Scalar radius, const Paint& paint);

  void DrawImage(const std::shared_ptr<Image>& image,
                 Point offset,
                 const Paint& paint,
                 SamplerDescriptor sampler = {});

  void DrawImageRect(const std::shared_ptr<Image>& image,
                     Rect source,
                     Rect dest,
                     const Paint& paint,
                     SamplerDescriptor sampler = {});

  void ClipPath(
      const Path& path,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect);

  void ClipRect(
      const Rect& rect,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect);

  void ClipRRect(
      const Rect& rect,
      Scalar corner_radius,
      Entity::ClipOperation clip_op = Entity::ClipOperation::kIntersect);

  void DrawPicture(Picture picture);

  void DrawTextFrame(const TextFrame& text_frame,
                     Point position,
                     const Paint& paint);

  void DrawVertices(const std::shared_ptr<VerticesGeometry>& vertices,
                    BlendMode blend_mode,
                    const Paint& paint);

  void DrawAtlas(const std::shared_ptr<Image>& atlas,
                 std::vector<Matrix> transforms,
                 std::vector<Rect> texture_coordinates,
                 std::vector<Color> colors,
                 BlendMode blend_mode,
                 SamplerDescriptor sampler,
                 std::optional<Rect> cull_rect,
                 const Paint& paint);

  Picture EndRecordingAsPicture();

 private:
  std::unique_ptr<EntityPass> base_pass_;
  EntityPass* current_pass_ = nullptr;
  std::deque<CanvasStackEntry> xformation_stack_;
  std::shared_ptr<LazyGlyphAtlas> lazy_glyph_atlas_;

  void Initialize();

  void Reset();

  EntityPass& GetCurrentPass();

  size_t GetStencilDepth() const;

  void ClipGeometry(std::unique_ptr<Geometry> geometry,
                    Entity::ClipOperation clip_op);

  void Save(bool create_subpass,
            BlendMode = BlendMode::kSourceOver,
            std::optional<EntityPass::BackdropFilterProc> backdrop_filter =
                std::nullopt);

  void RestoreClip();

  bool AttemptDrawBlurredRRect(const Rect& rect,
                               Scalar corner_radius,
                               const Paint& paint);

  FML_DISALLOW_COPY_AND_ASSIGN(Canvas);
};

}  // namespace impeller
