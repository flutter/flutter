/*
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SurrogatePairAwareTextIterator_h
#define SurrogatePairAwareTextIterator_h

#include "platform/PlatformExport.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/CharacterNames.h"

namespace blink {

class PLATFORM_EXPORT SurrogatePairAwareTextIterator {
public:
    // The passed in UChar pointer starts at 'currentCharacter'. The iterator operatoes on the range [currentCharacter, lastCharacter].
    // 'endCharacter' denotes the maximum length of the UChar array, which might exceed 'lastCharacter'.
    SurrogatePairAwareTextIterator(const UChar*, int currentCharacter, int lastCharacter, int endCharacter);

    inline bool consume(UChar32& character, unsigned& clusterLength)
    {
        if (m_currentCharacter >= m_lastCharacter)
            return false;

        character = *m_characters;
        clusterLength = 1;

        if (character < HiraganaLetterSmallA)
            return true;

        return consumeSlowCase(character, clusterLength);
    }

    void advance(unsigned advanceLength)
    {
        m_characters += advanceLength;
        m_currentCharacter += advanceLength;
    }

    int currentCharacter() const { return m_currentCharacter; }
    const UChar* characters() const { return m_characters; }

private:
    bool consumeSlowCase(UChar32&, unsigned&);
    UChar32 normalizeVoicingMarks();

    const UChar* m_characters;
    int m_currentCharacter;
    int m_lastCharacter;
    int m_endCharacter;
};

}

#endif
