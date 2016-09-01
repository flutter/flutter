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

#ifndef HB_GOBJECT_H_IN
#error "Include <hb-gobject.h> instead."
#endif

#ifndef HB_GOBJECT_STRUCTS_H
#define HB_GOBJECT_STRUCTS_H

#include "hb.h"

#include <glib-object.h>

HB_BEGIN_DECLS


/* Object types */

GType hb_gobject_blob_get_type (void);
#define HB_GOBJECT_TYPE_BLOB (hb_gobject_blob_get_type ())

GType hb_gobject_buffer_get_type (void);
#define HB_GOBJECT_TYPE_BUFFER (hb_gobject_buffer_get_type ())

GType hb_gobject_face_get_type (void);
#define HB_GOBJECT_TYPE_FACE (hb_gobject_face_get_type ())

GType hb_gobject_font_get_type (void);
#define HB_GOBJECT_TYPE_FONT (hb_gobject_font_get_type ())

GType hb_gobject_font_funcs_get_type (void);
#define HB_GOBJECT_TYPE_FONT_FUNCS (hb_gobject_font_funcs_get_type ())

GType hb_gobject_set_get_type (void);
#define HB_GOBJECT_TYPE_SET (hb_gobject_set_get_type ())

GType hb_gobject_shape_plan_get_type (void);
#define HB_GOBJECT_TYPE_SHAPE_PLAN (hb_gobject_shape_plan_get_type ())

GType hb_gobject_unicode_funcs_get_type (void);
#define HB_GOBJECT_TYPE_UNICODE_FUNCS (hb_gobject_unicode_funcs_get_type ())

/* Value types */

GType hb_gobject_feature_get_type (void);
#define HB_GOBJECT_TYPE_FEATURE (hb_gobject_feature_get_type ())

GType hb_gobject_glyph_info_get_type (void);
#define HB_GOBJECT_TYPE_GLYPH_INFO (hb_gobject_glyph_info_get_type ())

GType hb_gobject_glyph_position_get_type (void);
#define HB_GOBJECT_TYPE_GLYPH_POSITION (hb_gobject_glyph_position_get_type ())

GType hb_gobject_segment_properties_get_type (void);
#define HB_GOBJECT_TYPE_SEGMENT_PROPERTIES (hb_gobject_segment_properties_get_type ())

GType hb_gobject_user_data_key_get_type (void);
#define HB_GOBJECT_TYPE_USER_DATA_KEY (hb_gobject_user_data_key_get_type ())

/* Currently gobject-introspection doesn't understand that hb_language_t
 * can be passed by-value.  As such we box it up.  May remove in the
 * future.
 *
 *   https://bugzilla.gnome.org/show_bug.cgi?id=707656
 */
GType hb_gobject_language_get_type (void);
#define HB_GOBJECT_TYPE_LANGUAGE (hb_gobject_language_get_type ())

HB_END_DECLS

#endif /* HB_GOBJECT_H */
