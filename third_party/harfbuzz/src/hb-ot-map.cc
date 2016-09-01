/*
 * Copyright © 2009,2010  Red Hat, Inc.
 * Copyright © 2010,2011,2013  Google, Inc.
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

#include "hb-ot-map-private.hh"

#include "hb-ot-layout-private.hh"


void
hb_ot_map_t::add_lookups (hb_face_t    *face,
			  unsigned int  table_index,
			  unsigned int  feature_index,
			  hb_mask_t     mask,
			  bool          auto_zwj)
{
  unsigned int lookup_indices[32];
  unsigned int offset, len;
  unsigned int table_lookup_count;

  table_lookup_count = hb_ot_layout_table_get_lookup_count (face, table_tags[table_index]);

  offset = 0;
  do {
    len = ARRAY_LENGTH (lookup_indices);
    hb_ot_layout_feature_get_lookups (face,
				      table_tags[table_index],
				      feature_index,
				      offset, &len,
				      lookup_indices);

    for (unsigned int i = 0; i < len; i++)
    {
      if (lookup_indices[i] >= table_lookup_count)
	continue;
      hb_ot_map_t::lookup_map_t *lookup = lookups[table_index].push ();
      if (unlikely (!lookup))
        return;
      lookup->mask = mask;
      lookup->index = lookup_indices[i];
      lookup->auto_zwj = auto_zwj;
    }

    offset += len;
  } while (len == ARRAY_LENGTH (lookup_indices));
}

hb_ot_map_builder_t::hb_ot_map_builder_t (hb_face_t *face_,
					  const hb_segment_properties_t *props_)
{
  memset (this, 0, sizeof (*this));

  face = face_;
  props = *props_;


  /* Fetch script/language indices for GSUB/GPOS.  We need these later to skip
   * features not available in either table and not waste precious bits for them. */

  hb_tag_t script_tags[3] = {HB_TAG_NONE, HB_TAG_NONE, HB_TAG_NONE};
  hb_tag_t language_tag;

  hb_ot_tags_from_script (props.script, &script_tags[0], &script_tags[1]);
  language_tag = hb_ot_tag_from_language (props.language);

  for (unsigned int table_index = 0; table_index < 2; table_index++) {
    hb_tag_t table_tag = table_tags[table_index];
    found_script[table_index] = hb_ot_layout_table_choose_script (face, table_tag, script_tags, &script_index[table_index], &chosen_script[table_index]);
    hb_ot_layout_script_find_language (face, table_tag, script_index[table_index], language_tag, &language_index[table_index]);
  }
}

void hb_ot_map_builder_t::add_feature (hb_tag_t tag, unsigned int value,
				       hb_ot_map_feature_flags_t flags)
{
  feature_info_t *info = feature_infos.push();
  if (unlikely (!info)) return;
  if (unlikely (!tag)) return;
  info->tag = tag;
  info->seq = feature_infos.len;
  info->max_value = value;
  info->flags = flags;
  info->default_value = (flags & F_GLOBAL) ? value : 0;
  info->stage[0] = current_stage[0];
  info->stage[1] = current_stage[1];
}


void hb_ot_map_t::collect_lookups (unsigned int table_index, hb_set_t *lookups_out) const
{
  for (unsigned int i = 0; i < lookups[table_index].len; i++)
    hb_set_add (lookups_out, lookups[table_index][i].index);
}

void hb_ot_map_builder_t::add_pause (unsigned int table_index, hb_ot_map_t::pause_func_t pause_func)
{
  stage_info_t *s = stages[table_index].push ();
  if (likely (s)) {
    s->index = current_stage[table_index];
    s->pause_func = pause_func;
  }

  current_stage[table_index]++;
}

void
hb_ot_map_builder_t::compile (hb_ot_map_t &m)
{
  m.global_mask = 1;

  unsigned int required_feature_index[2];
  hb_tag_t required_feature_tag[2];
  /* We default to applying required feature in stage 0.  If the required
   * feature has a tag that is known to the shaper, we apply required feature
   * in the stage for that tag.
   */
  unsigned int required_feature_stage[2] = {0, 0};

  for (unsigned int table_index = 0; table_index < 2; table_index++)
  {
    m.chosen_script[table_index] = chosen_script[table_index];
    m.found_script[table_index] = found_script[table_index];

    hb_ot_layout_language_get_required_feature (face,
						table_tags[table_index],
						script_index[table_index],
						language_index[table_index],
						&required_feature_index[table_index],
						&required_feature_tag[table_index]);
  }

  if (!feature_infos.len)
    return;

  /* Sort features and merge duplicates */
  {
    feature_infos.qsort ();
    unsigned int j = 0;
    for (unsigned int i = 1; i < feature_infos.len; i++)
      if (feature_infos[i].tag != feature_infos[j].tag)
	feature_infos[++j] = feature_infos[i];
      else {
	if (feature_infos[i].flags & F_GLOBAL) {
	  feature_infos[j].flags |= F_GLOBAL;
	  feature_infos[j].max_value = feature_infos[i].max_value;
	  feature_infos[j].default_value = feature_infos[i].default_value;
	} else {
	  feature_infos[j].flags &= ~F_GLOBAL;
	  feature_infos[j].max_value = MAX (feature_infos[j].max_value, feature_infos[i].max_value);
	  /* Inherit default_value from j */
	}
	feature_infos[j].flags |= (feature_infos[i].flags & F_HAS_FALLBACK);
	feature_infos[j].stage[0] = MIN (feature_infos[j].stage[0], feature_infos[i].stage[0]);
	feature_infos[j].stage[1] = MIN (feature_infos[j].stage[1], feature_infos[i].stage[1]);
      }
    feature_infos.shrink (j + 1);
  }


  /* Allocate bits now */
  unsigned int next_bit = 1;
  for (unsigned int i = 0; i < feature_infos.len; i++)
  {
    const feature_info_t *info = &feature_infos[i];

    unsigned int bits_needed;

    if ((info->flags & F_GLOBAL) && info->max_value == 1)
      /* Uses the global bit */
      bits_needed = 0;
    else
      bits_needed = _hb_bit_storage (info->max_value);

    if (!info->max_value || next_bit + bits_needed > 8 * sizeof (hb_mask_t))
      continue; /* Feature disabled, or not enough bits. */


    hb_bool_t found = false;
    unsigned int feature_index[2];
    for (unsigned int table_index = 0; table_index < 2; table_index++)
    {
      if (required_feature_tag[table_index] == info->tag)
      {
	required_feature_stage[table_index] = info->stage[table_index];
	found = true;
	continue;
      }
      found |= hb_ot_layout_language_find_feature (face,
						   table_tags[table_index],
						   script_index[table_index],
						   language_index[table_index],
						   info->tag,
						   &feature_index[table_index]);
    }
    if (!found && !(info->flags & F_HAS_FALLBACK))
      continue;


    hb_ot_map_t::feature_map_t *map = m.features.push ();
    if (unlikely (!map))
      break;

    map->tag = info->tag;
    map->index[0] = feature_index[0];
    map->index[1] = feature_index[1];
    map->stage[0] = info->stage[0];
    map->stage[1] = info->stage[1];
    map->auto_zwj = !(info->flags & F_MANUAL_ZWJ);
    if ((info->flags & F_GLOBAL) && info->max_value == 1) {
      /* Uses the global bit */
      map->shift = 0;
      map->mask = 1;
    } else {
      map->shift = next_bit;
      map->mask = (1 << (next_bit + bits_needed)) - (1 << next_bit);
      next_bit += bits_needed;
      m.global_mask |= (info->default_value << map->shift) & map->mask;
    }
    map->_1_mask = (1 << map->shift) & map->mask;
    map->needs_fallback = !found;

  }
  feature_infos.shrink (0); /* Done with these */


  add_gsub_pause (NULL);
  add_gpos_pause (NULL);

  for (unsigned int table_index = 0; table_index < 2; table_index++)
  {
    /* Collect lookup indices for features */

    unsigned int stage_index = 0;
    unsigned int last_num_lookups = 0;
    for (unsigned stage = 0; stage < current_stage[table_index]; stage++)
    {
      if (required_feature_index[table_index] != HB_OT_LAYOUT_NO_FEATURE_INDEX &&
	  required_feature_stage[table_index] == stage)
	m.add_lookups (face, table_index,
		       required_feature_index[table_index],
		       1 /* mask */,
		       true /* auto_zwj */);

      for (unsigned i = 0; i < m.features.len; i++)
        if (m.features[i].stage[table_index] == stage)
	  m.add_lookups (face, table_index,
			 m.features[i].index[table_index],
			 m.features[i].mask,
			 m.features[i].auto_zwj);

      /* Sort lookups and merge duplicates */
      if (last_num_lookups < m.lookups[table_index].len)
      {
	m.lookups[table_index].qsort (last_num_lookups, m.lookups[table_index].len);

	unsigned int j = last_num_lookups;
	for (unsigned int i = j + 1; i < m.lookups[table_index].len; i++)
	  if (m.lookups[table_index][i].index != m.lookups[table_index][j].index)
	    m.lookups[table_index][++j] = m.lookups[table_index][i];
	  else
	  {
	    m.lookups[table_index][j].mask |= m.lookups[table_index][i].mask;
	    m.lookups[table_index][j].auto_zwj &= m.lookups[table_index][i].auto_zwj;
	  }
	m.lookups[table_index].shrink (j + 1);
      }

      last_num_lookups = m.lookups[table_index].len;

      if (stage_index < stages[table_index].len && stages[table_index][stage_index].index == stage) {
	hb_ot_map_t::stage_map_t *stage_map = m.stages[table_index].push ();
	if (likely (stage_map)) {
	  stage_map->last_lookup = last_num_lookups;
	  stage_map->pause_func = stages[table_index][stage_index].pause_func;
	}

	stage_index++;
      }
    }
  }
}
