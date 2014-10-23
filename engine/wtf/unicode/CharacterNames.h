/*
 * Copyright (C) 2007, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef CharacterNames_h
#define CharacterNames_h

#include "wtf/unicode/Unicode.h"

namespace WTF {
namespace Unicode {

// Names here are taken from the Unicode standard.

// Most of these are UChar constants, not UChar32, which makes them
// more convenient for WebCore code that mostly uses UTF-16.

const UChar32 aegeanWordSeparatorLine = 0x10100;
const UChar32 aegeanWordSeparatorDot = 0x10101;
const UChar blackCircle = 0x25CF;
const UChar blackSquare = 0x25A0;
const UChar blackUpPointingTriangle = 0x25B2;
const UChar bullet = 0x2022;
const UChar bullseye = 0x25CE;
const UChar carriageReturn = 0x000D;
const UChar characterTabulation = 0x0009;
const UChar ethiopicPrefaceColon = 0x1366;
const UChar ethiopicWordspace = 0x1361;
const UChar fisheye = 0x25C9;
const UChar hebrewPunctuationGeresh = 0x05F3;
const UChar hebrewPunctuationGershayim = 0x05F4;
const UChar HiraganaLetterSmallA = 0x3041;
const UChar horizontalEllipsis = 0x2026;
const UChar hyphen = 0x2010;
const UChar hyphenMinus = 0x002D;
const UChar ideographicComma = 0x3001;
const UChar ideographicFullStop = 0x3002;
const UChar ideographicSpace = 0x3000;
const UChar leftDoubleQuotationMark = 0x201C;
const UChar leftSingleQuotationMark = 0x2018;
const UChar leftToRightEmbed = 0x202A;
const UChar leftToRightMark = 0x200E;
const UChar leftToRightOverride = 0x202D;
const UChar minusSign = 0x2212;
const UChar newlineCharacter = 0x000A;
const UChar noBreakSpace = 0x00A0;
const UChar objectReplacementCharacter = 0xFFFC;
const UChar popDirectionalFormatting = 0x202C;
const UChar replacementCharacter = 0xFFFD;
const UChar rightDoubleQuotationMark = 0x201D;
const UChar rightSingleQuotationMark = 0x2019;
const UChar rightToLeftEmbed = 0x202B;
const UChar rightToLeftMark = 0x200F;
const UChar rightToLeftOverride = 0x202E;
const UChar sesameDot = 0xFE45;
const UChar smallLetterSharpS = 0x00DF;
const UChar softHyphen = 0x00AD;
const UChar space = 0x0020;
const UChar tibetanMarkIntersyllabicTsheg = 0x0F0B;
const UChar tibetanMarkDelimiterTshegBstar = 0x0F0C;
const UChar32 ugariticWordDivider = 0x1039F;
const UChar whiteBullet = 0x25E6;
const UChar whiteCircle = 0x25CB;
const UChar whiteSesameDot = 0xFE46;
const UChar whiteUpPointingTriangle = 0x25B3;
const UChar yenSign = 0x00A5;
const UChar zeroWidthJoiner = 0x200D;
const UChar zeroWidthNonJoiner = 0x200C;
const UChar zeroWidthSpace = 0x200B;
const UChar zeroWidthNoBreakSpace = 0xFEFF;

} // namespace Unicode
} // namespace WTF

using WTF::Unicode::aegeanWordSeparatorLine;
using WTF::Unicode::aegeanWordSeparatorDot;
using WTF::Unicode::blackCircle;
using WTF::Unicode::blackSquare;
using WTF::Unicode::blackUpPointingTriangle;
using WTF::Unicode::bullet;
using WTF::Unicode::bullseye;
using WTF::Unicode::carriageReturn;
using WTF::Unicode::characterTabulation;
using WTF::Unicode::ethiopicPrefaceColon;
using WTF::Unicode::ethiopicWordspace;
using WTF::Unicode::fisheye;
using WTF::Unicode::hebrewPunctuationGeresh;
using WTF::Unicode::hebrewPunctuationGershayim;
using WTF::Unicode::HiraganaLetterSmallA;
using WTF::Unicode::horizontalEllipsis;
using WTF::Unicode::hyphen;
using WTF::Unicode::hyphenMinus;
using WTF::Unicode::ideographicComma;
using WTF::Unicode::ideographicFullStop;
using WTF::Unicode::ideographicSpace;
using WTF::Unicode::leftDoubleQuotationMark;
using WTF::Unicode::leftSingleQuotationMark;
using WTF::Unicode::leftToRightEmbed;
using WTF::Unicode::leftToRightMark;
using WTF::Unicode::leftToRightOverride;
using WTF::Unicode::minusSign;
using WTF::Unicode::newlineCharacter;
using WTF::Unicode::noBreakSpace;
using WTF::Unicode::objectReplacementCharacter;
using WTF::Unicode::popDirectionalFormatting;
using WTF::Unicode::replacementCharacter;
using WTF::Unicode::rightDoubleQuotationMark;
using WTF::Unicode::rightSingleQuotationMark;
using WTF::Unicode::rightToLeftEmbed;
using WTF::Unicode::rightToLeftMark;
using WTF::Unicode::rightToLeftOverride;
using WTF::Unicode::sesameDot;
using WTF::Unicode::softHyphen;
using WTF::Unicode::space;
using WTF::Unicode::tibetanMarkIntersyllabicTsheg;
using WTF::Unicode::tibetanMarkDelimiterTshegBstar;
using WTF::Unicode::ugariticWordDivider;
using WTF::Unicode::whiteBullet;
using WTF::Unicode::whiteCircle;
using WTF::Unicode::whiteSesameDot;
using WTF::Unicode::whiteUpPointingTriangle;
using WTF::Unicode::yenSign;
using WTF::Unicode::zeroWidthJoiner;
using WTF::Unicode::zeroWidthNonJoiner;
using WTF::Unicode::zeroWidthSpace;
using WTF::Unicode::zeroWidthNoBreakSpace;

#endif // CharacterNames_h
