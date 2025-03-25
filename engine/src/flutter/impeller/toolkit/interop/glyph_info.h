// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_GLYPH_INFO_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_GLYPH_INFO_H_

#include "flutter/third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/object.h"

namespace impeller::interop {

//------------------------------------------------------------------------------
/// @brief      Internal C++ peer of ImpellerGlyphInfo. For detailed
///             documentation, refer to the headerdocs in the public API in
///             impeller.h.
///
class GlyphInfo final
    : public Object<GlyphInfo,
                    IMPELLER_INTERNAL_HANDLE_NAME(ImpellerGlyphInfo)> {
 public:
  explicit GlyphInfo(skia::textlayout::Paragraph::GlyphInfo info)
      : info_(info) {}

  ~GlyphInfo();

  GlyphInfo(const GlyphInfo&) = delete;

  GlyphInfo& operator=(const GlyphInfo&) = delete;

  //----------------------------------------------------------------------------
  /// @see      ImpellerGlyphInfoGetGraphemeClusterCodeUnitRangeBegin.
  ///
  size_t GetGraphemeClusterCodeUnitRangeBegin() const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerGlyphInfoGetGraphemeClusterCodeUnitRangeEnd.
  ///
  size_t GetGraphemeClusterCodeUnitRangeEnd() const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerGlyphInfoGetGraphemeClusterBounds.
  ///
  ImpellerRect GetGraphemeClusterBounds() const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerGlyphInfoIsEllipsis.
  ///
  bool IsEllipsis() const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerGlyphInfoGetTextDirection.
  ///
  ImpellerTextDirection GetTextDirection() const;

 private:
  const skia::textlayout::Paragraph::GlyphInfo info_;
};

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_GLYPH_INFO_H_
