// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/context.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The graphics context necessary to render text.
///
///             This is necessary to create and reference resources related to
///             rendering text on the GPU.
///
///
class TextRenderContext {
 public:
  static std::unique_ptr<TextRenderContext> Create(
      std::shared_ptr<Context> context);

  virtual ~TextRenderContext();

  virtual bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the underlying graphics context.
  ///
  /// @return     The context.
  ///
  const std::shared_ptr<Context>& GetContext() const;

  using FrameIterator = std::function<const TextFrame*(void)>;

  // TODO(dnfield): Callers should not need to know which type of atlas to
  // create. https://github.com/flutter/flutter/issues/111640

  virtual std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const std::shared_ptr<const Capabilities>& capabilities,
      FrameIterator iterator) const = 0;

  std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      GlyphAtlas::Type type,
      std::shared_ptr<GlyphAtlasContext> atlas_context,
      const std::shared_ptr<const Capabilities>& capabilities,
      const TextFrame& frame) const;

 protected:
  //----------------------------------------------------------------------------
  /// @brief      Create a new context to render text that talks to an
  ///             underlying graphics context.
  ///
  /// @param[in]  context  The graphics context
  ///
  TextRenderContext(std::shared_ptr<Context> context);

 private:
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TextRenderContext);
};

}  // namespace impeller
