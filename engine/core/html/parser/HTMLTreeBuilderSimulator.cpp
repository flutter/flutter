/*
 * Copyright (C) 2013 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/html/parser/HTMLTreeBuilderSimulator.h"

#include "core/HTMLNames.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLTokenizer.h"
#include "core/html/parser/HTMLTreeBuilder.h"

namespace blink {

HTMLTreeBuilderSimulator::HTMLTreeBuilderSimulator(const HTMLParserOptions& options)
    : m_options(options)
{
}

bool HTMLTreeBuilderSimulator::simulate(const CompactHTMLToken& token, HTMLTokenizer* tokenizer)
{
    if (token.type() == HTMLToken::StartTag) {
        const String& tagName = token.data();
        // FIXME: This is just a copy of Tokenizer::updateStateFor which uses threadSafeMatches.
        if (threadSafeMatch(tagName, HTMLNames::scriptTag))
            tokenizer->setState(HTMLTokenizer::ScriptDataState);
        else if (threadSafeMatch(tagName, HTMLNames::styleTag))
            tokenizer->setState(HTMLTokenizer::RAWTEXTState);
    }

    if (token.type() == HTMLToken::EndTag) {
        const String& tagName = token.data();
        if (threadSafeMatch(tagName, HTMLNames::scriptTag)) {
            tokenizer->setState(HTMLTokenizer::DataState);
            return false;
        }
    }

    return true;
}

}
