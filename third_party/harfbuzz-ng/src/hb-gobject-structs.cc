/*
 * Copyright © 2011  Google, Inc.
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

#include "hb-private.hh"

/* g++ didn't like older gtype.h gcc-only code path. */
#include <glib.h>
#if !GLIB_CHECK_VERSION(2,29,16)
#undef __GNUC__
#undef __GNUC_MINOR__
#define __GNUC__ 2
#define __GNUC_MINOR__ 6
#endif

#include "hb-gobject.h"

#define HB_DEFINE_BOXED_TYPE(name,copy_func,free_func) \
GType \
hb_gobject_##name##_get_type (void) \
{ \
   static gsize type_id = 0; \
   if (g_once_init_enter (&type_id)) { \
      GType id = g_boxed_type_register_static (g_intern_static_string ("hb_" #name "_t"), \
					       (GBoxedCopyFunc) copy_func, \
					       (GBoxedFreeFunc) free_func); \
      g_once_init_leave (&type_id, id); \
   } \
   return type_id; \
}

#define HB_DEFINE_OBJECT_TYPE(name) \
	HB_DEFINE_BOXED_TYPE (name, hb_##name##_reference, hb_##name##_destroy);

HB_DEFINE_OBJECT_TYPE (buffer)
HB_DEFINE_OBJECT_TYPE (blob)
HB_DEFINE_OBJECT_TYPE (face)
HB_DEFINE_OBJECT_TYPE (font)
HB_DEFINE_OBJECT_TYPE (font_funcs)
HB_DEFINE_OBJECT_TYPE (set)
HB_DEFINE_OBJECT_TYPE (shape_plan)
HB_DEFINE_OBJECT_TYPE (unicode_funcs)


static hb_feature_t *feature_reference (hb_feature_t *g)
{
  hb_feature_t *c = (hb_feature_t *) calloc (1, sizeof (hb_feature_t));
  if (unlikely (!c)) return NULL;
  *c = *g;
  return c;
}
static void feature_destroy (hb_feature_t *g) { free (g); }
HB_DEFINE_BOXED_TYPE (feature, feature_reference, feature_destroy)

static hb_glyph_info_t *glyph_info_reference (hb_glyph_info_t *g)
{
  hb_glyph_info_t *c = (hb_glyph_info_t *) calloc (1, sizeof (hb_glyph_info_t));
  if (unlikely (!c)) return NULL;
  *c = *g;
  return c;
}
static void glyph_info_destroy (hb_glyph_info_t *g) { free (g); }
HB_DEFINE_BOXED_TYPE (glyph_info, glyph_info_reference, glyph_info_destroy)

static hb_glyph_position_t *glyph_position_reference (hb_glyph_position_t *g)
{
  hb_glyph_position_t *c = (hb_glyph_position_t *) calloc (1, sizeof (hb_glyph_position_t));
  if (unlikely (!c)) return NULL;
  *c = *g;
  return c;
}
static void glyph_position_destroy (hb_glyph_position_t *g) { free (g); }
HB_DEFINE_BOXED_TYPE (glyph_position, glyph_position_reference, glyph_position_destroy)

static hb_segment_properties_t *segment_properties_reference (hb_segment_properties_t *g)
{
  hb_segment_properties_t *c = (hb_segment_properties_t *) calloc (1, sizeof (hb_segment_properties_t));
  if (unlikely (!c)) return NULL;
  *c = *g;
  return c;
}
static void segment_properties_destroy (hb_segment_properties_t *g) { free (g); }
HB_DEFINE_BOXED_TYPE (segment_properties, segment_properties_reference, segment_properties_destroy)

static hb_user_data_key_t user_data_key_reference (hb_user_data_key_t l) { return l; }
static void user_data_key_destroy (hb_user_data_key_t l) { }
HB_DEFINE_BOXED_TYPE (user_data_key, user_data_key_reference, user_data_key_destroy)


static hb_language_t *language_reference (hb_language_t *l)
{
  hb_language_t *c = (hb_language_t *) calloc (1, sizeof (hb_language_t));
  if (unlikely (!c)) return NULL;
  *c = *l;
  return c;
}
static void language_destroy (hb_language_t *l) { free (l); }
HB_DEFINE_BOXED_TYPE (language, language_reference, language_destroy)
