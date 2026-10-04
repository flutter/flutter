// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "paragraph_builder.h"

#include "flutter/txt/src/skia/paragraph_builder_skia.h"
#include "paragraph_style.h"
#include "third_party/icu/source/common/unicode/unistr.h"

namespace txt {

//------------------------------------------------------------------------------
/// @brief      Creates a |ParagraphBuilder| based on Skia's text layout module.
///
/// @param[in]  style             The style to use for the paragraph.
/// @param[in]  font_collection   The font collection to use for the paragraph.
/// @param[in]  impeller_enabled  Whether Impeller is enabled in the runtime.
std::unique_ptr<ParagraphBuilder> ParagraphBuilder::CreateSkiaBuilder(
    const ParagraphStyle& style,
    const std::shared_ptr<FontCollection>& font_collection,
    const bool impeller_enabled) {
  return std::make_unique<ParagraphBuilderSkia>(style, font_collection,
                                                impeller_enabled);
}

}  // namespace txt
