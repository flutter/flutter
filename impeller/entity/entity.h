// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>

#include "impeller/core/capture.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class Renderer;
class RenderPass;

class Entity {
 public:
  static constexpr BlendMode kLastPipelineBlendMode = BlendMode::kModulate;
  static constexpr BlendMode kLastAdvancedBlendMode = BlendMode::kLuminosity;

  enum class RenderingMode {
    /// In direct mode, the Entity's transform is used as the current
    /// local-to-screen transformation matrix.
    kDirect,
    /// In subpass mode, the Entity passed through the filter is in screen space
    /// rather than local space, and so some filters (namely,
    /// MatrixFilterContents) need to interpret the given EffectTransform as the
    /// current transformation matrix.
    kSubpass,
  };

  /// An enum to define how to repeat, fold, or omit colors outside of the
  /// typically defined range of the source of the colors (such as the
  /// bounds of an image or the defining geometry of a gradient).
  enum class TileMode {
    /// Replicate the edge color if the shader draws outside of its original
    /// bounds.
    kClamp,

    /// Repeat the shader's image horizontally and vertically (or both along and
    /// perpendicular to a gradient's geometry).
    kRepeat,

    /// Repeat the shader's image horizontally and vertically, seamlessly
    /// alternating mirrored images.
    kMirror,

    /// Render the shader's image pixels only within its original bounds. If the
    /// shader draws outside of its original bounds, transparent black is drawn
    /// instead.
    kDecal,
  };

  enum class ClipOperation {
    kDifference,
    kIntersect,
  };

  /// @brief  Create an entity that can be used to render a given snapshot.
  static std::optional<Entity> FromSnapshot(
      const std::optional<Snapshot>& snapshot,
      BlendMode blend_mode = BlendMode::kSourceOver,
      uint32_t clip_depth = 0);

  Entity();

  ~Entity();

  /// @brief  Get the global transformation matrix for this Entity.
  const Matrix& GetTransformation() const;

  /// @brief  Set the global transformation matrix for this Entity.
  void SetTransformation(const Matrix& transformation);

  std::optional<Rect> GetCoverage() const;

  Contents::ClipCoverage GetClipCoverage(
      const std::optional<Rect>& current_clip_coverage) const;

  bool ShouldRender(const std::optional<Rect>& clip_coverage) const;

  void SetContents(std::shared_ptr<Contents> contents);

  const std::shared_ptr<Contents>& GetContents() const;

  void SetClipDepth(uint32_t clip_depth);

  void IncrementStencilDepth(uint32_t increment);

  uint32_t GetClipDepth() const;

  void SetBlendMode(BlendMode blend_mode);

  BlendMode GetBlendMode() const;

  bool Render(const ContentContext& renderer, RenderPass& parent_pass) const;

  static bool IsBlendModeDestructive(BlendMode blend_mode);

  bool CanInheritOpacity() const;

  bool SetInheritedOpacity(Scalar alpha);

  std::optional<Color> AsBackgroundColor(ISize target_size) const;

  Scalar DeriveTextScale() const;

  Capture& GetCapture() const;

  void SetCapture(Capture capture) const;

 private:
  Matrix transformation_;
  std::shared_ptr<Contents> contents_;
  BlendMode blend_mode_ = BlendMode::kSourceOver;
  uint32_t clip_depth_ = 0u;
  mutable Capture capture_;
};

}  // namespace impeller
