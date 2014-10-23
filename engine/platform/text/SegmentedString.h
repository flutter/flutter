/*
    Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef SegmentedString_h
#define SegmentedString_h

#include "platform/PlatformExport.h"
#include "wtf/Deque.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/TextPosition.h"
#include "wtf/text/WTFString.h"

namespace blink {

class SegmentedString;

class PLATFORM_EXPORT SegmentedSubstring {
public:
    SegmentedSubstring()
        : m_length(0)
        , m_doNotExcludeLineNumbers(true)
        , m_is8Bit(false)
    {
        m_data.string16Ptr = 0;
    }

    SegmentedSubstring(const String& str)
        : m_length(str.length())
        , m_doNotExcludeLineNumbers(true)
        , m_string(str)
    {
        if (m_length) {
            if (m_string.is8Bit()) {
                m_is8Bit = true;
                m_data.string8Ptr = m_string.characters8();
            } else {
                m_is8Bit = false;
                m_data.string16Ptr = m_string.characters16();
            }
        } else {
            m_is8Bit = false;
        }
    }

    void clear() { m_length = 0; m_data.string16Ptr = 0; m_is8Bit = false;}

    bool is8Bit() { return m_is8Bit; }

    bool excludeLineNumbers() const { return !m_doNotExcludeLineNumbers; }
    bool doNotExcludeLineNumbers() const { return m_doNotExcludeLineNumbers; }

    void setExcludeLineNumbers() { m_doNotExcludeLineNumbers = false; }

    int numberOfCharactersConsumed() const { return m_string.length() - m_length; }

    void appendTo(StringBuilder& builder) const
    {
        int offset = m_string.length() - m_length;

        if (!offset) {
            if (m_length)
                builder.append(m_string);
        } else {
            builder.append(m_string.substring(offset, m_length));
        }
    }

    UChar getCurrentChar8()
    {
        return *m_data.string8Ptr;
    }

    UChar getCurrentChar16()
    {
        return m_data.string16Ptr ? *m_data.string16Ptr : 0;
    }

    UChar incrementAndGetCurrentChar8()
    {
        ASSERT(m_data.string8Ptr);
        return *++m_data.string8Ptr;
    }

    UChar incrementAndGetCurrentChar16()
    {
        ASSERT(m_data.string16Ptr);
        return *++m_data.string16Ptr;
    }

    String currentSubString(unsigned length)
    {
        int offset = m_string.length() - m_length;
        return m_string.substring(offset, length);
    }

    ALWAYS_INLINE UChar getCurrentChar()
    {
        ASSERT(m_length);
        if (is8Bit())
            return getCurrentChar8();
        return getCurrentChar16();
    }

    ALWAYS_INLINE UChar incrementAndGetCurrentChar()
    {
        ASSERT(m_length);
        if (is8Bit())
            return incrementAndGetCurrentChar8();
        return incrementAndGetCurrentChar16();
    }

public:
    union {
        const LChar* string8Ptr;
        const UChar* string16Ptr;
    } m_data;
    int m_length;

private:
    bool m_doNotExcludeLineNumbers;
    bool m_is8Bit;
    String m_string;
};

class PLATFORM_EXPORT SegmentedString {
public:
    SegmentedString()
        : m_pushedChar1(0)
        , m_pushedChar2(0)
        , m_currentChar(0)
        , m_numberOfCharactersConsumedPriorToCurrentString(0)
        , m_numberOfCharactersConsumedPriorToCurrentLine(0)
        , m_currentLine(0)
        , m_closed(false)
        , m_empty(true)
        , m_fastPathFlags(NoFastPath)
        , m_advanceFunc(&SegmentedString::advanceEmpty)
        , m_advanceAndUpdateLineNumberFunc(&SegmentedString::advanceEmpty)
    {
    }

    SegmentedString(const String& str)
        : m_pushedChar1(0)
        , m_pushedChar2(0)
        , m_currentString(str)
        , m_currentChar(0)
        , m_numberOfCharactersConsumedPriorToCurrentString(0)
        , m_numberOfCharactersConsumedPriorToCurrentLine(0)
        , m_currentLine(0)
        , m_closed(false)
        , m_empty(!str.length())
        , m_fastPathFlags(NoFastPath)
    {
        if (m_currentString.m_length)
            m_currentChar = m_currentString.getCurrentChar();
        updateAdvanceFunctionPointers();
    }

    void clear();
    void close();

    void append(const SegmentedString&);
    void prepend(const SegmentedString&);

    bool excludeLineNumbers() const { return m_currentString.excludeLineNumbers(); }
    void setExcludeLineNumbers();

    void push(UChar c)
    {
        if (!m_pushedChar1) {
            m_pushedChar1 = c;
            m_currentChar = m_pushedChar1 ? m_pushedChar1 : m_currentString.getCurrentChar();
            updateSlowCaseFunctionPointers();
        } else {
            ASSERT(!m_pushedChar2);
            m_pushedChar2 = c;
        }
    }

    bool isEmpty() const { return m_empty; }
    unsigned length() const;

    bool isClosed() const { return m_closed; }

    enum LookAheadResult {
        DidNotMatch,
        DidMatch,
        NotEnoughCharacters,
    };

    LookAheadResult lookAhead(const String& string) { return lookAheadInline(string, true); }
    LookAheadResult lookAheadIgnoringCase(const String& string) { return lookAheadInline(string, false); }

    void advance()
    {
        if (m_fastPathFlags & Use8BitAdvance) {
            ASSERT(!m_pushedChar1);
            bool haveOneCharacterLeft = (--m_currentString.m_length == 1);
            m_currentChar = m_currentString.incrementAndGetCurrentChar8();

            if (!haveOneCharacterLeft)
                return;

            updateSlowCaseFunctionPointers();

            return;
        }

        (this->*m_advanceFunc)();
    }

    inline void advanceAndUpdateLineNumber()
    {
        if (m_fastPathFlags & Use8BitAdvance) {
            ASSERT(!m_pushedChar1);

            bool haveNewLine = (m_currentChar == '\n') & !!(m_fastPathFlags & Use8BitAdvanceAndUpdateLineNumbers);
            bool haveOneCharacterLeft = (--m_currentString.m_length == 1);

            m_currentChar = m_currentString.incrementAndGetCurrentChar8();

            if (!(haveNewLine | haveOneCharacterLeft))
                return;

            if (haveNewLine) {
                ++m_currentLine;
                m_numberOfCharactersConsumedPriorToCurrentLine =  m_numberOfCharactersConsumedPriorToCurrentString + m_currentString.numberOfCharactersConsumed();
            }

            if (haveOneCharacterLeft)
                updateSlowCaseFunctionPointers();

            return;
        }

        (this->*m_advanceAndUpdateLineNumberFunc)();
    }

    void advanceAndASSERT(UChar expectedCharacter)
    {
        ASSERT_UNUSED(expectedCharacter, currentChar() == expectedCharacter);
        advance();
    }

    void advanceAndASSERTIgnoringCase(UChar expectedCharacter)
    {
        ASSERT_UNUSED(expectedCharacter, WTF::Unicode::foldCase(currentChar()) == WTF::Unicode::foldCase(expectedCharacter));
        advance();
    }

    void advancePastNonNewline()
    {
        ASSERT(currentChar() != '\n');
        advance();
    }

    void advancePastNewlineAndUpdateLineNumber()
    {
        ASSERT(currentChar() == '\n');
        if (!m_pushedChar1 && m_currentString.m_length > 1) {
            int newLineFlag = m_currentString.doNotExcludeLineNumbers();
            m_currentLine += newLineFlag;
            if (newLineFlag)
                m_numberOfCharactersConsumedPriorToCurrentLine = numberOfCharactersConsumed() + 1;
            decrementAndCheckLength();
            m_currentChar = m_currentString.incrementAndGetCurrentChar();
            return;
        }
        advanceAndUpdateLineNumberSlowCase();
    }

    // Writes the consumed characters into consumedCharacters, which must
    // have space for at least |count| characters.
    void advance(unsigned count, UChar* consumedCharacters);

    bool escaped() const { return m_pushedChar1; }

    int numberOfCharactersConsumed() const
    {
        int numberOfPushedCharacters = 0;
        if (m_pushedChar1) {
            ++numberOfPushedCharacters;
            if (m_pushedChar2)
                ++numberOfPushedCharacters;
        }
        return m_numberOfCharactersConsumedPriorToCurrentString + m_currentString.numberOfCharactersConsumed() - numberOfPushedCharacters;
    }

    String toString() const;

    UChar currentChar() const { return m_currentChar; }

    // The method is moderately slow, comparing to currentLine method.
    OrdinalNumber currentColumn() const;
    OrdinalNumber currentLine() const;
    // Sets value of line/column variables. Column is specified indirectly by a parameter columnAftreProlog
    // which is a value of column that we should get after a prolog (first prologLength characters) has been consumed.
    void setCurrentPosition(OrdinalNumber line, OrdinalNumber columnAftreProlog, int prologLength);

private:
    enum FastPathFlags {
        NoFastPath = 0,
        Use8BitAdvanceAndUpdateLineNumbers = 1 << 0,
        Use8BitAdvance = 1 << 1,
    };

    void append(const SegmentedSubstring&);
    void prepend(const SegmentedSubstring&);

    void advance8();
    void advance16();
    void advanceAndUpdateLineNumber8();
    void advanceAndUpdateLineNumber16();
    void advanceSlowCase();
    void advanceAndUpdateLineNumberSlowCase();
    void advanceEmpty();
    void advanceSubstring();

    void updateSlowCaseFunctionPointers();

    void decrementAndCheckLength()
    {
        ASSERT(m_currentString.m_length > 1);
        if (--m_currentString.m_length == 1)
            updateSlowCaseFunctionPointers();
    }

    void updateAdvanceFunctionPointers()
    {
        if ((m_currentString.m_length > 1) && !m_pushedChar1) {
            if (m_currentString.is8Bit()) {
                m_advanceFunc = &SegmentedString::advance8;
                m_fastPathFlags = Use8BitAdvance;
                if (m_currentString.doNotExcludeLineNumbers()) {
                    m_advanceAndUpdateLineNumberFunc = &SegmentedString::advanceAndUpdateLineNumber8;
                    m_fastPathFlags |= Use8BitAdvanceAndUpdateLineNumbers;
                } else {
                    m_advanceAndUpdateLineNumberFunc = &SegmentedString::advance8;
                }
                return;
            }

            m_advanceFunc = &SegmentedString::advance16;
            m_fastPathFlags = NoFastPath;
            if (m_currentString.doNotExcludeLineNumbers())
                m_advanceAndUpdateLineNumberFunc = &SegmentedString::advanceAndUpdateLineNumber16;
            else
                m_advanceAndUpdateLineNumberFunc = &SegmentedString::advance16;
            return;
        }

        if (!m_currentString.m_length && !isComposite()) {
            m_advanceFunc = &SegmentedString::advanceEmpty;
            m_fastPathFlags = NoFastPath;
            m_advanceAndUpdateLineNumberFunc = &SegmentedString::advanceEmpty;
        }

        updateSlowCaseFunctionPointers();
    }

    inline LookAheadResult lookAheadInline(const String& string, bool caseSensitive)
    {
        if (!m_pushedChar1 && string.length() <= static_cast<unsigned>(m_currentString.m_length)) {
            String currentSubstring = m_currentString.currentSubString(string.length());
            if (currentSubstring.startsWith(string, caseSensitive))
                return DidMatch;
            return DidNotMatch;
        }
        return lookAheadSlowCase(string, caseSensitive);
    }

    LookAheadResult lookAheadSlowCase(const String& string, bool caseSensitive)
    {
        unsigned count = string.length();
        if (count > length())
            return NotEnoughCharacters;
        UChar* consumedCharacters;
        String consumedString = String::createUninitialized(count, consumedCharacters);
        advance(count, consumedCharacters);
        LookAheadResult result = DidNotMatch;
        if (consumedString.startsWith(string, caseSensitive))
            result = DidMatch;
        prepend(SegmentedString(consumedString));
        return result;
    }

    bool isComposite() const { return !m_substrings.isEmpty(); }

    UChar m_pushedChar1;
    UChar m_pushedChar2;
    SegmentedSubstring m_currentString;
    UChar m_currentChar;
    int m_numberOfCharactersConsumedPriorToCurrentString;
    int m_numberOfCharactersConsumedPriorToCurrentLine;
    int m_currentLine;
    Deque<SegmentedSubstring> m_substrings;
    bool m_closed;
    bool m_empty;
    unsigned char m_fastPathFlags;
    void (SegmentedString::*m_advanceFunc)();
    void (SegmentedString::*m_advanceAndUpdateLineNumberFunc)();
};

}

#endif
