// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

namespace blink {

ParagraphBuilder::ParagraphBuilder()
{
}

ParagraphBuilder::~ParagraphBuilder()
{
}

void ParagraphBuilder::pushStyle(TextStyle* style)
{
}

void ParagraphBuilder::pop()
{
}

void ParagraphBuilder::addText(const String& text)
{
}

PassRefPtr<Paragraph> ParagraphBuilder::build(ParagraphStyle* style)
{
    return nullptr;
}

} // namespace blink
