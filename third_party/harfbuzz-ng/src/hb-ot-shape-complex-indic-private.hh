/*
 * Copyright © 2012  Google, Inc.
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

#ifndef HB_OT_SHAPE_COMPLEX_INDIC_PRIVATE_HH
#define HB_OT_SHAPE_COMPLEX_INDIC_PRIVATE_HH

#include "hb-private.hh"


#include "hb-ot-shape-complex-private.hh"
#include "hb-ot-shape-private.hh" /* XXX Remove */


#define INDIC_TABLE_ELEMENT_TYPE uint16_t

/* Cateories used in the OpenType spec:
 * https://www.microsoft.com/typography/otfntdev/devanot/shaping.aspx
 */
/* Note: This enum is duplicated in the -machine.rl source file.
 * Not sure how to avoid duplication. */
enum indic_category_t {
  OT_X = 0,
  OT_C = 1,
  OT_V = 2,
  OT_N = 3,
  OT_H = 4,
  OT_ZWNJ = 5,
  OT_ZWJ = 6,
  OT_M = 7,
  OT_SM = 8,
  OT_VD = 9,
  OT_A = 10,
  OT_PLACEHOLDER = 11,
  OT_DOTTEDCIRCLE = 12,
  OT_RS = 13, /* Register Shifter, used in Khmer OT spec. */
  OT_Coeng = 14, /* Khmer-style Virama. */
  OT_Repha = 15, /* Atomically-encoded logical or visual repha. */
  OT_Ra = 16,
  OT_CM = 17,  /* Consonant-Medial. */
  OT_Symbol = 18, /* Avagraha, etc that take marks (SM,A,VD). */
  OT_CM2 = 31 /* Consonant-Medial, second slot. */
};

#define MEDIAL_FLAGS (FLAG (OT_CM) | FLAG (OT_CM2))

/* Note:
 *
 * We treat Vowels and placeholders as if they were consonants.  This is safe because Vowels
 * cannot happen in a consonant syllable.  The plus side however is, we can call the
 * consonant syllable logic from the vowel syllable function and get it all right! */
#define CONSONANT_FLAGS (FLAG (OT_C) | FLAG (OT_Ra) | MEDIAL_FLAGS | FLAG (OT_V) | FLAG (OT_PLACEHOLDER) | FLAG (OT_DOTTEDCIRCLE))
#define JOINER_FLAGS (FLAG (OT_ZWJ) | FLAG (OT_ZWNJ))
#define HALANT_OR_COENG_FLAGS (FLAG (OT_H) | FLAG (OT_Coeng))


/* Visual positions in a syllable from left to right. */
enum indic_position_t {
  POS_START,

  POS_RA_TO_BECOME_REPH,
  POS_PRE_M,
  POS_PRE_C,

  POS_BASE_C,
  POS_AFTER_MAIN,

  POS_ABOVE_C,

  POS_BEFORE_SUB,
  POS_BELOW_C,
  POS_AFTER_SUB,

  POS_BEFORE_POST,
  POS_POST_C,
  POS_AFTER_POST,

  POS_FINAL_C,
  POS_SMVD,

  POS_END
};

/* Categories used in IndicSyllabicCategory.txt from UCD. */
enum indic_syllabic_category_t {
  INDIC_SYLLABIC_CATEGORY_OTHER				= OT_X,

  INDIC_SYLLABIC_CATEGORY_AVAGRAHA			= OT_Symbol,
  INDIC_SYLLABIC_CATEGORY_BINDU				= OT_SM,
  INDIC_SYLLABIC_CATEGORY_BRAHMI_JOINING_NUMBER		= OT_PLACEHOLDER, /* TODO */
  INDIC_SYLLABIC_CATEGORY_CANTILLATION_MARK		= OT_A,
  INDIC_SYLLABIC_CATEGORY_CONSONANT			= OT_C,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_DEAD		= OT_C,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_FINAL		= OT_CM,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_HEAD_LETTER		= OT_C,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_MEDIAL		= OT_CM,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_PLACEHOLDER		= OT_PLACEHOLDER,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_PRECEDING_REPHA	= OT_Repha,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_SUBJOINED		= OT_CM,
  INDIC_SYLLABIC_CATEGORY_CONSONANT_SUCCEEDING_REPHA	= OT_N,
  INDIC_SYLLABIC_CATEGORY_GEMINATION_MARK		= OT_SM,
  INDIC_SYLLABIC_CATEGORY_INVISIBLE_STACKER		= OT_H, /* TODO */
  INDIC_SYLLABIC_CATEGORY_JOINER			= OT_ZWJ,
  INDIC_SYLLABIC_CATEGORY_MODIFYING_LETTER		= OT_X,
  INDIC_SYLLABIC_CATEGORY_NON_JOINER			= OT_ZWNJ,
  INDIC_SYLLABIC_CATEGORY_NUKTA				= OT_N,
  INDIC_SYLLABIC_CATEGORY_NUMBER			= OT_PLACEHOLDER,
  INDIC_SYLLABIC_CATEGORY_NUMBER_JOINER			= OT_PLACEHOLDER, /* TODO */
  INDIC_SYLLABIC_CATEGORY_PURE_KILLER			= OT_H, /* TODO */
  INDIC_SYLLABIC_CATEGORY_REGISTER_SHIFTER		= OT_RS,
  INDIC_SYLLABIC_CATEGORY_TONE_LETTER			= OT_X,
  INDIC_SYLLABIC_CATEGORY_TONE_MARK			= OT_N,
  INDIC_SYLLABIC_CATEGORY_VIRAMA			= OT_H,
  INDIC_SYLLABIC_CATEGORY_VISARGA			= OT_SM,
  INDIC_SYLLABIC_CATEGORY_VOWEL				= OT_V,
  INDIC_SYLLABIC_CATEGORY_VOWEL_DEPENDENT		= OT_M,
  INDIC_SYLLABIC_CATEGORY_VOWEL_INDEPENDENT		= OT_V
};

/* Categories used in IndicSMatraCategory.txt from UCD */
enum indic_matra_category_t {
  INDIC_MATRA_CATEGORY_NOT_APPLICABLE			= POS_END,

  INDIC_MATRA_CATEGORY_LEFT				= POS_PRE_C,
  INDIC_MATRA_CATEGORY_TOP				= POS_ABOVE_C,
  INDIC_MATRA_CATEGORY_BOTTOM				= POS_BELOW_C,
  INDIC_MATRA_CATEGORY_RIGHT				= POS_POST_C,

  /* These should resolve to the position of the last part of the split sequence. */
  INDIC_MATRA_CATEGORY_BOTTOM_AND_RIGHT			= INDIC_MATRA_CATEGORY_RIGHT,
  INDIC_MATRA_CATEGORY_LEFT_AND_RIGHT			= INDIC_MATRA_CATEGORY_RIGHT,
  INDIC_MATRA_CATEGORY_TOP_AND_BOTTOM			= INDIC_MATRA_CATEGORY_BOTTOM,
  INDIC_MATRA_CATEGORY_TOP_AND_BOTTOM_AND_RIGHT		= INDIC_MATRA_CATEGORY_RIGHT,
  INDIC_MATRA_CATEGORY_TOP_AND_LEFT			= INDIC_MATRA_CATEGORY_TOP,
  INDIC_MATRA_CATEGORY_TOP_AND_LEFT_AND_RIGHT		= INDIC_MATRA_CATEGORY_RIGHT,
  INDIC_MATRA_CATEGORY_TOP_AND_RIGHT			= INDIC_MATRA_CATEGORY_RIGHT,

  INDIC_MATRA_CATEGORY_OVERSTRUCK			= POS_AFTER_MAIN,
  INDIC_MATRA_CATEGORY_VISUAL_ORDER_LEFT		= POS_PRE_M
};

/* Note: We use ASSERT_STATIC_EXPR_ZERO() instead of ASSERT_STATIC_EXPR() and the comma operation
 * because gcc fails to optimize the latter and fills the table in at runtime. */
#define INDIC_COMBINE_CATEGORIES(S,M) \
  (ASSERT_STATIC_EXPR_ZERO (M == INDIC_MATRA_CATEGORY_NOT_APPLICABLE || \
			    ( \
			     S == INDIC_SYLLABIC_CATEGORY_CONSONANT_MEDIAL || \
			     S == INDIC_SYLLABIC_CATEGORY_GEMINATION_MARK || \
			     S == INDIC_SYLLABIC_CATEGORY_REGISTER_SHIFTER || \
			     S == INDIC_SYLLABIC_CATEGORY_CONSONANT_SUCCEEDING_REPHA || \
			     S == INDIC_SYLLABIC_CATEGORY_VIRAMA || \
			     S == INDIC_SYLLABIC_CATEGORY_VOWEL_DEPENDENT || \
			     false)) + \
   ASSERT_STATIC_EXPR_ZERO (S < 255 && M < 255) + \
   ((M << 8) | S))

HB_INTERNAL INDIC_TABLE_ELEMENT_TYPE
hb_indic_get_categories (hb_codepoint_t u);

#endif /* HB_OT_SHAPE_COMPLEX_INDIC_PRIVATE_HH */
