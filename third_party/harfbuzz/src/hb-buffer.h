/*
 * Copyright © 1998-2004  David Turner and Werner Lemberg
 * Copyright © 2004,2007,2009  Red Hat, Inc.
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
 * Red Hat Author(s): Owen Taylor, Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_H_IN
#error "Include <hb.h> instead."
#endif

#ifndef HB_BUFFER_H
#define HB_BUFFER_H

#include "hb-common.h"
#include "hb-unicode.h"
#include "hb-font.h"

HB_BEGIN_DECLS


typedef struct hb_glyph_info_t {
  hb_codepoint_t codepoint;
  hb_mask_t      mask;
  uint32_t       cluster;

  /*< private >*/
  hb_var_int_t   var1;
  hb_var_int_t   var2;
} hb_glyph_info_t;

typedef struct hb_glyph_position_t {
  hb_position_t  x_advance;
  hb_position_t  y_advance;
  hb_position_t  x_offset;
  hb_position_t  y_offset;

  /*< private >*/
  hb_var_int_t   var;
} hb_glyph_position_t;


typedef struct hb_segment_properties_t {
  hb_direction_t  direction;
  hb_script_t     script;
  hb_language_t   language;
  /*< private >*/
  void           *reserved1;
  void           *reserved2;
} hb_segment_properties_t;

#define HB_SEGMENT_PROPERTIES_DEFAULT {HB_DIRECTION_INVALID, \
				       HB_SCRIPT_INVALID, \
				       HB_LANGUAGE_INVALID, \
				       NULL, \
				       NULL}

hb_bool_t
hb_segment_properties_equal (const hb_segment_properties_t *a,
			     const hb_segment_properties_t *b);

unsigned int
hb_segment_properties_hash (const hb_segment_properties_t *p);



/*
 * hb_buffer_t
 */

typedef struct hb_buffer_t hb_buffer_t;

hb_buffer_t *
hb_buffer_create (void);

hb_buffer_t *
hb_buffer_get_empty (void);

hb_buffer_t *
hb_buffer_reference (hb_buffer_t *buffer);

void
hb_buffer_destroy (hb_buffer_t *buffer);

hb_bool_t
hb_buffer_set_user_data (hb_buffer_t        *buffer,
			 hb_user_data_key_t *key,
			 void *              data,
			 hb_destroy_func_t   destroy,
			 hb_bool_t           replace);

void *
hb_buffer_get_user_data (hb_buffer_t        *buffer,
			 hb_user_data_key_t *key);


typedef enum {
  HB_BUFFER_CONTENT_TYPE_INVALID = 0,
  HB_BUFFER_CONTENT_TYPE_UNICODE,
  HB_BUFFER_CONTENT_TYPE_GLYPHS
} hb_buffer_content_type_t;

void
hb_buffer_set_content_type (hb_buffer_t              *buffer,
			    hb_buffer_content_type_t  content_type);

hb_buffer_content_type_t
hb_buffer_get_content_type (hb_buffer_t *buffer);


void
hb_buffer_set_unicode_funcs (hb_buffer_t        *buffer,
			     hb_unicode_funcs_t *unicode_funcs);

hb_unicode_funcs_t *
hb_buffer_get_unicode_funcs (hb_buffer_t        *buffer);

void
hb_buffer_set_direction (hb_buffer_t    *buffer,
			 hb_direction_t  direction);

hb_direction_t
hb_buffer_get_direction (hb_buffer_t *buffer);

void
hb_buffer_set_script (hb_buffer_t *buffer,
		      hb_script_t  script);

hb_script_t
hb_buffer_get_script (hb_buffer_t *buffer);

void
hb_buffer_set_language (hb_buffer_t   *buffer,
			hb_language_t  language);


hb_language_t
hb_buffer_get_language (hb_buffer_t *buffer);

void
hb_buffer_set_segment_properties (hb_buffer_t *buffer,
				  const hb_segment_properties_t *props);

void
hb_buffer_get_segment_properties (hb_buffer_t *buffer,
				  hb_segment_properties_t *props);

void
hb_buffer_guess_segment_properties (hb_buffer_t *buffer);


typedef enum { /*< flags >*/
  HB_BUFFER_FLAG_DEFAULT			= 0x00000000u,
  HB_BUFFER_FLAG_BOT				= 0x00000001u, /* Beginning-of-text */
  HB_BUFFER_FLAG_EOT				= 0x00000002u, /* End-of-text */
  HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES	= 0x00000004u
} hb_buffer_flags_t;

void
hb_buffer_set_flags (hb_buffer_t       *buffer,
		     hb_buffer_flags_t  flags);

hb_buffer_flags_t
hb_buffer_get_flags (hb_buffer_t *buffer);



#define HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT 0xFFFDu

/* Sets codepoint used to replace invalid UTF-8/16/32 entries.
 * Default is 0xFFFDu. */
void
hb_buffer_set_replacement_codepoint (hb_buffer_t    *buffer,
				     hb_codepoint_t  replacement);

hb_codepoint_t
hb_buffer_get_replacement_codepoint (hb_buffer_t    *buffer);


/* Resets the buffer.  Afterwards it's as if it was just created,
 * except that it has a larger buffer allocated perhaps... */
void
hb_buffer_reset (hb_buffer_t *buffer);

/* Like reset, but does NOT clear unicode_funcs and replacement_codepoint. */
void
hb_buffer_clear_contents (hb_buffer_t *buffer);

/* Returns false if allocation failed */
hb_bool_t
hb_buffer_pre_allocate (hb_buffer_t  *buffer,
		        unsigned int  size);


/* Returns false if allocation has failed before */
hb_bool_t
hb_buffer_allocation_successful (hb_buffer_t  *buffer);

void
hb_buffer_reverse (hb_buffer_t *buffer);

void
hb_buffer_reverse_clusters (hb_buffer_t *buffer);


/* Filling the buffer in */

void
hb_buffer_add (hb_buffer_t    *buffer,
	       hb_codepoint_t  codepoint,
	       unsigned int    cluster);

void
hb_buffer_add_utf8 (hb_buffer_t  *buffer,
		    const char   *text,
		    int           text_length,
		    unsigned int  item_offset,
		    int           item_length);

void
hb_buffer_add_utf16 (hb_buffer_t    *buffer,
		     const uint16_t *text,
		     int             text_length,
		     unsigned int    item_offset,
		     int             item_length);

void
hb_buffer_add_utf32 (hb_buffer_t    *buffer,
		     const uint32_t *text,
		     int             text_length,
		     unsigned int    item_offset,
		     int             item_length);

/* Allows only access to first 256 Unicode codepoints. */
void
hb_buffer_add_latin1 (hb_buffer_t   *buffer,
		      const uint8_t *text,
		      int            text_length,
		      unsigned int   item_offset,
		      int            item_length);

/* Like add_utf32 but does NOT check for invalid Unicode codepoints. */
void
hb_buffer_add_codepoints (hb_buffer_t          *buffer,
			  const hb_codepoint_t *text,
			  int                   text_length,
			  unsigned int          item_offset,
			  int                   item_length);


/* Clears any new items added at the end */
hb_bool_t
hb_buffer_set_length (hb_buffer_t  *buffer,
		      unsigned int  length);

/* Return value valid as long as buffer not modified */
unsigned int
hb_buffer_get_length (hb_buffer_t *buffer);

/* Getting glyphs out of the buffer */

/* Return value valid as long as buffer not modified */
hb_glyph_info_t *
hb_buffer_get_glyph_infos (hb_buffer_t  *buffer,
                           unsigned int *length);

/* Return value valid as long as buffer not modified */
hb_glyph_position_t *
hb_buffer_get_glyph_positions (hb_buffer_t  *buffer,
                               unsigned int *length);


/* Reorders a glyph buffer to have canonical in-cluster glyph order / position.
 * The resulting clusters should behave identical to pre-reordering clusters.
 * NOTE: This has nothing to do with Unicode normalization. */
void
hb_buffer_normalize_glyphs (hb_buffer_t *buffer);


/*
 * Serialize
 */

typedef enum { /*< flags >*/
  HB_BUFFER_SERIALIZE_FLAG_DEFAULT		= 0x00000000u,
  HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS		= 0x00000001u,
  HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS		= 0x00000002u,
  HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES	= 0x00000004u
} hb_buffer_serialize_flags_t;

typedef enum {
  HB_BUFFER_SERIALIZE_FORMAT_TEXT	= HB_TAG('T','E','X','T'),
  HB_BUFFER_SERIALIZE_FORMAT_JSON	= HB_TAG('J','S','O','N'),
  HB_BUFFER_SERIALIZE_FORMAT_INVALID	= HB_TAG_NONE
} hb_buffer_serialize_format_t;

/* len=-1 means str is NUL-terminated. */
hb_buffer_serialize_format_t
hb_buffer_serialize_format_from_string (const char *str, int len);

const char *
hb_buffer_serialize_format_to_string (hb_buffer_serialize_format_t format);

const char **
hb_buffer_serialize_list_formats (void);

/* Returns number of items, starting at start, that were serialized. */
unsigned int
hb_buffer_serialize_glyphs (hb_buffer_t *buffer,
			    unsigned int start,
			    unsigned int end,
			    char *buf,
			    unsigned int buf_size,
			    unsigned int *buf_consumed, /* May be NULL */
			    hb_font_t *font, /* May be NULL */
			    hb_buffer_serialize_format_t format,
			    hb_buffer_serialize_flags_t flags);

hb_bool_t
hb_buffer_deserialize_glyphs (hb_buffer_t *buffer,
			      const char *buf,
			      int buf_len, /* -1 means nul-terminated */
			      const char **end_ptr, /* May be NULL */
			      hb_font_t *font, /* May be NULL */
			      hb_buffer_serialize_format_t format);


HB_END_DECLS

#endif /* HB_BUFFER_H */
