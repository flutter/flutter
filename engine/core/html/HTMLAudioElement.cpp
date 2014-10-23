/*
 * Copyright (C) 2007, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
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
#include "core/html/HTMLAudioElement.h"

#include "core/HTMLNames.h"

namespace blink {

HTMLAudioElement::HTMLAudioElement(Document& document)
    : HTMLMediaElement(HTMLNames::audioTag, document)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<HTMLAudioElement> HTMLAudioElement::create(Document& document)
{
    RefPtrWillBeRawPtr<HTMLAudioElement> audio = adoptRefWillBeNoop(new HTMLAudioElement(document));
    audio->suspendIfNeeded();
    return audio.release();
}

PassRefPtrWillBeRawPtr<HTMLAudioElement> HTMLAudioElement::createForJSConstructor(Document& document, const AtomicString& src)
{
    RefPtrWillBeRawPtr<HTMLAudioElement> audio = adoptRefWillBeNoop(new HTMLAudioElement(document));
    audio->setPreload(AtomicString("auto", AtomicString::ConstructFromLiteral));
    if (!src.isNull())
        audio->setSrc(src);
    audio->suspendIfNeeded();
    return audio.release();
}

}
