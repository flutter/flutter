// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_

#include <memory>

#include "impeller/core/sampler_descriptor.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/color.h"

namespace impeller {

// Interface wrapper to allow usage of DL pointer data without copying (or
// circular imports).
class AtlasGeometry {
 public:
  virtual bool ShouldUseBlend() const = 0;

  virtual bool ShouldSkip() const = 0;

  virtual VertexBuffer CreateSimpleVertexBuffer(
      HostBuffer& host_buffer) const = 0;

  virtual VertexBuffer CreateBlendVertexBuffer(
      HostBuffer& host_buffer) const = 0;

  virtual Rect ComputeBoundingBox() const = 0;

  virtual const std::shared_ptr<Texture>& GetAtlas() const = 0;

  virtual const SamplerDescriptor& GetSamplerDescriptor() const = 0;

  virtual BlendMode GetBlendMode() const = 0;

  virtual bool ShouldInvertBlendMode() const { return true; }
};

/// @brief An atlas geometry that adapts for drawImageRect.
class DrawImageRectAtlasGeometry : public AtlasGeometry {
 public:
  DrawImageRectAtlasGeometry(std::shared_ptr<Texture> texture,
                             const Rect& source,
                             const Rect& destination,
                             const Color& color,
                             BlendMode blend_mode,
                             const SamplerDescriptor& desc);

  ~DrawImageRectAtlasGeometry();

  bool ShouldUseBlend() const override;

  bool ShouldSkip() const override;

  VertexBuffer CreateSimpleVertexBuffer(HostBuffer& host_buffer) const override;

  VertexBuffer CreateBlendVertexBuffer(HostBuffer& host_buffer) const override;

  Rect ComputeBoundingBox() const override;

  const std::shared_ptr<Texture>& GetAtlas() const override;

  const SamplerDescriptor& GetSamplerDescriptor() const override;

  BlendMode GetBlendMode() const override;

  bool ShouldInvertBlendMode() const override;

 private:
  const std::shared_ptr<Texture> texture_;
  const Rect source_;
  const Rect destination_;
  const Color color_;
  const BlendMode blend_mode_;
  const SamplerDescriptor desc_;
};

class AtlasContents final : public Contents {
 public:
  explicit AtlasContents();

  ~AtlasContents() override;

  void SetGeometry(AtlasGeometry* geometry);

  void SetAlpha(Scalar alpha);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  AtlasGeometry* geometry_ = nullptr;
  Scalar alpha_ = 1.0;

  AtlasContents(const AtlasContents&) = delete;

  AtlasContents& operator=(const AtlasContents&) = delete;
};

/// A specialized atlas class for applying a color matrix filter to a
/// drawImageRect call.
class ColorFilterAtlasContents final : public Contents {
 public:
  explicit ColorFilterAtlasContents();

  ~ColorFilterAtlasContents() override;

  void SetGeometry(AtlasGeometry* geometry);

  void SetAlpha(Scalar alpha);

  void SetMatrix(ColorMatrix matrix);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  // These contents are created temporarily on the stack and never stored.
  // The referenced geometry is also stack allocated and will be de-allocated
  // after the contents are.
  AtlasGeometry* geometry_ = nullptr;
  ColorMatrix matrix_;
  Scalar alpha_ = 1.0;

  ColorFilterAtlasContents(const ColorFilterAtlasContents&) = delete;

  ColorFilterAtlasContents& operator=(const ColorFilterAtlasContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_ATLAS_CONTENTS_H_
