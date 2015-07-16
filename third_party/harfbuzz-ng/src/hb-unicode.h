/*
 * Copyright © 2009  Red Hat, Inc.
 * Copyright © 2011  Codethink Limited
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
 * Red Hat Author(s): Behdad Esfahbod
 * Codethink Author(s): Ryan Lortie
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_H_IN
#error "Include <hb.h> instead."
#endif

#ifndef HB_UNICODE_H
#define HB_UNICODE_H

#include "hb-common.h"

HB_BEGIN_DECLS


/* hb_unicode_general_category_t */

/* Unicode Character Database property: General_Category (gc) */
typedef enum
{
  HB_UNICODE_GENERAL_CATEGORY_CONTROL,			/* Cc */
  HB_UNICODE_GENERAL_CATEGORY_FORMAT,			/* Cf */
  HB_UNICODE_GENERAL_CATEGORY_UNASSIGNED,		/* Cn */
  HB_UNICODE_GENERAL_CATEGORY_PRIVATE_USE,		/* Co */
  HB_UNICODE_GENERAL_CATEGORY_SURROGATE,		/* Cs */
  HB_UNICODE_GENERAL_CATEGORY_LOWERCASE_LETTER,		/* Ll */
  HB_UNICODE_GENERAL_CATEGORY_MODIFIER_LETTER,		/* Lm */
  HB_UNICODE_GENERAL_CATEGORY_OTHER_LETTER,		/* Lo */
  HB_UNICODE_GENERAL_CATEGORY_TITLECASE_LETTER,		/* Lt */
  HB_UNICODE_GENERAL_CATEGORY_UPPERCASE_LETTER,		/* Lu */
  HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK,		/* Mc */
  HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK,		/* Me */
  HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK,		/* Mn */
  HB_UNICODE_GENERAL_CATEGORY_DECIMAL_NUMBER,		/* Nd */
  HB_UNICODE_GENERAL_CATEGORY_LETTER_NUMBER,		/* Nl */
  HB_UNICODE_GENERAL_CATEGORY_OTHER_NUMBER,		/* No */
  HB_UNICODE_GENERAL_CATEGORY_CONNECT_PUNCTUATION,	/* Pc */
  HB_UNICODE_GENERAL_CATEGORY_DASH_PUNCTUATION,		/* Pd */
  HB_UNICODE_GENERAL_CATEGORY_CLOSE_PUNCTUATION,	/* Pe */
  HB_UNICODE_GENERAL_CATEGORY_FINAL_PUNCTUATION,	/* Pf */
  HB_UNICODE_GENERAL_CATEGORY_INITIAL_PUNCTUATION,	/* Pi */
  HB_UNICODE_GENERAL_CATEGORY_OTHER_PUNCTUATION,	/* Po */
  HB_UNICODE_GENERAL_CATEGORY_OPEN_PUNCTUATION,		/* Ps */
  HB_UNICODE_GENERAL_CATEGORY_CURRENCY_SYMBOL,		/* Sc */
  HB_UNICODE_GENERAL_CATEGORY_MODIFIER_SYMBOL,		/* Sk */
  HB_UNICODE_GENERAL_CATEGORY_MATH_SYMBOL,		/* Sm */
  HB_UNICODE_GENERAL_CATEGORY_OTHER_SYMBOL,		/* So */
  HB_UNICODE_GENERAL_CATEGORY_LINE_SEPARATOR,		/* Zl */
  HB_UNICODE_GENERAL_CATEGORY_PARAGRAPH_SEPARATOR,	/* Zp */
  HB_UNICODE_GENERAL_CATEGORY_SPACE_SEPARATOR		/* Zs */
} hb_unicode_general_category_t;

/* hb_unicode_combining_class_t */

/* Note: newer versions of Unicode may add new values.  Clients should be ready to handle
 * any value in the 0..254 range being returned from hb_unicode_combining_class().
 */

/* Unicode Character Database property: Canonical_Combining_Class (ccc) */
typedef enum
{
  HB_UNICODE_COMBINING_CLASS_NOT_REORDERED	= 0,
  HB_UNICODE_COMBINING_CLASS_OVERLAY		= 1,
  HB_UNICODE_COMBINING_CLASS_NUKTA		= 7,
  HB_UNICODE_COMBINING_CLASS_KANA_VOICING	= 8,
  HB_UNICODE_COMBINING_CLASS_VIRAMA		= 9,

  /* Hebrew */
  HB_UNICODE_COMBINING_CLASS_CCC10	=  10,
  HB_UNICODE_COMBINING_CLASS_CCC11	=  11,
  HB_UNICODE_COMBINING_CLASS_CCC12	=  12,
  HB_UNICODE_COMBINING_CLASS_CCC13	=  13,
  HB_UNICODE_COMBINING_CLASS_CCC14	=  14,
  HB_UNICODE_COMBINING_CLASS_CCC15	=  15,
  HB_UNICODE_COMBINING_CLASS_CCC16	=  16,
  HB_UNICODE_COMBINING_CLASS_CCC17	=  17,
  HB_UNICODE_COMBINING_CLASS_CCC18	=  18,
  HB_UNICODE_COMBINING_CLASS_CCC19	=  19,
  HB_UNICODE_COMBINING_CLASS_CCC20	=  20,
  HB_UNICODE_COMBINING_CLASS_CCC21	=  21,
  HB_UNICODE_COMBINING_CLASS_CCC22	=  22,
  HB_UNICODE_COMBINING_CLASS_CCC23	=  23,
  HB_UNICODE_COMBINING_CLASS_CCC24	=  24,
  HB_UNICODE_COMBINING_CLASS_CCC25	=  25,
  HB_UNICODE_COMBINING_CLASS_CCC26	=  26,

  /* Arabic */
  HB_UNICODE_COMBINING_CLASS_CCC27	=  27,
  HB_UNICODE_COMBINING_CLASS_CCC28	=  28,
  HB_UNICODE_COMBINING_CLASS_CCC29	=  29,
  HB_UNICODE_COMBINING_CLASS_CCC30	=  30,
  HB_UNICODE_COMBINING_CLASS_CCC31	=  31,
  HB_UNICODE_COMBINING_CLASS_CCC32	=  32,
  HB_UNICODE_COMBINING_CLASS_CCC33	=  33,
  HB_UNICODE_COMBINING_CLASS_CCC34	=  34,
  HB_UNICODE_COMBINING_CLASS_CCC35	=  35,

  /* Syriac */
  HB_UNICODE_COMBINING_CLASS_CCC36	=  36,

  /* Telugu */
  HB_UNICODE_COMBINING_CLASS_CCC84	=  84,
  HB_UNICODE_COMBINING_CLASS_CCC91	=  91,

  /* Thai */
  HB_UNICODE_COMBINING_CLASS_CCC103	= 103,
  HB_UNICODE_COMBINING_CLASS_CCC107	= 107,

  /* Lao */
  HB_UNICODE_COMBINING_CLASS_CCC118	= 118,
  HB_UNICODE_COMBINING_CLASS_CCC122	= 122,

  /* Tibetan */
  HB_UNICODE_COMBINING_CLASS_CCC129	= 129,
  HB_UNICODE_COMBINING_CLASS_CCC130	= 130,
  HB_UNICODE_COMBINING_CLASS_CCC133	= 132,


  HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW_LEFT	= 200,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_BELOW		= 202,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE		= 214,
  HB_UNICODE_COMBINING_CLASS_ATTACHED_ABOVE_RIGHT	= 216,
  HB_UNICODE_COMBINING_CLASS_BELOW_LEFT			= 218,
  HB_UNICODE_COMBINING_CLASS_BELOW			= 220,
  HB_UNICODE_COMBINING_CLASS_BELOW_RIGHT		= 222,
  HB_UNICODE_COMBINING_CLASS_LEFT			= 224,
  HB_UNICODE_COMBINING_CLASS_RIGHT			= 226,
  HB_UNICODE_COMBINING_CLASS_ABOVE_LEFT			= 228,
  HB_UNICODE_COMBINING_CLASS_ABOVE			= 230,
  HB_UNICODE_COMBINING_CLASS_ABOVE_RIGHT		= 232,
  HB_UNICODE_COMBINING_CLASS_DOUBLE_BELOW		= 233,
  HB_UNICODE_COMBINING_CLASS_DOUBLE_ABOVE		= 234,

  HB_UNICODE_COMBINING_CLASS_IOTA_SUBSCRIPT		= 240,

  HB_UNICODE_COMBINING_CLASS_INVALID	= 255
} hb_unicode_combining_class_t;


/*
 * hb_unicode_funcs_t
 */

typedef struct hb_unicode_funcs_t hb_unicode_funcs_t;


/*
 * just give me the best implementation you've got there.
 */
hb_unicode_funcs_t *
hb_unicode_funcs_get_default (void);


hb_unicode_funcs_t *
hb_unicode_funcs_create (hb_unicode_funcs_t *parent);

hb_unicode_funcs_t *
hb_unicode_funcs_get_empty (void);

hb_unicode_funcs_t *
hb_unicode_funcs_reference (hb_unicode_funcs_t *ufuncs);

void
hb_unicode_funcs_destroy (hb_unicode_funcs_t *ufuncs);

hb_bool_t
hb_unicode_funcs_set_user_data (hb_unicode_funcs_t *ufuncs,
			        hb_user_data_key_t *key,
			        void *              data,
			        hb_destroy_func_t   destroy,
				hb_bool_t           replace);


void *
hb_unicode_funcs_get_user_data (hb_unicode_funcs_t *ufuncs,
			        hb_user_data_key_t *key);


void
hb_unicode_funcs_make_immutable (hb_unicode_funcs_t *ufuncs);

hb_bool_t
hb_unicode_funcs_is_immutable (hb_unicode_funcs_t *ufuncs);

hb_unicode_funcs_t *
hb_unicode_funcs_get_parent (hb_unicode_funcs_t *ufuncs);


/*
 * funcs
 */

/* typedefs */

typedef hb_unicode_combining_class_t	(*hb_unicode_combining_class_func_t)	(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      unicode,
										 void               *user_data);
typedef unsigned int			(*hb_unicode_eastasian_width_func_t)	(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      unicode,
										 void               *user_data);
typedef hb_unicode_general_category_t	(*hb_unicode_general_category_func_t)	(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      unicode,
										 void               *user_data);
typedef hb_codepoint_t			(*hb_unicode_mirroring_func_t)		(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      unicode,
										 void               *user_data);
typedef hb_script_t			(*hb_unicode_script_func_t)		(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      unicode,
										 void               *user_data);

typedef hb_bool_t			(*hb_unicode_compose_func_t)		(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      a,
										 hb_codepoint_t      b,
										 hb_codepoint_t     *ab,
										 void               *user_data);
typedef hb_bool_t			(*hb_unicode_decompose_func_t)		(hb_unicode_funcs_t *ufuncs,
										 hb_codepoint_t      ab,
										 hb_codepoint_t     *a,
										 hb_codepoint_t     *b,
										 void               *user_data);

/**
 * hb_unicode_decompose_compatibility_func_t:
 * @ufuncs: a Unicode function structure
 * @u: codepoint to decompose
 * @decomposed: address of codepoint array (of length %HB_UNICODE_MAX_DECOMPOSITION_LEN) to write decomposition into
 * @user_data: user data pointer as passed to hb_unicode_funcs_set_decompose_compatibility_func()
 *
 * Fully decompose @u to its Unicode compatibility decomposition. The codepoints of the decomposition will be written to @decomposed.
 * The complete length of the decomposition will be returned.
 *
 * If @u has no compatibility decomposition, zero should be returned.
 *
 * The Unicode standard guarantees that a buffer of length %HB_UNICODE_MAX_DECOMPOSITION_LEN codepoints will always be sufficient for any
 * compatibility decomposition plus an terminating value of 0.  Consequently, @decompose must be allocated by the caller to be at least this length.  Implementations
 * of this function type must ensure that they do not write past the provided array.
 *
 * Return value: number of codepoints in the full compatibility decomposition of @u, or 0 if no decomposition available.
 */
typedef unsigned int			(*hb_unicode_decompose_compatibility_func_t)	(hb_unicode_funcs_t *ufuncs,
											 hb_codepoint_t      u,
											 hb_codepoint_t     *decomposed,
											 void               *user_data);

/* See Unicode 6.1 for details on the maximum decomposition length. */
#define HB_UNICODE_MAX_DECOMPOSITION_LEN (18+1) /* codepoints */

/* setters */

/**
 * hb_unicode_funcs_set_combining_class_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_combining_class_func (hb_unicode_funcs_t *ufuncs,
					   hb_unicode_combining_class_func_t func,
					   void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_eastasian_width_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_eastasian_width_func (hb_unicode_funcs_t *ufuncs,
					   hb_unicode_eastasian_width_func_t func,
					   void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_general_category_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_general_category_func (hb_unicode_funcs_t *ufuncs,
					    hb_unicode_general_category_func_t func,
					    void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_mirroring_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_mirroring_func (hb_unicode_funcs_t *ufuncs,
				     hb_unicode_mirroring_func_t func,
				     void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_script_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_script_func (hb_unicode_funcs_t *ufuncs,
				  hb_unicode_script_func_t func,
				  void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_compose_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_compose_func (hb_unicode_funcs_t *ufuncs,
				   hb_unicode_compose_func_t func,
				   void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_decompose_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_decompose_func (hb_unicode_funcs_t *ufuncs,
				     hb_unicode_decompose_func_t func,
				     void *user_data, hb_destroy_func_t destroy);

/**
 * hb_unicode_funcs_set_decompose_compatibility_func:
 * @ufuncs: a Unicode function structure
 * @func: (closure user_data) (destroy destroy) (scope notified):
 * @user_data:
 * @destroy:
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_unicode_funcs_set_decompose_compatibility_func (hb_unicode_funcs_t *ufuncs,
						   hb_unicode_decompose_compatibility_func_t func,
						   void *user_data, hb_destroy_func_t destroy);

/* accessors */

hb_unicode_combining_class_t
hb_unicode_combining_class (hb_unicode_funcs_t *ufuncs,
			    hb_codepoint_t unicode);

unsigned int
hb_unicode_eastasian_width (hb_unicode_funcs_t *ufuncs,
			    hb_codepoint_t unicode);

hb_unicode_general_category_t
hb_unicode_general_category (hb_unicode_funcs_t *ufuncs,
			     hb_codepoint_t unicode);

hb_codepoint_t
hb_unicode_mirroring (hb_unicode_funcs_t *ufuncs,
		      hb_codepoint_t unicode);

hb_script_t
hb_unicode_script (hb_unicode_funcs_t *ufuncs,
		   hb_codepoint_t unicode);

hb_bool_t
hb_unicode_compose (hb_unicode_funcs_t *ufuncs,
		    hb_codepoint_t      a,
		    hb_codepoint_t      b,
		    hb_codepoint_t     *ab);
hb_bool_t
hb_unicode_decompose (hb_unicode_funcs_t *ufuncs,
		      hb_codepoint_t      ab,
		      hb_codepoint_t     *a,
		      hb_codepoint_t     *b);

unsigned int
hb_unicode_decompose_compatibility (hb_unicode_funcs_t *ufuncs,
				    hb_codepoint_t      u,
				    hb_codepoint_t     *decomposed);

HB_END_DECLS

#endif /* HB_UNICODE_H */
