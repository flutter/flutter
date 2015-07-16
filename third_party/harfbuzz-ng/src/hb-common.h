/*
 * Copyright © 2007,2008,2009  Red Hat, Inc.
 * Copyright © 2011,2012  Google, Inc.
 *
 *  This is part of HarfBuzz, a text shaping library.
 *
 * Permission is hereby granted, without written agreement and without
 * license or royalty fees, to use, copy, modify, and distribute this
 * software and its documentation for any purpose, provided that the
 * above copyright notice and the following two paragraphs appear in
 * all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF THE COPYRIGHT HOLDER HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * THE COPYRIGHT HOLDER SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDER HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Red Hat Author(s): Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_H_IN
#error "Include <hb.h> instead."
#endif

#ifndef HB_COMMON_H
#define HB_COMMON_H

#ifndef HB_BEGIN_DECLS
# ifdef __cplusplus
#  define HB_BEGIN_DECLS	extern "C" {
#  define HB_END_DECLS		}
# else /* !__cplusplus */
#  define HB_BEGIN_DECLS
#  define HB_END_DECLS
# endif /* !__cplusplus */
#endif

#if !defined (HB_DONT_DEFINE_STDINT)

#if defined (_SVR4) || defined (SVR4) || defined (__OpenBSD__) || \
    defined (_sgi) || defined (__sun) || defined (sun) || \
    defined (__digital__) || defined (__HP_cc)
#  include <inttypes.h>
#elif defined (_AIX)
#  include <sys/inttypes.h>
/* VS 2010 (_MSC_VER 1600) has stdint.h */
#elif defined (_MSC_VER) && _MSC_VER < 1600
typedef __int8 int8_t;
typedef unsigned __int8 uint8_t;
typedef __int16 int16_t;
typedef unsigned __int16 uint16_t;
typedef __int32 int32_t;
typedef unsigned __int32 uint32_t;
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#else
#  include <stdint.h>
#endif

#endif

HB_BEGIN_DECLS


typedef int hb_bool_t;

typedef uint32_t hb_codepoint_t;
typedef int32_t hb_position_t;
typedef uint32_t hb_mask_t;

typedef union _hb_var_int_t {
  uint32_t u32;
  int32_t i32;
  uint16_t u16[2];
  int16_t i16[2];
  uint8_t u8[4];
  int8_t i8[4];
} hb_var_int_t;


/* hb_tag_t */

typedef uint32_t hb_tag_t;

#define HB_TAG(c1,c2,c3,c4) ((hb_tag_t)((((uint8_t)(c1))<<24)|(((uint8_t)(c2))<<16)|(((uint8_t)(c3))<<8)|((uint8_t)(c4))))
#define HB_UNTAG(tag)   ((uint8_t)((tag)>>24)), ((uint8_t)((tag)>>16)), ((uint8_t)((tag)>>8)), ((uint8_t)(tag))

#define HB_TAG_NONE HB_TAG(0,0,0,0)
#define HB_TAG_MAX HB_TAG(0xff,0xff,0xff,0xff)
#define HB_TAG_MAX_SIGNED HB_TAG(0x7f,0xff,0xff,0xff)

/* len=-1 means str is NUL-terminated. */
hb_tag_t
hb_tag_from_string (const char *str, int len);

/* buf should have 4 bytes. */
void
hb_tag_to_string (hb_tag_t tag, char *buf);


/* hb_direction_t */

typedef enum {
  HB_DIRECTION_INVALID = 0,
  HB_DIRECTION_LTR = 4,
  HB_DIRECTION_RTL,
  HB_DIRECTION_TTB,
  HB_DIRECTION_BTT
} hb_direction_t;

/* len=-1 means str is NUL-terminated */
hb_direction_t
hb_direction_from_string (const char *str, int len);

const char *
hb_direction_to_string (hb_direction_t direction);

#define HB_DIRECTION_IS_VALID(dir)	((((unsigned int) (dir)) & ~3U) == 4)
/* Direction must be valid for the following */
#define HB_DIRECTION_IS_HORIZONTAL(dir)	((((unsigned int) (dir)) & ~1U) == 4)
#define HB_DIRECTION_IS_VERTICAL(dir)	((((unsigned int) (dir)) & ~1U) == 6)
#define HB_DIRECTION_IS_FORWARD(dir)	((((unsigned int) (dir)) & ~2U) == 4)
#define HB_DIRECTION_IS_BACKWARD(dir)	((((unsigned int) (dir)) & ~2U) == 5)
#define HB_DIRECTION_REVERSE(dir)	((hb_direction_t) (((unsigned int) (dir)) ^ 1))


/* hb_language_t */

typedef const struct hb_language_impl_t *hb_language_t;

/* len=-1 means str is NUL-terminated */
hb_language_t
hb_language_from_string (const char *str, int len);

const char *
hb_language_to_string (hb_language_t language);

#define HB_LANGUAGE_INVALID ((hb_language_t) NULL)

hb_language_t
hb_language_get_default (void);


/* hb_script_t */

/* http://unicode.org/iso15924/ */
/* http://goo.gl/x9ilM */
/* Unicode Character Database property: Script (sc) */
typedef enum
{
  /*1.1*/ HB_SCRIPT_COMMON			= HB_TAG ('Z','y','y','y'),
  /*1.1*/ HB_SCRIPT_INHERITED			= HB_TAG ('Z','i','n','h'),
  /*5.0*/ HB_SCRIPT_UNKNOWN			= HB_TAG ('Z','z','z','z'),

  /*1.1*/ HB_SCRIPT_ARABIC			= HB_TAG ('A','r','a','b'),
  /*1.1*/ HB_SCRIPT_ARMENIAN			= HB_TAG ('A','r','m','n'),
  /*1.1*/ HB_SCRIPT_BENGALI			= HB_TAG ('B','e','n','g'),
  /*1.1*/ HB_SCRIPT_CYRILLIC			= HB_TAG ('C','y','r','l'),
  /*1.1*/ HB_SCRIPT_DEVANAGARI			= HB_TAG ('D','e','v','a'),
  /*1.1*/ HB_SCRIPT_GEORGIAN			= HB_TAG ('G','e','o','r'),
  /*1.1*/ HB_SCRIPT_GREEK			= HB_TAG ('G','r','e','k'),
  /*1.1*/ HB_SCRIPT_GUJARATI			= HB_TAG ('G','u','j','r'),
  /*1.1*/ HB_SCRIPT_GURMUKHI			= HB_TAG ('G','u','r','u'),
  /*1.1*/ HB_SCRIPT_HANGUL			= HB_TAG ('H','a','n','g'),
  /*1.1*/ HB_SCRIPT_HAN				= HB_TAG ('H','a','n','i'),
  /*1.1*/ HB_SCRIPT_HEBREW			= HB_TAG ('H','e','b','r'),
  /*1.1*/ HB_SCRIPT_HIRAGANA			= HB_TAG ('H','i','r','a'),
  /*1.1*/ HB_SCRIPT_KANNADA			= HB_TAG ('K','n','d','a'),
  /*1.1*/ HB_SCRIPT_KATAKANA			= HB_TAG ('K','a','n','a'),
  /*1.1*/ HB_SCRIPT_LAO				= HB_TAG ('L','a','o','o'),
  /*1.1*/ HB_SCRIPT_LATIN			= HB_TAG ('L','a','t','n'),
  /*1.1*/ HB_SCRIPT_MALAYALAM			= HB_TAG ('M','l','y','m'),
  /*1.1*/ HB_SCRIPT_ORIYA			= HB_TAG ('O','r','y','a'),
  /*1.1*/ HB_SCRIPT_TAMIL			= HB_TAG ('T','a','m','l'),
  /*1.1*/ HB_SCRIPT_TELUGU			= HB_TAG ('T','e','l','u'),
  /*1.1*/ HB_SCRIPT_THAI			= HB_TAG ('T','h','a','i'),

  /*2.0*/ HB_SCRIPT_TIBETAN			= HB_TAG ('T','i','b','t'),

  /*3.0*/ HB_SCRIPT_BOPOMOFO			= HB_TAG ('B','o','p','o'),
  /*3.0*/ HB_SCRIPT_BRAILLE			= HB_TAG ('B','r','a','i'),
  /*3.0*/ HB_SCRIPT_CANADIAN_SYLLABICS		= HB_TAG ('C','a','n','s'),
  /*3.0*/ HB_SCRIPT_CHEROKEE			= HB_TAG ('C','h','e','r'),
  /*3.0*/ HB_SCRIPT_ETHIOPIC			= HB_TAG ('E','t','h','i'),
  /*3.0*/ HB_SCRIPT_KHMER			= HB_TAG ('K','h','m','r'),
  /*3.0*/ HB_SCRIPT_MONGOLIAN			= HB_TAG ('M','o','n','g'),
  /*3.0*/ HB_SCRIPT_MYANMAR			= HB_TAG ('M','y','m','r'),
  /*3.0*/ HB_SCRIPT_OGHAM			= HB_TAG ('O','g','a','m'),
  /*3.0*/ HB_SCRIPT_RUNIC			= HB_TAG ('R','u','n','r'),
  /*3.0*/ HB_SCRIPT_SINHALA			= HB_TAG ('S','i','n','h'),
  /*3.0*/ HB_SCRIPT_SYRIAC			= HB_TAG ('S','y','r','c'),
  /*3.0*/ HB_SCRIPT_THAANA			= HB_TAG ('T','h','a','a'),
  /*3.0*/ HB_SCRIPT_YI				= HB_TAG ('Y','i','i','i'),

  /*3.1*/ HB_SCRIPT_DESERET			= HB_TAG ('D','s','r','t'),
  /*3.1*/ HB_SCRIPT_GOTHIC			= HB_TAG ('G','o','t','h'),
  /*3.1*/ HB_SCRIPT_OLD_ITALIC			= HB_TAG ('I','t','a','l'),

  /*3.2*/ HB_SCRIPT_BUHID			= HB_TAG ('B','u','h','d'),
  /*3.2*/ HB_SCRIPT_HANUNOO			= HB_TAG ('H','a','n','o'),
  /*3.2*/ HB_SCRIPT_TAGALOG			= HB_TAG ('T','g','l','g'),
  /*3.2*/ HB_SCRIPT_TAGBANWA			= HB_TAG ('T','a','g','b'),

  /*4.0*/ HB_SCRIPT_CYPRIOT			= HB_TAG ('C','p','r','t'),
  /*4.0*/ HB_SCRIPT_LIMBU			= HB_TAG ('L','i','m','b'),
  /*4.0*/ HB_SCRIPT_LINEAR_B			= HB_TAG ('L','i','n','b'),
  /*4.0*/ HB_SCRIPT_OSMANYA			= HB_TAG ('O','s','m','a'),
  /*4.0*/ HB_SCRIPT_SHAVIAN			= HB_TAG ('S','h','a','w'),
  /*4.0*/ HB_SCRIPT_TAI_LE			= HB_TAG ('T','a','l','e'),
  /*4.0*/ HB_SCRIPT_UGARITIC			= HB_TAG ('U','g','a','r'),

  /*4.1*/ HB_SCRIPT_BUGINESE			= HB_TAG ('B','u','g','i'),
  /*4.1*/ HB_SCRIPT_COPTIC			= HB_TAG ('C','o','p','t'),
  /*4.1*/ HB_SCRIPT_GLAGOLITIC			= HB_TAG ('G','l','a','g'),
  /*4.1*/ HB_SCRIPT_KHAROSHTHI			= HB_TAG ('K','h','a','r'),
  /*4.1*/ HB_SCRIPT_NEW_TAI_LUE			= HB_TAG ('T','a','l','u'),
  /*4.1*/ HB_SCRIPT_OLD_PERSIAN			= HB_TAG ('X','p','e','o'),
  /*4.1*/ HB_SCRIPT_SYLOTI_NAGRI		= HB_TAG ('S','y','l','o'),
  /*4.1*/ HB_SCRIPT_TIFINAGH			= HB_TAG ('T','f','n','g'),

  /*5.0*/ HB_SCRIPT_BALINESE			= HB_TAG ('B','a','l','i'),
  /*5.0*/ HB_SCRIPT_CUNEIFORM			= HB_TAG ('X','s','u','x'),
  /*5.0*/ HB_SCRIPT_NKO				= HB_TAG ('N','k','o','o'),
  /*5.0*/ HB_SCRIPT_PHAGS_PA			= HB_TAG ('P','h','a','g'),
  /*5.0*/ HB_SCRIPT_PHOENICIAN			= HB_TAG ('P','h','n','x'),

  /*5.1*/ HB_SCRIPT_CARIAN			= HB_TAG ('C','a','r','i'),
  /*5.1*/ HB_SCRIPT_CHAM			= HB_TAG ('C','h','a','m'),
  /*5.1*/ HB_SCRIPT_KAYAH_LI			= HB_TAG ('K','a','l','i'),
  /*5.1*/ HB_SCRIPT_LEPCHA			= HB_TAG ('L','e','p','c'),
  /*5.1*/ HB_SCRIPT_LYCIAN			= HB_TAG ('L','y','c','i'),
  /*5.1*/ HB_SCRIPT_LYDIAN			= HB_TAG ('L','y','d','i'),
  /*5.1*/ HB_SCRIPT_OL_CHIKI			= HB_TAG ('O','l','c','k'),
  /*5.1*/ HB_SCRIPT_REJANG			= HB_TAG ('R','j','n','g'),
  /*5.1*/ HB_SCRIPT_SAURASHTRA			= HB_TAG ('S','a','u','r'),
  /*5.1*/ HB_SCRIPT_SUNDANESE			= HB_TAG ('S','u','n','d'),
  /*5.1*/ HB_SCRIPT_VAI				= HB_TAG ('V','a','i','i'),

  /*5.2*/ HB_SCRIPT_AVESTAN			= HB_TAG ('A','v','s','t'),
  /*5.2*/ HB_SCRIPT_BAMUM			= HB_TAG ('B','a','m','u'),
  /*5.2*/ HB_SCRIPT_EGYPTIAN_HIEROGLYPHS	= HB_TAG ('E','g','y','p'),
  /*5.2*/ HB_SCRIPT_IMPERIAL_ARAMAIC		= HB_TAG ('A','r','m','i'),
  /*5.2*/ HB_SCRIPT_INSCRIPTIONAL_PAHLAVI	= HB_TAG ('P','h','l','i'),
  /*5.2*/ HB_SCRIPT_INSCRIPTIONAL_PARTHIAN	= HB_TAG ('P','r','t','i'),
  /*5.2*/ HB_SCRIPT_JAVANESE			= HB_TAG ('J','a','v','a'),
  /*5.2*/ HB_SCRIPT_KAITHI			= HB_TAG ('K','t','h','i'),
  /*5.2*/ HB_SCRIPT_LISU			= HB_TAG ('L','i','s','u'),
  /*5.2*/ HB_SCRIPT_MEETEI_MAYEK		= HB_TAG ('M','t','e','i'),
  /*5.2*/ HB_SCRIPT_OLD_SOUTH_ARABIAN		= HB_TAG ('S','a','r','b'),
  /*5.2*/ HB_SCRIPT_OLD_TURKIC			= HB_TAG ('O','r','k','h'),
  /*5.2*/ HB_SCRIPT_SAMARITAN			= HB_TAG ('S','a','m','r'),
  /*5.2*/ HB_SCRIPT_TAI_THAM			= HB_TAG ('L','a','n','a'),
  /*5.2*/ HB_SCRIPT_TAI_VIET			= HB_TAG ('T','a','v','t'),

  /*6.0*/ HB_SCRIPT_BATAK			= HB_TAG ('B','a','t','k'),
  /*6.0*/ HB_SCRIPT_BRAHMI			= HB_TAG ('B','r','a','h'),
  /*6.0*/ HB_SCRIPT_MANDAIC			= HB_TAG ('M','a','n','d'),

  /*6.1*/ HB_SCRIPT_CHAKMA			= HB_TAG ('C','a','k','m'),
  /*6.1*/ HB_SCRIPT_MEROITIC_CURSIVE		= HB_TAG ('M','e','r','c'),
  /*6.1*/ HB_SCRIPT_MEROITIC_HIEROGLYPHS	= HB_TAG ('M','e','r','o'),
  /*6.1*/ HB_SCRIPT_MIAO			= HB_TAG ('P','l','r','d'),
  /*6.1*/ HB_SCRIPT_SHARADA			= HB_TAG ('S','h','r','d'),
  /*6.1*/ HB_SCRIPT_SORA_SOMPENG		= HB_TAG ('S','o','r','a'),
  /*6.1*/ HB_SCRIPT_TAKRI			= HB_TAG ('T','a','k','r'),

  /*7.0*/ HB_SCRIPT_BASSA_VAH			= HB_TAG ('B','a','s','s'),
  /*7.0*/ HB_SCRIPT_CAUCASIAN_ALBANIAN		= HB_TAG ('A','g','h','b'),
  /*7.0*/ HB_SCRIPT_DUPLOYAN			= HB_TAG ('D','u','p','l'),
  /*7.0*/ HB_SCRIPT_ELBASAN			= HB_TAG ('E','l','b','a'),
  /*7.0*/ HB_SCRIPT_GRANTHA			= HB_TAG ('G','r','a','n'),
  /*7.0*/ HB_SCRIPT_KHOJKI			= HB_TAG ('K','h','o','j'),
  /*7.0*/ HB_SCRIPT_KHUDAWADI			= HB_TAG ('S','i','n','d'),
  /*7.0*/ HB_SCRIPT_LINEAR_A			= HB_TAG ('L','i','n','a'),
  /*7.0*/ HB_SCRIPT_MAHAJANI			= HB_TAG ('M','a','h','j'),
  /*7.0*/ HB_SCRIPT_MANICHAEAN			= HB_TAG ('M','a','n','i'),
  /*7.0*/ HB_SCRIPT_MENDE_KIKAKUI		= HB_TAG ('M','e','n','d'),
  /*7.0*/ HB_SCRIPT_MODI			= HB_TAG ('M','o','d','i'),
  /*7.0*/ HB_SCRIPT_MRO				= HB_TAG ('M','r','o','o'),
  /*7.0*/ HB_SCRIPT_NABATAEAN			= HB_TAG ('N','b','a','t'),
  /*7.0*/ HB_SCRIPT_OLD_NORTH_ARABIAN		= HB_TAG ('N','a','r','b'),
  /*7.0*/ HB_SCRIPT_OLD_PERMIC			= HB_TAG ('P','e','r','m'),
  /*7.0*/ HB_SCRIPT_PAHAWH_HMONG		= HB_TAG ('H','m','n','g'),
  /*7.0*/ HB_SCRIPT_PALMYRENE			= HB_TAG ('P','a','l','m'),
  /*7.0*/ HB_SCRIPT_PAU_CIN_HAU			= HB_TAG ('P','a','u','c'),
  /*7.0*/ HB_SCRIPT_PSALTER_PAHLAVI		= HB_TAG ('P','h','l','p'),
  /*7.0*/ HB_SCRIPT_SIDDHAM			= HB_TAG ('S','i','d','d'),
  /*7.0*/ HB_SCRIPT_TIRHUTA			= HB_TAG ('T','i','r','h'),
  /*7.0*/ HB_SCRIPT_WARANG_CITI			= HB_TAG ('W','a','r','a'),

  /* No script set. */
  HB_SCRIPT_INVALID				= HB_TAG_NONE,

  /* Dummy values to ensure any hb_tag_t value can be passed/stored as hb_script_t
   * without risking undefined behavior.  Include both a signed and unsigned max,
   * since technically enums are int, and indeed, hb_script_t ends up being signed.
   * See this thread for technicalities:
   *
   *   http://lists.freedesktop.org/archives/harfbuzz/2014-March/004150.html
   */
  _HB_SCRIPT_MAX_VALUE				= HB_TAG_MAX, /*< skip >*/
  _HB_SCRIPT_MAX_VALUE_SIGNED			= HB_TAG_MAX_SIGNED /*< skip >*/

} hb_script_t;


/* Script functions */

hb_script_t
hb_script_from_iso15924_tag (hb_tag_t tag);

/* sugar for tag_from_string() then script_from_iso15924_tag */
/* len=-1 means s is NUL-terminated */
hb_script_t
hb_script_from_string (const char *s, int len);

hb_tag_t
hb_script_to_iso15924_tag (hb_script_t script);

hb_direction_t
hb_script_get_horizontal_direction (hb_script_t script);


/* User data */

typedef struct hb_user_data_key_t {
  /*< private >*/
  char unused;
} hb_user_data_key_t;

typedef void (*hb_destroy_func_t) (void *user_data);


HB_END_DECLS

#endif /* HB_COMMON_H */
