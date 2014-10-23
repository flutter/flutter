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
#include "core/dom/DecodedDataDocumentParser.h"

#include "core/dom/Document.h"
#include "core/html/parser/TextResourceDecoder.h"

namespace blink {

DecodedDataDocumentParser::DecodedDataDocumentParser(Document& document)
    : DocumentParser(&document)
    , m_decoder(TextResourceDecoder::create())
{
}

DecodedDataDocumentParser::~DecodedDataDocumentParser()
{
}

void DecodedDataDocumentParser::appendBytes(const char* data, size_t length)
{
    if (!length)
        return;

    // This should be checking isStopped(), but XMLDocumentParser prematurely
    // stops parsing when handling an XSLT processing instruction and still
    // needs to receive decoded bytes.
    if (isDetached())
        return;

    String decodedData = m_decoder->decode(data, length);
    if (!decodedData.isEmpty())
        append(decodedData.releaseImpl());
}

void DecodedDataDocumentParser::flush()
{
    // This should be checking isStopped(), but XMLDocumentParser prematurely
    // stops parsing when handling an XSLT processing instruction and still
    // needs to receive decoded bytes.
    if (isDetached())
        return;

    String decodedData = m_decoder->flush();
    if (!decodedData.isEmpty())
        append(decodedData.releaseImpl());
}

};
