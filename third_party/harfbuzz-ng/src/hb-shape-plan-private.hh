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

#ifndef HB_SHAPE_PLAN_PRIVATE_HH
#define HB_SHAPE_PLAN_PRIVATE_HH

#include "hb-private.hh"
#include "hb-object-private.hh"
#include "hb-shaper-private.hh"


struct hb_shape_plan_t
{
  hb_object_header_t header;
  ASSERT_POD ();

  hb_bool_t default_shaper_list;
  hb_face_t *face_unsafe; /* We don't carry a reference to face. */
  hb_segment_properties_t props;

  hb_shape_func_t *shaper_func;
  const char *shaper_name;

  hb_feature_t *user_features;
  unsigned int num_user_features;

  struct hb_shaper_data_t shaper_data;
};

#define HB_SHAPER_DATA_CREATE_FUNC_EXTRA_ARGS \
	, const hb_feature_t            *user_features \
	, unsigned int                   num_user_features
#define HB_SHAPER_IMPLEMENT(shaper) HB_SHAPER_DATA_PROTOTYPE(shaper, shape_plan);
#include "hb-shaper-list.hh"
#undef HB_SHAPER_IMPLEMENT
#undef HB_SHAPER_DATA_CREATE_FUNC_EXTRA_ARGS


#endif /* HB_SHAPE_PLAN_PRIVATE_HH */
