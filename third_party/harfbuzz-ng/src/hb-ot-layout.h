/*
 * Copyright © 2007,2008,2009  Red Hat, Inc.
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
 */

#ifndef HB_OT_H_IN
#error "Include <hb-ot.h> instead."
#endif

#ifndef HB_OT_LAYOUT_H
#define HB_OT_LAYOUT_H

#include "hb.h"

#include "hb-ot-tag.h"

HB_BEGIN_DECLS


#define HB_OT_TAG_GDEF HB_TAG('G','D','E','F')
#define HB_OT_TAG_GSUB HB_TAG('G','S','U','B')
#define HB_OT_TAG_GPOS HB_TAG('G','P','O','S')
#define HB_OT_TAG_JSTF HB_TAG('J','S','T','F')


/*
 * GDEF
 */

hb_bool_t
hb_ot_layout_has_glyph_classes (hb_face_t *face);

typedef enum {
  HB_OT_LAYOUT_GLYPH_CLASS_UNCLASSIFIED	= 0,
  HB_OT_LAYOUT_GLYPH_CLASS_BASE_GLYPH	= 1,
  HB_OT_LAYOUT_GLYPH_CLASS_LIGATURE	= 2,
  HB_OT_LAYOUT_GLYPH_CLASS_MARK		= 3,
  HB_OT_LAYOUT_GLYPH_CLASS_COMPONENT	= 4
} hb_ot_layout_glyph_class_t;

hb_ot_layout_glyph_class_t
hb_ot_layout_get_glyph_class (hb_face_t      *face,
			      hb_codepoint_t  glyph);

void
hb_ot_layout_get_glyphs_in_class (hb_face_t                  *face,
				  hb_ot_layout_glyph_class_t  klass,
				  hb_set_t                   *glyphs /* OUT */);


/* Not that useful.  Provides list of attach points for a glyph that a
 * client may want to cache */
unsigned int
hb_ot_layout_get_attach_points (hb_face_t      *face,
				hb_codepoint_t  glyph,
				unsigned int    start_offset,
				unsigned int   *point_count /* IN/OUT */,
				unsigned int   *point_array /* OUT */);

/* Ligature caret positions */
unsigned int
hb_ot_layout_get_ligature_carets (hb_font_t      *font,
				  hb_direction_t  direction,
				  hb_codepoint_t  glyph,
				  unsigned int    start_offset,
				  unsigned int   *caret_count /* IN/OUT */,
				  hb_position_t  *caret_array /* OUT */);


/*
 * GSUB/GPOS feature query and enumeration interface
 */

#define HB_OT_LAYOUT_NO_SCRIPT_INDEX		0xFFFFu
#define HB_OT_LAYOUT_NO_FEATURE_INDEX		0xFFFFu
#define HB_OT_LAYOUT_DEFAULT_LANGUAGE_INDEX	0xFFFFu

unsigned int
hb_ot_layout_table_get_script_tags (hb_face_t    *face,
				    hb_tag_t      table_tag,
				    unsigned int  start_offset,
				    unsigned int *script_count /* IN/OUT */,
				    hb_tag_t     *script_tags /* OUT */);

hb_bool_t
hb_ot_layout_table_find_script (hb_face_t    *face,
				hb_tag_t      table_tag,
				hb_tag_t      script_tag,
				unsigned int *script_index);

/* Like find_script, but takes zero-terminated array of scripts to test */
hb_bool_t
hb_ot_layout_table_choose_script (hb_face_t      *face,
				  hb_tag_t        table_tag,
				  const hb_tag_t *script_tags,
				  unsigned int   *script_index,
				  hb_tag_t       *chosen_script);

unsigned int
hb_ot_layout_table_get_feature_tags (hb_face_t    *face,
				     hb_tag_t      table_tag,
				     unsigned int  start_offset,
				     unsigned int *feature_count /* IN/OUT */,
				     hb_tag_t     *feature_tags /* OUT */);

unsigned int
hb_ot_layout_script_get_language_tags (hb_face_t    *face,
				       hb_tag_t      table_tag,
				       unsigned int  script_index,
				       unsigned int  start_offset,
				       unsigned int *language_count /* IN/OUT */,
				       hb_tag_t     *language_tags /* OUT */);

hb_bool_t
hb_ot_layout_script_find_language (hb_face_t    *face,
				   hb_tag_t      table_tag,
				   unsigned int  script_index,
				   hb_tag_t      language_tag,
				   unsigned int *language_index);

hb_bool_t
hb_ot_layout_language_get_required_feature_index (hb_face_t    *face,
						  hb_tag_t      table_tag,
						  unsigned int  script_index,
						  unsigned int  language_index,
						  unsigned int *feature_index);

hb_bool_t
hb_ot_layout_language_get_required_feature (hb_face_t    *face,
					    hb_tag_t      table_tag,
					    unsigned int  script_index,
					    unsigned int  language_index,
					    unsigned int *feature_index,
					    hb_tag_t     *feature_tag);

unsigned int
hb_ot_layout_language_get_feature_indexes (hb_face_t    *face,
					   hb_tag_t      table_tag,
					   unsigned int  script_index,
					   unsigned int  language_index,
					   unsigned int  start_offset,
					   unsigned int *feature_count /* IN/OUT */,
					   unsigned int *feature_indexes /* OUT */);

unsigned int
hb_ot_layout_language_get_feature_tags (hb_face_t    *face,
					hb_tag_t      table_tag,
					unsigned int  script_index,
					unsigned int  language_index,
					unsigned int  start_offset,
					unsigned int *feature_count /* IN/OUT */,
					hb_tag_t     *feature_tags /* OUT */);

hb_bool_t
hb_ot_layout_language_find_feature (hb_face_t    *face,
				    hb_tag_t      table_tag,
				    unsigned int  script_index,
				    unsigned int  language_index,
				    hb_tag_t      feature_tag,
				    unsigned int *feature_index);

unsigned int
hb_ot_layout_feature_get_lookups (hb_face_t    *face,
				  hb_tag_t      table_tag,
				  unsigned int  feature_index,
				  unsigned int  start_offset,
				  unsigned int *lookup_count /* IN/OUT */,
				  unsigned int *lookup_indexes /* OUT */);

unsigned int
hb_ot_layout_table_get_lookup_count (hb_face_t    *face,
				     hb_tag_t      table_tag);


void
hb_ot_layout_collect_lookups (hb_face_t      *face,
			      hb_tag_t        table_tag,
			      const hb_tag_t *scripts,
			      const hb_tag_t *languages,
			      const hb_tag_t *features,
			      hb_set_t       *lookup_indexes /* OUT */);

void
hb_ot_layout_lookup_collect_glyphs (hb_face_t    *face,
				    hb_tag_t      table_tag,
				    unsigned int  lookup_index,
				    hb_set_t     *glyphs_before, /* OUT. May be NULL */
				    hb_set_t     *glyphs_input,  /* OUT. May be NULL */
				    hb_set_t     *glyphs_after,  /* OUT. May be NULL */
				    hb_set_t     *glyphs_output  /* OUT. May be NULL */);

#ifdef HB_NOT_IMPLEMENTED
typedef struct
{
  const hb_codepoint_t *before,
  unsigned int          before_length,
  const hb_codepoint_t *input,
  unsigned int          input_length,
  const hb_codepoint_t *after,
  unsigned int          after_length,
} hb_ot_layout_glyph_sequence_t;

typedef hb_bool_t
(*hb_ot_layout_glyph_sequence_func_t) (hb_font_t    *font,
				       hb_tag_t      table_tag,
				       unsigned int  lookup_index,
				       const hb_ot_layout_glyph_sequence_t *sequence,
				       void         *user_data);

void
Xhb_ot_layout_lookup_enumerate_sequences (hb_face_t    *face,
					 hb_tag_t      table_tag,
					 unsigned int  lookup_index,
					 hb_ot_layout_glyph_sequence_func_t callback,
					 void         *user_data);
#endif


/*
 * GSUB
 */

hb_bool_t
hb_ot_layout_has_substitution (hb_face_t *face);

hb_bool_t
hb_ot_layout_lookup_would_substitute (hb_face_t            *face,
				      unsigned int          lookup_index,
				      const hb_codepoint_t *glyphs,
				      unsigned int          glyphs_length,
				      hb_bool_t             zero_context);

void
hb_ot_layout_lookup_substitute_closure (hb_face_t    *face,
				        unsigned int  lookup_index,
				        hb_set_t     *glyphs
					/*TODO , hb_bool_t  inclusive */);

#ifdef HB_NOT_IMPLEMENTED
/* Note: You better have GDEF when using this API, or marks won't do much. */
hb_bool_t
Xhb_ot_layout_lookup_substitute (hb_font_t            *font,
				unsigned int          lookup_index,
				const hb_ot_layout_glyph_sequence_t *sequence,
				unsigned int          out_size,
				hb_codepoint_t       *glyphs_out,   /* OUT */
				unsigned int         *clusters_out, /* OUT */
				unsigned int         *out_length    /* OUT */);
#endif


/*
 * GPOS
 */

hb_bool_t
hb_ot_layout_has_positioning (hb_face_t *face);

#ifdef HB_NOT_IMPLEMENTED
/* Note: You better have GDEF when using this API, or marks won't do much. */
hb_bool_t
Xhb_ot_layout_lookup_position (hb_font_t            *font,
			      unsigned int          lookup_index,
			      const hb_ot_layout_glyph_sequence_t *sequence,
			      hb_glyph_position_t  *positions /* IN / OUT */);
#endif

/* Optical 'size' feature info.  Returns true if found.
 * http://www.microsoft.com/typography/otspec/features_pt.htm#size */
hb_bool_t
hb_ot_layout_get_size_params (hb_face_t    *face,
			      unsigned int *design_size,       /* OUT.  May be NULL */
			      unsigned int *subfamily_id,      /* OUT.  May be NULL */
			      unsigned int *subfamily_name_id, /* OUT.  May be NULL */
			      unsigned int *range_start,       /* OUT.  May be NULL */
			      unsigned int *range_end          /* OUT.  May be NULL */);


HB_END_DECLS

#endif /* HB_OT_LAYOUT_H */
