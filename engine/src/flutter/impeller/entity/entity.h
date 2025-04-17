// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_ENTITY_H_
#define FLUTTER_IMPELLER_ENTITY_ENTITY_H_

#include <cstdint>

#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class Renderer;
class RenderPass;

/// Represents a renderable object within the Impeller scene.
///
/// An Entity combines graphical content (`Contents`) with properties
/// like transformation (`Matrix`), blend mode (`BlendMode`), and stencil
/// clip depth. It serves as the primary unit for constructing and rendering
/// scenes. Entities can be created directly or from `Snapshot` objects.
class Entity {
 public:
  static constexpr BlendMode kLastPipelineBlendMode = BlendMode::kModulate;
  static constexpr BlendMode kLastAdvancedBlendMode = BlendMode::kLuminosity;

  static constexpr Scalar kDepthEpsilon = 1.0f / 262144.0;

  enum class RenderingMode {
    /// In direct mode, the Entity's transform is used as the current
    /// local-to-screen transform matrix.
    kDirect,
    /// In subpass mode, the Entity passed through the filter is in screen space
    /// rather than local space, and so some filters (namely,
    /// MatrixFilterContents) need to interpret the given EffectTransform as the
    /// current transform matrix.
    kSubpassAppendSnapshotTransform,
    kSubpassPrependSnapshotTransform,
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
  static Entity FromSnapshot(const Snapshot& snapshot,
                             BlendMode blend_mode = BlendMode::kSrcOver);

  Entity();

  ~Entity();

  Entity(Entity&&);

  Entity& operator=(Entity&&);

  /// @brief  Get the global transform matrix for this Entity.
  const Matrix& GetTransform() const;

  /// Calculates the final transformation matrix for rendering in a shader.
  ///
  /// This combines the entity's transform with the render pass's orthographic
  /// projection and applies the necessary adjustments based on the entity's
  /// shader clip depth.
  ///
  /// @param[in] pass The current render pass.
  /// @return The combined model-view-projection matrix for the shader.
  Matrix GetShaderTransform(const RenderPass& pass) const;

  /// @brief  Static utility that computes the vertex shader transform used for
  ///         drawing an Entity with a given the clip depth and RenderPass size.
  static Matrix GetShaderTransform(Scalar clip_depth,
                                   const RenderPass& pass,
                                   const Matrix& transform);

  /// @brief  Set the global transform matrix for this Entity.
  void SetTransform(const Matrix& transform);

  /// Calculates the axis-aligned bounding box covering this entity after its
  /// transformation is applied.
  /// @return The coverage rectangle in the parent coordinate space, or
  /// `std::nullopt` if the entity has no contents.
  std::optional<Rect> GetCoverage() const;

  void SetContents(std::shared_ptr<Contents> contents);

  const std::shared_ptr<Contents>& GetContents() const;

  /// Sets the stencil clip depth for this entity.
  ///
  /// The clip depth determines the entity's level within a stack of stencil
  /// clips. Higher values indicate the entity is nested deeper within clips.
  /// This value is used during rendering to configure stencil buffer
  /// operations.
  ///
  /// @param[in] clip_depth The integer clip depth level.
  void SetClipDepth(uint32_t clip_depth);

  /// Gets the stencil clip depth level for this entity.
  ///
  /// @see SetClipDepth(uint32_t)
  /// @see GetShaderClipDepth()
  ///
  /// @return The current integer clip depth level.
  uint32_t GetClipDepth() const;

  /// Gets the shader-compatible depth value based on the entity's current clip
  /// depth level (`clip_depth_`).
  ///
  /// @see GetShaderClipDepth(uint32_t) for details on the conversion logic.
  ///
  /// @return The floating-point depth value for shaders corresponding to the
  /// entity's `clip_depth_`.
  float GetShaderClipDepth() const;

  /// Converts an integer clip depth level into a floating-point depth value
  /// suitable for use in shaders.
  ///
  /// The integer `clip_depth` represents discrete layers used for stencil
  /// clipping. This function maps that integer to a depth value within the [0,
  /// 1) range for the depth buffer. Each increment in `clip_depth` corresponds
  /// to a small step (`kDepthEpsilon`) in the shader depth.
  ///
  /// The result is clamped to ensure it stays within the valid depth range and
  /// slightly below 1.0 to avoid potential issues with the maximum depth value.
  ///
  /// @param[in] clip_depth The integer clip depth level.
  /// @return The corresponding floating-point depth value for shaders.
  static float GetShaderClipDepth(uint32_t clip_depth);

  void SetBlendMode(BlendMode blend_mode);

  BlendMode GetBlendMode() const;

  bool Render(const ContentContext& renderer, RenderPass& parent_pass) const;

  static bool IsBlendModeDestructive(BlendMode blend_mode);

  bool SetInheritedOpacity(Scalar alpha);

  /// Attempts to represent this entity as a solid background color.
  ///
  /// This is an optimization. If the entity's contents can be represented as a
  /// solid color covering the entire target area, this method returns that
  /// color.
  ///
  /// @param[in] target_size The size of the render target.
  /// @return The background color if representable, otherwise `std::nullopt`.
  std::optional<Color> AsBackgroundColor(ISize target_size) const;

  Entity Clone() const;

 private:
  Entity(const Entity&);

  Matrix transform_;
  std::shared_ptr<Contents> contents_;
  BlendMode blend_mode_ = BlendMode::kSrcOver;
  uint32_t clip_depth_ = 1u;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_ENTITY_H_
