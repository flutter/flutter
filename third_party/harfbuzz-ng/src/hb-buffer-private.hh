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

#ifndef HB_BUFFER_PRIVATE_HH
#define HB_BUFFER_PRIVATE_HH

#include "hb-private.hh"
#include "hb-object-private.hh"
#include "hb-unicode-private.hh"


ASSERT_STATIC (sizeof (hb_glyph_info_t) == 20);
ASSERT_STATIC (sizeof (hb_glyph_info_t) == sizeof (hb_glyph_position_t));


/*
 * hb_buffer_t
 */

struct hb_buffer_t {
  hb_object_header_t header;
  ASSERT_POD ();

  /* Information about how the text in the buffer should be treated */
  hb_unicode_funcs_t *unicode; /* Unicode functions */
  hb_buffer_flags_t flags; /* BOT / EOT / etc. */
  hb_codepoint_t replacement; /* U+FFFD or something else. */

  /* Buffer contents */
  hb_buffer_content_type_t content_type;
  hb_segment_properties_t props; /* Script, language, direction */

  bool in_error; /* Allocation failed */
  bool have_output; /* Whether we have an output buffer going on */
  bool have_positions; /* Whether we have positions */

  unsigned int idx; /* Cursor into ->info and ->pos arrays */
  unsigned int len; /* Length of ->info and ->pos arrays */
  unsigned int out_len; /* Length of ->out array if have_output */

  unsigned int allocated; /* Length of allocated arrays */
  hb_glyph_info_t     *info;
  hb_glyph_info_t     *out_info;
  hb_glyph_position_t *pos;

  inline hb_glyph_info_t &cur (unsigned int i = 0) { return info[idx + i]; }
  inline hb_glyph_info_t cur (unsigned int i = 0) const { return info[idx + i]; }

  inline hb_glyph_position_t &cur_pos (unsigned int i = 0) { return pos[idx + i]; }
  inline hb_glyph_position_t cur_pos (unsigned int i = 0) const { return pos[idx + i]; }

  inline hb_glyph_info_t &prev (void) { return out_info[out_len - 1]; }
  inline hb_glyph_info_t prev (void) const { return info[out_len - 1]; }

  inline bool has_separate_output (void) const { return info != out_info; }

  unsigned int serial;

  /* These reflect current allocations of the bytes in glyph_info_t's var1 and var2. */
  uint8_t allocated_var_bytes[8];
  const char *allocated_var_owner[8];

  /* Text before / after the main buffer contents.
   * Always in Unicode, and ordered outward.
   * Index 0 is for "pre-context", 1 for "post-context". */
  static const unsigned int CONTEXT_LENGTH = 5;
  hb_codepoint_t context[2][CONTEXT_LENGTH];
  unsigned int context_len[2];


  /* Methods */

  HB_INTERNAL void reset (void);
  HB_INTERNAL void clear (void);

  inline unsigned int backtrack_len (void) const
  { return have_output? out_len : idx; }
  inline unsigned int lookahead_len (void) const
  { return len - idx; }
  inline unsigned int next_serial (void) { return serial++; }

  HB_INTERNAL void allocate_var (unsigned int byte_i, unsigned int count, const char *owner);
  HB_INTERNAL void deallocate_var (unsigned int byte_i, unsigned int count, const char *owner);
  HB_INTERNAL void assert_var (unsigned int byte_i, unsigned int count, const char *owner);
  HB_INTERNAL void deallocate_var_all (void);

  HB_INTERNAL void add (hb_codepoint_t  codepoint,
			unsigned int    cluster);
  HB_INTERNAL void add_info (const hb_glyph_info_t &glyph_info);

  HB_INTERNAL void reverse_range (unsigned int start, unsigned int end);
  HB_INTERNAL void reverse (void);
  HB_INTERNAL void reverse_clusters (void);
  HB_INTERNAL void guess_segment_properties (void);

  HB_INTERNAL void swap_buffers (void);
  HB_INTERNAL void remove_output (void);
  HB_INTERNAL void clear_output (void);
  HB_INTERNAL void clear_positions (void);

  HB_INTERNAL void replace_glyphs (unsigned int num_in,
				   unsigned int num_out,
				   const hb_codepoint_t *glyph_data);

  HB_INTERNAL void replace_glyph (hb_codepoint_t glyph_index);
  /* Makes a copy of the glyph at idx to output and replace glyph_index */
  HB_INTERNAL void output_glyph (hb_codepoint_t glyph_index);
  HB_INTERNAL void output_info (const hb_glyph_info_t &glyph_info);
  /* Copies glyph at idx to output but doesn't advance idx */
  HB_INTERNAL void copy_glyph (void);
  HB_INTERNAL bool move_to (unsigned int i); /* i is output-buffer index. */
  /* Copies glyph at idx to output and advance idx.
   * If there's no output, just advance idx. */
  inline void
  next_glyph (void)
  {
    if (have_output)
    {
      if (unlikely (out_info != info || out_len != idx)) {
	if (unlikely (!make_room_for (1, 1))) return;
	out_info[out_len] = info[idx];
      }
      out_len++;
    }

    idx++;
  }

  /* Advance idx without copying to output. */
  inline void skip_glyph (void) { idx++; }

  inline void reset_masks (hb_mask_t mask)
  {
    for (unsigned int j = 0; j < len; j++)
      info[j].mask = mask;
  }
  inline void add_masks (hb_mask_t mask)
  {
    for (unsigned int j = 0; j < len; j++)
      info[j].mask |= mask;
  }
  HB_INTERNAL void set_masks (hb_mask_t value,
			      hb_mask_t mask,
			      unsigned int cluster_start,
			      unsigned int cluster_end);

  HB_INTERNAL void merge_clusters (unsigned int start,
				   unsigned int end);
  HB_INTERNAL void merge_out_clusters (unsigned int start,
				       unsigned int end);

  /* Internal methods */
  HB_INTERNAL bool enlarge (unsigned int size);

  inline bool ensure (unsigned int size)
  { return likely (!size || size < allocated) ? true : enlarge (size); }

  inline bool ensure_inplace (unsigned int size)
  { return likely (!size || size < allocated); }

  HB_INTERNAL bool make_room_for (unsigned int num_in, unsigned int num_out);
  HB_INTERNAL bool shift_forward (unsigned int count);

  typedef long scratch_buffer_t;
  HB_INTERNAL scratch_buffer_t *get_scratch_buffer (unsigned int *size);

  inline void clear_context (unsigned int side) { context_len[side] = 0; }
};


#define HB_BUFFER_XALLOCATE_VAR(b, func, var, owner) \
  b->func (offsetof (hb_glyph_info_t, var) - offsetof(hb_glyph_info_t, var1), \
	   sizeof (b->info[0].var), owner)
#define HB_BUFFER_ALLOCATE_VAR(b, var) \
	HB_BUFFER_XALLOCATE_VAR (b, allocate_var, var (), #var)
#define HB_BUFFER_DEALLOCATE_VAR(b, var) \
	HB_BUFFER_XALLOCATE_VAR (b, deallocate_var, var (), #var)
#define HB_BUFFER_ASSERT_VAR(b, var) \
	HB_BUFFER_XALLOCATE_VAR (b, assert_var, var (), #var)


#endif /* HB_BUFFER_PRIVATE_HH */
