/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/core/rendering/TextRunConstructor.h"

#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/platform/text/BidiTextRun.h"

namespace blink {

template <typename CharacterType>
static inline TextRun constructTextRunInternal(
    RenderObject* context,
    const Font& font,
    const CharacterType* characters,
    int length,
    RenderStyle* style,
    TextDirection direction,
    TextRun::ExpansionBehavior expansion) {
  ASSERT(style);

  bool directionalOverride = style->rtlOrdering() == VisualOrder;
  return TextRun(characters, length, 0, 0, expansion, direction,
                 directionalOverride);
}

template <typename CharacterType>
static inline TextRun constructTextRunInternal(
    RenderObject* context,
    const Font& font,
    const CharacterType* characters,
    int length,
    RenderStyle* style,
    TextDirection direction,
    TextRun::ExpansionBehavior expansion,
    TextRunFlags flags) {
  ASSERT(style);

  TextDirection textDirection = direction;
  bool directionalOverride = style->rtlOrdering() == VisualOrder;
  if (flags != DefaultTextRunFlags) {
    if (flags & RespectDirection)
      textDirection = style->direction();
    if (flags & RespectDirectionOverride)
      directionalOverride |= isOverride(style->unicodeBidi());
  }

  return TextRun(characters, length, 0, 0, expansion, textDirection,
                 directionalOverride);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const LChar* characters,
                         int length,
                         RenderStyle* style,
                         TextDirection direction,
                         TextRun::ExpansionBehavior expansion) {
  return constructTextRunInternal(context, font, characters, length, style,
                                  direction, expansion);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const UChar* characters,
                         int length,
                         RenderStyle* style,
                         TextDirection direction,
                         TextRun::ExpansionBehavior expansion) {
  return constructTextRunInternal(context, font, characters, length, style,
                                  direction, expansion);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const RenderText* text,
                         RenderStyle* style,
                         TextDirection direction,
                         TextRun::ExpansionBehavior expansion) {
  if (text->is8Bit())
    return constructTextRunInternal(context, font, text->characters8(),
                                    text->textLength(), style, direction,
                                    expansion);
  return constructTextRunInternal(context, font, text->characters16(),
                                  text->textLength(), style, direction,
                                  expansion);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const RenderText* text,
                         unsigned offset,
                         unsigned length,
                         RenderStyle* style,
                         TextDirection direction,
                         TextRun::ExpansionBehavior expansion) {
  ASSERT(offset + length <= text->textLength());
  if (text->is8Bit())
    return constructTextRunInternal(context, font, text->characters8() + offset,
                                    length, style, direction, expansion);
  return constructTextRunInternal(context, font, text->characters16() + offset,
                                  length, style, direction, expansion);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const String& string,
                         RenderStyle* style,
                         TextDirection direction,
                         TextRun::ExpansionBehavior expansion,
                         TextRunFlags flags) {
  unsigned length = string.length();
  if (!length)
    return constructTextRunInternal(context, font, static_cast<const LChar*>(0),
                                    length, style, direction, expansion, flags);
  if (string.is8Bit())
    return constructTextRunInternal(context, font, string.characters8(), length,
                                    style, direction, expansion, flags);
  return constructTextRunInternal(context, font, string.characters16(), length,
                                  style, direction, expansion, flags);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const String& string,
                         RenderStyle* style,
                         TextRun::ExpansionBehavior expansion,
                         TextRunFlags flags) {
  bool hasStrongDirectionality;
  return constructTextRun(
      context, font, string, style,
      determineDirectionality(string, hasStrongDirectionality), expansion,
      flags);
}

TextRun constructTextRun(RenderObject* context,
                         const Font& font,
                         const RenderText* text,
                         unsigned offset,
                         unsigned length,
                         RenderStyle* style,
                         TextRun::ExpansionBehavior expansion) {
  ASSERT(offset + length <= text->textLength());
  TextRun run = text->is8Bit()
                    ? constructTextRunInternal(context, font,
                                               text->characters8() + offset,
                                               length, style, LTR, expansion)
                    : constructTextRunInternal(context, font,
                                               text->characters16() + offset,
                                               length, style, LTR, expansion);
  bool hasStrongDirectionality;
  run.setDirection(directionForRun(run, hasStrongDirectionality));
  return run;
}

}  // namespace blink
