/*
 * Copyright © 2012  Google, Inc.
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

#ifndef HB_H_IN
#error "Include <hb.h> instead."
#endif

#ifndef HB_SET_H
#define HB_SET_H

#include "hb-common.h"

HB_BEGIN_DECLS


#define HB_SET_VALUE_INVALID ((hb_codepoint_t) -1)

typedef struct hb_set_t hb_set_t;


hb_set_t *
hb_set_create (void);

hb_set_t *
hb_set_get_empty (void);

hb_set_t *
hb_set_reference (hb_set_t *set);

void
hb_set_destroy (hb_set_t *set);

hb_bool_t
hb_set_set_user_data (hb_set_t           *set,
		      hb_user_data_key_t *key,
		      void *              data,
		      hb_destroy_func_t   destroy,
		      hb_bool_t           replace);

void *
hb_set_get_user_data (hb_set_t           *set,
		      hb_user_data_key_t *key);


/* Returns false if allocation has failed before */
hb_bool_t
hb_set_allocation_successful (const hb_set_t *set);

void
hb_set_clear (hb_set_t *set);

hb_bool_t
hb_set_is_empty (const hb_set_t *set);

hb_bool_t
hb_set_has (const hb_set_t *set,
	    hb_codepoint_t  codepoint);

/* Right now limited to 16-bit integers.  Eventually will do full codepoint range, sans -1
 * which we will use as a sentinel. */
void
hb_set_add (hb_set_t       *set,
	    hb_codepoint_t  codepoint);

void
hb_set_add_range (hb_set_t       *set,
		  hb_codepoint_t  first,
		  hb_codepoint_t  last);

void
hb_set_del (hb_set_t       *set,
	    hb_codepoint_t  codepoint);

void
hb_set_del_range (hb_set_t       *set,
		  hb_codepoint_t  first,
		  hb_codepoint_t  last);

hb_bool_t
hb_set_is_equal (const hb_set_t *set,
		 const hb_set_t *other);

void
hb_set_set (hb_set_t       *set,
	    const hb_set_t *other);

void
hb_set_union (hb_set_t       *set,
	      const hb_set_t *other);

void
hb_set_intersect (hb_set_t       *set,
		  const hb_set_t *other);

void
hb_set_subtract (hb_set_t       *set,
		 const hb_set_t *other);

void
hb_set_symmetric_difference (hb_set_t       *set,
			     const hb_set_t *other);

void
hb_set_invert (hb_set_t *set);

unsigned int
hb_set_get_population (const hb_set_t *set);

/* Returns -1 if set empty. */
hb_codepoint_t
hb_set_get_min (const hb_set_t *set);

/* Returns -1 if set empty. */
hb_codepoint_t
hb_set_get_max (const hb_set_t *set);

/* Pass -1 in to get started. */
hb_bool_t
hb_set_next (const hb_set_t *set,
	     hb_codepoint_t *codepoint);

/* Pass -1 for first and last to get started. */
hb_bool_t
hb_set_next_range (const hb_set_t *set,
		   hb_codepoint_t *first,
		   hb_codepoint_t *last);


HB_END_DECLS

#endif /* HB_SET_H */
