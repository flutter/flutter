// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_

#include <cstdint>

#include "flutter/display_list/geometry/dl_path.h"
#include "fml/status_or.h"
#include "impeller/geometry/rational.h"
#include "impeller/typographer/glyph.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_run.h"

namespace impeller {

using PathCreator = std::function<fml::StatusOr<flutter::DlPath>()>;

//------------------------------------------------------------------------------
/// @brief      Represents a collection of shaped text runs.
///
///             This object is typically the entrypoint in the Impeller type
///             rendering subsystem.
///
/// A text frame should not be reused in multiple places within a single frame,
/// as internally it is used as a cache for various glyph properties.
class TextFrame {
 public:
  TextFrame();

  TextFrame(std::vector<TextRun>& runs,
            Rect bounds,
            bool has_color,
            const PathCreator& path_creator = {});

  ~TextFrame();

  static SubpixelPosition ComputeSubpixelPosition(
      const TextRun::GlyphPosition& glyph_position,
      AxisAlignment alignment,
      const Matrix& transform);

  static Rational RoundScaledFontSize(Scalar scale);
  static Rational RoundScaledFontSize(Rational scale);

  //----------------------------------------------------------------------------
  /// @brief      The conservative bounding box for this text frame.
  ///
  /// @return     The bounds rectangle. If there are no glyphs in this text
  ///             frame and empty Rectangle is returned instead.
  ///
  Rect GetBounds() const;

  //----------------------------------------------------------------------------
  /// @brief      The number of runs in this text frame.
  ///
  /// @return     The run count.
  ///
  size_t GetRunCount() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns a reference to all the text runs in this frame.
  ///
  /// @return     The runs in this frame.
  ///
  const std::vector<TextRun>& GetRuns() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns the paint color this text frame was recorded with.
  ///
  ///             Non-bitmap/COLR fonts always use a black text color here, but
  ///             COLR fonts can potentially use the paint color in the glyph
  ///             atlas, so this color must be considered as part of the cache
  ///             key.
  bool HasColor() const;

  //----------------------------------------------------------------------------
  /// @brief      The type of atlas this run should be place in.
  GlyphAtlas::Type GetAtlasType() const;

  /// @brief If this text frame contains a single glyph (such as for an Icon),
  ///        then return it, otherwise std::nullopt.
  std::optional<Glyph> AsSingleGlyph() const;

  /// @brief Return the font of the first glyph run.
  const Font& GetFont() const;

  // A generation id for the glyph atlas this text run was associated
  // with. As long as the frame generation matches the atlas generation,
  // the contents are guaranteed to be populated and do not need to be
  // processed.
  std::pair<size_t, intptr_t> GetAtlasGenerationAndID() const;

  fml::StatusOr<flutter::DlPath> GetPath() const;

  Matrix GetOffsetTransform() const;

 private:
  friend class TypographerContextSkia;
  friend class LazyGlyphAtlas;
  friend class RenderTextFrame;

  std::optional<GlyphProperties> GetProperties() const;

  void AppendFrameBounds(const FrameBounds& frame_bounds);

  void ClearFrameBounds();

  void SetAtlasGeneration(size_t value, intptr_t atlas_id);

  std::vector<TextRun> runs_;
  Rect bounds_;
  bool has_color_;
  const PathCreator path_creator_;

  size_t generation_ = 0;
  intptr_t atlas_id_ = 0;
};

/// @brief Combine a text frame along with its specific contextual scale,
///        offset, and properties for rendering and hashing in the glyph atlas.
class RenderTextFrame {
 public:
  RenderTextFrame(
      const std::shared_ptr<TextFrame>& frame,
      Rational scale,
      Point offset,
      const Matrix& offset_transform = Matrix(),
      bool render_as_path = false,
      const std::optional<GlyphProperties>& properties = std::nullopt);

  static std::shared_ptr<RenderTextFrame> Make(
      const std::shared_ptr<TextFrame>& frame,
      Rational scale,
      Point offset,
      const Matrix& offset_transform = Matrix(),
      bool render_as_path = false,
      const std::optional<GlyphProperties>& properties = std::nullopt);

  /// The text frame with which the data is associated.
  const std::shared_ptr<TextFrame>& GetFrame() const { return frame_; }

  /// Return the Bounds information from the associated TextFrame.
  Rect GetBounds() const { return frame_->GetBounds(); }

  /// Return the HasColor information from the associated TextFrame.
  bool HasColor() const { return frame_->HasColor(); }

  /// Return the AtlasType information from the associated TextFrame.
  GlyphAtlas::Type GetAtlasType() const { return frame_->GetAtlasType(); }

  /// Return the Run information from the associated TextFrame.
  const std::vector<TextRun>& GetRuns() const { return frame_->GetRuns(); }

  /// Return the Path information from the associated TextFrame.
  fml::StatusOr<flutter::DlPath> GetPath() const { return frame_->GetPath(); }

  /// Set the AtlasGeneration information on the associated TextFrame.
  void SetAtlasGeneration(size_t value, intptr_t atlas_id) {
    frame_->SetAtlasGeneration(value, atlas_id);
  }

  /// The scaled applied within the context that the frame is used.
  Rational GetScale() const { return scale_; }

  /// The location within the context that the frame is used where the
  /// text_frame is located (the x,y of the drawText operation).
  Point GetOffset() const { return offset_; }

  /// The full matrix within the context that the frame is used including
  /// the offset to the text_frame position (offset).
  const Matrix& GetOffsetTransform() const { return offset_transform_; }

  /// True if the combined transform and font size is large enough to
  /// recommend rendering the entire frame as a path for fidelity.
  bool ShouldRenderAsPath() const { return render_as_path_; }

  /// The glyph properties within the context that the frame is used.
  const std::optional<GlyphProperties>& GetProperties() const {
    return properties_;
  }

  /// @brief Verifies that all glyphs in this text frame have computed bounds
  ///        information.
  bool IsFrameComplete() const;

  void AppendFrameBounds(const FrameBounds& frame_bounds) {
    bound_values_.push_back(frame_bounds);
  }

  void ClearFrameBounds() { bound_values_.clear(); }

  /// @brief Retrieve the frame bounds for the glyph at [index].
  ///
  /// This method is only valid if [IsFrameComplete] returns true.
  const FrameBounds& GetFrameBounds(size_t index) const;

  bool operator==(const RenderTextFrame& other) const;

 private:
  const std::shared_ptr<TextFrame> frame_;
  Rational scale_;
  Point offset_;
  Matrix offset_transform_;
  bool render_as_path_;
  std::optional<GlyphProperties> properties_;

  // Data that is cached when rendering the text frame and is only
  // valid for the current atlas generation.
  std::vector<FrameBounds> bound_values_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_TEXT_FRAME_H_
