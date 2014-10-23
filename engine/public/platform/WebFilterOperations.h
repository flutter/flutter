/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebFilterOperations_h
#define WebFilterOperations_h

#include "SkImageFilter.h"
#include "SkScalar.h"
#include "WebColor.h"
#include "WebPoint.h"

namespace blink {

// An ordered list of filter operations.
class WebFilterOperations {
public:
    virtual ~WebFilterOperations() { }

    virtual void appendGrayscaleFilter(float amount) = 0;
    virtual void appendSepiaFilter(float amount) = 0;
    virtual void appendSaturateFilter(float amount) = 0;
    virtual void appendHueRotateFilter(float amount) = 0;
    virtual void appendInvertFilter(float amount) = 0;
    virtual void appendBrightnessFilter(float amount) = 0;
    virtual void appendContrastFilter(float amount) = 0;
    virtual void appendOpacityFilter(float amount)= 0;
    virtual void appendBlurFilter(float amount) = 0;
    virtual void appendDropShadowFilter(WebPoint offset, float stdDeviation, WebColor) = 0;
    virtual void appendColorMatrixFilter(SkScalar matrix[20]) = 0;
    virtual void appendZoomFilter(float amount, int inset) = 0;
    virtual void appendSaturatingBrightnessFilter(float amount) = 0;

    // This grabs a ref on the passed-in filter.
    virtual void appendReferenceFilter(SkImageFilter*) = 0;

    virtual void clear() = 0;
};

} // namespace blink

#endif // WebFilterOperations_h
