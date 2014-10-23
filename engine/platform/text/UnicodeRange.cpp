/*
 * Copyright (C) 2007 Apple Computer, Inc.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "config.h"
#include "platform/text/UnicodeRange.h"

namespace blink {

// This table depends on unicode range definitions.
// Each item's index must correspond to a unicode range value
// eg. x-cyrillic = LangGroupTable[cRangeCyrillic]
static const char* const gUnicodeRangeToLangGroupTable[] =
{
  "x-cyrillic",
  "el",
  "tr",
  "he",
  "ar",
  "x-baltic",
  "th",
  "ko",
  "ja",
  "zh-CN",
  "zh-TW",
  "x-devanagari",
  "x-tamil",
  "x-armn",
  "x-beng",
  "x-cans",
  "x-ethi",
  "x-geor",
  "x-gujr",
  "x-guru",
  "x-khmr",
  "x-mlym"
};

/**********************************************************************
 * Unicode subranges as defined in unicode 3.0
 * x-western, x-central-euro, tr, x-baltic  -> latin
 *  0000 - 036f
 *  1e00 - 1eff
 *  2000 - 206f  (general punctuation)
 *  20a0 - 20cf  (currency symbols)
 *  2100 - 214f  (letterlike symbols)
 *  2150 - 218f  (Number Forms)
 * el         -> greek
 *  0370 - 03ff
 *  1f00 - 1fff
 * x-cyrillic -> cyrillic
 *  0400 - 04ff
 * he         -> hebrew
 *  0590 - 05ff
 * ar         -> arabic
 *  0600 - 06ff
 *  fb50 - fdff (arabic presentation forms)
 *  fe70 - feff (arabic presentation forms b)
 * th - thai
 *  0e00 - 0e7f
 * ko        -> korean
 *  ac00 - d7af  (hangul Syllables)
 *  1100 - 11ff    (jamo)
 *  3130 - 318f (hangul compatibility jamo)
 * ja
 *  3040 - 309f (hiragana)
 *  30a0 - 30ff (katakana)
 * zh-CN
 * zh-TW
 *
 * CJK
 *  3100 - 312f (bopomofo)
 *  31a0 - 31bf (bopomofo extended)
 *  3000 - 303f (CJK Symbols and Punctuation)
 *  2e80 - 2eff (CJK radicals supplement)
 *  2f00 - 2fdf (Kangxi Radicals)
 *  2ff0 - 2fff (Ideographic Description Characters)
 *  3190 - 319f (kanbun)
 *  3200 - 32ff (Enclosed CJK letters and Months)
 *  3300 - 33ff (CJK compatibility)
 *  3400 - 4dbf (CJK Unified Ideographs Extension A)
 *  4e00 - 9faf (CJK Unified Ideographs)
 *  f900 - fa5f (CJK Compatibility Ideographs)
 *  fe30 - fe4f (CJK compatibility Forms)
 *  ff00 - ffef (halfwidth and fullwidth forms)
 *
 * Armenian
 *  0530 - 058f
 * Sriac
 *  0700 - 074f
 * Thaana
 *  0780 - 07bf
 * Devanagari
 *  0900 - 097f
 * Bengali
 *  0980 - 09ff
 * Gurmukhi
 *  0a00 - 0a7f
 * Gujarati
 *  0a80 - 0aff
 * Oriya
 *  0b00 - 0b7f
 * Tamil
 *  0b80 - 0bff
 * Telugu
 *  0c00 - 0c7f
 * Kannada
 *  0c80 - 0cff
 * Malayalam
 *  0d00 - 0d7f
 * Sinhala
 *  0d80 - 0def
 * Lao
 *  0e80 - 0eff
 * Tibetan
 *  0f00 - 0fbf
 * Myanmar
 *  1000 - 109f
 * Georgian
 *  10a0 - 10ff
 * Ethiopic
 *  1200 - 137f
 * Cherokee
 *  13a0 - 13ff
 * Canadian Aboriginal Syllabics
 *  1400 - 167f
 * Ogham
 *  1680 - 169f
 * Runic
 *  16a0 - 16ff
 * Khmer
 *  1780 - 17ff
 * Mongolian
 *  1800 - 18af
 * Misc - superscripts and subscripts
 *  2070 - 209f
 * Misc - Combining Diacritical Marks for Symbols
 *  20d0 - 20ff
 * Misc - Arrows
 *  2190 - 21ff
 * Misc - Mathematical Operators
 *  2200 - 22ff
 * Misc - Miscellaneous Technical
 *  2300 - 23ff
 * Misc - Control picture
 *  2400 - 243f
 * Misc - Optical character recognition
 *  2440 - 2450
 * Misc - Enclose Alphanumerics
 *  2460 - 24ff
 * Misc - Box Drawing
 *  2500 - 257f
 * Misc - Block Elements
 *  2580 - 259f
 * Misc - Geometric Shapes
 *  25a0 - 25ff
 * Misc - Miscellaneous Symbols
 *  2600 - 267f
 * Misc - Dingbats
 *  2700 - 27bf
 * Misc - Braille Patterns
 *  2800 - 28ff
 * Yi Syllables
 *  a000 - a48f
 * Yi radicals
 *  a490 - a4cf
 * Alphabetic Presentation Forms
 *  fb00 - fb4f
 * Misc - Combining half Marks
 *  fe20 - fe2f
 * Misc - small form variants
 *  fe50 - fe6f
 * Misc - Specials
 *  fff0 - ffff
 *********************************************************************/

static const unsigned cNumSubTables = 9;
static const unsigned cSubTableSize = 16;

static const unsigned char gUnicodeSubrangeTable[cNumSubTables][cSubTableSize] =
{
  { // table for X---
    cRangeTableBase+1,  //u0xxx
    cRangeTableBase+2,  //u1xxx
    cRangeTableBase+3,  //u2xxx
    cRangeSetCJK,       //u3xxx
    cRangeSetCJK,       //u4xxx
    cRangeSetCJK,       //u5xxx
    cRangeSetCJK,       //u6xxx
    cRangeSetCJK,       //u7xxx
    cRangeSetCJK,       //u8xxx
    cRangeSetCJK,       //u9xxx
    cRangeTableBase+4,  //uaxxx
    cRangeKorean,       //ubxxx
    cRangeKorean,       //ucxxx
    cRangeTableBase+5,  //udxxx
    cRangePrivate,      //uexxx
    cRangeTableBase+6   //ufxxx
  },
  { //table for 0X--
    cRangeSetLatin,          //u00xx
    cRangeSetLatin,          //u01xx
    cRangeSetLatin,          //u02xx
    cRangeGreek,             //u03xx     XXX 0300-036f is in fact cRangeCombiningDiacriticalMarks
    cRangeCyrillic,          //u04xx
    cRangeTableBase+7,       //u05xx, includes Cyrillic supplement, Hebrew, and Armenian
    cRangeArabic,            //u06xx
    cRangeTertiaryTable,     //u07xx
    cRangeUnassigned,        //u08xx
    cRangeTertiaryTable,     //u09xx
    cRangeTertiaryTable,     //u0axx
    cRangeTertiaryTable,     //u0bxx
    cRangeTertiaryTable,     //u0cxx
    cRangeTertiaryTable,     //u0dxx
    cRangeTertiaryTable,     //u0exx
    cRangeTibetan,           //u0fxx
  },
  { //table for 1x--
    cRangeTertiaryTable,     //u10xx
    cRangeKorean,            //u11xx
    cRangeEthiopic,          //u12xx
    cRangeTertiaryTable,     //u13xx
    cRangeCanadian,          //u14xx
    cRangeCanadian,          //u15xx
    cRangeTertiaryTable,     //u16xx
    cRangeKhmer,             //u17xx
    cRangeMongolian,         //u18xx
    cRangeUnassigned,        //u19xx
    cRangeUnassigned,        //u1axx
    cRangeUnassigned,        //u1bxx
    cRangeUnassigned,        //u1cxx
    cRangeUnassigned,        //u1dxx
    cRangeSetLatin,          //u1exx
    cRangeGreek,             //u1fxx
  },
  { //table for 2x--
    cRangeSetLatin,          //u20xx
    cRangeSetLatin,          //u21xx
    cRangeMathOperators,     //u22xx
    cRangeMiscTechnical,     //u23xx
    cRangeControlOpticalEnclose, //u24xx
    cRangeBoxBlockGeometrics, //u25xx
    cRangeMiscSymbols,       //u26xx
    cRangeDingbats,          //u27xx
    cRangeBraillePattern,    //u28xx
    cRangeUnassigned,        //u29xx
    cRangeUnassigned,        //u2axx
    cRangeUnassigned,        //u2bxx
    cRangeUnassigned,        //u2cxx
    cRangeUnassigned,        //u2dxx
    cRangeSetCJK,            //u2exx
    cRangeSetCJK,            //u2fxx
  },
  {  //table for ax--
    cRangeYi,                //ua0xx
    cRangeYi,                //ua1xx
    cRangeYi,                //ua2xx
    cRangeYi,                //ua3xx
    cRangeYi,                //ua4xx
    cRangeUnassigned,        //ua5xx
    cRangeUnassigned,        //ua6xx
    cRangeUnassigned,        //ua7xx
    cRangeUnassigned,        //ua8xx
    cRangeUnassigned,        //ua9xx
    cRangeUnassigned,        //uaaxx
    cRangeUnassigned,        //uabxx
    cRangeKorean,            //uacxx
    cRangeKorean,            //uadxx
    cRangeKorean,            //uaexx
    cRangeKorean,            //uafxx
  },
  {  //table for dx--
    cRangeKorean,            //ud0xx
    cRangeKorean,            //ud1xx
    cRangeKorean,            //ud2xx
    cRangeKorean,            //ud3xx
    cRangeKorean,            //ud4xx
    cRangeKorean,            //ud5xx
    cRangeKorean,            //ud6xx
    cRangeKorean,            //ud7xx
    cRangeSurrogate,         //ud8xx
    cRangeSurrogate,         //ud9xx
    cRangeSurrogate,         //udaxx
    cRangeSurrogate,         //udbxx
    cRangeSurrogate,         //udcxx
    cRangeSurrogate,         //uddxx
    cRangeSurrogate,         //udexx
    cRangeSurrogate,         //udfxx
  },
  { // table for fx--
    cRangePrivate,           //uf0xx
    cRangePrivate,           //uf1xx
    cRangePrivate,           //uf2xx
    cRangePrivate,           //uf3xx
    cRangePrivate,           //uf4xx
    cRangePrivate,           //uf5xx
    cRangePrivate,           //uf6xx
    cRangePrivate,           //uf7xx
    cRangePrivate,           //uf8xx
    cRangeSetCJK,            //uf9xx
    cRangeSetCJK,            //ufaxx
    cRangeArabic,            //ufbxx, includes alphabic presentation form
    cRangeArabic,            //ufcxx
    cRangeArabic,            //ufdxx
    cRangeArabic,            //ufexx, includes Combining half marks,
                             //                CJK compatibility forms,
                             //                CJK compatibility forms,
                             //                small form variants
    cRangeTableBase+8,       //uffxx, halfwidth and fullwidth forms, includes Specials
  },
  { //table for 0x0500 - 0x05ff
    cRangeCyrillic,          //u050x
    cRangeCyrillic,          //u051x
    cRangeCyrillic,          //u052x
    cRangeArmenian,          //u053x
    cRangeArmenian,          //u054x
    cRangeArmenian,          //u055x
    cRangeArmenian,          //u056x
    cRangeArmenian,          //u057x
    cRangeArmenian,          //u058x
    cRangeHebrew,            //u059x
    cRangeHebrew,            //u05ax
    cRangeHebrew,            //u05bx
    cRangeHebrew,            //u05cx
    cRangeHebrew,            //u05dx
    cRangeHebrew,            //u05ex
    cRangeHebrew,            //u05fx
  },
  { //table for 0xff00 - 0xffff
    cRangeSetCJK,            //uff0x, fullwidth latin
    cRangeSetCJK,            //uff1x, fullwidth latin
    cRangeSetCJK,            //uff2x, fullwidth latin
    cRangeSetCJK,            //uff3x, fullwidth latin
    cRangeSetCJK,            //uff4x, fullwidth latin
    cRangeSetCJK,            //uff5x, fullwidth latin
    cRangeSetCJK,            //uff6x, halfwidth katakana
    cRangeSetCJK,            //uff7x, halfwidth katakana
    cRangeSetCJK,            //uff8x, halfwidth katakana
    cRangeSetCJK,            //uff9x, halfwidth katakana
    cRangeSetCJK,            //uffax, halfwidth hangul jamo
    cRangeSetCJK,            //uffbx, halfwidth hangul jamo
    cRangeSetCJK,            //uffcx, halfwidth hangul jamo
    cRangeSetCJK,            //uffdx, halfwidth hangul jamo
    cRangeSetCJK,            //uffex, fullwidth symbols
    cRangeSpecials,          //ufffx, Specials
  },
};

// Most scripts between U+0700 and U+16FF are assigned a chunk of 128 (0x80)
// code points so that the number of entries in the tertiary range
// table for that range is obtained by dividing (0x1700 - 0x0700) by 128.
// Exceptions: Ethiopic, Tibetan, Hangul Jamo and Canadian aboriginal
// syllabaries take multiple chunks and Ogham and Runic share a single chunk.
static const unsigned cTertiaryTableSize = ((0x1700 - 0x0700) / 0x80);

static const unsigned char gUnicodeTertiaryRangeTable[cTertiaryTableSize] =
{ //table for 0x0700 - 0x1600
    cRangeSyriac,            //u070x
    cRangeThaana,            //u078x
    cRangeUnassigned,        //u080x  place holder(resolved in the 2ndary tab.)
    cRangeUnassigned,        //u088x  place holder(resolved in the 2ndary tab.)
    cRangeDevanagari,        //u090x
    cRangeBengali,           //u098x
    cRangeGurmukhi,          //u0a0x
    cRangeGujarati,          //u0a8x
    cRangeOriya,             //u0b0x
    cRangeTamil,             //u0b8x
    cRangeTelugu,            //u0c0x
    cRangeKannada,           //u0c8x
    cRangeMalayalam,         //u0d0x
    cRangeSinhala,           //u0d8x
    cRangeThai,              //u0e0x
    cRangeLao,               //u0e8x
    cRangeTibetan,           //u0f0x  place holder(resolved in the 2ndary tab.)
    cRangeTibetan,           //u0f8x  place holder(resolved in the 2ndary tab.)
    cRangeMyanmar,           //u100x
    cRangeGeorgian,          //u108x
    cRangeKorean,            //u110x  place holder(resolved in the 2ndary tab.)
    cRangeKorean,            //u118x  place holder(resolved in the 2ndary tab.)
    cRangeEthiopic,          //u120x  place holder(resolved in the 2ndary tab.)
    cRangeEthiopic,          //u128x  place holder(resolved in the 2ndary tab.)
    cRangeEthiopic,          //u130x
    cRangeCherokee,          //u138x
    cRangeCanadian,          //u140x  place holder(resolved in the 2ndary tab.)
    cRangeCanadian,          //u148x  place holder(resolved in the 2ndary tab.)
    cRangeCanadian,          //u150x  place holder(resolved in the 2ndary tab.)
    cRangeCanadian,          //u158x  place holder(resolved in the 2ndary tab.)
    cRangeCanadian,          //u160x
    cRangeOghamRunic,        //u168x  this contains two scripts, Ogham & Runic
};

// A two level index is almost enough for locating a range, with the
// exception of u03xx and u05xx. Since we don't really care about range for
// combining diacritical marks in our font application, they are
// not discriminated further.  Future adoption of this method for other use
// should be aware of this limitation. The implementation can be extended if
// there is such a need.
// For Indic, Southeast Asian scripts and some other scripts between
// U+0700 and U+16FF, it's extended to the third level.
unsigned findCharUnicodeRange(UChar32 ch)
{
    if (ch >= 0xFFFF)
        return 0;

    unsigned range;

    //search the first table
    range = gUnicodeSubrangeTable[0][ch >> 12];

    if (range < cRangeTableBase)
        // we try to get a specific range
        return range;

    // otherwise, we have one more table to look at
    range = gUnicodeSubrangeTable[range - cRangeTableBase][(ch & 0x0f00) >> 8];
    if (range < cRangeTableBase)
        return range;
    if (range < cRangeTertiaryTable)
        return gUnicodeSubrangeTable[range - cRangeTableBase][(ch & 0x00f0) >> 4];

    // Yet another table to look at : U+0700 - U+16FF : 128 code point blocks
    return gUnicodeTertiaryRangeTable[(ch - 0x0700) >> 7];
}

const char* langGroupFromUnicodeRange(unsigned char unicodeRange)
{
    if (cRangeSpecificItemNum > unicodeRange)
        return gUnicodeRangeToLangGroupTable[unicodeRange];
    return 0;
}

}
