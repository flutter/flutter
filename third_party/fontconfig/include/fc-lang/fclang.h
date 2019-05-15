/*
 * fontconfig/fc-lang/fclang.tmpl.h
 *
 * Copyright © 2002 Keith Packard
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the author(s) not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  The authors make no
 * representations about the suitability of this software for any purpose.  It
 * is provided "as is" without express or implied warranty.
 *
 * THE AUTHOR(S) DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 * EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
 * DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

/* total size: 1111 unique leaves: 725 */

#define LEAF0       (246 * sizeof (FcLangCharSet))
#define OFF0        (LEAF0 + 725 * sizeof (FcCharLeaf))
#define NUM0        (OFF0 + 779 * sizeof (uintptr_t))
#define SET(n)      (n * sizeof (FcLangCharSet) + offsetof (FcLangCharSet, charset))
#define OFF(s,o)    (OFF0 + o * sizeof (uintptr_t) - SET(s))
#define NUM(s,n)    (NUM0 + n * sizeof (FcChar16) - SET(s))
#define LEAF(o,l)   (LEAF0 + l * sizeof (FcCharLeaf) - (OFF0 + o * sizeof (intptr_t)))
#define fcLangCharSets (fcLangData.langCharSets)
#define fcLangCharSetIndices (fcLangData.langIndices)
#define fcLangCharSetIndicesInv (fcLangData.langIndicesInv)

static const struct {
    FcLangCharSet  langCharSets[246];
    FcCharLeaf     leaves[725];
    uintptr_t      leaf_offsets[779];
    FcChar16       numbers[779];
    FcChar8        langIndices[246];
    FcChar8        langIndicesInv[246];
} fcLangData = {
{
    { "aa",  { FC_REF_CONSTANT, 1, OFF(0,0), NUM(0,0) } }, /* 0 */
    { "ab",  { FC_REF_CONSTANT, 1, OFF(1,1), NUM(1,1) } }, /* 1 */
    { "af",  { FC_REF_CONSTANT, 2, OFF(2,2), NUM(2,2) } }, /* 2 */
    { "ak",  { FC_REF_CONSTANT, 5, OFF(3,4), NUM(3,4) } }, /* 3 */
    { "am",  { FC_REF_CONSTANT, 2, OFF(4,9), NUM(4,9) } }, /* 4 */
    { "an",  { FC_REF_CONSTANT, 1, OFF(5,11), NUM(5,11) } }, /* 5 */
    { "ar",  { FC_REF_CONSTANT, 1, OFF(6,12), NUM(6,12) } }, /* 6 */
    { "as",  { FC_REF_CONSTANT, 1, OFF(7,13), NUM(7,13) } }, /* 7 */
    { "ast",  { FC_REF_CONSTANT, 2, OFF(8,14), NUM(8,14) } }, /* 8 */
    { "av",  { FC_REF_CONSTANT, 1, OFF(9,16), NUM(9,16) } }, /* 9 */
    { "ay",  { FC_REF_CONSTANT, 1, OFF(10,17), NUM(10,17) } }, /* 10 */
    { "az-az",  { FC_REF_CONSTANT, 3, OFF(11,18), NUM(11,18) } }, /* 11 */
    { "az-ir",  { FC_REF_CONSTANT, 1, OFF(12,21), NUM(12,21) } }, /* 12 */
    { "ba",  { FC_REF_CONSTANT, 1, OFF(13,22), NUM(13,22) } }, /* 13 */
    { "be",  { FC_REF_CONSTANT, 1, OFF(14,23), NUM(14,23) } }, /* 14 */
    { "ber-dz",  { FC_REF_CONSTANT, 4, OFF(15,24), NUM(15,24) } }, /* 15 */
    { "ber-ma",  { FC_REF_CONSTANT, 1, OFF(16,28), NUM(16,28) } }, /* 16 */
    { "bg",  { FC_REF_CONSTANT, 1, OFF(17,29), NUM(17,29) } }, /* 17 */
    { "bh",  { FC_REF_CONSTANT, 1, OFF(18,30), NUM(18,30) } }, /* 18 */
    { "bho",  { FC_REF_CONSTANT, 1, OFF(19,30), NUM(19,30) } }, /* 19 */
    { "bi",  { FC_REF_CONSTANT, 1, OFF(20,31), NUM(20,31) } }, /* 20 */
    { "bin",  { FC_REF_CONSTANT, 3, OFF(21,32), NUM(21,32) } }, /* 21 */
    { "bm",  { FC_REF_CONSTANT, 3, OFF(22,35), NUM(22,35) } }, /* 22 */
    { "bn",  { FC_REF_CONSTANT, 1, OFF(23,38), NUM(23,38) } }, /* 23 */
    { "bo",  { FC_REF_CONSTANT, 1, OFF(24,39), NUM(24,39) } }, /* 24 */
    { "br",  { FC_REF_CONSTANT, 1, OFF(25,40), NUM(25,40) } }, /* 25 */
    { "brx",  { FC_REF_CONSTANT, 1, OFF(26,41), NUM(26,41) } }, /* 26 */
    { "bs",  { FC_REF_CONSTANT, 2, OFF(27,42), NUM(27,42) } }, /* 27 */
    { "bua",  { FC_REF_CONSTANT, 1, OFF(28,44), NUM(28,44) } }, /* 28 */
    { "byn",  { FC_REF_CONSTANT, 2, OFF(29,45), NUM(29,45) } }, /* 29 */
    { "ca",  { FC_REF_CONSTANT, 2, OFF(30,47), NUM(30,47) } }, /* 30 */
    { "ce",  { FC_REF_CONSTANT, 1, OFF(31,16), NUM(31,16) } }, /* 31 */
    { "ch",  { FC_REF_CONSTANT, 1, OFF(32,49), NUM(32,49) } }, /* 32 */
    { "chm",  { FC_REF_CONSTANT, 1, OFF(33,50), NUM(33,50) } }, /* 33 */
    { "chr",  { FC_REF_CONSTANT, 1, OFF(34,51), NUM(34,51) } }, /* 34 */
    { "co",  { FC_REF_CONSTANT, 2, OFF(35,52), NUM(35,52) } }, /* 35 */
    { "crh",  { FC_REF_CONSTANT, 2, OFF(36,54), NUM(36,54) } }, /* 36 */
    { "cs",  { FC_REF_CONSTANT, 2, OFF(37,56), NUM(37,56) } }, /* 37 */
    { "csb",  { FC_REF_CONSTANT, 2, OFF(38,58), NUM(38,58) } }, /* 38 */
    { "cu",  { FC_REF_CONSTANT, 1, OFF(39,60), NUM(39,60) } }, /* 39 */
    { "cv",  { FC_REF_CONSTANT, 2, OFF(40,61), NUM(40,61) } }, /* 40 */
    { "cy",  { FC_REF_CONSTANT, 3, OFF(41,63), NUM(41,63) } }, /* 41 */
    { "da",  { FC_REF_CONSTANT, 1, OFF(42,66), NUM(42,66) } }, /* 42 */
    { "de",  { FC_REF_CONSTANT, 1, OFF(43,67), NUM(43,67) } }, /* 43 */
    { "doi",  { FC_REF_CONSTANT, 1, OFF(44,68), NUM(44,68) } }, /* 44 */
    { "dv",  { FC_REF_CONSTANT, 1, OFF(45,69), NUM(45,69) } }, /* 45 */
    { "dz",  { FC_REF_CONSTANT, 1, OFF(46,39), NUM(46,39) } }, /* 46 */
    { "ee",  { FC_REF_CONSTANT, 4, OFF(47,70), NUM(47,70) } }, /* 47 */
    { "el",  { FC_REF_CONSTANT, 1, OFF(48,74), NUM(48,74) } }, /* 48 */
    { "en",  { FC_REF_CONSTANT, 1, OFF(49,75), NUM(49,75) } }, /* 49 */
    { "eo",  { FC_REF_CONSTANT, 2, OFF(50,76), NUM(50,76) } }, /* 50 */
    { "es",  { FC_REF_CONSTANT, 1, OFF(51,11), NUM(51,11) } }, /* 51 */
    { "et",  { FC_REF_CONSTANT, 2, OFF(52,78), NUM(52,78) } }, /* 52 */
    { "eu",  { FC_REF_CONSTANT, 1, OFF(53,80), NUM(53,80) } }, /* 53 */
    { "fa",  { FC_REF_CONSTANT, 1, OFF(54,21), NUM(54,21) } }, /* 54 */
    { "fat",  { FC_REF_CONSTANT, 5, OFF(55,4), NUM(55,4) } }, /* 55 */
    { "ff",  { FC_REF_CONSTANT, 3, OFF(56,81), NUM(56,81) } }, /* 56 */
    { "fi",  { FC_REF_CONSTANT, 2, OFF(57,84), NUM(57,84) } }, /* 57 */
    { "fil",  { FC_REF_CONSTANT, 1, OFF(58,86), NUM(58,86) } }, /* 58 */
    { "fj",  { FC_REF_CONSTANT, 1, OFF(59,87), NUM(59,87) } }, /* 59 */
    { "fo",  { FC_REF_CONSTANT, 1, OFF(60,88), NUM(60,88) } }, /* 60 */
    { "fr",  { FC_REF_CONSTANT, 2, OFF(61,52), NUM(61,52) } }, /* 61 */
    { "fur",  { FC_REF_CONSTANT, 1, OFF(62,89), NUM(62,89) } }, /* 62 */
    { "fy",  { FC_REF_CONSTANT, 1, OFF(63,90), NUM(63,90) } }, /* 63 */
    { "ga",  { FC_REF_CONSTANT, 3, OFF(64,91), NUM(64,91) } }, /* 64 */
    { "gd",  { FC_REF_CONSTANT, 1, OFF(65,94), NUM(65,94) } }, /* 65 */
    { "gez",  { FC_REF_CONSTANT, 2, OFF(66,95), NUM(66,95) } }, /* 66 */
    { "gl",  { FC_REF_CONSTANT, 1, OFF(67,11), NUM(67,11) } }, /* 67 */
    { "gn",  { FC_REF_CONSTANT, 3, OFF(68,97), NUM(68,97) } }, /* 68 */
    { "gu",  { FC_REF_CONSTANT, 1, OFF(69,100), NUM(69,100) } }, /* 69 */
    { "gv",  { FC_REF_CONSTANT, 1, OFF(70,101), NUM(70,101) } }, /* 70 */
    { "ha",  { FC_REF_CONSTANT, 3, OFF(71,102), NUM(71,102) } }, /* 71 */
    { "haw",  { FC_REF_CONSTANT, 3, OFF(72,105), NUM(72,105) } }, /* 72 */
    { "he",  { FC_REF_CONSTANT, 1, OFF(73,108), NUM(73,108) } }, /* 73 */
    { "hi",  { FC_REF_CONSTANT, 1, OFF(74,30), NUM(74,30) } }, /* 74 */
    { "hne",  { FC_REF_CONSTANT, 1, OFF(75,30), NUM(75,30) } }, /* 75 */
    { "ho",  { FC_REF_CONSTANT, 1, OFF(76,87), NUM(76,87) } }, /* 76 */
    { "hr",  { FC_REF_CONSTANT, 2, OFF(77,42), NUM(77,42) } }, /* 77 */
    { "hsb",  { FC_REF_CONSTANT, 2, OFF(78,109), NUM(78,109) } }, /* 78 */
    { "ht",  { FC_REF_CONSTANT, 1, OFF(79,111), NUM(79,111) } }, /* 79 */
    { "hu",  { FC_REF_CONSTANT, 2, OFF(80,112), NUM(80,112) } }, /* 80 */
    { "hy",  { FC_REF_CONSTANT, 1, OFF(81,114), NUM(81,114) } }, /* 81 */
    { "hz",  { FC_REF_CONSTANT, 3, OFF(82,115), NUM(82,115) } }, /* 82 */
    { "ia",  { FC_REF_CONSTANT, 1, OFF(83,87), NUM(83,87) } }, /* 83 */
    { "id",  { FC_REF_CONSTANT, 1, OFF(84,118), NUM(84,118) } }, /* 84 */
    { "ie",  { FC_REF_CONSTANT, 1, OFF(85,87), NUM(85,87) } }, /* 85 */
    { "ig",  { FC_REF_CONSTANT, 2, OFF(86,119), NUM(86,119) } }, /* 86 */
    { "ii",  { FC_REF_CONSTANT, 5, OFF(87,121), NUM(87,121) } }, /* 87 */
    { "ik",  { FC_REF_CONSTANT, 1, OFF(88,126), NUM(88,126) } }, /* 88 */
    { "io",  { FC_REF_CONSTANT, 1, OFF(89,87), NUM(89,87) } }, /* 89 */
    { "is",  { FC_REF_CONSTANT, 1, OFF(90,127), NUM(90,127) } }, /* 90 */
    { "it",  { FC_REF_CONSTANT, 1, OFF(91,128), NUM(91,128) } }, /* 91 */
    { "iu",  { FC_REF_CONSTANT, 3, OFF(92,129), NUM(92,129) } }, /* 92 */
    { "ja",  { FC_REF_CONSTANT, 83, OFF(93,132), NUM(93,132) } }, /* 93 */
    { "jv",  { FC_REF_CONSTANT, 1, OFF(94,215), NUM(94,215) } }, /* 94 */
    { "ka",  { FC_REF_CONSTANT, 1, OFF(95,216), NUM(95,216) } }, /* 95 */
    { "kaa",  { FC_REF_CONSTANT, 1, OFF(96,217), NUM(96,217) } }, /* 96 */
    { "kab",  { FC_REF_CONSTANT, 4, OFF(97,24), NUM(97,24) } }, /* 97 */
    { "ki",  { FC_REF_CONSTANT, 2, OFF(98,218), NUM(98,218) } }, /* 98 */
    { "kj",  { FC_REF_CONSTANT, 1, OFF(99,87), NUM(99,87) } }, /* 99 */
    { "kk",  { FC_REF_CONSTANT, 1, OFF(100,220), NUM(100,220) } }, /* 100 */
    { "kl",  { FC_REF_CONSTANT, 2, OFF(101,221), NUM(101,221) } }, /* 101 */
    { "km",  { FC_REF_CONSTANT, 1, OFF(102,223), NUM(102,223) } }, /* 102 */
    { "kn",  { FC_REF_CONSTANT, 1, OFF(103,224), NUM(103,224) } }, /* 103 */
    { "ko",  { FC_REF_CONSTANT, 45, OFF(104,225), NUM(104,225) } }, /* 104 */
    { "kok",  { FC_REF_CONSTANT, 1, OFF(105,30), NUM(105,30) } }, /* 105 */
    { "kr",  { FC_REF_CONSTANT, 3, OFF(106,270), NUM(106,270) } }, /* 106 */
    { "ks",  { FC_REF_CONSTANT, 1, OFF(107,273), NUM(107,273) } }, /* 107 */
    { "ku-am",  { FC_REF_CONSTANT, 2, OFF(108,274), NUM(108,274) } }, /* 108 */
    { "ku-iq",  { FC_REF_CONSTANT, 1, OFF(109,276), NUM(109,276) } }, /* 109 */
    { "ku-ir",  { FC_REF_CONSTANT, 1, OFF(110,276), NUM(110,276) } }, /* 110 */
    { "ku-tr",  { FC_REF_CONSTANT, 2, OFF(111,277), NUM(111,277) } }, /* 111 */
    { "kum",  { FC_REF_CONSTANT, 1, OFF(112,279), NUM(112,279) } }, /* 112 */
    { "kv",  { FC_REF_CONSTANT, 1, OFF(113,280), NUM(113,280) } }, /* 113 */
    { "kw",  { FC_REF_CONSTANT, 3, OFF(114,281), NUM(114,281) } }, /* 114 */
    { "kwm",  { FC_REF_CONSTANT, 1, OFF(115,87), NUM(115,87) } }, /* 115 */
    { "ky",  { FC_REF_CONSTANT, 1, OFF(116,284), NUM(116,284) } }, /* 116 */
    { "la",  { FC_REF_CONSTANT, 2, OFF(117,285), NUM(117,285) } }, /* 117 */
    { "lah",  { FC_REF_CONSTANT, 1, OFF(118,287), NUM(118,287) } }, /* 118 */
    { "lb",  { FC_REF_CONSTANT, 1, OFF(119,288), NUM(119,288) } }, /* 119 */
    { "lez",  { FC_REF_CONSTANT, 1, OFF(120,16), NUM(120,16) } }, /* 120 */
    { "lg",  { FC_REF_CONSTANT, 2, OFF(121,289), NUM(121,289) } }, /* 121 */
    { "li",  { FC_REF_CONSTANT, 1, OFF(122,291), NUM(122,291) } }, /* 122 */
    { "ln",  { FC_REF_CONSTANT, 4, OFF(123,292), NUM(123,292) } }, /* 123 */
    { "lo",  { FC_REF_CONSTANT, 1, OFF(124,296), NUM(124,296) } }, /* 124 */
    { "lt",  { FC_REF_CONSTANT, 2, OFF(125,297), NUM(125,297) } }, /* 125 */
    { "lv",  { FC_REF_CONSTANT, 2, OFF(126,299), NUM(126,299) } }, /* 126 */
    { "mai",  { FC_REF_CONSTANT, 1, OFF(127,30), NUM(127,30) } }, /* 127 */
    { "mg",  { FC_REF_CONSTANT, 1, OFF(128,301), NUM(128,301) } }, /* 128 */
    { "mh",  { FC_REF_CONSTANT, 2, OFF(129,302), NUM(129,302) } }, /* 129 */
    { "mi",  { FC_REF_CONSTANT, 3, OFF(130,304), NUM(130,304) } }, /* 130 */
    { "mk",  { FC_REF_CONSTANT, 1, OFF(131,307), NUM(131,307) } }, /* 131 */
    { "ml",  { FC_REF_CONSTANT, 1, OFF(132,308), NUM(132,308) } }, /* 132 */
    { "mn-cn",  { FC_REF_CONSTANT, 1, OFF(133,309), NUM(133,309) } }, /* 133 */
    { "mn-mn",  { FC_REF_CONSTANT, 1, OFF(134,310), NUM(134,310) } }, /* 134 */
    { "mni",  { FC_REF_CONSTANT, 1, OFF(135,311), NUM(135,311) } }, /* 135 */
    { "mo",  { FC_REF_CONSTANT, 4, OFF(136,312), NUM(136,312) } }, /* 136 */
    { "mr",  { FC_REF_CONSTANT, 1, OFF(137,30), NUM(137,30) } }, /* 137 */
    { "ms",  { FC_REF_CONSTANT, 1, OFF(138,87), NUM(138,87) } }, /* 138 */
    { "mt",  { FC_REF_CONSTANT, 2, OFF(139,316), NUM(139,316) } }, /* 139 */
    { "my",  { FC_REF_CONSTANT, 1, OFF(140,318), NUM(140,318) } }, /* 140 */
    { "na",  { FC_REF_CONSTANT, 2, OFF(141,319), NUM(141,319) } }, /* 141 */
    { "nb",  { FC_REF_CONSTANT, 1, OFF(142,321), NUM(142,321) } }, /* 142 */
    { "nds",  { FC_REF_CONSTANT, 1, OFF(143,67), NUM(143,67) } }, /* 143 */
    { "ne",  { FC_REF_CONSTANT, 1, OFF(144,322), NUM(144,322) } }, /* 144 */
    { "ng",  { FC_REF_CONSTANT, 1, OFF(145,87), NUM(145,87) } }, /* 145 */
    { "nl",  { FC_REF_CONSTANT, 1, OFF(146,323), NUM(146,323) } }, /* 146 */
    { "nn",  { FC_REF_CONSTANT, 1, OFF(147,324), NUM(147,324) } }, /* 147 */
    { "no",  { FC_REF_CONSTANT, 1, OFF(148,321), NUM(148,321) } }, /* 148 */
    { "nqo",  { FC_REF_CONSTANT, 1, OFF(149,325), NUM(149,325) } }, /* 149 */
    { "nr",  { FC_REF_CONSTANT, 1, OFF(150,87), NUM(150,87) } }, /* 150 */
    { "nso",  { FC_REF_CONSTANT, 2, OFF(151,326), NUM(151,326) } }, /* 151 */
    { "nv",  { FC_REF_CONSTANT, 4, OFF(152,328), NUM(152,328) } }, /* 152 */
    { "ny",  { FC_REF_CONSTANT, 2, OFF(153,332), NUM(153,332) } }, /* 153 */
    { "oc",  { FC_REF_CONSTANT, 1, OFF(154,334), NUM(154,334) } }, /* 154 */
    { "om",  { FC_REF_CONSTANT, 1, OFF(155,87), NUM(155,87) } }, /* 155 */
    { "or",  { FC_REF_CONSTANT, 1, OFF(156,335), NUM(156,335) } }, /* 156 */
    { "os",  { FC_REF_CONSTANT, 1, OFF(157,279), NUM(157,279) } }, /* 157 */
    { "ota",  { FC_REF_CONSTANT, 1, OFF(158,336), NUM(158,336) } }, /* 158 */
    { "pa",  { FC_REF_CONSTANT, 1, OFF(159,337), NUM(159,337) } }, /* 159 */
    { "pa-pk",  { FC_REF_CONSTANT, 1, OFF(160,287), NUM(160,287) } }, /* 160 */
    { "pap-an",  { FC_REF_CONSTANT, 1, OFF(161,338), NUM(161,338) } }, /* 161 */
    { "pap-aw",  { FC_REF_CONSTANT, 1, OFF(162,339), NUM(162,339) } }, /* 162 */
    { "pl",  { FC_REF_CONSTANT, 2, OFF(163,340), NUM(163,340) } }, /* 163 */
    { "ps-af",  { FC_REF_CONSTANT, 1, OFF(164,342), NUM(164,342) } }, /* 164 */
    { "ps-pk",  { FC_REF_CONSTANT, 1, OFF(165,343), NUM(165,343) } }, /* 165 */
    { "pt",  { FC_REF_CONSTANT, 1, OFF(166,344), NUM(166,344) } }, /* 166 */
    { "qu",  { FC_REF_CONSTANT, 2, OFF(167,345), NUM(167,345) } }, /* 167 */
    { "quz",  { FC_REF_CONSTANT, 2, OFF(168,345), NUM(168,345) } }, /* 168 */
    { "rm",  { FC_REF_CONSTANT, 1, OFF(169,347), NUM(169,347) } }, /* 169 */
    { "rn",  { FC_REF_CONSTANT, 1, OFF(170,87), NUM(170,87) } }, /* 170 */
    { "ro",  { FC_REF_CONSTANT, 3, OFF(171,348), NUM(171,348) } }, /* 171 */
    { "ru",  { FC_REF_CONSTANT, 1, OFF(172,279), NUM(172,279) } }, /* 172 */
    { "rw",  { FC_REF_CONSTANT, 1, OFF(173,87), NUM(173,87) } }, /* 173 */
    { "sa",  { FC_REF_CONSTANT, 1, OFF(174,30), NUM(174,30) } }, /* 174 */
    { "sah",  { FC_REF_CONSTANT, 1, OFF(175,351), NUM(175,351) } }, /* 175 */
    { "sat",  { FC_REF_CONSTANT, 1, OFF(176,352), NUM(176,352) } }, /* 176 */
    { "sc",  { FC_REF_CONSTANT, 1, OFF(177,353), NUM(177,353) } }, /* 177 */
    { "sco",  { FC_REF_CONSTANT, 3, OFF(178,354), NUM(178,354) } }, /* 178 */
    { "sd",  { FC_REF_CONSTANT, 1, OFF(179,357), NUM(179,357) } }, /* 179 */
    { "se",  { FC_REF_CONSTANT, 2, OFF(180,358), NUM(180,358) } }, /* 180 */
    { "sel",  { FC_REF_CONSTANT, 1, OFF(181,279), NUM(181,279) } }, /* 181 */
    { "sg",  { FC_REF_CONSTANT, 1, OFF(182,360), NUM(182,360) } }, /* 182 */
    { "sh",  { FC_REF_CONSTANT, 3, OFF(183,361), NUM(183,361) } }, /* 183 */
    { "shs",  { FC_REF_CONSTANT, 2, OFF(184,364), NUM(184,364) } }, /* 184 */
    { "si",  { FC_REF_CONSTANT, 1, OFF(185,366), NUM(185,366) } }, /* 185 */
    { "sid",  { FC_REF_CONSTANT, 2, OFF(186,367), NUM(186,367) } }, /* 186 */
    { "sk",  { FC_REF_CONSTANT, 2, OFF(187,369), NUM(187,369) } }, /* 187 */
    { "sl",  { FC_REF_CONSTANT, 2, OFF(188,42), NUM(188,42) } }, /* 188 */
    { "sm",  { FC_REF_CONSTANT, 2, OFF(189,371), NUM(189,371) } }, /* 189 */
    { "sma",  { FC_REF_CONSTANT, 1, OFF(190,373), NUM(190,373) } }, /* 190 */
    { "smj",  { FC_REF_CONSTANT, 1, OFF(191,374), NUM(191,374) } }, /* 191 */
    { "smn",  { FC_REF_CONSTANT, 2, OFF(192,375), NUM(192,375) } }, /* 192 */
    { "sms",  { FC_REF_CONSTANT, 3, OFF(193,377), NUM(193,377) } }, /* 193 */
    { "sn",  { FC_REF_CONSTANT, 1, OFF(194,87), NUM(194,87) } }, /* 194 */
    { "so",  { FC_REF_CONSTANT, 1, OFF(195,87), NUM(195,87) } }, /* 195 */
    { "sq",  { FC_REF_CONSTANT, 1, OFF(196,380), NUM(196,380) } }, /* 196 */
    { "sr",  { FC_REF_CONSTANT, 1, OFF(197,381), NUM(197,381) } }, /* 197 */
    { "ss",  { FC_REF_CONSTANT, 1, OFF(198,87), NUM(198,87) } }, /* 198 */
    { "st",  { FC_REF_CONSTANT, 1, OFF(199,87), NUM(199,87) } }, /* 199 */
    { "su",  { FC_REF_CONSTANT, 1, OFF(200,118), NUM(200,118) } }, /* 200 */
    { "sv",  { FC_REF_CONSTANT, 1, OFF(201,382), NUM(201,382) } }, /* 201 */
    { "sw",  { FC_REF_CONSTANT, 1, OFF(202,87), NUM(202,87) } }, /* 202 */
    { "syr",  { FC_REF_CONSTANT, 1, OFF(203,383), NUM(203,383) } }, /* 203 */
    { "ta",  { FC_REF_CONSTANT, 1, OFF(204,384), NUM(204,384) } }, /* 204 */
    { "te",  { FC_REF_CONSTANT, 1, OFF(205,385), NUM(205,385) } }, /* 205 */
    { "tg",  { FC_REF_CONSTANT, 1, OFF(206,386), NUM(206,386) } }, /* 206 */
    { "th",  { FC_REF_CONSTANT, 1, OFF(207,387), NUM(207,387) } }, /* 207 */
    { "ti-er",  { FC_REF_CONSTANT, 2, OFF(208,45), NUM(208,45) } }, /* 208 */
    { "ti-et",  { FC_REF_CONSTANT, 2, OFF(209,367), NUM(209,367) } }, /* 209 */
    { "tig",  { FC_REF_CONSTANT, 2, OFF(210,388), NUM(210,388) } }, /* 210 */
    { "tk",  { FC_REF_CONSTANT, 2, OFF(211,390), NUM(211,390) } }, /* 211 */
    { "tl",  { FC_REF_CONSTANT, 1, OFF(212,86), NUM(212,86) } }, /* 212 */
    { "tn",  { FC_REF_CONSTANT, 2, OFF(213,326), NUM(213,326) } }, /* 213 */
    { "to",  { FC_REF_CONSTANT, 2, OFF(214,371), NUM(214,371) } }, /* 214 */
    { "tr",  { FC_REF_CONSTANT, 2, OFF(215,392), NUM(215,392) } }, /* 215 */
    { "ts",  { FC_REF_CONSTANT, 1, OFF(216,87), NUM(216,87) } }, /* 216 */
    { "tt",  { FC_REF_CONSTANT, 1, OFF(217,394), NUM(217,394) } }, /* 217 */
    { "tw",  { FC_REF_CONSTANT, 5, OFF(218,4), NUM(218,4) } }, /* 218 */
    { "ty",  { FC_REF_CONSTANT, 3, OFF(219,395), NUM(219,395) } }, /* 219 */
    { "tyv",  { FC_REF_CONSTANT, 1, OFF(220,284), NUM(220,284) } }, /* 220 */
    { "ug",  { FC_REF_CONSTANT, 1, OFF(221,398), NUM(221,398) } }, /* 221 */
    { "uk",  { FC_REF_CONSTANT, 1, OFF(222,399), NUM(222,399) } }, /* 222 */
    { "und-zmth",  { FC_REF_CONSTANT, 12, OFF(223,400), NUM(223,400) } }, /* 223 */
    { "und-zsye",  { FC_REF_CONSTANT, 12, OFF(224,412), NUM(224,412) } }, /* 224 */
    { "ur",  { FC_REF_CONSTANT, 1, OFF(225,287), NUM(225,287) } }, /* 225 */
    { "uz",  { FC_REF_CONSTANT, 1, OFF(226,87), NUM(226,87) } }, /* 226 */
    { "ve",  { FC_REF_CONSTANT, 2, OFF(227,424), NUM(227,424) } }, /* 227 */
    { "vi",  { FC_REF_CONSTANT, 4, OFF(228,426), NUM(228,426) } }, /* 228 */
    { "vo",  { FC_REF_CONSTANT, 1, OFF(229,430), NUM(229,430) } }, /* 229 */
    { "vot",  { FC_REF_CONSTANT, 2, OFF(230,431), NUM(230,431) } }, /* 230 */
    { "wa",  { FC_REF_CONSTANT, 1, OFF(231,433), NUM(231,433) } }, /* 231 */
    { "wal",  { FC_REF_CONSTANT, 2, OFF(232,367), NUM(232,367) } }, /* 232 */
    { "wen",  { FC_REF_CONSTANT, 2, OFF(233,434), NUM(233,434) } }, /* 233 */
    { "wo",  { FC_REF_CONSTANT, 2, OFF(234,436), NUM(234,436) } }, /* 234 */
    { "xh",  { FC_REF_CONSTANT, 1, OFF(235,87), NUM(235,87) } }, /* 235 */
    { "yap",  { FC_REF_CONSTANT, 1, OFF(236,438), NUM(236,438) } }, /* 236 */
    { "yi",  { FC_REF_CONSTANT, 1, OFF(237,108), NUM(237,108) } }, /* 237 */
    { "yo",  { FC_REF_CONSTANT, 4, OFF(238,439), NUM(238,439) } }, /* 238 */
    { "za",  { FC_REF_CONSTANT, 1, OFF(239,87), NUM(239,87) } }, /* 239 */
    { "zh-cn",  { FC_REF_CONSTANT, 82, OFF(240,443), NUM(240,443) } }, /* 240 */
    { "zh-hk",  { FC_REF_CONSTANT, 171, OFF(241,525), NUM(241,525) } }, /* 241 */
    { "zh-mo",  { FC_REF_CONSTANT, 171, OFF(242,525), NUM(242,525) } }, /* 242 */
    { "zh-sg",  { FC_REF_CONSTANT, 82, OFF(243,443), NUM(243,443) } }, /* 243 */
    { "zh-tw",  { FC_REF_CONSTANT, 83, OFF(244,696), NUM(244,696) } }, /* 244 */
    { "zu",  { FC_REF_CONSTANT, 1, OFF(245,87), NUM(245,87) } }, /* 245 */
},
{
    { { /* 0 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x08104404, 0x08104404,
    } },
    { { /* 1 */
    0xffff8002, 0xffffffff, 0x8002ffff, 0x00000000,
    0xc0000000, 0xf0fc33c0, 0x03000000, 0x00000003,
    } },
    { { /* 2 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0810cf00, 0x0810cf00,
    } },
    { { /* 3 */
    0x00000000, 0x00000000, 0x00000200, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 4 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00220008, 0x00220008,
    } },
    { { /* 5 */
    0x00000000, 0x00000300, 0x00000000, 0x00000300,
    0x00010040, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 6 */
    0x00000000, 0x00000000, 0x08100000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 7 */
    0x00000048, 0x00000200, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 8 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x30000000, 0x00000000, 0x03000000,
    } },
    { { /* 9 */
    0xff7fff7f, 0xff01ff7f, 0x00003d7f, 0xffff7fff,
    0xffff3d7f, 0x003d7fff, 0xff7f7f00, 0x00ff7fff,
    } },
    { { /* 10 */
    0x003d7fff, 0xffffffff, 0x007fff7f, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 11 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x140a2202, 0x140a2202,
    } },
    { { /* 12 */
    0x00000000, 0x07fffffe, 0x000007fe, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 13 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfff99fee, 0xd3c4fdff, 0xb000399f, 0x00030000,
    } },
    { { /* 14 */
    0x00000000, 0x00c00030, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 15 */
    0xffff0042, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 16 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10028010, 0x10028010,
    } },
    { { /* 17 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10400080, 0x10400080,
    } },
    { { /* 18 */
    0xc0000000, 0x00030000, 0xc0000000, 0x00000000,
    0x00008000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 19 */
    0x00000000, 0x00000000, 0x02000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 20 */
    0x00000000, 0x07ffffde, 0x001009f6, 0x40000000,
    0x01000040, 0x00008200, 0x00001000, 0x00000000,
    } },
    { { /* 21 */
    0xffff0000, 0xffffffff, 0x0000ffff, 0x00000000,
    0x030c0000, 0x0c00cc0f, 0x03000000, 0x00000300,
    } },
    { { /* 22 */
    0xffff4040, 0xffffffff, 0x4040ffff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 23 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 24 */
    0x00003000, 0x00000000, 0x00000000, 0x00000000,
    0x00110000, 0x00000000, 0x00000000, 0x000000c0,
    } },
    { { /* 25 */
    0x00000000, 0x00000000, 0x08000000, 0x00000008,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 26 */
    0x00003000, 0x00000030, 0x00000000, 0x0000300c,
    0x000c0000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 27 */
    0x00000000, 0x3a8b0000, 0x9e78e6b9, 0x0000802e,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 28 */
    0xffff0000, 0xffffd7ff, 0x0000d7ff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 29 */
    0xffffffe0, 0x83ffffff, 0x00003fff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 30 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10008200, 0x10008200,
    } },
    { { /* 31 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x060c3303, 0x060c3303,
    } },
    { { /* 32 */
    0x00000003, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 33 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x03000000, 0x00003000, 0x00000000,
    } },
    { { /* 34 */
    0x00000000, 0x00000000, 0x00000c00, 0x00000000,
    0x20010040, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 35 */
    0x00000000, 0x00000000, 0x08100000, 0x00040000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 36 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfff99fee, 0xd3c5fdff, 0xb000399f, 0x00000000,
    } },
    { { /* 37 */
    0x00000000, 0x00000000, 0xfffffeff, 0x3d7e03ff,
    0xfeff0003, 0x03ffffff, 0x00000000, 0x00000000,
    } },
    { { /* 38 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x12120404, 0x12120404,
    } },
    { { /* 39 */
    0xfff99fee, 0xf3e5fdff, 0x0007399f, 0x0001ffff,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 40 */
    0x000330c0, 0x00000000, 0x00000000, 0x60000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 41 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x0c00c000, 0x00000000, 0x00000000,
    } },
    { { /* 42 */
    0xff7fff7f, 0xff01ff00, 0x3d7f3d7f, 0xffff7fff,
    0xffff0000, 0x003d7fff, 0xff7f7f3d, 0x00ff7fff,
    } },
    { { /* 43 */
    0x003d7fff, 0xffffffff, 0x007fff00, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 44 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x140ca381, 0x140ca381,
    } },
    { { /* 45 */
    0x00000000, 0x80000000, 0x00000001, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 46 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10020004, 0x10020004,
    } },
    { { /* 47 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x00000030, 0x000c0000, 0x030300c0,
    } },
    { { /* 48 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0xffffffff, 0xffffffff, 0x001fffff,
    } },
    { { /* 49 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x1a10cfc5, 0x9a10cfc5,
    } },
    { { /* 50 */
    0x00000000, 0x00000000, 0x000c0000, 0x01000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 51 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10420084, 0x10420084,
    } },
    { { /* 52 */
    0xc0000000, 0x00030000, 0xc0000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 53 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x24082202, 0x24082202,
    } },
    { { /* 54 */
    0x0c00f000, 0x00000000, 0x03000180, 0x6000c033,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 55 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x021c0a08, 0x021c0a08,
    } },
    { { /* 56 */
    0x00000030, 0x00000000, 0x0000001e, 0x18000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 57 */
    0xfdffa966, 0xffffdfff, 0xa965dfff, 0x03ffffff,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 58 */
    0x0000000c, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 59 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x00000c00, 0x00c00000, 0x000c0000,
    } },
    { { /* 60 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0010c604, 0x8010c604,
    } },
    { { /* 61 */
    0x00000000, 0x00000000, 0x00000000, 0x01f00000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 62 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x0000003f, 0x00000000, 0x00000000, 0x000c0000,
    } },
    { { /* 63 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x25082262, 0x25082262,
    } },
    { { /* 64 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x90400010, 0x10400010,
    } },
    { { /* 65 */
    0xfff99fec, 0xf3e5fdff, 0xf807399f, 0x0000ffff,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 66 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xffffffff, 0x0001ffff, 0x00000000, 0x00000000,
    } },
    { { /* 67 */
    0x0c000000, 0x00000000, 0x00000c00, 0x00000000,
    0x00170240, 0x00040000, 0x001fe000, 0x00000000,
    } },
    { { /* 68 */
    0x00000000, 0x00000000, 0x08500000, 0x00000008,
    0x00000800, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 69 */
    0x00001003, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 70 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xffffd740, 0xfffffffb, 0x00007fff, 0x00000000,
    } },
    { { /* 71 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00528f81, 0x00528f81,
    } },
    { { /* 72 */
    0x30000300, 0x00300030, 0x30000000, 0x00003000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 73 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10600010, 0x10600010,
    } },
    { { /* 74 */
    0x00000000, 0x00000000, 0x00000000, 0x60000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 75 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10020000, 0x10020000,
    } },
    { { /* 76 */
    0x00000000, 0x00000000, 0x00000c00, 0x00000000,
    0x20000402, 0x00180000, 0x00000000, 0x00000000,
    } },
    { { /* 77 */
    0x00000000, 0x00000000, 0x00880000, 0x00040000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 78 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00400030, 0x00400030,
    } },
    { { /* 79 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0e1e7707, 0x0e1e7707,
    } },
    { { /* 80 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x25092042, 0x25092042,
    } },
    { { /* 81 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x02041107, 0x02041107,
    } },
    { { /* 82 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x9c508e14, 0x1c508e14,
    } },
    { { /* 83 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x04082202, 0x04082202,
    } },
    { { /* 84 */
    0x00000c00, 0x00000003, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 85 */
    0xc0000c0c, 0x00000000, 0x00c00003, 0x00000c03,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 86 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x020c1383, 0x020c1383,
    } },
    { { /* 87 */
    0xff7fff7f, 0xff01ff7f, 0x00003d7f, 0x00ff00ff,
    0x00ff3d7f, 0x003d7fff, 0xff7f7f00, 0x00ff7f00,
    } },
    { { /* 88 */
    0x003d7f00, 0xffff01ff, 0x007fff7f, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 89 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x040a2202, 0x042a220a,
    } },
    { { /* 90 */
    0x00000000, 0x00000200, 0x00000000, 0x00000200,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 91 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x20000000, 0x00000000, 0x02000000,
    } },
    { { /* 92 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfffbafee, 0xf3edfdff, 0x00013bbf, 0x00000001,
    } },
    { { /* 93 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000080, 0x00000080,
    } },
    { { /* 94 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x03000402, 0x00180000, 0x00000000, 0x00000000,
    } },
    { { /* 95 */
    0x00000000, 0x00000000, 0x00880000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 96 */
    0x000c0003, 0x00000c00, 0x00003000, 0x00000c00,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 97 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x08000000, 0x00000000, 0x00000000,
    } },
    { { /* 98 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0xffff0000, 0x000007ff,
    } },
    { { /* 99 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00080000, 0x00080000,
    } },
    { { /* 100 */
    0x0c0030c0, 0x00000000, 0x0300001e, 0x66000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 101 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00040100, 0x00040100,
    } },
    { { /* 102 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x14482202, 0x14482202,
    } },
    { { /* 103 */
    0x00000000, 0x00000000, 0x00030000, 0x00030000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 104 */
    0x00000000, 0xfffe0000, 0x007fffff, 0xfffffffe,
    0x000000ff, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 105 */
    0x00000000, 0x00008000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 106 */
    0x000c0000, 0x00000000, 0x00000c00, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 107 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000200, 0x00000200,
    } },
    { { /* 108 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00003c00, 0x00000030,
    } },
    { { /* 109 */
    0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
    0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
    } },
    { { /* 110 */
    0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff,
    0x00001fff, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 111 */
    0xffff4002, 0xffffffff, 0x4002ffff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 112 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x64092242, 0x64092242,
    } },
    { { /* 113 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x060cb301, 0x060cb301,
    } },
    { { /* 114 */
    0x00000c7e, 0x031f8000, 0x0063f200, 0x000df840,
    0x00037e08, 0x08000dfa, 0x0df901bf, 0x5437e400,
    } },
    { { /* 115 */
    0x00000025, 0x40006fc0, 0x27f91be4, 0xdee00000,
    0x007ff83f, 0x00007f7f, 0x00000000, 0x00000000,
    } },
    { { /* 116 */
    0x00000000, 0x00000000, 0x00000000, 0x007f8000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 117 */
    0x000000a7, 0x00000000, 0xfffffffe, 0xffffffff,
    0x780fffff, 0xfffffffe, 0xffffffff, 0x787fffff,
    } },
    { { /* 118 */
    0x03506f8b, 0x1b042042, 0x62808020, 0x400a0000,
    0x10341b41, 0x04003812, 0x03608c02, 0x08454038,
    } },
    { { /* 119 */
    0x2403c002, 0x15108000, 0x1229e040, 0x80280000,
    0x28002800, 0x8060c002, 0x2080040c, 0x05284002,
    } },
    { { /* 120 */
    0x82042a00, 0x02000818, 0x10008200, 0x20700020,
    0x03022000, 0x40a41000, 0x0420a020, 0x00000080,
    } },
    { { /* 121 */
    0x80040011, 0x00000400, 0x04012b78, 0x11a23920,
    0x02842460, 0x00c01021, 0x20002050, 0x07400042,
    } },
    { { /* 122 */
    0x208205c9, 0x0fc10230, 0x08402480, 0x00258018,
    0x88000080, 0x42120609, 0xa32002a8, 0x40040094,
    } },
    { { /* 123 */
    0x00c00024, 0x8e000001, 0x059e058a, 0x013b0001,
    0x85000010, 0x08080000, 0x02d07d04, 0x018d9838,
    } },
    { { /* 124 */
    0x8803f310, 0x03000840, 0x00000704, 0x30080500,
    0x00001000, 0x20040000, 0x00000003, 0x04040002,
    } },
    { { /* 125 */
    0x000100d0, 0x40028000, 0x00088040, 0x00000000,
    0x34000210, 0x00400e00, 0x00000020, 0x00000008,
    } },
    { { /* 126 */
    0x00000040, 0x00060000, 0x00000000, 0x00100100,
    0x00000080, 0x00000000, 0x4c000000, 0x240d0009,
    } },
    { { /* 127 */
    0x80048000, 0x00010180, 0x00020484, 0x00000400,
    0x00000804, 0x00000008, 0x80004800, 0x16800000,
    } },
    { { /* 128 */
    0x00200065, 0x00120410, 0x44920403, 0x40000200,
    0x10880008, 0x40080100, 0x00001482, 0x00074800,
    } },
    { { /* 129 */
    0x14608200, 0x00024e84, 0x00128380, 0x20184520,
    0x0240041c, 0x0a001120, 0x00180a00, 0x88000800,
    } },
    { { /* 130 */
    0x01000002, 0x00008001, 0x04000040, 0x80000040,
    0x08040000, 0x00000000, 0x00001202, 0x00000002,
    } },
    { { /* 131 */
    0x00000000, 0x00000004, 0x21910000, 0x00000858,
    0xbf8013a0, 0x8279401c, 0xa8041054, 0xc5004282,
    } },
    { { /* 132 */
    0x0402ce56, 0xfc020000, 0x40200d21, 0x00028030,
    0x00010000, 0x01081202, 0x00000000, 0x00410003,
    } },
    { { /* 133 */
    0x00404080, 0x00000200, 0x00010000, 0x00000000,
    0x00000000, 0x00000000, 0x60000000, 0x480241ea,
    } },
    { { /* 134 */
    0x2000104c, 0x2109a820, 0x00200020, 0x7b1c0008,
    0x10a0840a, 0x01c028c0, 0x00000608, 0x04c00000,
    } },
    { { /* 135 */
    0x80398412, 0x40a200e0, 0x02080000, 0x12030a04,
    0x008d1833, 0x02184602, 0x13803028, 0x00200801,
    } },
    { { /* 136 */
    0x20440000, 0x000005a1, 0x00050800, 0x0020a328,
    0x80100000, 0x10040649, 0x10020020, 0x00090180,
    } },
    { { /* 137 */
    0x8c008202, 0x00000000, 0x00205910, 0x0041410c,
    0x00004004, 0x40441290, 0x00010080, 0x01040000,
    } },
    { { /* 138 */
    0x04070000, 0x89108040, 0x00282a81, 0x82420000,
    0x51a20411, 0x32220800, 0x2b0d2220, 0x40c83003,
    } },
    { { /* 139 */
    0x82020082, 0x80008900, 0x10a00200, 0x08004100,
    0x09041108, 0x000405a6, 0x0c018000, 0x04104002,
    } },
    { { /* 140 */
    0x00002000, 0x44003000, 0x01000004, 0x00008200,
    0x00000008, 0x00044010, 0x00002002, 0x00001040,
    } },
    { { /* 141 */
    0x00000000, 0xca008000, 0x02828020, 0x00b1100c,
    0x12824280, 0x22013030, 0x00808820, 0x040013e4,
    } },
    { { /* 142 */
    0x801840c0, 0x1000a1a1, 0x00000004, 0x0050c200,
    0x00c20082, 0x00104840, 0x10400080, 0xa3140000,
    } },
    { { /* 143 */
    0xa8a02301, 0x24123d00, 0x80030200, 0xc0028022,
    0x34a10000, 0x00408005, 0x00190010, 0x882a0000,
    } },
    { { /* 144 */
    0x00080018, 0x33000402, 0x9002010a, 0x00000000,
    0x00800020, 0x00010100, 0x84040810, 0x04004000,
    } },
    { { /* 145 */
    0x10006020, 0x00000000, 0x00000000, 0x30a02000,
    0x00000004, 0x00000000, 0x01000800, 0x20000000,
    } },
    { { /* 146 */
    0x02000000, 0x02000602, 0x80000800, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 147 */
    0x00000010, 0x44040083, 0x00081000, 0x0818824c,
    0x00400e00, 0x8c300000, 0x08146001, 0x00000000,
    } },
    { { /* 148 */
    0x00828000, 0x41900000, 0x84804006, 0x24010001,
    0x02400108, 0x9b080006, 0x00201602, 0x0009012e,
    } },
    { { /* 149 */
    0x40800800, 0x48000420, 0x10000032, 0x01904440,
    0x02000100, 0x10048000, 0x00020000, 0x08820802,
    } },
    { { /* 150 */
    0x08080ba0, 0x00009242, 0x00400000, 0xc0008080,
    0x20410001, 0x04400000, 0x60020820, 0x00100000,
    } },
    { { /* 151 */
    0x00108046, 0x01001805, 0x90100000, 0x00014010,
    0x00000010, 0x00000000, 0x0000000b, 0x00008800,
    } },
    { { /* 152 */
    0x00000000, 0x00001000, 0x00000000, 0x20018800,
    0x00004600, 0x06002000, 0x00000100, 0x00000000,
    } },
    { { /* 153 */
    0x00000000, 0x10400042, 0x02004000, 0x00004280,
    0x80000400, 0x00020000, 0x00000008, 0x00000020,
    } },
    { { /* 154 */
    0x00000040, 0x20600400, 0x0a000180, 0x02040280,
    0x00000000, 0x00409001, 0x02000004, 0x00003200,
    } },
    { { /* 155 */
    0x88000000, 0x80404800, 0x00000010, 0x00040008,
    0x00000a90, 0x00000200, 0x00002000, 0x40002001,
    } },
    { { /* 156 */
    0x00000048, 0x00100000, 0x00000000, 0x00000001,
    0x00000008, 0x20010080, 0x00000000, 0x00400040,
    } },
    { { /* 157 */
    0x85000000, 0x0c8f0108, 0x32129000, 0x80090420,
    0x00024000, 0x40040800, 0x092000a0, 0x00100204,
    } },
    { { /* 158 */
    0x00002000, 0x00000000, 0x00440004, 0x6c000000,
    0x000000d0, 0x80004000, 0x88800440, 0x41144018,
    } },
    { { /* 159 */
    0x80001a02, 0x14000001, 0x00000001, 0x0000004a,
    0x00000000, 0x00083000, 0x08000000, 0x0008a024,
    } },
    { { /* 160 */
    0x00300004, 0x00140000, 0x20000000, 0x00001800,
    0x00020002, 0x04000000, 0x00000002, 0x00000100,
    } },
    { { /* 161 */
    0x00004002, 0x54000000, 0x60400300, 0x00002120,
    0x0000a022, 0x00000000, 0x81060803, 0x08010200,
    } },
    { { /* 162 */
    0x04004800, 0xb0044000, 0x0000a005, 0x04500800,
    0x800c000a, 0x0000c000, 0x10000800, 0x02408021,
    } },
    { { /* 163 */
    0x08020000, 0x00001040, 0x00540a40, 0x00000000,
    0x00800880, 0x01020002, 0x00000211, 0x00000010,
    } },
    { { /* 164 */
    0x00000000, 0x80000002, 0x00002000, 0x00080001,
    0x09840a00, 0x40000080, 0x00400000, 0x49000080,
    } },
    { { /* 165 */
    0x0e102831, 0x06098807, 0x40011014, 0x02620042,
    0x06000000, 0x88062000, 0x04068400, 0x08108301,
    } },
    { { /* 166 */
    0x08000012, 0x40004840, 0x00300402, 0x00012000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 167 */
    0x00000000, 0x00400000, 0x00000000, 0x00a54400,
    0x40004420, 0x20000310, 0x00041002, 0x18000000,
    } },
    { { /* 168 */
    0x00a1002a, 0x00080000, 0x40400000, 0x00900000,
    0x21401200, 0x04048626, 0x40005048, 0x21100000,
    } },
    { { /* 169 */
    0x040005a4, 0x000a0000, 0x00214000, 0x07010800,
    0x34000000, 0x00080100, 0x00080040, 0x10182508,
    } },
    { { /* 170 */
    0xc0805100, 0x02c01400, 0x00000080, 0x00448040,
    0x20000800, 0x210a8000, 0x08800000, 0x00020060,
    } },
    { { /* 171 */
    0x00004004, 0x00400100, 0x01040200, 0x00800000,
    0x00000000, 0x00000000, 0x10081400, 0x00008000,
    } },
    { { /* 172 */
    0x00004000, 0x20000000, 0x08800200, 0x00001000,
    0x00000000, 0x01000000, 0x00000810, 0x00000000,
    } },
    { { /* 173 */
    0x00020000, 0x20200000, 0x00000000, 0x00000000,
    0x00000010, 0x00001c40, 0x00002000, 0x08000210,
    } },
    { { /* 174 */
    0x00000000, 0x00000000, 0x54014000, 0x02000800,
    0x00200400, 0x00000000, 0x00002080, 0x00004000,
    } },
    { { /* 175 */
    0x10000004, 0x00000000, 0x00000000, 0x00000000,
    0x00002000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 176 */
    0x00000000, 0x00000000, 0x28881041, 0x0081010a,
    0x00400800, 0x00000800, 0x10208026, 0x61000000,
    } },
    { { /* 177 */
    0x00050080, 0x00000000, 0x80000000, 0x80040000,
    0x044088c2, 0x00080480, 0x00040000, 0x00000048,
    } },
    { { /* 178 */
    0x8188410d, 0x141a2400, 0x40310000, 0x000f4249,
    0x41283280, 0x80053011, 0x00400880, 0x410060c0,
    } },
    { { /* 179 */
    0x2a004013, 0x02000002, 0x11000000, 0x00850040,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 180 */
    0x00000000, 0x00800000, 0x04000440, 0x00000402,
    0x60001000, 0x99909f87, 0x5808049d, 0x10002445,
    } },
    { { /* 181 */
    0x00000100, 0x00000000, 0x00000000, 0x00910050,
    0x00000420, 0x00080008, 0x20000000, 0x00288002,
    } },
    { { /* 182 */
    0x00008400, 0x00000400, 0x00000000, 0x00100000,
    0x00002000, 0x00000800, 0x80043400, 0x21000004,
    } },
    { { /* 183 */
    0x20000208, 0x01000600, 0x00000010, 0x00000000,
    0x48000000, 0x14060008, 0x00124020, 0x20812800,
    } },
    { { /* 184 */
    0xa419804b, 0x01064009, 0x10386ca4, 0x85a0620b,
    0x00000010, 0x01000448, 0x00004400, 0x20a02102,
    } },
    { { /* 185 */
    0x00000000, 0x00000000, 0x00147000, 0x01a01404,
    0x10040000, 0x01000000, 0x3002f180, 0x00000008,
    } },
    { { /* 186 */
    0x00002000, 0x00100000, 0x08000010, 0x00020004,
    0x01000029, 0x00002000, 0x00000000, 0x10082000,
    } },
    { { /* 187 */
    0x00000000, 0x0004d041, 0x08000800, 0x00200000,
    0x00401000, 0x00004000, 0x00000000, 0x00000002,
    } },
    { { /* 188 */
    0x01000000, 0x00000000, 0x00020000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 189 */
    0x00000000, 0x00000000, 0x00000000, 0x00800000,
    0x000a0a01, 0x0004002c, 0x01000080, 0x00000000,
    } },
    { { /* 190 */
    0x10000000, 0x08040400, 0x08012010, 0x2569043c,
    0x1a10c460, 0x08800009, 0x000210f0, 0x08c5050c,
    } },
    { { /* 191 */
    0x10000481, 0x00040080, 0x42040000, 0x00100204,
    0x00000000, 0x00000000, 0x00080000, 0x88080000,
    } },
    { { /* 192 */
    0x010f016c, 0x18002000, 0x41307000, 0x00000080,
    0x00000000, 0x00000100, 0x88000000, 0x70048004,
    } },
    { { /* 193 */
    0x00081420, 0x00000100, 0x00000000, 0x00000000,
    0x02400000, 0x00001000, 0x00050070, 0x00000000,
    } },
    { { /* 194 */
    0x000c4000, 0x00010000, 0x04000000, 0x00000000,
    0x00000000, 0x01000100, 0x01000010, 0x00000400,
    } },
    { { /* 195 */
    0x00000000, 0x10020000, 0x04100024, 0x00000000,
    0x00000000, 0x00004000, 0x00000000, 0x00000100,
    } },
    { { /* 196 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00100020,
    } },
    { { /* 197 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00008000, 0x00100000, 0x00000000, 0x00000000,
    } },
    { { /* 198 */
    0x00000000, 0x00000000, 0x00000000, 0x80000000,
    0x00880000, 0x0c000040, 0x02040010, 0x00000000,
    } },
    { { /* 199 */
    0x00080000, 0x08000000, 0x00000000, 0x00000004,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 200 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000300, 0x00000300,
    } },
    { { /* 201 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0xffff0000, 0x0001ffff,
    } },
    { { /* 202 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x0c0c0000, 0x000cc00c, 0x03000000, 0x00000000,
    } },
    { { /* 203 */
    0x00000000, 0x00000300, 0x00000000, 0x00000300,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 204 */
    0xffff0000, 0xffffffff, 0x0040ffff, 0x00000000,
    0x0c0c0000, 0x0c00000c, 0x03000000, 0x00000300,
    } },
    { { /* 205 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0d10646e, 0x0d10646e,
    } },
    { { /* 206 */
    0x00000000, 0x01000300, 0x00000000, 0x00000300,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 207 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x9fffffff, 0xffcffee7, 0x0000003f, 0x00000000,
    } },
    { { /* 208 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfffddfec, 0xc3effdff, 0x40603ddf, 0x00000003,
    } },
    { { /* 209 */
    0x00000000, 0xfffe0000, 0xffffffff, 0xffffffef,
    0x00007fff, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 210 */
    0x3eff0793, 0x1303b011, 0x11102801, 0x05930000,
    0xb0111e7b, 0x3b019703, 0x00a01112, 0x306b9593,
    } },
    { { /* 211 */
    0x1102b051, 0x11303201, 0x011102b0, 0xb879300a,
    0x30011306, 0x00800010, 0x100b0113, 0x93000011,
    } },
    { { /* 212 */
    0x00102b03, 0x05930000, 0xb051746b, 0x3b011323,
    0x00001030, 0x70000000, 0x1303b011, 0x11102900,
    } },
    { { /* 213 */
    0x00012180, 0xb0153000, 0x3001030e, 0x02000030,
    0x10230111, 0x13000000, 0x10106b81, 0x01130300,
    } },
    { { /* 214 */
    0x30111013, 0x00000100, 0x22b85530, 0x30000000,
    0x9702b011, 0x113afb07, 0x011303b0, 0x00000021,
    } },
    { { /* 215 */
    0x3b0d1b00, 0x03b01138, 0x11330113, 0x13000001,
    0x111c2b05, 0x00000100, 0xb0111000, 0x2a011300,
    } },
    { { /* 216 */
    0x02b01930, 0x10100001, 0x11000000, 0x10300301,
    0x07130230, 0x0011146b, 0x2b051300, 0x8fb8f974,
    } },
    { { /* 217 */
    0x103b0113, 0x00000000, 0xd9700000, 0x01134ab0,
    0x0011103b, 0x00001103, 0x2ab15930, 0x10000111,
    } },
    { { /* 218 */
    0x11010000, 0x00100b01, 0x01130000, 0x0000102b,
    0x20000101, 0x02a01110, 0x30210111, 0x0102b059,
    } },
    { { /* 219 */
    0x19300000, 0x011307b0, 0xb011383b, 0x00000003,
    0x00000000, 0x383b0d13, 0x0103b011, 0x00001000,
    } },
    { { /* 220 */
    0x01130000, 0x00101020, 0x00000100, 0x00000110,
    0x30000000, 0x00021811, 0x00100000, 0x01110000,
    } },
    { { /* 221 */
    0x00000023, 0x0b019300, 0x00301110, 0x302b0111,
    0x13c7b011, 0x01303b01, 0x00000280, 0xb0113000,
    } },
    { { /* 222 */
    0x2b011383, 0x03b01130, 0x300a0011, 0x1102b011,
    0x00002000, 0x01110100, 0xa011102b, 0x2b011302,
    } },
    { { /* 223 */
    0x01000010, 0x30000001, 0x13029011, 0x11302b01,
    0x000066b0, 0xb0113000, 0x6b07d302, 0x07b0113a,
    } },
    { { /* 224 */
    0x00200103, 0x13000000, 0x11386b05, 0x011303b0,
    0x000010b8, 0x2b051b00, 0x03000110, 0x10000000,
    } },
    { { /* 225 */
    0x1102a011, 0x79700a01, 0x0111a2b0, 0x0000100a,
    0x00011100, 0x00901110, 0x00090111, 0x93000000,
    } },
    { { /* 226 */
    0xf9f2bb05, 0x011322b0, 0x2001323b, 0x00000000,
    0x06b05930, 0x303b0193, 0x1123a011, 0x11700000,
    } },
    { { /* 227 */
    0x001102b0, 0x00001010, 0x03011301, 0x00000110,
    0x162b0793, 0x01010010, 0x11300000, 0x01110200,
    } },
    { { /* 228 */
    0xb0113029, 0x00000000, 0x0eb05130, 0x383b0513,
    0x0303b011, 0x00000100, 0x01930000, 0x00001039,
    } },
    { { /* 229 */
    0x3b000302, 0x00000000, 0x00230113, 0x00000000,
    0x00100000, 0x00010000, 0x90113020, 0x00000002,
    } },
    { { /* 230 */
    0x00000000, 0x10000000, 0x11020000, 0x00000301,
    0x01130000, 0xb079b02b, 0x3b011323, 0x02b01130,
    } },
    { { /* 231 */
    0xf0210111, 0x1343b0d9, 0x11303b01, 0x011103b0,
    0xb0517020, 0x20011322, 0x01901110, 0x300b0111,
    } },
    { { /* 232 */
    0x9302b011, 0x0016ab01, 0x01130100, 0xb0113021,
    0x29010302, 0x02b03130, 0x30000000, 0x1b42b819,
    } },
    { { /* 233 */
    0x11383301, 0x00000330, 0x00000020, 0x33051300,
    0x00001110, 0x00000000, 0x93000000, 0x01302305,
    } },
    { { /* 234 */
    0x00010100, 0x30111010, 0x00000100, 0x02301130,
    0x10100001, 0x11000000, 0x00000000, 0x85130200,
    } },
    { { /* 235 */
    0x10111003, 0x2b011300, 0x63b87730, 0x303b0113,
    0x11a2b091, 0x7b300201, 0x011357f0, 0xf0d1702b,
    } },
    { { /* 236 */
    0x1b0111e3, 0x0ab97130, 0x303b0113, 0x13029001,
    0x11302b01, 0x071302b0, 0x3011302b, 0x23011303,
    } },
    { { /* 237 */
    0x02b01130, 0x30ab0113, 0x11feb411, 0x71300901,
    0x05d347b8, 0xb011307b, 0x21015303, 0x00001110,
    } },
    { { /* 238 */
    0x306b0513, 0x1102b011, 0x00103301, 0x05130000,
    0xa01038eb, 0x30000102, 0x02b01110, 0x30200013,
    } },
    { { /* 239 */
    0x0102b071, 0x00101000, 0x01130000, 0x1011100b,
    0x2b011300, 0x00000000, 0x366b0593, 0x1303b095,
    } },
    { { /* 240 */
    0x01103b01, 0x00000200, 0xb0113000, 0x20000103,
    0x01000010, 0x30000000, 0x030ab011, 0x00101001,
    } },
    { { /* 241 */
    0x01110100, 0x00000003, 0x23011302, 0x03000010,
    0x10000000, 0x01000000, 0x00100000, 0x00000290,
    } },
    { { /* 242 */
    0x30113000, 0x7b015386, 0x03b01130, 0x00210151,
    0x13000000, 0x11303b01, 0x001102b0, 0x00011010,
    } },
    { { /* 243 */
    0x2b011302, 0x02001110, 0x10000000, 0x0102b011,
    0x11300100, 0x000102b0, 0x00011010, 0x2b011100,
    } },
    { { /* 244 */
    0x02101110, 0x002b0113, 0x93000000, 0x11302b03,
    0x011302b0, 0x0000303b, 0x00000002, 0x03b01930,
    } },
    { { /* 245 */
    0x102b0113, 0x0103b011, 0x11300000, 0x011302b0,
    0x00001021, 0x00010102, 0x00000010, 0x102b0113,
    } },
    { { /* 246 */
    0x01020011, 0x11302000, 0x011102b0, 0x30113001,
    0x00000002, 0x02b01130, 0x303b0313, 0x0103b011,
    } },
    { { /* 247 */
    0x00002000, 0x05130000, 0xb011303b, 0x10001102,
    0x00000110, 0x142b0113, 0x01000001, 0x01100000,
    } },
    { { /* 248 */
    0x00010280, 0xb0113000, 0x10000102, 0x00000010,
    0x10230113, 0x93021011, 0x11100b05, 0x01130030,
    } },
    { { /* 249 */
    0xb051702b, 0x3b011323, 0x00000030, 0x30000000,
    0x1303b011, 0x11102b01, 0x01010330, 0xb011300a,
    } },
    { { /* 250 */
    0x20000102, 0x00000000, 0x10000011, 0x9300a011,
    0x00102b05, 0x00000200, 0x90111000, 0x29011100,
    } },
    { { /* 251 */
    0x00b01110, 0x30000000, 0x1302b011, 0x11302b21,
    0x000103b0, 0x00000020, 0x2b051300, 0x02b01130,
    } },
    { { /* 252 */
    0x103b0113, 0x13002011, 0x11322b21, 0x00130280,
    0xa0113028, 0x0a011102, 0x02921130, 0x30210111,
    } },
    { { /* 253 */
    0x13020011, 0x11302b01, 0x03d30290, 0x3011122b,
    0x2b011302, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 254 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00004000, 0x00000000, 0x20000000, 0x00000000,
    } },
    { { /* 255 */
    0x00000000, 0x00000000, 0x00003000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 256 */
    0x00000000, 0x040001df, 0x80800176, 0x420c0000,
    0x01020140, 0x44008200, 0x00041018, 0x00000000,
    } },
    { { /* 257 */
    0xffff0000, 0xffff27bf, 0x000027bf, 0x00000000,
    0x00000000, 0x0c000000, 0x03000000, 0x000000c0,
    } },
    { { /* 258 */
    0x3c000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 259 */
    0x00000000, 0x061ef5c0, 0x000001f6, 0x40000000,
    0x01040040, 0x00208210, 0x00005040, 0x00000000,
    } },
    { { /* 260 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x08004480, 0x08004480,
    } },
    { { /* 261 */
    0x00000000, 0x00000000, 0xc0000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 262 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 263 */
    0xffff0042, 0xffffffff, 0x0042ffff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x000000c0,
    } },
    { { /* 264 */
    0x00000000, 0x000c0000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 265 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x0000c00c, 0x00000000, 0x00000000,
    } },
    { { /* 266 */
    0x000c0003, 0x00003c00, 0x0000f000, 0x00003c00,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 267 */
    0x00000000, 0x040001de, 0x00000176, 0x42000000,
    0x01020140, 0x44008200, 0x00041008, 0x00000000,
    } },
    { { /* 268 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x98504f14, 0x18504f14,
    } },
    { { /* 269 */
    0x00000000, 0x00000000, 0x00000c00, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 270 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00480910, 0x00480910,
    } },
    { { /* 271 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0c186606, 0x0c186606,
    } },
    { { /* 272 */
    0x0c000000, 0x00000000, 0x00000000, 0x00000000,
    0x00010040, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 273 */
    0x00001006, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 274 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfef02596, 0x3bffecae, 0x30003f5f, 0x00000000,
    } },
    { { /* 275 */
    0x03c03030, 0x0000c000, 0x00000000, 0x600c0c03,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 276 */
    0x000c3003, 0x18c00c0c, 0x00c03060, 0x60000c03,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 277 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00100002, 0x00100002,
    } },
    { { /* 278 */
    0x00000003, 0x18000000, 0x00003060, 0x00000c00,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 279 */
    0x00000000, 0x00300000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 280 */
    0xfdffb729, 0x000001ff, 0xb7290000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 281 */
    0xfffddfec, 0xc3fffdff, 0x00803dcf, 0x00000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 282 */
    0x00000000, 0xffffffff, 0xffffffff, 0x00ffffff,
    0xffffffff, 0x000003ff, 0x00000000, 0x00000000,
    } },
    { { /* 283 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00000000, 0x0000c000, 0x00000000, 0x00000300,
    } },
    { { /* 284 */
    0x00000000, 0x00000000, 0x00000000, 0x00000010,
    0xfff99fee, 0xf3c5fdff, 0xb000798f, 0x0002ffc0,
    } },
    { { /* 285 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00004004, 0x00004004,
    } },
    { { /* 286 */
    0x0f000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 287 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x02045101, 0x02045101,
    } },
    { { /* 288 */
    0x00000c00, 0x000000c3, 0x00000000, 0x18000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 289 */
    0xffffffff, 0x0007f6fb, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 290 */
    0x00000000, 0x00000000, 0x00000000, 0x00000300,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 291 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x011c0661, 0x011c0661,
    } },
    { { /* 292 */
    0xfff98fee, 0xc3e5fdff, 0x0001398f, 0x0001fff0,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 293 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x1c58af16, 0x1c58af16,
    } },
    { { /* 294 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x115c0671, 0x115c0671,
    } },
    { { /* 295 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0xffffffff, 0x07ffffff,
    } },
    { { /* 296 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00100400, 0x00100400,
    } },
    { { /* 297 */
    0x00000000, 0x00000000, 0x00000000, 0x00000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 298 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00082202, 0x00082202,
    } },
    { { /* 299 */
    0x03000030, 0x0000c000, 0x00000006, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000c00,
    } },
    { { /* 300 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x10000000, 0x00000000, 0x00000000,
    } },
    { { /* 301 */
    0x00000002, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 302 */
    0x00000000, 0x00000000, 0x00000000, 0x00300000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 303 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x040c2383, 0x040c2383,
    } },
    { { /* 304 */
    0xfff99fee, 0xf3cdfdff, 0xb0c0398f, 0x00000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 305 */
    0x00000000, 0x07ffffc6, 0x000001fe, 0x40000000,
    0x01000040, 0x0000a000, 0x00001000, 0x00000000,
    } },
    { { /* 306 */
    0xfff987e0, 0xd36dfdff, 0x1e003987, 0x001f0000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 307 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x160e2302, 0x160e2302,
    } },
    { { /* 308 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00020000, 0x00020000,
    } },
    { { /* 309 */
    0x030000f0, 0x00000000, 0x0c00001e, 0x1e000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 310 */
    0x00000000, 0x07ffffde, 0x000005f6, 0x50000000,
    0x05480262, 0x10000a00, 0x00013000, 0x00000000,
    } },
    { { /* 311 */
    0x00000000, 0x07ffffde, 0x000005f6, 0x50000000,
    0x05480262, 0x10000a00, 0x00052000, 0x00000000,
    } },
    { { /* 312 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x143c278f, 0x143c278f,
    } },
    { { /* 313 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000100, 0x00000000,
    } },
    { { /* 314 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x02045301, 0x02045301,
    } },
    { { /* 315 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00300000, 0x0c00c030, 0x03000000, 0x00000000,
    } },
    { { /* 316 */
    0xfff987ee, 0xf325fdff, 0x00013987, 0x0001fff0,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 317 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x02041101, 0x02041101,
    } },
    { { /* 318 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00800000, 0x00000000, 0x00000000,
    } },
    { { /* 319 */
    0x30000000, 0x00000000, 0x00000000, 0x00000000,
    0x00040000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 320 */
    0x00000000, 0x07fffdd6, 0x000005f6, 0xec000000,
    0x0200b4d9, 0x480a8640, 0x00000000, 0x00000000,
    } },
    { { /* 321 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000002, 0x00000002,
    } },
    { { /* 322 */
    0x00033000, 0x00000000, 0x00000c00, 0x600000c3,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 323 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x1850cc14, 0x1850cc14,
    } },
    { { /* 324 */
    0xffff8f04, 0xffffffff, 0x8f04ffff, 0x00000000,
    0x030c0000, 0x0c00cc0f, 0x03000000, 0x00000300,
    } },
    { { /* 325 */
    0x00000000, 0x00800000, 0x03bffbaa, 0x03bffbaa,
    0x00000000, 0x00000000, 0x00002202, 0x00002202,
    } },
    { { /* 326 */
    0x00080000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 327 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xfc7e3fec, 0x2ffbffbf, 0x7f5f847f, 0x00040000,
    } },
    { { /* 328 */
    0xff7fff7f, 0xff01ff7f, 0x3d7f3d7f, 0xffff7fff,
    0xffff3d7f, 0x003d7fff, 0xff7f7f3d, 0x00ff7fff,
    } },
    { { /* 329 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x24182212, 0x24182212,
    } },
    { { /* 330 */
    0x0000f000, 0x66000000, 0x00300180, 0x60000033,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 331 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00408030, 0x00408030,
    } },
    { { /* 332 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00020032, 0x00020032,
    } },
    { { /* 333 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000016, 0x00000016,
    } },
    { { /* 334 */
    0x00033000, 0x00000000, 0x00000c00, 0x60000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 335 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00200034, 0x00200034,
    } },
    { { /* 336 */
    0x00033000, 0x00000000, 0x00000c00, 0x60000003,
    0x00000000, 0x00800000, 0x00000000, 0x0000c3f0,
    } },
    { { /* 337 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00040000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 338 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00000880, 0x00000880,
    } },
    { { /* 339 */
    0xfdff8f04, 0xfdff01ff, 0x8f0401ff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 340 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10400a33, 0x10400a33,
    } },
    { { /* 341 */
    0xffff0000, 0xffff1fff, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 342 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0xd63dc7e8, 0xc3bfc718, 0x00803dc7, 0x00000000,
    } },
    { { /* 343 */
    0xfffddfee, 0xc3effdff, 0x00603ddf, 0x00000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 344 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x0c0c0000, 0x00cc0000, 0x00000000, 0x0000c00c,
    } },
    { { /* 345 */
    0xfffffffe, 0x87ffffff, 0x00007fff, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 346 */
    0xff7fff7f, 0xff01ff00, 0x00003d7f, 0xffff7fff,
    0x00ff0000, 0x003d7f7f, 0xff7f7f00, 0x00ff7f00,
    } },
    { { /* 347 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x30400090, 0x30400090,
    } },
    { { /* 348 */
    0x00000000, 0x00000000, 0xc0000180, 0x60000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 349 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x18404084, 0x18404084,
    } },
    { { /* 350 */
    0xffff0002, 0xffffffff, 0x0002ffff, 0x00000000,
    0x00c00000, 0x0c00c00c, 0x03000000, 0x00000000,
    } },
    { { /* 351 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00008000, 0x00008000,
    } },
    { { /* 352 */
    0x00000000, 0x041ed5c0, 0x0000077e, 0x40000000,
    0x01000040, 0x4000a000, 0x002109c0, 0x00000000,
    } },
    { { /* 353 */
    0xffff00d0, 0xffffffff, 0x00d0ffff, 0x00000000,
    0x00030000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 354 */
    0x00000000, 0xffffff7b, 0x7fffffff, 0x7ffffffe,
    0x00000000, 0x80e310fe, 0x00800000, 0x00800000,
    } },
    { { /* 355 */
    0x00000000, 0x00020000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 356 */
    0x00001500, 0x01000000, 0x00000000, 0x00000000,
    0xfffe0000, 0xfffe03db, 0x006003fb, 0x00030000,
    } },
    { { /* 357 */
    0x00400000, 0x00000047, 0x00800010, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000002,
    } },
    { { /* 358 */
    0x3f2fc004, 0x00000010, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 359 */
    0xe3ffbfff, 0xfff007ff, 0x00000001, 0x00000000,
    0xfffff000, 0x0000003f, 0x0000e10f, 0x00000000,
    } },
    { { /* 360 */
    0x00000f00, 0x0000000c, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 361 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000003, 0x00000000, 0x00000000,
    } },
    { { /* 362 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x000003c0,
    } },
    { { /* 363 */
    0xffffffff, 0xffffffff, 0xffdfffff, 0xffffffff,
    0xdfffffff, 0x00001e64, 0x00000000, 0x00000000,
    } },
    { { /* 364 */
    0x00000000, 0x78000000, 0x0001fc5f, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 365 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000030, 0x00000000, 0x00000000,
    } },
    { { /* 366 */
    0x0c000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00091e00,
    } },
    { { /* 367 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x60000000,
    } },
    { { /* 368 */
    0x00300000, 0x00000000, 0x000fff00, 0x80000000,
    0x00080000, 0x60000c02, 0x00104030, 0x242c0400,
    } },
    { { /* 369 */
    0x00000c20, 0x00000100, 0x00b85000, 0x00000000,
    0x00e00000, 0x80010000, 0x00000000, 0x00000000,
    } },
    { { /* 370 */
    0x18000000, 0x00000000, 0x00210000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 371 */
    0x00000010, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00008000, 0x00000000,
    } },
    { { /* 372 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x07fe4000, 0x00000000, 0x00000000, 0xffffffc0,
    } },
    { { /* 373 */
    0x04000002, 0x077c8000, 0x00030000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 374 */
    0xffffffff, 0xffbf0001, 0xffffffff, 0x1fffffff,
    0x000fffff, 0xffffffff, 0x000007df, 0x0001ffff,
    } },
    { { /* 375 */
    0x00000000, 0x00000000, 0xfffffffd, 0xffffffff,
    0xffffffff, 0xffffffff, 0xffffffff, 0x1effffff,
    } },
    { { /* 376 */
    0xffffffff, 0x3fffffff, 0xffff0000, 0x000000ff,
    0x00000000, 0x00000000, 0x00000000, 0xf8000000,
    } },
    { { /* 377 */
    0x755dfffe, 0xffef2f3f, 0x0000ffe1, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 378 */
    0x000c0000, 0x30000000, 0x00000c30, 0x00030000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 379 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x263c370f, 0x263c370f,
    } },
    { { /* 380 */
    0x0003000c, 0x00000300, 0x00000000, 0x00000300,
    0x00000000, 0x00018003, 0x00000000, 0x00000000,
    } },
    { { /* 381 */
    0x0800024f, 0x00000008, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 382 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0xffffffff, 0xffffffff, 0x03ffffff,
    } },
    { { /* 383 */
    0x00000000, 0x00000000, 0x077dfffe, 0x077dfffe,
    0x00000000, 0x00000000, 0x10400010, 0x10400010,
    } },
    { { /* 384 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x10400010, 0x10400010,
    } },
    { { /* 385 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x081047a4, 0x081047a4,
    } },
    { { /* 386 */
    0x0c0030c0, 0x00000000, 0x0f30001e, 0x66000003,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 387 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x000a0a09, 0x000a0a09,
    } },
    { { /* 388 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x00400810, 0x00400810,
    } },
    { { /* 389 */
    0x00000000, 0x00000000, 0x07fffffe, 0x07fffffe,
    0x00000000, 0x00000000, 0x0e3c770f, 0x0e3c770f,
    } },
    { { /* 390 */
    0x0c000000, 0x00000300, 0x00000018, 0x00000300,
    0x00000000, 0x00000000, 0x001fe000, 0x03000000,
    } },
    { { /* 391 */
    0x0000100f, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 392 */
    0x00000000, 0xc0000000, 0x00000000, 0x0000000c,
    0x00000000, 0x33000000, 0x00003000, 0x00000000,
    } },
    { { /* 393 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000280, 0x00000000,
    } },
    { { /* 394 */
    0x7f7b7f8b, 0xef553db4, 0xf35dfba8, 0x400b0243,
    0x8d3efb40, 0x8c2c7bf7, 0xe3fa6eff, 0xa8ed1d3a,
    } },
    { { /* 395 */
    0xcf83e602, 0x35558cf5, 0xffabe048, 0xd85992b9,
    0x2892ab18, 0x8020d7e9, 0xf583c438, 0x450ae74a,
    } },
    { { /* 396 */
    0x9714b000, 0x54007762, 0x1420d188, 0xc8c01020,
    0x00002121, 0x0c0413a8, 0x04408000, 0x082870c0,
    } },
    { { /* 397 */
    0x000408c0, 0x80000002, 0x14722b7b, 0x3bfb7924,
    0x1ae43327, 0x38ef9835, 0x28029ad1, 0xbf69a813,
    } },
    { { /* 398 */
    0x2fc665cf, 0xafc96b11, 0x5053340f, 0xa00486a2,
    0xe8090106, 0xc00e3f0f, 0x81450a88, 0xc6010010,
    } },
    { { /* 399 */
    0x26e1a161, 0xce00444b, 0xd4eec7aa, 0x85bbcadf,
    0xa5203a74, 0x8840436c, 0x8bd23f06, 0x3befff79,
    } },
    { { /* 400 */
    0xe8eff75a, 0x5b36fbcb, 0x1bfd0d49, 0x39ee0154,
    0x2e75d855, 0xa91abfd8, 0xf6bff3d7, 0xb40c67e0,
    } },
    { { /* 401 */
    0x081382c2, 0xd08bd49d, 0x1061065a, 0x59e074f2,
    0xb3128f9f, 0x6aaa0080, 0xb05e3230, 0x60ac9d7a,
    } },
    { { /* 402 */
    0xc900d303, 0x8a563098, 0x13907000, 0x18421f14,
    0x0008c060, 0x10808008, 0xec900400, 0xe6332817,
    } },
    { { /* 403 */
    0x90000758, 0x4e09f708, 0xfc83f485, 0x18c8af53,
    0x080c187c, 0x01146adf, 0xa734c80c, 0x2710a011,
    } },
    { { /* 404 */
    0x422228c5, 0x00210413, 0x41123010, 0x40001820,
    0xc60c022b, 0x10000300, 0x00220022, 0x02495810,
    } },
    { { /* 405 */
    0x9670a094, 0x1792eeb0, 0x05f2cb96, 0x23580025,
    0x42cc25de, 0x4a04cf38, 0x359f0c40, 0x8a001128,
    } },
    { { /* 406 */
    0x910a13fa, 0x10560229, 0x04200641, 0x84f00484,
    0x0c040000, 0x412c0400, 0x11541206, 0x00020a4b,
    } },
    { { /* 407 */
    0x00c00200, 0x00940000, 0xbfbb0001, 0x242b167c,
    0x7fa89bbb, 0xe3790c7f, 0xe00d10f4, 0x9f014132,
    } },
    { { /* 408 */
    0x35728652, 0xff1210b4, 0x4223cf27, 0x8602c06b,
    0x1fd33106, 0xa1aa3a0c, 0x02040812, 0x08012572,
    } },
    { { /* 409 */
    0x485040cc, 0x601062d0, 0x29001c80, 0x00109a00,
    0x22000004, 0x00800000, 0x68002020, 0x609ecbe6,
    } },
    { { /* 410 */
    0x3f73916e, 0x398260c0, 0x48301034, 0xbd5c0006,
    0xd6fb8cd1, 0x43e820e1, 0x084e0600, 0xc4d00500,
    } },
    { { /* 411 */
    0x89aa8d1f, 0x1602a6e1, 0x21ed0001, 0x1a8b3656,
    0x13a51fb7, 0x30a06502, 0x23c7b278, 0xe9226c93,
    } },
    { { /* 412 */
    0x3a74e47f, 0x98208fe3, 0x2625280e, 0xbf49bf9c,
    0xac543218, 0x1916b949, 0xb5220c60, 0x0659fbc1,
    } },
    { { /* 413 */
    0x8420e343, 0x800008d9, 0x20225500, 0x00a10184,
    0x20104800, 0x40801380, 0x00160d04, 0x80200040,
    } },
    { { /* 414 */
    0x8de7fd40, 0xe0985436, 0x091e7b8b, 0xd249fec8,
    0x8dee0611, 0xba221937, 0x9fdd77f4, 0xf0daf3ec,
    } },
    { { /* 415 */
    0xec424386, 0x26048d3f, 0xc021fa6c, 0x0cc2628e,
    0x0145d785, 0x559977ad, 0x4045e250, 0xa154260b,
    } },
    { { /* 416 */
    0x58199827, 0xa4103443, 0x411405f2, 0x07002280,
    0x426600b4, 0x15a17210, 0x41856025, 0x00000054,
    } },
    { { /* 417 */
    0x01040201, 0xcb70c820, 0x6a629320, 0x0095184c,
    0x9a8b1880, 0x3201aab2, 0x00c4d87a, 0x04c3f3e5,
    } },
    { { /* 418 */
    0xa238d44d, 0x5072a1a1, 0x84fc980a, 0x44d1c152,
    0x20c21094, 0x42104180, 0x3a000000, 0xd29d0240,
    } },
    { { /* 419 */
    0xa8b12f01, 0x2432bd40, 0xd04bd34d, 0xd0ada723,
    0x75a10a92, 0x01e9adac, 0x771f801a, 0xa01b9225,
    } },
    { { /* 420 */
    0x20cadfa1, 0x738c0602, 0x003b577f, 0x00d00bff,
    0x0088806a, 0x0029a1c4, 0x05242a05, 0x16234009,
    } },
    { { /* 421 */
    0x80056822, 0xa2112011, 0x64900004, 0x13824849,
    0x193023d5, 0x08922980, 0x88115402, 0xa0042001,
    } },
    { { /* 422 */
    0x81800400, 0x60228502, 0x0b010090, 0x12020022,
    0x00834011, 0x00001a01, 0x00000000, 0x00000000,
    } },
    { { /* 423 */
    0x00000000, 0x4684009f, 0x020012c8, 0x1a0004fc,
    0x0c4c2ede, 0x80b80402, 0x0afca826, 0x22288c02,
    } },
    { { /* 424 */
    0x8f7ba0e0, 0x2135c7d6, 0xf8b106c7, 0x62550713,
    0x8a19936e, 0xfb0e6efa, 0x48f91630, 0x7debcd2f,
    } },
    { { /* 425 */
    0x4e845892, 0x7a2e4ca0, 0x561eedea, 0x1190c649,
    0xe83a5324, 0x8124cfdb, 0x634218f1, 0x1a8a5853,
    } },
    { { /* 426 */
    0x24d37420, 0x0514aa3b, 0x89586018, 0xc0004800,
    0x91018268, 0x2cd684a4, 0xc4ba8886, 0x02100377,
    } },
    { { /* 427 */
    0x00388244, 0x404aae11, 0x510028c0, 0x15146044,
    0x10007310, 0x02480082, 0x40060205, 0x0000c003,
    } },
    { { /* 428 */
    0x0c020000, 0x02200008, 0x40009000, 0xd161b800,
    0x32744621, 0x3b8af800, 0x8b00050f, 0x2280bbd0,
    } },
    { { /* 429 */
    0x07690600, 0x00438040, 0x50005420, 0x250c41d0,
    0x83108410, 0x02281101, 0x00304008, 0x020040a1,
    } },
    { { /* 430 */
    0x20000040, 0xabe31500, 0xaa443180, 0xc624c2c6,
    0x8004ac13, 0x03d1b000, 0x4285611e, 0x1d9ff303,
    } },
    { { /* 431 */
    0x78e8440a, 0xc3925e26, 0x00852000, 0x4000b001,
    0x88424a90, 0x0c8dca04, 0x4203a705, 0x000422a1,
    } },
    { { /* 432 */
    0x0c018668, 0x10795564, 0xdea00002, 0x40c12000,
    0x5001488b, 0x04000380, 0x50040000, 0x80d0c05d,
    } },
    { { /* 433 */
    0x970aa010, 0x4dafbb20, 0x1e10d921, 0x83140460,
    0xa6d68848, 0x733fd83b, 0x497427bc, 0x92130ddc,
    } },
    { { /* 434 */
    0x8ba1142b, 0xd1392e75, 0x50503009, 0x69008808,
    0x024a49d4, 0x80164010, 0x89d7e564, 0x5316c020,
    } },
    { { /* 435 */
    0x86002b92, 0x15e0a345, 0x0c03008b, 0xe200196e,
    0x80067031, 0xa82916a5, 0x18802000, 0xe1487aac,
    } },
    { { /* 436 */
    0xb5d63207, 0x5f9132e8, 0x20e550a1, 0x10807c00,
    0x9d8a7280, 0x421f00aa, 0x02310e22, 0x04941100,
    } },
    { { /* 437 */
    0x40080022, 0x5c100010, 0xfcc80343, 0x0580a1a5,
    0x04008433, 0x6e080080, 0x81262a4b, 0x2901aad8,
    } },
    { { /* 438 */
    0x4490684d, 0xba880009, 0x00820040, 0x87d10000,
    0xb1e6215b, 0x80083161, 0xc2400800, 0xa600a069,
    } },
    { { /* 439 */
    0x4a328d58, 0x550a5d71, 0x2d579aa0, 0x4aa64005,
    0x30b12021, 0x01123fc6, 0x260a10c2, 0x50824462,
    } },
    { { /* 440 */
    0x80409880, 0x810004c0, 0x00002003, 0x38180000,
    0xf1a60200, 0x720e4434, 0x92e035a2, 0x09008101,
    } },
    { { /* 441 */
    0x00000400, 0x00008885, 0x00000000, 0x00804000,
    0x00000000, 0x00004040, 0x00000000, 0x00000000,
    } },
    { { /* 442 */
    0x00000000, 0x08000000, 0x00000082, 0x00000000,
    0x88000004, 0xe7efbfff, 0xffbfffff, 0xfdffefef,
    } },
    { { /* 443 */
    0xbffefbff, 0x057fffff, 0x85b30034, 0x42164706,
    0xe4105402, 0xb3058092, 0x81305422, 0x180b4263,
    } },
    { { /* 444 */
    0x13f5387b, 0xa9ea07e5, 0x05143c4c, 0x80020600,
    0xbd481ad9, 0xf496ee37, 0x7ec0705f, 0x355fbfb2,
    } },
    { { /* 445 */
    0x455fe644, 0x41469000, 0x063b1d40, 0xfe1362a1,
    0x39028505, 0x0c080548, 0x0000144f, 0x58183488,
    } },
    { { /* 446 */
    0xd8153077, 0x4bfbbd0e, 0x85008a90, 0xe61dc100,
    0xb386ed14, 0x639bff72, 0xd9befd92, 0x0a92887b,
    } },
    { { /* 447 */
    0x1cb2d3fe, 0x177ab980, 0xdc1782c9, 0x3980fffb,
    0x590c4260, 0x37df0f01, 0xb15094a3, 0x23070623,
    } },
    { { /* 448 */
    0x3102f85a, 0x310201f0, 0x1e820040, 0x056a3a0a,
    0x12805b84, 0xa7148002, 0xa04b2612, 0x90011069,
    } },
    { { /* 449 */
    0x848a1000, 0x3f801802, 0x42400708, 0x4e140110,
    0x180080b0, 0x0281c510, 0x10298202, 0x88000210,
    } },
    { { /* 450 */
    0x00420020, 0x11000280, 0x4413e000, 0xfe025804,
    0x30283c07, 0x04739798, 0xcb13ced1, 0x431f6210,
    } },
    { { /* 451 */
    0x55ac278d, 0xc892422e, 0x02885380, 0x78514039,
    0x8088292c, 0x2428b900, 0x080e0c41, 0x42004421,
    } },
    { { /* 452 */
    0x08680408, 0x12040006, 0x02903031, 0xe0855b3e,
    0x10442936, 0x10822814, 0x83344266, 0x531b013c,
    } },
    { { /* 453 */
    0x0e0d0404, 0x00510c22, 0xc0000012, 0x88000040,
    0x0000004a, 0x00000000, 0x5447dff6, 0x00088868,
    } },
    { { /* 454 */
    0x00000081, 0x40000000, 0x00000100, 0x02000000,
    0x00080600, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 455 */
    0x00000080, 0x00000040, 0x00000000, 0x00001040,
    0x00000000, 0xf7fdefff, 0xfffeff7f, 0xfffffbff,
    } },
    { { /* 456 */
    0xbffffdff, 0x00ffffff, 0x042012c2, 0x07080c06,
    0x01101624, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 457 */
    0xe0000000, 0xfffffffe, 0x7f79ffff, 0x00f928df,
    0x80120c32, 0xd53a0008, 0xecc2d858, 0x2fa89d18,
    } },
    { { /* 458 */
    0xe0109620, 0x2622d60c, 0x02060f97, 0x9055b240,
    0x501180a2, 0x04049800, 0x00004000, 0x00000000,
    } },
    { { /* 459 */
    0x00000000, 0x00000000, 0x00000000, 0xfffffbc0,
    0xdffbeffe, 0x62430b08, 0xfb3b41b6, 0x23896f74,
    } },
    { { /* 460 */
    0xecd7ae7f, 0x5960e047, 0x098fa096, 0xa030612c,
    0x2aaa090d, 0x4f7bd44e, 0x388bc4b2, 0x6110a9c6,
    } },
    { { /* 461 */
    0x42000014, 0x0202800c, 0x6485fe48, 0xe3f7d63e,
    0x0c073aa0, 0x0430e40c, 0x1002f680, 0x00000000,
    } },
    { { /* 462 */
    0x00000000, 0x00000000, 0x00000000, 0x00100000,
    0x00004000, 0x00004000, 0x00000100, 0x00000000,
    } },
    { { /* 463 */
    0x00000000, 0x40000000, 0x00000000, 0x00000400,
    0x00008000, 0x00000000, 0x00400400, 0x00000000,
    } },
    { { /* 464 */
    0x00000000, 0x40000000, 0x00000000, 0x00000800,
    0xfebdffe0, 0xffffffff, 0xfbe77f7f, 0xf7ffffbf,
    } },
    { { /* 465 */
    0xefffffff, 0xdff7ff7e, 0xfbdff6f7, 0x804fbffe,
    0x00000000, 0x00000000, 0x00000000, 0x7fffef00,
    } },
    { { /* 466 */
    0xb6f7ff7f, 0xb87e4406, 0x88313bf5, 0x00f41796,
    0x1391a960, 0x72490080, 0x0024f2f3, 0x42c88701,
    } },
    { { /* 467 */
    0x5048e3d3, 0x43052400, 0x4a4c0000, 0x10580227,
    0x01162820, 0x0014a809, 0x00000000, 0x00683ec0,
    } },
    { { /* 468 */
    0x00000000, 0x00000000, 0x00000000, 0xffe00000,
    0xfddbb7ff, 0x000000f7, 0xc72e4000, 0x00000180,
    } },
    { { /* 469 */
    0x00012000, 0x00004000, 0x00300000, 0xb4f7ffa8,
    0x03ffadf3, 0x00000120, 0x00000000, 0x00000000,
    } },
    { { /* 470 */
    0x00000000, 0x00000000, 0x00000000, 0xfffbf000,
    0xfdcf9df7, 0x15c301bf, 0x810a1827, 0x0a00a842,
    } },
    { { /* 471 */
    0x80088108, 0x18048008, 0x0012a3be, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 472 */
    0x00000000, 0x00000000, 0x00000000, 0x90000000,
    0xdc3769e6, 0x3dff6bff, 0xf3f9fcf8, 0x00000004,
    } },
    { { /* 473 */
    0x80000000, 0xe7eebf6f, 0x5da2dffe, 0xc00b3fd8,
    0xa00c0984, 0x69100040, 0xb912e210, 0x5a0086a5,
    } },
    { { /* 474 */
    0x02896800, 0x6a809005, 0x00030010, 0x80000000,
    0x8e001ff9, 0x00000001, 0x00000000, 0x00000000,
    } },
    { { /* 475 */
    0x00000080, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 476 */
    0x00000000, 0x00000000, 0x00001000, 0x64080010,
    0x00480000, 0x10000020, 0x80000102, 0x08000010,
    } },
    { { /* 477 */
    0x00000040, 0x40000000, 0x00020000, 0x01852002,
    0x00800010, 0x80002022, 0x084444a2, 0x480e0000,
    } },
    { { /* 478 */
    0x04000200, 0x02202008, 0x80004380, 0x04000000,
    0x00000002, 0x12231420, 0x2058003a, 0x00200060,
    } },
    { { /* 479 */
    0x10002508, 0x040d0028, 0x00000009, 0x00008004,
    0x00800000, 0x42000001, 0x00000000, 0x09040000,
    } },
    { { /* 480 */
    0x02008000, 0x01402001, 0x00000000, 0x00000008,
    0x00000000, 0x00000001, 0x00021008, 0x04000000,
    } },
    { { /* 481 */
    0x00100100, 0x80040080, 0x00002000, 0x00000008,
    0x08040601, 0x01000012, 0x10000000, 0x49001024,
    } },
    { { /* 482 */
    0x0180004a, 0x00100600, 0x50840800, 0x000000c0,
    0x00800000, 0x20000800, 0x40000000, 0x08050000,
    } },
    { { /* 483 */
    0x02004000, 0x02000804, 0x01000004, 0x18060001,
    0x02400001, 0x40000002, 0x20800014, 0x000c1000,
    } },
    { { /* 484 */
    0x00222000, 0x00000000, 0x00100000, 0x00000000,
    0x00000000, 0x00000000, 0x10422800, 0x00000800,
    } },
    { { /* 485 */
    0x20080000, 0x00040000, 0x80025040, 0x20208604,
    0x00028020, 0x80102020, 0x080820c0, 0x10880800,
    } },
    { { /* 486 */
    0x00000000, 0x00000000, 0x00200109, 0x00100000,
    0x00000000, 0x81022700, 0x40c21404, 0x84010882,
    } },
    { { /* 487 */
    0x00004010, 0x00000000, 0x03000000, 0x00000008,
    0x00080000, 0x00000000, 0x10800001, 0x06002020,
    } },
    { { /* 488 */
    0x00000010, 0x02000000, 0x00880020, 0x00008424,
    0x00000000, 0x88000000, 0x81000100, 0x04000000,
    } },
    { { /* 489 */
    0x00004218, 0x00040000, 0x00000000, 0x80005080,
    0x00010000, 0x00040000, 0x08008000, 0x02008000,
    } },
    { { /* 490 */
    0x00020000, 0x00000000, 0x00000001, 0x04000401,
    0x00100000, 0x12200004, 0x00000000, 0x18100000,
    } },
    { { /* 491 */
    0x00000000, 0x00000800, 0x00000000, 0x00004000,
    0x00800000, 0x04000000, 0x82000002, 0x00042000,
    } },
    { { /* 492 */
    0x00080006, 0x00000000, 0x00000000, 0x04000000,
    0x80008000, 0x00810001, 0xa0000000, 0x00100410,
    } },
    { { /* 493 */
    0x00400218, 0x88084080, 0x00260008, 0x00800404,
    0x00000020, 0x00000000, 0x00000000, 0x00000200,
    } },
    { { /* 494 */
    0x00a08048, 0x00000000, 0x08000000, 0x04000000,
    0x00000000, 0x00000000, 0x00018000, 0x00200000,
    } },
    { { /* 495 */
    0x01000000, 0x00000000, 0x00000000, 0x10000000,
    0x00000000, 0x00000000, 0x00200000, 0x00102000,
    } },
    { { /* 496 */
    0x00000801, 0x00000000, 0x00000000, 0x00020000,
    0x08000000, 0x00002000, 0x20010000, 0x04002000,
    } },
    { { /* 497 */
    0x40000040, 0x50202400, 0x000a0020, 0x00040420,
    0x00000200, 0x00000080, 0x80000000, 0x00000020,
    } },
    { { /* 498 */
    0x20008000, 0x00200010, 0x00000000, 0x00000000,
    0x00400000, 0x01100000, 0x00020000, 0x80000010,
    } },
    { { /* 499 */
    0x02000000, 0x00801000, 0x00000000, 0x48058000,
    0x20c94000, 0x60000000, 0x00000001, 0x00000000,
    } },
    { { /* 500 */
    0x00004090, 0x48000000, 0x08000000, 0x28802000,
    0x00000002, 0x00014000, 0x00002000, 0x00002002,
    } },
    { { /* 501 */
    0x00010200, 0x00100000, 0x00000000, 0x00800000,
    0x10020000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 502 */
    0x00000010, 0x00000402, 0x0c000000, 0x01000400,
    0x01000021, 0x00000000, 0x00004000, 0x00004000,
    } },
    { { /* 503 */
    0x00000000, 0x00800000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x02000020,
    } },
    { { /* 504 */
    0x00000100, 0x08000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00002000, 0x00000000,
    } },
    { { /* 505 */
    0x00006000, 0x00000000, 0x00000000, 0x00000400,
    0x04000040, 0x003c0180, 0x00000200, 0x00102000,
    } },
    { { /* 506 */
    0x00000800, 0x101000c0, 0x00800000, 0x00000000,
    0x00008000, 0x02200000, 0x00020020, 0x00000000,
    } },
    { { /* 507 */
    0x00000000, 0x01000000, 0x00000000, 0x20100000,
    0x00080000, 0x00000141, 0x02001002, 0x40400001,
    } },
    { { /* 508 */
    0x00580000, 0x00000002, 0x00003000, 0x00002400,
    0x00988000, 0x00040010, 0x00002800, 0x00000008,
    } },
    { { /* 509 */
    0x40080004, 0x00000020, 0x20080000, 0x02060a00,
    0x00010040, 0x14010200, 0x40800000, 0x08031000,
    } },
    { { /* 510 */
    0x40020020, 0x0000202c, 0x2014a008, 0x00000000,
    0x80040200, 0x82020012, 0x00400000, 0x20000000,
    } },
    { { /* 511 */
    0x00000000, 0x00000000, 0x00000004, 0x04000000,
    0x00000000, 0x00000000, 0x40800100, 0x00000000,
    } },
    { { /* 512 */
    0x00000008, 0x04000040, 0x00000001, 0x000c0200,
    0x00000000, 0x08000400, 0x00000000, 0x080c0001,
    } },
    { { /* 513 */
    0x00000400, 0x00000000, 0x00000000, 0x00200000,
    0x80000000, 0x00001000, 0x00000200, 0x01000800,
    } },
    { { /* 514 */
    0x00000000, 0x00000800, 0x00000000, 0x40000000,
    0x00000000, 0x00000000, 0x00000000, 0x04040000,
    } },
    { { /* 515 */
    0x00000000, 0x00000000, 0x00000040, 0x00002000,
    0xa0000000, 0x00000000, 0x08000008, 0x00080000,
    } },
    { { /* 516 */
    0x00000020, 0x00000000, 0x40000400, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00008000,
    } },
    { { /* 517 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000800, 0x00000000, 0x00000000, 0x00200000,
    } },
    { { /* 518 */
    0x00000000, 0x00000000, 0x00000000, 0x04000000,
    0x00000008, 0x00000000, 0x00010000, 0x1b000000,
    } },
    { { /* 519 */
    0x00007000, 0x00000000, 0x10000000, 0x00000000,
    0x00000000, 0x00000080, 0x80000000, 0x00000000,
    } },
    { { /* 520 */
    0x00000000, 0x00020000, 0x00000000, 0x00200000,
    0x40000000, 0x00000010, 0x00800000, 0x00000008,
    } },
    { { /* 521 */
    0x00000000, 0x00000000, 0x02000000, 0x20000010,
    0x00000080, 0x00000000, 0x00010000, 0x00000000,
    } },
    { { /* 522 */
    0x00000000, 0x02000000, 0x00000000, 0x00000000,
    0x20000000, 0x00000040, 0x00200028, 0x00000000,
    } },
    { { /* 523 */
    0x00000000, 0x00020000, 0x00000000, 0x02000000,
    0x00000000, 0x02000000, 0x40020000, 0x51000040,
    } },
    { { /* 524 */
    0x00000080, 0x04040000, 0x00000000, 0x10000000,
    0x00022000, 0x00100000, 0x20000000, 0x00000082,
    } },
    { { /* 525 */
    0x40000000, 0x00010000, 0x00002000, 0x00000000,
    0x00000240, 0x00000000, 0x00000000, 0x00000008,
    } },
    { { /* 526 */
    0x00000000, 0x00010000, 0x00000810, 0x00080880,
    0x00004000, 0x00000000, 0x00000000, 0x00020000,
    } },
    { { /* 527 */
    0x00000000, 0x00400020, 0x00000000, 0x00000082,
    0x00000000, 0x00020001, 0x00000000, 0x00000000,
    } },
    { { /* 528 */
    0x40000018, 0x00000004, 0x00000000, 0x00000000,
    0x01000000, 0x00400000, 0x00000000, 0x00000000,
    } },
    { { /* 529 */
    0x00000001, 0x00400000, 0x00000000, 0x00080002,
    0x00000400, 0x00040000, 0x00000000, 0x00000000,
    } },
    { { /* 530 */
    0x00000800, 0x00000800, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000100, 0x00000000,
    } },
    { { /* 531 */
    0x00000000, 0x00200000, 0x00000000, 0x04108000,
    0x00000000, 0x00000000, 0x00000000, 0x00000002,
    } },
    { { /* 532 */
    0x00000000, 0x02800000, 0x04000000, 0x00000000,
    0x00000000, 0x00000004, 0x00000000, 0x00000400,
    } },
    { { /* 533 */
    0x00000000, 0x00000000, 0x10000000, 0x00040000,
    0x00400000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 534 */
    0x00200000, 0x00000200, 0x00000000, 0x10000000,
    0x00000000, 0x00000000, 0x2a000000, 0x00000000,
    } },
    { { /* 535 */
    0x00400000, 0x00000000, 0x00400000, 0x00000000,
    0x00000002, 0x40000000, 0x00000000, 0x00400000,
    } },
    { { /* 536 */
    0x40000000, 0x00001000, 0x00000000, 0x00000000,
    0x00000202, 0x02000000, 0x80000000, 0x00020000,
    } },
    { { /* 537 */
    0x00000020, 0x00000800, 0x00020421, 0x00020000,
    0x00000000, 0x00000000, 0x00000000, 0x00400000,
    } },
    { { /* 538 */
    0x00200000, 0x00000000, 0x00000001, 0x00000000,
    0x00000084, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 539 */
    0x00000000, 0x00004400, 0x00000002, 0x00100000,
    0x00000000, 0x00000000, 0x00008200, 0x00000000,
    } },
    { { /* 540 */
    0x00000000, 0x12000000, 0x00000100, 0x00000001,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 541 */
    0x00000020, 0x08100000, 0x000a0400, 0x00000081,
    0x00006000, 0x00120000, 0x00000000, 0x00000000,
    } },
    { { /* 542 */
    0x00000004, 0x08000000, 0x00004000, 0x044000c0,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 543 */
    0x40001000, 0x00000000, 0x01000001, 0x05000000,
    0x00080000, 0x02000000, 0x00000800, 0x00000000,
    } },
    { { /* 544 */
    0x00000100, 0x00000000, 0x00000000, 0x00000000,
    0x00002002, 0x01020000, 0x00800000, 0x00000000,
    } },
    { { /* 545 */
    0x00000040, 0x00004000, 0x01000000, 0x00000004,
    0x00020000, 0x00000000, 0x00000010, 0x00000000,
    } },
    { { /* 546 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00080000, 0x00010000, 0x30000300, 0x00000400,
    } },
    { { /* 547 */
    0x00000800, 0x02000000, 0x00000000, 0x00008000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 548 */
    0x00200000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x000040c0, 0x00002200, 0x12002000,
    } },
    { { /* 549 */
    0x00000000, 0x00000020, 0x20000000, 0x00000000,
    0x00000200, 0x00080800, 0x1000a000, 0x00000000,
    } },
    { { /* 550 */
    0x00000000, 0x00000000, 0x00000000, 0x00004000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 551 */
    0x00000000, 0x00000000, 0x00004280, 0x01000000,
    0x00800000, 0x00000008, 0x00000000, 0x00000000,
    } },
    { { /* 552 */
    0x00000000, 0x00000000, 0x00000000, 0x00000002,
    0x00000000, 0x20400000, 0x00000040, 0x00000000,
    } },
    { { /* 553 */
    0x00800080, 0x00800000, 0x00000000, 0x00000000,
    0x00000000, 0x00400020, 0x00000000, 0x00008000,
    } },
    { { /* 554 */
    0x01000000, 0x00000040, 0x00000000, 0x00400000,
    0x00000000, 0x00000440, 0x00000000, 0x00800000,
    } },
    { { /* 555 */
    0x01000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00080000, 0x00000000,
    } },
    { { /* 556 */
    0x01000000, 0x00000001, 0x00000000, 0x00020000,
    0x00000000, 0x20002000, 0x00000000, 0x00000004,
    } },
    { { /* 557 */
    0x00000008, 0x00100000, 0x00000000, 0x00010000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 558 */
    0x00000004, 0x00008000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00008000,
    } },
    { { /* 559 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000040, 0x00000000, 0x00004000, 0x00000000,
    } },
    { { /* 560 */
    0x00000010, 0x00002000, 0x40000040, 0x00000000,
    0x10000000, 0x00000000, 0x00008080, 0x00000000,
    } },
    { { /* 561 */
    0x00000000, 0x00000000, 0x00000080, 0x00000000,
    0x00100080, 0x000000a0, 0x00000000, 0x00000000,
    } },
    { { /* 562 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00100000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 563 */
    0x00000000, 0x00000000, 0x00001000, 0x00000000,
    0x0001000a, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 564 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x08002000, 0x00000000,
    } },
    { { /* 565 */
    0x00000808, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 566 */
    0x00004000, 0x00002400, 0x00008000, 0x40000000,
    0x00000001, 0x00002000, 0x04000000, 0x00040004,
    } },
    { { /* 567 */
    0x00000000, 0x00002000, 0x00000000, 0x00000000,
    0x00000000, 0x1c200000, 0x00000000, 0x02000000,
    } },
    { { /* 568 */
    0x00000000, 0x00080000, 0x00400000, 0x00000002,
    0x00000000, 0x00000100, 0x00000000, 0x00000000,
    } },
    { { /* 569 */
    0x00000000, 0x00000000, 0x00000000, 0x00400000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 570 */
    0x00004100, 0x00000400, 0x20200010, 0x00004004,
    0x00000000, 0x42000000, 0x00000000, 0x00000000,
    } },
    { { /* 571 */
    0x00000080, 0x00000000, 0x00000121, 0x00000200,
    0x000000b0, 0x80002000, 0x00000000, 0x00010000,
    } },
    { { /* 572 */
    0x00000010, 0x000000c0, 0x08100000, 0x00000020,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 573 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x02000000, 0x00000404, 0x00000000, 0x00000000,
    } },
    { { /* 574 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00400000, 0x00000008, 0x00000000, 0x00000000,
    } },
    { { /* 575 */
    0x00000000, 0x00000002, 0x00020000, 0x00002000,
    0x00000000, 0x00000000, 0x00000000, 0x00204000,
    } },
    { { /* 576 */
    0x00000000, 0x00100000, 0x00000000, 0x00000000,
    0x00000000, 0x00800000, 0x00000100, 0x00000001,
    } },
    { { /* 577 */
    0x10000000, 0x01000000, 0x00002400, 0x00000004,
    0x00000000, 0x00000000, 0x00000020, 0x00000002,
    } },
    { { /* 578 */
    0x00010000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 579 */
    0x00000000, 0x00002400, 0x00000000, 0x00000000,
    0x00004802, 0x00000000, 0x00000000, 0x80022000,
    } },
    { { /* 580 */
    0x00001004, 0x04208000, 0x20000020, 0x00040000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 581 */
    0x00000000, 0x00100000, 0x40010000, 0x00000000,
    0x00080000, 0x00000000, 0x00100211, 0x00000000,
    } },
    { { /* 582 */
    0x00001400, 0x00000000, 0x00000000, 0x00000000,
    0x00610000, 0x80008c00, 0x00000000, 0x00000000,
    } },
    { { /* 583 */
    0x00000100, 0x00000040, 0x00000000, 0x00000004,
    0x00004000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 584 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000400, 0x00000000,
    } },
    { { /* 585 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000210, 0x00000000, 0x00000000,
    } },
    { { /* 586 */
    0x00000000, 0x00000020, 0x00000002, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 587 */
    0x00004000, 0x00000000, 0x00000000, 0x02000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 588 */
    0x00000000, 0x00000000, 0x00080002, 0x01000020,
    0x00400000, 0x00200000, 0x00008000, 0x00000000,
    } },
    { { /* 589 */
    0x00000000, 0x00020000, 0x00000000, 0xc0020000,
    0x10000000, 0x00000080, 0x00000000, 0x00000000,
    } },
    { { /* 590 */
    0x00000210, 0x00000000, 0x00001000, 0x04480000,
    0x20000000, 0x00000004, 0x00800000, 0x02000000,
    } },
    { { /* 591 */
    0x00000000, 0x08006000, 0x00001000, 0x00000000,
    0x00000000, 0x00100000, 0x00000000, 0x00000400,
    } },
    { { /* 592 */
    0x00100000, 0x00000000, 0x10000000, 0x08608000,
    0x00000000, 0x00000000, 0x00080002, 0x00000000,
    } },
    { { /* 593 */
    0x00000000, 0x20000000, 0x00008020, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 594 */
    0x00000000, 0x00000000, 0x00000000, 0x10000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 595 */
    0x00000000, 0x00100000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 596 */
    0x00000000, 0x00000400, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 597 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x02000000,
    } },
    { { /* 598 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000080, 0x00000000,
    } },
    { { /* 599 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000002, 0x00000000, 0x00000000,
    } },
    { { /* 600 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00008000, 0x00000000,
    } },
    { { /* 601 */
    0x00000000, 0x00000000, 0x00000008, 0x00000000,
    0x00000000, 0x00000000, 0x00000400, 0x00000000,
    } },
    { { /* 602 */
    0x00000000, 0x00000000, 0x00220000, 0x00000004,
    0x00000000, 0x00040000, 0x00000004, 0x00000000,
    } },
    { { /* 603 */
    0x00000000, 0x00000000, 0x00001000, 0x00000080,
    0x00002000, 0x00000000, 0x00000000, 0x00004000,
    } },
    { { /* 604 */
    0x00000000, 0x00000000, 0x00000000, 0x00100000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 605 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00200000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 606 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x04000000, 0x00000000, 0x00000000,
    } },
    { { /* 607 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000200, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 608 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000001, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 609 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00080000, 0x00000000,
    } },
    { { /* 610 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x01000000, 0x00000000, 0x00000400,
    } },
    { { /* 611 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000080, 0x00000000, 0x00000000,
    } },
    { { /* 612 */
    0x00000000, 0x00000800, 0x00000100, 0x40000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 613 */
    0x00000000, 0x00200000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 614 */
    0x00000000, 0x00000000, 0x01000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 615 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x04000000, 0x00000000,
    } },
    { { /* 616 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00001000, 0x00000000,
    } },
    { { /* 617 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000400, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 618 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x04040000,
    } },
    { { /* 619 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000020, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 620 */
    0x00000000, 0x00000000, 0x00800000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 621 */
    0x00000000, 0x00200000, 0x40000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 622 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x20000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 623 */
    0x00000000, 0x00000000, 0x00000000, 0x04000000,
    0x00000000, 0x00000001, 0x00000000, 0x00000000,
    } },
    { { /* 624 */
    0x00000000, 0x40000000, 0x02000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 625 */
    0x00000000, 0x00000000, 0x00000000, 0x00080000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 626 */
    0x00000000, 0x00000010, 0x00000000, 0x00000000,
    0x00000000, 0x20000000, 0x00000000, 0x00000000,
    } },
    { { /* 627 */
    0x00000000, 0x00000000, 0x20000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 628 */
    0x00000080, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000004,
    } },
    { { /* 629 */
    0x00000000, 0x00000000, 0x00000000, 0x00002000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 630 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x10000001, 0x00000000,
    } },
    { { /* 631 */
    0x00008000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 632 */
    0x00000000, 0x00000000, 0x00004040, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 633 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00042400, 0x00000000,
    } },
    { { /* 634 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x02000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 635 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000080,
    } },
    { { /* 636 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000020,
    } },
    { { /* 637 */
    0x00000000, 0x00000001, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 638 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00020000, 0x00000000,
    } },
    { { /* 639 */
    0x00000000, 0x00000000, 0x00002000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 640 */
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    0x01000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 641 */
    0x00000000, 0x00040000, 0x08000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 642 */
    0xc373ff8b, 0x1b0f6840, 0xf34ce9ac, 0xc0080200,
    0xca3e795c, 0x06487976, 0xf7f02fdf, 0xa8ff033a,
    } },
    { { /* 643 */
    0x233fef37, 0xfd59b004, 0xfffff3ca, 0xfff9de9f,
    0x7df7abff, 0x8eecc000, 0xffdbeebf, 0x45fad003,
    } },
    { { /* 644 */
    0xdffefae1, 0x10abbfef, 0xfcaaffeb, 0x24fdef3f,
    0x7f7678ad, 0xedfff00c, 0x2cfacff6, 0xeb6bf7f9,
    } },
    { { /* 645 */
    0x95bf1ffd, 0xbfbf6677, 0xfeb43bfb, 0x11e27bae,
    0x41bea681, 0x72c31435, 0x71917d70, 0x276b0003,
    } },
    { { /* 646 */
    0x70cf57cb, 0x0def4732, 0xfc747eda, 0xbdb4fe06,
    0x8bca3f9f, 0x58007e49, 0xebec228f, 0xddbb8a5c,
    } },
    { { /* 647 */
    0xb6e7ef60, 0xf293a40f, 0x549e37bb, 0x9bafd04b,
    0xf7d4c414, 0x0a1430b0, 0x88d02f08, 0x192fff7e,
    } },
    { { /* 648 */
    0xfb07ffda, 0x7beb7ff1, 0x0010c5ef, 0xfdff99ff,
    0x056779d7, 0xfdcbffe7, 0x4040c3ff, 0xbd8e6ff7,
    } },
    { { /* 649 */
    0x0497dffa, 0x5bfff4c0, 0xd0e7ed7b, 0xf8e0047e,
    0xb73eff9f, 0x882e7dfe, 0xbe7ffffd, 0xf6c483fe,
    } },
    { { /* 650 */
    0xb8fdf357, 0xef7dd680, 0x47885767, 0xc3dfff7d,
    0x37a9f0ff, 0x70fc7de0, 0xec9a3f6f, 0x86814cb3,
    } },
    { { /* 651 */
    0xdd5c3f9e, 0x4819f70d, 0x0007fea3, 0x38ffaf56,
    0xefb8980d, 0xb760403d, 0x9035d8ce, 0x3fff72bf,
    } },
    { { /* 652 */
    0x7a117ff7, 0xabfff7bb, 0x6fbeff00, 0xfe72a93c,
    0xf11bcfef, 0xf40adb6b, 0xef7ec3e6, 0xf6109b9c,
    } },
    { { /* 653 */
    0x16f4f048, 0x5182feb5, 0x15bbc7b1, 0xfbdf6e87,
    0x63cde43f, 0x7e7ec1ff, 0x7d5ffdeb, 0xfcfe777b,
    } },
    { { /* 654 */
    0xdbea960b, 0x53e86229, 0xfdef37df, 0xbd8136f5,
    0xfcbddc18, 0xffffd2e4, 0xffe03fd7, 0xabf87f6f,
    } },
    { { /* 655 */
    0x6ed99bae, 0xf115f5fb, 0xbdfb79a9, 0xadaf5a3c,
    0x1facdbba, 0x837971fc, 0xc35f7cf7, 0x0567dfff,
    } },
    { { /* 656 */
    0x8467ff9a, 0xdf8b1534, 0x3373f9f3, 0x5e1af7bd,
    0xa03fbf40, 0x01ebffff, 0xcfdddfc0, 0xabd37500,
    } },
    { { /* 657 */
    0xeed6f8c3, 0xb7ff43fd, 0x42275eaf, 0xf6869bac,
    0xf6bc27d7, 0x35b7f787, 0xe176aacd, 0xe29f49e7,
    } },
    { { /* 658 */
    0xaff2545c, 0x61d82b3f, 0xbbb8fc3b, 0x7b7dffcf,
    0x1ce0bf95, 0x43ff7dfd, 0xfffe5ff6, 0xc4ced3ef,
    } },
    { { /* 659 */
    0xadbc8db6, 0x11eb63dc, 0x23d0df59, 0xf3dbbeb4,
    0xdbc71fe7, 0xfae4ff63, 0x63f7b22b, 0xadbaed3b,
    } },
    { { /* 660 */
    0x7efffe01, 0x02bcfff7, 0xef3932ff, 0x8005fffc,
    0xbcf577fb, 0xfff7010d, 0xbf3afffb, 0xdfff0057,
    } },
    { { /* 661 */
    0xbd7def7b, 0xc8d4db88, 0xed7cfff3, 0x56ff5dee,
    0xac5f7e0d, 0xd57fff96, 0xc1403fee, 0xffe76ff9,
    } },
    { { /* 662 */
    0x8e77779b, 0xe45d6ebf, 0x5f1f6fcf, 0xfedfe07f,
    0x01fed7db, 0xfb7bff00, 0x1fdfffd4, 0xfffff800,
    } },
    { { /* 663 */
    0x007bfb8f, 0x7f5cbf00, 0x07f3ffff, 0x3de7eba0,
    0xfbd7f7bf, 0x6003ffbf, 0xbfedfffd, 0x027fefbb,
    } },
    { { /* 664 */
    0xddfdfe40, 0xe2f9fdff, 0xfb1f680b, 0xaffdfbe3,
    0xf7ed9fa4, 0xf80f7a7d, 0x0fd5eebe, 0xfd9fbb5d,
    } },
    { { /* 665 */
    0x3bf9f2db, 0xebccfe7f, 0x73fa876a, 0x9ffc95fc,
    0xfaf7109f, 0xbbcdddb7, 0xeccdf87e, 0x3c3ff366,
    } },
    { { /* 666 */
    0xb03ffffd, 0x067ee9f7, 0xfe0696ae, 0x5fd7d576,
    0xa3f33fd1, 0x6fb7cf07, 0x7f449fd1, 0xd3dd7b59,
    } },
    { { /* 667 */
    0xa9bdaf3b, 0xff3a7dcf, 0xf6ebfbe0, 0xffffb401,
    0xb7bf7afa, 0x0ffdc000, 0xff1fff7f, 0x95fffefc,
    } },
    { { /* 668 */
    0xb5dc0000, 0x3f3eef63, 0x001bfb7f, 0xfbf6e800,
    0xb8df9eef, 0x003fff9f, 0xf5ff7bd0, 0x3fffdfdb,
    } },
    { { /* 669 */
    0x00bffdf0, 0xbbbd8420, 0xffdedf37, 0x0ff3ff6d,
    0x5efb604c, 0xfafbfffb, 0x0219fe5e, 0xf9de79f4,
    } },
    { { /* 670 */
    0xebfaa7f7, 0xff3401eb, 0xef73ebd3, 0xc040afd7,
    0xdcff72bb, 0x2fd8f17f, 0xfe0bb8ec, 0x1f0bdda3,
    } },
    { { /* 671 */
    0x47cf8f1d, 0xffdeb12b, 0xda737fee, 0xcbc424ff,
    0xcbf2f75d, 0xb4edecfd, 0x4dddbff9, 0xfb8d99dd,
    } },
    { { /* 672 */
    0xaf7bbb7f, 0xc959ddfb, 0xfab5fc4f, 0x6d5fafe3,
    0x3f7dffff, 0xffdb7800, 0x7effb6ff, 0x022ffbaf,
    } },
    { { /* 673 */
    0xefc7ff9b, 0xffffffa5, 0xc7000007, 0xfff1f7ff,
    0x01bf7ffd, 0xfdbcdc00, 0xffffbff5, 0x3effff7f,
    } },
    { { /* 674 */
    0xbe000029, 0xff7ff9ff, 0xfd7e6efb, 0x039ecbff,
    0xfbdde300, 0xf6dfccff, 0x117fffff, 0xfbf6f800,
    } },
    { { /* 675 */
    0xd73ce7ef, 0xdfeffeef, 0xedbfc00b, 0xfdcdfedf,
    0x40fd7bf5, 0xb75fffff, 0xf930ffdf, 0xdc97fbdf,
    } },
    { { /* 676 */
    0xbff2fef3, 0xdfbf8fdf, 0xede6177f, 0x35530f7f,
    0x877e447c, 0x45bbfa12, 0x779eede0, 0xbfd98017,
    } },
    { { /* 677 */
    0xde897e55, 0x0447c16f, 0xf75d7ade, 0x290557ff,
    0xfe9586f7, 0xf32f97b3, 0x9f75cfff, 0xfb1771f7,
    } },
    { { /* 678 */
    0xee1934ee, 0xef6137cc, 0xef4c9fd6, 0xfbddd68f,
    0x6def7b73, 0xa431d7fe, 0x97d75e7f, 0xffd80f5b,
    } },
    { { /* 679 */
    0x7bce9d83, 0xdcff22ec, 0xef87763d, 0xfdeddfe7,
    0xa0fc4fff, 0xdbfc3b77, 0x7fdc3ded, 0xf5706fa9,
    } },
    { { /* 680 */
    0x2c403ffb, 0x847fff7f, 0xdeb7ec57, 0xf22fe69c,
    0xd5b50feb, 0xede7afeb, 0xfff08c2f, 0xe8f0537f,
    } },
    { { /* 681 */
    0xb5ffb99d, 0xe78fff66, 0xbe10d981, 0xe3c19c7c,
    0x27339cd1, 0xff6d0cbc, 0xefb7fcb7, 0xffffa0df,
    } },
    { { /* 682 */
    0xfe7bbf0b, 0x353fa3ff, 0x97cd13cc, 0xfb277637,
    0x7e6ccfd6, 0xed31ec50, 0xfc1c677c, 0x5fbff6fa,
    } },
    { { /* 683 */
    0xae2f0fba, 0x7ffea3ad, 0xde74fcf0, 0xf200ffef,
    0xfea2fbbf, 0xbcff3daf, 0x5fb9f694, 0x3f8ff3ad,
    } },
    { { /* 684 */
    0xa01ff26c, 0x01bfffef, 0x70057728, 0xda03ff35,
    0xc7fad2f9, 0x5c1d3fbf, 0xec33ff3a, 0xfe9cb7af,
    } },
    { { /* 685 */
    0x7a9f5236, 0xe722bffa, 0xfcff9ff7, 0xb61d2fbb,
    0x1dfded06, 0xefdf7dd7, 0xf166eb23, 0x0dc07ed9,
    } },
    { { /* 686 */
    0xdfbf3d3d, 0xba83c945, 0x9dd07dd1, 0xcf737b87,
    0xc3f59ff3, 0xc5fedf0d, 0x83020cb3, 0xaec0e879,
    } },
    { { /* 687 */
    0x6f0fc773, 0x093ffd7d, 0x0157fff1, 0x01ff62fb,
    0x3bf3fdb4, 0x43b2b013, 0xff305ed3, 0xeb9f0fff,
    } },
    { { /* 688 */
    0xf203feef, 0xfb893fef, 0x9e9937a9, 0xa72cdef9,
    0xc1f63733, 0xfe3e812e, 0xf2f75d20, 0x69d7d585,
    } },
    { { /* 689 */
    0xffffffff, 0xff6fdb07, 0xd97fc4ff, 0xbe0fefce,
    0xf05ef17b, 0xffb7f6cf, 0xef845ef7, 0x0edfd7cb,
    } },
    { { /* 690 */
    0xfcffff08, 0xffffee3f, 0xd7ff13ff, 0x7ffdaf0f,
    0x1ffabdc7, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 691 */
    0x00000000, 0xe7400000, 0xf933bd38, 0xfeed7feb,
    0x7c767fe8, 0xffefb3f7, 0xd8b7feaf, 0xfbbfff6f,
    } },
    { { /* 692 */
    0xdbf7f8fb, 0xe2f91752, 0x754785c8, 0xe3ef9090,
    0x3f6d9ef4, 0x0536ee2e, 0x7ff3f7bc, 0x7f3fa07b,
    } },
    { { /* 693 */
    0xeb600567, 0x6601babe, 0x583ffcd8, 0x87dfcaf7,
    0xffa0bfcd, 0xfebf5bcd, 0xefa7b6fd, 0xdf9c77ef,
    } },
    { { /* 694 */
    0xf8773fb7, 0xb7fc9d27, 0xdfefcab5, 0xf1b6fb5a,
    0xef1fec39, 0x7ffbfbbf, 0xdafe000d, 0x4e7fbdfb,
    } },
    { { /* 695 */
    0x5ac033ff, 0x9ffebff5, 0x005fffbf, 0xfdf80000,
    0x6ffdffca, 0xa001cffd, 0xfbf2dfff, 0xff7fdfbf,
    } },
    { { /* 696 */
    0x080ffeda, 0xbfffba08, 0xeed77afd, 0x67f9fbeb,
    0xff93e044, 0x9f57df97, 0x08dffef7, 0xfedfdf80,
    } },
    { { /* 697 */
    0xf7feffc5, 0x6803fffb, 0x6bfa67fb, 0x5fe27fff,
    0xff73ffff, 0xe7fb87df, 0xf7a7ebfd, 0xefc7bf7e,
    } },
    { { /* 698 */
    0xdf821ef3, 0xdf7e76ff, 0xda7d79c9, 0x1e9befbe,
    0x77fb7ce0, 0xfffb87be, 0xffdb1bff, 0x4fe03f5c,
    } },
    { { /* 699 */
    0x5f0e7fff, 0xddbf77ff, 0xfffff04f, 0x0ff8ffff,
    0xfddfa3be, 0xfffdfc1c, 0xfb9e1f7d, 0xdedcbdff,
    } },
    { { /* 700 */
    0xbafb3f6f, 0xfbefdf7f, 0x2eec7d1b, 0xf2f7af8e,
    0xcfee7b0f, 0x77c61d96, 0xfff57e07, 0x7fdfd982,
    } },
    { { /* 701 */
    0xc7ff5ee6, 0x79effeee, 0xffcf9a56, 0xde5efe5f,
    0xf9e8896e, 0xe6c4f45e, 0xbe7c0001, 0xdddf3b7f,
    } },
    { { /* 702 */
    0xe9efd59d, 0xde5334ac, 0x4bf7f573, 0x9eff7b4f,
    0x476eb8fe, 0xff450dfb, 0xfbfeabfd, 0xddffe9d7,
    } },
    { { /* 703 */
    0x7fffedf7, 0x7eebddfd, 0xb7ffcfe7, 0xef91bde9,
    0xd77c5d75, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 704 */
    0x00000000, 0xfa800000, 0xb4f1ffee, 0x2fefbf76,
    0x77bfb677, 0xfffd9fbf, 0xf6ae95bf, 0x7f3b75ff,
    } },
    { { /* 705 */
    0x0af9a7f5, 0x00000000, 0x00000000, 0x2bddfbd0,
    0x9a7ff633, 0xd6fcfdab, 0xbfebf9e6, 0xf41fdfdf,
    } },
    { { /* 706 */
    0xffffa6fd, 0xf37b4aff, 0xfef97fb7, 0x1d5cb6ff,
    0xe5ff7ff6, 0x24041f7b, 0xf99ebe05, 0xdff2dbe3,
    } },
    { { /* 707 */
    0xfdff6fef, 0xcbfcd679, 0xefffebfd, 0x0000001f,
    0x98000000, 0x8017e148, 0x00fe6a74, 0xfdf16d7f,
    } },
    { { /* 708 */
    0xfef3b87f, 0xf176e01f, 0x7b3fee96, 0xfffdeb8d,
    0xcbb3adff, 0xe17f84ef, 0xbff04daa, 0xfe3fbf3f,
    } },
    { { /* 709 */
    0xffd7ebff, 0xcf7fffdf, 0x85edfffb, 0x07bcd73f,
    0xfe0faeff, 0x76bffdaf, 0x37bbfaef, 0xa3ba7fdc,
    } },
    { { /* 710 */
    0x56f7b6ff, 0xe7df60f8, 0x4cdfff61, 0xff45b0fb,
    0x3ffa7ded, 0x18fc1fff, 0xe3afffff, 0xdf83c7d3,
    } },
    { { /* 711 */
    0xef7dfb57, 0x1378efff, 0x5ff7fec0, 0x5ee334bb,
    0xeff6f70d, 0x00bfd7fe, 0xf7f7f59d, 0xffe051de,
    } },
    { { /* 712 */
    0x037ffec9, 0xbfef5f01, 0x60a79ff1, 0xf1ffef1d,
    0x0000000f, 0x00000000, 0x00000000, 0x00000000,
    } },
    { { /* 713 */
    0x00000000, 0x00000000, 0x00000000, 0x3c800000,
    0xd91ffb4d, 0xfee37b3a, 0xdc7f3fe9, 0x0000003f,
    } },
    { { /* 714 */
    0x50000000, 0xbe07f51f, 0xf91bfc1d, 0x71ffbc1e,
    0x5bbe6ff9, 0x9b1b5796, 0xfffc7fff, 0xafe7872e,
    } },
    { { /* 715 */
    0xf34febf5, 0xe725dffd, 0x5d440bdc, 0xfddd5747,
    0x7790ed3f, 0x8ac87d7f, 0xf3f9fafa, 0xef4b202a,
    } },
    { { /* 716 */
    0x79cff5ff, 0x0ba5abd3, 0xfb8ff77a, 0x001f8ebd,
    0x00000000, 0xfd4ef300, 0x88001a57, 0x7654aeac,
    } },
    { { /* 717 */
    0xcdff17ad, 0xf42fffb2, 0xdbff5baa, 0x00000002,
    0x73c00000, 0x2e3ff9ea, 0xbbfffa8e, 0xffd376bc,
    } },
    { { /* 718 */
    0x7e72eefe, 0xe7f77ebd, 0xcefdf77f, 0x00000ff5,
    0x00000000, 0xdb9ba900, 0x917fa4c7, 0x7ecef8ca,
    } },
    { { /* 719 */
    0xc7e77d7a, 0xdcaecbbd, 0x8f76fd7e, 0x7cf391d3,
    0x4c2f01e5, 0xa360ed77, 0x5ef807db, 0x21811df7,
    } },
    { { /* 720 */
    0x309c6be0, 0xfade3b3a, 0xc3f57f53, 0x07ba61cd,
    0x00000000, 0x00000000, 0x00000000, 0xbefe26e0,
    } },
    { { /* 721 */
    0xebb503f9, 0xe9cbe36d, 0xbfde9c2f, 0xabbf9f83,
    0xffd51ff7, 0xdffeb7df, 0xffeffdae, 0xeffdfb7e,
    } },
    { { /* 722 */
    0x6ebfaaff, 0x00000000, 0x00000000, 0xb6200000,
    0xbe9e7fcd, 0x58f162b3, 0xfd7bf10d, 0xbefde9f1,
    } },
    { { /* 723 */
    0x5f6dc6c3, 0x69ffff3d, 0xfbf4ffcf, 0x4ff7dcfb,
    0x11372000, 0x00000015, 0x00000000, 0x00000000,
    } },
    { { /* 724 */
    0x00003000, 0x00000000, 0x00000000, 0x00000000,
    0x00000000, 0x00000000, 0x00000000, 0x00000000,
    } },
},
{
    /* aa */
    LEAF(  0,  0),
    /* ab */
    LEAF(  1,  1),
    /* af */
    LEAF(  2,  2), LEAF(  2,  3),
    /* ak */
    LEAF(  4,  4), LEAF(  4,  5), LEAF(  4,  6), LEAF(  4,  7),
    LEAF(  4,  8),
    /* am */
    LEAF(  9,  9), LEAF(  9, 10),
    /* an */
    LEAF( 11, 11),
    /* ar */
    LEAF( 12, 12),
    /* as */
    LEAF( 13, 13),
    /* ast */
    LEAF( 14, 11), LEAF( 14, 14),
    /* av */
    LEAF( 16, 15),
    /* ay */
    LEAF( 17, 16),
    /* az_az */
    LEAF( 18, 17), LEAF( 18, 18), LEAF( 18, 19),
    /* az_ir */
    LEAF( 21, 20),
    /* ba */
    LEAF( 22, 21),
    /* be */
    LEAF( 23, 22),
    /* ber_dz */
    LEAF( 24, 23), LEAF( 24, 24), LEAF( 24, 25), LEAF( 24, 26),
    /* ber_ma */
    LEAF( 28, 27),
    /* bg */
    LEAF( 29, 28),
    /* bh */
    LEAF( 30, 29),
    /* bi */
    LEAF( 31, 30),
    /* bin */
    LEAF( 32, 31), LEAF( 32, 32), LEAF( 32, 33),
    /* bm */
    LEAF( 35, 23), LEAF( 35, 34), LEAF( 35, 35),
    /* bn */
    LEAF( 38, 36),
    /* bo */
    LEAF( 39, 37),
    /* br */
    LEAF( 40, 38),
    /* brx */
    LEAF( 41, 39),
    /* bs */
    LEAF( 42, 23), LEAF( 42, 40),
    /* bua */
    LEAF( 44, 41),
    /* byn */
    LEAF( 45, 42), LEAF( 45, 43),
    /* ca */
    LEAF( 47, 44), LEAF( 47, 45),
    /* ch */
    LEAF( 49, 46),
    /* chm */
    LEAF( 50, 47),
    /* chr */
    LEAF( 51, 48),
    /* co */
    LEAF( 52, 49), LEAF( 52, 50),
    /* crh */
    LEAF( 54, 51), LEAF( 54, 52),
    /* cs */
    LEAF( 56, 53), LEAF( 56, 54),
    /* csb */
    LEAF( 58, 55), LEAF( 58, 56),
    /* cu */
    LEAF( 60, 57),
    /* cv */
    LEAF( 61, 58), LEAF( 61, 59),
    /* cy */
    LEAF( 63, 60), LEAF( 63, 61), LEAF( 63, 62),
    /* da */
    LEAF( 66, 63),
    /* de */
    LEAF( 67, 64),
    /* doi */
    LEAF( 68, 65),
    /* dv */
    LEAF( 69, 66),
    /* ee */
    LEAF( 70, 31), LEAF( 70, 67), LEAF( 70, 68), LEAF( 70, 69),
    /* el */
    LEAF( 74, 70),
    /* en */
    LEAF( 75, 71),
    /* eo */
    LEAF( 76, 23), LEAF( 76, 72),
    /* et */
    LEAF( 78, 73), LEAF( 78, 74),
    /* eu */
    LEAF( 80, 75),
    /* ff */
    LEAF( 81, 23), LEAF( 81, 76), LEAF( 81, 77),
    /* fi */
    LEAF( 84, 78), LEAF( 84, 74),
    /* fil */
    LEAF( 86, 79),
    /* fj */
    LEAF( 87, 23),
    /* fo */
    LEAF( 88, 80),
    /* fur */
    LEAF( 89, 81),
    /* fy */
    LEAF( 90, 82),
    /* ga */
    LEAF( 91, 83), LEAF( 91, 84), LEAF( 91, 85),
    /* gd */
    LEAF( 94, 86),
    /* gez */
    LEAF( 95, 87), LEAF( 95, 88),
    /* gn */
    LEAF( 97, 89), LEAF( 97, 90), LEAF( 97, 91),
    /* gu */
    LEAF(100, 92),
    /* gv */
    LEAF(101, 93),
    /* ha */
    LEAF(102, 23), LEAF(102, 94), LEAF(102, 95),
    /* haw */
    LEAF(105, 23), LEAF(105, 96), LEAF(105, 97),
    /* he */
    LEAF(108, 98),
    /* hsb */
    LEAF(109, 99), LEAF(109,100),
    /* ht */
    LEAF(111,101),
    /* hu */
    LEAF(112,102), LEAF(112,103),
    /* hy */
    LEAF(114,104),
    /* hz */
    LEAF(115, 23), LEAF(115,105), LEAF(115,106),
    /* id */
    LEAF(118,107),
    /* ig */
    LEAF(119, 23), LEAF(119,108),
    /* ii */
    LEAF(121,109), LEAF(121,109), LEAF(121,109), LEAF(121,109),
    LEAF(121,110),
    /* ik */
    LEAF(126,111),
    /* is */
    LEAF(127,112),
    /* it */
    LEAF(128,113),
    /* iu */
    LEAF(129,114), LEAF(129,115), LEAF(129,116),
    /* ja */
    LEAF(132,117), LEAF(132,118), LEAF(132,119), LEAF(132,120),
    LEAF(132,121), LEAF(132,122), LEAF(132,123), LEAF(132,124),
    LEAF(132,125), LEAF(132,126), LEAF(132,127), LEAF(132,128),
    LEAF(132,129), LEAF(132,130), LEAF(132,131), LEAF(132,132),
    LEAF(132,133), LEAF(132,134), LEAF(132,135), LEAF(132,136),
    LEAF(132,137), LEAF(132,138), LEAF(132,139), LEAF(132,140),
    LEAF(132,141), LEAF(132,142), LEAF(132,143), LEAF(132,144),
    LEAF(132,145), LEAF(132,146), LEAF(132,147), LEAF(132,148),
    LEAF(132,149), LEAF(132,150), LEAF(132,151), LEAF(132,152),
    LEAF(132,153), LEAF(132,154), LEAF(132,155), LEAF(132,156),
    LEAF(132,157), LEAF(132,158), LEAF(132,159), LEAF(132,160),
    LEAF(132,161), LEAF(132,162), LEAF(132,163), LEAF(132,164),
    LEAF(132,165), LEAF(132,166), LEAF(132,167), LEAF(132,168),
    LEAF(132,169), LEAF(132,170), LEAF(132,171), LEAF(132,172),
    LEAF(132,173), LEAF(132,174), LEAF(132,175), LEAF(132,176),
    LEAF(132,177), LEAF(132,178), LEAF(132,179), LEAF(132,180),
    LEAF(132,181), LEAF(132,182), LEAF(132,183), LEAF(132,184),
    LEAF(132,185), LEAF(132,186), LEAF(132,187), LEAF(132,188),
    LEAF(132,189), LEAF(132,190), LEAF(132,191), LEAF(132,192),
    LEAF(132,193), LEAF(132,194), LEAF(132,195), LEAF(132,196),
    LEAF(132,197), LEAF(132,198), LEAF(132,199),
    /* jv */
    LEAF(215,200),
    /* ka */
    LEAF(216,201),
    /* kaa */
    LEAF(217,202),
    /* ki */
    LEAF(218, 23), LEAF(218,203),
    /* kk */
    LEAF(220,204),
    /* kl */
    LEAF(221,205), LEAF(221,206),
    /* km */
    LEAF(223,207),
    /* kn */
    LEAF(224,208),
    /* ko */
    LEAF(225,209), LEAF(225,210), LEAF(225,211), LEAF(225,212),
    LEAF(225,213), LEAF(225,214), LEAF(225,215), LEAF(225,216),
    LEAF(225,217), LEAF(225,218), LEAF(225,219), LEAF(225,220),
    LEAF(225,221), LEAF(225,222), LEAF(225,223), LEAF(225,224),
    LEAF(225,225), LEAF(225,226), LEAF(225,227), LEAF(225,228),
    LEAF(225,229), LEAF(225,230), LEAF(225,231), LEAF(225,232),
    LEAF(225,233), LEAF(225,234), LEAF(225,235), LEAF(225,236),
    LEAF(225,237), LEAF(225,238), LEAF(225,239), LEAF(225,240),
    LEAF(225,241), LEAF(225,242), LEAF(225,243), LEAF(225,244),
    LEAF(225,245), LEAF(225,246), LEAF(225,247), LEAF(225,248),
    LEAF(225,249), LEAF(225,250), LEAF(225,251), LEAF(225,252),
    LEAF(225,253),
    /* kr */
    LEAF(270, 23), LEAF(270,254), LEAF(270,255),
    /* ks */
    LEAF(273,256),
    /* ku_am */
    LEAF(274,257), LEAF(274,258),
    /* ku_iq */
    LEAF(276,259),
    /* ku_tr */
    LEAF(277,260), LEAF(277,261),
    /* kum */
    LEAF(279,262),
    /* kv */
    LEAF(280,263),
    /* kw */
    LEAF(281, 23), LEAF(281, 96), LEAF(281,264),
    /* ky */
    LEAF(284,265),
    /* la */
    LEAF(285, 23), LEAF(285,266),
    /* lah */
    LEAF(287,267),
    /* lb */
    LEAF(288,268),
    /* lg */
    LEAF(289, 23), LEAF(289,269),
    /* li */
    LEAF(291,270),
    /* ln */
    LEAF(292,271), LEAF(292,272), LEAF(292,  6), LEAF(292,273),
    /* lo */
    LEAF(296,274),
    /* lt */
    LEAF(297, 23), LEAF(297,275),
    /* lv */
    LEAF(299, 23), LEAF(299,276),
    /* mg */
    LEAF(301,277),
    /* mh */
    LEAF(302, 23), LEAF(302,278),
    /* mi */
    LEAF(304, 23), LEAF(304, 96), LEAF(304,279),
    /* mk */
    LEAF(307,280),
    /* ml */
    LEAF(308,281),
    /* mn_cn */
    LEAF(309,282),
    /* mn_mn */
    LEAF(310,283),
    /* mni */
    LEAF(311,284),
    /* mo */
    LEAF(312,285), LEAF(312, 58), LEAF(312,286), LEAF(312,262),
    /* mt */
    LEAF(316,287), LEAF(316,288),
    /* my */
    LEAF(318,289),
    /* na */
    LEAF(319,  4), LEAF(319,290),
    /* nb */
    LEAF(321,291),
    /* ne */
    LEAF(322,292),
    /* nl */
    LEAF(323,293),
    /* nn */
    LEAF(324,294),
    /* nqo */
    LEAF(325,295),
    /* nso */
    LEAF(326,296), LEAF(326,297),
    /* nv */
    LEAF(328,298), LEAF(328,299), LEAF(328,300), LEAF(328,301),
    /* ny */
    LEAF(332, 23), LEAF(332,302),
    /* oc */
    LEAF(334,303),
    /* or */
    LEAF(335,304),
    /* ota */
    LEAF(336,305),
    /* pa */
    LEAF(337,306),
    /* pap_an */
    LEAF(338,307),
    /* pap_aw */
    LEAF(339,308),
    /* pl */
    LEAF(340, 99), LEAF(340,309),
    /* ps_af */
    LEAF(342,310),
    /* ps_pk */
    LEAF(343,311),
    /* pt */
    LEAF(344,312),
    /* qu */
    LEAF(345,308), LEAF(345,313),
    /* rm */
    LEAF(347,314),
    /* ro */
    LEAF(348,285), LEAF(348, 58), LEAF(348,286),
    /* sah */
    LEAF(351,315),
    /* sat */
    LEAF(352,316),
    /* sc */
    LEAF(353,317),
    /* sco */
    LEAF(354, 23), LEAF(354,318), LEAF(354,319),
    /* sd */
    LEAF(357,320),
    /* se */
    LEAF(358,321), LEAF(358,322),
    /* sg */
    LEAF(360,323),
    /* sh */
    LEAF(361, 23), LEAF(361, 40), LEAF(361,324),
    /* shs */
    LEAF(364,325), LEAF(364,326),
    /* si */
    LEAF(366,327),
    /* sid */
    LEAF(367,328), LEAF(367, 10),
    /* sk */
    LEAF(369,329), LEAF(369,330),
    /* sm */
    LEAF(371, 23), LEAF(371, 97),
    /* sma */
    LEAF(373,331),
    /* smj */
    LEAF(374,332),
    /* smn */
    LEAF(375,333), LEAF(375,334),
    /* sms */
    LEAF(377,335), LEAF(377,336), LEAF(377,337),
    /* sq */
    LEAF(380,338),
    /* sr */
    LEAF(381,339),
    /* sv */
    LEAF(382,340),
    /* syr */
    LEAF(383,341),
    /* ta */
    LEAF(384,342),
    /* te */
    LEAF(385,343),
    /* tg */
    LEAF(386,344),
    /* th */
    LEAF(387,345),
    /* tig */
    LEAF(388,346), LEAF(388, 43),
    /* tk */
    LEAF(390,347), LEAF(390,348),
    /* tr */
    LEAF(392,349), LEAF(392, 52),
    /* tt */
    LEAF(394,350),
    /* ty */
    LEAF(395,351), LEAF(395, 96), LEAF(395,300),
    /* ug */
    LEAF(398,352),
    /* uk */
    LEAF(399,353),
    /* und_zmth */
    LEAF(400,354), LEAF(400,355), LEAF(400,356), LEAF(400,357),
    LEAF(400,358), LEAF(400,359), LEAF(400,360), LEAF(400,361),
    LEAF(400,362), LEAF(400,363), LEAF(400,364), LEAF(400,365),
    /* und_zsye */
    LEAF(412,366), LEAF(412,367), LEAF(412,368), LEAF(412,369),
    LEAF(412,370), LEAF(412,371), LEAF(412,372), LEAF(412,373),
    LEAF(412,374), LEAF(412,375), LEAF(412,376), LEAF(412,377),
    /* ve */
    LEAF(424, 23), LEAF(424,378),
    /* vi */
    LEAF(426,379), LEAF(426,380), LEAF(426,381), LEAF(426,382),
    /* vo */
    LEAF(430,383),
    /* vot */
    LEAF(431,384), LEAF(431, 74),
    /* wa */
    LEAF(433,385),
    /* wen */
    LEAF(434, 99), LEAF(434,386),
    /* wo */
    LEAF(436,387), LEAF(436,269),
    /* yap */
    LEAF(438,388),
    /* yo */
    LEAF(439,389), LEAF(439,390), LEAF(439,391), LEAF(439,392),
    /* zh_cn */
    LEAF(443,393), LEAF(443,394), LEAF(443,395), LEAF(443,396),
    LEAF(443,397), LEAF(443,398), LEAF(443,399), LEAF(443,400),
    LEAF(443,401), LEAF(443,402), LEAF(443,403), LEAF(443,404),
    LEAF(443,405), LEAF(443,406), LEAF(443,407), LEAF(443,408),
    LEAF(443,409), LEAF(443,410), LEAF(443,411), LEAF(443,412),
    LEAF(443,413), LEAF(443,414), LEAF(443,415), LEAF(443,416),
    LEAF(443,417), LEAF(443,418), LEAF(443,419), LEAF(443,420),
    LEAF(443,421), LEAF(443,422), LEAF(443,423), LEAF(443,424),
    LEAF(443,425), LEAF(443,426), LEAF(443,427), LEAF(443,428),
    LEAF(443,429), LEAF(443,430), LEAF(443,431), LEAF(443,432),
    LEAF(443,433), LEAF(443,434), LEAF(443,435), LEAF(443,436),
    LEAF(443,437), LEAF(443,438), LEAF(443,439), LEAF(443,440),
    LEAF(443,441), LEAF(443,442), LEAF(443,443), LEAF(443,444),
    LEAF(443,445), LEAF(443,446), LEAF(443,447), LEAF(443,448),
    LEAF(443,449), LEAF(443,450), LEAF(443,451), LEAF(443,452),
    LEAF(443,453), LEAF(443,454), LEAF(443,455), LEAF(443,456),
    LEAF(443,457), LEAF(443,458), LEAF(443,459), LEAF(443,460),
    LEAF(443,461), LEAF(443,462), LEAF(443,463), LEAF(443,464),
    LEAF(443,465), LEAF(443,466), LEAF(443,467), LEAF(443,468),
    LEAF(443,469), LEAF(443,470), LEAF(443,471), LEAF(443,472),
    LEAF(443,473), LEAF(443,474),
    /* zh_hk */
    LEAF(525,475), LEAF(525,476), LEAF(525,477), LEAF(525,478),
    LEAF(525,479), LEAF(525,480), LEAF(525,481), LEAF(525,482),
    LEAF(525,483), LEAF(525,484), LEAF(525,485), LEAF(525,486),
    LEAF(525,487), LEAF(525,488), LEAF(525,489), LEAF(525,490),
    LEAF(525,491), LEAF(525,492), LEAF(525,493), LEAF(525,494),
    LEAF(525,495), LEAF(525,496), LEAF(525,497), LEAF(525,498),
    LEAF(525,499), LEAF(525,500), LEAF(525,501), LEAF(525,502),
    LEAF(525,503), LEAF(525,504), LEAF(525,505), LEAF(525,506),
    LEAF(525,507), LEAF(525,508), LEAF(525,509), LEAF(525,510),
    LEAF(525,511), LEAF(525,512), LEAF(525,513), LEAF(525,514),
    LEAF(525,515), LEAF(525,516), LEAF(525,517), LEAF(525,518),
    LEAF(525,519), LEAF(525,520), LEAF(525,521), LEAF(525,522),
    LEAF(525,523), LEAF(525,524), LEAF(525,525), LEAF(525,526),
    LEAF(525,527), LEAF(525,528), LEAF(525,529), LEAF(525,530),
    LEAF(525,531), LEAF(525,532), LEAF(525,533), LEAF(525,534),
    LEAF(525,535), LEAF(525,536), LEAF(525,537), LEAF(525,538),
    LEAF(525,539), LEAF(525,540), LEAF(525,541), LEAF(525,542),
    LEAF(525,543), LEAF(525,544), LEAF(525,545), LEAF(525,546),
    LEAF(525,547), LEAF(525,548), LEAF(525,549), LEAF(525,550),
    LEAF(525,551), LEAF(525,552), LEAF(525,553), LEAF(525,554),
    LEAF(525,555), LEAF(525,556), LEAF(525,557), LEAF(525,558),
    LEAF(525,559), LEAF(525,560), LEAF(525,561), LEAF(525,562),
    LEAF(525,563), LEAF(525,564), LEAF(525,565), LEAF(525,566),
    LEAF(525,567), LEAF(525,568), LEAF(525,569), LEAF(525,570),
    LEAF(525,571), LEAF(525,572), LEAF(525,573), LEAF(525,574),
    LEAF(525,575), LEAF(525,576), LEAF(525,577), LEAF(525,578),
    LEAF(525,579), LEAF(525,580), LEAF(525,581), LEAF(525,582),
    LEAF(525,583), LEAF(525,584), LEAF(525,585), LEAF(525,586),
    LEAF(525,587), LEAF(525,588), LEAF(525,589), LEAF(525,590),
    LEAF(525,591), LEAF(525,592), LEAF(525,593), LEAF(525,594),
    LEAF(525,595), LEAF(525,596), LEAF(525,597), LEAF(525,598),
    LEAF(525,599), LEAF(525,600), LEAF(525,601), LEAF(525,602),
    LEAF(525,603), LEAF(525,604), LEAF(525,355), LEAF(525,605),
    LEAF(525,606), LEAF(525,318), LEAF(525,607), LEAF(525,608),
    LEAF(525,609), LEAF(525,610), LEAF(525,611), LEAF(525,612),
    LEAF(525,613), LEAF(525,  3), LEAF(525,614), LEAF(525,615),
    LEAF(525,616), LEAF(525,617), LEAF(525,618), LEAF(525,619),
    LEAF(525,604), LEAF(525,620), LEAF(525,621), LEAF(525,622),
    LEAF(525,623), LEAF(525,624), LEAF(525,625), LEAF(525,626),
    LEAF(525,627), LEAF(525,628), LEAF(525,629), LEAF(525,630),
    LEAF(525,631), LEAF(525,632), LEAF(525,633), LEAF(525,634),
    LEAF(525,635), LEAF(525,636), LEAF(525,637), LEAF(525,638),
    LEAF(525,639), LEAF(525,640), LEAF(525,641),
    /* zh_tw */
    LEAF(696,642), LEAF(696,643), LEAF(696,644), LEAF(696,645),
    LEAF(696,646), LEAF(696,647), LEAF(696,648), LEAF(696,649),
    LEAF(696,650), LEAF(696,651), LEAF(696,652), LEAF(696,653),
    LEAF(696,654), LEAF(696,655), LEAF(696,656), LEAF(696,657),
    LEAF(696,658), LEAF(696,659), LEAF(696,660), LEAF(696,661),
    LEAF(696,662), LEAF(696,663), LEAF(696,664), LEAF(696,665),
    LEAF(696,666), LEAF(696,667), LEAF(696,668), LEAF(696,669),
    LEAF(696,670), LEAF(696,671), LEAF(696,672), LEAF(696,673),
    LEAF(696,674), LEAF(696,675), LEAF(696,676), LEAF(696,677),
    LEAF(696,678), LEAF(696,679), LEAF(696,680), LEAF(696,681),
    LEAF(696,682), LEAF(696,683), LEAF(696,684), LEAF(696,685),
    LEAF(696,686), LEAF(696,687), LEAF(696,688), LEAF(696,689),
    LEAF(696,690), LEAF(696,691), LEAF(696,692), LEAF(696,693),
    LEAF(696,694), LEAF(696,695), LEAF(696,696), LEAF(696,697),
    LEAF(696,698), LEAF(696,699), LEAF(696,700), LEAF(696,701),
    LEAF(696,702), LEAF(696,703), LEAF(696,704), LEAF(696,705),
    LEAF(696,706), LEAF(696,707), LEAF(696,708), LEAF(696,709),
    LEAF(696,710), LEAF(696,711), LEAF(696,712), LEAF(696,713),
    LEAF(696,714), LEAF(696,715), LEAF(696,716), LEAF(696,717),
    LEAF(696,718), LEAF(696,719), LEAF(696,720), LEAF(696,721),
    LEAF(696,722), LEAF(696,723), LEAF(696,724),
},
{
    /* aa */
    0x0000,
    /* ab */
    0x0004,
    /* af */
    0x0000, 0x0001,
    /* ak */
    0x0000, 0x0001, 0x0002, 0x0003, 0x001e,
    /* am */
    0x0012, 0x0013,
    /* an */
    0x0000,
    /* ar */
    0x0006,
    /* as */
    0x0009,
    /* ast */
    0x0000, 0x001e,
    /* av */
    0x0004,
    /* ay */
    0x0000,
    /* az_az */
    0x0000, 0x0001, 0x0002,
    /* az_ir */
    0x0006,
    /* ba */
    0x0004,
    /* be */
    0x0004,
    /* ber_dz */
    0x0000, 0x0001, 0x0002, 0x001e,
    /* ber_ma */
    0x002d,
    /* bg */
    0x0004,
    /* bh */
    0x0009,
    /* bi */
    0x0000,
    /* bin */
    0x0000, 0x0003, 0x001e,
    /* bm */
    0x0000, 0x0001, 0x0002,
    /* bn */
    0x0009,
    /* bo */
    0x000f,
    /* br */
    0x0000,
    /* brx */
    0x0009,
    /* bs */
    0x0000, 0x0001,
    /* bua */
    0x0004,
    /* byn */
    0x0012, 0x0013,
    /* ca */
    0x0000, 0x0001,
    /* ch */
    0x0000,
    /* chm */
    0x0004,
    /* chr */
    0x0013,
    /* co */
    0x0000, 0x0001,
    /* crh */
    0x0000, 0x0001,
    /* cs */
    0x0000, 0x0001,
    /* csb */
    0x0000, 0x0001,
    /* cu */
    0x0004,
    /* cv */
    0x0001, 0x0004,
    /* cy */
    0x0000, 0x0001, 0x001e,
    /* da */
    0x0000,
    /* de */
    0x0000,
    /* doi */
    0x0009,
    /* dv */
    0x0007,
    /* ee */
    0x0000, 0x0001, 0x0002, 0x0003,
    /* el */
    0x0003,
    /* en */
    0x0000,
    /* eo */
    0x0000, 0x0001,
    /* et */
    0x0000, 0x0001,
    /* eu */
    0x0000,
    /* ff */
    0x0000, 0x0001, 0x0002,
    /* fi */
    0x0000, 0x0001,
    /* fil */
    0x0000,
    /* fj */
    0x0000,
    /* fo */
    0x0000,
    /* fur */
    0x0000,
    /* fy */
    0x0000,
    /* ga */
    0x0000, 0x0001, 0x001e,
    /* gd */
    0x0000,
    /* gez */
    0x0012, 0x0013,
    /* gn */
    0x0000, 0x0001, 0x001e,
    /* gu */
    0x000a,
    /* gv */
    0x0000,
    /* ha */
    0x0000, 0x0001, 0x0002,
    /* haw */
    0x0000, 0x0001, 0x0002,
    /* he */
    0x0005,
    /* hsb */
    0x0000, 0x0001,
    /* ht */
    0x0000,
    /* hu */
    0x0000, 0x0001,
    /* hy */
    0x0005,
    /* hz */
    0x0000, 0x0003, 0x001e,
    /* id */
    0x0000,
    /* ig */
    0x0000, 0x001e,
    /* ii */
    0x00a0, 0x00a1, 0x00a2, 0x00a3, 0x00a4,
    /* ik */
    0x0004,
    /* is */
    0x0000,
    /* it */
    0x0000,
    /* iu */
    0x0014, 0x0015, 0x0016,
    /* ja */
    0x0030, 0x004e, 0x004f, 0x0050, 0x0051, 0x0052, 0x0053, 0x0054,
    0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005a, 0x005b, 0x005c,
    0x005d, 0x005e, 0x005f, 0x0060, 0x0061, 0x0062, 0x0063, 0x0064,
    0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006a, 0x006b, 0x006c,
    0x006d, 0x006e, 0x006f, 0x0070, 0x0071, 0x0072, 0x0073, 0x0074,
    0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007a, 0x007b, 0x007c,
    0x007d, 0x007e, 0x007f, 0x0080, 0x0081, 0x0082, 0x0083, 0x0084,
    0x0085, 0x0086, 0x0087, 0x0088, 0x0089, 0x008a, 0x008b, 0x008c,
    0x008d, 0x008e, 0x008f, 0x0090, 0x0091, 0x0092, 0x0093, 0x0094,
    0x0095, 0x0096, 0x0097, 0x0098, 0x0099, 0x009a, 0x009b, 0x009c,
    0x009d, 0x009e, 0x009f,
    /* jv */
    0x0000,
    /* ka */
    0x0010,
    /* kaa */
    0x0004,
    /* ki */
    0x0000, 0x0001,
    /* kk */
    0x0004,
    /* kl */
    0x0000, 0x0001,
    /* km */
    0x0017,
    /* kn */
    0x000c,
    /* ko */
    0x0031, 0x00ac, 0x00ad, 0x00ae, 0x00af, 0x00b0, 0x00b1, 0x00b2,
    0x00b3, 0x00b4, 0x00b5, 0x00b6, 0x00b7, 0x00b8, 0x00b9, 0x00ba,
    0x00bb, 0x00bc, 0x00bd, 0x00be, 0x00bf, 0x00c0, 0x00c1, 0x00c2,
    0x00c3, 0x00c4, 0x00c5, 0x00c6, 0x00c7, 0x00c8, 0x00c9, 0x00ca,
    0x00cb, 0x00cc, 0x00cd, 0x00ce, 0x00cf, 0x00d0, 0x00d1, 0x00d2,
    0x00d3, 0x00d4, 0x00d5, 0x00d6, 0x00d7,
    /* kr */
    0x0000, 0x0001, 0x0002,
    /* ks */
    0x0006,
    /* ku_am */
    0x0004, 0x0005,
    /* ku_iq */
    0x0006,
    /* ku_tr */
    0x0000, 0x0001,
    /* kum */
    0x0004,
    /* kv */
    0x0004,
    /* kw */
    0x0000, 0x0001, 0x0002,
    /* ky */
    0x0004,
    /* la */
    0x0000, 0x0001,
    /* lah */
    0x0006,
    /* lb */
    0x0000,
    /* lg */
    0x0000, 0x0001,
    /* li */
    0x0000,
    /* ln */
    0x0000, 0x0001, 0x0002, 0x0003,
    /* lo */
    0x000e,
    /* lt */
    0x0000, 0x0001,
    /* lv */
    0x0000, 0x0001,
    /* mg */
    0x0000,
    /* mh */
    0x0000, 0x0001,
    /* mi */
    0x0000, 0x0001, 0x001e,
    /* mk */
    0x0004,
    /* ml */
    0x000d,
    /* mn_cn */
    0x0018,
    /* mn_mn */
    0x0004,
    /* mni */
    0x0009,
    /* mo */
    0x0000, 0x0001, 0x0002, 0x0004,
    /* mt */
    0x0000, 0x0001,
    /* my */
    0x0010,
    /* na */
    0x0000, 0x0001,
    /* nb */
    0x0000,
    /* ne */
    0x0009,
    /* nl */
    0x0000,
    /* nn */
    0x0000,
    /* nqo */
    0x0007,
    /* nso */
    0x0000, 0x0001,
    /* nv */
    0x0000, 0x0001, 0x0002, 0x0003,
    /* ny */
    0x0000, 0x0001,
    /* oc */
    0x0000,
    /* or */
    0x000b,
    /* ota */
    0x0006,
    /* pa */
    0x000a,
    /* pap_an */
    0x0000,
    /* pap_aw */
    0x0000,
    /* pl */
    0x0000, 0x0001,
    /* ps_af */
    0x0006,
    /* ps_pk */
    0x0006,
    /* pt */
    0x0000,
    /* qu */
    0x0000, 0x0002,
    /* rm */
    0x0000,
    /* ro */
    0x0000, 0x0001, 0x0002,
    /* sah */
    0x0004,
    /* sat */
    0x0009,
    /* sc */
    0x0000,
    /* sco */
    0x0000, 0x0001, 0x0002,
    /* sd */
    0x0006,
    /* se */
    0x0000, 0x0001,
    /* sg */
    0x0000,
    /* sh */
    0x0000, 0x0001, 0x0004,
    /* shs */
    0x0000, 0x0003,
    /* si */
    0x000d,
    /* sid */
    0x0012, 0x0013,
    /* sk */
    0x0000, 0x0001,
    /* sm */
    0x0000, 0x0002,
    /* sma */
    0x0000,
    /* smj */
    0x0000,
    /* smn */
    0x0000, 0x0001,
    /* sms */
    0x0000, 0x0001, 0x0002,
    /* sq */
    0x0000,
    /* sr */
    0x0004,
    /* sv */
    0x0000,
    /* syr */
    0x0007,
    /* ta */
    0x000b,
    /* te */
    0x000c,
    /* tg */
    0x0004,
    /* th */
    0x000e,
    /* tig */
    0x0012, 0x0013,
    /* tk */
    0x0000, 0x0001,
    /* tr */
    0x0000, 0x0001,
    /* tt */
    0x0004,
    /* ty */
    0x0000, 0x0001, 0x0002,
    /* ug */
    0x0006,
    /* uk */
    0x0004,
    /* und_zmth */
    0x0000, 0x0001, 0x0003, 0x0020, 0x0021, 0x0022, 0x0023, 0x0025,
    0x0027, 0x01d4, 0x01d5, 0x01d6,
    /* und_zsye */
    0x0023, 0x0025, 0x0026, 0x0027, 0x002b, 0x01f0, 0x01f1, 0x01f2,
    0x01f3, 0x01f4, 0x01f5, 0x01f6,
    /* ve */
    0x0000, 0x001e,
    /* vi */
    0x0000, 0x0001, 0x0003, 0x001e,
    /* vo */
    0x0000,
    /* vot */
    0x0000, 0x0001,
    /* wa */
    0x0000,
    /* wen */
    0x0000, 0x0001,
    /* wo */
    0x0000, 0x0001,
    /* yap */
    0x0000,
    /* yo */
    0x0000, 0x0001, 0x0003, 0x001e,
    /* zh_cn */
    0x0002, 0x004e, 0x004f, 0x0050, 0x0051, 0x0052, 0x0053, 0x0054,
    0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005a, 0x005b, 0x005c,
    0x005d, 0x005e, 0x005f, 0x0060, 0x0061, 0x0062, 0x0063, 0x0064,
    0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006a, 0x006b, 0x006c,
    0x006d, 0x006e, 0x006f, 0x0070, 0x0071, 0x0072, 0x0073, 0x0074,
    0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007a, 0x007b, 0x007c,
    0x007d, 0x007e, 0x007f, 0x0080, 0x0081, 0x0082, 0x0083, 0x0084,
    0x0085, 0x0086, 0x0087, 0x0088, 0x0089, 0x008a, 0x008b, 0x008c,
    0x008d, 0x008e, 0x008f, 0x0090, 0x0091, 0x0092, 0x0093, 0x0094,
    0x0095, 0x0096, 0x0097, 0x0098, 0x0099, 0x009a, 0x009b, 0x009c,
    0x009e, 0x009f,
    /* zh_hk */
    0x0030, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003a,
    0x003b, 0x003c, 0x003d, 0x003e, 0x003f, 0x0040, 0x0041, 0x0042,
    0x0043, 0x0044, 0x0045, 0x0046, 0x0047, 0x0048, 0x0049, 0x004a,
    0x004b, 0x004c, 0x004d, 0x004e, 0x004f, 0x0050, 0x0051, 0x0052,
    0x0053, 0x0054, 0x0055, 0x0056, 0x0057, 0x0058, 0x0059, 0x005a,
    0x005b, 0x005c, 0x005d, 0x005e, 0x005f, 0x0060, 0x0061, 0x0062,
    0x0063, 0x0064, 0x0065, 0x0066, 0x0067, 0x0068, 0x0069, 0x006a,
    0x006b, 0x006c, 0x006d, 0x006e, 0x006f, 0x0070, 0x0071, 0x0072,
    0x0073, 0x0074, 0x0075, 0x0076, 0x0077, 0x0078, 0x0079, 0x007a,
    0x007b, 0x007c, 0x007d, 0x007e, 0x007f, 0x0080, 0x0081, 0x0082,
    0x0083, 0x0084, 0x0085, 0x0086, 0x0087, 0x0088, 0x0089, 0x008a,
    0x008b, 0x008c, 0x008d, 0x008e, 0x008f, 0x0090, 0x0091, 0x0092,
    0x0093, 0x0094, 0x0095, 0x0096, 0x0097, 0x0098, 0x0099, 0x009a,
    0x009b, 0x009c, 0x009d, 0x009e, 0x009f, 0x0200, 0x0201, 0x0203,
    0x0207, 0x020c, 0x020d, 0x020e, 0x020f, 0x0210, 0x0211, 0x0219,
    0x021a, 0x021c, 0x021d, 0x0220, 0x0221, 0x022a, 0x022b, 0x022c,
    0x022d, 0x022f, 0x0232, 0x0235, 0x0236, 0x023c, 0x023e, 0x023f,
    0x0244, 0x024d, 0x024e, 0x0251, 0x0255, 0x025e, 0x0262, 0x0266,
    0x0267, 0x0268, 0x0269, 0x0272, 0x0275, 0x0276, 0x0277, 0x0278,
    0x0279, 0x027a, 0x027d, 0x0280, 0x0281, 0x0282, 0x0283, 0x0289,
    0x028a, 0x028b, 0x028c, 0x028d, 0x028e, 0x0294, 0x0297, 0x0298,
    0x029a, 0x029d, 0x02a6,
    /* zh_tw */
    0x004e, 0x004f, 0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055,
    0x0056, 0x0057, 0x0058, 0x0059, 0x005a, 0x005b, 0x005c, 0x005d,
    0x005e, 0x005f, 0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065,
    0x0066, 0x0067, 0x0068, 0x0069, 0x006a, 0x006b, 0x006c, 0x006d,
    0x006e, 0x006f, 0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075,
    0x0076, 0x0077, 0x0078, 0x0079, 0x007a, 0x007b, 0x007c, 0x007d,
    0x007e, 0x007f, 0x0080, 0x0081, 0x0082, 0x0083, 0x0084, 0x0085,
    0x0086, 0x0087, 0x0088, 0x0089, 0x008a, 0x008b, 0x008c, 0x008d,
    0x008e, 0x008f, 0x0090, 0x0091, 0x0092, 0x0093, 0x0094, 0x0095,
    0x0096, 0x0097, 0x0098, 0x0099, 0x009a, 0x009b, 0x009c, 0x009d,
    0x009e, 0x009f, 0x00fa,
},
{
    0, /* aa */
    1, /* ab */
    2, /* af */
    190, /* ak */
    3, /* am */
    191, /* an */
    4, /* ar */
    5, /* as */
    6, /* ast */
    7, /* av */
    8, /* ay */
    9, /* az_az */
    10, /* az_ir */
    11, /* ba */
    13, /* be */
    192, /* ber_dz */
    193, /* ber_ma */
    14, /* bg */
    15, /* bh */
    16, /* bho */
    17, /* bi */
    18, /* bin */
    12, /* bm */
    19, /* bn */
    20, /* bo */
    21, /* br */
    240, /* brx */
    22, /* bs */
    23, /* bua */
    194, /* byn */
    24, /* ca */
    25, /* ce */
    26, /* ch */
    27, /* chm */
    28, /* chr */
    29, /* co */
    195, /* crh */
    30, /* cs */
    196, /* csb */
    31, /* cu */
    32, /* cv */
    33, /* cy */
    34, /* da */
    35, /* de */
    242, /* doi */
    197, /* dv */
    36, /* dz */
    198, /* ee */
    37, /* el */
    38, /* en */
    39, /* eo */
    40, /* es */
    41, /* et */
    42, /* eu */
    43, /* fa */
    199, /* fat */
    48, /* ff */
    44, /* fi */
    200, /* fil */
    45, /* fj */
    46, /* fo */
    47, /* fr */
    49, /* fur */
    50, /* fy */
    51, /* ga */
    52, /* gd */
    53, /* gez */
    54, /* gl */
    55, /* gn */
    56, /* gu */
    57, /* gv */
    58, /* ha */
    59, /* haw */
    60, /* he */
    61, /* hi */
    201, /* hne */
    62, /* ho */
    63, /* hr */
    202, /* hsb */
    203, /* ht */
    64, /* hu */
    65, /* hy */
    204, /* hz */
    66, /* ia */
    68, /* id */
    69, /* ie */
    67, /* ig */
    205, /* ii */
    70, /* ik */
    71, /* io */
    72, /* is */
    73, /* it */
    74, /* iu */
    75, /* ja */
    206, /* jv */
    76, /* ka */
    77, /* kaa */
    207, /* kab */
    78, /* ki */
    208, /* kj */
    79, /* kk */
    80, /* kl */
    81, /* km */
    82, /* kn */
    83, /* ko */
    84, /* kok */
    209, /* kr */
    85, /* ks */
    86, /* ku_am */
    210, /* ku_iq */
    87, /* ku_ir */
    211, /* ku_tr */
    88, /* kum */
    89, /* kv */
    90, /* kw */
    212, /* kwm */
    91, /* ky */
    92, /* la */
    238, /* lah */
    93, /* lb */
    94, /* lez */
    213, /* lg */
    214, /* li */
    95, /* ln */
    96, /* lo */
    97, /* lt */
    98, /* lv */
    215, /* mai */
    99, /* mg */
    100, /* mh */
    101, /* mi */
    102, /* mk */
    103, /* ml */
    104, /* mn_cn */
    216, /* mn_mn */
    243, /* mni */
    105, /* mo */
    106, /* mr */
    217, /* ms */
    107, /* mt */
    108, /* my */
    218, /* na */
    109, /* nb */
    110, /* nds */
    111, /* ne */
    219, /* ng */
    112, /* nl */
    113, /* nn */
    114, /* no */
    239, /* nqo */
    115, /* nr */
    116, /* nso */
    220, /* nv */
    117, /* ny */
    118, /* oc */
    119, /* om */
    120, /* or */
    121, /* os */
    221, /* ota */
    122, /* pa */
    222, /* pa_pk */
    223, /* pap_an */
    224, /* pap_aw */
    123, /* pl */
    124, /* ps_af */
    125, /* ps_pk */
    126, /* pt */
    225, /* qu */
    226, /* quz */
    127, /* rm */
    227, /* rn */
    128, /* ro */
    129, /* ru */
    228, /* rw */
    130, /* sa */
    131, /* sah */
    241, /* sat */
    229, /* sc */
    132, /* sco */
    230, /* sd */
    133, /* se */
    134, /* sel */
    231, /* sg */
    135, /* sh */
    136, /* shs */
    137, /* si */
    232, /* sid */
    138, /* sk */
    139, /* sl */
    140, /* sm */
    141, /* sma */
    142, /* smj */
    143, /* smn */
    144, /* sms */
    233, /* sn */
    145, /* so */
    146, /* sq */
    147, /* sr */
    148, /* ss */
    149, /* st */
    234, /* su */
    150, /* sv */
    151, /* sw */
    152, /* syr */
    153, /* ta */
    154, /* te */
    155, /* tg */
    156, /* th */
    157, /* ti_er */
    158, /* ti_et */
    159, /* tig */
    160, /* tk */
    161, /* tl */
    162, /* tn */
    163, /* to */
    164, /* tr */
    165, /* ts */
    166, /* tt */
    167, /* tw */
    235, /* ty */
    168, /* tyv */
    169, /* ug */
    170, /* uk */
    245, /* und_zmth */
    244, /* und_zsye */
    171, /* ur */
    172, /* uz */
    173, /* ve */
    174, /* vi */
    175, /* vo */
    176, /* vot */
    177, /* wa */
    236, /* wal */
    178, /* wen */
    179, /* wo */
    180, /* xh */
    181, /* yap */
    182, /* yi */
    183, /* yo */
    237, /* za */
    184, /* zh_cn */
    185, /* zh_hk */
    186, /* zh_mo */
    187, /* zh_sg */
    188, /* zh_tw */
    189, /* zu */
},
{
    0, /* aa */
    1, /* ab */
    2, /* af */
    4, /* am */
    6, /* ar */
    7, /* as */
    8, /* ast */
    9, /* av */
    10, /* ay */
    11, /* az_az */
    12, /* az_ir */
    13, /* ba */
    22, /* bm */
    14, /* be */
    17, /* bg */
    18, /* bh */
    19, /* bho */
    20, /* bi */
    21, /* bin */
    23, /* bn */
    24, /* bo */
    25, /* br */
    27, /* bs */
    28, /* bua */
    30, /* ca */
    31, /* ce */
    32, /* ch */
    33, /* chm */
    34, /* chr */
    35, /* co */
    37, /* cs */
    39, /* cu */
    40, /* cv */
    41, /* cy */
    42, /* da */
    43, /* de */
    46, /* dz */
    48, /* el */
    49, /* en */
    50, /* eo */
    51, /* es */
    52, /* et */
    53, /* eu */
    54, /* fa */
    57, /* fi */
    59, /* fj */
    60, /* fo */
    61, /* fr */
    56, /* ff */
    62, /* fur */
    63, /* fy */
    64, /* ga */
    65, /* gd */
    66, /* gez */
    67, /* gl */
    68, /* gn */
    69, /* gu */
    70, /* gv */
    71, /* ha */
    72, /* haw */
    73, /* he */
    74, /* hi */
    76, /* ho */
    77, /* hr */
    80, /* hu */
    81, /* hy */
    83, /* ia */
    86, /* ig */
    84, /* id */
    85, /* ie */
    88, /* ik */
    89, /* io */
    90, /* is */
    91, /* it */
    92, /* iu */
    93, /* ja */
    95, /* ka */
    96, /* kaa */
    98, /* ki */
    100, /* kk */
    101, /* kl */
    102, /* km */
    103, /* kn */
    104, /* ko */
    105, /* kok */
    107, /* ks */
    108, /* ku_am */
    110, /* ku_ir */
    112, /* kum */
    113, /* kv */
    114, /* kw */
    116, /* ky */
    117, /* la */
    119, /* lb */
    120, /* lez */
    123, /* ln */
    124, /* lo */
    125, /* lt */
    126, /* lv */
    128, /* mg */
    129, /* mh */
    130, /* mi */
    131, /* mk */
    132, /* ml */
    133, /* mn_cn */
    136, /* mo */
    137, /* mr */
    139, /* mt */
    140, /* my */
    142, /* nb */
    143, /* nds */
    144, /* ne */
    146, /* nl */
    147, /* nn */
    148, /* no */
    150, /* nr */
    151, /* nso */
    153, /* ny */
    154, /* oc */
    155, /* om */
    156, /* or */
    157, /* os */
    159, /* pa */
    163, /* pl */
    164, /* ps_af */
    165, /* ps_pk */
    166, /* pt */
    169, /* rm */
    171, /* ro */
    172, /* ru */
    174, /* sa */
    175, /* sah */
    178, /* sco */
    180, /* se */
    181, /* sel */
    183, /* sh */
    184, /* shs */
    185, /* si */
    187, /* sk */
    188, /* sl */
    189, /* sm */
    190, /* sma */
    191, /* smj */
    192, /* smn */
    193, /* sms */
    195, /* so */
    196, /* sq */
    197, /* sr */
    198, /* ss */
    199, /* st */
    201, /* sv */
    202, /* sw */
    203, /* syr */
    204, /* ta */
    205, /* te */
    206, /* tg */
    207, /* th */
    208, /* ti_er */
    209, /* ti_et */
    210, /* tig */
    211, /* tk */
    212, /* tl */
    213, /* tn */
    214, /* to */
    215, /* tr */
    216, /* ts */
    217, /* tt */
    218, /* tw */
    220, /* tyv */
    221, /* ug */
    222, /* uk */
    225, /* ur */
    226, /* uz */
    227, /* ve */
    228, /* vi */
    229, /* vo */
    230, /* vot */
    231, /* wa */
    233, /* wen */
    234, /* wo */
    235, /* xh */
    236, /* yap */
    237, /* yi */
    238, /* yo */
    240, /* zh_cn */
    241, /* zh_hk */
    242, /* zh_mo */
    243, /* zh_sg */
    244, /* zh_tw */
    245, /* zu */
    3, /* ak */
    5, /* an */
    15, /* ber_dz */
    16, /* ber_ma */
    29, /* byn */
    36, /* crh */
    38, /* csb */
    45, /* dv */
    47, /* ee */
    55, /* fat */
    58, /* fil */
    75, /* hne */
    78, /* hsb */
    79, /* ht */
    82, /* hz */
    87, /* ii */
    94, /* jv */
    97, /* kab */
    99, /* kj */
    106, /* kr */
    109, /* ku_iq */
    111, /* ku_tr */
    115, /* kwm */
    121, /* lg */
    122, /* li */
    127, /* mai */
    134, /* mn_mn */
    138, /* ms */
    141, /* na */
    145, /* ng */
    152, /* nv */
    158, /* ota */
    160, /* pa_pk */
    161, /* pap_an */
    162, /* pap_aw */
    167, /* qu */
    168, /* quz */
    170, /* rn */
    173, /* rw */
    177, /* sc */
    179, /* sd */
    182, /* sg */
    186, /* sid */
    194, /* sn */
    200, /* su */
    219, /* ty */
    232, /* wal */
    239, /* za */
    118, /* lah */
    149, /* nqo */
    26, /* brx */
    176, /* sat */
    44, /* doi */
    135, /* mni */
    224, /* und_zsye */
    223, /* und_zmth */
}
};

#define NUM_LANG_CHAR_SET	246
#define NUM_LANG_SET_MAP	8

static const FcChar32 fcLangCountrySets[][NUM_LANG_SET_MAP] = {
    { 0x00000600, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, }, /* az */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000003, 0x00000000, }, /* ber */
    { 0x00000000, 0x00000000, 0x00c00000, 0x00000000, 0x00000000, 0x00000000, 0x000c0000, 0x00000000, }, /* ku */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000100, 0x00000000, 0x00000000, 0x01000000, 0x00000000, }, /* mn */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x40000000, 0x00000000, }, /* pa */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x80000000, 0x00000001, }, /* pap */
    { 0x00000000, 0x00000000, 0x00000000, 0x30000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, }, /* ps */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x60000000, 0x00000000, 0x00000000, 0x00000000, }, /* ti */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00300000, }, /* und */
    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x1f000000, 0x00000000, 0x00000000, }, /* zh */
};

#define NUM_COUNTRY_SET 10

static const FcLangCharSetRange  fcLangCharSetRanges[] = {

    { 0, 12 }, /* a */
    { 13, 29 }, /* b */
    { 30, 41 }, /* c */
    { 42, 46 }, /* d */
    { 47, 53 }, /* e */
    { 54, 63 }, /* f */
    { 64, 70 }, /* g */
    { 71, 82 }, /* h */
    { 83, 92 }, /* i */
    { 93, 94 }, /* j */
    { 95, 116 }, /* k */
    { 117, 126 }, /* l */
    { 127, 140 }, /* m */
    { 141, 153 }, /* n */
    { 154, 158 }, /* o */
    { 159, 166 }, /* p */
    { 167, 168 }, /* q */
    { 169, 173 }, /* r */
    { 174, 203 }, /* s */
    { 204, 220 }, /* t */
    { 221, 226 }, /* u */
    { 227, 230 }, /* v */
    { 231, 234 }, /* w */
    { 235, 235 }, /* x */
    { 236, 238 }, /* y */
    { 239, 245 }, /* z */
};
