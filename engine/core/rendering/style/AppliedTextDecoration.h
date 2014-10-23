// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AppliedTextDecoration_h
#define AppliedTextDecoration_h

#include "core/css/StyleColor.h"
#include "core/rendering/style/RenderStyleConstants.h"

namespace blink {

class AppliedTextDecoration {
public:
    AppliedTextDecoration(TextDecoration, TextDecorationStyle, StyleColor);
    explicit AppliedTextDecoration(TextDecoration);
    AppliedTextDecoration();

    TextDecoration line() const { return static_cast<TextDecoration>(m_line); }
    TextDecorationStyle style() const { return static_cast<TextDecorationStyle>(m_style); }

    bool isSimpleUnderline() const { return m_line == TextDecorationUnderline && m_style == TextDecorationStyleSolid && m_color.isCurrentColor(); }
    bool operator==(const AppliedTextDecoration&) const;
    bool operator!=(const AppliedTextDecoration& o) const { return !(*this == o); }

private:
    unsigned m_line : TextDecorationBits;
    unsigned m_style : 3; // TextDecorationStyle
    StyleColor m_color;
};

} // namespace blink

#endif // AppliedTextDecoration_h
