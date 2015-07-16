/*
 * Copyright © 2009  Red Hat, Inc.
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

#ifndef HB_H_IN
#error "Include <hb.h> instead."
#endif

#ifndef HB_FONT_H
#define HB_FONT_H

#include "hb-common.h"
#include "hb-face.h"

HB_BEGIN_DECLS


typedef struct hb_font_t hb_font_t;


/*
 * hb_font_funcs_t
 */

typedef struct hb_font_funcs_t hb_font_funcs_t;

hb_font_funcs_t *
hb_font_funcs_create (void);

hb_font_funcs_t *
hb_font_funcs_get_empty (void);

hb_font_funcs_t *
hb_font_funcs_reference (hb_font_funcs_t *ffuncs);

void
hb_font_funcs_destroy (hb_font_funcs_t *ffuncs);

hb_bool_t
hb_font_funcs_set_user_data (hb_font_funcs_t    *ffuncs,
			     hb_user_data_key_t *key,
			     void *              data,
			     hb_destroy_func_t   destroy,
			     hb_bool_t           replace);


void *
hb_font_funcs_get_user_data (hb_font_funcs_t    *ffuncs,
			     hb_user_data_key_t *key);


void
hb_font_funcs_make_immutable (hb_font_funcs_t *ffuncs);

hb_bool_t
hb_font_funcs_is_immutable (hb_font_funcs_t *ffuncs);


/* glyph extents */

typedef struct hb_glyph_extents_t
{
  hb_position_t x_bearing;
  hb_position_t y_bearing;
  hb_position_t width;
  hb_position_t height;
} hb_glyph_extents_t;


/* func types */

typedef hb_bool_t (*hb_font_get_glyph_func_t) (hb_font_t *font, void *font_data,
					       hb_codepoint_t unicode, hb_codepoint_t variation_selector,
					       hb_codepoint_t *glyph,
					       void *user_data);


typedef hb_position_t (*hb_font_get_glyph_advance_func_t) (hb_font_t *font, void *font_data,
							   hb_codepoint_t glyph,
							   void *user_data);
typedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_h_advance_func_t;
typedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_v_advance_func_t;

typedef hb_bool_t (*hb_font_get_glyph_origin_func_t) (hb_font_t *font, void *font_data,
						      hb_codepoint_t glyph,
						      hb_position_t *x, hb_position_t *y,
						      void *user_data);
typedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_h_origin_func_t;
typedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_v_origin_func_t;

typedef hb_position_t (*hb_font_get_glyph_kerning_func_t) (hb_font_t *font, void *font_data,
							   hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
							   void *user_data);
typedef hb_font_get_glyph_kerning_func_t hb_font_get_glyph_h_kerning_func_t;
typedef hb_font_get_glyph_kerning_func_t hb_font_get_glyph_v_kerning_func_t;


typedef hb_bool_t (*hb_font_get_glyph_extents_func_t) (hb_font_t *font, void *font_data,
						       hb_codepoint_t glyph,
						       hb_glyph_extents_t *extents,
						       void *user_data);
typedef hb_bool_t (*hb_font_get_glyph_contour_point_func_t) (hb_font_t *font, void *font_data,
							     hb_codepoint_t glyph, unsigned int point_index,
							     hb_position_t *x, hb_position_t *y,
							     void *user_data);


typedef hb_bool_t (*hb_font_get_glyph_name_func_t) (hb_font_t *font, void *font_data,
						    hb_codepoint_t glyph,
						    char *name, unsigned int size,
						    void *user_data);
typedef hb_bool_t (*hb_font_get_glyph_from_name_func_t) (hb_font_t *font, void *font_data,
							 const char *name, int len, /* -1 means nul-terminated */
							 hb_codepoint_t *glyph,
							 void *user_data);


/* func setters */

/**
 * hb_font_funcs_set_glyph_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_func (hb_font_funcs_t *ffuncs,
			      hb_font_get_glyph_func_t func,
			      void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_h_advance_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_h_advance_func (hb_font_funcs_t *ffuncs,
					hb_font_get_glyph_h_advance_func_t func,
					void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_v_advance_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_v_advance_func (hb_font_funcs_t *ffuncs,
					hb_font_get_glyph_v_advance_func_t func,
					void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_h_origin_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_h_origin_func (hb_font_funcs_t *ffuncs,
				       hb_font_get_glyph_h_origin_func_t func,
				       void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_v_origin_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_v_origin_func (hb_font_funcs_t *ffuncs,
				       hb_font_get_glyph_v_origin_func_t func,
				       void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_h_kerning_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_h_kerning_func (hb_font_funcs_t *ffuncs,
					hb_font_get_glyph_h_kerning_func_t func,
					void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_v_kerning_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_v_kerning_func (hb_font_funcs_t *ffuncs,
					hb_font_get_glyph_v_kerning_func_t func,
					void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_extents_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_extents_func (hb_font_funcs_t *ffuncs,
				      hb_font_get_glyph_extents_func_t func,
				      void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_contour_point_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_contour_point_func (hb_font_funcs_t *ffuncs,
					    hb_font_get_glyph_contour_point_func_t func,
					    void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_name_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_name_func (hb_font_funcs_t *ffuncs,
				   hb_font_get_glyph_name_func_t func,
				   void *user_data, hb_destroy_func_t destroy);

/**
 * hb_font_funcs_set_glyph_from_name_func:
 * @ffuncs: font functions.
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_font_funcs_set_glyph_from_name_func (hb_font_funcs_t *ffuncs,
					hb_font_get_glyph_from_name_func_t func,
					void *user_data, hb_destroy_func_t destroy);


/* func dispatch */

hb_bool_t
hb_font_get_glyph (hb_font_t *font,
		   hb_codepoint_t unicode, hb_codepoint_t variation_selector,
		   hb_codepoint_t *glyph);

hb_position_t
hb_font_get_glyph_h_advance (hb_font_t *font,
			     hb_codepoint_t glyph);
hb_position_t
hb_font_get_glyph_v_advance (hb_font_t *font,
			     hb_codepoint_t glyph);

hb_bool_t
hb_font_get_glyph_h_origin (hb_font_t *font,
			    hb_codepoint_t glyph,
			    hb_position_t *x, hb_position_t *y);
hb_bool_t
hb_font_get_glyph_v_origin (hb_font_t *font,
			    hb_codepoint_t glyph,
			    hb_position_t *x, hb_position_t *y);

hb_position_t
hb_font_get_glyph_h_kerning (hb_font_t *font,
			     hb_codepoint_t left_glyph, hb_codepoint_t right_glyph);
hb_position_t
hb_font_get_glyph_v_kerning (hb_font_t *font,
			     hb_codepoint_t top_glyph, hb_codepoint_t bottom_glyph);

hb_bool_t
hb_font_get_glyph_extents (hb_font_t *font,
			   hb_codepoint_t glyph,
			   hb_glyph_extents_t *extents);

hb_bool_t
hb_font_get_glyph_contour_point (hb_font_t *font,
				 hb_codepoint_t glyph, unsigned int point_index,
				 hb_position_t *x, hb_position_t *y);

hb_bool_t
hb_font_get_glyph_name (hb_font_t *font,
			hb_codepoint_t glyph,
			char *name, unsigned int size);
hb_bool_t
hb_font_get_glyph_from_name (hb_font_t *font,
			     const char *name, int len, /* -1 means nul-terminated */
			     hb_codepoint_t *glyph);


/* high-level funcs, with fallback */

void
hb_font_get_glyph_advance_for_direction (hb_font_t *font,
					 hb_codepoint_t glyph,
					 hb_direction_t direction,
					 hb_position_t *x, hb_position_t *y);
void
hb_font_get_glyph_origin_for_direction (hb_font_t *font,
					hb_codepoint_t glyph,
					hb_direction_t direction,
					hb_position_t *x, hb_position_t *y);
void
hb_font_add_glyph_origin_for_direction (hb_font_t *font,
					hb_codepoint_t glyph,
					hb_direction_t direction,
					hb_position_t *x, hb_position_t *y);
void
hb_font_subtract_glyph_origin_for_direction (hb_font_t *font,
					     hb_codepoint_t glyph,
					     hb_direction_t direction,
					     hb_position_t *x, hb_position_t *y);

void
hb_font_get_glyph_kerning_for_direction (hb_font_t *font,
					 hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
					 hb_direction_t direction,
					 hb_position_t *x, hb_position_t *y);

hb_bool_t
hb_font_get_glyph_extents_for_origin (hb_font_t *font,
				      hb_codepoint_t glyph,
				      hb_direction_t direction,
				      hb_glyph_extents_t *extents);

hb_bool_t
hb_font_get_glyph_contour_point_for_origin (hb_font_t *font,
					    hb_codepoint_t glyph, unsigned int point_index,
					    hb_direction_t direction,
					    hb_position_t *x, hb_position_t *y);

/* Generates gidDDD if glyph has no name. */
void
hb_font_glyph_to_string (hb_font_t *font,
			 hb_codepoint_t glyph,
			 char *s, unsigned int size);
/* Parses gidDDD and uniUUUU strings automatically. */
hb_bool_t
hb_font_glyph_from_string (hb_font_t *font,
			   const char *s, int len, /* -1 means nul-terminated */
			   hb_codepoint_t *glyph);


/*
 * hb_font_t
 */

/* Fonts are very light-weight objects */

hb_font_t *
hb_font_create (hb_face_t *face);

hb_font_t *
hb_font_create_sub_font (hb_font_t *parent);

hb_font_t *
hb_font_get_empty (void);

hb_font_t *
hb_font_reference (hb_font_t *font);

void
hb_font_destroy (hb_font_t *font);

hb_bool_t
hb_font_set_user_data (hb_font_t          *font,
		       hb_user_data_key_t *key,
		       void *              data,
		       hb_destroy_func_t   destroy,
		       hb_bool_t           replace);


void *
hb_font_get_user_data (hb_font_t          *font,
		       hb_user_data_key_t *key);

void
hb_font_make_immutable (hb_font_t *font);

hb_bool_t
hb_font_is_immutable (hb_font_t *font);

hb_font_t *
hb_font_get_parent (hb_font_t *font);

hb_face_t *
hb_font_get_face (hb_font_t *font);


void
hb_font_set_funcs (hb_font_t         *font,
		   hb_font_funcs_t   *klass,
		   void              *font_data,
		   hb_destroy_func_t  destroy);

/* Be *very* careful with this function! */
void
hb_font_set_funcs_data (hb_font_t         *font,
		        void              *font_data,
		        hb_destroy_func_t  destroy);


void
hb_font_set_scale (hb_font_t *font,
		   int x_scale,
		   int y_scale);

void
hb_font_get_scale (hb_font_t *font,
		   int *x_scale,
		   int *y_scale);

/*
 * A zero value means "no hinting in that direction"
 */
void
hb_font_set_ppem (hb_font_t *font,
		  unsigned int x_ppem,
		  unsigned int y_ppem);

void
hb_font_get_ppem (hb_font_t *font,
		  unsigned int *x_ppem,
		  unsigned int *y_ppem);


HB_END_DECLS

#endif /* HB_FONT_H */
