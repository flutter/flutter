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

#ifndef SKY_ENGINE_CORE_CSS_FONTFACESETLOADEVENT_H_
#define SKY_ENGINE_CORE_CSS_FONTFACESETLOADEVENT_H_

#include "sky/engine/core/css/FontFace.h"
#include "sky/engine/core/dom/DOMError.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

struct FontFaceSetLoadEventInit : public EventInit {
    FontFaceArray fontfaces;
};

class FontFaceSetLoadEvent final : public Event {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<FontFaceSetLoadEvent> create()
    {
        return adoptRef(new FontFaceSetLoadEvent());
    }

    static PassRefPtr<FontFaceSetLoadEvent> create(const AtomicString& type, const FontFaceSetLoadEventInit& initializer)
    {
        return adoptRef(new FontFaceSetLoadEvent(type, initializer));
    }

    static PassRefPtr<FontFaceSetLoadEvent> createForFontFaces(const AtomicString& type, const FontFaceArray& fontfaces = FontFaceArray())
    {
        return adoptRef(new FontFaceSetLoadEvent(type, fontfaces));
    }

    virtual ~FontFaceSetLoadEvent();

    FontFaceArray fontfaces() const { return m_fontfaces; }

    virtual const AtomicString& interfaceName() const override;

private:
    FontFaceSetLoadEvent();
    FontFaceSetLoadEvent(const AtomicString&, const FontFaceArray&);
    FontFaceSetLoadEvent(const AtomicString&, const FontFaceSetLoadEventInit&);

    FontFaceArray m_fontfaces;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_FONTFACESETLOADEVENT_H_
