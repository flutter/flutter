// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

namespace blink {

Paragraph::Paragraph()
{
}

Paragraph::~Paragraph()
{
}

double Paragraph::width()
{
    return 0.0;
}

double Paragraph::height()
{
    return 0.0;
}

double Paragraph::minIntrinsicWidth()
{
    return 0.0;
}

double Paragraph::maxIntrinsicWidth()
{
    return 0.0;
}

double Paragraph::alphabeticBaseline()
{
    return 0.0;
}

double Paragraph::ideographicBaseline()
{
    return 0.0;
}

void Paragraph::layout()
{
}

void Paragraph::paint(Canvas* canvas, const Offset& offset)
{
}

} // namespace blink
