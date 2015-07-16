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
#define sea_category() complex_var_u8_0() /* indic_category_t */
#define sea_position() complex_var_u8_1() /* indic_position_t */


/*
 * South-East Asian shaper.
 * Loosely based on the Myanmar spec / shaper.
 * There is no OpenType spec for this.
 */

static const hb_tag_t
basic_features[] =
{
  /*
   * Basic features.
   * These features are applied in order, one at a time, after initial_reordering.
   */
  HB_TAG('p','r','e','f'),
  HB_TAG('a','b','v','f'),
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
collect_features_sea (hb_ot_shape_planner_t *plan)
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
override_features_sea (hb_ot_shape_planner_t *plan)
{
  plan->map.add_feature (HB_TAG('l','i','g','a'), 0, F_GLOBAL);
}


enum syllable_type_t {
  consonant_syllable,
  broken_cluster,
  non_sea_cluster,
};

#include "hb-ot-shape-complex-sea-machine.hh"


/* Note: This enum is duplicated in the -machine.rl source file.
 * Not sure how to avoid duplication. */
enum sea_category_t {
//  OT_C    = 1,
  OT_GB   = 12, /* Generic Base XXX DOTTED CIRCLE only for now */
//  OT_H    = 4,  /* Halant */
  OT_IV   = 2,  /* Independent Vowel */
  OT_MR   = 22, /* Medial Ra */
//  OT_CM   = 17, /* Consonant Medial */
  OT_VAbv = 26,
  OT_VBlw = 27,
  OT_VPre = 28,
  OT_VPst = 29,
  OT_T    = 3,  /* Tone Marks */
//  OT_A    = 10, /* Anusvara */
};

static inline void
set_sea_properties (hb_glyph_info_t &info)
{
  hb_codepoint_t u = info.codepoint;
  unsigned int type = hb_indic_get_categories (u);
  indic_category_t cat = (indic_category_t) (type & 0x7Fu);
  indic_position_t pos = (indic_position_t) (type >> 8);

  /* Medial Ra */
  if (u == 0x1A55u || u == 0xAA34u)
    cat = (indic_category_t) OT_MR;

  if (cat == OT_M)
  {
    switch ((int) pos)
    {
      case POS_PRE_C:	cat = (indic_category_t) OT_VPre; break;
      case POS_ABOVE_C:	cat = (indic_category_t) OT_VAbv; break;
      case POS_BELOW_C:	cat = (indic_category_t) OT_VBlw; break;
      case POS_POST_C:	cat = (indic_category_t) OT_VPst; break;
    }
  }

  info.sea_category() = (sea_category_t) cat;
  info.sea_position() = pos;
}


static void
setup_masks_sea (const hb_ot_shape_plan_t *plan HB_UNUSED,
		 hb_buffer_t              *buffer,
		 hb_font_t                *font HB_UNUSED)
{
  HB_BUFFER_ALLOCATE_VAR (buffer, sea_category);
  HB_BUFFER_ALLOCATE_VAR (buffer, sea_position);

  /* We cannot setup masks here.  We save information about characters
   * and setup masks later on in a pause-callback. */

  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    set_sea_properties (info[i]);
}

static void
setup_syllables (const hb_ot_shape_plan_t *plan HB_UNUSED,
		 hb_font_t *font HB_UNUSED,
		 hb_buffer_t *buffer)
{
  find_syllables (buffer);
}

static int
compare_sea_order (const hb_glyph_info_t *pa, const hb_glyph_info_t *pb)
{
  int a = pa->sea_position();
  int b = pb->sea_position();

  return a < b ? -1 : a == b ? 0 : +1;
}


static void
initial_reordering_consonant_syllable (const hb_ot_shape_plan_t *plan,
				       hb_face_t *face,
				       hb_buffer_t *buffer,
				       unsigned int start, unsigned int end)
{
  hb_glyph_info_t *info = buffer->info;
  unsigned int base = start;

  /* Reorder! */
  unsigned int i = start;
  for (; i < base; i++)
    info[i].sea_position() = POS_PRE_C;
  if (i < end)
  {
    info[i].sea_position() = POS_BASE_C;
    i++;
  }
  for (; i < end; i++)
  {
    if (info[i].sea_category() == OT_MR) /* Pre-base reordering */
    {
      info[i].sea_position() = POS_PRE_C;
      continue;
    }
    if (info[i].sea_category() == OT_VPre) /* Left matra */
    {
      info[i].sea_position() = POS_PRE_M;
      continue;
    }

    info[i].sea_position() = POS_AFTER_MAIN;
  }

  buffer->merge_clusters (start, end);
  /* Sit tight, rock 'n roll! */
  hb_bubble_sort (info + start, end - start, compare_sea_order);
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
initial_reordering_non_sea_cluster (const hb_ot_shape_plan_t *plan HB_UNUSED,
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
  case broken_cluster:		initial_reordering_broken_cluster      (plan, face, buffer, start, end); return;
  case non_sea_cluster:		initial_reordering_non_sea_cluster     (plan, face, buffer, start, end); return;
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
  set_sea_properties (dottedcircle);
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

  HB_BUFFER_DEALLOCATE_VAR (buffer, sea_category);
  HB_BUFFER_DEALLOCATE_VAR (buffer, sea_position);
}


const hb_ot_complex_shaper_t _hb_ot_complex_shaper_sea =
{
  "sea",
  collect_features_sea,
  override_features_sea,
  NULL, /* data_create */
  NULL, /* data_destroy */
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_COMPOSED_DIACRITICS_NO_SHORT_CIRCUIT,
  NULL, /* decompose */
  NULL, /* compose */
  setup_masks_sea,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE,
  false, /* fallback_position */
};
