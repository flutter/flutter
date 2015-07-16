/*
 * Copyright © 2013  Google, Inc.
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


/* Hangul shaper */


/* Same order as the feature array below */
enum {
  NONE,

  LJMO,
  VJMO,
  TJMO,

  FIRST_HANGUL_FEATURE = LJMO,
  HANGUL_FEATURE_COUNT = TJMO + 1
};

static const hb_tag_t hangul_features[HANGUL_FEATURE_COUNT] =
{
  HB_TAG_NONE,
  HB_TAG('l','j','m','o'),
  HB_TAG('v','j','m','o'),
  HB_TAG('t','j','m','o')
};

static void
collect_features_hangul (hb_ot_shape_planner_t *plan)
{
  hb_ot_map_builder_t *map = &plan->map;

  for (unsigned int i = FIRST_HANGUL_FEATURE; i < HANGUL_FEATURE_COUNT; i++)
    map->add_feature (hangul_features[i], 1, F_NONE);
}

static void
override_features_hangul (hb_ot_shape_planner_t *plan)
{
  /* Uniscribe does not apply 'calt' for Hangul, and certain fonts
   * (Noto Sans CJK, Source Sans Han, etc) apply all of jamo lookups
   * in calt, which is not desirable. */
  plan->map.add_feature (HB_TAG('c','a','l','t'), 0, F_GLOBAL);
}

struct hangul_shape_plan_t
{
  ASSERT_POD ();

  hb_mask_t mask_array[HANGUL_FEATURE_COUNT];
};

static void *
data_create_hangul (const hb_ot_shape_plan_t *plan)
{
  hangul_shape_plan_t *hangul_plan = (hangul_shape_plan_t *) calloc (1, sizeof (hangul_shape_plan_t));
  if (unlikely (!hangul_plan))
    return NULL;

  for (unsigned int i = 0; i < HANGUL_FEATURE_COUNT; i++)
    hangul_plan->mask_array[i] = plan->map.get_1_mask (hangul_features[i]);

  return hangul_plan;
}

static void
data_destroy_hangul (void *data)
{
  free (data);
}

/* Constants for algorithmic hangul syllable [de]composition. */
#define LBase 0x1100u
#define VBase 0x1161u
#define TBase 0x11A7u
#define LCount 19u
#define VCount 21u
#define TCount 28u
#define SBase 0xAC00u
#define NCount (VCount * TCount)
#define SCount (LCount * NCount)

#define isCombiningL(u) (hb_in_range ((u), LBase, LBase+LCount-1))
#define isCombiningV(u) (hb_in_range ((u), VBase, VBase+VCount-1))
#define isCombiningT(u) (hb_in_range ((u), TBase+1, TBase+TCount-1))
#define isCombinedS(u) (hb_in_range ((u), SBase, SBase+SCount-1))

#define isL(u) (hb_in_ranges ((u), 0x1100u, 0x115Fu, 0xA960u, 0xA97Cu))
#define isV(u) (hb_in_ranges ((u), 0x1160u, 0x11A7u, 0xD7B0u, 0xD7C6u))
#define isT(u) (hb_in_ranges ((u), 0x11A8u, 0x11FFu, 0xD7CBu, 0xD7FBu))

#define isHangulTone(u) (hb_in_range ((u), 0x302Eu, 0x302Fu))

/* buffer var allocations */
#define hangul_shaping_feature() complex_var_u8_0() /* hangul jamo shaping feature */

static bool
is_zero_width_char (hb_font_t *font,
		    hb_codepoint_t unicode)
{
  hb_codepoint_t glyph;
  return hb_font_get_glyph (font, unicode, 0, &glyph) && hb_font_get_glyph_h_advance (font, glyph) == 0;
}

static void
preprocess_text_hangul (const hb_ot_shape_plan_t *plan,
			hb_buffer_t              *buffer,
			hb_font_t                *font)
{
  HB_BUFFER_ALLOCATE_VAR (buffer, hangul_shaping_feature);

  /* Hangul syllables come in two shapes: LV, and LVT.  Of those:
   *
   *   - LV can be precomposed, or decomposed.  Lets call those
   *     <LV> and <L,V>,
   *   - LVT can be fully precomposed, partically precomposed, or
   *     fully decomposed.  Ie. <LVT>, <LV,T>, or <L,V,T>.
   *
   * The composition / decomposition is mechanical.  However, not
   * all <L,V> sequences compose, and not all <LV,T> sequences
   * compose.
   *
   * Here are the specifics:
   *
   *   - <L>: U+1100..115F, U+A960..A97F
   *   - <V>: U+1160..11A7, U+D7B0..D7C7
   *   - <T>: U+11A8..11FF, U+D7CB..D7FB
   *
   *   - Only the <L,V> sequences for the 11xx ranges combine.
   *   - Only <LV,T> sequences for T in U+11A8..11C3 combine.
   *
   * Here is what we want to accomplish in this shaper:
   *
   *   - If the whole syllable can be precomposed, do that,
   *   - Otherwise, fully decompose and apply ljmo/vjmo/tjmo features.
   *   - If a valid syllable is followed by a Hangul tone mark, reorder the tone
   *     mark to precede the whole syllable - unless it is a zero-width glyph, in
   *     which case we leave it untouched, assuming it's designed to overstrike.
   *
   * That is, of the different possible syllables:
   *
   *   <L>
   *   <L,V>
   *   <L,V,T>
   *   <LV>
   *   <LVT>
   *   <LV, T>
   *
   * - <L> needs no work.
   *
   * - <LV> and <LVT> can stay the way they are if the font supports them, otherwise we
   *   should fully decompose them if font supports.
   *
   * - <L,V> and <L,V,T> we should compose if the whole thing can be composed.
   *
   * - <LV,T> we should compose if the whole thing can be composed, otherwise we should
   *   decompose.
   */

  buffer->clear_output ();
  unsigned int start = 0, end = 0; /* Extent of most recently seen syllable;
				    * valid only if start < end
				    */
  unsigned int count = buffer->len;

  for (buffer->idx = 0; buffer->idx < count;)
  {
    hb_codepoint_t u = buffer->cur().codepoint;

    if (isHangulTone (u))
    {
      /*
       * We could cache the width of the tone marks and the existence of dotted-circle,
       * but the use of the Hangul tone mark characters seems to be rare enough that
       * I didn't bother for now.
       */
      if (start < end && end == buffer->out_len)
      {
	/* Tone mark follows a valid syllable; move it in front, unless it's zero width. */
	buffer->next_glyph ();
	if (!is_zero_width_char (font, u))
	{
	  hb_glyph_info_t *info = buffer->out_info;
	  hb_glyph_info_t tone = info[end];
	  memmove (&info[start + 1], &info[start], (end - start) * sizeof (hb_glyph_info_t));
	  info[start] = tone;
	}
	/* Merge clusters across the (possibly reordered) syllable+tone.
	 * We want to merge even in the zero-width tone mark case here,
	 * so that clustering behavior isn't dependent on how the tone mark
	 * is handled by the font.
	 */
	buffer->merge_out_clusters (start, end + 1);
      }
      else
      {
	/* No valid syllable as base for tone mark; try to insert dotted circle. */
	if (font->has_glyph (0x25CCu))
	{
	  hb_codepoint_t chars[2];
	  if (!is_zero_width_char (font, u)) {
	    chars[0] = u;
	    chars[1] = 0x25CCu;
	  } else {
	    chars[0] = 0x25CCu;
	    chars[1] = u;
	  }
	  buffer->replace_glyphs (1, 2, chars);
	}
	else
	{
	  /* No dotted circle available in the font; just leave tone mark untouched. */
	  buffer->next_glyph ();
	}
      }
      start = end = buffer->out_len;
      continue;
    }

    start = buffer->out_len; /* Remember current position as a potential syllable start;
			      * will only be used if we set end to a later position.
			      */

    if (isL (u) && buffer->idx + 1 < count)
    {
      hb_codepoint_t l = u;
      hb_codepoint_t v = buffer->cur(+1).codepoint;
      if (isV (v))
      {
	/* Have <L,V> or <L,V,T>. */
	hb_codepoint_t t = 0;
	unsigned int tindex = 0;
	if (buffer->idx + 2 < count)
	{
	  t = buffer->cur(+2).codepoint;
	  if (isT (t))
	    tindex = t - TBase; /* Only used if isCombiningT (t); otherwise invalid. */
	  else
	    t = 0; /* The next character was not a trailing jamo. */
	}

	/* We've got a syllable <L,V,T?>; see if it can potentially be composed. */
	if (isCombiningL (l) && isCombiningV (v) && (t == 0 || isCombiningT (t)))
	{
	  /* Try to compose; if this succeeds, end is set to start+1. */
	  hb_codepoint_t s = SBase + (l - LBase) * NCount + (v - VBase) * TCount + tindex;
	  if (font->has_glyph (s))
	  {
	    buffer->replace_glyphs (t ? 3 : 2, 1, &s);
	    if (unlikely (buffer->in_error))
	      return;
	    end = start + 1;
	    continue;
	  }
	}

	/* We didn't compose, either because it's an Old Hangul syllable without a
	 * precomposed character in Unicode, or because the font didn't support the
	 * necessary precomposed glyph.
	 * Set jamo features on the individual glyphs, and advance past them.
	 */
	buffer->cur().hangul_shaping_feature() = LJMO;
	buffer->next_glyph ();
	buffer->cur().hangul_shaping_feature() = VJMO;
	buffer->next_glyph ();
	if (t)
	{
	  buffer->cur().hangul_shaping_feature() = TJMO;
	  buffer->next_glyph ();
	  end = start + 3;
	}
	else
	  end = start + 2;
	buffer->merge_out_clusters (start, end);
	continue;
      }
    }

    else if (isCombinedS (u))
    {
      /* Have <LV>, <LVT>, or <LV,T> */
      hb_codepoint_t s = u;
      bool has_glyph = font->has_glyph (s);
      unsigned int lindex = (s - SBase) / NCount;
      unsigned int nindex = (s - SBase) % NCount;
      unsigned int vindex = nindex / TCount;
      unsigned int tindex = nindex % TCount;

      if (!tindex &&
	  buffer->idx + 1 < count &&
	  isCombiningT (buffer->cur(+1).codepoint))
      {
	/* <LV,T>, try to combine. */
	unsigned int new_tindex = buffer->cur(+1).codepoint - TBase;
	hb_codepoint_t new_s = s + new_tindex;
	if (font->has_glyph (new_s))
	{
	  buffer->replace_glyphs (2, 1, &new_s);
	  if (unlikely (buffer->in_error))
	    return;
	  end = start + 1;
	  continue;
	}
      }

      /* Otherwise, decompose if font doesn't support <LV> or <LVT>,
       * or if having non-combining <LV,T>.  Note that we already handled
       * combining <LV,T> above. */
      if (!has_glyph ||
	  (!tindex &&
	   buffer->idx + 1 < count &&
	   isT (buffer->cur(+1).codepoint)))
      {
	hb_codepoint_t decomposed[3] = {LBase + lindex,
					VBase + vindex,
					TBase + tindex};
	if (font->has_glyph (decomposed[0]) &&
	    font->has_glyph (decomposed[1]) &&
	    (!tindex || font->has_glyph (decomposed[2])))
	{
	  unsigned int s_len = tindex ? 3 : 2;
	  buffer->replace_glyphs (1, s_len, decomposed);
	  if (unlikely (buffer->in_error))
	    return;

	  /* We decomposed S: apply jamo features to the individual glyphs
	   * that are now in buffer->out_info.
	   */
	  hb_glyph_info_t *info = buffer->out_info;

	  /* If we decomposed an LV because of a non-combining T following,
	   * we want to include this T in the syllable.
	   */
	  if (has_glyph && !tindex)
	  {
            buffer->next_glyph ();
            s_len++;
          }
          end = start + s_len;

	  unsigned int i = start;
	  info[i++].hangul_shaping_feature() = LJMO;
	  info[i++].hangul_shaping_feature() = VJMO;
	  if (i < end)
	    info[i++].hangul_shaping_feature() = TJMO;
	  buffer->merge_out_clusters (start, end);
	  continue;
	}
      }

      if (has_glyph)
      {
        /* We didn't decompose the S, so just advance past it. */
	end = start + 1;
	buffer->next_glyph ();
	continue;
      }
    }

    /* Didn't find a recognizable syllable, so we leave end <= start;
     * this will prevent tone-mark reordering happening.
     */
    buffer->next_glyph ();
  }
  buffer->swap_buffers ();
}

static void
setup_masks_hangul (const hb_ot_shape_plan_t *plan,
		    hb_buffer_t              *buffer,
		    hb_font_t                *font HB_UNUSED)
{
  const hangul_shape_plan_t *hangul_plan = (const hangul_shape_plan_t *) plan->data;

  if (likely (hangul_plan))
  {
    unsigned int count = buffer->len;
    hb_glyph_info_t *info = buffer->info;
    for (unsigned int i = 0; i < count; i++, info++)
      info->mask |= hangul_plan->mask_array[info->hangul_shaping_feature()];
  }

  HB_BUFFER_DEALLOCATE_VAR (buffer, hangul_shaping_feature);
}


const hb_ot_complex_shaper_t _hb_ot_complex_shaper_hangul =
{
  "hangul",
  collect_features_hangul,
  override_features_hangul,
  data_create_hangul, /* data_create */
  data_destroy_hangul, /* data_destroy */
  preprocess_text_hangul,
  HB_OT_SHAPE_NORMALIZATION_MODE_NONE,
  NULL, /* decompose */
  NULL, /* compose */
  setup_masks_hangul, /* setup_masks */
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE,
  false, /* fallback_position */
};
