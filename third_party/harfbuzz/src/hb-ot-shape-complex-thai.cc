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


/* Thai / Lao shaper */


/* PUA shaping */


enum thai_consonant_type_t
{
  NC,
  AC,
  RC,
  DC,
  NOT_CONSONANT,
  NUM_CONSONANT_TYPES = NOT_CONSONANT
};

static thai_consonant_type_t
get_consonant_type (hb_codepoint_t u)
{
  if (u == 0x0E1Bu || u == 0x0E1Du || u == 0x0E1Fu/* || u == 0x0E2Cu*/)
    return AC;
  if (u == 0x0E0Du || u == 0x0E10u)
    return RC;
  if (u == 0x0E0Eu || u == 0x0E0Fu)
    return DC;
  if (hb_in_range (u, 0x0E01u, 0x0E2Eu))
    return NC;
  return NOT_CONSONANT;
}


enum thai_mark_type_t
{
  AV,
  BV,
  T,
  NOT_MARK,
  NUM_MARK_TYPES = NOT_MARK
};

static thai_mark_type_t
get_mark_type (hb_codepoint_t u)
{
  if (u == 0x0E31u || hb_in_range (u, 0x0E34u, 0x0E37u) ||
      u == 0x0E47u || hb_in_range (u, 0x0E4Du, 0x0E4Eu))
    return AV;
  if (hb_in_range (u, 0x0E38u, 0x0E3Au))
    return BV;
  if (hb_in_range (u, 0x0E48u, 0x0E4Cu))
    return T;
  return NOT_MARK;
}


enum thai_action_t
{
  NOP,
  SD,  /* Shift combining-mark down */
  SL,  /* Shift combining-mark left */
  SDL, /* Shift combining-mark down-left */
  RD   /* Remove descender from base */
};

static hb_codepoint_t
thai_pua_shape (hb_codepoint_t u, thai_action_t action, hb_font_t *font)
{
  struct thai_pua_mapping_t {
    hb_codepoint_t u;
    hb_codepoint_t win_pua;
    hb_codepoint_t mac_pua;
  } const *pua_mappings = NULL;
  static const thai_pua_mapping_t SD_mappings[] = {
    {0x0E48u, 0xF70Au, 0xF88Bu}, /* MAI EK */
    {0x0E49u, 0xF70Bu, 0xF88Eu}, /* MAI THO */
    {0x0E4Au, 0xF70Cu, 0xF891u}, /* MAI TRI */
    {0x0E4Bu, 0xF70Du, 0xF894u}, /* MAI CHATTAWA */
    {0x0E4Cu, 0xF70Eu, 0xF897u}, /* THANTHAKHAT */
    {0x0E38u, 0xF718u, 0xF89Bu}, /* SARA U */
    {0x0E39u, 0xF719u, 0xF89Cu}, /* SARA UU */
    {0x0E3Au, 0xF71Au, 0xF89Du}, /* PHINTHU */
    {0x0000u, 0x0000u, 0x0000u}
  };
  static const thai_pua_mapping_t SDL_mappings[] = {
    {0x0E48u, 0xF705u, 0xF88Cu}, /* MAI EK */
    {0x0E49u, 0xF706u, 0xF88Fu}, /* MAI THO */
    {0x0E4Au, 0xF707u, 0xF892u}, /* MAI TRI */
    {0x0E4Bu, 0xF708u, 0xF895u}, /* MAI CHATTAWA */
    {0x0E4Cu, 0xF709u, 0xF898u}, /* THANTHAKHAT */
    {0x0000u, 0x0000u, 0x0000u}
  };
  static const thai_pua_mapping_t SL_mappings[] = {
    {0x0E48u, 0xF713u, 0xF88Au}, /* MAI EK */
    {0x0E49u, 0xF714u, 0xF88Du}, /* MAI THO */
    {0x0E4Au, 0xF715u, 0xF890u}, /* MAI TRI */
    {0x0E4Bu, 0xF716u, 0xF893u}, /* MAI CHATTAWA */
    {0x0E4Cu, 0xF717u, 0xF896u}, /* THANTHAKHAT */
    {0x0E31u, 0xF710u, 0xF884u}, /* MAI HAN-AKAT */
    {0x0E34u, 0xF701u, 0xF885u}, /* SARA I */
    {0x0E35u, 0xF702u, 0xF886u}, /* SARA II */
    {0x0E36u, 0xF703u, 0xF887u}, /* SARA UE */
    {0x0E37u, 0xF704u, 0xF888u}, /* SARA UEE */
    {0x0E47u, 0xF712u, 0xF889u}, /* MAITAIKHU */
    {0x0E4Du, 0xF711u, 0xF899u}, /* NIKHAHIT */
    {0x0000u, 0x0000u, 0x0000u}
  };
  static const thai_pua_mapping_t RD_mappings[] = {
    {0x0E0Du, 0xF70Fu, 0xF89Au}, /* YO YING */
    {0x0E10u, 0xF700u, 0xF89Eu}, /* THO THAN */
    {0x0000u, 0x0000u, 0x0000u}
  };

  switch (action) {
    default: assert (false); /* Fallthrough */
    case NOP: return u;
    case SD:  pua_mappings = SD_mappings; break;
    case SDL: pua_mappings = SDL_mappings; break;
    case SL:  pua_mappings = SL_mappings; break;
    case RD:  pua_mappings = RD_mappings; break;
  }
  for (; pua_mappings->u; pua_mappings++)
    if (pua_mappings->u == u)
    {
      hb_codepoint_t glyph;
      if (hb_font_get_glyph (font, pua_mappings->win_pua, 0, &glyph))
	return pua_mappings->win_pua;
      if (hb_font_get_glyph (font, pua_mappings->mac_pua, 0, &glyph))
	return pua_mappings->mac_pua;
      break;
    }
  return u;
}


static enum thai_above_state_t
{     /* Cluster above looks like: */
  T0, /*  ⣤                      */
  T1, /*     ⣼                   */
  T2, /*        ⣾                */
  T3, /*           ⣿             */
  NUM_ABOVE_STATES
} thai_above_start_state[NUM_CONSONANT_TYPES + 1/* For NOT_CONSONANT */] =
{
  T0, /* NC */
  T1, /* AC */
  T0, /* RC */
  T0, /* DC */
  T3, /* NOT_CONSONANT */
};

static const struct thai_above_state_machine_edge_t {
  thai_action_t action;
  thai_above_state_t next_state;
} thai_above_state_machine[NUM_ABOVE_STATES][NUM_MARK_TYPES] =
{        /*AV*/    /*BV*/    /*T*/
/*T0*/ {{NOP,T3}, {NOP,T0}, {SD, T3}},
/*T1*/ {{SL, T2}, {NOP,T1}, {SDL,T2}},
/*T2*/ {{NOP,T3}, {NOP,T2}, {SL, T3}},
/*T3*/ {{NOP,T3}, {NOP,T3}, {NOP,T3}},
};


static enum thai_below_state_t
{
  B0, /* No descender */
  B1, /* Removable descender */
  B2, /* Strict descender */
  NUM_BELOW_STATES
} thai_below_start_state[NUM_CONSONANT_TYPES + 1/* For NOT_CONSONANT */] =
{
  B0, /* NC */
  B0, /* AC */
  B1, /* RC */
  B2, /* DC */
  B2, /* NOT_CONSONANT */
};

static const struct thai_below_state_machine_edge_t {
  thai_action_t action;
  thai_below_state_t next_state;
} thai_below_state_machine[NUM_BELOW_STATES][NUM_MARK_TYPES] =
{        /*AV*/    /*BV*/    /*T*/
/*B0*/ {{NOP,B0}, {NOP,B2}, {NOP, B0}},
/*B1*/ {{NOP,B1}, {RD, B2}, {NOP, B1}},
/*B2*/ {{NOP,B2}, {SD, B2}, {NOP, B2}},
};


static void
do_thai_pua_shaping (const hb_ot_shape_plan_t *plan HB_UNUSED,
		     hb_buffer_t              *buffer,
		     hb_font_t                *font)
{
  thai_above_state_t above_state = thai_above_start_state[NOT_CONSONANT];
  thai_below_state_t below_state = thai_below_start_state[NOT_CONSONANT];
  unsigned int base = 0;

  hb_glyph_info_t *info = buffer->info;
  unsigned int count = buffer->len;
  for (unsigned int i = 0; i < count; i++)
  {
    thai_mark_type_t mt = get_mark_type (info[i].codepoint);

    if (mt == NOT_MARK) {
      thai_consonant_type_t ct = get_consonant_type (info[i].codepoint);
      above_state = thai_above_start_state[ct];
      below_state = thai_below_start_state[ct];
      base = i;
      continue;
    }

    const thai_above_state_machine_edge_t &above_edge = thai_above_state_machine[above_state][mt];
    const thai_below_state_machine_edge_t &below_edge = thai_below_state_machine[below_state][mt];
    above_state = above_edge.next_state;
    below_state = below_edge.next_state;

    /* At least one of the above/below actions is NOP. */
    thai_action_t action = above_edge.action != NOP ? above_edge.action : below_edge.action;

    if (action == RD)
      info[base].codepoint = thai_pua_shape (info[base].codepoint, action, font);
    else
      info[i].codepoint = thai_pua_shape (info[i].codepoint, action, font);
  }
}


static void
preprocess_text_thai (const hb_ot_shape_plan_t *plan,
		      hb_buffer_t              *buffer,
		      hb_font_t                *font)
{
  /* This function implements the shaping logic documented here:
   *
   *   http://linux.thai.net/~thep/th-otf/shaping.html
   *
   * The first shaping rule listed there is needed even if the font has Thai
   * OpenType tables.  The rest do fallback positioning based on PUA codepoints.
   * We implement that only if there exist no Thai GSUB in the font.
   */

  /* The following is NOT specified in the MS OT Thai spec, however, it seems
   * to be what Uniscribe and other engines implement.  According to Eric Muller:
   *
   * When you have a SARA AM, decompose it in NIKHAHIT + SARA AA, *and* move the
   * NIKHAHIT backwards over any tone mark (0E48-0E4B).
   *
   * <0E14, 0E4B, 0E33> -> <0E14, 0E4D, 0E4B, 0E32>
   *
   * This reordering is legit only when the NIKHAHIT comes from a SARA AM, not
   * when it's there to start with. The string <0E14, 0E4B, 0E4D> is probably
   * not what a user wanted, but the rendering is nevertheless nikhahit above
   * chattawa.
   *
   * Same for Lao.
   *
   * Note:
   *
   * Uniscribe also does some below-marks reordering.  Namely, it positions U+0E3A
   * after U+0E38 and U+0E39.  We do that by modifying the ccc for U+0E3A.
   * See unicode->modified_combining_class ().  Lao does NOT have a U+0E3A
   * equivalent.
   */


  /*
   * Here are the characters of significance:
   *
   *			Thai	Lao
   * SARA AM:		U+0E33	U+0EB3
   * SARA AA:		U+0E32	U+0EB2
   * Nikhahit:		U+0E4D	U+0ECD
   *
   * Testing shows that Uniscribe reorder the following marks:
   * Thai:	<0E31,0E34..0E37,0E47..0E4E>
   * Lao:	<0EB1,0EB4..0EB7,0EC7..0ECE>
   *
   * Note how the Lao versions are the same as Thai + 0x80.
   */

  /* We only get one script at a time, so a script-agnostic implementation
   * is adequate here. */
#define IS_SARA_AM(x) (((x) & ~0x0080u) == 0x0E33u)
#define NIKHAHIT_FROM_SARA_AM(x) ((x) - 0x0E33u + 0x0E4Du)
#define SARA_AA_FROM_SARA_AM(x) ((x) - 1)
#define IS_TONE_MARK(x) (hb_in_ranges ((x) & ~0x0080u, 0x0E34u, 0x0E37u, 0x0E47u, 0x0E4Eu, 0x0E31u, 0x0E31u))

  buffer->clear_output ();
  unsigned int count = buffer->len;
  for (buffer->idx = 0; buffer->idx < count;)
  {
    hb_codepoint_t u = buffer->cur().codepoint;
    if (likely (!IS_SARA_AM (u))) {
      buffer->next_glyph ();
      continue;
    }

    /* Is SARA AM. Decompose and reorder. */
    hb_codepoint_t decomposed[2] = {hb_codepoint_t (NIKHAHIT_FROM_SARA_AM (u)),
				    hb_codepoint_t (SARA_AA_FROM_SARA_AM (u))};
    buffer->replace_glyphs (1, 2, decomposed);
    if (unlikely (buffer->in_error))
      return;

    /* Make Nikhahit be recognized as a mark when zeroing widths. */
    unsigned int end = buffer->out_len;
    _hb_glyph_info_set_general_category (&buffer->out_info[end - 2], HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK);

    /* Ok, let's see... */
    unsigned int start = end - 2;
    while (start > 0 && IS_TONE_MARK (buffer->out_info[start - 1].codepoint))
      start--;

    if (start + 2 < end)
    {
      /* Move Nikhahit (end-2) to the beginning */
      buffer->merge_out_clusters (start, end);
      hb_glyph_info_t t = buffer->out_info[end - 2];
      memmove (buffer->out_info + start + 1,
	       buffer->out_info + start,
	       sizeof (buffer->out_info[0]) * (end - start - 2));
      buffer->out_info[start] = t;
    }
    else
    {
      /* Since we decomposed, and NIKHAHIT is combining, merge clusters with the
       * previous cluster. */
      if (start)
	buffer->merge_out_clusters (start - 1, end);
    }
  }
  buffer->swap_buffers ();

  /* If font has Thai GSUB, we are done. */
  if (plan->props.script == HB_SCRIPT_THAI && !plan->map.found_script[0])
    do_thai_pua_shaping (plan, buffer, font);
}

const hb_ot_complex_shaper_t _hb_ot_complex_shaper_thai =
{
  "thai",
  NULL, /* collect_features */
  NULL, /* override_features */
  NULL, /* data_create */
  NULL, /* data_destroy */
  preprocess_text_thai,
  HB_OT_SHAPE_NORMALIZATION_MODE_DEFAULT,
  NULL, /* decompose */
  NULL, /* compose */
  NULL, /* setup_masks */
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_DEFAULT,
  false,/* fallback_position */
};
