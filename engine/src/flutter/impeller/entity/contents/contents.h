// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/snapshot.h"

namespace impeller {

class ContentContext;
struct ContentContextOptions;
class Entity;
class Surface;
class RenderPass;

ContentContextOptions OptionsFromPass(const RenderPass& pass);

ContentContextOptions OptionsFromPassAndEntity(const RenderPass& pass,
                                               const Entity& entity);

class Contents {
 public:
  struct StencilCoverage {
    enum class Type { kNoChange, kAppend, kRestore };

    Type type = Type::kNoChange;
    std::optional<Rect> coverage = std::nullopt;
  };

  using RenderProc = std::function<bool(const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass)>;
  using CoverageProc = std::function<std::optional<Rect>(const Entity& entity)>;

  static std::shared_ptr<Contents> MakeAnonymous(RenderProc render_proc,
                                                 CoverageProc coverage_proc);

  Contents();

  virtual ~Contents();

  virtual bool Render(const ContentContext& renderer,
                      const Entity& entity,
                      RenderPass& pass) const = 0;

  /// @brief Get the screen space bounding rectangle that this contents affects.
  virtual std::optional<Rect> GetCoverage(const Entity& entity) const = 0;

  /// @brief Whether this Contents only emits opaque source colors from the
  ///        fragment stage. This value does not account for any entity
  ///        properties (e.g. the blend mode), clips/visibility culling, or
  ///        inherited opacity.
  virtual bool IsOpaque() const;

  /// @brief Given the current screen space bounding rectangle of the stencil,
  ///        return the expected stencil coverage after this draw call. This
  ///        should only be implemented for contents that may write to the
  ///        stencil buffer.
  virtual StencilCoverage GetStencilCoverage(
      const Entity& entity,
      const std::optional<Rect>& current_stencil_coverage) const;

  /// @brief Render this contents to a snapshot, respecting the entity's
  ///        transform, path, stencil depth, and blend mode.
  ///        The result texture size is always the size of
  ///        `GetCoverage(entity)`.
  virtual std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      std::optional<Rect> coverage_limit = std::nullopt,
      const std::optional<SamplerDescriptor>& sampler_descriptor = std::nullopt,
      bool msaa_enabled = true,
      const std::string& label = "Snapshot") const;

  virtual bool ShouldRender(const Entity& entity,
                            const std::optional<Rect>& stencil_coverage) const;

  /// @brief  Return the color source's intrinsic size, if available.
  ///
  ///         For example, a gradient has a size based on its end and beginning
  ///         points, ignoring any tiling. Solid colors and runtime effects have
  ///         no size.
  std::optional<Size> GetColorSourceSize() const;

  void SetColorSourceSize(Size size);

  /// @brief Whether or not this contents can accept the opacity peephole
  ///        optimization.
  ///
  ///        By default all contents return false. Contents are responsible
  ///        for determining whether or not their own geometries intersect in
  ///        a way that makes accepting opacity impossible. It is always safe
  ///        to return false, especially if computing overlap would be
  ///        computationally expensive.
  virtual bool CanInheritOpacity(const Entity& entity) const;

  /// @brief Inherit the provided opacity.
  ///
  ///        Use of this method is invalid if CanAcceptOpacity returns false.
  virtual void SetInheritedOpacity(Scalar opacity);

 private:
  std::optional<Size> color_source_size_;

  FML_DISALLOW_COPY_AND_ASSIGN(Contents);
};

}  // namespace impeller
