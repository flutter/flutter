/*
 * Copyright (C) 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2012 Rik Cabanier (cabanier@adobe.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/GraphicsTypes.h"

#include "wtf/Assertions.h"
#include "wtf/text/WTFString.h"

namespace blink {

static const char* const compositeOperatorNames[] = {
    "clear",
    "copy",
    "source-over",
    "source-in",
    "source-out",
    "source-atop",
    "destination-over",
    "destination-in",
    "destination-out",
    "destination-atop",
    "xor",
    "darker",
    "lighter"
};

static const char* const blendOperatorNames[] = {
    "multiply",
    "screen",
    "overlay",
    "darken",
    "lighten",
    "color-dodge",
    "color-burn",
    "hard-light",
    "soft-light",
    "difference",
    "exclusion",
    "hue",
    "saturation",
    "color",
    "luminosity"
};
const int numCompositeOperatorNames = WTF_ARRAY_LENGTH(compositeOperatorNames);
const int numBlendOperatorNames = WTF_ARRAY_LENGTH(blendOperatorNames);

bool parseCompositeAndBlendOperator(const String& s, CompositeOperator& op, WebBlendMode& blendOp)
{
    for (int i = 0; i < numCompositeOperatorNames; i++) {
        if (s == compositeOperatorNames[i]) {
            op = static_cast<CompositeOperator>(i);
            blendOp = WebBlendModeNormal;
            return true;
        }
    }

    for (int i = 0; i < numBlendOperatorNames; i++) {
        if (s == blendOperatorNames[i]) {
            blendOp = static_cast<WebBlendMode>(i+1);
            // For now, blending will always assume source-over. This will be fixed in the future
            op = CompositeSourceOver;
            return true;
        }
    }

    return false;
}

// FIXME: when we support blend modes in combination with compositing other than source-over
// this routine needs to be updated.
String compositeOperatorName(CompositeOperator op, WebBlendMode blendOp)
{
    ASSERT(op >= 0);
    ASSERT(op < numCompositeOperatorNames);
    ASSERT(blendOp >= 0);
    ASSERT(blendOp <= numBlendOperatorNames);
    if (blendOp != WebBlendModeNormal)
        return blendOperatorNames[blendOp-1];
    return compositeOperatorNames[op];
}

bool parseLineCap(const String& s, LineCap& cap)
{
    if (s == "butt") {
        cap = ButtCap;
        return true;
    }
    if (s == "round") {
        cap = RoundCap;
        return true;
    }
    if (s == "square") {
        cap = SquareCap;
        return true;
    }
    return false;
}

String lineCapName(LineCap cap)
{
    ASSERT(cap >= 0);
    ASSERT(cap < 3);
    const char* const names[3] = { "butt", "round", "square" };
    return names[cap];
}

bool parseLineJoin(const String& s, LineJoin& join)
{
    if (s == "miter") {
        join = MiterJoin;
        return true;
    }
    if (s == "round") {
        join = RoundJoin;
        return true;
    }
    if (s == "bevel") {
        join = BevelJoin;
        return true;
    }
    return false;
}

String lineJoinName(LineJoin join)
{
    ASSERT(join >= 0);
    ASSERT(join < 3);
    const char* const names[3] = { "miter", "round", "bevel" };
    return names[join];
}

String textAlignName(TextAlign align)
{
    ASSERT(align >= 0);
    ASSERT(align < 5);
    const char* const names[5] = { "start", "end", "left", "center", "right" };
    return names[align];
}

bool parseTextAlign(const String& s, TextAlign& align)
{
    if (s == "start") {
        align = StartTextAlign;
        return true;
    }
    if (s == "end") {
        align = EndTextAlign;
        return true;
    }
    if (s == "left") {
        align = LeftTextAlign;
        return true;
    }
    if (s == "center") {
        align = CenterTextAlign;
        return true;
    }
    if (s == "right") {
        align = RightTextAlign;
        return true;
    }
    return false;
}

String textBaselineName(TextBaseline baseline)
{
    ASSERT(baseline >= 0);
    ASSERT(baseline < 6);
    const char* const names[6] = { "alphabetic", "top", "middle", "bottom", "ideographic", "hanging" };
    return names[baseline];
}

bool parseTextBaseline(const String& s, TextBaseline& baseline)
{
    if (s == "alphabetic") {
        baseline = AlphabeticTextBaseline;
        return true;
    }
    if (s == "top") {
        baseline = TopTextBaseline;
        return true;
    }
    if (s == "middle") {
        baseline = MiddleTextBaseline;
        return true;
    }
    if (s == "bottom") {
        baseline = BottomTextBaseline;
        return true;
    }
    if (s == "ideographic") {
        baseline = IdeographicTextBaseline;
        return true;
    }
    if (s == "hanging") {
        baseline = HangingTextBaseline;
        return true;
    }
    return false;
}

} // namespace blink
