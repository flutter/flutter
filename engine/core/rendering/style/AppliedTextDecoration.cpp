// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/rendering/style/AppliedTextDecoration.h"

namespace blink {

AppliedTextDecoration::AppliedTextDecoration(TextDecoration line, TextDecorationStyle style, StyleColor color)
    : m_line(line)
    , m_style(style)
    , m_color(color)
{
}

AppliedTextDecoration::AppliedTextDecoration(TextDecoration line)
    : m_line(line)
    , m_style(TextDecorationStyleSolid)
    , m_color(StyleColor::currentColor())
{
}

AppliedTextDecoration::AppliedTextDecoration()
    : m_line(TextDecorationUnderline)
    , m_style(TextDecorationStyleSolid)
    , m_color(StyleColor::currentColor())
{
}

bool AppliedTextDecoration::operator==(const AppliedTextDecoration& o) const
{
    return m_color == o.m_color && m_line == o.m_line && m_style == o.m_style;
}

} // namespace blink
