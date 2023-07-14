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
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/vertices_geometry.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/vector.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

class Entity;

struct CanvasStackEntry {
  Matrix xformation;
  // |cull_rect| is conservative screen-space bounds of the clipped output area
  std::optional<Rect> cull_rect;
  size_t stencil_depth = 0u;
  bool is_subpass = false;
  bool contains_clips = false;
};

enum class PointStyle {
  /// @brief Points are drawn as squares.
  kRound,

  /// @brief Points are drawn as circles.
  kSquare,
};

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

  explicit Canvas(Rect cull_rect);

  explicit Canvas(IRect cull_rect);

  ~Canvas();

  void Save();

  void SaveLayer(const Paint& paint,
                 std::optional<Rect> bounds = std::nullopt,
                 const Paint::ImageFilterProc& backdrop_filter = nullptr);

  bool Restore();

  size_t GetSaveCount() const;

  void RestoreToCount(size_t count);

  const Matrix& GetCurrentTransformation() const;

  const std::optional<Rect> GetCurrentLocalCullingBounds() const;

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

  void DrawPoints(std::vector<Point>,
                  Scalar radius,
                  const Paint& paint,
                  PointStyle point_style);

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

  void DrawPicture(const Picture& picture);

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
  std::optional<Rect> initial_cull_rect_;

  void Initialize(std::optional<Rect> cull_rect);

  void Reset();

  EntityPass& GetCurrentPass();

  size_t GetStencilDepth() const;

  void ClipGeometry(std::unique_ptr<Geometry> geometry,
                    Entity::ClipOperation clip_op);

  void IntersectCulling(Rect clip_bounds);
  void SubtractCulling(Rect clip_bounds);

  void Save(bool create_subpass,
            BlendMode = BlendMode::kSourceOver,
            EntityPass::BackdropFilterProc backdrop_filter = nullptr);

  void RestoreClip();

  bool AttemptDrawBlurredRRect(const Rect& rect,
                               Scalar corner_radius,
                               const Paint& paint);

  FML_DISALLOW_COPY_AND_ASSIGN(Canvas);
};

}  // namespace impeller
