/*
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
 * Google Author(s): Behdad Esfahbod
 */

#include "hb-ot-shape-normalize-private.hh"
#include "hb-ot-shape-complex-private.hh"
#include "hb-ot-shape-private.hh"


/*
 * HIGHLEVEL DESIGN:
 *
 * This file exports one main function: _hb_ot_shape_normalize().
 *
 * This function closely reflects the Unicode Normalization Algorithm,
 * yet it's different.
 *
 * Each shaper specifies whether it prefers decomposed (NFD) or composed (NFC).
 * The logic however tries to use whatever the font can support.
 *
 * In general what happens is that: each grapheme is decomposed in a chain
 * of 1:2 decompositions, marks reordered, and then recomposed if desired,
 * so far it's like Unicode Normalization.  However, the decomposition and
 * recomposition only happens if the font supports the resulting characters.
 *
 * The goals are:
 *
 *   - Try to render all canonically equivalent strings similarly.  To really
 *     achieve this we have to always do the full decomposition and then
 *     selectively recompose from there.  It's kinda too expensive though, so
 *     we skip some cases.  For example, if composed is desired, we simply
 *     don't touch 1-character clusters that are supported by the font, even
 *     though their NFC may be different.
 *
 *   - When a font has a precomposed character for a sequence but the 'ccmp'
 *     feature in the font is not adequate, use the precomposed character
 *     which typically has better mark positioning.
 *
 *   - When a font does not support a combining mark, but supports it precomposed
 *     with previous base, use that.  This needs the itemizer to have this
 *     knowledge too.  We need to provide assistance to the itemizer.
 *
 *   - When a font does not support a character but supports its decomposition,
 *     well, use the decomposition (preferring the canonical decomposition, but
 *     falling back to the compatibility decomposition if necessary).  The
 *     compatibility decomposition is really nice to have, for characters like
 *     ellipsis, or various-sized space characters.
 *
 *   - The complex shapers can customize the compose and decompose functions to
 *     offload some of their requirements to the normalizer.  For example, the
 *     Indic shaper may want to disallow recomposing of two matras.
 *
 *   - We try compatibility decomposition if decomposing through canonical
 *     decomposition alone failed to find a sequence that the font supports.
 *     We don't try compatibility decomposition recursively during the canonical
 *     decomposition phase.  This has minimal impact.  There are only a handful
 *     of Greek letter that have canonical decompositions that include characters
 *     with compatibility decomposition.  Those can be found using this command:
 *
 *     egrep  "`echo -n ';('; grep ';<' UnicodeData.txt | cut -d';' -f1 | tr '\n' '|'; echo ') '`" UnicodeData.txt
 */

static bool
decompose_unicode (const hb_ot_shape_normalize_context_t *c,
		   hb_codepoint_t  ab,
		   hb_codepoint_t *a,
		   hb_codepoint_t *b)
{
  return c->unicode->decompose (ab, a, b);
}

static bool
compose_unicode (const hb_ot_shape_normalize_context_t *c,
		 hb_codepoint_t  a,
		 hb_codepoint_t  b,
		 hb_codepoint_t *ab)
{
  return c->unicode->compose (a, b, ab);
}

static inline void
set_glyph (hb_glyph_info_t &info, hb_font_t *font)
{
  font->get_glyph (info.codepoint, 0, &info.glyph_index());
}

static inline void
output_char (hb_buffer_t *buffer, hb_codepoint_t unichar, hb_codepoint_t glyph)
{
  buffer->cur().glyph_index() = glyph;
  buffer->output_glyph (unichar);
  _hb_glyph_info_set_unicode_props (&buffer->prev(), buffer->unicode);
}

static inline void
next_char (hb_buffer_t *buffer, hb_codepoint_t glyph)
{
  buffer->cur().glyph_index() = glyph;
  buffer->next_glyph ();
}

static inline void
skip_char (hb_buffer_t *buffer)
{
  buffer->skip_glyph ();
}

/* Returns 0 if didn't decompose, number of resulting characters otherwise. */
static inline unsigned int
decompose (const hb_ot_shape_normalize_context_t *c, bool shortest, hb_codepoint_t ab)
{
  hb_codepoint_t a, b, a_glyph, b_glyph;
  hb_buffer_t * const buffer = c->buffer;
  hb_font_t * const font = c->font;

  if (!c->decompose (c, ab, &a, &b) ||
      (b && !font->get_glyph (b, 0, &b_glyph)))
    return 0;

  bool has_a = font->get_glyph (a, 0, &a_glyph);
  if (shortest && has_a) {
    /* Output a and b */
    output_char (buffer, a, a_glyph);
    if (likely (b)) {
      output_char (buffer, b, b_glyph);
      return 2;
    }
    return 1;
  }

  unsigned int ret;
  if ((ret = decompose (c, shortest, a))) {
    if (b) {
      output_char (buffer, b, b_glyph);
      return ret + 1;
    }
    return ret;
  }

  if (has_a) {
    output_char (buffer, a, a_glyph);
    if (likely (b)) {
      output_char (buffer, b, b_glyph);
      return 2;
    }
    return 1;
  }

  return 0;
}

/* Returns 0 if didn't decompose, number of resulting characters otherwise. */
static inline unsigned int
decompose_compatibility (const hb_ot_shape_normalize_context_t *c, hb_codepoint_t u)
{
  unsigned int len, i;
  hb_codepoint_t decomposed[HB_UNICODE_MAX_DECOMPOSITION_LEN];
  hb_codepoint_t glyphs[HB_UNICODE_MAX_DECOMPOSITION_LEN];

  len = c->buffer->unicode->decompose_compatibility (u, decomposed);
  if (!len)
    return 0;

  for (i = 0; i < len; i++)
    if (!c->font->get_glyph (decomposed[i], 0, &glyphs[i]))
      return 0;

  for (i = 0; i < len; i++)
    output_char (c->buffer, decomposed[i], glyphs[i]);

  return len;
}

static inline void
decompose_current_character (const hb_ot_shape_normalize_context_t *c, bool shortest)
{
  hb_buffer_t * const buffer = c->buffer;
  hb_codepoint_t u = buffer->cur().codepoint;
  hb_codepoint_t glyph;

  /* Kind of a cute waterfall here... */
  if (shortest && c->font->get_glyph (u, 0, &glyph))
    next_char (buffer, glyph);
  else if (decompose (c, shortest, u))
    skip_char (buffer);
  else if (!shortest && c->font->get_glyph (u, 0, &glyph))
    next_char (buffer, glyph);
  else if (decompose_compatibility (c, u))
    skip_char (buffer);
  else
    next_char (buffer, glyph); /* glyph is initialized in earlier branches. */
}

static inline void
handle_variation_selector_cluster (const hb_ot_shape_normalize_context_t *c, unsigned int end, bool short_circuit)
{
  /* TODO Currently if there's a variation-selector we give-up, it's just too hard. */
  hb_buffer_t * const buffer = c->buffer;
  hb_font_t * const font = c->font;
  for (; buffer->idx < end - 1;) {
    if (unlikely (buffer->unicode->is_variation_selector (buffer->cur(+1).codepoint))) {
      /* The next two lines are some ugly lines... But work. */
      if (font->get_glyph (buffer->cur().codepoint, buffer->cur(+1).codepoint, &buffer->cur().glyph_index()))
      {
	buffer->replace_glyphs (2, 1, &buffer->cur().codepoint);
      }
      else
      {
        /* Just pass on the two characters separately, let GSUB do its magic. */
	set_glyph (buffer->cur(), font);
	buffer->next_glyph ();
	set_glyph (buffer->cur(), font);
	buffer->next_glyph ();
      }
      /* Skip any further variation selectors. */
      while (buffer->idx < end && unlikely (buffer->unicode->is_variation_selector (buffer->cur().codepoint)))
      {
	set_glyph (buffer->cur(), font);
	buffer->next_glyph ();
      }
    } else {
      set_glyph (buffer->cur(), font);
      buffer->next_glyph ();
    }
  }
  if (likely (buffer->idx < end)) {
    set_glyph (buffer->cur(), font);
    buffer->next_glyph ();
  }
}

static inline void
decompose_multi_char_cluster (const hb_ot_shape_normalize_context_t *c, unsigned int end, bool short_circuit)
{
  hb_buffer_t * const buffer = c->buffer;
  for (unsigned int i = buffer->idx; i < end; i++)
    if (unlikely (buffer->unicode->is_variation_selector (buffer->info[i].codepoint))) {
      handle_variation_selector_cluster (c, end, short_circuit);
      return;
    }

  while (buffer->idx < end)
    decompose_current_character (c, short_circuit);
}

static inline void
decompose_cluster (const hb_ot_shape_normalize_context_t *c, unsigned int end, bool might_short_circuit, bool always_short_circuit)
{
  if (likely (c->buffer->idx + 1 == end))
    decompose_current_character (c, might_short_circuit);
  else
    decompose_multi_char_cluster (c, end, always_short_circuit);
}


static int
compare_combining_class (const hb_glyph_info_t *pa, const hb_glyph_info_t *pb)
{
  unsigned int a = _hb_glyph_info_get_modified_combining_class (pa);
  unsigned int b = _hb_glyph_info_get_modified_combining_class (pb);

  return a < b ? -1 : a == b ? 0 : +1;
}


void
_hb_ot_shape_normalize (const hb_ot_shape_plan_t *plan,
			hb_buffer_t *buffer,
			hb_font_t *font)
{
  _hb_buffer_assert_unicode_vars (buffer);

  hb_ot_shape_normalization_mode_t mode = plan->shaper->normalization_preference;
  const hb_ot_shape_normalize_context_t c = {
    plan,
    buffer,
    font,
    buffer->unicode,
    plan->shaper->decompose ? plan->shaper->decompose : decompose_unicode,
    plan->shaper->compose   ? plan->shaper->compose   : compose_unicode
  };

  bool always_short_circuit = mode == HB_OT_SHAPE_NORMALIZATION_MODE_NONE;
  bool might_short_circuit = always_short_circuit ||
			     (mode != HB_OT_SHAPE_NORMALIZATION_MODE_DECOMPOSED &&
			      mode != HB_OT_SHAPE_NORMALIZATION_MODE_COMPOSED_DIACRITICS_NO_SHORT_CIRCUIT);
  unsigned int count;

  /* We do a fairly straightforward yet custom normalization process in three
   * separate rounds: decompose, reorder, recompose (if desired).  Currently
   * this makes two buffer swaps.  We can make it faster by moving the last
   * two rounds into the inner loop for the first round, but it's more readable
   * this way. */


  /* First round, decompose */

  buffer->clear_output ();
  count = buffer->len;
  for (buffer->idx = 0; buffer->idx < count;)
  {
    unsigned int end;
    for (end = buffer->idx + 1; end < count; end++)
      if (buffer->cur().cluster != buffer->info[end].cluster)
        break;

    decompose_cluster (&c, end, might_short_circuit, always_short_circuit);
  }
  buffer->swap_buffers ();


  /* Second round, reorder (inplace) */

  count = buffer->len;
  for (unsigned int i = 0; i < count; i++)
  {
    if (_hb_glyph_info_get_modified_combining_class (&buffer->info[i]) == 0)
      continue;

    unsigned int end;
    for (end = i + 1; end < count; end++)
      if (_hb_glyph_info_get_modified_combining_class (&buffer->info[end]) == 0)
        break;

    /* We are going to do a bubble-sort.  Only do this if the
     * sequence is short.  Doing it on long sequences can result
     * in an O(n^2) DoS. */
    if (end - i > 10) {
      i = end;
      continue;
    }

    hb_bubble_sort (buffer->info + i, end - i, compare_combining_class);

    i = end;
  }


  if (mode == HB_OT_SHAPE_NORMALIZATION_MODE_NONE ||
      mode == HB_OT_SHAPE_NORMALIZATION_MODE_DECOMPOSED)
    return;

  /* Third round, recompose */

  /* As noted in the comment earlier, we don't try to combine
   * ccc=0 chars with their previous Starter. */

  buffer->clear_output ();
  count = buffer->len;
  unsigned int starter = 0;
  buffer->next_glyph ();
  while (buffer->idx < count)
  {
    hb_codepoint_t composed, glyph;
    if (/* We don't try to compose a non-mark character with it's preceding starter.
	 * This is both an optimization to avoid trying to compose every two neighboring
	 * glyphs in most scripts AND a desired feature for Hangul.  Apparently Hangul
	 * fonts are not designed to mix-and-match pre-composed syllables and Jamo. */
	HB_UNICODE_GENERAL_CATEGORY_IS_MARK (_hb_glyph_info_get_general_category (&buffer->cur())) &&
	/* If there's anything between the starter and this char, they should have CCC
	 * smaller than this character's. */
	(starter == buffer->out_len - 1 ||
	 _hb_glyph_info_get_modified_combining_class (&buffer->prev()) < _hb_glyph_info_get_modified_combining_class (&buffer->cur())) &&
	/* And compose. */
	c.compose (&c,
		   buffer->out_info[starter].codepoint,
		   buffer->cur().codepoint,
		   &composed) &&
	/* And the font has glyph for the composite. */
	font->get_glyph (composed, 0, &glyph))
    {
      /* Composes. */
      buffer->next_glyph (); /* Copy to out-buffer. */
      if (unlikely (buffer->in_error))
        return;
      buffer->merge_out_clusters (starter, buffer->out_len);
      buffer->out_len--; /* Remove the second composable. */
      /* Modify starter and carry on. */
      buffer->out_info[starter].codepoint = composed;
      buffer->out_info[starter].glyph_index() = glyph;
      _hb_glyph_info_set_unicode_props (&buffer->out_info[starter], buffer->unicode);

      continue;
    }

    /* Blocked, or doesn't compose. */
    buffer->next_glyph ();

    if (_hb_glyph_info_get_modified_combining_class (&buffer->prev()) == 0)
      starter = buffer->out_len - 1;
  }
  buffer->swap_buffers ();

}
