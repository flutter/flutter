/*
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
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_OT_SHAPE_COMPLEX_PRIVATE_HH
#define HB_OT_SHAPE_COMPLEX_PRIVATE_HH

#include "hb-private.hh"

#include "hb-ot-shape-private.hh"
#include "hb-ot-shape-normalize-private.hh"



/* buffer var allocations, used by complex shapers */
#define complex_var_u8_0()	var2.u8[2]
#define complex_var_u8_1()	var2.u8[3]


enum hb_ot_shape_zero_width_marks_type_t {
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE,
//  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_EARLY,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_LATE,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_EARLY,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_LATE,

  HB_OT_SHAPE_ZERO_WIDTH_MARKS_DEFAULT = HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_LATE
};


/* Master OT shaper list */
#define HB_COMPLEX_SHAPERS_IMPLEMENT_SHAPERS \
  HB_COMPLEX_SHAPER_IMPLEMENT (default) /* should be first */ \
  HB_COMPLEX_SHAPER_IMPLEMENT (arabic) \
  HB_COMPLEX_SHAPER_IMPLEMENT (hangul) \
  HB_COMPLEX_SHAPER_IMPLEMENT (hebrew) \
  HB_COMPLEX_SHAPER_IMPLEMENT (myanmar_old) \
  HB_COMPLEX_SHAPER_IMPLEMENT (indic) \
  HB_COMPLEX_SHAPER_IMPLEMENT (myanmar) \
  HB_COMPLEX_SHAPER_IMPLEMENT (sea) \
  HB_COMPLEX_SHAPER_IMPLEMENT (thai) \
  HB_COMPLEX_SHAPER_IMPLEMENT (tibetan) \
  /* ^--- Add new shapers here */


struct hb_ot_complex_shaper_t
{
  char name[8];

  /* collect_features()
   * Called during shape_plan().
   * Shapers should use plan->map to add their features and callbacks.
   * May be NULL.
   */
  void (*collect_features) (hb_ot_shape_planner_t *plan);

  /* override_features()
   * Called during shape_plan().
   * Shapers should use plan->map to override features and add callbacks after
   * common features are added.
   * May be NULL.
   */
  void (*override_features) (hb_ot_shape_planner_t *plan);


  /* data_create()
   * Called at the end of shape_plan().
   * Whatever shapers return will be accessible through plan->data later.
   * If NULL is returned, means a plan failure.
   */
  void *(*data_create) (const hb_ot_shape_plan_t *plan);

  /* data_destroy()
   * Called when the shape_plan is being destroyed.
   * plan->data is passed here for destruction.
   * If NULL is returned, means a plan failure.
   * May be NULL.
   */
  void (*data_destroy) (void *data);


  /* preprocess_text()
   * Called during shape().
   * Shapers can use to modify text before shaping starts.
   * May be NULL.
   */
  void (*preprocess_text) (const hb_ot_shape_plan_t *plan,
			   hb_buffer_t              *buffer,
			   hb_font_t                *font);


  hb_ot_shape_normalization_mode_t normalization_preference;

  /* decompose()
   * Called during shape()'s normalization.
   * May be NULL.
   */
  bool (*decompose) (const hb_ot_shape_normalize_context_t *c,
		     hb_codepoint_t  ab,
		     hb_codepoint_t *a,
		     hb_codepoint_t *b);

  /* compose()
   * Called during shape()'s normalization.
   * May be NULL.
   */
  bool (*compose) (const hb_ot_shape_normalize_context_t *c,
		   hb_codepoint_t  a,
		   hb_codepoint_t  b,
		   hb_codepoint_t *ab);

  /* setup_masks()
   * Called during shape().
   * Shapers should use map to get feature masks and set on buffer.
   * Shapers may NOT modify characters.
   * May be NULL.
   */
  void (*setup_masks) (const hb_ot_shape_plan_t *plan,
		       hb_buffer_t              *buffer,
		       hb_font_t                *font);

  hb_ot_shape_zero_width_marks_type_t zero_width_marks;

  bool fallback_position;
};

#define HB_COMPLEX_SHAPER_IMPLEMENT(name) extern HB_INTERNAL const hb_ot_complex_shaper_t _hb_ot_complex_shaper_##name;
HB_COMPLEX_SHAPERS_IMPLEMENT_SHAPERS
#undef HB_COMPLEX_SHAPER_IMPLEMENT


static inline const hb_ot_complex_shaper_t *
hb_ot_shape_complex_categorize (const hb_ot_shape_planner_t *planner)
{
  switch ((hb_tag_t) planner->props.script)
  {
    default:
      return &_hb_ot_complex_shaper_default;


    /* Unicode-1.1 additions */
    case HB_SCRIPT_ARABIC:

    /* Unicode-3.0 additions */
    case HB_SCRIPT_MONGOLIAN:
    case HB_SCRIPT_SYRIAC:

    /* Unicode-5.0 additions */
    case HB_SCRIPT_NKO:
    case HB_SCRIPT_PHAGS_PA:

    /* Unicode-6.0 additions */
    case HB_SCRIPT_MANDAIC:

    /* Unicode-7.0 additions */
    case HB_SCRIPT_MANICHAEAN:
    case HB_SCRIPT_PSALTER_PAHLAVI:

      /* For Arabic script, use the Arabic shaper even if no OT script tag was found.
       * This is because we do fallback shaping for Arabic script (and not others). */
      if (planner->map.chosen_script[0] != HB_OT_TAG_DEFAULT_SCRIPT ||
	  planner->props.script == HB_SCRIPT_ARABIC)
	return &_hb_ot_complex_shaper_arabic;
      else
	return &_hb_ot_complex_shaper_default;


    /* Unicode-1.1 additions */
    case HB_SCRIPT_THAI:
    case HB_SCRIPT_LAO:

      return &_hb_ot_complex_shaper_thai;


    /* Unicode-1.1 additions */
    case HB_SCRIPT_HANGUL:

      return &_hb_ot_complex_shaper_hangul;


    /* Unicode-2.0 additions */
    case HB_SCRIPT_TIBETAN:

      return &_hb_ot_complex_shaper_tibetan;


    /* Unicode-1.1 additions */
    case HB_SCRIPT_HEBREW:

      return &_hb_ot_complex_shaper_hebrew;


    /* ^--- Add new shapers here */


#if 0
    /* Note:
     *
     * These disabled scripts are listed in ucd/IndicSyllabicCategory.txt, but according
     * to Martin Hosken and Jonathan Kew do not require complex shaping.
     *
     * TODO We should automate figuring out which scripts do not need complex shaping
     *
     * TODO We currently keep data for these scripts in our indic table.  Need to fix the
     * generator to not do that.
     */


    /* Simple? */

    /* Unicode-3.2 additions */
    case HB_SCRIPT_BUHID:
    case HB_SCRIPT_HANUNOO:

    /* Unicode-5.1 additions */
    case HB_SCRIPT_SAURASHTRA:

    /* Unicode-6.0 additions */
    case HB_SCRIPT_BATAK:
    case HB_SCRIPT_BRAHMI:


    /* Simple */

    /* Unicode-1.1 additions */
    /* These have their own shaper now. */
    case HB_SCRIPT_LAO:
    case HB_SCRIPT_THAI:

    /* Unicode-3.2 additions */
    case HB_SCRIPT_TAGALOG:
    case HB_SCRIPT_TAGBANWA:

    /* Unicode-4.0 additions */
    case HB_SCRIPT_LIMBU:
    case HB_SCRIPT_TAI_LE:

    /* Unicode-4.1 additions */
    case HB_SCRIPT_KHAROSHTHI:
    case HB_SCRIPT_NEW_TAI_LUE:
    case HB_SCRIPT_SYLOTI_NAGRI:

    /* Unicode-5.1 additions */
    case HB_SCRIPT_KAYAH_LI:

    /* Unicode-5.2 additions */
    case HB_SCRIPT_TAI_VIET:


#endif

    /* Unicode-1.1 additions */
    case HB_SCRIPT_BENGALI:
    case HB_SCRIPT_DEVANAGARI:
    case HB_SCRIPT_GUJARATI:
    case HB_SCRIPT_GURMUKHI:
    case HB_SCRIPT_KANNADA:
    case HB_SCRIPT_MALAYALAM:
    case HB_SCRIPT_ORIYA:
    case HB_SCRIPT_TAMIL:
    case HB_SCRIPT_TELUGU:

    /* Unicode-3.0 additions */
    case HB_SCRIPT_SINHALA:

    /* Unicode-5.0 additions */
    case HB_SCRIPT_BALINESE:

    /* Unicode-5.1 additions */
    case HB_SCRIPT_LEPCHA:
    case HB_SCRIPT_REJANG:
    case HB_SCRIPT_SUNDANESE:

    /* Unicode-5.2 additions */
    case HB_SCRIPT_JAVANESE:
    case HB_SCRIPT_KAITHI:
    case HB_SCRIPT_MEETEI_MAYEK:

    /* Unicode-6.0 additions */

    /* Unicode-6.1 additions */
    case HB_SCRIPT_CHAKMA:
    case HB_SCRIPT_SHARADA:
    case HB_SCRIPT_TAKRI:

      /* If the designer designed the font for the 'DFLT' script,
       * use the default shaper.  Otherwise, use the Indic shaper.
       * Note that for some simple scripts, there may not be *any*
       * GSUB/GPOS needed, so there may be no scripts found! */
      if (planner->map.chosen_script[0] == HB_TAG ('D','F','L','T'))
	return &_hb_ot_complex_shaper_default;
      else
	return &_hb_ot_complex_shaper_indic;

    case HB_SCRIPT_KHMER:
      /* A number of Khmer fonts in the wild don't have a 'pref' feature,
       * and as such won't shape properly via the Indic shaper;
       * however, they typically have 'liga' / 'clig' features that implement
       * the necessary "reordering" by means of ligature substitutions.
       * So we send such pref-less fonts through the generic shaper instead. */
      if (planner->map.found_script[0] &&
	  hb_ot_layout_language_find_feature (planner->face, HB_OT_TAG_GSUB,
					      planner->map.script_index[0],
					      planner->map.language_index[0],
					      HB_TAG ('p','r','e','f'),
					      NULL))
	return &_hb_ot_complex_shaper_indic;
      else
	return &_hb_ot_complex_shaper_default;

    case HB_SCRIPT_MYANMAR:
      if (planner->map.chosen_script[0] == HB_TAG ('m','y','m','2'))
	return &_hb_ot_complex_shaper_myanmar;
      else if (planner->map.chosen_script[0] == HB_TAG ('m','y','m','r'))
	return &_hb_ot_complex_shaper_myanmar_old;
      else
	return &_hb_ot_complex_shaper_default;

    /* Unicode-4.1 additions */
    case HB_SCRIPT_BUGINESE:

    /* Unicode-5.1 additions */
    case HB_SCRIPT_CHAM:

    /* Unicode-5.2 additions */
    case HB_SCRIPT_TAI_THAM:

      /* If the designer designed the font for the 'DFLT' script,
       * use the default shaper.  Otherwise, use the Indic shaper.
       * Note that for some simple scripts, there may not be *any*
       * GSUB/GPOS needed, so there may be no scripts found! */
      if (planner->map.chosen_script[0] == HB_TAG ('D','F','L','T'))
	return &_hb_ot_complex_shaper_default;
      else
	return &_hb_ot_complex_shaper_sea;
  }
}


#endif /* HB_OT_SHAPE_COMPLEX_PRIVATE_HH */
