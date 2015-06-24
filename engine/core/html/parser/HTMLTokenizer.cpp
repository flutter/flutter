/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2009 Torch Mobile, Inc. http://www.torchmobile.com/
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

#include "sky/engine/core/html/parser/HTMLTokenizer.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/html/parser/AtomicHTMLToken.h"
#include "sky/engine/core/html/parser/HTMLEntityParser.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/html/parser/HTMLTreeBuilder.h"
#include "sky/engine/core/html/parser/MarkupTokenizerInlines.h"
#include "sky/engine/platform/NotImplemented.h"
#include "sky/engine/wtf/ASCIICType.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/unicode/Unicode.h"

// Please don't use DEFINE_STATIC_LOCAL in this file. The HTMLTokenizer is used
// from multiple threads and DEFINE_STATIC_LOCAL isn't threadsafe.
#undef DEFINE_STATIC_LOCAL

namespace blink {

// This has to go in a .cpp file, as the linker doesn't like it being included more than once.
// We don't have an HTMLToken.cpp though, so this is the next best place.
QualifiedName AtomicHTMLToken::nameForAttribute(const HTMLToken::Attribute& attribute) const
{
    return QualifiedName(AtomicString(attribute.name));
}

bool AtomicHTMLToken::usesName() const
{
    return m_type == HTMLToken::StartTag || m_type == HTMLToken::EndTag;
}

bool AtomicHTMLToken::usesAttributes() const
{
    return m_type == HTMLToken::StartTag || m_type == HTMLToken::EndTag;
}

static inline bool isEndTagBufferingState(HTMLTokenizer::State state)
{
    return state == HTMLTokenizer::RawDataEndTagOpenState || state == HTMLTokenizer::RawDataEndTagNameState;
}

#define HTML_BEGIN_STATE(stateName) BEGIN_STATE(HTMLTokenizer, stateName)
#define HTML_RECONSUME_IN(stateName) RECONSUME_IN(HTMLTokenizer, stateName)
#define HTML_ADVANCE_TO(stateName) ADVANCE_TO(HTMLTokenizer, stateName)
#define HTML_SWITCH_TO(stateName) SWITCH_TO(HTMLTokenizer, stateName)

HTMLTokenizer::HTMLTokenizer()
    : m_inputStreamPreprocessor(this)
{
    reset();
}

HTMLTokenizer::~HTMLTokenizer()
{
}

void HTMLTokenizer::reset()
{
    m_state = HTMLTokenizer::DataState;
    m_token = 0;
}

bool HTMLTokenizer::flushBufferedEndTag(SegmentedString& source)
{
    ASSERT(m_token->type() == HTMLToken::Character || m_token->type() == HTMLToken::Uninitialized);
    source.advanceAndUpdateLineNumber();
    if (m_token->type() == HTMLToken::Character)
        return true;
    m_token->beginEndTag(m_temporaryBuffer);
    m_appropriateEndTagName.clear();
    m_temporaryBuffer.clear();
    return false;
}

#define FLUSH_AND_ADVANCE_TO(stateName)                                    \
    do {                                                                   \
        m_state = HTMLTokenizer::stateName;                                \
        if (flushBufferedEndTag(source))                                   \
            return true;                                                   \
        if (source.isEmpty()                                               \
            || !m_inputStreamPreprocessor.peek(source))                    \
            return haveBufferedCharacterToken();                           \
        cc = m_inputStreamPreprocessor.nextInputCharacter();               \
        goto stateName;                                                    \
    } while (false)

bool HTMLTokenizer::flushEmitAndResumeIn(SegmentedString& source, HTMLTokenizer::State state)
{
    m_state = state;
    flushBufferedEndTag(source);
    return true;
}

bool HTMLTokenizer::nextToken(SegmentedString& source, HTMLToken& token)
{
    // If we have a token in progress, then we're supposed to be called back
    // with the same token so we can finish it.
    ASSERT(!m_token || m_token == &token || token.type() == HTMLToken::Uninitialized);
    m_token = &token;

    if (!m_temporaryBuffer.isEmpty() && !isEndTagBufferingState(m_state)) {
        // FIXME: This should call flushBufferedEndTag().
        // We started an end tag during our last iteration.
        m_token->beginEndTag(m_temporaryBuffer);
        m_appropriateEndTagName.clear();
        m_temporaryBuffer.clear();
        if (m_state == HTMLTokenizer::DataState) {
            // We're back in the data state, so we must be done with the tag.
            return true;
        }
    }

    if (source.isEmpty() || !m_inputStreamPreprocessor.peek(source))
        return haveBufferedCharacterToken();
    UChar cc = m_inputStreamPreprocessor.nextInputCharacter();

    // Source: http://www.whatwg.org/specs/web-apps/current-work/#tokenisation0
    switch (m_state) {
    HTML_BEGIN_STATE(DataState) {
        if (cc == '&') {
            m_returnState = DataState;
            m_entityParser.reset();
            HTML_ADVANCE_TO(CharacterReferenceInDataState);
        } else if (cc == '<') {
            if (m_token->type() == HTMLToken::Character) {
                // We have a bunch of character tokens queued up that we
                // are emitting lazily here.
                return true;
            }
            HTML_ADVANCE_TO(TagOpenState);
        } else if (cc == kEndOfFileMarker) {
            return emitEndOfFile(source);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CharacterReferenceInDataState) {
        if (!m_entityParser.parse(source))
            return haveBufferedCharacterToken();
        for (const UChar& entityCharacter : m_entityParser.result())
            bufferCharacter(entityCharacter);
        cc = m_inputStreamPreprocessor.nextInputCharacter();
        ASSERT(m_returnState == m_returnState);
        HTML_SWITCH_TO(DataState);
    }
    END_STATE()

    HTML_BEGIN_STATE(CharacterReferenceInAttributeValueState) {
        if (!m_entityParser.parse(source))
            return haveBufferedCharacterToken();
        for (const UChar& entityCharacter : m_entityParser.result())
            m_token->appendToAttributeValue(entityCharacter);
        cc = m_inputStreamPreprocessor.nextInputCharacter();

        if (m_returnState == AttributeValueDoubleQuotedState)
            HTML_SWITCH_TO(AttributeValueDoubleQuotedState);
        else if (m_returnState == AttributeValueSingleQuotedState)
            HTML_SWITCH_TO(AttributeValueSingleQuotedState);
        else if (m_returnState == AttributeValueUnquotedState)
            HTML_SWITCH_TO(AttributeValueUnquotedState);
        else
            ASSERT_NOT_REACHED();
    }
    END_STATE()

    HTML_BEGIN_STATE(RawDataState) {
        if (cc == '<') {
            HTML_ADVANCE_TO(RawDataLessThanSignState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(RawDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RawDataLessThanSignState) {
        if (cc == '/') {
            m_temporaryBuffer.clear();
            HTML_ADVANCE_TO(RawDataEndTagOpenState);
        } else {
            bufferCharacter('<');
            HTML_RECONSUME_IN(RawDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RawDataEndTagOpenState) {
        if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(RawDataEndTagNameState);
        } else {
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(RawDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RawDataEndTagNameState) {
        if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(RawDataEndTagNameState);
        } else {
            if (isTokenizerWhitespace(cc)) {
                if (isAppropriateEndTag())
                    FLUSH_AND_ADVANCE_TO(BeforeAttributeNameState);
            } else if (cc == '/') {
                if (isAppropriateEndTag())
                    FLUSH_AND_ADVANCE_TO(VoidTagState);
            } else if (cc == '>') {
                if (isAppropriateEndTag())
                    return flushEmitAndResumeIn(source, HTMLTokenizer::DataState);
            }
            bufferCharacter('<');
            bufferCharacter('/');
            m_token->appendToCharacter(m_temporaryBuffer);
            m_temporaryBuffer.clear();
            HTML_RECONSUME_IN(RawDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(TagOpenState) {
        if (cc == '!') {
            HTML_ADVANCE_TO(CommentStart1State);
        } else if (cc == '/') {
            HTML_ADVANCE_TO(CloseTagState);
        } else if (isTokenizerTagName(cc)) {
            m_token->beginStartTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(TagNameState);
        } else {
            bufferCharacter('<');
            HTML_RECONSUME_IN(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CloseTagState) {
        if (isTokenizerTagName(cc)) {
            m_token->beginEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(TagNameState);
        } else if (cc == '>') {
            bufferCharacter('<');
            bufferCharacter('/');
            bufferCharacter('>');
            HTML_ADVANCE_TO(DataState);
        } else {
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(TagNameState) {
        if (isTokenizerWhitespace(cc)) {
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        } else if (cc == '/') {
            HTML_ADVANCE_TO(VoidTagState);
        } else if (cc == '>') {
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToName(cc);
            HTML_ADVANCE_TO(TagNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(BeforeAttributeNameState) {
        if (isTokenizerWhitespace(cc)) {
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        } else if (cc == '/') {
            HTML_ADVANCE_TO(VoidTagState);
        } else if (cc == '>') {
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->addNewAttribute();
            m_token->beginAttributeName(source.numberOfCharactersConsumed());
            m_token->appendToAttributeName(cc);
            HTML_ADVANCE_TO(AttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeNameState) {
        if (isTokenizerWhitespace(cc)) {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(AfterAttributeNameState);
        } else if (cc == '/') {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(VoidTagState);
        } else if (cc == '=') {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(BeforeAttributeValueState);
        } else if (cc == '>') {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToAttributeName(cc);
            HTML_ADVANCE_TO(AttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AfterAttributeNameState) {
        if (isTokenizerWhitespace(cc)) {
            HTML_ADVANCE_TO(AfterAttributeNameState);
        } else if (cc == '/') {
            HTML_ADVANCE_TO(VoidTagState);
        } else if (cc == '=') {
            HTML_ADVANCE_TO(BeforeAttributeValueState);
        } else if (cc == '>') {
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->addNewAttribute();
            m_token->beginAttributeName(source.numberOfCharactersConsumed());
            m_token->appendToAttributeName(cc);
            HTML_ADVANCE_TO(AttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(BeforeAttributeValueState) {
        if (isTokenizerWhitespace(cc))
            HTML_ADVANCE_TO(BeforeAttributeValueState);
        else if (cc == '"') {
            m_token->beginAttributeValue(source.numberOfCharactersConsumed() + 1);
            HTML_ADVANCE_TO(AttributeValueDoubleQuotedState);
        } else if (cc == '&') {
            m_token->beginAttributeValue(source.numberOfCharactersConsumed());
            HTML_RECONSUME_IN(AttributeValueUnquotedState);
        } else if (cc == '\'') {
            m_token->beginAttributeValue(source.numberOfCharactersConsumed() + 1);
            HTML_ADVANCE_TO(AttributeValueSingleQuotedState);
        } else if (cc == '>') {
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->beginAttributeValue(source.numberOfCharactersConsumed());
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueUnquotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeValueDoubleQuotedState) {
        if (cc == '"') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        } else if (cc == '&') {
            m_returnState = AttributeValueDoubleQuotedState;
            m_entityParser.reset();
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else {
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueDoubleQuotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeValueSingleQuotedState) {
        if (cc == '\'') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        } else if (cc == '&') {
            m_returnState = AttributeValueSingleQuotedState;
            m_entityParser.reset();
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else {
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueSingleQuotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeValueUnquotedState) {
        if (isTokenizerWhitespace(cc)) {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        } else if (cc == '&') {
            m_returnState = AttributeValueUnquotedState;
            m_entityParser.reset();
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else if (cc == '>') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueUnquotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(VoidTagState) {
        if (cc == '>') {
            m_token->setSelfClosing();
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else {
            HTML_RECONSUME_IN(BeforeAttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentStart1State) {
        if (cc == '-') {
            HTML_ADVANCE_TO(CommentStart2State);
        } else {
            bufferCharacter('<');
            bufferCharacter('!');
            HTML_RECONSUME_IN(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentStart2State) {
        if (cc == '-') {
            HTML_ADVANCE_TO(CommentState);
        } else {
            bufferCharacter('<');
            bufferCharacter('!');
            bufferCharacter('-');
            HTML_RECONSUME_IN(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentState) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEnd1State);
        else
            HTML_ADVANCE_TO(CommentState);
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentEnd1State) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEnd2State);
        else
            HTML_ADVANCE_TO(CommentState);
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentEnd2State) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEnd2State);
        else if (cc == '>')
            HTML_ADVANCE_TO(DataState);
        else
            HTML_ADVANCE_TO(CommentState);
    }
    END_STATE()
    }

    ASSERT_NOT_REACHED();
    return false;
}

inline bool HTMLTokenizer::isAppropriateEndTag()
{
    if (m_temporaryBuffer.size() != m_appropriateEndTagName.size())
        return false;

    size_t numCharacters = m_temporaryBuffer.size();

    for (size_t i = 0; i < numCharacters; i++) {
        if (m_temporaryBuffer[i] != m_appropriateEndTagName[i])
            return false;
    }

    return true;
}

inline void HTMLTokenizer::parseError()
{
    notImplemented();
}

}
