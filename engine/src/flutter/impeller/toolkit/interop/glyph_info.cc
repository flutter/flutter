// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/interop/glyph_info.h"

namespace impeller::interop {

GlyphInfo::~GlyphInfo() = default;

size_t GlyphInfo::GetGraphemeClusterCodeUnitRangeBegin() const {
  return info_.fGraphemeClusterTextRange.start;
}

size_t GlyphInfo::GetGraphemeClusterCodeUnitRangeEnd() const {
  return info_.fGraphemeClusterTextRange.end;
}

ImpellerRect GlyphInfo::GetGraphemeClusterBounds() const {
  return ImpellerRect{
      info_.fGraphemeLayoutBounds.y(),
      info_.fGraphemeLayoutBounds.x(),
      info_.fGraphemeLayoutBounds.width(),
      info_.fGraphemeLayoutBounds.height(),
  };
}

bool GlyphInfo::IsEllipsis() const {
  return info_.fIsEllipsis;
}

ImpellerTextDirection GlyphInfo::GetTextDirection() const {
  switch (info_.fDirection) {
    case skia::textlayout::TextDirection::kRtl:
      return kImpellerTextDirectionRTL;
    case skia::textlayout::TextDirection::kLtr:
      return kImpellerTextDirectionLTR;
  }
  return kImpellerTextDirectionLTR;
}

}  // namespace impeller::interop
