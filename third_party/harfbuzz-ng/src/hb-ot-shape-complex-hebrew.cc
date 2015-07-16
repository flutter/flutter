/*
 * Copyright © 2010,2012  Google, Inc.
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

#include "hb-ot-shape-complex-private.hh"


static bool
compose_hebrew (const hb_ot_shape_normalize_context_t *c,
		hb_codepoint_t  a,
		hb_codepoint_t  b,
		hb_codepoint_t *ab)
{
  /* Hebrew presentation-form shaping.
   * https://bugzilla.mozilla.org/show_bug.cgi?id=728866
   * Hebrew presentation forms with dagesh, for characters U+05D0..05EA;
   * Note that some letters do not have a dagesh presForm encoded.
   */
  static const hb_codepoint_t sDageshForms[0x05EAu - 0x05D0u + 1] = {
    0xFB30u, /* ALEF */
    0xFB31u, /* BET */
    0xFB32u, /* GIMEL */
    0xFB33u, /* DALET */
    0xFB34u, /* HE */
    0xFB35u, /* VAV */
    0xFB36u, /* ZAYIN */
    0x0000u, /* HET */
    0xFB38u, /* TET */
    0xFB39u, /* YOD */
    0xFB3Au, /* FINAL KAF */
    0xFB3Bu, /* KAF */
    0xFB3Cu, /* LAMED */
    0x0000u, /* FINAL MEM */
    0xFB3Eu, /* MEM */
    0x0000u, /* FINAL NUN */
    0xFB40u, /* NUN */
    0xFB41u, /* SAMEKH */
    0x0000u, /* AYIN */
    0xFB43u, /* FINAL PE */
    0xFB44u, /* PE */
    0x0000u, /* FINAL TSADI */
    0xFB46u, /* TSADI */
    0xFB47u, /* QOF */
    0xFB48u, /* RESH */
    0xFB49u, /* SHIN */
    0xFB4Au /* TAV */
  };

  bool found = c->unicode->compose (a, b, ab);

  if (!found && !c->plan->has_mark)
  {
      /* Special-case Hebrew presentation forms that are excluded from
       * standard normalization, but wanted for old fonts. */
      switch (b) {
      case 0x05B4u: /* HIRIQ */
	  if (a == 0x05D9u) { /* YOD */
	      *ab = 0xFB1Du;
	      found = true;
	  }
	  break;
      case 0x05B7u: /* patah */
	  if (a == 0x05F2u) { /* YIDDISH YOD YOD */
	      *ab = 0xFB1Fu;
	      found = true;
	  } else if (a == 0x05D0u) { /* ALEF */
	      *ab = 0xFB2Eu;
	      found = true;
	  }
	  break;
      case 0x05B8u: /* QAMATS */
	  if (a == 0x05D0u) { /* ALEF */
	      *ab = 0xFB2Fu;
	      found = true;
	  }
	  break;
      case 0x05B9u: /* HOLAM */
	  if (a == 0x05D5u) { /* VAV */
	      *ab = 0xFB4Bu;
	      found = true;
	  }
	  break;
      case 0x05BCu: /* DAGESH */
	  if (a >= 0x05D0u && a <= 0x05EAu) {
	      *ab = sDageshForms[a - 0x05D0u];
	      found = (*ab != 0);
	  } else if (a == 0xFB2Au) { /* SHIN WITH SHIN DOT */
	      *ab = 0xFB2Cu;
	      found = true;
	  } else if (a == 0xFB2Bu) { /* SHIN WITH SIN DOT */
	      *ab = 0xFB2Du;
	      found = true;
	  }
	  break;
      case 0x05BFu: /* RAFE */
	  switch (a) {
	  case 0x05D1u: /* BET */
	      *ab = 0xFB4Cu;
	      found = true;
	      break;
	  case 0x05DBu: /* KAF */
	      *ab = 0xFB4Du;
	      found = true;
	      break;
	  case 0x05E4u: /* PE */
	      *ab = 0xFB4Eu;
	      found = true;
	      break;
	  }
	  break;
      case 0x05C1u: /* SHIN DOT */
	  if (a == 0x05E9u) { /* SHIN */
	      *ab = 0xFB2Au;
	      found = true;
	  } else if (a == 0xFB49u) { /* SHIN WITH DAGESH */
	      *ab = 0xFB2Cu;
	      found = true;
	  }
	  break;
      case 0x05C2u: /* SIN DOT */
	  if (a == 0x05E9u) { /* SHIN */
	      *ab = 0xFB2Bu;
	      found = true;
	  } else if (a == 0xFB49u) { /* SHIN WITH DAGESH */
	      *ab = 0xFB2Du;
	      found = true;
	  }
	  break;
      }
  }

  return found;
}


const hb_ot_complex_shaper_t _hb_ot_complex_shaper_hebrew =
{
  "hebrew",
  NULL, /* collect_features */
  NULL, /* override_features */
  NULL, /* data_create */
  NULL, /* data_destroy */
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_DEFAULT,
  NULL, /* decompose */
  compose_hebrew,
  NULL, /* setup_masks */
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_LATE,
  true, /* fallback_position */
};
