/*
 * Copyright © 2011,2012,2013  Google, Inc.
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

#include "hb-ot-shape-complex-indic-private.hh"

/* buffer var allocations */
#define myanmar_category() complex_var_u8_0() /* myanmar_category_t */
#define myanmar_position() complex_var_u8_1() /* myanmar_position_t */


/*
 * Myanmar shaper.
 */

static const hb_tag_t
basic_features[] =
{
  /*
   * Basic features.
   * These features are applied in order, one at a time, after initial_reordering.
   */
  HB_TAG('r','p','h','f'),
  HB_TAG('p','r','e','f'),
  HB_TAG('b','l','w','f'),
  HB_TAG('p','s','t','f'),
};
static const hb_tag_t
other_features[] =
{
  /*
   * Other features.
   * These features are applied all at once, after final_reordering.
   */
  HB_TAG('p','r','e','s'),
  HB_TAG('a','b','v','s'),
  HB_TAG('b','l','w','s'),
  HB_TAG('p','s','t','s'),
  /* Positioning features, though we don't care about the types. */
  HB_TAG('d','i','s','t'),
  /* Pre-release version of Windows 8 Myanmar font had abvm,blwm
   * features.  The released Windows 8 version of the font (as well
   * as the released spec) used 'mark' instead.  The Windows 8
   * shaper however didn't apply 'mark' but did apply 'mkmk'.
   * Perhaps it applied abvm/blwm.  This was fixed in a Windows 8
   * update, so now it applies mark/mkmk.  We are guessing that
   * it still applies abvm/blwm too.
   */
  HB_TAG('a','b','v','m'),
  HB_TAG('b','l','w','m'),
};

static void
setup_syllables (const hb_ot_shape_plan_t *plan,
		 hb_font_t *font,
		 hb_buffer_t *buffer);
static void
initial_reordering (const hb_ot_shape_plan_t *plan,
		    hb_font_t *font,
		    hb_buffer_t *buffer);
static void
final_reordering (const hb_ot_shape_plan_t *plan,
		  hb_font_t *font,
		  hb_buffer_t *buffer);

static void
collect_features_myanmar (hb_ot_shape_planner_t *plan)
{
  hb_ot_map_builder_t *map = &plan->map;

  /* Do this before any lookups have been applied. */
  map->add_gsub_pause (setup_syllables);

  map->add_global_bool_feature (HB_TAG('l','o','c','l'));
  /* The Indic specs do not require ccmp, but we apply it here since if
   * there is a use of it, it's typically at the beginning. */
  map->add_global_bool_feature (HB_TAG('c','c','m','p'));


  map->add_gsub_pause (initial_reordering);
  for (unsigned int i = 0; i < ARRAY_LENGTH (basic_features); i++)
  {
    map->add_feature (basic_features[i], 1, F_GLOBAL | F_MANUAL_ZWJ);
    map->add_gsub_pause (NULL);
  }
  map->add_gsub_pause (final_reordering);
  for (unsigned int i = 0; i < ARRAY_LENGTH (other_features); i++)
    map->add_feature (other_features[i], 1, F_GLOBAL | F_MANUAL_ZWJ);
}

static void
override_features_myanmar (hb_ot_shape_planner_t *plan)
{
  plan->map.add_feature (HB_TAG('l','i','g','a'), 0, F_GLOBAL);
}


enum syllable_type_t {
  consonant_syllable,
  punctuation_cluster,
  broken_cluster,
  non_myanmar_cluster,
};

#include "hb-ot-shape-complex-myanmar-machine.hh"


/* Note: This enum is duplicated in the -machine.rl source file.
 * Not sure how to avoid duplication. */
enum myanmar_category_t {
  OT_As  = 18, /* Asat */
  OT_D   = 19, /* Digits except zero */
  OT_D0  = 20, /* Digit zero */
  OT_DB  = OT_N, /* Dot below */
  OT_GB  = OT_PLACEHOLDER,
  OT_MH  = 21, /* Various consonant medial types */
  OT_MR  = 22, /* Various consonant medial types */
  OT_MW  = 23, /* Various consonant medial types */
  OT_MY  = 24, /* Various consonant medial types */
  OT_PT  = 25, /* Pwo and other tones */
  OT_VAbv = 26,
  OT_VBlw = 27,
  OT_VPre = 28,
  OT_VPst = 29,
  OT_VS   = 30, /* Variation selectors */
  OT_P    = 31  /* Punctuation */
};


static inline bool
is_one_of (const hb_glyph_info_t &info, unsigned int flags)
{
  /* If it ligated, all bets are off. */
  if (_hb_glyph_info_ligated (&info)) return false;
  return !!(FLAG (info.myanmar_category()) & flags);
}

static inline bool
is_consonant (const hb_glyph_info_t &info)
{
  return is_one_of (info, CONSONANT_FLAGS);
}


static inline void
set_myanmar_properties (hb_glyph_info_t &info)
{
  hb_codepoint_t u = info.codepoint;
  unsigned int type = hb_indic_get_categories (u);
  indic_category_t cat = (indic_category_t) (type & 0x7Fu);
  indic_position_t pos = (indic_position_t) (type >> 8);

  /* Myanmar
   * http://www.microsoft.com/typography/OpenTypeDev/myanmar/intro.htm#analyze
   */
  if (unlikely (hb_in_range (u, 0xFE00u, 0xFE0Fu)))
    cat = (indic_category_t) OT_VS;

  switch (u)
  {
    case 0x104Eu:
      cat = (indic_category_t) OT_C; /* The spec says C, IndicSyllableCategory doesn't have. */
      break;

    case 0x002Du: case 0x00A0u: case 0x00D7u: case 0x2012u:
    case 0x2013u: case 0x2014u: case 0x2015u: case 0x2022u:
    case 0x25CCu: case 0x25FBu: case 0x25FCu: case 0x25FDu:
    case 0x25FEu:
      cat = (indic_category_t) OT_GB;
      break;

    case 0x1004u: case 0x101Bu: case 0x105Au:
      cat = (indic_category_t) OT_Ra;
      break;

    case 0x1032u: case 0x1036u:
      cat = (indic_category_t) OT_A;
      break;

    case 0x103Au:
      cat = (indic_category_t) OT_As;
      break;

    case 0x1041u: case 0x1042u: case 0x1043u: case 0x1044u:
    case 0x1045u: case 0x1046u: case 0x1047u: case 0x1048u:
    case 0x1049u: case 0x1090u: case 0x1091u: case 0x1092u:
    case 0x1093u: case 0x1094u: case 0x1095u: case 0x1096u:
    case 0x1097u: case 0x1098u: case 0x1099u:
      cat = (indic_category_t) OT_D;
      break;

    case 0x1040u:
      cat = (indic_category_t) OT_D; /* XXX The spec says D0, but Uniscribe doesn't seem to do. */
      break;

    case 0x103Eu: case 0x1060u:
      cat = (indic_category_t) OT_MH;
      break;

    case 0x103Cu:
      cat = (indic_category_t) OT_MR;
      break;

    case 0x103Du: case 0x1082u:
      cat = (indic_category_t) OT_MW;
      break;

    case 0x103Bu: case 0x105Eu: case 0x105Fu:
      cat = (indic_category_t) OT_MY;
      break;

    case 0x1063u: case 0x1064u: case 0x1069u: case 0x106Au:
    case 0x106Bu: case 0x106Cu: case 0x106Du: case 0xAA7Bu:
      cat = (indic_category_t) OT_PT;
      break;

    case 0x1038u: case 0x1087u: case 0x1088u: case 0x1089u:
    case 0x108Au: case 0x108Bu: case 0x108Cu: case 0x108Du:
    case 0x108Fu: case 0x109Au: case 0x109Bu: case 0x109Cu:
      cat = (indic_category_t) OT_SM;
      break;

    case 0x104Au: case 0x104Bu:
      cat = (indic_category_t) OT_P;
      break;
  }

  if (cat == OT_M)
  {
    switch ((int) pos)
    {
      case POS_PRE_C:	cat = (indic_category_t) OT_VPre;
			pos = POS_PRE_M;                  break;
      case POS_ABOVE_C:	cat = (indic_category_t) OT_VAbv; break;
      case POS_BELOW_C:	cat = (indic_category_t) OT_VBlw; break;
      case POS_POST_C:	cat = (indic_category_t) OT_VPst; break;
    }
  }

  info.myanmar_category() = (myanmar_category_t) cat;
  info.myanmar_position() = pos;
}



static void
setup_masks_myanmar (const hb_ot_shape_plan_t *plan HB_UNUSED,
		   hb_buffer_t              *buffer,
		   hb_font_t                *font HB_UNUSED)
{
  HB_BUFFER_ALLOCATE_VAR (buffer, myanmar_category);
  HB_BUFFER_ALLOCATE_VAR (buffer, myanmar_position);

  /* We cannot setup masks here.  We save information about characters
   * and setup masks later on in a pause-callback. */

  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    set_myanmar_properties (info[i]);
}

static void
setup_syllables (const hb_ot_shape_plan_t *plan HB_UNUSED,
		 hb_font_t *font HB_UNUSED,
		 hb_buffer_t *buffer)
{
  find_syllables (buffer);
}

static int
compare_myanmar_order (const hb_glyph_info_t *pa, const hb_glyph_info_t *pb)
{
  int a = pa->myanmar_position();
  int b = pb->myanmar_position();

  return a < b ? -1 : a == b ? 0 : +1;
}


/* Rules from:
 * http://www.microsoft.com/typography/OpenTypeDev/myanmar/intro.htm */

static void
initial_reordering_consonant_syllable (const hb_ot_shape_plan_t *plan,
				       hb_face_t *face,
				       hb_buffer_t *buffer,
				       unsigned int start, unsigned int end)
{
  hb_glyph_info_t *info = buffer->info;

  unsigned int base = end;
  bool has_reph = false;

  {
    unsigned int limit = start;
    if (start + 3 <= end &&
	info[start  ].myanmar_category() == OT_Ra &&
	info[start+1].myanmar_category() == OT_As &&
	info[start+2].myanmar_category() == OT_H)
    {
      limit += 3;
      base = start;
      has_reph = true;
    }

    {
      if (!has_reph)
	base = limit;

      for (unsigned int i = limit; i < end; i++)
	if (is_consonant (info[i]))
	{
	  base = i;
	  break;
	}
    }
  }

  /* Reorder! */
  {
    unsigned int i = start;
    for (; i < start + (has_reph ? 3 : 0); i++)
      info[i].myanmar_position() = POS_AFTER_MAIN;
    for (; i < base; i++)
      info[i].myanmar_position() = POS_PRE_C;
    if (i < end)
    {
      info[i].myanmar_position() = POS_BASE_C;
      i++;
    }
    indic_position_t pos = POS_AFTER_MAIN;
    /* The following loop may be ugly, but it implements all of
     * Myanmar reordering! */
    for (; i < end; i++)
    {
      if (info[i].myanmar_category() == OT_MR) /* Pre-base reordering */
      {
	info[i].myanmar_position() = POS_PRE_C;
	continue;
      }
      if (info[i].myanmar_position() < POS_BASE_C) /* Left matra */
      {
	continue;
      }

      if (pos == POS_AFTER_MAIN && info[i].myanmar_category() == OT_VBlw)
      {
	pos = POS_BELOW_C;
	info[i].myanmar_position() = pos;
	continue;
      }

      if (pos == POS_BELOW_C && info[i].myanmar_category() == OT_A)
      {
	info[i].myanmar_position() = POS_BEFORE_SUB;
	continue;
      }
      if (pos == POS_BELOW_C && info[i].myanmar_category() == OT_VBlw)
      {
	info[i].myanmar_position() = pos;
	continue;
      }
      if (pos == POS_BELOW_C && info[i].myanmar_category() != OT_A)
      {
        pos = POS_AFTER_SUB;
	info[i].myanmar_position() = pos;
	continue;
      }
      info[i].myanmar_position() = pos;
    }
  }

  buffer->merge_clusters (start, end);
  /* Sit tight, rock 'n roll! */
  hb_bubble_sort (info + start, end - start, compare_myanmar_order);
}

static void
initial_reordering_broken_cluster (const hb_ot_shape_plan_t *plan,
				   hb_face_t *face,
				   hb_buffer_t *buffer,
				   unsigned int start, unsigned int end)
{
  /* We already inserted dotted-circles, so just call the consonant_syllable. */
  initial_reordering_consonant_syllable (plan, face, buffer, start, end);
}

static void
initial_reordering_punctuation_cluster (const hb_ot_shape_plan_t *plan HB_UNUSED,
					hb_face_t *face HB_UNUSED,
					hb_buffer_t *buffer HB_UNUSED,
					unsigned int start HB_UNUSED, unsigned int end HB_UNUSED)
{
  /* Nothing to do right now.  If we ever switch to using the output
   * buffer in the reordering process, we'd need to next_glyph() here. */
}

static void
initial_reordering_non_myanmar_cluster (const hb_ot_shape_plan_t *plan HB_UNUSED,
					hb_face_t *face HB_UNUSED,
					hb_buffer_t *buffer HB_UNUSED,
					unsigned int start HB_UNUSED, unsigned int end HB_UNUSED)
{
  /* Nothing to do right now.  If we ever switch to using the output
   * buffer in the reordering process, we'd need to next_glyph() here. */
}


static void
initial_reordering_syllable (const hb_ot_shape_plan_t *plan,
			     hb_face_t *face,
			     hb_buffer_t *buffer,
			     unsigned int start, unsigned int end)
{
  syllable_type_t syllable_type = (syllable_type_t) (buffer->info[start].syllable() & 0x0F);
  switch (syllable_type) {
  case consonant_syllable:	initial_reordering_consonant_syllable  (plan, face, buffer, start, end); return;
  case punctuation_cluster:	initial_reordering_punctuation_cluster (plan, face, buffer, start, end); return;
  case broken_cluster:		initial_reordering_broken_cluster      (plan, face, buffer, start, end); return;
  case non_myanmar_cluster:	initial_reordering_non_myanmar_cluster (plan, face, buffer, start, end); return;
  }
}

static inline void
insert_dotted_circles (const hb_ot_shape_plan_t *plan HB_UNUSED,
		       hb_font_t *font,
		       hb_buffer_t *buffer)
{
  /* Note: This loop is extra overhead, but should not be measurable. */
  bool has_broken_syllables = false;
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    if ((info[i].syllable() & 0x0F) == broken_cluster)
    {
      has_broken_syllables = true;
      break;
    }
  if (likely (!has_broken_syllables))
    return;


  hb_codepoint_t dottedcircle_glyph;
  if (!font->get_glyph (0x25CCu, 0, &dottedcircle_glyph))
    return;

  hb_glyph_info_t dottedcircle = {0};
  dottedcircle.codepoint = 0x25CCu;
  set_myanmar_properties (dottedcircle);
  dottedcircle.codepoint = dottedcircle_glyph;

  buffer->clear_output ();

  buffer->idx = 0;
  unsigned int last_syllable = 0;
  while (buffer->idx < buffer->len)
  {
    unsigned int syllable = buffer->cur().syllable();
    syllable_type_t syllable_type = (syllable_type_t) (syllable & 0x0F);
    if (unlikely (last_syllable != syllable && syllable_type == broken_cluster))
    {
      last_syllable = syllable;

      hb_glyph_info_t info = dottedcircle;
      info.cluster = buffer->cur().cluster;
      info.mask = buffer->cur().mask;
      info.syllable() = buffer->cur().syllable();

      buffer->output_info (info);
    }
    else
      buffer->next_glyph ();
  }

  buffer->swap_buffers ();
}

static void
initial_reordering (const hb_ot_shape_plan_t *plan,
		    hb_font_t *font,
		    hb_buffer_t *buffer)
{
  insert_dotted_circles (plan, font, buffer);

  hb_glyph_info_t *info = buffer->info;
  unsigned int count = buffer->len;
  if (unlikely (!count)) return;
  unsigned int last = 0;
  unsigned int last_syllable = info[0].syllable();
  for (unsigned int i = 1; i < count; i++)
    if (last_syllable != info[i].syllable()) {
      initial_reordering_syllable (plan, font->face, buffer, last, i);
      last = i;
      last_syllable = info[last].syllable();
    }
  initial_reordering_syllable (plan, font->face, buffer, last, count);
}

static void
final_reordering (const hb_ot_shape_plan_t *plan,
		  hb_font_t *font HB_UNUSED,
		  hb_buffer_t *buffer)
{
  hb_glyph_info_t *info = buffer->info;
  unsigned int count = buffer->len;

  /* Zero syllables now... */
  for (unsigned int i = 0; i < count; i++)
    info[i].syllable() = 0;

  HB_BUFFER_DEALLOCATE_VAR (buffer, myanmar_category);
  HB_BUFFER_DEALLOCATE_VAR (buffer, myanmar_position);
}


/* Uniscribe seems to have a shaper for 'mymr' that is like the
 * generic shaper, except that it zeros mark advances GDEF_LATE. */
const hb_ot_complex_shaper_t _hb_ot_complex_shaper_myanmar_old =
{
  "default",
  NULL, /* collect_features */
  NULL, /* override_features */
  NULL, /* data_create */
  NULL, /* data_destroy */
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_DEFAULT,
  NULL, /* decompose */
  NULL, /* compose */
  NULL, /* setup_masks */
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_LATE,
  true, /* fallback_position */
};

const hb_ot_complex_shaper_t _hb_ot_complex_shaper_myanmar =
{
  "myanmar",
  collect_features_myanmar,
  override_features_myanmar,
  NULL, /* data_create */
  NULL, /* data_destroy */
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_COMPOSED_DIACRITICS_NO_SHORT_CIRCUIT,
  NULL, /* decompose */
  NULL, /* compose */
  setup_masks_myanmar,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_EARLY,
  false, /* fallback_position */
};
