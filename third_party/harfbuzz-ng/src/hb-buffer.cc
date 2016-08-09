/*
 * Copyright © 1998-2004  David Turner and Werner Lemberg
 * Copyright © 2004,2007,2009,2010  Red Hat, Inc.
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

#include "hb-buffer-private.hh"
#include "hb-utf-private.hh"


#ifndef HB_DEBUG_BUFFER
#define HB_DEBUG_BUFFER (HB_DEBUG+0)
#endif


hb_bool_t
hb_segment_properties_equal (const hb_segment_properties_t *a,
			     const hb_segment_properties_t *b)
{
  return a->direction == b->direction &&
	 a->script    == b->script    &&
	 a->language  == b->language  &&
	 a->reserved1 == b->reserved1 &&
	 a->reserved2 == b->reserved2;

}

unsigned int
hb_segment_properties_hash (const hb_segment_properties_t *p)
{
  return (unsigned int) p->direction ^
	 (unsigned int) p->script ^
	 (intptr_t) (p->language);
}



/* Here is how the buffer works internally:
 *
 * There are two info pointers: info and out_info.  They always have
 * the same allocated size, but different lengths.
 *
 * As an optimization, both info and out_info may point to the
 * same piece of memory, which is owned by info.  This remains the
 * case as long as out_len doesn't exceed i at any time.
 * In that case, swap_buffers() is no-op and the glyph operations operate
 * mostly in-place.
 *
 * As soon as out_info gets longer than info, out_info is moved over
 * to an alternate buffer (which we reuse the pos buffer for!), and its
 * current contents (out_len entries) are copied to the new place.
 * This should all remain transparent to the user.  swap_buffers() then
 * switches info and out_info.
 */



/* Internal API */

bool
hb_buffer_t::enlarge (unsigned int size)
{
  if (unlikely (in_error))
    return false;

  unsigned int new_allocated = allocated;
  hb_glyph_position_t *new_pos = NULL;
  hb_glyph_info_t *new_info = NULL;
  bool separate_out = out_info != info;

  if (unlikely (_hb_unsigned_int_mul_overflows (size, sizeof (info[0]))))
    goto done;

  while (size >= new_allocated)
    new_allocated += (new_allocated >> 1) + 32;

  ASSERT_STATIC (sizeof (info[0]) == sizeof (pos[0]));
  if (unlikely (_hb_unsigned_int_mul_overflows (new_allocated, sizeof (info[0]))))
    goto done;

  new_pos = (hb_glyph_position_t *) realloc (pos, new_allocated * sizeof (pos[0]));
  new_info = (hb_glyph_info_t *) realloc (info, new_allocated * sizeof (info[0]));

done:
  if (unlikely (!new_pos || !new_info))
    in_error = true;

  if (likely (new_pos))
    pos = new_pos;

  if (likely (new_info))
    info = new_info;

  out_info = separate_out ? (hb_glyph_info_t *) pos : info;
  if (likely (!in_error))
    allocated = new_allocated;

  return likely (!in_error);
}

bool
hb_buffer_t::make_room_for (unsigned int num_in,
			    unsigned int num_out)
{
  if (unlikely (!ensure (out_len + num_out))) return false;

  if (out_info == info &&
      out_len + num_out > idx + num_in)
  {
    assert (have_output);

    out_info = (hb_glyph_info_t *) pos;
    memcpy (out_info, info, out_len * sizeof (out_info[0]));
  }

  return true;
}

bool
hb_buffer_t::shift_forward (unsigned int count)
{
  assert (have_output);
  if (unlikely (!ensure (len + count))) return false;

  memmove (info + idx + count, info + idx, (len - idx) * sizeof (info[0]));
  len += count;
  idx += count;

  return true;
}

hb_buffer_t::scratch_buffer_t *
hb_buffer_t::get_scratch_buffer (unsigned int *size)
{
  have_output = false;
  have_positions = false;

  out_len = 0;
  out_info = info;

  assert ((uintptr_t) pos % sizeof (scratch_buffer_t) == 0);
  *size = allocated * sizeof (pos[0]) / sizeof (scratch_buffer_t);
  return (scratch_buffer_t *) (void *) pos;
}



/* HarfBuzz-Internal API */

void
hb_buffer_t::reset (void)
{
  if (unlikely (hb_object_is_inert (this)))
    return;

  hb_unicode_funcs_destroy (unicode);
  unicode = hb_unicode_funcs_get_default ();
  flags = HB_BUFFER_FLAG_DEFAULT;
  replacement = HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT;

  clear ();
}

void
hb_buffer_t::clear (void)
{
  if (unlikely (hb_object_is_inert (this)))
    return;

  hb_segment_properties_t default_props = HB_SEGMENT_PROPERTIES_DEFAULT;
  props = default_props;

  content_type = HB_BUFFER_CONTENT_TYPE_INVALID;
  in_error = false;
  have_output = false;
  have_positions = false;

  idx = 0;
  len = 0;
  out_len = 0;
  out_info = info;

  serial = 0;
  memset (allocated_var_bytes, 0, sizeof allocated_var_bytes);
  memset (allocated_var_owner, 0, sizeof allocated_var_owner);

  memset (context, 0, sizeof context);
  memset (context_len, 0, sizeof context_len);
}

void
hb_buffer_t::add (hb_codepoint_t  codepoint,
		  unsigned int    cluster)
{
  hb_glyph_info_t *glyph;

  if (unlikely (!ensure (len + 1))) return;

  glyph = &info[len];

  memset (glyph, 0, sizeof (*glyph));
  glyph->codepoint = codepoint;
  glyph->mask = 1;
  glyph->cluster = cluster;

  len++;
}

void
hb_buffer_t::add_info (const hb_glyph_info_t &glyph_info)
{
  if (unlikely (!ensure (len + 1))) return;

  info[len] = glyph_info;

  len++;
}


void
hb_buffer_t::remove_output (void)
{
  if (unlikely (hb_object_is_inert (this)))
    return;

  have_output = false;
  have_positions = false;

  out_len = 0;
  out_info = info;
}

void
hb_buffer_t::clear_output (void)
{
  if (unlikely (hb_object_is_inert (this)))
    return;

  have_output = true;
  have_positions = false;

  out_len = 0;
  out_info = info;
}

void
hb_buffer_t::clear_positions (void)
{
  if (unlikely (hb_object_is_inert (this)))
    return;

  have_output = false;
  have_positions = true;

  out_len = 0;
  out_info = info;

  memset (pos, 0, sizeof (pos[0]) * len);
}

void
hb_buffer_t::swap_buffers (void)
{
  if (unlikely (in_error)) return;

  assert (have_output);
  have_output = false;

  if (out_info != info)
  {
    hb_glyph_info_t *tmp_string;
    tmp_string = info;
    info = out_info;
    out_info = tmp_string;
    pos = (hb_glyph_position_t *) out_info;
  }

  unsigned int tmp;
  tmp = len;
  len = out_len;
  out_len = tmp;

  idx = 0;
}


void
hb_buffer_t::replace_glyphs (unsigned int num_in,
			     unsigned int num_out,
			     const uint32_t *glyph_data)
{
  if (unlikely (!make_room_for (num_in, num_out))) return;

  merge_clusters (idx, idx + num_in);

  hb_glyph_info_t orig_info = info[idx];
  hb_glyph_info_t *pinfo = &out_info[out_len];
  for (unsigned int i = 0; i < num_out; i++)
  {
    *pinfo = orig_info;
    pinfo->codepoint = glyph_data[i];
    pinfo++;
  }

  idx  += num_in;
  out_len += num_out;
}

void
hb_buffer_t::output_glyph (hb_codepoint_t glyph_index)
{
  if (unlikely (!make_room_for (0, 1))) return;

  out_info[out_len] = info[idx];
  out_info[out_len].codepoint = glyph_index;

  out_len++;
}

void
hb_buffer_t::output_info (const hb_glyph_info_t &glyph_info)
{
  if (unlikely (!make_room_for (0, 1))) return;

  out_info[out_len] = glyph_info;

  out_len++;
}

void
hb_buffer_t::copy_glyph (void)
{
  if (unlikely (!make_room_for (0, 1))) return;

  out_info[out_len] = info[idx];

  out_len++;
}

bool
hb_buffer_t::move_to (unsigned int i)
{
  if (!have_output)
  {
    assert (i <= len);
    idx = i;
    return true;
  }

  assert (i <= out_len + (len - idx));

  if (out_len < i)
  {
    unsigned int count = i - out_len;
    if (unlikely (!make_room_for (count, count))) return false;

    memmove (out_info + out_len, info + idx, count * sizeof (out_info[0]));
    idx += count;
    out_len += count;
  }
  else if (out_len > i)
  {
    /* Tricky part: rewinding... */
    unsigned int count = out_len - i;

    if (unlikely (idx < count && !shift_forward (count + 32))) return false;

    assert (idx >= count);

    idx -= count;
    out_len -= count;
    memmove (info + idx, out_info + out_len, count * sizeof (out_info[0]));
  }

  return true;
}

void
hb_buffer_t::replace_glyph (hb_codepoint_t glyph_index)
{
  if (unlikely (out_info != info || out_len != idx)) {
    if (unlikely (!make_room_for (1, 1))) return;
    out_info[out_len] = info[idx];
  }
  out_info[out_len].codepoint = glyph_index;

  idx++;
  out_len++;
}


void
hb_buffer_t::set_masks (hb_mask_t    value,
			hb_mask_t    mask,
			unsigned int cluster_start,
			unsigned int cluster_end)
{
  hb_mask_t not_mask = ~mask;
  value &= mask;

  if (!mask)
    return;

  if (cluster_start == 0 && cluster_end == (unsigned int)-1) {
    unsigned int count = len;
    for (unsigned int i = 0; i < count; i++)
      info[i].mask = (info[i].mask & not_mask) | value;
    return;
  }

  unsigned int count = len;
  for (unsigned int i = 0; i < count; i++)
    if (cluster_start <= info[i].cluster && info[i].cluster < cluster_end)
      info[i].mask = (info[i].mask & not_mask) | value;
}

void
hb_buffer_t::reverse_range (unsigned int start,
			    unsigned int end)
{
  unsigned int i, j;

  if (end - start < 2)
    return;

  for (i = start, j = end - 1; i < j; i++, j--) {
    hb_glyph_info_t t;

    t = info[i];
    info[i] = info[j];
    info[j] = t;
  }

  if (have_positions) {
    for (i = start, j = end - 1; i < j; i++, j--) {
      hb_glyph_position_t t;

      t = pos[i];
      pos[i] = pos[j];
      pos[j] = t;
    }
  }
}

void
hb_buffer_t::reverse (void)
{
  if (unlikely (!len))
    return;

  reverse_range (0, len);
}

void
hb_buffer_t::reverse_clusters (void)
{
  unsigned int i, start, count, last_cluster;

  if (unlikely (!len))
    return;

  reverse ();

  count = len;
  start = 0;
  last_cluster = info[0].cluster;
  for (i = 1; i < count; i++) {
    if (last_cluster != info[i].cluster) {
      reverse_range (start, i);
      start = i;
      last_cluster = info[i].cluster;
    }
  }
  reverse_range (start, i);
}

void
hb_buffer_t::merge_clusters (unsigned int start,
			     unsigned int end)
{
#ifdef HB_NO_MERGE_CLUSTERS
  return;
#endif

  if (unlikely (end - start < 2))
    return;

  unsigned int cluster = info[start].cluster;

  for (unsigned int i = start + 1; i < end; i++)
    cluster = MIN (cluster, info[i].cluster);

  /* Extend end */
  while (end < len && info[end - 1].cluster == info[end].cluster)
    end++;

  /* Extend start */
  while (idx < start && info[start - 1].cluster == info[start].cluster)
    start--;

  /* If we hit the start of buffer, continue in out-buffer. */
  if (idx == start)
    for (unsigned i = out_len; i && out_info[i - 1].cluster == info[start].cluster; i--)
      out_info[i - 1].cluster = cluster;

  for (unsigned int i = start; i < end; i++)
    info[i].cluster = cluster;
}
void
hb_buffer_t::merge_out_clusters (unsigned int start,
				 unsigned int end)
{
#ifdef HB_NO_MERGE_CLUSTERS
  return;
#endif

  if (unlikely (end - start < 2))
    return;

  unsigned int cluster = out_info[start].cluster;

  for (unsigned int i = start + 1; i < end; i++)
    cluster = MIN (cluster, out_info[i].cluster);

  /* Extend start */
  while (start && out_info[start - 1].cluster == out_info[start].cluster)
    start--;

  /* Extend end */
  while (end < out_len && out_info[end - 1].cluster == out_info[end].cluster)
    end++;

  /* If we hit the end of out-buffer, continue in buffer. */
  if (end == out_len)
    for (unsigned i = idx; i < len && info[i].cluster == out_info[end - 1].cluster; i++)
      info[i].cluster = cluster;

  for (unsigned int i = start; i < end; i++)
    out_info[i].cluster = cluster;
}

void
hb_buffer_t::guess_segment_properties (void)
{
  assert (content_type == HB_BUFFER_CONTENT_TYPE_UNICODE ||
	  (!len && content_type == HB_BUFFER_CONTENT_TYPE_INVALID));

  /* If script is set to INVALID, guess from buffer contents */
  if (props.script == HB_SCRIPT_INVALID) {
    for (unsigned int i = 0; i < len; i++) {
      hb_script_t script = unicode->script (info[i].codepoint);
      if (likely (script != HB_SCRIPT_COMMON &&
		  script != HB_SCRIPT_INHERITED &&
		  script != HB_SCRIPT_UNKNOWN)) {
        props.script = script;
        break;
      }
    }
  }

  /* If direction is set to INVALID, guess from script */
  if (props.direction == HB_DIRECTION_INVALID) {
    props.direction = hb_script_get_horizontal_direction (props.script);
  }

  /* If language is not set, use default language from locale */
  if (props.language == HB_LANGUAGE_INVALID) {
    /* TODO get_default_for_script? using $LANGUAGE */
    props.language = hb_language_get_default ();
  }
}


static inline void
dump_var_allocation (const hb_buffer_t *buffer)
{
  char buf[80];
  for (unsigned int i = 0; i < 8; i++)
    buf[i] = '0' + buffer->allocated_var_bytes[7 - i];
  buf[8] = '\0';
  DEBUG_MSG (BUFFER, buffer,
	     "Current var allocation: %s",
	     buf);
}

void hb_buffer_t::allocate_var (unsigned int byte_i, unsigned int count, const char *owner)
{
  assert (byte_i < 8 && byte_i + count <= 8);

  if (DEBUG_ENABLED (BUFFER))
    dump_var_allocation (this);
  DEBUG_MSG (BUFFER, this,
	     "Allocating var bytes %d..%d for %s",
	     byte_i, byte_i + count - 1, owner);

  for (unsigned int i = byte_i; i < byte_i + count; i++) {
    assert (!allocated_var_bytes[i]);
    allocated_var_bytes[i]++;
    allocated_var_owner[i] = owner;
  }
}

void hb_buffer_t::deallocate_var (unsigned int byte_i, unsigned int count, const char *owner)
{
  if (DEBUG_ENABLED (BUFFER))
    dump_var_allocation (this);

  DEBUG_MSG (BUFFER, this,
	     "Deallocating var bytes %d..%d for %s",
	     byte_i, byte_i + count - 1, owner);

  assert (byte_i < 8 && byte_i + count <= 8);
  for (unsigned int i = byte_i; i < byte_i + count; i++) {
    assert (allocated_var_bytes[i]);
    assert (0 == strcmp (allocated_var_owner[i], owner));
    allocated_var_bytes[i]--;
  }
}

void hb_buffer_t::assert_var (unsigned int byte_i, unsigned int count, const char *owner)
{
  if (DEBUG_ENABLED (BUFFER))
    dump_var_allocation (this);

  DEBUG_MSG (BUFFER, this,
	     "Asserting var bytes %d..%d for %s",
	     byte_i, byte_i + count - 1, owner);

  assert (byte_i < 8 && byte_i + count <= 8);
  for (unsigned int i = byte_i; i < byte_i + count; i++) {
    assert (allocated_var_bytes[i]);
    assert (0 == strcmp (allocated_var_owner[i], owner));
  }
}

void hb_buffer_t::deallocate_var_all (void)
{
  memset (allocated_var_bytes, 0, sizeof (allocated_var_bytes));
  memset (allocated_var_owner, 0, sizeof (allocated_var_owner));
}

/* Public API */

/**
 * hb_buffer_create: (Xconstructor)
 *
 * 
 *
 * Return value: (transfer full)
 *
 * Since: 1.0
 **/
hb_buffer_t *
hb_buffer_create (void)
{
  hb_buffer_t *buffer;

  if (!(buffer = hb_object_create<hb_buffer_t> ()))
    return hb_buffer_get_empty ();

  buffer->reset ();

  return buffer;
}

/**
 * hb_buffer_get_empty:
 *
 * 
 *
 * Return value: (transfer full):
 *
 * Since: 1.0
 **/
hb_buffer_t *
hb_buffer_get_empty (void)
{
  static const hb_buffer_t _hb_buffer_nil = {
    HB_OBJECT_HEADER_STATIC,

    const_cast<hb_unicode_funcs_t *> (&_hb_unicode_funcs_nil),
    HB_BUFFER_FLAG_DEFAULT,
    HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT,

    HB_BUFFER_CONTENT_TYPE_INVALID,
    HB_SEGMENT_PROPERTIES_DEFAULT,
    true, /* in_error */
    true, /* have_output */
    true  /* have_positions */

    /* Zero is good enough for everything else. */
  };

  return const_cast<hb_buffer_t *> (&_hb_buffer_nil);
}

/**
 * hb_buffer_reference: (skip)
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: (transfer full):
 *
 * Since: 1.0
 **/
hb_buffer_t *
hb_buffer_reference (hb_buffer_t *buffer)
{
  return hb_object_reference (buffer);
}

/**
 * hb_buffer_destroy: (skip)
 * @buffer: a buffer.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_destroy (hb_buffer_t *buffer)
{
  if (!hb_object_destroy (buffer)) return;

  hb_unicode_funcs_destroy (buffer->unicode);

  free (buffer->info);
  free (buffer->pos);

  free (buffer);
}

/**
 * hb_buffer_set_user_data: (skip)
 * @buffer: a buffer.
 * @key: 
 * @data: 
 * @destroy: 
 * @replace: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_buffer_set_user_data (hb_buffer_t        *buffer,
			 hb_user_data_key_t *key,
			 void *              data,
			 hb_destroy_func_t   destroy,
			 hb_bool_t           replace)
{
  return hb_object_set_user_data (buffer, key, data, destroy, replace);
}

/**
 * hb_buffer_get_user_data: (skip)
 * @buffer: a buffer.
 * @key: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
void *
hb_buffer_get_user_data (hb_buffer_t        *buffer,
			 hb_user_data_key_t *key)
{
  return hb_object_get_user_data (buffer, key);
}


/**
 * hb_buffer_set_content_type:
 * @buffer: a buffer.
 * @content_type: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_content_type (hb_buffer_t              *buffer,
			    hb_buffer_content_type_t  content_type)
{
  buffer->content_type = content_type;
}

/**
 * hb_buffer_get_content_type:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_buffer_content_type_t
hb_buffer_get_content_type (hb_buffer_t *buffer)
{
  return buffer->content_type;
}


/**
 * hb_buffer_set_unicode_funcs:
 * @buffer: a buffer.
 * @unicode_funcs: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_unicode_funcs (hb_buffer_t        *buffer,
			     hb_unicode_funcs_t *unicode_funcs)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  if (!unicode_funcs)
    unicode_funcs = hb_unicode_funcs_get_default ();


  hb_unicode_funcs_reference (unicode_funcs);
  hb_unicode_funcs_destroy (buffer->unicode);
  buffer->unicode = unicode_funcs;
}

/**
 * hb_buffer_get_unicode_funcs:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_unicode_funcs_t *
hb_buffer_get_unicode_funcs (hb_buffer_t        *buffer)
{
  return buffer->unicode;
}

/**
 * hb_buffer_set_direction:
 * @buffer: a buffer.
 * @direction: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_direction (hb_buffer_t    *buffer,
			 hb_direction_t  direction)

{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->props.direction = direction;
}

/**
 * hb_buffer_get_direction:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_direction_t
hb_buffer_get_direction (hb_buffer_t    *buffer)
{
  return buffer->props.direction;
}

/**
 * hb_buffer_set_script:
 * @buffer: a buffer.
 * @script: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_script (hb_buffer_t *buffer,
		      hb_script_t  script)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->props.script = script;
}

/**
 * hb_buffer_get_script:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_script_t
hb_buffer_get_script (hb_buffer_t *buffer)
{
  return buffer->props.script;
}

/**
 * hb_buffer_set_language:
 * @buffer: a buffer.
 * @language: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_language (hb_buffer_t   *buffer,
			hb_language_t  language)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->props.language = language;
}

/**
 * hb_buffer_get_language:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_language_t
hb_buffer_get_language (hb_buffer_t *buffer)
{
  return buffer->props.language;
}

/**
 * hb_buffer_set_segment_properties:
 * @buffer: a buffer.
 * @props: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_segment_properties (hb_buffer_t *buffer,
				  const hb_segment_properties_t *props)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->props = *props;
}

/**
 * hb_buffer_get_segment_properties:
 * @buffer: a buffer.
 * @props: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_get_segment_properties (hb_buffer_t *buffer,
				  hb_segment_properties_t *props)
{
  *props = buffer->props;
}


/**
 * hb_buffer_set_flags:
 * @buffer: a buffer.
 * @flags: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_flags (hb_buffer_t       *buffer,
		     hb_buffer_flags_t  flags)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->flags = flags;
}

/**
 * hb_buffer_get_flags:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_buffer_flags_t
hb_buffer_get_flags (hb_buffer_t *buffer)
{
  return buffer->flags;
}


/**
 * hb_buffer_set_replacement_codepoint:
 * @buffer: a buffer.
 * @replacement: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_set_replacement_codepoint (hb_buffer_t    *buffer,
				     hb_codepoint_t  replacement)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return;

  buffer->replacement = replacement;
}

/**
 * hb_buffer_get_replacement_codepoint:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_codepoint_t
hb_buffer_get_replacement_codepoint (hb_buffer_t    *buffer)
{
  return buffer->replacement;
}


/**
 * hb_buffer_reset:
 * @buffer: a buffer.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_reset (hb_buffer_t *buffer)
{
  buffer->reset ();
}

/**
 * hb_buffer_clear_contents:
 * @buffer: a buffer.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_clear_contents (hb_buffer_t *buffer)
{
  buffer->clear ();
}

/**
 * hb_buffer_pre_allocate:
 * @buffer: a buffer.
 * @size: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_buffer_pre_allocate (hb_buffer_t *buffer, unsigned int size)
{
  return buffer->ensure (size);
}

/**
 * hb_buffer_allocation_successful:
 * @buffer: a buffer.
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_buffer_allocation_successful (hb_buffer_t  *buffer)
{
  return !buffer->in_error;
}

/**
 * hb_buffer_add:
 * @buffer: a buffer.
 * @codepoint: 
 * @cluster: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add (hb_buffer_t    *buffer,
	       hb_codepoint_t  codepoint,
	       unsigned int    cluster)
{
  buffer->add (codepoint, cluster);
  buffer->clear_context (1);
}

/**
 * hb_buffer_set_length:
 * @buffer: a buffer.
 * @length: 
 *
 * 
 *
 * Return value: 
 *
 * Since: 1.0
 **/
hb_bool_t
hb_buffer_set_length (hb_buffer_t  *buffer,
		      unsigned int  length)
{
  if (unlikely (hb_object_is_inert (buffer)))
    return length == 0;

  if (!buffer->ensure (length))
    return false;

  /* Wipe the new space */
  if (length > buffer->len) {
    memset (buffer->info + buffer->len, 0, sizeof (buffer->info[0]) * (length - buffer->len));
    if (buffer->have_positions)
      memset (buffer->pos + buffer->len, 0, sizeof (buffer->pos[0]) * (length - buffer->len));
  }

  buffer->len = length;

  if (!length)
  {
    buffer->content_type = HB_BUFFER_CONTENT_TYPE_INVALID;
    buffer->clear_context (0);
  }
  buffer->clear_context (1);

  return true;
}

/**
 * hb_buffer_get_length:
 * @buffer: a buffer.
 *
 * Returns the number of items in the buffer.
 *
 * Return value: buffer length.
 *
 * Since: 1.0
 **/
unsigned int
hb_buffer_get_length (hb_buffer_t *buffer)
{
  return buffer->len;
}

/**
 * hb_buffer_get_glyph_infos:
 * @buffer: a buffer.
 * @length: (out): output array length.
 *
 * Returns buffer glyph information array.  Returned pointer
 * is valid as long as buffer contents are not modified.
 *
 * Return value: (transfer none) (array length=length): buffer glyph information array.
 *
 * Since: 1.0
 **/
hb_glyph_info_t *
hb_buffer_get_glyph_infos (hb_buffer_t  *buffer,
                           unsigned int *length)
{
  if (length)
    *length = buffer->len;

  return (hb_glyph_info_t *) buffer->info;
}

/**
 * hb_buffer_get_glyph_positions:
 * @buffer: a buffer.
 * @length: (out): output length.
 *
 * Returns buffer glyph position array.  Returned pointer
 * is valid as long as buffer contents are not modified.
 *
 * Return value: (transfer none) (array length=length): buffer glyph position array.
 *
 * Since: 1.0
 **/
hb_glyph_position_t *
hb_buffer_get_glyph_positions (hb_buffer_t  *buffer,
                               unsigned int *length)
{
  if (!buffer->have_positions)
    buffer->clear_positions ();

  if (length)
    *length = buffer->len;

  return (hb_glyph_position_t *) buffer->pos;
}

/**
 * hb_buffer_reverse:
 * @buffer: a buffer.
 *
 * Reverses buffer contents.
 *
 * Since: 1.0
 **/
void
hb_buffer_reverse (hb_buffer_t *buffer)
{
  buffer->reverse ();
}

/**
 * hb_buffer_reverse_clusters:
 * @buffer: a buffer.
 *
 * Reverses buffer clusters.  That is, the buffer contents are
 * reversed, then each cluster (consecutive items having the
 * same cluster number) are reversed again.
 *
 * Since: 1.0
 **/
void
hb_buffer_reverse_clusters (hb_buffer_t *buffer)
{
  buffer->reverse_clusters ();
}

/**
 * hb_buffer_guess_segment_properties:
 * @buffer: a buffer.
 *
 * Sets unset buffer segment properties based on buffer Unicode
 * contents.  If buffer is not empty, it must have content type
 * %HB_BUFFER_CONTENT_TYPE_UNICODE.
 *
 * If buffer script is not set (ie. is %HB_SCRIPT_INVALID), it
 * will be set to the Unicode script of the first character in
 * the buffer that has a script other than %HB_SCRIPT_COMMON,
 * %HB_SCRIPT_INHERITED, and %HB_SCRIPT_UNKNOWN.
 *
 * Next, if buffer direction is not set (ie. is %HB_DIRECTION_INVALID),
 * it will be set to the natural horizontal direction of the
 * buffer script as returned by hb_script_get_horizontal_direction().
 *
 * Finally, if buffer language is not set (ie. is %HB_LANGUAGE_INVALID),
 * it will be set to the process's default language as returned by
 * hb_language_get_default().  This may change in the future by
 * taking buffer script into consideration when choosing a language.
 *
 * Since: 1.0
 **/
void
hb_buffer_guess_segment_properties (hb_buffer_t *buffer)
{
  buffer->guess_segment_properties ();
}

template <typename utf_t>
static inline void
hb_buffer_add_utf (hb_buffer_t  *buffer,
		   const typename utf_t::codepoint_t *text,
		   int           text_length,
		   unsigned int  item_offset,
		   int           item_length)
{
  typedef typename utf_t::codepoint_t T;
  const hb_codepoint_t replacement = buffer->replacement;

  assert (buffer->content_type == HB_BUFFER_CONTENT_TYPE_UNICODE ||
	  (!buffer->len && buffer->content_type == HB_BUFFER_CONTENT_TYPE_INVALID));

  if (unlikely (hb_object_is_inert (buffer)))
    return;

  if (text_length == -1)
    text_length = utf_t::strlen (text);

  if (item_length == -1)
    item_length = text_length - item_offset;

  buffer->ensure (buffer->len + item_length * sizeof (T) / 4);

  /* If buffer is empty and pre-context provided, install it.
   * This check is written this way, to make sure people can
   * provide pre-context in one add_utf() call, then provide
   * text in a follow-up call.  See:
   *
   * https://bugzilla.mozilla.org/show_bug.cgi?id=801410#c13
   */
  if (!buffer->len && item_offset > 0)
  {
    /* Add pre-context */
    buffer->clear_context (0);
    const T *prev = text + item_offset;
    const T *start = text;
    while (start < prev && buffer->context_len[0] < buffer->CONTEXT_LENGTH)
    {
      hb_codepoint_t u;
      prev = utf_t::prev (prev, start, &u, replacement);
      buffer->context[0][buffer->context_len[0]++] = u;
    }
  }

  const T *next = text + item_offset;
  const T *end = next + item_length;
  while (next < end)
  {
    hb_codepoint_t u;
    const T *old_next = next;
    next = utf_t::next (next, end, &u, replacement);
    buffer->add (u, old_next - (const T *) text);
  }

  /* Add post-context */
  buffer->clear_context (1);
  end = text + text_length;
  while (next < end && buffer->context_len[1] < buffer->CONTEXT_LENGTH)
  {
    hb_codepoint_t u;
    next = utf_t::next (next, end, &u, replacement);
    buffer->context[1][buffer->context_len[1]++] = u;
  }

  buffer->content_type = HB_BUFFER_CONTENT_TYPE_UNICODE;
}

/**
 * hb_buffer_add_utf8:
 * @buffer: a buffer.
 * @text: (array length=text_length) (element-type uint8_t):
 * @text_length: 
 * @item_offset: 
 * @item_length: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add_utf8 (hb_buffer_t  *buffer,
		    const char   *text,
		    int           text_length,
		    unsigned int  item_offset,
		    int           item_length)
{
  hb_buffer_add_utf<hb_utf8_t> (buffer, (const uint8_t *) text, text_length, item_offset, item_length);
}

/**
 * hb_buffer_add_utf16:
 * @buffer: a buffer.
 * @text: (array length=text_length):
 * @text_length: 
 * @item_offset: 
 * @item_length: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add_utf16 (hb_buffer_t    *buffer,
		     const uint16_t *text,
		     int             text_length,
		     unsigned int    item_offset,
		     int             item_length)
{
  hb_buffer_add_utf<hb_utf16_t> (buffer, text, text_length, item_offset, item_length);
}

/**
 * hb_buffer_add_utf32:
 * @buffer: a buffer.
 * @text: (array length=text_length):
 * @text_length: 
 * @item_offset: 
 * @item_length: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add_utf32 (hb_buffer_t    *buffer,
		     const uint32_t *text,
		     int             text_length,
		     unsigned int    item_offset,
		     int             item_length)
{
  hb_buffer_add_utf<hb_utf32_t<> > (buffer, text, text_length, item_offset, item_length);
}

/**
 * hb_buffer_add_latin1:
 * @buffer: a buffer.
 * @text: (array length=text_length) (element-type uint8_t):
 * @text_length: 
 * @item_offset: 
 * @item_length: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add_latin1 (hb_buffer_t   *buffer,
		      const uint8_t *text,
		      int            text_length,
		      unsigned int   item_offset,
		      int            item_length)
{
  hb_buffer_add_utf<hb_latin1_t> (buffer, text, text_length, item_offset, item_length);
}

/**
 * hb_buffer_add_codepoints:
 * @buffer: a buffer.
 * @text: (array length=text_length):
 * @text_length: 
 * @item_offset: 
 * @item_length: 
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_add_codepoints (hb_buffer_t          *buffer,
			  const hb_codepoint_t *text,
			  int                   text_length,
			  unsigned int          item_offset,
			  int                   item_length)
{
  hb_buffer_add_utf<hb_utf32_t<false> > (buffer, text, text_length, item_offset, item_length);
}


static int
compare_info_codepoint (const hb_glyph_info_t *pa,
			const hb_glyph_info_t *pb)
{
  return (int) pb->codepoint - (int) pa->codepoint;
}

static inline void
normalize_glyphs_cluster (hb_buffer_t *buffer,
			  unsigned int start,
			  unsigned int end,
			  bool backward)
{
  hb_glyph_position_t *pos = buffer->pos;

  /* Total cluster advance */
  hb_position_t total_x_advance = 0, total_y_advance = 0;
  for (unsigned int i = start; i < end; i++)
  {
    total_x_advance += pos[i].x_advance;
    total_y_advance += pos[i].y_advance;
  }

  hb_position_t x_advance = 0, y_advance = 0;
  for (unsigned int i = start; i < end; i++)
  {
    pos[i].x_offset += x_advance;
    pos[i].y_offset += y_advance;

    x_advance += pos[i].x_advance;
    y_advance += pos[i].y_advance;

    pos[i].x_advance = 0;
    pos[i].y_advance = 0;
  }

  if (backward)
  {
    /* Transfer all cluster advance to the last glyph. */
    pos[end - 1].x_advance = total_x_advance;
    pos[end - 1].y_advance = total_y_advance;

    hb_bubble_sort (buffer->info + start, end - start - 1, compare_info_codepoint, buffer->pos + start);
  } else {
    /* Transfer all cluster advance to the first glyph. */
    pos[start].x_advance += total_x_advance;
    pos[start].y_advance += total_y_advance;
    for (unsigned int i = start + 1; i < end; i++) {
      pos[i].x_offset -= total_x_advance;
      pos[i].y_offset -= total_y_advance;
    }
    hb_bubble_sort (buffer->info + start + 1, end - start - 1, compare_info_codepoint, buffer->pos + start + 1);
  }
}

/**
 * hb_buffer_normalize_glyphs:
 * @buffer: a buffer.
 *
 * 
 *
 * Since: 1.0
 **/
void
hb_buffer_normalize_glyphs (hb_buffer_t *buffer)
{
  assert (buffer->have_positions);
  assert (buffer->content_type == HB_BUFFER_CONTENT_TYPE_GLYPHS);

  bool backward = HB_DIRECTION_IS_BACKWARD (buffer->props.direction);

  unsigned int count = buffer->len;
  if (unlikely (!count)) return;
  hb_glyph_info_t *info = buffer->info;

  unsigned int start = 0;
  unsigned int end;
  for (end = start + 1; end < count; end++)
    if (info[start].cluster != info[end].cluster) {
      normalize_glyphs_cluster (buffer, start, end, backward);
      start = end;
    }
  normalize_glyphs_cluster (buffer, start, end, backward);
}
