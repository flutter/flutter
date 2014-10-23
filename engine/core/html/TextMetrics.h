/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef TextMetrics_h
#define TextMetrics_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class TextMetrics FINAL : public RefCountedWillBeGarbageCollected<TextMetrics>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<TextMetrics> create() { return adoptRefWillBeNoop(new TextMetrics); }

    float width() const { return m_width; }
    void setWidth(float w) { m_width = w; }

    float actualBoundingBoxLeft() const { return m_actualBoundingBoxLeft; }
    void setActualBoundingBoxLeft(float actualBoundingBoxLeft) { m_actualBoundingBoxLeft = actualBoundingBoxLeft; }

    float actualBoundingBoxRight() const { return m_actualBoundingBoxRight; }
    void setActualBoundingBoxRight(float actualBoundingBoxRight) { m_actualBoundingBoxRight = actualBoundingBoxRight; }

    float fontBoundingBoxAscent() const { return m_fontBoundingBoxAscent; }
    void setFontBoundingBoxAscent(float fontBoundingBoxAscent) { m_fontBoundingBoxAscent = fontBoundingBoxAscent; }

    float fontBoundingBoxDescent() const { return m_fontBoundingBoxDescent; }
    void setFontBoundingBoxDescent(float fontBoundingBoxDescent) { m_fontBoundingBoxDescent = fontBoundingBoxDescent; }

    float actualBoundingBoxAscent() const { return m_actualBoundingBoxAscent; }
    void setActualBoundingBoxAscent(float actualBoundingBoxAscent) { m_actualBoundingBoxAscent = actualBoundingBoxAscent; }

    float actualBoundingBoxDescent() const { return m_actualBoundingBoxDescent; }
    void setActualBoundingBoxDescent(float actualBoundingBoxDescent) { m_actualBoundingBoxDescent = actualBoundingBoxDescent; }

    float emHeightAscent() const { return m_emHeightAscent; }
    void setEmHeightAscent(float emHeightAscent) { m_emHeightAscent = emHeightAscent; }

    float emHeightDescent() const { return m_emHeightDescent; }
    void setEmHeightDescent(float emHeightDescent) { m_emHeightDescent = emHeightDescent; }

    float hangingBaseline() const { return m_hangingBaseline; }
    void setHangingBaseline(float hangingBaseline) { m_hangingBaseline = hangingBaseline; }

    float alphabeticBaseline() const { return m_alphabeticBaseline; }
    void setAlphabeticBaseline(float alphabeticBaseline) { m_alphabeticBaseline = alphabeticBaseline; }

    float ideographicBaseline() const { return m_ideographicBaseline; }
    void setIdeographicBaseline(float ideographicBaseline) { m_ideographicBaseline = ideographicBaseline; }

    void trace(Visitor*) { }

private:
    TextMetrics()
        : m_width(0)
        , m_actualBoundingBoxLeft(0)
        , m_actualBoundingBoxRight(0)
        , m_fontBoundingBoxAscent(0)
        , m_fontBoundingBoxDescent(0)
        , m_actualBoundingBoxAscent(0)
        , m_actualBoundingBoxDescent(0)
        , m_emHeightAscent(0)
        , m_emHeightDescent(0)
        , m_hangingBaseline(0)
        , m_alphabeticBaseline(0)
        , m_ideographicBaseline(0)
    {
        ScriptWrappable::init(this);
    }

    // x-direction
    float m_width;
    float m_actualBoundingBoxLeft;
    float m_actualBoundingBoxRight;

    // y-direction
    float m_fontBoundingBoxAscent;
    float m_fontBoundingBoxDescent;
    float m_actualBoundingBoxAscent;
    float m_actualBoundingBoxDescent;
    float m_emHeightAscent;
    float m_emHeightDescent;
    float m_hangingBaseline;
    float m_alphabeticBaseline;
    float m_ideographicBaseline;
};

} // namespace blink

#endif // TextMetrics_h
