/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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

#include "config.h"
#include "core/dom/DocumentParser.h"

#include "core/dom/Document.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "wtf/Assertions.h"

namespace blink {

DocumentParser::DocumentParser(Document* document)
    : m_state(ParsingState)
    , m_document(document)
{
    ASSERT(document);
}

DocumentParser::~DocumentParser()
{
#if !ENABLE(OILPAN)
    // Document is expected to call detach() before releasing its ref.
    // This ASSERT is slightly awkward for parsers with a fragment case
    // as there is no Document to release the ref.
    ASSERT(!m_document);
#endif
}

void DocumentParser::trace(Visitor* visitor)
{
    visitor->trace(m_document);
}

void DocumentParser::prepareToStopParsing()
{
    ASSERT(m_state == ParsingState);
    m_state = StoppingState;
}

void DocumentParser::stopParsing()
{
    m_state = StoppedState;
}

void DocumentParser::detach()
{
    m_state = DetachedState;
    m_document = nullptr;
}

};

