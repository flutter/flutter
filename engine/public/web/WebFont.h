/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebFont_h
#define WebFont_h

#include "../platform/WebCanvas.h"
#include "../platform/WebColor.h"
#include "../platform/WebCommon.h"

namespace blink {

struct WebFontDescription;
struct WebFloatPoint;
struct WebFloatRect;
struct WebPoint;
struct WebRect;
struct WebTextRun;

class WebFont {
public:
    virtual ~WebFont() { }

    BLINK_EXPORT static WebFont* create(const WebFontDescription&);

    virtual WebFontDescription fontDescription() const = 0;

    virtual int ascent() const = 0;
    virtual int descent() const = 0;
    virtual int height() const = 0;
    virtual int lineSpacing() const = 0;
    virtual float xHeight() const = 0;

    // Draws the text run to the given canvas. The text is positioned at the
    // given left-hand point at the baseline.
    //
    // The text will be clipped to the given clip rect. |canvasIsOpaque| is
    // used to control whether subpixel antialiasing is possible. If there is a
    // possibility the area drawn could be semi-transparent, subpixel
    // antialiasing will be disabled.
    //
    // |from| and |to| allow the caller to specify a subrange of the given text
    // run to draw. If |to| is -1, the entire run will be drawn.
    virtual void drawText(WebCanvas*, const WebTextRun&, const WebFloatPoint& leftBaseline, WebColor,
                          const WebRect& clip, bool canvasIsOpaque,
                          int from = 0, int to = -1) const = 0;

    // Measures the width in pixels of the given text run.
    virtual int calculateWidth(const WebTextRun&) const = 0;

    // Returns the character offset corresponding to the given horizontal pixel
    // position as measured from from the left of the run.
    virtual int offsetForPosition(const WebTextRun&, float position) const = 0;

    // Returns the rectangle representing the selection rect for the subrange
    // |from| -> |to| of the given text run. You can use -1 for |to| to specify
    // the entire run (this will do something similar to calling width()).
    //
    // The rect will be positioned as if the text was drawn at the given
    // |leftBaseline| position. |height| indicates the height of the selection
    // rect you want, typically this will just be the height() of this font.
    //
    // To get the pixel offset of some character (the opposite of
    // offsetForPosition()), pass in a |leftBaseline| = (0, 0), |from| = 0, and
    // |to| = the character you want. The right edge of the resulting selection
    // rect will tell you the right side of the character.
    virtual WebFloatRect selectionRectForText(const WebTextRun&, const WebFloatPoint& leftBaseline,
                                              int height, int from = 0, int to = -1) const = 0;
};

} // namespace blink

#endif
