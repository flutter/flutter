/*
 * Copyright © 2009  Red Hat, Inc.
 * Copyright © 2011  Codethink Limited
 * Copyright © 2010,2011,2012  Google, Inc.
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
 * Codethink Author(s): Ryan Lortie
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_UNICODE_PRIVATE_HH
#define HB_UNICODE_PRIVATE_HH

#include "hb-private.hh"
#include "hb-object-private.hh"


extern HB_INTERNAL const uint8_t _hb_modified_combining_class[256];

/*
 * hb_unicode_funcs_t
 */

#define HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS \
  HB_UNICODE_FUNC_IMPLEMENT (combining_class) \
  HB_UNICODE_FUNC_IMPLEMENT (eastasian_width) \
  HB_UNICODE_FUNC_IMPLEMENT (general_category) \
  HB_UNICODE_FUNC_IMPLEMENT (mirroring) \
  HB_UNICODE_FUNC_IMPLEMENT (script) \
  HB_UNICODE_FUNC_IMPLEMENT (compose) \
  HB_UNICODE_FUNC_IMPLEMENT (decompose) \
  HB_UNICODE_FUNC_IMPLEMENT (decompose_compatibility) \
  /* ^--- Add new callbacks here */

/* Simple callbacks are those taking a hb_codepoint_t and returning a hb_codepoint_t */
#define HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS_SIMPLE \
  HB_UNICODE_FUNC_IMPLEMENT (hb_unicode_combining_class_t, combining_class) \
  HB_UNICODE_FUNC_IMPLEMENT (unsigned int, eastasian_width) \
  HB_UNICODE_FUNC_IMPLEMENT (hb_unicode_general_category_t, general_category) \
  HB_UNICODE_FUNC_IMPLEMENT (hb_codepoint_t, mirroring) \
  HB_UNICODE_FUNC_IMPLEMENT (hb_script_t, script) \
  /* ^--- Add new simple callbacks here */

struct hb_unicode_funcs_t {
  hb_object_header_t header;
  ASSERT_POD ();

  hb_unicode_funcs_t *parent;

  bool immutable;

#define HB_UNICODE_FUNC_IMPLEMENT(return_type, name) \
  inline return_type name (hb_codepoint_t unicode) { return func.name (this, unicode, user_data.name); }
HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS_SIMPLE
#undef HB_UNICODE_FUNC_IMPLEMENT

  inline hb_bool_t compose (hb_codepoint_t a, hb_codepoint_t b,
			    hb_codepoint_t *ab)
  {
    *ab = 0;
    if (unlikely (!a || !b)) return false;
    return func.compose (this, a, b, ab, user_data.compose);
  }

  inline hb_bool_t decompose (hb_codepoint_t ab,
			      hb_codepoint_t *a, hb_codepoint_t *b)
  {
    *a = ab; *b = 0;
    return func.decompose (this, ab, a, b, user_data.decompose);
  }

  inline unsigned int decompose_compatibility (hb_codepoint_t  u,
					       hb_codepoint_t *decomposed)
  {
    unsigned int ret = func.decompose_compatibility (this, u, decomposed, user_data.decompose_compatibility);
    if (ret == 1 && u == decomposed[0]) {
      decomposed[0] = 0;
      return 0;
    }
    decomposed[ret] = 0;
    return ret;
  }


  inline unsigned int
  modified_combining_class (hb_codepoint_t unicode)
  {
    /* XXX This hack belongs to the Myanmar shaper. */
    if (unlikely (unicode == 0x1037u)) unicode = 0x103Au;

    /* XXX This hack belongs to the SEA shaper (for Tai Tham):
     * Reorder SAKOT to ensure it comes after any tone marks. */
    if (unlikely (unicode == 0x1A60u)) return 254;

    /* XXX This hack belongs to the Tibetan shaper:
     * Reorder PADMA to ensure it comes after any vowel marks. */
    if (unlikely (unicode == 0x0FC6u)) return 254;

    return _hb_modified_combining_class[combining_class (unicode)];
  }

  static inline hb_bool_t
  is_variation_selector (hb_codepoint_t unicode)
  {
    /* U+180B..180D MONGOLIAN FREE VARIATION SELECTORs are handled in the
     * Arabic shaper.  No need to match them here. */
    return unlikely (hb_in_ranges (unicode,
				   0xFE00u, 0xFE0Fu, /* VARIATION SELECTOR-1..16 */
				   0xE0100u, 0xE01EFu));  /* VARIATION SELECTOR-17..256 */
  }

  /* Default_Ignorable codepoints:
   *
   * Note: While U+115F, U+1160, U+3164 and U+FFA0 are Default_Ignorable,
   * we do NOT want to hide them, as the way Uniscribe has implemented them
   * is with regular spacing glyphs, and that's the way fonts are made to work.
   * As such, we make exceptions for those four.
   *
   * Unicode 7.0:
   * $ grep '; Default_Ignorable_Code_Point ' DerivedCoreProperties.txt | sed 's/;.*#/#/'
   * 00AD          # Cf       SOFT HYPHEN
   * 034F          # Mn       COMBINING GRAPHEME JOINER
   * 061C          # Cf       ARABIC LETTER MARK
   * 115F..1160    # Lo   [2] HANGUL CHOSEONG FILLER..HANGUL JUNGSEONG FILLER
   * 17B4..17B5    # Mn   [2] KHMER VOWEL INHERENT AQ..KHMER VOWEL INHERENT AA
   * 180B..180D    # Mn   [3] MONGOLIAN FREE VARIATION SELECTOR ONE..MONGOLIAN FREE VARIATION SELECTOR THREE
   * 180E          # Cf       MONGOLIAN VOWEL SEPARATOR
   * 200B..200F    # Cf   [5] ZERO WIDTH SPACE..RIGHT-TO-LEFT MARK
   * 202A..202E    # Cf   [5] LEFT-TO-RIGHT EMBEDDING..RIGHT-TO-LEFT OVERRIDE
   * 2060..2064    # Cf   [5] WORD JOINER..INVISIBLE PLUS
   * 2065          # Cn       <reserved-2065>
   * 2066..206F    # Cf  [10] LEFT-TO-RIGHT ISOLATE..NOMINAL DIGIT SHAPES
   * 3164          # Lo       HANGUL FILLER
   * FE00..FE0F    # Mn  [16] VARIATION SELECTOR-1..VARIATION SELECTOR-16
   * FEFF          # Cf       ZERO WIDTH NO-BREAK SPACE
   * FFA0          # Lo       HALFWIDTH HANGUL FILLER
   * FFF0..FFF8    # Cn   [9] <reserved-FFF0>..<reserved-FFF8>
   * 1BCA0..1BCA3  # Cf   [4] SHORTHAND FORMAT LETTER OVERLAP..SHORTHAND FORMAT UP STEP
   * 1D173..1D17A  # Cf   [8] MUSICAL SYMBOL BEGIN BEAM..MUSICAL SYMBOL END PHRASE
   * E0000         # Cn       <reserved-E0000>
   * E0001         # Cf       LANGUAGE TAG
   * E0002..E001F  # Cn  [30] <reserved-E0002>..<reserved-E001F>
   * E0020..E007F  # Cf  [96] TAG SPACE..CANCEL TAG
   * E0080..E00FF  # Cn [128] <reserved-E0080>..<reserved-E00FF>
   * E0100..E01EF  # Mn [240] VARIATION SELECTOR-17..VARIATION SELECTOR-256
   * E01F0..E0FFF  # Cn [3600] <reserved-E01F0>..<reserved-E0FFF>
   */
  static inline hb_bool_t
  is_default_ignorable (hb_codepoint_t ch)
  {
    hb_codepoint_t plane = ch >> 16;
    if (likely (plane == 0))
    {
      /* BMP */
      hb_codepoint_t page = ch >> 8;
      switch (page) {
	case 0x00: return unlikely (ch == 0x00ADu);
	case 0x03: return unlikely (ch == 0x034Fu);
	case 0x06: return unlikely (ch == 0x061Cu);
	case 0x17: return hb_in_range (ch, 0x17B4u, 0x17B5u);
	case 0x18: return hb_in_range (ch, 0x180Bu, 0x180Eu);
	case 0x20: return hb_in_ranges (ch, 0x200Bu, 0x200Fu,
							    0x202Au, 0x202Eu,
							    0x2060u, 0x206Fu);
	case 0xFE: return hb_in_range (ch, 0xFE00u, 0xFE0Fu) || ch == 0xFEFFu;
	case 0xFF: return hb_in_range (ch, 0xFFF0u, 0xFFF8u);
	default: return false;
      }
    }
    else
    {
      /* Other planes */
      switch (plane) {
	case 0x01: return hb_in_ranges (ch, 0x1BCA0u, 0x1BCA3u,
					    0x1D173u, 0x1D17Au);
	case 0x0E: return hb_in_range (ch, 0xE0000u, 0xE0FFFu);
	default: return false;
      }
    }
  }


  struct {
#define HB_UNICODE_FUNC_IMPLEMENT(name) hb_unicode_##name##_func_t name;
    HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS
#undef HB_UNICODE_FUNC_IMPLEMENT
  } func;

  struct {
#define HB_UNICODE_FUNC_IMPLEMENT(name) void *name;
    HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS
#undef HB_UNICODE_FUNC_IMPLEMENT
  } user_data;

  struct {
#define HB_UNICODE_FUNC_IMPLEMENT(name) hb_destroy_func_t name;
    HB_UNICODE_FUNCS_IMPLEMENT_CALLBACKS
#undef HB_UNICODE_FUNC_IMPLEMENT
  } destroy;
};


extern HB_INTERNAL const hb_unicode_funcs_t _hb_unicode_funcs_nil;


/* Modified combining marks */

/* Hebrew
 *
 * We permute the "fixed-position" classes 10-26 into the order
 * described in the SBL Hebrew manual:
 *
 * http://www.sbl-site.org/Fonts/SBLHebrewUserManual1.5x.pdf
 *
 * (as recommended by:
 *  http://forum.fontlab.com/archive-old-microsoft-volt-group/vista-and-diacritic-ordering-t6751.0.html)
 *
 * More details here:
 * https://bugzilla.mozilla.org/show_bug.cgi?id=662055
 */
#define HB_MODIFIED_COMBINING_CLASS_CCC10 22 /* sheva */
#define HB_MODIFIED_COMBINING_CLASS_CCC11 15 /* hataf segol */
#define HB_MODIFIED_COMBINING_CLASS_CCC12 16 /* hataf patah */
#define HB_MODIFIED_COMBINING_CLASS_CCC13 17 /* hataf qamats */
#define HB_MODIFIED_COMBINING_CLASS_CCC14 23 /* hiriq */
#define HB_MODIFIED_COMBINING_CLASS_CCC15 18 /* tsere */
#define HB_MODIFIED_COMBINING_CLASS_CCC16 19 /* segol */
#define HB_MODIFIED_COMBINING_CLASS_CCC17 20 /* patah */
#define HB_MODIFIED_COMBINING_CLASS_CCC18 21 /* qamats */
#define HB_MODIFIED_COMBINING_CLASS_CCC19 14 /* holam */
#define HB_MODIFIED_COMBINING_CLASS_CCC20 24 /* qubuts */
#define HB_MODIFIED_COMBINING_CLASS_CCC21 12 /* dagesh */
#define HB_MODIFIED_COMBINING_CLASS_CCC22 25 /* meteg */
#define HB_MODIFIED_COMBINING_CLASS_CCC23 13 /* rafe */
#define HB_MODIFIED_COMBINING_CLASS_CCC24 10 /* shin dot */
#define HB_MODIFIED_COMBINING_CLASS_CCC25 11 /* sin dot */
#define HB_MODIFIED_COMBINING_CLASS_CCC26 26 /* point varika */

/*
 * Arabic
 *
 * Modify to move Shadda (ccc=33) before other marks.  See:
 * http://unicode.org/faq/normalization.html#8
 * http://unicode.org/faq/normalization.html#9
 */
#define HB_MODIFIED_COMBINING_CLASS_CCC27 28 /* fathatan */
#define HB_MODIFIED_COMBINING_CLASS_CCC28 29 /* dammatan */
#define HB_MODIFIED_COMBINING_CLASS_CCC29 30 /* kasratan */
#define HB_MODIFIED_COMBINING_CLASS_CCC30 31 /* fatha */
#define HB_MODIFIED_COMBINING_CLASS_CCC31 32 /* damma */
#define HB_MODIFIED_COMBINING_CLASS_CCC32 33 /* kasra */
#define HB_MODIFIED_COMBINING_CLASS_CCC33 27 /* shadda */
#define HB_MODIFIED_COMBINING_CLASS_CCC34 34 /* sukun */
#define HB_MODIFIED_COMBINING_CLASS_CCC35 35 /* superscript alef */

/* Syriac */
#define HB_MODIFIED_COMBINING_CLASS_CCC36 36 /* superscript alaph */

/* Telugu
 *
 * Modify Telugu length marks (ccc=84, ccc=91).
 * These are the only matras in the main Indic scripts range that have
 * a non-zero ccc.  That makes them reorder with the Halant that is
 * ccc=9.  Just zero them, we don't need them in our Indic shaper.
 */
#define HB_MODIFIED_COMBINING_CLASS_CCC84 0 /* length mark */
#define HB_MODIFIED_COMBINING_CLASS_CCC91 0 /* ai length mark */

/* Thai
 *
 * Modify U+0E38 and U+0E39 (ccc=103) to be reordered before U+0E3A (ccc=9).
 * Assign 3, which is unassigned otherwise.
 * Uniscribe does this reordering too.
 */
#define HB_MODIFIED_COMBINING_CLASS_CCC103 3 /* sara u / sara uu */
#define HB_MODIFIED_COMBINING_CLASS_CCC107 107 /* mai * */

/* Lao */
#define HB_MODIFIED_COMBINING_CLASS_CCC118 118 /* sign u / sign uu */
#define HB_MODIFIED_COMBINING_CLASS_CCC122 122 /* mai * */

/* Tibetan */
#define HB_MODIFIED_COMBINING_CLASS_CCC129 129 /* sign aa */
#define HB_MODIFIED_COMBINING_CLASS_CCC130 130 /* sign i */
#define HB_MODIFIED_COMBINING_CLASS_CCC132 132 /* sign u */


/* Misc */

#define HB_UNICODE_GENERAL_CATEGORY_IS_MARK(gen_cat) \
	(FLAG (gen_cat) & \
	 (FLAG (HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK) | \
	  FLAG (HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK) | \
	  FLAG (HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK)))


#endif /* HB_UNICODE_PRIVATE_HH */
