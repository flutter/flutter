/*
 * Copyright © 2010,2012  Google, Inc.
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

#include "hb-ot-shape-complex-private.hh"


static const hb_tag_t tibetan_features[] =
{
  HB_TAG('a','b','v','s'),
  HB_TAG('b','l','w','s'),
  HB_TAG('a','b','v','m'),
  HB_TAG('b','l','w','m'),
  HB_TAG_NONE
};

static void
collect_features_tibetan (hb_ot_shape_planner_t *plan)
{
  for (const hb_tag_t *script_features = tibetan_features; script_features && *script_features; script_features++)
    plan->map.add_global_bool_feature (*script_features);
}


const hb_ot_complex_shaper_t _hb_ot_complex_shaper_tibetan =
{
  "default",
  collect_features_tibetan,
  NULL, /* override_features */
  NULL, /* data_create */
  NULL, /* data_destroy */
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_DEFAULT,
  NULL, /* decompose */
  NULL, /* compose */
  NULL, /* setup_masks */
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_DEFAULT,
  true, /* fallback_position */
};
