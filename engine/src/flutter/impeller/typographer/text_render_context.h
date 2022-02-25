// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

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
///             It is caller responsibility to create as few of these and keep
///             these around for as long possible.
///
class TextRenderContext {
 public:
  //----------------------------------------------------------------------------
  /// @brief      Create a new context to render text that talks to an
  ///             underlying graphics context.
  ///
  /// @param[in]  context  The graphics context
  ///
  TextRenderContext(std::shared_ptr<Context> context);

  virtual ~TextRenderContext();

  virtual bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      Get the underlying graphics context.
  ///
  /// @return     The context.
  ///
  const std::shared_ptr<Context>& GetContext() const;

  //----------------------------------------------------------------------------
  /// @brief      Create a new glyph atlas for the specified text frame.
  ///
  /// @param[in]  frame  The text frame
  ///
  /// @return     A valid glyph atlas or null.
  ///
  virtual std::shared_ptr<GlyphAtlas> CreateGlyphAtlas(
      const TextFrame& frame) const = 0;

 private:
  std::shared_ptr<Context> context_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(TextRenderContext);
};

}  // namespace impeller
