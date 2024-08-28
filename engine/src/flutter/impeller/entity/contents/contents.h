// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENTS_H_

#include <functional>
#include <memory>

#include "impeller/core/sampler_descriptor.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/renderer/snapshot.h"
#include "impeller/typographer/lazy_glyph_atlas.h"

namespace impeller {

class ContentContext;
struct ContentContextOptions;
class Entity;
class Surface;
class RenderPass;
class FilterContents;

ContentContextOptions OptionsFromPass(const RenderPass& pass);

ContentContextOptions OptionsFromPassAndEntity(const RenderPass& pass,
                                               const Entity& entity);

class Contents {
 public:
  /// A procedure that filters a given unpremultiplied color to produce a new
  /// unpremultiplied color.
  using ColorFilterProc = std::function<Color(Color)>;

  struct ClipCoverage {
    enum class Type { kNoChange, kAppend, kRestore };

    Type type = Type::kNoChange;
    // TODO(jonahwilliams): this should probably use the Entity::ClipOperation
    // enum, but that has transitive import errors.
    bool is_difference_or_non_square = false;

    /// @brief This coverage is the outer coverage of the clip.
    ///
    /// For example, if the clip is a circular clip, this is the rectangle that
    /// contains the circle and not the rectangle that is contained within the
    /// circle. This means that we cannot use the coverage alone to determine if
    /// a clip can be culled, and instead also use the somewhat hacky
    /// "is_difference_or_non_square" field.
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

  /// @brief  Add any text data to the specified lazy atlas. The scale parameter
  ///         must be used again later when drawing the text.
  virtual void PopulateGlyphAtlas(
      const std::shared_ptr<LazyGlyphAtlas>& lazy_glyph_atlas,
      Scalar scale) {}

  virtual bool Render(const ContentContext& renderer,
                      const Entity& entity,
                      RenderPass& pass) const = 0;

  //----------------------------------------------------------------------------
  /// @brief   Get the area of the render pass that will be affected when this
  ///          contents is rendered.
  ///
  ///          During rendering, coverage coordinates count pixels from the top
  ///          left corner of the framebuffer.
  ///
  /// @return  The coverage rectangle. An `std::nullopt` result means that
  ///          rendering this contents has no effect on the output color.
  ///
  virtual std::optional<Rect> GetCoverage(const Entity& entity) const = 0;

  //----------------------------------------------------------------------------
  /// @brief  Hint that specifies the coverage area of this Contents that will
  ///         actually be used during rendering. This is for optimization
  ///         purposes only and can not be relied on as a clip. May optionally
  ///         affect the result of `GetCoverage()`.
  ///
  void SetCoverageHint(std::optional<Rect> coverage_hint);

  const std::optional<Rect>& GetCoverageHint() const;

  //----------------------------------------------------------------------------
  /// @brief Whether this Contents only emits opaque source colors from the
  ///        fragment stage. This value does not account for any entity
  ///        properties (e.g. the blend mode), clips/visibility culling, or
  ///        inherited opacity.
  ///
  /// @param transform The current transform matrix of the entity that will
  /// render this contents.
  virtual bool IsOpaque(const Matrix& transform) const;

  //----------------------------------------------------------------------------
  /// @brief Given the current pass space bounding rectangle of the clip
  ///        buffer, return the expected clip coverage after this draw call.
  ///        This should only be implemented for contents that may write to the
  ///        clip buffer.
  ///
  ///        During rendering, coverage coordinates count pixels from the top
  ///        left corner of the framebuffer.
  ///
  virtual ClipCoverage GetClipCoverage(
      const Entity& entity,
      const std::optional<Rect>& current_clip_coverage) const;

  //----------------------------------------------------------------------------
  /// @brief Render this contents to a snapshot, respecting the entity's
  ///        transform, path, clip depth, and blend mode.
  ///        The result texture size is always the size of
  ///        `GetCoverage(entity)`.
  ///
  virtual std::optional<Snapshot> RenderToSnapshot(
      const ContentContext& renderer,
      const Entity& entity,
      std::optional<Rect> coverage_limit = std::nullopt,
      const std::optional<SamplerDescriptor>& sampler_descriptor = std::nullopt,
      bool msaa_enabled = true,
      int32_t mip_count = 1,
      const std::string& label = "Snapshot") const;

  virtual bool ShouldRender(const Entity& entity,
                            const std::optional<Rect> clip_coverage) const;

  //----------------------------------------------------------------------------
  /// @brief  Return the color source's intrinsic size, if available.
  ///
  ///         For example, a gradient has a size based on its end and beginning
  ///         points, ignoring any tiling. Solid colors and runtime effects have
  ///         no size.
  ///
  std::optional<Size> GetColorSourceSize() const;

  void SetColorSourceSize(Size size);

  //----------------------------------------------------------------------------
  /// @brief Whether or not this contents can accept the opacity peephole
  ///        optimization.
  ///
  ///        By default all contents return false. Contents are responsible
  ///        for determining whether or not their own geometries intersect in
  ///        a way that makes accepting opacity impossible. It is always safe
  ///        to return false, especially if computing overlap would be
  ///        computationally expensive.
  ///
  virtual bool CanInheritOpacity(const Entity& entity) const;

  //----------------------------------------------------------------------------
  /// @brief Inherit the provided opacity.
  ///
  ///        Use of this method is invalid if CanAcceptOpacity returns false.
  ///
  virtual void SetInheritedOpacity(Scalar opacity);

  //----------------------------------------------------------------------------
  /// @brief Returns a color if this Contents will flood the given `target_size`
  ///        with a color. This output color is the "Source" color that will be
  ///        used for the Entity's blend operation.
  ///
  ///        This is useful for absorbing full screen solid color draws into
  ///        subpass clear colors.
  ///
  virtual std::optional<Color> AsBackgroundColor(const Entity& entity,
                                                 ISize target_size) const;

  //----------------------------------------------------------------------------
  /// @brief Cast to a filter. Returns `nullptr` if this Contents is not a
  ///        filter.
  ///
  virtual const FilterContents* AsFilter() const;

  //----------------------------------------------------------------------------
  /// @brief      If possible, applies a color filter to this contents inputs on
  ///             the CPU.
  ///
  ///             This method will either fully apply the color filter or
  ///             perform no action. Partial/incorrect application of the color
  ///             filter will never occur.
  ///
  /// @param[in]  color_filter_proc  A function that filters a given
  ///                                unpremultiplied color to produce a new
  ///                                unpremultiplied color.
  ///
  /// @return     True if the color filter was able to be fully applied to all
  ///             all relevant inputs. Otherwise, this operation is a no-op and
  ///             false is returned.
  ///
  [[nodiscard]] virtual bool ApplyColorFilter(
      const ColorFilterProc& color_filter_proc);

 private:
  std::optional<Rect> coverage_hint_;
  std::optional<Size> color_source_size_;

  Contents(const Contents&) = delete;

  Contents& operator=(const Contents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CONTENTS_H_
