// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/x11/keysym_to_unicode.h"

// Define XK_xxx before the #include of <X11/keysym.h> so that <X11/keysym.h>
// defines all KeySyms we need.
#define XK_MISCELLANY
#define XK_LATIN1
#define XK_LATIN2
#define XK_LATIN3
#define XK_LATIN4
#define XK_LATIN8
#define XK_LATIN9
#define XK_KATAKANA
#define XK_ARABIC
#define XK_CYRILLIC
#define XK_GREEK
#define XK_TECHNICAL
#define XK_SPECIAL
#define XK_PUBLISHING
#define XK_APL
#define XK_HEBREW
#define XK_THAI
#define XK_KOREAN
#define XK_ARMENIAN
#define XK_GEORGIAN
#define XK_CAUCASUS
#define XK_VIETNAMESE
#define XK_CURRENCY
#define XK_MATHEMATICAL
#define XK_BRAILLE
#define XK_SINHALA
#include <X11/keysym.h>
#include <X11/X.h>

#include <unordered_map>

#include "base/lazy_instance.h"
#include "base/macros.h"

namespace ui {

const struct {
  KeySym keysym;
  uint16_t unicode;
} g_keysym_to_unicode_table[] = {
    // Control characters
    {XK_BackSpace, 0x0008},
    {XK_Tab, 0x0009},
    {XK_Linefeed, 0x000a},
    {XK_Clear, 0x000b},
    {XK_Return, 0x000d},
    {XK_Escape, 0x001b},
    {XK_Delete, 0x007f},

    // Numeric keypad
    {XK_KP_Space, 0x0020},
    {XK_KP_Tab, 0x0009},
    {XK_KP_Enter, 0x000d},
    {XK_KP_Equal, 0x003d},
    {XK_KP_Multiply, 0x002a},
    {XK_KP_Add, 0x002b},
    {XK_KP_Separator, 0x002c},
    {XK_KP_Subtract, 0x002d},
    {XK_KP_Decimal, 0x002e},
    {XK_KP_Divide, 0x002f},
    {XK_KP_0, 0x0030},
    {XK_KP_1, 0x0031},
    {XK_KP_2, 0x0032},
    {XK_KP_3, 0x0033},
    {XK_KP_4, 0x0034},
    {XK_KP_5, 0x0035},
    {XK_KP_6, 0x0036},
    {XK_KP_7, 0x0037},
    {XK_KP_8, 0x0038},
    {XK_KP_9, 0x0039},

    // Latin 1 KeySyms map 1:1 to Unicode

    // Latin 2
    {XK_Aogonek, 0x0104},       // LATIN CAPITAL LETTER A WITH OGONEK
    {XK_breve, 0x02D8},         // BREVE
    {XK_Lstroke, 0x0141},       // LATIN CAPITAL LETTER L WITH STROKE
    {XK_Lcaron, 0x013D},        // LATIN CAPITAL LETTER L WITH CARON
    {XK_Sacute, 0x015A},        // LATIN CAPITAL LETTER S WITH ACUTE
    {XK_Scaron, 0x0160},        // LATIN CAPITAL LETTER S WITH CARON
    {XK_Scedilla, 0x015E},      // LATIN CAPITAL LETTER S WITH CEDILLA
    {XK_Tcaron, 0x0164},        // LATIN CAPITAL LETTER T WITH CARON
    {XK_Zacute, 0x0179},        // LATIN CAPITAL LETTER Z WITH ACUTE
    {XK_Zcaron, 0x017D},        // LATIN CAPITAL LETTER Z WITH CARON
    {XK_Zabovedot, 0x017B},     // LATIN CAPITAL LETTER Z WITH DOT ABOVE
    {XK_aogonek, 0x0105},       // LATIN SMALL LETTER A WITH OGONEK
    {XK_ogonek, 0x02DB},        // OGONEK
    {XK_lstroke, 0x0142},       // LATIN SMALL LETTER L WITH STROKE
    {XK_lcaron, 0x013E},        // LATIN SMALL LETTER L WITH CARON
    {XK_sacute, 0x015B},        // LATIN SMALL LETTER S WITH ACUTE
    {XK_caron, 0x02C7},         // CARON
    {XK_scaron, 0x0161},        // LATIN SMALL LETTER S WITH CARON
    {XK_scedilla, 0x015F},      // LATIN SMALL LETTER S WITH CEDILLA
    {XK_tcaron, 0x0165},        // LATIN SMALL LETTER T WITH CARON
    {XK_zacute, 0x017A},        // LATIN SMALL LETTER Z WITH ACUTE
    {XK_doubleacute, 0x02DD},   // DOUBLE ACUTE ACCENT
    {XK_zcaron, 0x017E},        // LATIN SMALL LETTER Z WITH CARON
    {XK_zabovedot, 0x017C},     // LATIN SMALL LETTER Z WITH DOT ABOVE
    {XK_Racute, 0x0154},        // LATIN CAPITAL LETTER R WITH ACUTE
    {XK_Abreve, 0x0102},        // LATIN CAPITAL LETTER A WITH BREVE
    {XK_Lacute, 0x0139},        // LATIN CAPITAL LETTER L WITH ACUTE
    {XK_Cacute, 0x0106},        // LATIN CAPITAL LETTER C WITH ACUTE
    {XK_Ccaron, 0x010C},        // LATIN CAPITAL LETTER C WITH CARON
    {XK_Eogonek, 0x0118},       // LATIN CAPITAL LETTER E WITH OGONEK
    {XK_Ecaron, 0x011A},        // LATIN CAPITAL LETTER E WITH CARON
    {XK_Dcaron, 0x010E},        // LATIN CAPITAL LETTER D WITH CARON
    {XK_Dstroke, 0x0110},       // LATIN CAPITAL LETTER D WITH STROKE
    {XK_Nacute, 0x0143},        // LATIN CAPITAL LETTER N WITH ACUTE
    {XK_Ncaron, 0x0147},        // LATIN CAPITAL LETTER N WITH CARON
    {XK_Odoubleacute, 0x0150},  // LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
    {XK_Rcaron, 0x0158},        // LATIN CAPITAL LETTER R WITH CARON
    {XK_Uring, 0x016E},         // LATIN CAPITAL LETTER U WITH RING ABOVE
    {XK_Udoubleacute, 0x0170},  // LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
    {XK_Tcedilla, 0x0162},      // LATIN CAPITAL LETTER T WITH CEDILLA
    {XK_racute, 0x0155},        // LATIN SMALL LETTER R WITH ACUTE
    {XK_abreve, 0x0103},        // LATIN SMALL LETTER A WITH BREVE
    {XK_lacute, 0x013A},        // LATIN SMALL LETTER L WITH ACUTE
    {XK_cacute, 0x0107},        // LATIN SMALL LETTER C WITH ACUTE
    {XK_ccaron, 0x010D},        // LATIN SMALL LETTER C WITH CARON
    {XK_eogonek, 0x0119},       // LATIN SMALL LETTER E WITH OGONEK
    {XK_ecaron, 0x011B},        // LATIN SMALL LETTER E WITH CARON
    {XK_dcaron, 0x010F},        // LATIN SMALL LETTER D WITH CARON
    {XK_dstroke, 0x0111},       // LATIN SMALL LETTER D WITH STROKE
    {XK_nacute, 0x0144},        // LATIN SMALL LETTER N WITH ACUTE
    {XK_ncaron, 0x0148},        // LATIN SMALL LETTER N WITH CARON
    {XK_odoubleacute, 0x0151},  // LATIN SMALL LETTER O WITH DOUBLE ACUTE
    {XK_rcaron, 0x0159},        // LATIN SMALL LETTER R WITH CARON
    {XK_uring, 0x016F},         // LATIN SMALL LETTER U WITH RING ABOVE
    {XK_udoubleacute, 0x0171},  // LATIN SMALL LETTER U WITH DOUBLE ACUTE
    {XK_tcedilla, 0x0163},      // LATIN SMALL LETTER T WITH CEDILLA
    {XK_abovedot, 0x02D9},      // DOT ABOVE

    // Latin 3
    {XK_Hstroke, 0x0126},      // LATIN CAPITAL LETTER H WITH STROKE
    {XK_Hcircumflex, 0x0124},  // LATIN CAPITAL LETTER H WITH CIRCUMFLEX
    {XK_Iabovedot, 0x0130},    // LATIN CAPITAL LETTER I WITH DOT ABOVE
    {XK_Gbreve, 0x011E},       // LATIN CAPITAL LETTER G WITH BREVE
    {XK_Jcircumflex, 0x0134},  // LATIN CAPITAL LETTER J WITH CIRCUMFLEX
    {XK_hstroke, 0x0127},      // LATIN SMALL LETTER H WITH STROKE
    {XK_hcircumflex, 0x0125},  // LATIN SMALL LETTER H WITH CIRCUMFLEX
    {XK_idotless, 0x0131},     // LATIN SMALL LETTER DOTLESS I
    {XK_gbreve, 0x011F},       // LATIN SMALL LETTER G WITH BREVE
    {XK_jcircumflex, 0x0135},  // LATIN SMALL LETTER J WITH CIRCUMFLEX
    {XK_Cabovedot, 0x010A},    // LATIN CAPITAL LETTER C WITH DOT ABOVE
    {XK_Ccircumflex, 0x0108},  // LATIN CAPITAL LETTER C WITH CIRCUMFLEX
    {XK_Gabovedot, 0x0120},    // LATIN CAPITAL LETTER G WITH DOT ABOVE
    {XK_Gcircumflex, 0x011C},  // LATIN CAPITAL LETTER G WITH CIRCUMFLEX
    {XK_Ubreve, 0x016C},       // LATIN CAPITAL LETTER U WITH BREVE
    {XK_Scircumflex, 0x015C},  // LATIN CAPITAL LETTER S WITH CIRCUMFLEX
    {XK_cabovedot, 0x010B},    // LATIN SMALL LETTER C WITH DOT ABOVE
    {XK_ccircumflex, 0x0109},  // LATIN SMALL LETTER C WITH CIRCUMFLEX
    {XK_gabovedot, 0x0121},    // LATIN SMALL LETTER G WITH DOT ABOVE
    {XK_gcircumflex, 0x011D},  // LATIN SMALL LETTER G WITH CIRCUMFLEX
    {XK_ubreve, 0x016D},       // LATIN SMALL LETTER U WITH BREVE
    {XK_scircumflex, 0x015D},  // LATIN SMALL LETTER S WITH CIRCUMFLEX

    // Latin 4
    {XK_kra, 0x0138},        // LATIN SMALL LETTER KRA
    {XK_Rcedilla, 0x0156},   // LATIN CAPITAL LETTER R WITH CEDILLA
    {XK_Itilde, 0x0128},     // LATIN CAPITAL LETTER I WITH TILDE
    {XK_Lcedilla, 0x013B},   // LATIN CAPITAL LETTER L WITH CEDILLA
    {XK_Emacron, 0x0112},    // LATIN CAPITAL LETTER E WITH MACRON
    {XK_Gcedilla, 0x0122},   // LATIN CAPITAL LETTER G WITH CEDILLA
    {XK_Tslash, 0x0166},     // LATIN CAPITAL LETTER T WITH STROKE
    {XK_rcedilla, 0x0157},   // LATIN SMALL LETTER R WITH CEDILLA
    {XK_itilde, 0x0129},     // LATIN SMALL LETTER I WITH TILDE
    {XK_lcedilla, 0x013C},   // LATIN SMALL LETTER L WITH CEDILLA
    {XK_emacron, 0x0113},    // LATIN SMALL LETTER E WITH MACRON
    {XK_gcedilla, 0x0123},   // LATIN SMALL LETTER G WITH CEDILLA
    {XK_tslash, 0x0167},     // LATIN SMALL LETTER T WITH STROKE
    {XK_ENG, 0x014A},        // LATIN CAPITAL LETTER ENG
    {XK_eng, 0x014B},        // LATIN SMALL LETTER ENG
    {XK_Amacron, 0x0100},    // LATIN CAPITAL LETTER A WITH MACRON
    {XK_Iogonek, 0x012E},    // LATIN CAPITAL LETTER I WITH OGONEK
    {XK_Eabovedot, 0x0116},  // LATIN CAPITAL LETTER E WITH DOT ABOVE
    {XK_Imacron, 0x012A},    // LATIN CAPITAL LETTER I WITH MACRON
    {XK_Ncedilla, 0x0145},   // LATIN CAPITAL LETTER N WITH CEDILLA
    {XK_Omacron, 0x014C},    // LATIN CAPITAL LETTER O WITH MACRON
    {XK_Kcedilla, 0x0136},   // LATIN CAPITAL LETTER K WITH CEDILLA
    {XK_Uogonek, 0x0172},    // LATIN CAPITAL LETTER U WITH OGONEK
    {XK_Utilde, 0x0168},     // LATIN CAPITAL LETTER U WITH TILDE
    {XK_Umacron, 0x016A},    // LATIN CAPITAL LETTER U WITH MACRON
    {XK_amacron, 0x0101},    // LATIN SMALL LETTER A WITH MACRON
    {XK_iogonek, 0x012F},    // LATIN SMALL LETTER I WITH OGONEK
    {XK_eabovedot, 0x0117},  // LATIN SMALL LETTER E WITH DOT ABOVE
    {XK_imacron, 0x012B},    // LATIN SMALL LETTER I WITH MACRON
    {XK_ncedilla, 0x0146},   // LATIN SMALL LETTER N WITH CEDILLA
    {XK_omacron, 0x014D},    // LATIN SMALL LETTER O WITH MACRON
    {XK_kcedilla, 0x0137},   // LATIN SMALL LETTER K WITH CEDILLA
    {XK_uogonek, 0x0173},    // LATIN SMALL LETTER U WITH OGONEK
    {XK_utilde, 0x0169},     // LATIN SMALL LETTER U WITH TILDE
    {XK_umacron, 0x016B},    // LATIN SMALL LETTER U WITH MACRON

    // Latin 8 KeySyms map 1:1 to Unicode

    // Latin 9
    {XK_OE, 0x0152},          // LATIN CAPITAL LIGATURE OE
    {XK_oe, 0x0153},          // LATIN SMALL LIGATURE OE
    {XK_Ydiaeresis, 0x0178},  // LATIN CAPITAL LETTER Y WITH DIAERESIS

    // Katakana
    {XK_overline, 0x203E},             // OVERLINE
    {XK_kana_fullstop, 0x3002},        // IDEOGRAPHIC FULL STOP
    {XK_kana_openingbracket, 0x300C},  // LEFT CORNER BRACKET
    {XK_kana_closingbracket, 0x300D},  // RIGHT CORNER BRACKET
    {XK_kana_comma, 0x3001},           // IDEOGRAPHIC COMMA
    {XK_kana_conjunctive, 0x30FB},     // KATAKANA MIDDLE DOT
    {XK_kana_WO, 0x30F2},              // KATAKANA LETTER WO
    {XK_kana_a, 0x30A1},               // KATAKANA LETTER SMALL A
    {XK_kana_i, 0x30A3},               // KATAKANA LETTER SMALL I
    {XK_kana_u, 0x30A5},               // KATAKANA LETTER SMALL U
    {XK_kana_e, 0x30A7},               // KATAKANA LETTER SMALL E
    {XK_kana_o, 0x30A9},               // KATAKANA LETTER SMALL O
    {XK_kana_ya, 0x30E3},              // KATAKANA LETTER SMALL YA
    {XK_kana_yu, 0x30E5},              // KATAKANA LETTER SMALL YU
    {XK_kana_yo, 0x30E7},              // KATAKANA LETTER SMALL YO
    {XK_kana_tsu, 0x30C3},             // KATAKANA LETTER SMALL TU
    {XK_prolongedsound, 0x30FC},       // KATAKANA-HIRAGANA PROLONGED SOUND MARK
    {XK_kana_A, 0x30A2},               // KATAKANA LETTER A
    {XK_kana_I, 0x30A4},               // KATAKANA LETTER I
    {XK_kana_U, 0x30A6},               // KATAKANA LETTER U
    {XK_kana_E, 0x30A8},               // KATAKANA LETTER E
    {XK_kana_O, 0x30AA},               // KATAKANA LETTER O
    {XK_kana_KA, 0x30AB},              // KATAKANA LETTER KA
    {XK_kana_KI, 0x30AD},              // KATAKANA LETTER KI
    {XK_kana_KU, 0x30AF},              // KATAKANA LETTER KU
    {XK_kana_KE, 0x30B1},              // KATAKANA LETTER KE
    {XK_kana_KO, 0x30B3},              // KATAKANA LETTER KO
    {XK_kana_SA, 0x30B5},              // KATAKANA LETTER SA
    {XK_kana_SHI, 0x30B7},             // KATAKANA LETTER SI
    {XK_kana_SU, 0x30B9},              // KATAKANA LETTER SU
    {XK_kana_SE, 0x30BB},              // KATAKANA LETTER SE
    {XK_kana_SO, 0x30BD},              // KATAKANA LETTER SO
    {XK_kana_TA, 0x30BF},              // KATAKANA LETTER TA
    {XK_kana_CHI, 0x30C1},             // KATAKANA LETTER TI
    {XK_kana_TSU, 0x30C4},             // KATAKANA LETTER TU
    {XK_kana_TE, 0x30C6},              // KATAKANA LETTER TE
    {XK_kana_TO, 0x30C8},              // KATAKANA LETTER TO
    {XK_kana_NA, 0x30CA},              // KATAKANA LETTER NA
    {XK_kana_NI, 0x30CB},              // KATAKANA LETTER NI
    {XK_kana_NU, 0x30CC},              // KATAKANA LETTER NU
    {XK_kana_NE, 0x30CD},              // KATAKANA LETTER NE
    {XK_kana_NO, 0x30CE},              // KATAKANA LETTER NO
    {XK_kana_HA, 0x30CF},              // KATAKANA LETTER HA
    {XK_kana_HI, 0x30D2},              // KATAKANA LETTER HI
    {XK_kana_FU, 0x30D5},              // KATAKANA LETTER HU
    {XK_kana_HE, 0x30D8},              // KATAKANA LETTER HE
    {XK_kana_HO, 0x30DB},              // KATAKANA LETTER HO
    {XK_kana_MA, 0x30DE},              // KATAKANA LETTER MA
    {XK_kana_MI, 0x30DF},              // KATAKANA LETTER MI
    {XK_kana_MU, 0x30E0},              // KATAKANA LETTER MU
    {XK_kana_ME, 0x30E1},              // KATAKANA LETTER ME
    {XK_kana_MO, 0x30E2},              // KATAKANA LETTER MO
    {XK_kana_YA, 0x30E4},              // KATAKANA LETTER YA
    {XK_kana_YU, 0x30E6},              // KATAKANA LETTER YU
    {XK_kana_YO, 0x30E8},              // KATAKANA LETTER YO
    {XK_kana_RA, 0x30E9},              // KATAKANA LETTER RA
    {XK_kana_RI, 0x30EA},              // KATAKANA LETTER RI
    {XK_kana_RU, 0x30EB},              // KATAKANA LETTER RU
    {XK_kana_RE, 0x30EC},              // KATAKANA LETTER RE
    {XK_kana_RO, 0x30ED},              // KATAKANA LETTER RO
    {XK_kana_WA, 0x30EF},              // KATAKANA LETTER WA
    {XK_kana_N, 0x30F3},               // KATAKANA LETTER N
    {XK_voicedsound, 0x309B},          // KATAKANA-HIRAGANA VOICED SOUND MARK
    {XK_semivoicedsound, 0x309C},  // KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK

    // Arabic KeySyms partially map 1:1 to Unicode
    {XK_Arabic_comma, 0x060C},           // ARABIC COMMA
    {XK_Arabic_semicolon, 0x061B},       // ARABIC SEMICOLON
    {XK_Arabic_question_mark, 0x061F},   // ARABIC QUESTION MARK
    {XK_Arabic_hamza, 0x0621},           // ARABIC LETTER HAMZA
    {XK_Arabic_maddaonalef, 0x0622},     // ARABIC LETTER ALEF WITH MADDA ABOVE
    {XK_Arabic_hamzaonalef, 0x0623},     // ARABIC LETTER ALEF WITH HAMZA ABOVE
    {XK_Arabic_hamzaonwaw, 0x0624},      // ARABIC LETTER WAW WITH HAMZA ABOVE
    {XK_Arabic_hamzaunderalef, 0x0625},  // ARABIC LETTER ALEF WITH HAMZA BELOW
    {XK_Arabic_hamzaonyeh, 0x0626},      // ARABIC LETTER YEH WITH HAMZA ABOVE
    {XK_Arabic_alef, 0x0627},            // ARABIC LETTER ALEF
    {XK_Arabic_beh, 0x0628},             // ARABIC LETTER BEH
    {XK_Arabic_tehmarbuta, 0x0629},      // ARABIC LETTER TEH MARBUTA
    {XK_Arabic_teh, 0x062A},             // ARABIC LETTER TEH
    {XK_Arabic_theh, 0x062B},            // ARABIC LETTER THEH
    {XK_Arabic_jeem, 0x062C},            // ARABIC LETTER JEEM
    {XK_Arabic_hah, 0x062D},             // ARABIC LETTER HAH
    {XK_Arabic_khah, 0x062E},            // ARABIC LETTER KHAH
    {XK_Arabic_dal, 0x062F},             // ARABIC LETTER DAL
    {XK_Arabic_thal, 0x0630},            // ARABIC LETTER THAL
    {XK_Arabic_ra, 0x0631},              // ARABIC LETTER REH
    {XK_Arabic_zain, 0x0632},            // ARABIC LETTER ZAIN
    {XK_Arabic_seen, 0x0633},            // ARABIC LETTER SEEN
    {XK_Arabic_sheen, 0x0634},           // ARABIC LETTER SHEEN
    {XK_Arabic_sad, 0x0635},             // ARABIC LETTER SAD
    {XK_Arabic_dad, 0x0636},             // ARABIC LETTER DAD
    {XK_Arabic_tah, 0x0637},             // ARABIC LETTER TAH
    {XK_Arabic_zah, 0x0638},             // ARABIC LETTER ZAH
    {XK_Arabic_ain, 0x0639},             // ARABIC LETTER AIN
    {XK_Arabic_ghain, 0x063A},           // ARABIC LETTER GHAIN
    {XK_Arabic_tatweel, 0x0640},         // ARABIC TATWEEL
    {XK_Arabic_feh, 0x0641},             // ARABIC LETTER FEH
    {XK_Arabic_qaf, 0x0642},             // ARABIC LETTER QAF
    {XK_Arabic_kaf, 0x0643},             // ARABIC LETTER KAF
    {XK_Arabic_lam, 0x0644},             // ARABIC LETTER LAM
    {XK_Arabic_meem, 0x0645},            // ARABIC LETTER MEEM
    {XK_Arabic_noon, 0x0646},            // ARABIC LETTER NOON
    {XK_Arabic_ha, 0x0647},              // ARABIC LETTER HEH
    {XK_Arabic_waw, 0x0648},             // ARABIC LETTER WAW
    {XK_Arabic_alefmaksura, 0x0649},     // ARABIC LETTER ALEF MAKSURA
    {XK_Arabic_yeh, 0x064A},             // ARABIC LETTER YEH
    {XK_Arabic_fathatan, 0x064B},        // ARABIC FATHATAN
    {XK_Arabic_dammatan, 0x064C},        // ARABIC DAMMATAN
    {XK_Arabic_kasratan, 0x064D},        // ARABIC KASRATAN
    {XK_Arabic_fatha, 0x064E},           // ARABIC FATHA
    {XK_Arabic_damma, 0x064F},           // ARABIC DAMMA
    {XK_Arabic_kasra, 0x0650},           // ARABIC KASRA
    {XK_Arabic_shadda, 0x0651},          // ARABIC SHADDA
    {XK_Arabic_sukun, 0x0652},           // ARABIC SUKUN

    // Cyrillic KeySyms partially map 1:1 to Unicode
    {XK_Serbian_dje, 0x0452},    // CYRILLIC SMALL LETTER DJE
    {XK_Macedonia_gje, 0x0453},  // CYRILLIC SMALL LETTER GJE
    {XK_Cyrillic_io, 0x0451},    // CYRILLIC SMALL LETTER IO
    {XK_Ukrainian_ie, 0x0454},   // CYRILLIC SMALL LETTER UKRAINIAN IE
    {XK_Macedonia_dse, 0x0455},  // CYRILLIC SMALL LETTER DZE
    {XK_Ukrainian_i, 0x0456},  // CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
    {XK_Ukrainian_yi, 0x0457},   // CYRILLIC SMALL LETTER YI
    {XK_Cyrillic_je, 0x0458},    // CYRILLIC SMALL LETTER JE
    {XK_Cyrillic_lje, 0x0459},   // CYRILLIC SMALL LETTER LJE
    {XK_Cyrillic_nje, 0x045A},   // CYRILLIC SMALL LETTER NJE
    {XK_Serbian_tshe, 0x045B},   // CYRILLIC SMALL LETTER TSHE
    {XK_Macedonia_kje, 0x045C},  // CYRILLIC SMALL LETTER KJE
    {XK_Ukrainian_ghe_with_upturn,
     0x0491},                          // CYRILLIC SMALL LETTER GHE WITH UPTURN
    {XK_Byelorussian_shortu, 0x045E},  // CYRILLIC SMALL LETTER SHORT U
    {XK_Cyrillic_dzhe, 0x045F},        // CYRILLIC SMALL LETTER DZHE
    {XK_numerosign, 0x2116},           // NUMERO SIGN
    {XK_Serbian_DJE, 0x0402},          // CYRILLIC CAPITAL LETTER DJE
    {XK_Macedonia_GJE, 0x0403},        // CYRILLIC CAPITAL LETTER GJE
    {XK_Cyrillic_IO, 0x0401},          // CYRILLIC CAPITAL LETTER IO
    {XK_Ukrainian_IE, 0x0404},         // CYRILLIC CAPITAL LETTER UKRAINIAN IE
    {XK_Macedonia_DSE, 0x0405},        // CYRILLIC CAPITAL LETTER DZE
    {XK_Ukrainian_I,
     0x0406},  // CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
    {XK_Ukrainian_YI, 0x0407},   // CYRILLIC CAPITAL LETTER YI
    {XK_Cyrillic_JE, 0x0408},    // CYRILLIC CAPITAL LETTER JE
    {XK_Cyrillic_LJE, 0x0409},   // CYRILLIC CAPITAL LETTER LJE
    {XK_Cyrillic_NJE, 0x040A},   // CYRILLIC CAPITAL LETTER NJE
    {XK_Serbian_TSHE, 0x040B},   // CYRILLIC CAPITAL LETTER TSHE
    {XK_Macedonia_KJE, 0x040C},  // CYRILLIC CAPITAL LETTER KJE
    {XK_Ukrainian_GHE_WITH_UPTURN,
     0x0490},  // CYRILLIC CAPITAL LETTER GHE WITH UPTURN
    {XK_Byelorussian_SHORTU, 0x040E},  // CYRILLIC CAPITAL LETTER SHORT U
    {XK_Cyrillic_DZHE, 0x040F},        // CYRILLIC CAPITAL LETTER DZHE
    {XK_Cyrillic_yu, 0x044E},          // CYRILLIC SMALL LETTER YU
    {XK_Cyrillic_a, 0x0430},           // CYRILLIC SMALL LETTER A
    {XK_Cyrillic_be, 0x0431},          // CYRILLIC SMALL LETTER BE
    {XK_Cyrillic_tse, 0x0446},         // CYRILLIC SMALL LETTER TSE
    {XK_Cyrillic_de, 0x0434},          // CYRILLIC SMALL LETTER DE
    {XK_Cyrillic_ie, 0x0435},          // CYRILLIC SMALL LETTER IE
    {XK_Cyrillic_ef, 0x0444},          // CYRILLIC SMALL LETTER EF
    {XK_Cyrillic_ghe, 0x0433},         // CYRILLIC SMALL LETTER GHE
    {XK_Cyrillic_ha, 0x0445},          // CYRILLIC SMALL LETTER HA
    {XK_Cyrillic_i, 0x0438},           // CYRILLIC SMALL LETTER I
    {XK_Cyrillic_shorti, 0x0439},      // CYRILLIC SMALL LETTER SHORT I
    {XK_Cyrillic_ka, 0x043A},          // CYRILLIC SMALL LETTER KA
    {XK_Cyrillic_el, 0x043B},          // CYRILLIC SMALL LETTER EL
    {XK_Cyrillic_em, 0x043C},          // CYRILLIC SMALL LETTER EM
    {XK_Cyrillic_en, 0x043D},          // CYRILLIC SMALL LETTER EN
    {XK_Cyrillic_o, 0x043E},           // CYRILLIC SMALL LETTER O
    {XK_Cyrillic_pe, 0x043F},          // CYRILLIC SMALL LETTER PE
    {XK_Cyrillic_ya, 0x044F},          // CYRILLIC SMALL LETTER YA
    {XK_Cyrillic_er, 0x0440},          // CYRILLIC SMALL LETTER ER
    {XK_Cyrillic_es, 0x0441},          // CYRILLIC SMALL LETTER ES
    {XK_Cyrillic_te, 0x0442},          // CYRILLIC SMALL LETTER TE
    {XK_Cyrillic_u, 0x0443},           // CYRILLIC SMALL LETTER U
    {XK_Cyrillic_zhe, 0x0436},         // CYRILLIC SMALL LETTER ZHE
    {XK_Cyrillic_ve, 0x0432},          // CYRILLIC SMALL LETTER VE
    {XK_Cyrillic_softsign, 0x044C},    // CYRILLIC SMALL LETTER SOFT SIGN
    {XK_Cyrillic_yeru, 0x044B},        // CYRILLIC SMALL LETTER YERU
    {XK_Cyrillic_ze, 0x0437},          // CYRILLIC SMALL LETTER ZE
    {XK_Cyrillic_sha, 0x0448},         // CYRILLIC SMALL LETTER SHA
    {XK_Cyrillic_e, 0x044D},           // CYRILLIC SMALL LETTER E
    {XK_Cyrillic_shcha, 0x0449},       // CYRILLIC SMALL LETTER SHCHA
    {XK_Cyrillic_che, 0x0447},         // CYRILLIC SMALL LETTER CHE
    {XK_Cyrillic_hardsign, 0x044A},    // CYRILLIC SMALL LETTER HARD SIGN
    {XK_Cyrillic_YU, 0x042E},          // CYRILLIC CAPITAL LETTER YU
    {XK_Cyrillic_A, 0x0410},           // CYRILLIC CAPITAL LETTER A
    {XK_Cyrillic_BE, 0x0411},          // CYRILLIC CAPITAL LETTER BE
    {XK_Cyrillic_TSE, 0x0426},         // CYRILLIC CAPITAL LETTER TSE
    {XK_Cyrillic_DE, 0x0414},          // CYRILLIC CAPITAL LETTER DE
    {XK_Cyrillic_IE, 0x0415},          // CYRILLIC CAPITAL LETTER IE
    {XK_Cyrillic_EF, 0x0424},          // CYRILLIC CAPITAL LETTER EF
    {XK_Cyrillic_GHE, 0x0413},         // CYRILLIC CAPITAL LETTER GHE
    {XK_Cyrillic_HA, 0x0425},          // CYRILLIC CAPITAL LETTER HA
    {XK_Cyrillic_I, 0x0418},           // CYRILLIC CAPITAL LETTER I
    {XK_Cyrillic_SHORTI, 0x0419},      // CYRILLIC CAPITAL LETTER SHORT I
    {XK_Cyrillic_KA, 0x041A},          // CYRILLIC CAPITAL LETTER KA
    {XK_Cyrillic_EL, 0x041B},          // CYRILLIC CAPITAL LETTER EL
    {XK_Cyrillic_EM, 0x041C},          // CYRILLIC CAPITAL LETTER EM
    {XK_Cyrillic_EN, 0x041D},          // CYRILLIC CAPITAL LETTER EN
    {XK_Cyrillic_O, 0x041E},           // CYRILLIC CAPITAL LETTER O
    {XK_Cyrillic_PE, 0x041F},          // CYRILLIC CAPITAL LETTER PE
    {XK_Cyrillic_YA, 0x042F},          // CYRILLIC CAPITAL LETTER YA
    {XK_Cyrillic_ER, 0x0420},          // CYRILLIC CAPITAL LETTER ER
    {XK_Cyrillic_ES, 0x0421},          // CYRILLIC CAPITAL LETTER ES
    {XK_Cyrillic_TE, 0x0422},          // CYRILLIC CAPITAL LETTER TE
    {XK_Cyrillic_U, 0x0423},           // CYRILLIC CAPITAL LETTER U
    {XK_Cyrillic_ZHE, 0x0416},         // CYRILLIC CAPITAL LETTER ZHE
    {XK_Cyrillic_VE, 0x0412},          // CYRILLIC CAPITAL LETTER VE
    {XK_Cyrillic_SOFTSIGN, 0x042C},    // CYRILLIC CAPITAL LETTER SOFT SIGN
    {XK_Cyrillic_YERU, 0x042B},        // CYRILLIC CAPITAL LETTER YERU
    {XK_Cyrillic_ZE, 0x0417},          // CYRILLIC CAPITAL LETTER ZE
    {XK_Cyrillic_SHA, 0x0428},         // CYRILLIC CAPITAL LETTER SHA
    {XK_Cyrillic_E, 0x042D},           // CYRILLIC CAPITAL LETTER E
    {XK_Cyrillic_SHCHA, 0x0429},       // CYRILLIC CAPITAL LETTER SHCHA
    {XK_Cyrillic_CHE, 0x0427},         // CYRILLIC CAPITAL LETTER CHE
    {XK_Cyrillic_HARDSIGN, 0x042A},    // CYRILLIC CAPITAL LETTER HARD SIGN

    // Greek
    {XK_Greek_ALPHAaccent, 0x0386},  // GREEK CAPITAL LETTER ALPHA WITH TONOS
    {XK_Greek_EPSILONaccent,
     0x0388},                       // GREEK CAPITAL LETTER EPSILON WITH TONOS
    {XK_Greek_ETAaccent, 0x0389},   // GREEK CAPITAL LETTER ETA WITH TONOS
    {XK_Greek_IOTAaccent, 0x038A},  // GREEK CAPITAL LETTER IOTA WITH TONOS
    {XK_Greek_IOTAdieresis,
     0x03AA},  // GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
    {XK_Greek_OMICRONaccent,
     0x038C},  // GREEK CAPITAL LETTER OMICRON WITH TONOS
    {XK_Greek_UPSILONaccent,
     0x038E},  // GREEK CAPITAL LETTER UPSILON WITH TONOS
    {XK_Greek_UPSILONdieresis,
     0x03AB},  // GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA
    {XK_Greek_OMEGAaccent, 0x038F},     // GREEK CAPITAL LETTER OMEGA WITH TONOS
    {XK_Greek_accentdieresis, 0x0385},  // GREEK DIALYTIKA TONOS
    {XK_Greek_horizbar, 0x2015},        // HORIZONTAL BAR
    {XK_Greek_alphaaccent, 0x03AC},     // GREEK SMALL LETTER ALPHA WITH TONOS
    {XK_Greek_epsilonaccent, 0x03AD},   // GREEK SMALL LETTER EPSILON WITH TONOS
    {XK_Greek_etaaccent, 0x03AE},       // GREEK SMALL LETTER ETA WITH TONOS
    {XK_Greek_iotaaccent, 0x03AF},      // GREEK SMALL LETTER IOTA WITH TONOS
    {XK_Greek_iotadieresis, 0x03CA},  // GREEK SMALL LETTER IOTA WITH DIALYTIKA
    {XK_Greek_iotaaccentdieresis,
     0x0390},  // GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
    {XK_Greek_omicronaccent, 0x03CC},  // GREEK SMALL LETTER OMICRON WITH TONOS
    {XK_Greek_upsilonaccent, 0x03CD},  // GREEK SMALL LETTER UPSILON WITH TONOS
    {XK_Greek_upsilondieresis,
     0x03CB},  // GREEK SMALL LETTER UPSILON WITH DIALYTIKA
    {XK_Greek_upsilonaccentdieresis,
     0x03B0},  // GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
    {XK_Greek_omegaaccent, 0x03CE},      // GREEK SMALL LETTER OMEGA WITH TONOS
    {XK_Greek_ALPHA, 0x0391},            // GREEK CAPITAL LETTER ALPHA
    {XK_Greek_BETA, 0x0392},             // GREEK CAPITAL LETTER BETA
    {XK_Greek_GAMMA, 0x0393},            // GREEK CAPITAL LETTER GAMMA
    {XK_Greek_DELTA, 0x0394},            // GREEK CAPITAL LETTER DELTA
    {XK_Greek_EPSILON, 0x0395},          // GREEK CAPITAL LETTER EPSILON
    {XK_Greek_ZETA, 0x0396},             // GREEK CAPITAL LETTER ZETA
    {XK_Greek_ETA, 0x0397},              // GREEK CAPITAL LETTER ETA
    {XK_Greek_THETA, 0x0398},            // GREEK CAPITAL LETTER THETA
    {XK_Greek_IOTA, 0x0399},             // GREEK CAPITAL LETTER IOTA
    {XK_Greek_KAPPA, 0x039A},            // GREEK CAPITAL LETTER KAPPA
    {XK_Greek_LAMDA, 0x039B},            // GREEK CAPITAL LETTER LAMDA
    {XK_Greek_LAMBDA, 0x039B},           // GREEK CAPITAL LETTER LAMDA
    {XK_Greek_MU, 0x039C},               // GREEK CAPITAL LETTER MU
    {XK_Greek_NU, 0x039D},               // GREEK CAPITAL LETTER NU
    {XK_Greek_XI, 0x039E},               // GREEK CAPITAL LETTER XI
    {XK_Greek_OMICRON, 0x039F},          // GREEK CAPITAL LETTER OMICRON
    {XK_Greek_PI, 0x03A0},               // GREEK CAPITAL LETTER PI
    {XK_Greek_RHO, 0x03A1},              // GREEK CAPITAL LETTER RHO
    {XK_Greek_SIGMA, 0x03A3},            // GREEK CAPITAL LETTER SIGMA
    {XK_Greek_TAU, 0x03A4},              // GREEK CAPITAL LETTER TAU
    {XK_Greek_UPSILON, 0x03A5},          // GREEK CAPITAL LETTER UPSILON
    {XK_Greek_PHI, 0x03A6},              // GREEK CAPITAL LETTER PHI
    {XK_Greek_CHI, 0x03A7},              // GREEK CAPITAL LETTER CHI
    {XK_Greek_PSI, 0x03A8},              // GREEK CAPITAL LETTER PSI
    {XK_Greek_OMEGA, 0x03A9},            // GREEK CAPITAL LETTER OMEGA
    {XK_Greek_alpha, 0x03B1},            // GREEK SMALL LETTER ALPHA
    {XK_Greek_beta, 0x03B2},             // GREEK SMALL LETTER BETA
    {XK_Greek_gamma, 0x03B3},            // GREEK SMALL LETTER GAMMA
    {XK_Greek_delta, 0x03B4},            // GREEK SMALL LETTER DELTA
    {XK_Greek_epsilon, 0x03B5},          // GREEK SMALL LETTER EPSILON
    {XK_Greek_zeta, 0x03B6},             // GREEK SMALL LETTER ZETA
    {XK_Greek_eta, 0x03B7},              // GREEK SMALL LETTER ETA
    {XK_Greek_theta, 0x03B8},            // GREEK SMALL LETTER THETA
    {XK_Greek_iota, 0x03B9},             // GREEK SMALL LETTER IOTA
    {XK_Greek_kappa, 0x03BA},            // GREEK SMALL LETTER KAPPA
    {XK_Greek_lamda, 0x03BB},            // GREEK SMALL LETTER LAMDA
    {XK_Greek_lambda, 0x03BB},           // GREEK SMALL LETTER LAMDA
    {XK_Greek_mu, 0x03BC},               // GREEK SMALL LETTER MU
    {XK_Greek_nu, 0x03BD},               // GREEK SMALL LETTER NU
    {XK_Greek_xi, 0x03BE},               // GREEK SMALL LETTER XI
    {XK_Greek_omicron, 0x03BF},          // GREEK SMALL LETTER OMICRON
    {XK_Greek_pi, 0x03C0},               // GREEK SMALL LETTER PI
    {XK_Greek_rho, 0x03C1},              // GREEK SMALL LETTER RHO
    {XK_Greek_sigma, 0x03C3},            // GREEK SMALL LETTER SIGMA
    {XK_Greek_finalsmallsigma, 0x03C2},  // GREEK SMALL LETTER FINAL SIGMA
    {XK_Greek_tau, 0x03C4},              // GREEK SMALL LETTER TAU
    {XK_Greek_upsilon, 0x03C5},          // GREEK SMALL LETTER UPSILON
    {XK_Greek_phi, 0x03C6},              // GREEK SMALL LETTER PHI
    {XK_Greek_chi, 0x03C7},              // GREEK SMALL LETTER CHI
    {XK_Greek_psi, 0x03C8},              // GREEK SMALL LETTER PSI
    {XK_Greek_omega, 0x03C9},            // GREEK SMALL LETTER OMEGA

    // Technical
    {XK_leftradical, 0x23B7},            // RADICAL SYMBOL BOTTOM
    {XK_topleftradical, 0x250C},         // BOX DRAWINGS LIGHT DOWN AND RIGHT
    {XK_horizconnector, 0x2500},         // BOX DRAWINGS LIGHT HORIZONTAL
    {XK_topintegral, 0x2320},            // TOP HALF INTEGRAL
    {XK_botintegral, 0x2321},            // BOTTOM HALF INTEGRAL
    {XK_vertconnector, 0x2502},          // BOX DRAWINGS LIGHT VERTICAL
    {XK_topleftsqbracket, 0x23A1},       // LEFT SQUARE BRACKET UPPER CORNER
    {XK_botleftsqbracket, 0x23A3},       // LEFT SQUARE BRACKET LOWER CORNER
    {XK_toprightsqbracket, 0x23A4},      // RIGHT SQUARE BRACKET UPPER CORNER
    {XK_botrightsqbracket, 0x23A6},      // RIGHT SQUARE BRACKET LOWER CORNER
    {XK_topleftparens, 0x239B},          // LEFT PARENTHESIS UPPER HOOK
    {XK_botleftparens, 0x239D},          // LEFT PARENTHESIS LOWER HOOK
    {XK_toprightparens, 0x239E},         // RIGHT PARENTHESIS UPPER HOOK
    {XK_botrightparens, 0x23A0},         // RIGHT PARENTHESIS LOWER HOOK
    {XK_leftmiddlecurlybrace, 0x23A8},   // LEFT CURLY BRACKET MIDDLE PIECE
    {XK_rightmiddlecurlybrace, 0x23AC},  // RIGHT CURLY BRACKET MIDDLE PIECE
    {XK_lessthanequal, 0x2264},          // LESS-THAN OR EQUAL TO
    {XK_notequal, 0x2260},               // NOT EQUAL TO
    {XK_greaterthanequal, 0x2265},       // GREATER-THAN OR EQUAL TO
    {XK_integral, 0x222B},               // INTEGRAL
    {XK_therefore, 0x2234},              // THEREFORE
    {XK_variation, 0x221D},              // PROPORTIONAL TO
    {XK_infinity, 0x221E},               // INFINITY
    {XK_nabla, 0x2207},                  // NABLA
    {XK_approximate, 0x223C},            // TILDE OPERATOR
    {XK_similarequal, 0x2243},           // ASYMPTOTICALLY EQUAL TO
    {XK_ifonlyif, 0x21D4},               // LEFT RIGHT DOUBLE ARROW
    {XK_implies, 0x21D2},                // RIGHTWARDS DOUBLE ARROW
    {XK_identical, 0x2261},              // IDENTICAL TO
    {XK_radical, 0x221A},                // SQUARE ROOT
    {XK_includedin, 0x2282},             // SUBSET OF
    {XK_includes, 0x2283},               // SUPERSET OF
    {XK_intersection, 0x2229},           // INTERSECTION
    {XK_union, 0x222A},                  // UNION
    {XK_logicaland, 0x2227},             // LOGICAL AND
    {XK_logicalor, 0x2228},              // LOGICAL OR
    {XK_partialderivative, 0x2202},      // PARTIAL DIFFERENTIAL
    {XK_function, 0x0192},               // LATIN SMALL LETTER F WITH HOOK
    {XK_leftarrow, 0x2190},              // LEFTWARDS ARROW
    {XK_uparrow, 0x2191},                // UPWARDS ARROW
    {XK_rightarrow, 0x2192},             // RIGHTWARDS ARROW
    {XK_downarrow, 0x2193},              // DOWNWARDS ARROW

    // Special
    {XK_soliddiamond, 0x25C6},    // BLACK DIAMOND
    {XK_checkerboard, 0x2592},    // MEDIUM SHADE
    {XK_ht, 0x2409},              // SYMBOL FOR HORIZONTAL TABULATION
    {XK_ff, 0x240C},              // SYMBOL FOR FORM FEED
    {XK_cr, 0x240D},              // SYMBOL FOR CARRIAGE RETURN
    {XK_lf, 0x240A},              // SYMBOL FOR LINE FEED
    {XK_nl, 0x2424},              // SYMBOL FOR NEWLINE
    {XK_vt, 0x240B},              // SYMBOL FOR VERTICAL TABULATION
    {XK_lowrightcorner, 0x2518},  // BOX DRAWINGS LIGHT UP AND LEFT
    {XK_uprightcorner, 0x2510},   // BOX DRAWINGS LIGHT DOWN AND LEFT
    {XK_upleftcorner, 0x250C},    // BOX DRAWINGS LIGHT DOWN AND RIGHT
    {XK_lowleftcorner, 0x2514},   // BOX DRAWINGS LIGHT UP AND RIGHT
    {XK_crossinglines, 0x253C},   // BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
    {XK_horizlinescan1, 0x23BA},  // HORIZONTAL SCAN LINE-1
    {XK_horizlinescan3, 0x23BB},  // HORIZONTAL SCAN LINE-3
    {XK_horizlinescan5, 0x2500},  // BOX DRAWINGS LIGHT HORIZONTAL
    {XK_horizlinescan7, 0x23BC},  // HORIZONTAL SCAN LINE-7
    {XK_horizlinescan9, 0x23BD},  // HORIZONTAL SCAN LINE-9
    {XK_leftt, 0x251C},           // BOX DRAWINGS LIGHT VERTICAL AND RIGHT
    {XK_rightt, 0x2524},          // BOX DRAWINGS LIGHT VERTICAL AND LEFT
    {XK_bott, 0x2534},            // BOX DRAWINGS LIGHT UP AND HORIZONTAL
    {XK_topt, 0x252C},            // BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
    {XK_vertbar, 0x2502},         // BOX DRAWINGS LIGHT VERTICAL

    // Publishing
    {XK_emspace, 0x2003},               // EM SPACE
    {XK_enspace, 0x2002},               // EN SPACE
    {XK_em3space, 0x2004},              // THREE-PER-EM SPACE
    {XK_em4space, 0x2005},              // FOUR-PER-EM SPACE
    {XK_digitspace, 0x2007},            // FIGURE SPACE
    {XK_punctspace, 0x2008},            // PUNCTUATION SPACE
    {XK_thinspace, 0x2009},             // THIN SPACE
    {XK_hairspace, 0x200A},             // HAIR SPACE
    {XK_emdash, 0x2014},                // EM DASH
    {XK_endash, 0x2013},                // EN DASH
    {XK_signifblank, 0x2423},           // OPEN BOX
    {XK_ellipsis, 0x2026},              // HORIZONTAL ELLIPSIS
    {XK_doubbaselinedot, 0x2025},       // TWO DOT LEADER
    {XK_onethird, 0x2153},              // VULGAR FRACTION ONE THIRD
    {XK_twothirds, 0x2154},             // VULGAR FRACTION TWO THIRDS
    {XK_onefifth, 0x2155},              // VULGAR FRACTION ONE FIFTH
    {XK_twofifths, 0x2156},             // VULGAR FRACTION TWO FIFTHS
    {XK_threefifths, 0x2157},           // VULGAR FRACTION THREE FIFTHS
    {XK_fourfifths, 0x2158},            // VULGAR FRACTION FOUR FIFTHS
    {XK_onesixth, 0x2159},              // VULGAR FRACTION ONE SIXTH
    {XK_fivesixths, 0x215A},            // VULGAR FRACTION FIVE SIXTHS
    {XK_careof, 0x2105},                // CARE OF
    {XK_figdash, 0x2012},               // FIGURE DASH
    {XK_leftanglebracket, 0x27E8},      // MATHEMATICAL LEFT ANGLE BRACKET
    {XK_decimalpoint, 0x002E},          // FULL STOP
    {XK_rightanglebracket, 0x27E9},     // MATHEMATICAL RIGHT ANGLE BRACKET
    {XK_oneeighth, 0x215B},             // VULGAR FRACTION ONE EIGHTH
    {XK_threeeighths, 0x215C},          // VULGAR FRACTION THREE EIGHTHS
    {XK_fiveeighths, 0x215D},           // VULGAR FRACTION FIVE EIGHTHS
    {XK_seveneighths, 0x215E},          // VULGAR FRACTION SEVEN EIGHTHS
    {XK_trademark, 0x2122},             // TRADE MARK SIGN
    {XK_signaturemark, 0x2613},         // SALTIRE
    {XK_leftopentriangle, 0x25C1},      // WHITE LEFT-POINTING TRIANGLE
    {XK_rightopentriangle, 0x25B7},     // WHITE RIGHT-POINTING TRIANGLE
    {XK_emopencircle, 0x25CB},          // WHITE CIRCLE
    {XK_emopenrectangle, 0x25AF},       // WHITE VERTICAL RECTANGLE
    {XK_leftsinglequotemark, 0x2018},   // LEFT SINGLE QUOTATION MARK
    {XK_rightsinglequotemark, 0x2019},  // RIGHT SINGLE QUOTATION MARK
    {XK_leftdoublequotemark, 0x201C},   // LEFT DOUBLE QUOTATION MARK
    {XK_rightdoublequotemark, 0x201D},  // RIGHT DOUBLE QUOTATION MARK
    {XK_prescription, 0x211E},          // PRESCRIPTION TAKE
    {XK_minutes, 0x2032},               // PRIME
    {XK_seconds, 0x2033},               // DOUBLE PRIME
    {XK_latincross, 0x271D},            // LATIN CROSS
    {XK_filledrectbullet, 0x25AC},      // BLACK RECTANGLE
    {XK_filledlefttribullet, 0x25C0},   // BLACK LEFT-POINTING TRIANGLE
    {XK_filledrighttribullet, 0x25B6},  // BLACK RIGHT-POINTING TRIANGLE
    {XK_emfilledcircle, 0x25CF},        // BLACK CIRCLE
    {XK_emfilledrect, 0x25AE},          // BLACK VERTICAL RECTANGLE
    {XK_enopencircbullet, 0x25E6},      // WHITE BULLET
    {XK_enopensquarebullet, 0x25AB},    // WHITE SMALL SQUARE
    {XK_openrectbullet, 0x25AD},        // WHITE RECTANGLE
    {XK_opentribulletup, 0x25B3},       // WHITE UP-POINTING TRIANGLE
    {XK_opentribulletdown, 0x25BD},     // WHITE DOWN-POINTING TRIANGLE
    {XK_openstar, 0x2606},              // WHITE STAR
    {XK_enfilledcircbullet, 0x2022},    // BULLET
    {XK_enfilledsqbullet, 0x25AA},      // BLACK SMALL SQUARE
    {XK_filledtribulletup, 0x25B2},     // BLACK UP-POINTING TRIANGLE
    {XK_filledtribulletdown, 0x25BC},   // BLACK DOWN-POINTING TRIANGLE
    {XK_leftpointer, 0x261C},           // WHITE LEFT POINTING INDEX
    {XK_rightpointer, 0x261E},          // WHITE RIGHT POINTING INDEX
    {XK_club, 0x2663},                  // BLACK CLUB SUIT
    {XK_diamond, 0x2666},               // BLACK DIAMOND SUIT
    {XK_heart, 0x2665},                 // BLACK HEART SUIT
    {XK_maltesecross, 0x2720},          // MALTESE CROSS
    {XK_dagger, 0x2020},                // DAGGER
    {XK_doubledagger, 0x2021},          // DOUBLE DAGGER
    {XK_checkmark, 0x2713},             // CHECK MARK
    {XK_ballotcross, 0x2717},           // BALLOT X
    {XK_musicalsharp, 0x266F},          // MUSIC SHARP SIGN
    {XK_musicalflat, 0x266D},           // MUSIC FLAT SIGN
    {XK_malesymbol, 0x2642},            // MALE SIGN
    {XK_femalesymbol, 0x2640},          // FEMALE SIGN
    {XK_telephone, 0x260E},             // BLACK TELEPHONE
    {XK_telephonerecorder, 0x2315},     // TELEPHONE RECORDER
    {XK_phonographcopyright, 0x2117},   // SOUND RECORDING COPYRIGHT
    {XK_caret, 0x2038},                 // CARET
    {XK_singlelowquotemark, 0x201A},    // SINGLE LOW-9 QUOTATION MARK
    {XK_doublelowquotemark, 0x201E},    // DOUBLE LOW-9 QUOTATION MARK

    // APL
    {XK_leftcaret, 0x003C},   // LESS-THAN SIGN
    {XK_rightcaret, 0x003E},  // GREATER-THAN SIGN
    {XK_downcaret, 0x2228},   // LOGICAL OR
    {XK_upcaret, 0x2227},     // LOGICAL AND
    {XK_overbar, 0x00AF},     // MACRON
    {XK_downtack, 0x22A4},    // DOWN TACK
    {XK_upshoe, 0x2229},      // INTERSECTION
    {XK_downstile, 0x230A},   // LEFT FLOOR
    {XK_underbar, 0x005F},    // LOW LINE
    {XK_jot, 0x2218},         // RING OPERATOR
    {XK_quad, 0x2395},        // APL FUNCTIONAL SYMBOL QUAD
    {XK_uptack, 0x22A5},      // UP TACK
    {XK_circle, 0x25CB},      // WHITE CIRCLE
    {XK_upstile, 0x2308},     // LEFT CEILING
    {XK_downshoe, 0x222A},    // UNION
    {XK_rightshoe, 0x2283},   // SUPERSET OF
    {XK_leftshoe, 0x2282},    // SUBSET OF
    {XK_lefttack, 0x22A3},    // LEFT TACK
    {XK_righttack, 0x22A2},   // RIGHT TACK

    // Hebrew
    {XK_hebrew_doublelowline, 0x2017},  // DOUBLE LOW LINE
    {XK_hebrew_aleph, 0x05D0},          // HEBREW LETTER ALEF
    {XK_hebrew_bet, 0x05D1},            // HEBREW LETTER BET
    {XK_hebrew_gimel, 0x05D2},          // HEBREW LETTER GIMEL
    {XK_hebrew_dalet, 0x05D3},          // HEBREW LETTER DALET
    {XK_hebrew_he, 0x05D4},             // HEBREW LETTER HE
    {XK_hebrew_waw, 0x05D5},            // HEBREW LETTER VAV
    {XK_hebrew_zain, 0x05D6},           // HEBREW LETTER ZAYIN
    {XK_hebrew_chet, 0x05D7},           // HEBREW LETTER HET
    {XK_hebrew_tet, 0x05D8},            // HEBREW LETTER TET
    {XK_hebrew_yod, 0x05D9},            // HEBREW LETTER YOD
    {XK_hebrew_finalkaph, 0x05DA},      // HEBREW LETTER FINAL KAF
    {XK_hebrew_kaph, 0x05DB},           // HEBREW LETTER KAF
    {XK_hebrew_lamed, 0x05DC},          // HEBREW LETTER LAMED
    {XK_hebrew_finalmem, 0x05DD},       // HEBREW LETTER FINAL MEM
    {XK_hebrew_mem, 0x05DE},            // HEBREW LETTER MEM
    {XK_hebrew_finalnun, 0x05DF},       // HEBREW LETTER FINAL NUN
    {XK_hebrew_nun, 0x05E0},            // HEBREW LETTER NUN
    {XK_hebrew_samech, 0x05E1},         // HEBREW LETTER SAMEKH
    {XK_hebrew_ayin, 0x05E2},           // HEBREW LETTER AYIN
    {XK_hebrew_finalpe, 0x05E3},        // HEBREW LETTER FINAL PE
    {XK_hebrew_pe, 0x05E4},             // HEBREW LETTER PE
    {XK_hebrew_finalzade, 0x05E5},      // HEBREW LETTER FINAL TSADI
    {XK_hebrew_zade, 0x05E6},           // HEBREW LETTER TSADI
    {XK_hebrew_qoph, 0x05E7},           // HEBREW LETTER QOF
    {XK_hebrew_resh, 0x05E8},           // HEBREW LETTER RESH
    {XK_hebrew_shin, 0x05E9},           // HEBREW LETTER SHIN
    {XK_hebrew_taw, 0x05EA},            // HEBREW LETTER TAV

    // Thai
    {XK_Thai_kokai, 0x0E01},           // THAI CHARACTER KO KAI
    {XK_Thai_khokhai, 0x0E02},         // THAI CHARACTER KHO KHAI
    {XK_Thai_khokhuat, 0x0E03},        // THAI CHARACTER KHO KHUAT
    {XK_Thai_khokhwai, 0x0E04},        // THAI CHARACTER KHO KHWAI
    {XK_Thai_khokhon, 0x0E05},         // THAI CHARACTER KHO KHON
    {XK_Thai_khorakhang, 0x0E06},      // THAI CHARACTER KHO RAKHANG
    {XK_Thai_ngongu, 0x0E07},          // THAI CHARACTER NGO NGU
    {XK_Thai_chochan, 0x0E08},         // THAI CHARACTER CHO CHAN
    {XK_Thai_choching, 0x0E09},        // THAI CHARACTER CHO CHING
    {XK_Thai_chochang, 0x0E0A},        // THAI CHARACTER CHO CHANG
    {XK_Thai_soso, 0x0E0B},            // THAI CHARACTER SO SO
    {XK_Thai_chochoe, 0x0E0C},         // THAI CHARACTER CHO CHOE
    {XK_Thai_yoying, 0x0E0D},          // THAI CHARACTER YO YING
    {XK_Thai_dochada, 0x0E0E},         // THAI CHARACTER DO CHADA
    {XK_Thai_topatak, 0x0E0F},         // THAI CHARACTER TO PATAK
    {XK_Thai_thothan, 0x0E10},         // THAI CHARACTER THO THAN
    {XK_Thai_thonangmontho, 0x0E11},   // THAI CHARACTER THO NANGMONTHO
    {XK_Thai_thophuthao, 0x0E12},      // THAI CHARACTER THO PHUTHAO
    {XK_Thai_nonen, 0x0E13},           // THAI CHARACTER NO NEN
    {XK_Thai_dodek, 0x0E14},           // THAI CHARACTER DO DEK
    {XK_Thai_totao, 0x0E15},           // THAI CHARACTER TO TAO
    {XK_Thai_thothung, 0x0E16},        // THAI CHARACTER THO THUNG
    {XK_Thai_thothahan, 0x0E17},       // THAI CHARACTER THO THAHAN
    {XK_Thai_thothong, 0x0E18},        // THAI CHARACTER THO THONG
    {XK_Thai_nonu, 0x0E19},            // THAI CHARACTER NO NU
    {XK_Thai_bobaimai, 0x0E1A},        // THAI CHARACTER BO BAIMAI
    {XK_Thai_popla, 0x0E1B},           // THAI CHARACTER PO PLA
    {XK_Thai_phophung, 0x0E1C},        // THAI CHARACTER PHO PHUNG
    {XK_Thai_fofa, 0x0E1D},            // THAI CHARACTER FO FA
    {XK_Thai_phophan, 0x0E1E},         // THAI CHARACTER PHO PHAN
    {XK_Thai_fofan, 0x0E1F},           // THAI CHARACTER FO FAN
    {XK_Thai_phosamphao, 0x0E20},      // THAI CHARACTER PHO SAMPHAO
    {XK_Thai_moma, 0x0E21},            // THAI CHARACTER MO MA
    {XK_Thai_yoyak, 0x0E22},           // THAI CHARACTER YO YAK
    {XK_Thai_rorua, 0x0E23},           // THAI CHARACTER RO RUA
    {XK_Thai_ru, 0x0E24},              // THAI CHARACTER RU
    {XK_Thai_loling, 0x0E25},          // THAI CHARACTER LO LING
    {XK_Thai_lu, 0x0E26},              // THAI CHARACTER LU
    {XK_Thai_wowaen, 0x0E27},          // THAI CHARACTER WO WAEN
    {XK_Thai_sosala, 0x0E28},          // THAI CHARACTER SO SALA
    {XK_Thai_sorusi, 0x0E29},          // THAI CHARACTER SO RUSI
    {XK_Thai_sosua, 0x0E2A},           // THAI CHARACTER SO SUA
    {XK_Thai_hohip, 0x0E2B},           // THAI CHARACTER HO HIP
    {XK_Thai_lochula, 0x0E2C},         // THAI CHARACTER LO CHULA
    {XK_Thai_oang, 0x0E2D},            // THAI CHARACTER O ANG
    {XK_Thai_honokhuk, 0x0E2E},        // THAI CHARACTER HO NOKHUK
    {XK_Thai_paiyannoi, 0x0E2F},       // THAI CHARACTER PAIYANNOI
    {XK_Thai_saraa, 0x0E30},           // THAI CHARACTER SARA A
    {XK_Thai_maihanakat, 0x0E31},      // THAI CHARACTER MAI HAN-AKAT
    {XK_Thai_saraaa, 0x0E32},          // THAI CHARACTER SARA AA
    {XK_Thai_saraam, 0x0E33},          // THAI CHARACTER SARA AM
    {XK_Thai_sarai, 0x0E34},           // THAI CHARACTER SARA I
    {XK_Thai_saraii, 0x0E35},          // THAI CHARACTER SARA II
    {XK_Thai_saraue, 0x0E36},          // THAI CHARACTER SARA UE
    {XK_Thai_sarauee, 0x0E37},         // THAI CHARACTER SARA UEE
    {XK_Thai_sarau, 0x0E38},           // THAI CHARACTER SARA U
    {XK_Thai_sarauu, 0x0E39},          // THAI CHARACTER SARA UU
    {XK_Thai_phinthu, 0x0E3A},         // THAI CHARACTER PHINTHU
    {XK_Thai_baht, 0x0E3F},            // THAI CURRENCY SYMBOL BAHT
    {XK_Thai_sarae, 0x0E40},           // THAI CHARACTER SARA E
    {XK_Thai_saraae, 0x0E41},          // THAI CHARACTER SARA AE
    {XK_Thai_sarao, 0x0E42},           // THAI CHARACTER SARA O
    {XK_Thai_saraaimaimuan, 0x0E43},   // THAI CHARACTER SARA AI MAIMUAN
    {XK_Thai_saraaimaimalai, 0x0E44},  // THAI CHARACTER SARA AI MAIMALAI
    {XK_Thai_lakkhangyao, 0x0E45},     // THAI CHARACTER LAKKHANGYAO
    {XK_Thai_maiyamok, 0x0E46},        // THAI CHARACTER MAIYAMOK
    {XK_Thai_maitaikhu, 0x0E47},       // THAI CHARACTER MAITAIKHU
    {XK_Thai_maiek, 0x0E48},           // THAI CHARACTER MAI EK
    {XK_Thai_maitho, 0x0E49},          // THAI CHARACTER MAI THO
    {XK_Thai_maitri, 0x0E4A},          // THAI CHARACTER MAI TRI
    {XK_Thai_maichattawa, 0x0E4B},     // THAI CHARACTER MAI CHATTAWA
    {XK_Thai_thanthakhat, 0x0E4C},     // THAI CHARACTER THANTHAKHAT
    {XK_Thai_nikhahit, 0x0E4D},        // THAI CHARACTER NIKHAHIT
    {XK_Thai_leksun, 0x0E50},          // THAI DIGIT ZERO
    {XK_Thai_leknung, 0x0E51},         // THAI DIGIT ONE
    {XK_Thai_leksong, 0x0E52},         // THAI DIGIT TWO
    {XK_Thai_leksam, 0x0E53},          // THAI DIGIT THREE
    {XK_Thai_leksi, 0x0E54},           // THAI DIGIT FOUR
    {XK_Thai_lekha, 0x0E55},           // THAI DIGIT FIVE
    {XK_Thai_lekhok, 0x0E56},          // THAI DIGIT SIX
    {XK_Thai_lekchet, 0x0E57},         // THAI DIGIT SEVEN
    {XK_Thai_lekpaet, 0x0E58},         // THAI DIGIT EIGHT
    {XK_Thai_lekkao, 0x0E59},          // THAI DIGIT NINE

    // Korean
    {XK_Korean_Won, 0x20A9},  // WON SIGN

    // Armenian KeySyms map 1:1 to Unicode

    // Georgian KeySyms map 1:1 to Unicode

    // Azeri KeySyms map 1:1 to Unicode

    // Vietnamese KeySyms map 1:1 to Unicode

    // Currency KeySyms partially map 1:1 to Unicode
    {XK_EuroSign, 0x20AC},  // EURO SIGN

    // Mathematical KeySyms map 1:1 to Unicode

    // Braille KeySyms map 1:1 to Unicode

    // Sinhala KeySyms map 1:1 to Unicode
};

class KeySymToUnicode {
 public:
  KeySymToUnicode()
      : keysym_to_unicode_map_(arraysize(g_keysym_to_unicode_table)) {
    for (size_t i = 0; i < arraysize(g_keysym_to_unicode_table); ++i) {
      keysym_to_unicode_map_[g_keysym_to_unicode_table[i].keysym] =
          g_keysym_to_unicode_table[i].unicode;
    }
  }

  uint16_t UnicodeFromKeySym(KeySym keysym) const {
    // Latin-1 characters have the same representation.
    if ((0x0020 <= keysym && keysym <= 0x007e) ||
        (0x00a0 <= keysym && keysym <= 0x00ff))
      return static_cast<uint16_t>(keysym);

    // Unicode-style KeySyms.
    if ((keysym & 0xffe00000) == 0x01000000) {
      uint32_t unicode = static_cast<uint32_t>(keysym & 0x1fffff);
      if (unicode & ~0xffff)
        return 0;  // We don't support characters outside the Basic Plane.
      return static_cast<uint16_t>(unicode);
    }

    // Other KeySyms which are not Unicode-style.
    KeySymToUnicodeMap::const_iterator i = keysym_to_unicode_map_.find(keysym);
    return i != keysym_to_unicode_map_.end() ? i->second : 0;
  }

 private:
  typedef std::unordered_map<KeySym, uint16_t> KeySymToUnicodeMap;
  KeySymToUnicodeMap keysym_to_unicode_map_;

  DISALLOW_COPY_AND_ASSIGN(KeySymToUnicode);
};

static base::LazyInstance<KeySymToUnicode>::Leaky g_keysym_to_unicode =
    LAZY_INSTANCE_INITIALIZER;

uint16_t GetUnicodeCharacterFromXKeySym(unsigned long keysym) {
  return g_keysym_to_unicode.Get().UnicodeFromKeySym(
      static_cast<KeySym>(keysym));
}

}  // namespace ui
