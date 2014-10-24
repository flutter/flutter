/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
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

#ifndef CanvasStyle_h
#define CanvasStyle_h

#include "platform/graphics/Color.h"
#include "platform/heap/Handle.h"
#include "wtf/Assertions.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

    class CanvasGradient;
    class CanvasPattern;
    class GraphicsContext;
    class HTMLCanvasElement;

    class CanvasStyle final : public RefCountedWillBeGarbageCollected<CanvasStyle> {
    public:
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromRGBA(RGBA32 rgba) { return adoptRefWillBeNoop(new CanvasStyle(rgba)); }
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromString(const String& color);
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromStringWithOverrideAlpha(const String& color, float alpha);
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromGrayLevelWithAlpha(float grayLevel, float alpha) { return adoptRefWillBeNoop(new CanvasStyle(grayLevel, alpha)); }
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromRGBAChannels(float r, float g, float b, float a) { return adoptRefWillBeNoop(new CanvasStyle(r, g, b, a)); }
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromCMYKAChannels(float c, float m, float y, float k, float a) { return adoptRefWillBeNoop(new CanvasStyle(c, m, y, k, a)); }
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromGradient(PassRefPtrWillBeRawPtr<CanvasGradient>);
        static PassRefPtrWillBeRawPtr<CanvasStyle> createFromPattern(PassRefPtrWillBeRawPtr<CanvasPattern>);

        bool isCurrentColor() const { return m_type == CurrentColor || m_type == CurrentColorWithOverrideAlpha; }
        bool hasOverrideAlpha() const { return m_type == CurrentColorWithOverrideAlpha; }
        float overrideAlpha() const { ASSERT(m_type == CurrentColorWithOverrideAlpha); return m_overrideAlpha; }

        String color() const { ASSERT(m_type == RGBA || m_type == CMYKA); return Color(m_rgba).serialized(); }
        CanvasGradient* canvasGradient() const { return m_gradient.get(); }
        CanvasPattern* canvasPattern() const { return m_pattern.get(); }

        void applyFillColor(GraphicsContext*);
        void applyStrokeColor(GraphicsContext*);

        bool isEquivalentColor(const CanvasStyle&) const;
        bool isEquivalentRGBA(float r, float g, float b, float a) const;
        bool isEquivalentCMYKA(float c, float m, float y, float k, float a) const;

        void trace(Visitor*);

    private:
        enum Type { RGBA, CMYKA, Gradient, ImagePattern, CurrentColor, CurrentColorWithOverrideAlpha };

        CanvasStyle(Type, float overrideAlpha = 0);
        CanvasStyle(RGBA32 rgba);
        CanvasStyle(float grayLevel, float alpha);
        CanvasStyle(float r, float g, float b, float a);
        CanvasStyle(float c, float m, float y, float k, float a);
        CanvasStyle(PassRefPtrWillBeRawPtr<CanvasGradient>);
        CanvasStyle(PassRefPtrWillBeRawPtr<CanvasPattern>);

        Type m_type;

        union {
            RGBA32 m_rgba;
            float m_overrideAlpha;
        };

        RefPtrWillBeMember<CanvasGradient> m_gradient;
        RefPtrWillBeMember<CanvasPattern> m_pattern;

        struct CMYKAValues {
            CMYKAValues() : c(0), m(0), y(0), k(0), a(0) { }
            CMYKAValues(float cyan, float magenta, float yellow, float black, float alpha) : c(cyan), m(magenta), y(yellow), k(black), a(alpha) { }
            float c;
            float m;
            float y;
            float k;
            float a;
        } m_cmyka;
    };

    RGBA32 currentColor(HTMLCanvasElement*);
    bool parseColorOrCurrentColor(RGBA32& parsedColor, const String& colorString, HTMLCanvasElement*);

} // namespace blink

#endif
