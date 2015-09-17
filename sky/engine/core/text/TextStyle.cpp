// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/TextStyle.h"

namespace blink {

TextStyle::TextStyle(
    SkColor color,
    const String& fontFamily,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    const Vector<TextDecoration>& decoration,
    SkColor decorationColor,
    TextDecorationStyle decorationStyle)
    : m_color(color)
    , m_fontFamily(fontFamily)
    , m_fontSize(fontSize)
    , m_fontWeight(fontWeight)
    , m_fontStyle(fontStyle)
    , m_decoration(TextDecorationNone)
    , m_decorationColor(decorationColor)
    , m_decorationStyle(decorationStyle)
{
    for (const auto& d : decoration)
        m_decoration |= d;
}

TextStyle::~TextStyle()
{
}

} // namespace blink
