/*
 * Copyright (C) 2006, 2007, 2008 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2007 Alp Toker <alp@atoker.com>
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

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_CANVASIMAGESOURCE_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_CANVASIMAGESOURCE_H_

#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

class Image;

enum SourceImageMode {
    CopySourceImageIfVolatile,
    DontCopySourceImage
};

enum SourceImageStatus {
    NormalSourceImageStatus,
    ExternalSourceImageStatus, // Shared with another GPU context
    UndecodableSourceImageStatus, // Image element with a 'broken' image
    ZeroSizeCanvasSourceImageStatus, // Source is a canvas with width or heigh of zero
    IncompleteSourceImageStatus, // Image element with no source media
    InvalidSourceImageStatus,
};

class CanvasImageSource {
public:
    virtual PassRefPtr<Image> getSourceImageForCanvas(SourceImageMode, SourceImageStatus* = 0) const = 0;

    virtual bool isVideoElement() const { return false; }

    // Adjusts the source and destination rectangles for cases where the actual
    // source image is a subregion of the image returned by getSourceImageForCanvas.
    virtual void adjustDrawRects(FloatRect* srcRect, FloatRect* dstRect) const { }

    virtual FloatSize sourceSize() const = 0;
    virtual FloatSize defaultDestinationSize() const { return sourceSize(); }
    virtual const KURL& sourceURL() const { return blankURL(); }

protected:
    virtual ~CanvasImageSource() { }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_CANVASIMAGESOURCE_H_
