/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
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

#ifndef HTMLTokenizer_h
#define HTMLTokenizer_h

#include "core/html/parser/HTMLEntityParser.h"
#include "core/html/parser/HTMLToken.h"
#include "core/html/parser/InputStreamPreprocessor.h"
#include "platform/text/SegmentedString.h"

namespace blink {

class HTMLTokenizer {
    WTF_MAKE_NONCOPYABLE(HTMLTokenizer);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<HTMLTokenizer> create() { return adoptPtr(new HTMLTokenizer()); }
    ~HTMLTokenizer();

    void reset();

    enum State {
        DataState,
        CharacterReferenceInDataState,
        CharacterReferenceInAttributeValueState,
        RawDataState,
        RawDataLessThanSignState,
        RawDataEndTagOpenState,
        RawDataEndTagNameState,
        TagOpenState,
        CloseTagState,
        TagNameState,
        BeforeAttributeNameState,
        AttributeNameState,
        AfterAttributeNameState,
        BeforeAttributeValueState,
        AttributeValueDoubleQuotedState,
        AttributeValueSingleQuotedState,
        AttributeValueUnquotedState,
        VoidTagState,
        CommentStart1State,
        CommentStart2State,
        CommentState,
        CommentEnd1State,
        CommentEnd2State,
    };

    // This function returns true if it emits a token. Otherwise, callers
    // must provide the same (in progress) token on the next call (unless
    // they call reset() first).
    bool nextToken(SegmentedString&, HTMLToken&);

    State state() const { return m_state; }

    void setState(State state) { m_state = state; }

private:
    HTMLTokenizer();

    inline void parseError();

    inline void bufferCharacter(UChar character)
    {
        ASSERT(character != kEndOfFileMarker);
        m_token->ensureIsCharacterToken();
        m_token->appendToCharacter(character);
    }

    inline bool emitAndResumeIn(SegmentedString& source, State state)
    {
        saveEndTagNameIfNeeded();
        m_state = state;
        source.advanceAndUpdateLineNumber();
        return true;
    }

    inline bool emitAndReconsumeIn(SegmentedString&, State state)
    {
        saveEndTagNameIfNeeded();
        m_state = state;
        return true;
    }

    inline bool emitEndOfFile(SegmentedString& source)
    {
        if (haveBufferedCharacterToken())
            return true;
        m_state = HTMLTokenizer::DataState;
        source.advanceAndUpdateLineNumber();
        m_token->clear();
        m_token->makeEndOfFile();
        return true;
    }

    inline bool flushEmitAndResumeIn(SegmentedString&, State);

    // Return whether we need to emit a character token before dealing with
    // the buffered end tag.
    inline bool flushBufferedEndTag(SegmentedString&);

    inline void saveEndTagNameIfNeeded()
    {
        ASSERT(m_token->type() != HTMLToken::Uninitialized);
        if (m_token->type() == HTMLToken::StartTag)
            m_appropriateEndTagName = m_token->name();
    }
    inline bool isAppropriateEndTag();

    inline bool haveBufferedCharacterToken()
    {
        return m_token->type() == HTMLToken::Character;
    }

    State m_state;

    // m_token is owned by the caller. If nextToken is not on the stack,
    // this member might be pointing to unallocated memory.
    HTMLToken* m_token;

    State m_returnState;

    // http://www.whatwg.org/specs/web-apps/current-work/#preprocessing-the-input-stream
    InputStreamPreprocessor<HTMLTokenizer> m_inputStreamPreprocessor;
    HTMLEntityParser m_entityParser;

    Vector<UChar, 32> m_appropriateEndTagName;

    // http://www.whatwg.org/specs/web-apps/current-work/#temporary-buffer
    Vector<LChar, 32> m_temporaryBuffer;
};

}

#endif
