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

#ifndef DrawLooperBuilder_h
#define DrawLooperBuilder_h

#include "platform/PlatformExport.h"
#include "third_party/skia/include/effects/SkLayerDrawLooper.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"

class SkDrawLooper;

namespace blink {

class Color;
class FloatSize;

class PLATFORM_EXPORT DrawLooperBuilder FINAL {
    // Implementing the copy constructor properly would require writing code to
    // copy the underlying SkLayerDrawLooper::Builder.
    WTF_MAKE_NONCOPYABLE(DrawLooperBuilder);

public:
    enum ShadowTransformMode {
        ShadowRespectsTransforms,
        ShadowIgnoresTransforms
    };
    enum ShadowAlphaMode {
        ShadowRespectsAlpha,
        ShadowIgnoresAlpha
    };

    DrawLooperBuilder();
    ~DrawLooperBuilder();

    static PassOwnPtr<DrawLooperBuilder> create();

    // Creates the SkDrawLooper and passes ownership to the caller. The builder
    // should not be used any more after calling this method.
    PassRefPtr<SkDrawLooper> detachDrawLooper();

    void addUnmodifiedContent();
    void addShadow(const FloatSize& offset, float blur, const Color&,
        ShadowTransformMode = ShadowRespectsTransforms,
        ShadowAlphaMode = ShadowRespectsAlpha);

private:
    SkLayerDrawLooper::Builder m_skDrawLooperBuilder;
};

} // namespace blink

#endif // DrawLooperBuilder_h
