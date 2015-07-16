/*
 * Copyright (C) 2012 Grigori Goronzy <greg@kinoho.net>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include "hb-private.hh"

#include "hb-unicode-private.hh"

#include "ucdn.h"

static const hb_script_t ucdn_script_translate[] =
{
    HB_SCRIPT_COMMON,
    HB_SCRIPT_LATIN,
    HB_SCRIPT_GREEK,
    HB_SCRIPT_CYRILLIC,
    HB_SCRIPT_ARMENIAN,
    HB_SCRIPT_HEBREW,
    HB_SCRIPT_ARABIC,
    HB_SCRIPT_SYRIAC,
    HB_SCRIPT_THAANA,
    HB_SCRIPT_DEVANAGARI,
    HB_SCRIPT_BENGALI,
    HB_SCRIPT_GURMUKHI,
    HB_SCRIPT_GUJARATI,
    HB_SCRIPT_ORIYA,
    HB_SCRIPT_TAMIL,
    HB_SCRIPT_TELUGU,
    HB_SCRIPT_KANNADA,
    HB_SCRIPT_MALAYALAM,
    HB_SCRIPT_SINHALA,
    HB_SCRIPT_THAI,
    HB_SCRIPT_LAO,
    HB_SCRIPT_TIBETAN,
    HB_SCRIPT_MYANMAR,
    HB_SCRIPT_GEORGIAN,
    HB_SCRIPT_HANGUL,
    HB_SCRIPT_ETHIOPIC,
    HB_SCRIPT_CHEROKEE,
    HB_SCRIPT_CANADIAN_SYLLABICS,
    HB_SCRIPT_OGHAM,
    HB_SCRIPT_RUNIC,
    HB_SCRIPT_KHMER,
    HB_SCRIPT_MONGOLIAN,
    HB_SCRIPT_HIRAGANA,
    HB_SCRIPT_KATAKANA,
    HB_SCRIPT_BOPOMOFO,
    HB_SCRIPT_HAN,
    HB_SCRIPT_YI,
    HB_SCRIPT_OLD_ITALIC,
    HB_SCRIPT_GOTHIC,
    HB_SCRIPT_DESERET,
    HB_SCRIPT_INHERITED,
    HB_SCRIPT_TAGALOG,
    HB_SCRIPT_HANUNOO,
    HB_SCRIPT_BUHID,
    HB_SCRIPT_TAGBANWA,
    HB_SCRIPT_LIMBU,
    HB_SCRIPT_TAI_LE,
    HB_SCRIPT_LINEAR_B,
    HB_SCRIPT_UGARITIC,
    HB_SCRIPT_SHAVIAN,
    HB_SCRIPT_OSMANYA,
    HB_SCRIPT_CYPRIOT,
    HB_SCRIPT_BRAILLE,
    HB_SCRIPT_BUGINESE,
    HB_SCRIPT_COPTIC,
    HB_SCRIPT_NEW_TAI_LUE,
    HB_SCRIPT_GLAGOLITIC,
    HB_SCRIPT_TIFINAGH,
    HB_SCRIPT_SYLOTI_NAGRI,
    HB_SCRIPT_OLD_PERSIAN,
    HB_SCRIPT_KHAROSHTHI,
    HB_SCRIPT_BALINESE,
    HB_SCRIPT_CUNEIFORM,
    HB_SCRIPT_PHOENICIAN,
    HB_SCRIPT_PHAGS_PA,
    HB_SCRIPT_NKO,
    HB_SCRIPT_SUNDANESE,
    HB_SCRIPT_LEPCHA,
    HB_SCRIPT_OL_CHIKI,
    HB_SCRIPT_VAI,
    HB_SCRIPT_SAURASHTRA,
    HB_SCRIPT_KAYAH_LI,
    HB_SCRIPT_REJANG,
    HB_SCRIPT_LYCIAN,
    HB_SCRIPT_CARIAN,
    HB_SCRIPT_LYDIAN,
    HB_SCRIPT_CHAM,
    HB_SCRIPT_TAI_THAM,
    HB_SCRIPT_TAI_VIET,
    HB_SCRIPT_AVESTAN,
    HB_SCRIPT_EGYPTIAN_HIEROGLYPHS,
    HB_SCRIPT_SAMARITAN,
    HB_SCRIPT_LISU,
    HB_SCRIPT_BAMUM,
    HB_SCRIPT_JAVANESE,
    HB_SCRIPT_MEETEI_MAYEK,
    HB_SCRIPT_IMPERIAL_ARAMAIC,
    HB_SCRIPT_OLD_SOUTH_ARABIAN,
    HB_SCRIPT_INSCRIPTIONAL_PARTHIAN,
    HB_SCRIPT_INSCRIPTIONAL_PAHLAVI,
    HB_SCRIPT_OLD_TURKIC,
    HB_SCRIPT_KAITHI,
    HB_SCRIPT_BATAK,
    HB_SCRIPT_BRAHMI,
    HB_SCRIPT_MANDAIC,
    HB_SCRIPT_CHAKMA,
    HB_SCRIPT_MEROITIC_CURSIVE,
    HB_SCRIPT_MEROITIC_HIEROGLYPHS,
    HB_SCRIPT_MIAO,
    HB_SCRIPT_SHARADA,
    HB_SCRIPT_SORA_SOMPENG,
    HB_SCRIPT_TAKRI,
    HB_SCRIPT_UNKNOWN,
    HB_SCRIPT_BASSA_VAH,
    HB_SCRIPT_CAUCASIAN_ALBANIAN,
    HB_SCRIPT_DUPLOYAN,
    HB_SCRIPT_ELBASAN,
    HB_SCRIPT_GRANTHA,
    HB_SCRIPT_KHOJKI,
    HB_SCRIPT_KHUDAWADI,
    HB_SCRIPT_LINEAR_A,
    HB_SCRIPT_MAHAJANI,
    HB_SCRIPT_MANICHAEAN,
    HB_SCRIPT_MENDE_KIKAKUI,
    HB_SCRIPT_MODI,
    HB_SCRIPT_MRO,
    HB_SCRIPT_NABATAEAN,
    HB_SCRIPT_OLD_NORTH_ARABIAN,
    HB_SCRIPT_OLD_PERMIC,
    HB_SCRIPT_PAHAWH_HMONG,
    HB_SCRIPT_PALMYRENE,
    HB_SCRIPT_PAU_CIN_HAU,
    HB_SCRIPT_PSALTER_PAHLAVI,
    HB_SCRIPT_SIDDHAM,
    HB_SCRIPT_TIRHUTA,
    HB_SCRIPT_WARANG_CITI,
};

static hb_unicode_combining_class_t
hb_ucdn_combining_class(hb_unicode_funcs_t *ufuncs, hb_codepoint_t unicode,
			void *user_data HB_UNUSED)
{
    return (hb_unicode_combining_class_t) ucdn_get_combining_class(unicode);
}

static unsigned int
hb_ucdn_eastasian_width(hb_unicode_funcs_t *ufuncs, hb_codepoint_t unicode,
			void *user_data HB_UNUSED)
{
    int w = ucdn_get_east_asian_width(unicode);
    return (w == UCDN_EAST_ASIAN_F || w == UCDN_EAST_ASIAN_W) ? 2 : 1;
}

static hb_unicode_general_category_t
hb_ucdn_general_category(hb_unicode_funcs_t *ufuncs, hb_codepoint_t unicode,
			 void *user_data HB_UNUSED)
{
    return (hb_unicode_general_category_t)ucdn_get_general_category(unicode);
}

static hb_codepoint_t
hb_ucdn_mirroring(hb_unicode_funcs_t *ufuncs, hb_codepoint_t unicode,
		  void *user_data HB_UNUSED)
{
    return ucdn_mirror(unicode);
}

static hb_script_t
hb_ucdn_script(hb_unicode_funcs_t *ufuncs, hb_codepoint_t unicode,
	       void *user_data HB_UNUSED)
{
    return ucdn_script_translate[ucdn_get_script(unicode)];
}

static hb_bool_t
hb_ucdn_compose(hb_unicode_funcs_t *ufuncs,
		hb_codepoint_t a, hb_codepoint_t b, hb_codepoint_t *ab,
		void *user_data HB_UNUSED)
{
    return ucdn_compose(ab, a, b);
}

static hb_bool_t
hb_ucdn_decompose(hb_unicode_funcs_t *ufuncs,
		  hb_codepoint_t ab, hb_codepoint_t *a, hb_codepoint_t *b,
		  void *user_data HB_UNUSED)
{
    return ucdn_decompose(ab, a, b);
}

static unsigned int
hb_ucdn_decompose_compatibility(hb_unicode_funcs_t *ufuncs,
				hb_codepoint_t u, hb_codepoint_t *decomposed,
				void *user_data HB_UNUSED)
{
    return ucdn_compat_decompose(u, decomposed);
}

extern "C" HB_INTERNAL
hb_unicode_funcs_t *
hb_ucdn_get_unicode_funcs (void)
{
  static const hb_unicode_funcs_t _hb_ucdn_unicode_funcs = {
    HB_OBJECT_HEADER_STATIC,

    NULL, /* parent */
    true, /* immutable */
    {
#define HB_UNICODE_FUNC_IMPLEMENT(name) hb_ucdn_##name,
      HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS
#undef HB_UNICODE_FUNC_IMPLEMENT
    }
  };

  return const_cast<hb_unicode_funcs_t *> (&_hb_ucdn_unicode_funcs);
}

