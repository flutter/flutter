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

#include "config.h"
#include "core/html/parser/HTMLTokenizer.h"

#include "core/HTMLNames.h"
#include "core/HTMLTokenizerNames.h"
#include "core/html/parser/HTMLEntityParser.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLTreeBuilder.h"
#include "core/html/parser/MarkupTokenizerInlines.h"
#include "platform/NotImplemented.h"
#include "wtf/ASCIICType.h"
#include "wtf/text/AtomicString.h"
#include "wtf/unicode/Unicode.h"

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

static inline UChar toLowerCase(UChar cc)
{
    ASSERT(isASCIIUpper(cc));
    const int lowerCaseOffset = 0x20;
    return cc + lowerCaseOffset;
}

static inline bool vectorEqualsString(const Vector<LChar, 32>& vector, const String& string)
{
    if (vector.size() != string.length())
        return false;

    if (!string.length())
        return true;

    return equal(string.impl(), vector.data(), vector.size());
}

static inline bool isEndTagBufferingState(HTMLTokenizer::State state)
{
    switch (state) {
    case HTMLTokenizer::RAWTEXTEndTagOpenState:
    case HTMLTokenizer::RAWTEXTEndTagNameState:
    case HTMLTokenizer::ScriptDataEndTagOpenState:
    case HTMLTokenizer::ScriptDataEndTagNameState:
    case HTMLTokenizer::ScriptDataEscapedEndTagOpenState:
    case HTMLTokenizer::ScriptDataEscapedEndTagNameState:
        return true;
    default:
        return false;
    }
}

#define HTML_BEGIN_STATE(stateName) BEGIN_STATE(HTMLTokenizer, stateName)
#define HTML_RECONSUME_IN(stateName) RECONSUME_IN(HTMLTokenizer, stateName)
#define HTML_ADVANCE_TO(stateName) ADVANCE_TO(HTMLTokenizer, stateName)
#define HTML_SWITCH_TO(stateName) SWITCH_TO(HTMLTokenizer, stateName)

HTMLTokenizer::HTMLTokenizer(const HTMLParserOptions& options)
    : m_inputStreamPreprocessor(this)
    , m_options(options)
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
    m_additionalAllowedCharacter = '\0';
}

bool HTMLTokenizer::canCreateCheckpoint() const
{
    if (!m_appropriateEndTagName.isEmpty())
        return false;
    if (!m_temporaryBuffer.isEmpty())
        return false;
    if (!m_bufferedEndTagName.isEmpty())
        return false;
    return true;
}

void HTMLTokenizer::createCheckpoint(Checkpoint& result) const
{
    ASSERT(canCreateCheckpoint());
    result.options = m_options;
    result.state = m_state;
    result.additionalAllowedCharacter = m_additionalAllowedCharacter;
    result.skipNextNewLine = m_inputStreamPreprocessor.skipNextNewLine();
}

void HTMLTokenizer::restoreFromCheckpoint(const Checkpoint& checkpoint)
{
    m_token = 0;
    m_options = checkpoint.options;
    m_state = checkpoint.state;
    m_additionalAllowedCharacter = checkpoint.additionalAllowedCharacter;
    m_inputStreamPreprocessor.reset(checkpoint.skipNextNewLine);
}

inline bool HTMLTokenizer::processEntity(SegmentedString& source)
{
    bool notEnoughCharacters = false;
    DecodedHTMLEntity decodedEntity;
    bool success = consumeHTMLEntity(source, decodedEntity, notEnoughCharacters);
    if (notEnoughCharacters)
        return false;
    if (!success) {
        ASSERT(decodedEntity.isEmpty());
        bufferCharacter('&');
    } else {
        for (unsigned i = 0; i < decodedEntity.length; ++i)
            bufferCharacter(decodedEntity.data[i]);
    }
    return true;
}

bool HTMLTokenizer::flushBufferedEndTag(SegmentedString& source)
{
    ASSERT(m_token->type() == HTMLToken::Character || m_token->type() == HTMLToken::Uninitialized);
    source.advanceAndUpdateLineNumber();
    if (m_token->type() == HTMLToken::Character)
        return true;
    m_token->beginEndTag(m_bufferedEndTagName);
    m_bufferedEndTagName.clear();
    m_appropriateEndTagName.clear();
    m_temporaryBuffer.clear();
    return false;
}

#define FLUSH_AND_ADVANCE_TO(stateName)                                    \
    do {                                                                   \
        m_state = HTMLTokenizer::stateName;                           \
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

    if (!m_bufferedEndTagName.isEmpty() && !isEndTagBufferingState(m_state)) {
        // FIXME: This should call flushBufferedEndTag().
        // We started an end tag during our last iteration.
        m_token->beginEndTag(m_bufferedEndTagName);
        m_bufferedEndTagName.clear();
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
        if (cc == '&')
            HTML_ADVANCE_TO(CharacterReferenceInDataState);
        else if (cc == '<') {
            if (m_token->type() == HTMLToken::Character) {
                // We have a bunch of character tokens queued up that we
                // are emitting lazily here.
                return true;
            }
            HTML_ADVANCE_TO(TagOpenState);
        } else if (cc == kEndOfFileMarker)
            return emitEndOfFile(source);
        else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CharacterReferenceInDataState) {
        if (!processEntity(source))
            return haveBufferedCharacterToken();
        HTML_SWITCH_TO(DataState);
    }
    END_STATE()

    HTML_BEGIN_STATE(RAWTEXTState) {
        if (cc == '<')
            HTML_ADVANCE_TO(RAWTEXTLessThanSignState);
        else if (cc == kEndOfFileMarker)
            return emitEndOfFile(source);
        else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(RAWTEXTState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataState) {
        if (cc == '<')
            HTML_ADVANCE_TO(ScriptDataLessThanSignState);
        else if (cc == kEndOfFileMarker)
            return emitEndOfFile(source);
        else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(PLAINTEXTState) {
        if (cc == kEndOfFileMarker)
            return emitEndOfFile(source);
        bufferCharacter(cc);
        HTML_ADVANCE_TO(PLAINTEXTState);
    }
    END_STATE()

    HTML_BEGIN_STATE(TagOpenState) {
        if (cc == '!')
            HTML_ADVANCE_TO(MarkupDeclarationOpenState);
        else if (cc == '/')
            HTML_ADVANCE_TO(EndTagOpenState);
        else if (isASCIIUpper(cc)) {
            m_token->beginStartTag(toLowerCase(cc));
            HTML_ADVANCE_TO(TagNameState);
        } else if (isASCIILower(cc)) {
            m_token->beginStartTag(cc);
            HTML_ADVANCE_TO(TagNameState);
        } else if (cc == '?') {
            parseError();
            // The spec consumes the current character before switching
            // to the bogus comment state, but it's easier to implement
            // if we reconsume the current character.
            HTML_RECONSUME_IN(BogusCommentState);
        } else {
            parseError();
            bufferCharacter('<');
            HTML_RECONSUME_IN(DataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(EndTagOpenState) {
        if (isASCIIUpper(cc)) {
            m_token->beginEndTag(static_cast<LChar>(toLowerCase(cc)));
            m_appropriateEndTagName.clear();
            HTML_ADVANCE_TO(TagNameState);
        } else if (isASCIILower(cc)) {
            m_token->beginEndTag(static_cast<LChar>(cc));
            m_appropriateEndTagName.clear();
            HTML_ADVANCE_TO(TagNameState);
        } else if (cc == '>') {
            parseError();
            HTML_ADVANCE_TO(DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(DataState);
        } else {
            parseError();
            HTML_RECONSUME_IN(BogusCommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(TagNameState) {
        if (isTokenizerWhitespace(cc))
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        else if (cc == '/')
            HTML_ADVANCE_TO(SelfClosingStartTagState);
        else if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (isASCIIUpper(cc)) {
            m_token->appendToName(toLowerCase(cc));
            HTML_ADVANCE_TO(TagNameState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            m_token->appendToName(cc);
            HTML_ADVANCE_TO(TagNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RAWTEXTLessThanSignState) {
        if (cc == '/') {
            m_temporaryBuffer.clear();
            ASSERT(m_bufferedEndTagName.isEmpty());
            HTML_ADVANCE_TO(RAWTEXTEndTagOpenState);
        } else {
            bufferCharacter('<');
            HTML_RECONSUME_IN(RAWTEXTState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RAWTEXTEndTagOpenState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(RAWTEXTEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(RAWTEXTEndTagNameState);
        } else {
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(RAWTEXTState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(RAWTEXTEndTagNameState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(RAWTEXTEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(RAWTEXTEndTagNameState);
        } else {
            if (isTokenizerWhitespace(cc)) {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(BeforeAttributeNameState);
                }
            } else if (cc == '/') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(SelfClosingStartTagState);
                }
            } else if (cc == '>') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    return flushEmitAndResumeIn(source, HTMLTokenizer::DataState);
                }
            }
            bufferCharacter('<');
            bufferCharacter('/');
            m_token->appendToCharacter(m_temporaryBuffer);
            m_bufferedEndTagName.clear();
            m_temporaryBuffer.clear();
            HTML_RECONSUME_IN(RAWTEXTState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataLessThanSignState) {
        if (cc == '/') {
            m_temporaryBuffer.clear();
            ASSERT(m_bufferedEndTagName.isEmpty());
            HTML_ADVANCE_TO(ScriptDataEndTagOpenState);
        } else if (cc == '!') {
            bufferCharacter('<');
            bufferCharacter('!');
            HTML_ADVANCE_TO(ScriptDataEscapeStartState);
        } else {
            bufferCharacter('<');
            HTML_RECONSUME_IN(ScriptDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEndTagOpenState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(ScriptDataEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataEndTagNameState);
        } else {
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(ScriptDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEndTagNameState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(ScriptDataEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataEndTagNameState);
        } else {
            if (isTokenizerWhitespace(cc)) {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(BeforeAttributeNameState);
                }
            } else if (cc == '/') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(SelfClosingStartTagState);
                }
            } else if (cc == '>') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    return flushEmitAndResumeIn(source, HTMLTokenizer::DataState);
                }
            }
            bufferCharacter('<');
            bufferCharacter('/');
            m_token->appendToCharacter(m_temporaryBuffer);
            m_bufferedEndTagName.clear();
            m_temporaryBuffer.clear();
            HTML_RECONSUME_IN(ScriptDataState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapeStartState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapeStartDashState);
        } else
            HTML_RECONSUME_IN(ScriptDataState);
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapeStartDashState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedDashDashState);
        } else
            HTML_RECONSUME_IN(ScriptDataState);
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedDashState);
        } else if (cc == '<')
            HTML_ADVANCE_TO(ScriptDataEscapedLessThanSignState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedDashState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedDashDashState);
        } else if (cc == '<')
            HTML_ADVANCE_TO(ScriptDataEscapedLessThanSignState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedDashDashState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedDashDashState);
        } else if (cc == '<')
            HTML_ADVANCE_TO(ScriptDataEscapedLessThanSignState);
        else if (cc == '>') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedLessThanSignState) {
        if (cc == '/') {
            m_temporaryBuffer.clear();
            ASSERT(m_bufferedEndTagName.isEmpty());
            HTML_ADVANCE_TO(ScriptDataEscapedEndTagOpenState);
        } else if (isASCIIUpper(cc)) {
            bufferCharacter('<');
            bufferCharacter(cc);
            m_temporaryBuffer.clear();
            m_temporaryBuffer.append(toLowerCase(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeStartState);
        } else if (isASCIILower(cc)) {
            bufferCharacter('<');
            bufferCharacter(cc);
            m_temporaryBuffer.clear();
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeStartState);
        } else {
            bufferCharacter('<');
            HTML_RECONSUME_IN(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedEndTagOpenState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(ScriptDataEscapedEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataEscapedEndTagNameState);
        } else {
            bufferCharacter('<');
            bufferCharacter('/');
            HTML_RECONSUME_IN(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataEscapedEndTagNameState) {
        if (isASCIIUpper(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(toLowerCase(cc)));
            HTML_ADVANCE_TO(ScriptDataEscapedEndTagNameState);
        } else if (isASCIILower(cc)) {
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            addToPossibleEndTag(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataEscapedEndTagNameState);
        } else {
            if (isTokenizerWhitespace(cc)) {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(BeforeAttributeNameState);
                }
            } else if (cc == '/') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    FLUSH_AND_ADVANCE_TO(SelfClosingStartTagState);
                }
            } else if (cc == '>') {
                if (isAppropriateEndTag()) {
                    m_temporaryBuffer.append(static_cast<LChar>(cc));
                    return flushEmitAndResumeIn(source, HTMLTokenizer::DataState);
                }
            }
            bufferCharacter('<');
            bufferCharacter('/');
            m_token->appendToCharacter(m_temporaryBuffer);
            m_bufferedEndTagName.clear();
            m_temporaryBuffer.clear();
            HTML_RECONSUME_IN(ScriptDataEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapeStartState) {
        if (isTokenizerWhitespace(cc) || cc == '/' || cc == '>') {
            bufferCharacter(cc);
            if (temporaryBufferIs(HTMLNames::scriptTag.localName()))
                HTML_ADVANCE_TO(ScriptDataDoubleEscapedState);
            else
                HTML_ADVANCE_TO(ScriptDataEscapedState);
        } else if (isASCIIUpper(cc)) {
            bufferCharacter(cc);
            m_temporaryBuffer.append(toLowerCase(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeStartState);
        } else if (isASCIILower(cc)) {
            bufferCharacter(cc);
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeStartState);
        } else
            HTML_RECONSUME_IN(ScriptDataEscapedState);
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapedState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedDashState);
        } else if (cc == '<') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedLessThanSignState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapedDashState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedDashDashState);
        } else if (cc == '<') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedLessThanSignState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapedDashDashState) {
        if (cc == '-') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedDashDashState);
        } else if (cc == '<') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedLessThanSignState);
        } else if (cc == '>') {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            bufferCharacter(cc);
            HTML_ADVANCE_TO(ScriptDataDoubleEscapedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapedLessThanSignState) {
        if (cc == '/') {
            bufferCharacter(cc);
            m_temporaryBuffer.clear();
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeEndState);
        } else
            HTML_RECONSUME_IN(ScriptDataDoubleEscapedState);
    }
    END_STATE()

    HTML_BEGIN_STATE(ScriptDataDoubleEscapeEndState) {
        if (isTokenizerWhitespace(cc) || cc == '/' || cc == '>') {
            bufferCharacter(cc);
            if (temporaryBufferIs(HTMLNames::scriptTag.localName()))
                HTML_ADVANCE_TO(ScriptDataEscapedState);
            else
                HTML_ADVANCE_TO(ScriptDataDoubleEscapedState);
        } else if (isASCIIUpper(cc)) {
            bufferCharacter(cc);
            m_temporaryBuffer.append(toLowerCase(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeEndState);
        } else if (isASCIILower(cc)) {
            bufferCharacter(cc);
            m_temporaryBuffer.append(static_cast<LChar>(cc));
            HTML_ADVANCE_TO(ScriptDataDoubleEscapeEndState);
        } else
            HTML_RECONSUME_IN(ScriptDataDoubleEscapedState);
    }
    END_STATE()

    HTML_BEGIN_STATE(BeforeAttributeNameState) {
        if (isTokenizerWhitespace(cc))
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        else if (cc == '/')
            HTML_ADVANCE_TO(SelfClosingStartTagState);
        else if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (isASCIIUpper(cc)) {
            m_token->addNewAttribute();
            m_token->beginAttributeName(source.numberOfCharactersConsumed());
            m_token->appendToAttributeName(toLowerCase(cc));
            HTML_ADVANCE_TO(AttributeNameState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            if (cc == '"' || cc == '\'' || cc == '<' || cc == '=')
                parseError();
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
            HTML_ADVANCE_TO(SelfClosingStartTagState);
        } else if (cc == '=') {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(BeforeAttributeValueState);
        } else if (cc == '>') {
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (isASCIIUpper(cc)) {
            m_token->appendToAttributeName(toLowerCase(cc));
            HTML_ADVANCE_TO(AttributeNameState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            m_token->endAttributeName(source.numberOfCharactersConsumed());
            HTML_RECONSUME_IN(DataState);
        } else {
            if (cc == '"' || cc == '\'' || cc == '<' || cc == '=')
                parseError();
            m_token->appendToAttributeName(cc);
            HTML_ADVANCE_TO(AttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AfterAttributeNameState) {
        if (isTokenizerWhitespace(cc))
            HTML_ADVANCE_TO(AfterAttributeNameState);
        else if (cc == '/')
            HTML_ADVANCE_TO(SelfClosingStartTagState);
        else if (cc == '=')
            HTML_ADVANCE_TO(BeforeAttributeValueState);
        else if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (isASCIIUpper(cc)) {
            m_token->addNewAttribute();
            m_token->beginAttributeName(source.numberOfCharactersConsumed());
            m_token->appendToAttributeName(toLowerCase(cc));
            HTML_ADVANCE_TO(AttributeNameState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            if (cc == '"' || cc == '\'' || cc == '<')
                parseError();
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
            parseError();
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            if (cc == '<' || cc == '=' || cc == '`')
                parseError();
            m_token->beginAttributeValue(source.numberOfCharactersConsumed());
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueUnquotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeValueDoubleQuotedState) {
        if (cc == '"') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(AfterAttributeValueQuotedState);
        } else if (cc == '&') {
            m_additionalAllowedCharacter = '"';
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_RECONSUME_IN(DataState);
        } else {
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueDoubleQuotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(AttributeValueSingleQuotedState) {
        if (cc == '\'') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_ADVANCE_TO(AfterAttributeValueQuotedState);
        } else if (cc == '&') {
            m_additionalAllowedCharacter = '\'';
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_RECONSUME_IN(DataState);
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
            m_additionalAllowedCharacter = '>';
            HTML_ADVANCE_TO(CharacterReferenceInAttributeValueState);
        } else if (cc == '>') {
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            m_token->endAttributeValue(source.numberOfCharactersConsumed());
            HTML_RECONSUME_IN(DataState);
        } else {
            if (cc == '"' || cc == '\'' || cc == '<' || cc == '=' || cc == '`')
                parseError();
            m_token->appendToAttributeValue(cc);
            HTML_ADVANCE_TO(AttributeValueUnquotedState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CharacterReferenceInAttributeValueState) {
        bool notEnoughCharacters = false;
        DecodedHTMLEntity decodedEntity;
        bool success = consumeHTMLEntity(source, decodedEntity, notEnoughCharacters, m_additionalAllowedCharacter);
        if (notEnoughCharacters)
            return haveBufferedCharacterToken();
        if (!success) {
            ASSERT(decodedEntity.isEmpty());
            m_token->appendToAttributeValue('&');
        } else {
            for (unsigned i = 0; i < decodedEntity.length; ++i)
                m_token->appendToAttributeValue(decodedEntity.data[i]);
        }
        // We're supposed to switch back to the attribute value state that
        // we were in when we were switched into this state. Rather than
        // keeping track of this explictly, we observe that the previous
        // state can be determined by m_additionalAllowedCharacter.
        if (m_additionalAllowedCharacter == '"')
            HTML_SWITCH_TO(AttributeValueDoubleQuotedState);
        else if (m_additionalAllowedCharacter == '\'')
            HTML_SWITCH_TO(AttributeValueSingleQuotedState);
        else if (m_additionalAllowedCharacter == '>')
            HTML_SWITCH_TO(AttributeValueUnquotedState);
        else
            ASSERT_NOT_REACHED();
    }
    END_STATE()

    HTML_BEGIN_STATE(AfterAttributeValueQuotedState) {
        if (isTokenizerWhitespace(cc))
            HTML_ADVANCE_TO(BeforeAttributeNameState);
        else if (cc == '/')
            HTML_ADVANCE_TO(SelfClosingStartTagState);
        else if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            parseError();
            HTML_RECONSUME_IN(BeforeAttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(SelfClosingStartTagState) {
        if (cc == '>') {
            m_token->setSelfClosing();
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            HTML_RECONSUME_IN(DataState);
        } else {
            parseError();
            HTML_RECONSUME_IN(BeforeAttributeNameState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(BogusCommentState) {
        m_token->beginComment();
        HTML_RECONSUME_IN(ContinueBogusCommentState);
    }
    END_STATE()

    HTML_BEGIN_STATE(ContinueBogusCommentState) {
        if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (cc == kEndOfFileMarker)
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        else {
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(ContinueBogusCommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(MarkupDeclarationOpenState) {
        if (cc == '-') {
            SegmentedString::LookAheadResult result = source.lookAhead(HTMLTokenizerNames::dashDash);
            if (result == SegmentedString::DidMatch) {
                source.advanceAndASSERT('-');
                source.advanceAndASSERT('-');
                m_token->beginComment();
                HTML_SWITCH_TO(CommentStartState);
            } else if (result == SegmentedString::NotEnoughCharacters)
                return haveBufferedCharacterToken();
        }
        parseError();
        HTML_RECONSUME_IN(BogusCommentState);
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentStartState) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentStartDashState);
        else if (cc == '>') {
            parseError();
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentStartDashState) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEndState);
        else if (cc == '>') {
            parseError();
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToComment('-');
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentState) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEndDashState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentEndDashState) {
        if (cc == '-')
            HTML_ADVANCE_TO(CommentEndState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToComment('-');
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentEndState) {
        if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (cc == '!') {
            parseError();
            HTML_ADVANCE_TO(CommentEndBangState);
        } else if (cc == '-') {
            parseError();
            m_token->appendToComment('-');
            HTML_ADVANCE_TO(CommentEndState);
        } else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            parseError();
            m_token->appendToComment('-');
            m_token->appendToComment('-');
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    HTML_BEGIN_STATE(CommentEndBangState) {
        if (cc == '-') {
            m_token->appendToComment('-');
            m_token->appendToComment('-');
            m_token->appendToComment('!');
            HTML_ADVANCE_TO(CommentEndDashState);
        } else if (cc == '>')
            return emitAndResumeIn(source, HTMLTokenizer::DataState);
        else if (cc == kEndOfFileMarker) {
            parseError();
            return emitAndReconsumeIn(source, HTMLTokenizer::DataState);
        } else {
            m_token->appendToComment('-');
            m_token->appendToComment('-');
            m_token->appendToComment('!');
            m_token->appendToComment(cc);
            HTML_ADVANCE_TO(CommentState);
        }
    }
    END_STATE()

    }

    ASSERT_NOT_REACHED();
    return false;
}

String HTMLTokenizer::bufferedCharacters() const
{
    // FIXME: Add an assert about m_state.
    StringBuilder characters;
    characters.reserveCapacity(numberOfBufferedCharacters());
    characters.append('<');
    characters.append('/');
    characters.append(m_temporaryBuffer.data(), m_temporaryBuffer.size());
    return characters.toString();
}

void HTMLTokenizer::updateStateFor(const String& tagName)
{
    if (threadSafeMatch(tagName, HTMLNames::scriptTag))
        setState(HTMLTokenizer::ScriptDataState);
    else if (threadSafeMatch(tagName, HTMLNames::styleTag))
        setState(HTMLTokenizer::RAWTEXTState);
}

inline bool HTMLTokenizer::temporaryBufferIs(const String& expectedString)
{
    return vectorEqualsString(m_temporaryBuffer, expectedString);
}

inline void HTMLTokenizer::addToPossibleEndTag(LChar cc)
{
    ASSERT(isEndTagBufferingState(m_state));
    m_bufferedEndTagName.append(cc);
}

inline bool HTMLTokenizer::isAppropriateEndTag()
{
    if (m_bufferedEndTagName.size() != m_appropriateEndTagName.size())
        return false;

    size_t numCharacters = m_bufferedEndTagName.size();

    for (size_t i = 0; i < numCharacters; i++) {
        if (m_bufferedEndTagName[i] != m_appropriateEndTagName[i])
            return false;
    }

    return true;
}

inline void HTMLTokenizer::parseError()
{
    notImplemented();
}

}
