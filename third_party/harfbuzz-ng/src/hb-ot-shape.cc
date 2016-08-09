/*
 * Copyright © 2009,2010  Red Hat, Inc.
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
 * Google Author(s): Behdad Esfahbod
 */

#define HB_SHAPER ot
#define hb_ot_shaper_face_data_t hb_ot_layout_t
#define hb_ot_shaper_shape_plan_data_t hb_ot_shape_plan_t
#include "hb-shaper-impl-private.hh"

#include "hb-ot-shape-private.hh"
#include "hb-ot-shape-complex-private.hh"
#include "hb-ot-shape-fallback-private.hh"
#include "hb-ot-shape-normalize-private.hh"

#include "hb-ot-layout-private.hh"
#include "hb-unicode-private.hh"
#include "hb-set-private.hh"


static hb_tag_t common_features[] = {
  HB_TAG('c','c','m','p'),
  HB_TAG('l','o','c','l'),
  HB_TAG('m','a','r','k'),
  HB_TAG('m','k','m','k'),
  HB_TAG('r','l','i','g'),
};


static hb_tag_t horizontal_features[] = {
  HB_TAG('c','a','l','t'),
  HB_TAG('c','l','i','g'),
  HB_TAG('c','u','r','s'),
  HB_TAG('k','e','r','n'),
  HB_TAG('l','i','g','a'),
  HB_TAG('r','c','l','t'),
};

static hb_tag_t vertical_features[] = {
  HB_TAG('v','e','r','t'),
};



static void
hb_ot_shape_collect_features (hb_ot_shape_planner_t          *planner,
			      const hb_segment_properties_t  *props,
			      const hb_feature_t             *user_features,
			      unsigned int                    num_user_features)
{
  hb_ot_map_builder_t *map = &planner->map;

  switch (props->direction) {
    case HB_DIRECTION_LTR:
      map->add_global_bool_feature (HB_TAG ('l','t','r','a'));
      map->add_global_bool_feature (HB_TAG ('l','t','r','m'));
      break;
    case HB_DIRECTION_RTL:
      map->add_global_bool_feature (HB_TAG ('r','t','l','a'));
      map->add_feature (HB_TAG ('r','t','l','m'), 1, F_NONE);
      break;
    case HB_DIRECTION_TTB:
    case HB_DIRECTION_BTT:
    case HB_DIRECTION_INVALID:
    default:
      break;
  }

  map->add_feature (HB_TAG ('f','r','a','c'), 1, F_NONE);
  map->add_feature (HB_TAG ('n','u','m','r'), 1, F_NONE);
  map->add_feature (HB_TAG ('d','n','o','m'), 1, F_NONE);

  if (planner->shaper->collect_features)
    planner->shaper->collect_features (planner);

  for (unsigned int i = 0; i < ARRAY_LENGTH (common_features); i++)
    map->add_global_bool_feature (common_features[i]);

  if (HB_DIRECTION_IS_HORIZONTAL (props->direction))
    for (unsigned int i = 0; i < ARRAY_LENGTH (horizontal_features); i++)
      map->add_feature (horizontal_features[i], 1, F_GLOBAL |
			(horizontal_features[i] == HB_TAG('k','e','r','n') ?
			 F_HAS_FALLBACK : F_NONE));
  else
    for (unsigned int i = 0; i < ARRAY_LENGTH (vertical_features); i++)
      map->add_feature (vertical_features[i], 1, F_GLOBAL |
			(vertical_features[i] == HB_TAG('v','k','r','n') ?
			 F_HAS_FALLBACK : F_NONE));

  if (planner->shaper->override_features)
    planner->shaper->override_features (planner);

  for (unsigned int i = 0; i < num_user_features; i++) {
    const hb_feature_t *feature = &user_features[i];
    map->add_feature (feature->tag, feature->value,
		      (feature->start == 0 && feature->end == (unsigned int) -1) ?
		       F_GLOBAL : F_NONE);
  }
}


/*
 * shaper face data
 */

hb_ot_shaper_face_data_t *
_hb_ot_shaper_face_data_create (hb_face_t *face)
{
  return _hb_ot_layout_create (face);
}

void
_hb_ot_shaper_face_data_destroy (hb_ot_shaper_face_data_t *data)
{
  _hb_ot_layout_destroy (data);
}


/*
 * shaper font data
 */

struct hb_ot_shaper_font_data_t {};

hb_ot_shaper_font_data_t *
_hb_ot_shaper_font_data_create (hb_font_t *font)
{
  return (hb_ot_shaper_font_data_t *) HB_SHAPER_DATA_SUCCEEDED;
}

void
_hb_ot_shaper_font_data_destroy (hb_ot_shaper_font_data_t *data)
{
}


/*
 * shaper shape_plan data
 */

hb_ot_shaper_shape_plan_data_t *
_hb_ot_shaper_shape_plan_data_create (hb_shape_plan_t    *shape_plan,
				      const hb_feature_t *user_features,
				      unsigned int        num_user_features)
{
  hb_ot_shape_plan_t *plan = (hb_ot_shape_plan_t *) calloc (1, sizeof (hb_ot_shape_plan_t));
  if (unlikely (!plan))
    return NULL;

  hb_ot_shape_planner_t planner (shape_plan);

  planner.shaper = hb_ot_shape_complex_categorize (&planner);

  hb_ot_shape_collect_features (&planner, &shape_plan->props, user_features, num_user_features);

  planner.compile (*plan);

  if (plan->shaper->data_create) {
    plan->data = plan->shaper->data_create (plan);
    if (unlikely (!plan->data))
      return NULL;
  }

  return plan;
}

void
_hb_ot_shaper_shape_plan_data_destroy (hb_ot_shaper_shape_plan_data_t *plan)
{
  if (plan->shaper->data_destroy)
    plan->shaper->data_destroy (const_cast<void *> (plan->data));

  plan->finish ();

  free (plan);
}


/*
 * shaper
 */

struct hb_ot_shape_context_t
{
  hb_ot_shape_plan_t *plan;
  hb_font_t *font;
  hb_face_t *face;
  hb_buffer_t  *buffer;
  const hb_feature_t *user_features;
  unsigned int        num_user_features;

  /* Transient stuff */
  hb_direction_t target_direction;
};



/* Main shaper */


/* Prepare */

static void
hb_set_unicode_props (hb_buffer_t *buffer)
{
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    _hb_glyph_info_set_unicode_props (&info[i], buffer->unicode);
}

static void
hb_insert_dotted_circle (hb_buffer_t *buffer, hb_font_t *font)
{
  if (!(buffer->flags & HB_BUFFER_FLAG_BOT) ||
      buffer->context_len[0] ||
      _hb_glyph_info_get_general_category (&buffer->info[0]) !=
      HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK)
    return;

  if (!font->has_glyph (0x25CCu))
    return;

  hb_glyph_info_t dottedcircle = {0};
  dottedcircle.codepoint = 0x25CCu;
  _hb_glyph_info_set_unicode_props (&dottedcircle, buffer->unicode);

  buffer->clear_output ();

  buffer->idx = 0;
  hb_glyph_info_t info = dottedcircle;
  info.cluster = buffer->cur().cluster;
  info.mask = buffer->cur().mask;
  buffer->output_info (info);
  while (buffer->idx < buffer->len)
    buffer->next_glyph ();

  buffer->swap_buffers ();
}

static void
hb_form_clusters (hb_buffer_t *buffer)
{
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 1; i < count; i++)
    if (HB_UNICODE_GENERAL_CATEGORY_IS_MARK (_hb_glyph_info_get_general_category (&info[i])))
      buffer->merge_clusters (i - 1, i + 1);
}

static void
hb_ensure_native_direction (hb_buffer_t *buffer)
{
  hb_direction_t direction = buffer->props.direction;

  /* TODO vertical:
   * The only BTT vertical script is Ogham, but it's not clear to me whether OpenType
   * Ogham fonts are supposed to be implemented BTT or not.  Need to research that
   * first. */
  if ((HB_DIRECTION_IS_HORIZONTAL (direction) && direction != hb_script_get_horizontal_direction (buffer->props.script)) ||
      (HB_DIRECTION_IS_VERTICAL   (direction) && direction != HB_DIRECTION_TTB))
  {
    hb_buffer_reverse_clusters (buffer);
    buffer->props.direction = HB_DIRECTION_REVERSE (buffer->props.direction);
  }
}


/* Substitute */

static inline void
hb_ot_mirror_chars (hb_ot_shape_context_t *c)
{
  if (HB_DIRECTION_IS_FORWARD (c->target_direction))
    return;

  hb_buffer_t *buffer = c->buffer;
  hb_unicode_funcs_t *unicode = buffer->unicode;
  hb_mask_t rtlm_mask = c->plan->rtlm_mask;

  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++) {
    hb_codepoint_t codepoint = unicode->mirroring (info[i].codepoint);
    if (likely (codepoint == info[i].codepoint))
      info[i].mask |= rtlm_mask;
    else
      info[i].codepoint = codepoint;
  }
}

static inline void
hb_ot_shape_setup_masks_fraction (hb_ot_shape_context_t *c)
{
  if (!c->plan->has_frac)
    return;

  hb_buffer_t *buffer = c->buffer;

  /* TODO look in pre/post context text also. */
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
  {
    if (info[i].codepoint == 0x2044u) /* FRACTION SLASH */
    {
      unsigned int start = i, end = i + 1;
      while (start &&
	     _hb_glyph_info_get_general_category (&info[start - 1]) ==
	     HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER)
        start--;
      while (end < count &&
	     _hb_glyph_info_get_general_category (&info[end]) ==
	     HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER)
        end++;

      for (unsigned int j = start; j < i; j++)
        info[j].mask |= c->plan->numr_mask | c->plan->frac_mask;
      info[i].mask |= c->plan->frac_mask;
      for (unsigned int j = i + 1; j < end; j++)
        info[j].mask |= c->plan->frac_mask | c->plan->dnom_mask;

      i = end - 1;
    }
  }
}

static inline void
hb_ot_shape_initialize_masks (hb_ot_shape_context_t *c)
{
  hb_ot_map_t *map = &c->plan->map;
  hb_buffer_t *buffer = c->buffer;

  hb_mask_t global_mask = map->get_global_mask ();
  buffer->reset_masks (global_mask);
}

static inline void
hb_ot_shape_setup_masks (hb_ot_shape_context_t *c)
{
  hb_ot_map_t *map = &c->plan->map;
  hb_buffer_t *buffer = c->buffer;

  hb_ot_shape_setup_masks_fraction (c);

  if (c->plan->shaper->setup_masks)
    c->plan->shaper->setup_masks (c->plan, buffer, c->font);

  for (unsigned int i = 0; i < c->num_user_features; i++)
  {
    const hb_feature_t *feature = &c->user_features[i];
    if (!(feature->start == 0 && feature->end == (unsigned int)-1)) {
      unsigned int shift;
      hb_mask_t mask = map->get_mask (feature->tag, &shift);
      buffer->set_masks (feature->value << shift, mask, feature->start, feature->end);
    }
  }
}

static inline void
hb_ot_map_glyphs_fast (hb_buffer_t  *buffer)
{
  /* Normalization process sets up glyph_index(), we just copy it. */
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    info[i].codepoint = info[i].glyph_index();
}

static inline void
hb_synthesize_glyph_classes (hb_ot_shape_context_t *c)
{
  unsigned int count = c->buffer->len;
  hb_glyph_info_t *info = c->buffer->info;
  for (unsigned int i = 0; i < count; i++)
  {
    hb_ot_layout_glyph_class_mask_t klass;

    /* Never mark default-ignorables as marks.
     * They won't get in the way of lookups anyway,
     * but having them as mark will cause them to be skipped
     * over if the lookup-flag says so, but at least for the
     * Mongolian variation selectors, looks like Uniscribe
     * marks them as non-mark.  Some Mongolian fonts without
     * GDEF rely on this.  Another notable character that
     * this applies to is COMBINING GRAPHEME JOINER. */
    klass = (_hb_glyph_info_get_general_category (&info[i]) !=
	     HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK ||
	     _hb_glyph_info_is_default_ignorable (&info[i])) ?
	    HB_OT_LAYOUT_GLYPH_PROPS_BASE_GLYPH :
	    HB_OT_LAYOUT_GLYPH_PROPS_MARK;
    _hb_glyph_info_set_glyph_props (&info[i], klass);
  }
}

static inline void
hb_ot_substitute_default (hb_ot_shape_context_t *c)
{
  hb_buffer_t *buffer = c->buffer;

  if (c->plan->shaper->preprocess_text)
    c->plan->shaper->preprocess_text (c->plan, buffer, c->font);

  hb_ot_shape_initialize_masks (c);

  hb_ot_mirror_chars (c);

  HB_BUFFER_ALLOCATE_VAR (buffer, glyph_index);

  _hb_ot_shape_normalize (c->plan, buffer, c->font);

  hb_ot_shape_setup_masks (c);

  /* This is unfortunate to go here, but necessary... */
  if (!hb_ot_layout_has_positioning (c->face))
    _hb_ot_shape_fallback_position_recategorize_marks (c->plan, c->font, buffer);

  hb_ot_map_glyphs_fast (buffer);

  HB_BUFFER_DEALLOCATE_VAR (buffer, glyph_index);
}

static inline void
hb_ot_substitute_complex (hb_ot_shape_context_t *c)
{
  hb_buffer_t *buffer = c->buffer;

  _hb_buffer_allocate_gsubgpos_vars (buffer);
  hb_ot_layout_substitute_start (c->font, buffer);

  if (!hb_ot_layout_has_glyph_classes (c->face))
    hb_synthesize_glyph_classes (c);

  c->plan->substitute (c->font, buffer);

  hb_ot_layout_substitute_finish (c->font, buffer);

  return;
}

static inline void
hb_ot_substitute (hb_ot_shape_context_t *c)
{
  hb_ot_substitute_default (c);
  hb_ot_substitute_complex (c);
}

/* Position */

static inline void
adjust_mark_offsets (hb_glyph_position_t *pos)
{
  pos->x_offset -= pos->x_advance;
  pos->y_offset -= pos->y_advance;
}

static inline void
zero_mark_width (hb_glyph_position_t *pos)
{
  pos->x_advance = 0;
  pos->y_advance = 0;
}

static inline void
zero_mark_widths_by_unicode (hb_buffer_t *buffer, bool adjust_offsets)
{
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    if (_hb_glyph_info_get_general_category (&info[i]) == HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK)
    {
      if (adjust_offsets)
        adjust_mark_offsets (&buffer->pos[i]);
      zero_mark_width (&buffer->pos[i]);
    }
}

static inline void
zero_mark_widths_by_gdef (hb_buffer_t *buffer, bool adjust_offsets)
{
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    if (_hb_glyph_info_is_mark (&info[i]))
    {
      if (adjust_offsets)
        adjust_mark_offsets (&buffer->pos[i]);
      zero_mark_width (&buffer->pos[i]);
    }
}

static inline void
hb_ot_position_default (hb_ot_shape_context_t *c)
{
  hb_direction_t direction = c->buffer->props.direction;
  unsigned int count = c->buffer->len;
  hb_glyph_info_t *info = c->buffer->info;
  hb_glyph_position_t *pos = c->buffer->pos;
  for (unsigned int i = 0; i < count; i++)
  {
    c->font->get_glyph_advance_for_direction (info[i].codepoint,
					      direction,
					      &pos[i].x_advance,
					      &pos[i].y_advance);
    c->font->subtract_glyph_origin_for_direction (info[i].codepoint,
						  direction,
						  &pos[i].x_offset,
						  &pos[i].y_offset);

  }
}

static inline bool
hb_ot_position_complex (hb_ot_shape_context_t *c)
{
  bool ret = false;
  unsigned int count = c->buffer->len;
  bool has_positioning = hb_ot_layout_has_positioning (c->face);
  /* If the font has no GPOS, AND, no fallback positioning will
   * happen, AND, direction is forward, then when zeroing mark
   * widths, we shift the mark with it, such that the mark
   * is positioned hanging over the previous glyph.  When
   * direction is backward we don't shift and it will end up
   * hanging over the next glyph after the final reordering.
   * If fallback positinoing happens or GPOS is present, we don't
   * care.
   */
  bool adjust_offsets_when_zeroing = !(has_positioning || c->plan->shaper->fallback_position ||
                                       HB_DIRECTION_IS_BACKWARD (c->buffer->props.direction));

  switch (c->plan->shaper->zero_width_marks)
  {
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_EARLY:
      zero_mark_widths_by_gdef (c->buffer, adjust_offsets_when_zeroing);
      break;

    /* Not currently used for any shaper:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_EARLY:
      zero_mark_widths_by_unicode (c->buffer, adjust_offsets_when_zeroing);
      break;
    */

    default:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_LATE:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_LATE:
      break;
  }

  if (has_positioning)
  {
    hb_glyph_info_t *info = c->buffer->info;
    hb_glyph_position_t *pos = c->buffer->pos;

    /* Change glyph origin to what GPOS expects, apply GPOS, change it back. */

    for (unsigned int i = 0; i < count; i++) {
      c->font->add_glyph_origin_for_direction (info[i].codepoint,
					       HB_DIRECTION_LTR,
					       &pos[i].x_offset,
					       &pos[i].y_offset);
    }

    c->plan->position (c->font, c->buffer);

    for (unsigned int i = 0; i < count; i++) {
      c->font->subtract_glyph_origin_for_direction (info[i].codepoint,
						    HB_DIRECTION_LTR,
						    &pos[i].x_offset,
						    &pos[i].y_offset);
    }

    ret = true;
  }

  switch (c->plan->shaper->zero_width_marks)
  {
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_LATE:
      zero_mark_widths_by_unicode (c->buffer, adjust_offsets_when_zeroing);
      break;

    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_LATE:
      zero_mark_widths_by_gdef (c->buffer, adjust_offsets_when_zeroing);
      break;

    default:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE:
    //case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_UNICODE_EARLY:
    case HB_OT_SHAPE_ZERO_WIDTH_MARKS_BY_GDEF_EARLY:
      break;
  }

  return ret;
}

static inline void
hb_ot_position (hb_ot_shape_context_t *c)
{
  hb_ot_layout_position_start (c->font, c->buffer);

  hb_ot_position_default (c);

  hb_bool_t fallback = !hb_ot_position_complex (c);

  hb_ot_layout_position_finish (c->font, c->buffer);

  if (fallback && c->plan->shaper->fallback_position)
    _hb_ot_shape_fallback_position (c->plan, c->font, c->buffer);

  if (HB_DIRECTION_IS_BACKWARD (c->buffer->props.direction))
    hb_buffer_reverse (c->buffer);

  /* Visual fallback goes here. */

  if (fallback)
    _hb_ot_shape_fallback_kern (c->plan, c->font, c->buffer);

  _hb_buffer_deallocate_gsubgpos_vars (c->buffer);
}


/* Post-process */

static void
hb_ot_hide_default_ignorables (hb_ot_shape_context_t *c)
{
  if (c->buffer->flags & HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES)
    return;

  hb_codepoint_t space;
  enum {
    SPACE_DONT_KNOW,
    SPACE_AVAILABLE,
    SPACE_UNAVAILABLE
  } space_status = SPACE_DONT_KNOW;

  unsigned int count = c->buffer->len;
  hb_glyph_info_t *info = c->buffer->info;
  hb_glyph_position_t *pos = c->buffer->pos;
  unsigned int j = 0;
  for (unsigned int i = 0; i < count; i++)
  {
    if (unlikely (!_hb_glyph_info_ligated (&info[i]) &&
		  _hb_glyph_info_is_default_ignorable (&info[i])))
    {
      if (space_status == SPACE_DONT_KNOW)
	space_status = c->font->get_glyph (' ', 0, &space) ? SPACE_AVAILABLE : SPACE_UNAVAILABLE;

      if (space_status == SPACE_AVAILABLE)
      {
	info[i].codepoint = space;
	pos[i].x_advance = 0;
	pos[i].y_advance = 0;
      }
      else
	continue; /* Delete it. XXX Merge clusters? */
    }
    if (j != i)
    {
      info[j] = info[i];
      pos[j] = pos[i];
    }
    j++;
  }
  c->buffer->len = j;
}


/* Pull it all together! */

static void
hb_ot_shape_internal (hb_ot_shape_context_t *c)
{
  c->buffer->deallocate_var_all ();

  /* Save the original direction, we use it later. */
  c->target_direction = c->buffer->props.direction;

  _hb_buffer_allocate_unicode_vars (c->buffer);

  c->buffer->clear_output ();

  hb_set_unicode_props (c->buffer);
  hb_insert_dotted_circle (c->buffer, c->font);
  hb_form_clusters (c->buffer);

  hb_ensure_native_direction (c->buffer);

  hb_ot_substitute (c);
  hb_ot_position (c);

  hb_ot_hide_default_ignorables (c);

  _hb_buffer_deallocate_unicode_vars (c->buffer);

  c->buffer->props.direction = c->target_direction;

  c->buffer->deallocate_var_all ();
}


hb_bool_t
_hb_ot_shape (hb_shape_plan_t    *shape_plan,
	      hb_font_t          *font,
	      hb_buffer_t        *buffer,
	      const hb_feature_t *features,
	      unsigned int        num_features)
{
  hb_ot_shape_context_t c = {HB_SHAPER_DATA_GET (shape_plan), font, font->face, buffer, features, num_features};
  hb_ot_shape_internal (&c);

  return true;
}


void
hb_ot_shape_plan_collect_lookups (hb_shape_plan_t *shape_plan,
				  hb_tag_t         table_tag,
				  hb_set_t        *lookup_indexes /* OUT */)
{
  /* XXX Does the first part always succeed? */
  HB_SHAPER_DATA_GET (shape_plan)->collect_lookups (table_tag, lookup_indexes);
}


/* TODO Move this to hb-ot-shape-normalize, make it do decompose, and make it public. */
static void
add_char (hb_font_t          *font,
	  hb_unicode_funcs_t *unicode,
	  hb_bool_t           mirror,
	  hb_codepoint_t      u,
	  hb_set_t           *glyphs)
{
  hb_codepoint_t glyph;
  if (font->get_glyph (u, 0, &glyph))
    glyphs->add (glyph);
  if (mirror)
  {
    hb_codepoint_t m = unicode->mirroring (u);
    if (m != u && font->get_glyph (m, 0, &glyph))
      glyphs->add (glyph);
  }
}


void
hb_ot_shape_glyphs_closure (hb_font_t          *font,
			    hb_buffer_t        *buffer,
			    const hb_feature_t *features,
			    unsigned int        num_features,
			    hb_set_t           *glyphs)
{
  hb_ot_shape_plan_t plan;

  const char *shapers[] = {"ot", NULL};
  hb_shape_plan_t *shape_plan = hb_shape_plan_create_cached (font->face, &buffer->props,
							     features, num_features, shapers);

  bool mirror = hb_script_get_horizontal_direction (buffer->props.script) == HB_DIRECTION_RTL;

  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    add_char (font, buffer->unicode, mirror, info[i].codepoint, glyphs);

  hb_set_t lookups;
  lookups.init ();
  hb_ot_shape_plan_collect_lookups (shape_plan, HB_OT_TAG_GSUB, &lookups);

  /* And find transitive closure. */
  hb_set_t copy;
  copy.init ();
  do {
    copy.set (glyphs);
    for (hb_codepoint_t lookup_index = -1; hb_set_next (&lookups, &lookup_index);)
      hb_ot_layout_lookup_substitute_closure (font->face, lookup_index, glyphs);
  } while (!copy.is_equal (glyphs));

  hb_shape_plan_destroy (shape_plan);
}
