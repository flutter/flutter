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

#ifndef UnicodeRange_h
#define UnicodeRange_h

#include "platform/PlatformExport.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

// The following constants define unicode subranges
// values below cRangeNum must be continuous so that we can map to
// a lang group directly.
// All ranges we care about should fit within 32 bits.

// Frequently used range definitions
const unsigned char   cRangeCyrillic =    0;
const unsigned char   cRangeGreek    =    1;
const unsigned char   cRangeTurkish  =    2;
const unsigned char   cRangeHebrew   =    3;
const unsigned char   cRangeArabic   =    4;
const unsigned char   cRangeBaltic   =    5;
const unsigned char   cRangeThai     =    6;
const unsigned char   cRangeKorean   =    7;
const unsigned char   cRangeJapanese =    8;
const unsigned char   cRangeSChinese =    9;
const unsigned char   cRangeTChinese =   10;
const unsigned char   cRangeDevanagari = 11;
const unsigned char   cRangeTamil    =   12;
const unsigned char   cRangeArmenian =   13;
const unsigned char   cRangeBengali  =   14;
const unsigned char   cRangeCanadian =   15;
const unsigned char   cRangeEthiopic =   16;
const unsigned char   cRangeGeorgian =   17;
const unsigned char   cRangeGujarati =   18;
const unsigned char   cRangeGurmukhi =   19;
const unsigned char   cRangeKhmer    =   20;
const unsigned char   cRangeMalayalam =  21;

const unsigned char   cRangeSpecificItemNum = 22;

// range/rangeSet grow to this place 22-29

const unsigned char   cRangeSetStart  =  30; // range set definition starts from here
const unsigned char   cRangeSetLatin  =  30;
const unsigned char   cRangeSetCJK    =  31;
const unsigned char   cRangeSetEnd    =  31; // range set definition ends here

// less frequently used range definition
const unsigned char   cRangeSurrogate            = 32;
const unsigned char   cRangePrivate              = 33;
const unsigned char   cRangeMisc                 = 34;
const unsigned char   cRangeUnassigned           = 35;
const unsigned char   cRangeSyriac               = 36;
const unsigned char   cRangeThaana               = 37;
const unsigned char   cRangeOriya                = 38;
const unsigned char   cRangeTelugu               = 39;
const unsigned char   cRangeKannada              = 40;
const unsigned char   cRangeSinhala              = 41;
const unsigned char   cRangeLao                  = 42;
const unsigned char   cRangeTibetan              = 43;
const unsigned char   cRangeMyanmar              = 44;
const unsigned char   cRangeCherokee             = 45;
const unsigned char   cRangeOghamRunic           = 46;
const unsigned char   cRangeMongolian            = 47;
const unsigned char   cRangeMathOperators        = 48;
const unsigned char   cRangeMiscTechnical        = 49;
const unsigned char   cRangeControlOpticalEnclose = 50;
const unsigned char   cRangeBoxBlockGeometrics   = 51;
const unsigned char   cRangeMiscSymbols          = 52;
const unsigned char   cRangeDingbats             = 53;
const unsigned char   cRangeBraillePattern       = 54;
const unsigned char   cRangeYi                   = 55;
const unsigned char   cRangeCombiningDiacriticalMarks = 56;
const unsigned char   cRangeSpecials             = 57;

const unsigned char   cRangeTableBase   = 128; // values over 127 are reserved for internal use only
const unsigned char   cRangeTertiaryTable  = 145; // leave room for 16 subtable indices (cRangeTableBase + 1 .. cRangeTableBase + 16)



PLATFORM_EXPORT unsigned findCharUnicodeRange(UChar32);
PLATFORM_EXPORT const char* langGroupFromUnicodeRange(unsigned char unicodeRange);

}

#endif // UnicodeRange_h
