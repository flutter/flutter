// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXTURE_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXTURE_CONTENTS_H_

#include <memory>

#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"

namespace impeller {

class Texture;

/// Represents the contents of a texture to be rendered.
///
/// This class encapsulates a texture along with parameters defining how it
/// should be drawn, such as the source rectangle within the texture, the
/// destination rectangle on the render target, opacity, and sampler settings.
/// It's used by the rendering system to draw textured quads.
///
/// @see `TiledTextureContents` for a tiled version.
class TextureContents final : public Contents {
 public:
  TextureContents();

  ~TextureContents() override;

  /// A common case factory that marks the texture contents as having a
  /// destination rectangle.
  ///
  /// In this situation, a subpass can be avoided when image filters are
  /// applied.
  ///
  /// @param destination The destination rectangle in the Entity's local
  /// coordinate space.
  static std::shared_ptr<TextureContents> MakeRect(Rect destination);

  /// Sets a debug label for this contents object.
  ///
  /// This label is used for debugging purposes, for example, in graphics
  /// debuggers or logs.
  ///
  /// @param label The debug label string.
  void SetLabel(std::string_view label);

  /// Sets the destination rectangle within the current render target
  /// where the texture will be drawn.
  ///
  /// The texture, potentially clipped by the `source_rect_`, will be mapped to
  /// this rectangle. The coordinates are in the local coordinate space of the
  /// Entity.
  ///
  /// @param rect The destination rectangle in the Entity's local coordinate
  /// space.
  void SetDestinationRect(Rect rect);

  void SetTexture(std::shared_ptr<Texture> texture);

  std::shared_ptr<Texture> GetTexture() const;

  void SetSamplerDescriptor(const SamplerDescriptor& desc);

  const SamplerDescriptor& GetSamplerDescriptor() const;

  /// Sets the source rectangle within the texture to sample from.
  ///
  /// This rectangle defines the portion of the texture that will be mapped to
  /// the `destination_rect_`. The coordinates are in the coordinate space of
  /// the texture (texels), with the top-left corner being (0, 0).
  ///
  /// @param source_rect The rectangle defining the area of the texture to use.
  void SetSourceRect(const Rect& source_rect);

  const Rect& GetSourceRect() const;

  /// Sets whether strict source rect sampling should be used.
  ///
  /// When enabled, the texture coordinates are adjusted slightly (typically by
  /// half a texel) to ensure that linear filtering does not sample pixels
  /// outside the specified `source_rect_`. This is useful for preventing
  /// edge artifacts when rendering sub-sections of a texture atlas.
  ///
  /// @param strict True to enable strict source rect sampling, false otherwise.
  void SetStrictSourceRect(bool strict);

  bool GetStrictSourceRect() const;

  void SetOpacity(Scalar opacity);

  Scalar GetOpacity() const;

  void SetStencilEnabled(bool enabled);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      const SnapshotOptions& options) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

  /// Sets whether applying the opacity should be deferred.
  ///
  /// When true, the opacity value (`GetOpacity()`) might not be applied
  /// directly during rendering operations like `RenderToSnapshot`. Instead, the
  /// opacity might be stored in the resulting `Snapshot` to be applied later
  /// when the snapshot is drawn. This is typically used as an optimization when
  /// the texture covers its destination rectangle completely and has near-full
  /// opacity, allowing the original texture to be used directly in the
  /// snapshot.
  ///
  /// @param defer_applying_opacity True to defer applying opacity, false to
  ///        apply it during rendering.
  void SetDeferApplyingOpacity(bool defer_applying_opacity);

 private:
  std::string label_;

  Rect destination_rect_;
  bool stencil_enabled_ = true;

  std::shared_ptr<Texture> texture_;
  SamplerDescriptor sampler_descriptor_ = {};
  Rect source_rect_;
  bool strict_source_rect_enabled_ = false;
  Scalar opacity_ = 1.0f;
  Scalar inherited_opacity_ = 1.0f;
  bool defer_applying_opacity_ = false;

  TextureContents(const TextureContents&) = delete;

  TextureContents& operator=(const TextureContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEXTURE_CONTENTS_H_
