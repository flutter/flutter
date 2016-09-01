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

#include "hb-ot-shape-complex-indic-private.hh"
#include "hb-ot-layout-private.hh"

/* buffer var allocations */
#define indic_category() complex_var_u8_0() /* indic_category_t */
#define indic_position() complex_var_u8_1() /* indic_position_t */


/*
 * Indic shaper.
 */


#define IN_HALF_BLOCK(u, Base) (((u) & ~0x7Fu) == (Base))

#define IS_DEVA(u) (IN_HALF_BLOCK (u, 0x0900u))
#define IS_BENG(u) (IN_HALF_BLOCK (u, 0x0980u))
#define IS_GURU(u) (IN_HALF_BLOCK (u, 0x0A00u))
#define IS_GUJR(u) (IN_HALF_BLOCK (u, 0x0A80u))
#define IS_ORYA(u) (IN_HALF_BLOCK (u, 0x0B00u))
#define IS_TAML(u) (IN_HALF_BLOCK (u, 0x0B80u))
#define IS_TELU(u) (IN_HALF_BLOCK (u, 0x0C00u))
#define IS_KNDA(u) (IN_HALF_BLOCK (u, 0x0C80u))
#define IS_MLYM(u) (IN_HALF_BLOCK (u, 0x0D00u))
#define IS_SINH(u) (IN_HALF_BLOCK (u, 0x0D80u))
#define IS_KHMR(u) (IN_HALF_BLOCK (u, 0x1780u))


#define MATRA_POS_LEFT(u)	POS_PRE_M
#define MATRA_POS_RIGHT(u)	( \
				  IS_DEVA(u) ? POS_AFTER_SUB  : \
				  IS_BENG(u) ? POS_AFTER_POST : \
				  IS_GURU(u) ? POS_AFTER_POST : \
				  IS_GUJR(u) ? POS_AFTER_POST : \
				  IS_ORYA(u) ? POS_AFTER_POST : \
				  IS_TAML(u) ? POS_AFTER_POST : \
				  IS_TELU(u) ? (u <= 0x0C42u ? POS_BEFORE_SUB : POS_AFTER_SUB) : \
				  IS_KNDA(u) ? (u < 0x0CC3u || u > 0xCD6u ? POS_BEFORE_SUB : POS_AFTER_SUB) : \
				  IS_MLYM(u) ? POS_AFTER_POST : \
				  IS_SINH(u) ? POS_AFTER_SUB  : \
				  IS_KHMR(u) ? POS_AFTER_POST : \
				  /*default*/  POS_AFTER_SUB    \
				)
#define MATRA_POS_TOP(u)	( /* BENG and MLYM don't have top matras. */ \
				  IS_DEVA(u) ? POS_AFTER_SUB  : \
				  IS_GURU(u) ? POS_AFTER_POST : /* Deviate from spec */ \
				  IS_GUJR(u) ? POS_AFTER_SUB  : \
				  IS_ORYA(u) ? POS_AFTER_MAIN : \
				  IS_TAML(u) ? POS_AFTER_SUB  : \
				  IS_TELU(u) ? POS_BEFORE_SUB : \
				  IS_KNDA(u) ? POS_BEFORE_SUB : \
				  IS_SINH(u) ? POS_AFTER_SUB  : \
				  IS_KHMR(u) ? POS_AFTER_POST : \
				  /*default*/  POS_AFTER_SUB    \
				)
#define MATRA_POS_BOTTOM(u)	( \
				  IS_DEVA(u) ? POS_AFTER_SUB  : \
				  IS_BENG(u) ? POS_AFTER_SUB  : \
				  IS_GURU(u) ? POS_AFTER_POST : \
				  IS_GUJR(u) ? POS_AFTER_POST : \
				  IS_ORYA(u) ? POS_AFTER_SUB  : \
				  IS_TAML(u) ? POS_AFTER_POST : \
				  IS_TELU(u) ? POS_BEFORE_SUB : \
				  IS_KNDA(u) ? POS_BEFORE_SUB : \
				  IS_MLYM(u) ? POS_AFTER_POST : \
				  IS_SINH(u) ? POS_AFTER_SUB  : \
				  IS_KHMR(u) ? POS_AFTER_POST : \
				  /*default*/  POS_AFTER_SUB    \
				)

static inline indic_position_t
matra_position (hb_codepoint_t u, indic_position_t side)
{
  switch ((int) side)
  {
    case POS_PRE_C:	return MATRA_POS_LEFT (u);
    case POS_POST_C:	return MATRA_POS_RIGHT (u);
    case POS_ABOVE_C:	return MATRA_POS_TOP (u);
    case POS_BELOW_C:	return MATRA_POS_BOTTOM (u);
  };
  return side;
}

/* XXX
 * This is a hack for now.  We should move this data into the main Indic table.
 * Or completely remove it and just check in the tables.
 */
static const hb_codepoint_t ra_chars[] = {
  0x0930u, /* Devanagari */
  0x09B0u, /* Bengali */
  0x09F0u, /* Bengali */
  0x0A30u, /* Gurmukhi */	/* No Reph */
  0x0AB0u, /* Gujarati */
  0x0B30u, /* Oriya */
  0x0BB0u, /* Tamil */		/* No Reph */
  0x0C30u, /* Telugu */		/* Reph formed only with ZWJ */
  0x0CB0u, /* Kannada */
  0x0D30u, /* Malayalam */	/* No Reph, Logical Repha */

  0x0DBBu, /* Sinhala */		/* Reph formed only with ZWJ */

  0x179Au, /* Khmer */		/* No Reph, Visual Repha */
};

static inline bool
is_ra (hb_codepoint_t u)
{
  for (unsigned int i = 0; i < ARRAY_LENGTH (ra_chars); i++)
    if (u == ra_chars[i])
      return true;
  return false;
}

static inline bool
is_one_of (const hb_glyph_info_t &info, unsigned int flags)
{
  /* If it ligated, all bets are off. */
  if (_hb_glyph_info_ligated (&info)) return false;
  return !!(FLAG (info.indic_category()) & flags);
}

static inline bool
is_joiner (const hb_glyph_info_t &info)
{
  return is_one_of (info, JOINER_FLAGS);
}

static inline bool
is_consonant (const hb_glyph_info_t &info)
{
  return is_one_of (info, CONSONANT_FLAGS);
}

static inline bool
is_halant_or_coeng (const hb_glyph_info_t &info)
{
  return is_one_of (info, HALANT_OR_COENG_FLAGS);
}

static inline void
set_indic_properties (hb_glyph_info_t &info)
{
  hb_codepoint_t u = info.codepoint;
  unsigned int type = hb_indic_get_categories (u);
  indic_category_t cat = (indic_category_t) (type & 0x7Fu);
  indic_position_t pos = (indic_position_t) (type >> 8);


  /*
   * Re-assign category
   */


  /* The spec says U+0952 is OT_A.  However, testing shows that Uniscribe
   * treats a whole bunch of characters similarly.
   * TESTS: For example, for U+0951:
   * U+092E,U+0947,U+0952
   * U+092E,U+0952,U+0947
   * U+092E,U+0947,U+0951
   * U+092E,U+0951,U+0947
   * U+092E,U+0951,U+0952
   * U+092E,U+0952,U+0951
   */
  if (unlikely (hb_in_ranges (u, 0x0951u, 0x0952u,
				 0x1CD0u, 0x1CD2u,
				 0x1CD4u, 0x1CE1u) ||
			    u == 0x1CF4u))
    cat = OT_A;
  /* The following act more like the Bindus. */
  else if (unlikely (hb_in_range (u, 0x0953u, 0x0954u)))
    cat = OT_SM;
  /* The following act like consonants. */
  else if (unlikely (hb_in_ranges (u, 0x0A72u, 0x0A73u,
				      0x1CF5u, 0x1CF6u)))
    cat = OT_C;
  /* TODO: The following should only be allowed after a Visarga.
   * For now, just treat them like regular tone marks. */
  else if (unlikely (hb_in_range (u, 0x1CE2u, 0x1CE8u)))
    cat = OT_A;
  /* TODO: The following should only be allowed after some of
   * the nasalization marks, maybe only for U+1CE9..U+1CF1.
   * For now, just treat them like tone marks. */
  else if (unlikely (u == 0x1CEDu))
    cat = OT_A;
  /* The following take marks in standalone clusters, similar to Avagraha. */
  else if (unlikely (hb_in_ranges (u, 0xA8F2u, 0xA8F7u,
				      0x1CE9u, 0x1CECu,
				      0x1CEEu, 0x1CF1u)))
  {
    cat = OT_Symbol;
    ASSERT_STATIC ((int) INDIC_SYLLABIC_CATEGORY_AVAGRAHA == OT_Symbol);
  }
  else if (unlikely (hb_in_range (u, 0x17CDu, 0x17D1u) ||
		     u == 0x17CBu || u == 0x17D3u || u == 0x17DDu)) /* Khmer Various signs */
  {
    /* These are like Top Matras. */
    cat = OT_M;
    pos = POS_ABOVE_C;
  }
  else if (unlikely (u == 0x17C6u)) cat = OT_N; /* Khmer Bindu doesn't like to be repositioned. */
  else if (unlikely (u == 0x17D2u)) cat = OT_Coeng; /* Khmer coeng */
  else if (unlikely (hb_in_range (u, 0x2010u, 0x2011u)))
				    cat = OT_PLACEHOLDER;
  else if (unlikely (u == 0x25CCu)) cat = OT_DOTTEDCIRCLE;
  else if (unlikely (u == 0xA982u)) cat = OT_SM; /* Javanese repha. */
  else if (unlikely (u == 0xA9BEu)) cat = OT_CM2; /* Javanese medial ya. */
  else if (unlikely (u == 0xA9BDu)) { cat = OT_M; pos = POS_POST_C; } /* Javanese vocalic r. */


  /*
   * Re-assign position.
   */

  if ((FLAG (cat) & CONSONANT_FLAGS))
  {
    pos = POS_BASE_C;
    if (is_ra (u))
      cat = OT_Ra;
  }
  else if (cat == OT_M)
  {
    pos = matra_position (u, pos);
  }
  else if ((FLAG (cat) & (FLAG (OT_SM) | FLAG (OT_VD) | FLAG (OT_A) | FLAG (OT_Symbol))))
  {
    pos = POS_SMVD;
  }

  if (unlikely (u == 0x0B01u)) pos = POS_BEFORE_SUB; /* Oriya Bindu is BeforeSub in the spec. */



  info.indic_category() = cat;
  info.indic_position() = pos;
}

/*
 * Things above this line should ideally be moved to the Indic table itself.
 */


/*
 * Indic configurations.  Note that we do not want to keep every single script-specific
 * behavior in these tables necessarily.  This should mainly be used for per-script
 * properties that are cheaper keeping here, than in the code.  Ie. if, say, one and
 * only one script has an exception, that one script can be if'ed directly in the code,
 * instead of adding a new flag in these structs.
 */

enum base_position_t {
  BASE_POS_FIRST,
  BASE_POS_LAST_SINHALA,
  BASE_POS_LAST
};
enum reph_position_t {
  REPH_POS_AFTER_MAIN  = POS_AFTER_MAIN,
  REPH_POS_BEFORE_SUB  = POS_BEFORE_SUB,
  REPH_POS_AFTER_SUB   = POS_AFTER_SUB,
  REPH_POS_BEFORE_POST = POS_BEFORE_POST,
  REPH_POS_AFTER_POST  = POS_AFTER_POST,
  REPH_POS_DONT_CARE   = POS_RA_TO_BECOME_REPH
};
enum reph_mode_t {
  REPH_MODE_IMPLICIT,  /* Reph formed out of initial Ra,H sequence. */
  REPH_MODE_EXPLICIT,  /* Reph formed out of initial Ra,H,ZWJ sequence. */
  REPH_MODE_VIS_REPHA, /* Encoded Repha character, no reordering needed. */
  REPH_MODE_LOG_REPHA  /* Encoded Repha character, needs reordering. */
};
enum blwf_mode_t {
  BLWF_MODE_PRE_AND_POST, /* Below-forms feature applied to pre-base and post-base. */
  BLWF_MODE_POST_ONLY     /* Below-forms feature applied to post-base only. */
};
enum pref_len_t {
  PREF_LEN_1 = 1,
  PREF_LEN_2 = 2,
  PREF_LEN_DONT_CARE = PREF_LEN_2
};
struct indic_config_t
{
  hb_script_t     script;
  bool            has_old_spec;
  hb_codepoint_t  virama;
  base_position_t base_pos;
  reph_position_t reph_pos;
  reph_mode_t     reph_mode;
  blwf_mode_t     blwf_mode;
  pref_len_t      pref_len;
};

static const indic_config_t indic_configs[] =
{
  /* Default.  Should be first. */
  {HB_SCRIPT_INVALID,	false,      0,BASE_POS_LAST, REPH_POS_BEFORE_POST,REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_1},
  {HB_SCRIPT_DEVANAGARI,true, 0x094Du,BASE_POS_LAST, REPH_POS_BEFORE_POST,REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_BENGALI,	true, 0x09CDu,BASE_POS_LAST, REPH_POS_AFTER_SUB,  REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_GURMUKHI,	true, 0x0A4Du,BASE_POS_LAST, REPH_POS_BEFORE_SUB, REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_GUJARATI,	true, 0x0ACDu,BASE_POS_LAST, REPH_POS_BEFORE_POST,REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_ORIYA,	true, 0x0B4Du,BASE_POS_LAST, REPH_POS_AFTER_MAIN, REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_TAMIL,	true, 0x0BCDu,BASE_POS_LAST, REPH_POS_AFTER_POST, REPH_MODE_IMPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_2},
  {HB_SCRIPT_TELUGU,	true, 0x0C4Du,BASE_POS_LAST, REPH_POS_AFTER_POST, REPH_MODE_EXPLICIT, BLWF_MODE_POST_ONLY,    PREF_LEN_2},
  {HB_SCRIPT_KANNADA,	true, 0x0CCDu,BASE_POS_LAST, REPH_POS_AFTER_POST, REPH_MODE_IMPLICIT, BLWF_MODE_POST_ONLY,    PREF_LEN_2},
  {HB_SCRIPT_MALAYALAM,	true, 0x0D4Du,BASE_POS_LAST, REPH_POS_AFTER_MAIN, REPH_MODE_LOG_REPHA,BLWF_MODE_PRE_AND_POST, PREF_LEN_2},
  {HB_SCRIPT_SINHALA,	false,0x0DCAu,BASE_POS_LAST_SINHALA,
						     REPH_POS_AFTER_MAIN, REPH_MODE_EXPLICIT, BLWF_MODE_PRE_AND_POST, PREF_LEN_DONT_CARE},
  {HB_SCRIPT_KHMER,	false,0x17D2u,BASE_POS_FIRST,REPH_POS_DONT_CARE,  REPH_MODE_VIS_REPHA,BLWF_MODE_PRE_AND_POST, PREF_LEN_2},
  {HB_SCRIPT_JAVANESE,	false,0xA9C0u,BASE_POS_FIRST,REPH_POS_DONT_CARE,  REPH_MODE_VIS_REPHA,BLWF_MODE_PRE_AND_POST, PREF_LEN_1},
};



/*
 * Indic shaper.
 */

struct feature_list_t {
  hb_tag_t tag;
  hb_ot_map_feature_flags_t flags;
};

static const feature_list_t
indic_features[] =
{
  /*
   * Basic features.
   * These features are applied in order, one at a time, after initial_reordering.
   */
  {HB_TAG('n','u','k','t'), F_GLOBAL},
  {HB_TAG('a','k','h','n'), F_GLOBAL},
  {HB_TAG('r','p','h','f'), F_NONE},
  {HB_TAG('r','k','r','f'), F_GLOBAL},
  {HB_TAG('p','r','e','f'), F_NONE},
  {HB_TAG('b','l','w','f'), F_NONE},
  {HB_TAG('a','b','v','f'), F_NONE},
  {HB_TAG('h','a','l','f'), F_NONE},
  {HB_TAG('p','s','t','f'), F_NONE},
  {HB_TAG('v','a','t','u'), F_GLOBAL},
  {HB_TAG('c','j','c','t'), F_GLOBAL},
  {HB_TAG('c','f','a','r'), F_NONE},
  /*
   * Other features.
   * These features are applied all at once, after final_reordering.
   * Default Bengali font in Windows for example has intermixed
   * lookups for init,pres,abvs,blws features.
   */
  {HB_TAG('i','n','i','t'), F_NONE},
  {HB_TAG('p','r','e','s'), F_GLOBAL},
  {HB_TAG('a','b','v','s'), F_GLOBAL},
  {HB_TAG('b','l','w','s'), F_GLOBAL},
  {HB_TAG('p','s','t','s'), F_GLOBAL},
  {HB_TAG('h','a','l','n'), F_GLOBAL},
  /* Positioning features, though we don't care about the types. */
  {HB_TAG('d','i','s','t'), F_GLOBAL},
  {HB_TAG('a','b','v','m'), F_GLOBAL},
  {HB_TAG('b','l','w','m'), F_GLOBAL},
};

/*
 * Must be in the same order as the indic_features array.
 */
enum {
  _NUKT,
  _AKHN,
  RPHF,
  _RKRF,
  PREF,
  BLWF,
  ABVF,
  HALF,
  PSTF,
  _VATU,
  _CJCT,
  CFAR,

  INIT,
  _PRES,
  _ABVS,
  _BLWS,
  _PSTS,
  _HALN,
  _DIST,
  _ABVM,
  _BLWM,

  INDIC_NUM_FEATURES,
  INDIC_BASIC_FEATURES = INIT /* Don't forget to update this! */
};

static void
setup_syllables (const hb_ot_shape_plan_t *plan,
		 hb_font_t *font,
		 hb_buffer_t *buffer);
static void
initial_reordering (const hb_ot_shape_plan_t *plan,
		    hb_font_t *font,
		    hb_buffer_t *buffer);
static void
final_reordering (const hb_ot_shape_plan_t *plan,
		  hb_font_t *font,
		  hb_buffer_t *buffer);
static void
clear_syllables (const hb_ot_shape_plan_t *plan,
		 hb_font_t *font,
		 hb_buffer_t *buffer);

static void
collect_features_indic (hb_ot_shape_planner_t *plan)
{
  hb_ot_map_builder_t *map = &plan->map;

  /* Do this before any lookups have been applied. */
  map->add_gsub_pause (setup_syllables);

  map->add_global_bool_feature (HB_TAG('l','o','c','l'));
  /* The Indic specs do not require ccmp, but we apply it here since if
   * there is a use of it, it's typically at the beginning. */
  map->add_global_bool_feature (HB_TAG('c','c','m','p'));


  unsigned int i = 0;
  map->add_gsub_pause (initial_reordering);
  for (; i < INDIC_BASIC_FEATURES; i++) {
    map->add_feature (indic_features[i].tag, 1, indic_features[i].flags | F_MANUAL_ZWJ);
    map->add_gsub_pause (NULL);
  }
  map->add_gsub_pause (final_reordering);
  for (; i < INDIC_NUM_FEATURES; i++) {
    map->add_feature (indic_features[i].tag, 1, indic_features[i].flags | F_MANUAL_ZWJ);
  }

  map->add_global_bool_feature (HB_TAG('c','a','l','t'));
  map->add_global_bool_feature (HB_TAG('c','l','i','g'));

  map->add_gsub_pause (clear_syllables);
}

static void
override_features_indic (hb_ot_shape_planner_t *plan)
{
  /* Uniscribe does not apply 'kern' in Khmer. */
  if (hb_options ().uniscribe_bug_compatible)
  {
    switch ((hb_tag_t) plan->props.script)
    {
      case HB_SCRIPT_KHMER:
	plan->map.add_feature (HB_TAG('k','e','r','n'), 0, F_GLOBAL);
	break;
    }
  }

  plan->map.add_feature (HB_TAG('l','i','g','a'), 0, F_GLOBAL);
}


struct would_substitute_feature_t
{
  inline void init (const hb_ot_map_t *map, hb_tag_t feature_tag, bool zero_context_)
  {
    zero_context = zero_context_;
    map->get_stage_lookups (0/*GSUB*/,
			    map->get_feature_stage (0/*GSUB*/, feature_tag),
			    &lookups, &count);
  }

  inline bool would_substitute (const hb_codepoint_t *glyphs,
				unsigned int          glyphs_count,
				hb_face_t            *face) const
  {
    for (unsigned int i = 0; i < count; i++)
      if (hb_ot_layout_lookup_would_substitute_fast (face, lookups[i].index, glyphs, glyphs_count, zero_context))
	return true;
    return false;
  }

  private:
  const hb_ot_map_t::lookup_map_t *lookups;
  unsigned int count;
  bool zero_context;
};

struct indic_shape_plan_t
{
  ASSERT_POD ();

  inline bool get_virama_glyph (hb_font_t *font, hb_codepoint_t *pglyph) const
  {
    hb_codepoint_t glyph = virama_glyph;
    if (unlikely (virama_glyph == (hb_codepoint_t) -1))
    {
      if (!config->virama || !font->get_glyph (config->virama, 0, &glyph))
	glyph = 0;
      /* Technically speaking, the spec says we should apply 'locl' to virama too.
       * Maybe one day... */

      /* Our get_glyph() function needs a font, so we can't get the virama glyph
       * during shape planning...  Instead, overwrite it here.  It's safe.  Don't worry! */
      (const_cast<indic_shape_plan_t *> (this))->virama_glyph = glyph;
    }

    *pglyph = glyph;
    return glyph != 0;
  }

  const indic_config_t *config;

  bool is_old_spec;
  hb_codepoint_t virama_glyph;

  would_substitute_feature_t rphf;
  would_substitute_feature_t pref;
  would_substitute_feature_t blwf;
  would_substitute_feature_t pstf;

  hb_mask_t mask_array[INDIC_NUM_FEATURES];
};

static void *
data_create_indic (const hb_ot_shape_plan_t *plan)
{
  indic_shape_plan_t *indic_plan = (indic_shape_plan_t *) calloc (1, sizeof (indic_shape_plan_t));
  if (unlikely (!indic_plan))
    return NULL;

  indic_plan->config = &indic_configs[0];
  for (unsigned int i = 1; i < ARRAY_LENGTH (indic_configs); i++)
    if (plan->props.script == indic_configs[i].script) {
      indic_plan->config = &indic_configs[i];
      break;
    }

  indic_plan->is_old_spec = indic_plan->config->has_old_spec && ((plan->map.chosen_script[0] & 0x000000FFu) != '2');
  indic_plan->virama_glyph = (hb_codepoint_t) -1;

  /* Use zero-context would_substitute() matching for new-spec of the main
   * Indic scripts, and scripts with one spec only, but not for old-specs. */
  bool zero_context = !indic_plan->is_old_spec;
  indic_plan->rphf.init (&plan->map, HB_TAG('r','p','h','f'), zero_context);
  indic_plan->pref.init (&plan->map, HB_TAG('p','r','e','f'), zero_context);
  indic_plan->blwf.init (&plan->map, HB_TAG('b','l','w','f'), zero_context);
  indic_plan->pstf.init (&plan->map, HB_TAG('p','s','t','f'), zero_context);

  for (unsigned int i = 0; i < ARRAY_LENGTH (indic_plan->mask_array); i++)
    indic_plan->mask_array[i] = (indic_features[i].flags & F_GLOBAL) ?
				 0 : plan->map.get_1_mask (indic_features[i].tag);

  return indic_plan;
}

static void
data_destroy_indic (void *data)
{
  free (data);
}

static indic_position_t
consonant_position_from_face (const indic_shape_plan_t *indic_plan,
			      const hb_codepoint_t consonant,
			      const hb_codepoint_t virama,
			      hb_face_t *face)
{
  /* For old-spec, the order of glyphs is Consonant,Virama,
   * whereas for new-spec, it's Virama,Consonant.  However,
   * some broken fonts (like Free Sans) simply copied lookups
   * from old-spec to new-spec without modification.
   * And oddly enough, Uniscribe seems to respect those lookups.
   * Eg. in the sequence U+0924,U+094D,U+0930, Uniscribe finds
   * base at 0.  The font however, only has lookups matching
   * 930,94D in 'blwf', not the expected 94D,930 (with new-spec
   * table).  As such, we simply match both sequences.  Seems
   * to work. */
  hb_codepoint_t glyphs[3] = {virama, consonant, virama};
  if (indic_plan->blwf.would_substitute (glyphs  , 2, face) ||
      indic_plan->blwf.would_substitute (glyphs+1, 2, face))
    return POS_BELOW_C;
  if (indic_plan->pstf.would_substitute (glyphs  , 2, face) ||
      indic_plan->pstf.would_substitute (glyphs+1, 2, face))
    return POS_POST_C;
  unsigned int pref_len = indic_plan->config->pref_len;
  if ((pref_len == PREF_LEN_2 &&
       (indic_plan->pref.would_substitute (glyphs  , 2, face) ||
        indic_plan->pref.would_substitute (glyphs+1, 2, face)))
   || (pref_len == PREF_LEN_1 &&
       indic_plan->pref.would_substitute (glyphs+1, 1, face)))
    return POS_POST_C;
  return POS_BASE_C;
}


enum syllable_type_t {
  consonant_syllable,
  vowel_syllable,
  standalone_cluster,
  symbol_cluster,
  broken_cluster,
  non_indic_cluster,
};

#include "hb-ot-shape-complex-indic-machine.hh"


static void
setup_masks_indic (const hb_ot_shape_plan_t *plan HB_UNUSED,
		   hb_buffer_t              *buffer,
		   hb_font_t                *font HB_UNUSED)
{
  HB_BUFFER_ALLOCATE_VAR (buffer, indic_category);
  HB_BUFFER_ALLOCATE_VAR (buffer, indic_position);

  /* We cannot setup masks here.  We save information about characters
   * and setup masks later on in a pause-callback. */

  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    set_indic_properties (info[i]);
}

static void
setup_syllables (const hb_ot_shape_plan_t *plan HB_UNUSED,
		 hb_font_t *font HB_UNUSED,
		 hb_buffer_t *buffer)
{
  find_syllables (buffer);
}

static int
compare_indic_order (const hb_glyph_info_t *pa, const hb_glyph_info_t *pb)
{
  int a = pa->indic_position();
  int b = pb->indic_position();

  return a < b ? -1 : a == b ? 0 : +1;
}



static void
update_consonant_positions (const hb_ot_shape_plan_t *plan,
			    hb_font_t         *font,
			    hb_buffer_t       *buffer)
{
  const indic_shape_plan_t *indic_plan = (const indic_shape_plan_t *) plan->data;

  if (indic_plan->config->base_pos != BASE_POS_LAST)
    return;

  hb_codepoint_t virama;
  if (indic_plan->get_virama_glyph (font, &virama))
  {
    hb_face_t *face = font->face;
    unsigned int count = buffer->len;
    hb_glyph_info_t *info = buffer->info;
    for (unsigned int i = 0; i < count; i++)
      if (info[i].indic_position() == POS_BASE_C)
      {
	hb_codepoint_t consonant = info[i].codepoint;
	info[i].indic_position() = consonant_position_from_face (indic_plan, consonant, virama, face);
      }
  }
}


/* Rules from:
 * https://www.microsoft.com/typography/otfntdev/devanot/shaping.aspx */

static void
initial_reordering_consonant_syllable (const hb_ot_shape_plan_t *plan,
				       hb_face_t *face,
				       hb_buffer_t *buffer,
				       unsigned int start, unsigned int end)
{
  const indic_shape_plan_t *indic_plan = (const indic_shape_plan_t *) plan->data;
  hb_glyph_info_t *info = buffer->info;


  /* 1. Find base consonant:
   *
   * The shaping engine finds the base consonant of the syllable, using the
   * following algorithm: starting from the end of the syllable, move backwards
   * until a consonant is found that does not have a below-base or post-base
   * form (post-base forms have to follow below-base forms), or that is not a
   * pre-base reordering Ra, or arrive at the first consonant. The consonant
   * stopped at will be the base.
   *
   *   o If the syllable starts with Ra + Halant (in a script that has Reph)
   *     and has more than one consonant, Ra is excluded from candidates for
   *     base consonants.
   */

  unsigned int base = end;
  bool has_reph = false;

  {
    /* -> If the syllable starts with Ra + Halant (in a script that has Reph)
     *    and has more than one consonant, Ra is excluded from candidates for
     *    base consonants. */
    unsigned int limit = start;
    if (indic_plan->config->reph_pos != REPH_POS_DONT_CARE &&
	indic_plan->mask_array[RPHF] &&
	start + 3 <= end &&
	(
	 (indic_plan->config->reph_mode == REPH_MODE_IMPLICIT && !is_joiner (info[start + 2])) ||
	 (indic_plan->config->reph_mode == REPH_MODE_EXPLICIT && info[start + 2].indic_category() == OT_ZWJ)
	))
    {
      /* See if it matches the 'rphf' feature. */
      hb_codepoint_t glyphs[3] = {info[start].codepoint,
				  info[start + 1].codepoint,
				  indic_plan->config->reph_mode == REPH_MODE_EXPLICIT ?
				    info[start + 2].codepoint : 0};
      if (indic_plan->rphf.would_substitute (glyphs, 2, face) ||
	  (indic_plan->config->reph_mode == REPH_MODE_EXPLICIT &&
	   indic_plan->rphf.would_substitute (glyphs, 3, face)))
      {
	limit += 2;
	while (limit < end && is_joiner (info[limit]))
	  limit++;
	base = start;
	has_reph = true;
      }
    } else if (indic_plan->config->reph_mode == REPH_MODE_LOG_REPHA && info[start].indic_category() == OT_Repha)
    {
	limit += 1;
	while (limit < end && is_joiner (info[limit]))
	  limit++;
	base = start;
	has_reph = true;
    }

    switch (indic_plan->config->base_pos)
    {
      default:
        assert (false);
	/* fallthrough */

      case BASE_POS_LAST:
      {
	/* -> starting from the end of the syllable, move backwards */
	unsigned int i = end;
	bool seen_below = false;
	do {
	  i--;
	  /* -> until a consonant is found */
	  if (is_consonant (info[i]))
	  {
	    /* -> that does not have a below-base or post-base form
	     * (post-base forms have to follow below-base forms), */
	    if (info[i].indic_position() != POS_BELOW_C &&
		(info[i].indic_position() != POS_POST_C || seen_below))
	    {
	      base = i;
	      break;
	    }
	    if (info[i].indic_position() == POS_BELOW_C)
	      seen_below = true;

	    /* -> or that is not a pre-base reordering Ra,
	     *
	     * IMPLEMENTATION NOTES:
	     *
	     * Our pre-base reordering Ra's are marked POS_POST_C, so will be skipped
	     * by the logic above already.
	     */

	    /* -> or arrive at the first consonant. The consonant stopped at will
	     * be the base. */
	    base = i;
	  }
	  else
	  {
	    /* A ZWJ after a Halant stops the base search, and requests an explicit
	     * half form.
	     * A ZWJ before a Halant, requests a subjoined form instead, and hence
	     * search continues.  This is particularly important for Bengali
	     * sequence Ra,H,Ya that should form Ya-Phalaa by subjoining Ya. */
	    if (start < i &&
		info[i].indic_category() == OT_ZWJ &&
		info[i - 1].indic_category() == OT_H)
	      break;
	  }
	} while (i > limit);
      }
      break;

      case BASE_POS_LAST_SINHALA:
      {
        /* Sinhala base positioning is slightly different from main Indic, in that:
	 * 1. Its ZWJ behavior is different,
	 * 2. We don't need to look into the font for consonant positions.
	 */

	if (!has_reph)
	  base = limit;

	/* Find the last base consonant that is not blocked by ZWJ.  If there is
	 * a ZWJ right before a base consonant, that would request a subjoined form. */
	for (unsigned int i = limit; i < end; i++)
	  if (is_consonant (info[i]))
	  {
	    if (limit < i && info[i - 1].indic_category() == OT_ZWJ)
	      break;
	    else
	      base = i;
	  }

	/* Mark all subsequent consonants as below. */
	for (unsigned int i = base + 1; i < end; i++)
	  if (is_consonant (info[i]))
	    info[i].indic_position() = POS_BELOW_C;
      }
      break;

      case BASE_POS_FIRST:
      {
	/* The first consonant is always the base. */

	assert (indic_plan->config->reph_mode == REPH_MODE_VIS_REPHA);
	assert (!has_reph);

	base = start;

	/* Mark all subsequent consonants as below. */
	for (unsigned int i = base + 1; i < end; i++)
	  if (is_consonant (info[i]))
	    info[i].indic_position() = POS_BELOW_C;
      }
      break;
    }

    /* -> If the syllable starts with Ra + Halant (in a script that has Reph)
     *    and has more than one consonant, Ra is excluded from candidates for
     *    base consonants.
     *
     *  Only do this for unforced Reph. (ie. not for Ra,H,ZWJ. */
    if (has_reph && base == start && limit - base <= 2) {
      /* Have no other consonant, so Reph is not formed and Ra becomes base. */
      has_reph = false;
    }
  }


  /* 2. Decompose and reorder Matras:
   *
   * Each matra and any syllable modifier sign in the cluster are moved to the
   * appropriate position relative to the consonant(s) in the cluster. The
   * shaping engine decomposes two- or three-part matras into their constituent
   * parts before any repositioning. Matra characters are classified by which
   * consonant in a conjunct they have affinity for and are reordered to the
   * following positions:
   *
   *   o Before first half form in the syllable
   *   o After subjoined consonants
   *   o After post-form consonant
   *   o After main consonant (for above marks)
   *
   * IMPLEMENTATION NOTES:
   *
   * The normalize() routine has already decomposed matras for us, so we don't
   * need to worry about that.
   */


  /* 3.  Reorder marks to canonical order:
   *
   * Adjacent nukta and halant or nukta and vedic sign are always repositioned
   * if necessary, so that the nukta is first.
   *
   * IMPLEMENTATION NOTES:
   *
   * We don't need to do this: the normalize() routine already did this for us.
   */


  /* Reorder characters */

  for (unsigned int i = start; i < base; i++)
    info[i].indic_position() = MIN (POS_PRE_C, (indic_position_t) info[i].indic_position());

  if (base < end)
    info[base].indic_position() = POS_BASE_C;

  /* Mark final consonants.  A final consonant is one appearing after a matra,
   * like in Khmer. */
  for (unsigned int i = base + 1; i < end; i++)
    if (info[i].indic_category() == OT_M) {
      for (unsigned int j = i + 1; j < end; j++)
        if (is_consonant (info[j])) {
	  info[j].indic_position() = POS_FINAL_C;
	  break;
	}
      break;
    }

  /* Handle beginning Ra */
  if (has_reph)
    info[start].indic_position() = POS_RA_TO_BECOME_REPH;

  /* For old-style Indic script tags, move the first post-base Halant after
   * last consonant.
   *
   * Reports suggest that in some scripts Uniscribe does this only if there
   * is *not* a Halant after last consonant already (eg. Kannada), while it
   * does it unconditionally in other scripts (eg. Malayalam).  We don't
   * currently know about other scripts, so we single out Malayalam for now.
   *
   * Kannada test case:
   * U+0C9A,U+0CCD,U+0C9A,U+0CCD
   * With some versions of Lohit Kannada.
   * https://bugs.freedesktop.org/show_bug.cgi?id=59118
   *
   * Malayalam test case:
   * U+0D38,U+0D4D,U+0D31,U+0D4D,U+0D31,U+0D4D
   * With lohit-ttf-20121122/Lohit-Malayalam.ttf
   */
  if (indic_plan->is_old_spec)
  {
    bool disallow_double_halants = buffer->props.script != HB_SCRIPT_MALAYALAM;
    for (unsigned int i = base + 1; i < end; i++)
      if (info[i].indic_category() == OT_H)
      {
        unsigned int j;
        for (j = end - 1; j > i; j--)
	  if (is_consonant (info[j]) ||
	      (disallow_double_halants && info[j].indic_category() == OT_H))
	    break;
	if (info[j].indic_category() != OT_H && j > i) {
	  /* Move Halant to after last consonant. */
	  hb_glyph_info_t t = info[i];
	  memmove (&info[i], &info[i + 1], (j - i) * sizeof (info[0]));
	  info[j] = t;
	}
        break;
      }
  }

  /* Attach misc marks to previous char to move with them. */
  {
    indic_position_t last_pos = POS_START;
    for (unsigned int i = start; i < end; i++)
    {
      if ((FLAG (info[i].indic_category()) & (JOINER_FLAGS | FLAG (OT_N) | FLAG (OT_RS) | MEDIAL_FLAGS | HALANT_OR_COENG_FLAGS)))
      {
	info[i].indic_position() = last_pos;
	if (unlikely (info[i].indic_category() == OT_H &&
		      info[i].indic_position() == POS_PRE_M))
	{
	  /*
	   * Uniscribe doesn't move the Halant with Left Matra.
	   * TEST: U+092B,U+093F,U+094DE
	   * We follow.  This is important for the Sinhala
	   * U+0DDA split matra since it decomposes to U+0DD9,U+0DCA
	   * where U+0DD9 is a left matra and U+0DCA is the virama.
	   * We don't want to move the virama with the left matra.
	   * TEST: U+0D9A,U+0DDA
	   */
	  for (unsigned int j = i; j > start; j--)
	    if (info[j - 1].indic_position() != POS_PRE_M) {
	      info[i].indic_position() = info[j - 1].indic_position();
	      break;
	    }
	}
      } else if (info[i].indic_position() != POS_SMVD) {
        last_pos = (indic_position_t) info[i].indic_position();
      }
    }
  }
  /* For post-base consonants let them own anything before them
   * since the last consonant or matra. */
  {
    unsigned int last = base;
    for (unsigned int i = base + 1; i < end; i++)
      if (is_consonant (info[i]))
      {
	for (unsigned int j = last + 1; j < i; j++)
	  if (info[j].indic_position() < POS_SMVD)
	    info[j].indic_position() = info[i].indic_position();
	last = i;
      } else if (info[i].indic_category() == OT_M)
        last = i;
  }


  {
    /* Use syllable() for sort accounting temporarily. */
    unsigned int syllable = info[start].syllable();
    for (unsigned int i = start; i < end; i++)
      info[i].syllable() = i - start;

    /* Sit tight, rock 'n roll! */
    hb_bubble_sort (info + start, end - start, compare_indic_order);
    /* Find base again */
    base = end;
    for (unsigned int i = start; i < end; i++)
      if (info[i].indic_position() == POS_BASE_C)
      {
	base = i;
	break;
      }
    /* Things are out-of-control for post base positions, they may shuffle
     * around like crazy.  In old-spec mode, we move halants around, so in
     * that case merge all clusters after base.  Otherwise, check the sort
     * order and merge as needed.
     * For pre-base stuff, we handle cluster issues in final reordering. */
    if (indic_plan->is_old_spec || end - base > 127)
      buffer->merge_clusters (base, end);
    else
    {
      /* Note!  syllable() is a one-byte field. */
      for (unsigned int i = base; i < end; i++)
        if (info[i].syllable() != 255)
	{
	  unsigned int max = i;
	  unsigned int j = start + info[i].syllable();
	  while (j != i)
	  {
	    max = MAX (max, j);
	    unsigned int next = start + info[j].syllable();
	    info[j].syllable() = 255; /* So we don't process j later again. */
	    j = next;
	  }
	  if (i != max)
	    buffer->merge_clusters (i, max + 1);
	}
    }

    /* Put syllable back in. */
    for (unsigned int i = start; i < end; i++)
      info[i].syllable() = syllable;
  }

  /* Setup masks now */

  {
    hb_mask_t mask;

    /* Reph */
    for (unsigned int i = start; i < end && info[i].indic_position() == POS_RA_TO_BECOME_REPH; i++)
      info[i].mask |= indic_plan->mask_array[RPHF];

    /* Pre-base */
    mask = indic_plan->mask_array[HALF];
    if (!indic_plan->is_old_spec &&
	indic_plan->config->blwf_mode == BLWF_MODE_PRE_AND_POST)
      mask |= indic_plan->mask_array[BLWF];
    for (unsigned int i = start; i < base; i++)
      info[i].mask  |= mask;
    /* Base */
    mask = 0;
    if (base < end)
      info[base].mask |= mask;
    /* Post-base */
    mask = indic_plan->mask_array[BLWF] | indic_plan->mask_array[ABVF] | indic_plan->mask_array[PSTF];
    for (unsigned int i = base + 1; i < end; i++)
      info[i].mask  |= mask;
  }

  if (indic_plan->is_old_spec &&
      buffer->props.script == HB_SCRIPT_DEVANAGARI)
  {
    /* Old-spec eye-lash Ra needs special handling.  From the
     * spec:
     *
     * "The feature 'below-base form' is applied to consonants
     * having below-base forms and following the base consonant.
     * The exception is vattu, which may appear below half forms
     * as well as below the base glyph. The feature 'below-base
     * form' will be applied to all such occurrences of Ra as well."
     *
     * Test case: U+0924,U+094D,U+0930,U+094d,U+0915
     * with Sanskrit 2003 font.
     *
     * However, note that Ra,Halant,ZWJ is the correct way to
     * request eyelash form of Ra, so we wouldbn't inhibit it
     * in that sequence.
     *
     * Test case: U+0924,U+094D,U+0930,U+094d,U+200D,U+0915
     */
    for (unsigned int i = start; i + 1 < base; i++)
      if (info[i  ].indic_category() == OT_Ra &&
	  info[i+1].indic_category() == OT_H  &&
	  (i + 2 == base ||
	   info[i+2].indic_category() != OT_ZWJ))
      {
	info[i  ].mask |= indic_plan->mask_array[BLWF];
	info[i+1].mask |= indic_plan->mask_array[BLWF];
      }
  }

  unsigned int pref_len = indic_plan->config->pref_len;
  if (indic_plan->mask_array[PREF] && base + pref_len < end)
  {
    assert (1 <= pref_len && pref_len <= 2);
    /* Find a Halant,Ra sequence and mark it for pre-base reordering processing. */
    for (unsigned int i = base + 1; i + pref_len - 1 < end; i++) {
      hb_codepoint_t glyphs[2];
      for (unsigned int j = 0; j < pref_len; j++)
        glyphs[j] = info[i + j].codepoint;
      if (indic_plan->pref.would_substitute (glyphs, pref_len, face))
      {
	for (unsigned int j = 0; j < pref_len; j++)
	  info[i++].mask |= indic_plan->mask_array[PREF];

	/* Mark the subsequent stuff with 'cfar'.  Used in Khmer.
	 * Read the feature spec.
	 * This allows distinguishing the following cases with MS Khmer fonts:
	 * U+1784,U+17D2,U+179A,U+17D2,U+1782
	 * U+1784,U+17D2,U+1782,U+17D2,U+179A
	 */
	if (indic_plan->mask_array[CFAR])
	  for (; i < end; i++)
	    info[i].mask |= indic_plan->mask_array[CFAR];

	break;
      }
    }
  }

  /* Apply ZWJ/ZWNJ effects */
  for (unsigned int i = start + 1; i < end; i++)
    if (is_joiner (info[i])) {
      bool non_joiner = info[i].indic_category() == OT_ZWNJ;
      unsigned int j = i;

      do {
	j--;

	/* ZWJ/ZWNJ should disable CJCT.  They do that by simply
	 * being there, since we don't skip them for the CJCT
	 * feature (ie. F_MANUAL_ZWJ) */

	/* A ZWNJ disables HALF. */
	if (non_joiner)
	  info[j].mask &= ~indic_plan->mask_array[HALF];

      } while (j > start && !is_consonant (info[j]));
    }
}


static void
initial_reordering_vowel_syllable (const hb_ot_shape_plan_t *plan,
				   hb_face_t *face,
				   hb_buffer_t *buffer,
				   unsigned int start, unsigned int end)
{
  /* We made the vowels look like consonants.  So let's call the consonant logic! */
  initial_reordering_consonant_syllable (plan, face, buffer, start, end);
}

static void
initial_reordering_standalone_cluster (const hb_ot_shape_plan_t *plan,
				       hb_face_t *face,
				       hb_buffer_t *buffer,
				       unsigned int start, unsigned int end)
{
  /* We treat placeholder/dotted-circle as if they are consonants, so we
   * should just chain.  Only if not in compatibility mode that is... */

  if (hb_options ().uniscribe_bug_compatible)
  {
    /* For dotted-circle, this is what Uniscribe does:
     * If dotted-circle is the last glyph, it just does nothing.
     * Ie. It doesn't form Reph. */
    if (buffer->info[end - 1].indic_category() == OT_DOTTEDCIRCLE)
      return;
  }

  initial_reordering_consonant_syllable (plan, face, buffer, start, end);
}

static void
initial_reordering_broken_cluster (const hb_ot_shape_plan_t *plan,
				   hb_face_t *face,
				   hb_buffer_t *buffer,
				   unsigned int start, unsigned int end)
{
  /* We already inserted dotted-circles, so just call the standalone_cluster. */
  initial_reordering_standalone_cluster (plan, face, buffer, start, end);
}

static void
initial_reordering_symbol_cluster (const hb_ot_shape_plan_t *plan HB_UNUSED,
				   hb_face_t *face HB_UNUSED,
				   hb_buffer_t *buffer HB_UNUSED,
				   unsigned int start HB_UNUSED, unsigned int end HB_UNUSED)
{
  /* Nothing to do right now.  If we ever switch to using the output
   * buffer in the reordering process, we'd need to next_glyph() here. */
}

static void
initial_reordering_non_indic_cluster (const hb_ot_shape_plan_t *plan HB_UNUSED,
				      hb_face_t *face HB_UNUSED,
				      hb_buffer_t *buffer HB_UNUSED,
				      unsigned int start HB_UNUSED, unsigned int end HB_UNUSED)
{
  /* Nothing to do right now.  If we ever switch to using the output
   * buffer in the reordering process, we'd need to next_glyph() here. */
}


static void
initial_reordering_syllable (const hb_ot_shape_plan_t *plan,
			     hb_face_t *face,
			     hb_buffer_t *buffer,
			     unsigned int start, unsigned int end)
{
  syllable_type_t syllable_type = (syllable_type_t) (buffer->info[start].syllable() & 0x0F);
  switch (syllable_type) {
  case consonant_syllable:	initial_reordering_consonant_syllable (plan, face, buffer, start, end); return;
  case vowel_syllable:		initial_reordering_vowel_syllable     (plan, face, buffer, start, end); return;
  case standalone_cluster:	initial_reordering_standalone_cluster (plan, face, buffer, start, end); return;
  case symbol_cluster:		initial_reordering_symbol_cluster     (plan, face, buffer, start, end); return;
  case broken_cluster:		initial_reordering_broken_cluster     (plan, face, buffer, start, end); return;
  case non_indic_cluster:	initial_reordering_non_indic_cluster  (plan, face, buffer, start, end); return;
  }
}

static inline void
insert_dotted_circles (const hb_ot_shape_plan_t *plan HB_UNUSED,
		       hb_font_t *font,
		       hb_buffer_t *buffer)
{
  /* Note: This loop is extra overhead, but should not be measurable. */
  bool has_broken_syllables = false;
  unsigned int count = buffer->len;
  hb_glyph_info_t *info = buffer->info;
  for (unsigned int i = 0; i < count; i++)
    if ((info[i].syllable() & 0x0F) == broken_cluster)
    {
      has_broken_syllables = true;
      break;
    }
  if (likely (!has_broken_syllables))
    return;


  hb_codepoint_t dottedcircle_glyph;
  if (!font->get_glyph (0x25CCu, 0, &dottedcircle_glyph))
    return;

  hb_glyph_info_t dottedcircle = {0};
  dottedcircle.codepoint = 0x25CCu;
  set_indic_properties (dottedcircle);
  dottedcircle.codepoint = dottedcircle_glyph;

  buffer->clear_output ();

  buffer->idx = 0;
  unsigned int last_syllable = 0;
  while (buffer->idx < buffer->len)
  {
    unsigned int syllable = buffer->cur().syllable();
    syllable_type_t syllable_type = (syllable_type_t) (syllable & 0x0F);
    if (unlikely (last_syllable != syllable && syllable_type == broken_cluster))
    {
      last_syllable = syllable;

      hb_glyph_info_t info = dottedcircle;
      info.cluster = buffer->cur().cluster;
      info.mask = buffer->cur().mask;
      info.syllable() = buffer->cur().syllable();
      /* TODO Set glyph_props? */

      /* Insert dottedcircle after possible Repha. */
      while (buffer->idx < buffer->len &&
	     last_syllable == buffer->cur().syllable() &&
	     buffer->cur().indic_category() == OT_Repha)
        buffer->next_glyph ();

      buffer->output_info (info);
    }
    else
      buffer->next_glyph ();
  }

  buffer->swap_buffers ();
}

static void
initial_reordering (const hb_ot_shape_plan_t *plan,
		    hb_font_t *font,
		    hb_buffer_t *buffer)
{
  update_consonant_positions (plan, font, buffer);
  insert_dotted_circles (plan, font, buffer);

  hb_glyph_info_t *info = buffer->info;
  unsigned int count = buffer->len;
  if (unlikely (!count)) return;
  unsigned int last = 0;
  unsigned int last_syllable = info[0].syllable();
  for (unsigned int i = 1; i < count; i++)
    if (last_syllable != info[i].syllable()) {
      initial_reordering_syllable (plan, font->face, buffer, last, i);
      last = i;
      last_syllable = info[last].syllable();
    }
  initial_reordering_syllable (plan, font->face, buffer, last, count);
}

static void
final_reordering_syllable (const hb_ot_shape_plan_t *plan,
			   hb_buffer_t *buffer,
			   unsigned int start, unsigned int end)
{
  const indic_shape_plan_t *indic_plan = (const indic_shape_plan_t *) plan->data;
  hb_glyph_info_t *info = buffer->info;


  /* This function relies heavily on halant glyphs.  Lots of ligation
   * and possibly multiplication substitutions happened prior to this
   * phase, and that might have messed up our properties.  Recover
   * from a particular case of that where we're fairly sure that a
   * class of OT_H is desired but has been lost. */
  if (indic_plan->virama_glyph)
  {
    unsigned int virama_glyph = indic_plan->virama_glyph;
    for (unsigned int i = start; i < end; i++)
      if (info[i].codepoint == virama_glyph &&
	  _hb_glyph_info_ligated (&info[i]) &&
	  _hb_glyph_info_multiplied (&info[i]))
      {
        /* This will make sure that this glyph passes is_halant_or_coeng() test. */
	info[i].indic_category() = OT_H;
	_hb_glyph_info_clear_ligated_and_multiplied (&info[i]);
      }
  }


  /* 4. Final reordering:
   *
   * After the localized forms and basic shaping forms GSUB features have been
   * applied (see below), the shaping engine performs some final glyph
   * reordering before applying all the remaining font features to the entire
   * cluster.
   */

  bool try_pref = !!indic_plan->mask_array[PREF];

  /* Find base again */
  unsigned int base;
  for (base = start; base < end; base++)
    if (info[base].indic_position() >= POS_BASE_C)
    {
      if (try_pref && base + 1 < end && indic_plan->config->pref_len == 2)
      {
	for (unsigned int i = base + 1; i < end; i++)
	  if ((info[i].mask & indic_plan->mask_array[PREF]) != 0)
	  {
	    if (!(_hb_glyph_info_substituted (&info[i]) &&
		  _hb_glyph_info_ligated_and_didnt_multiply (&info[i])))
	    {
	      /* Ok, this was a 'pref' candidate but didn't form any.
	       * Base is around here... */
	      base = i;
	      while (base < end && is_halant_or_coeng (info[base]))
		base++;
	      info[base].indic_position() = POS_BASE_C;

	      try_pref = false;
	    }
	    break;
	  }
      }

      if (start < base && info[base].indic_position() > POS_BASE_C)
        base--;
      break;
    }
  if (base == end && start < base &&
      is_one_of (info[base - 1], FLAG (OT_ZWJ)))
    base--;
  if (base < end)
    while (start < base &&
	   is_one_of (info[base], (FLAG (OT_N) | HALANT_OR_COENG_FLAGS)))
      base--;


  /*   o Reorder matras:
   *
   *     If a pre-base matra character had been reordered before applying basic
   *     features, the glyph can be moved closer to the main consonant based on
   *     whether half-forms had been formed. Actual position for the matra is
   *     defined as “after last standalone halant glyph, after initial matra
   *     position and before the main consonant”. If ZWJ or ZWNJ follow this
   *     halant, position is moved after it.
   */

  if (start + 1 < end && start < base) /* Otherwise there can't be any pre-base matra characters. */
  {
    /* If we lost track of base, alas, position before last thingy. */
    unsigned int new_pos = base == end ? base - 2 : base - 1;

    /* Malayalam / Tamil do not have "half" forms or explicit virama forms.
     * The glyphs formed by 'half' are Chillus or ligated explicit viramas.
     * We want to position matra after them.
     */
    if (buffer->props.script != HB_SCRIPT_MALAYALAM && buffer->props.script != HB_SCRIPT_TAMIL)
    {
      while (new_pos > start &&
	     !(is_one_of (info[new_pos], (FLAG (OT_M) | HALANT_OR_COENG_FLAGS))))
	new_pos--;

      /* If we found no Halant we are done.
       * Otherwise only proceed if the Halant does
       * not belong to the Matra itself! */
      if (is_halant_or_coeng (info[new_pos]) &&
	  info[new_pos].indic_position() != POS_PRE_M)
      {
	/* -> If ZWJ or ZWNJ follow this halant, position is moved after it. */
	if (new_pos + 1 < end && is_joiner (info[new_pos + 1]))
	  new_pos++;
      }
      else
        new_pos = start; /* No move. */
    }

    if (start < new_pos && info[new_pos].indic_position () != POS_PRE_M)
    {
      /* Now go see if there's actually any matras... */
      for (unsigned int i = new_pos; i > start; i--)
	if (info[i - 1].indic_position () == POS_PRE_M)
	{
	  unsigned int old_pos = i - 1;
	  hb_glyph_info_t tmp = info[old_pos];
	  memmove (&info[old_pos], &info[old_pos + 1], (new_pos - old_pos) * sizeof (info[0]));
	  info[new_pos] = tmp;
	  if (old_pos < base && base <= new_pos) /* Shouldn't actually happen. */
	    base--;
	  buffer->merge_clusters (new_pos, MIN (end, base + 1));
	  new_pos--;
	}
    } else {
      for (unsigned int i = start; i < base; i++)
	if (info[i].indic_position () == POS_PRE_M) {
	  buffer->merge_clusters (i, MIN (end, base + 1));
	  break;
	}
    }
  }


  /*   o Reorder reph:
   *
   *     Reph’s original position is always at the beginning of the syllable,
   *     (i.e. it is not reordered at the character reordering stage). However,
   *     it will be reordered according to the basic-forms shaping results.
   *     Possible positions for reph, depending on the script, are; after main,
   *     before post-base consonant forms, and after post-base consonant forms.
   */

  /* Two cases:
   *
   * - If repha is encoded as a sequence of characters (Ra,H or Ra,H,ZWJ), then
   *   we should only move it if the sequence ligated to the repha form.
   *
   * - If repha is encoded separately and in the logical position, we should only
   *   move it if it did NOT ligate.  If it ligated, it's probably the font trying
   *   to make it work without the reordering.
   */
  if (start + 1 < end &&
      info[start].indic_position() == POS_RA_TO_BECOME_REPH &&
      ((info[start].indic_category() == OT_Repha) ^
       _hb_glyph_info_ligated_and_didnt_multiply (&info[start])))
  {
    unsigned int new_reph_pos;
    reph_position_t reph_pos = indic_plan->config->reph_pos;

    assert (reph_pos != REPH_POS_DONT_CARE);

    /*       1. If reph should be positioned after post-base consonant forms,
     *          proceed to step 5.
     */
    if (reph_pos == REPH_POS_AFTER_POST)
    {
      goto reph_step_5;
    }

    /*       2. If the reph repositioning class is not after post-base: target
     *          position is after the first explicit halant glyph between the
     *          first post-reph consonant and last main consonant. If ZWJ or ZWNJ
     *          are following this halant, position is moved after it. If such
     *          position is found, this is the target position. Otherwise,
     *          proceed to the next step.
     *
     *          Note: in old-implementation fonts, where classifications were
     *          fixed in shaping engine, there was no case where reph position
     *          will be found on this step.
     */
    {
      new_reph_pos = start + 1;
      while (new_reph_pos < base && !is_halant_or_coeng (info[new_reph_pos]))
	new_reph_pos++;

      if (new_reph_pos < base && is_halant_or_coeng (info[new_reph_pos]))
      {
	/* ->If ZWJ or ZWNJ are following this halant, position is moved after it. */
	if (new_reph_pos + 1 < base && is_joiner (info[new_reph_pos + 1]))
	  new_reph_pos++;
	goto reph_move;
      }
    }

    /*       3. If reph should be repositioned after the main consonant: find the
     *          first consonant not ligated with main, or find the first
     *          consonant that is not a potential pre-base reordering Ra.
     */
    if (reph_pos == REPH_POS_AFTER_MAIN)
    {
      new_reph_pos = base;
      while (new_reph_pos + 1 < end && info[new_reph_pos + 1].indic_position() <= POS_AFTER_MAIN)
	new_reph_pos++;
      if (new_reph_pos < end)
        goto reph_move;
    }

    /*       4. If reph should be positioned before post-base consonant, find
     *          first post-base classified consonant not ligated with main. If no
     *          consonant is found, the target position should be before the
     *          first matra, syllable modifier sign or vedic sign.
     */
    /* This is our take on what step 4 is trying to say (and failing, BADLY). */
    if (reph_pos == REPH_POS_AFTER_SUB)
    {
      new_reph_pos = base;
      while (new_reph_pos < end &&
	     !( FLAG (info[new_reph_pos + 1].indic_position()) & (FLAG (POS_POST_C) | FLAG (POS_AFTER_POST) | FLAG (POS_SMVD))))
	new_reph_pos++;
      if (new_reph_pos < end)
        goto reph_move;
    }

    /*       5. If no consonant is found in steps 3 or 4, move reph to a position
     *          immediately before the first post-base matra, syllable modifier
     *          sign or vedic sign that has a reordering class after the intended
     *          reph position. For example, if the reordering position for reph
     *          is post-main, it will skip above-base matras that also have a
     *          post-main position.
     */
    reph_step_5:
    {
      /* Copied from step 2. */
      new_reph_pos = start + 1;
      while (new_reph_pos < base && !is_halant_or_coeng (info[new_reph_pos]))
	new_reph_pos++;

      if (new_reph_pos < base && is_halant_or_coeng (info[new_reph_pos]))
      {
	/* ->If ZWJ or ZWNJ are following this halant, position is moved after it. */
	if (new_reph_pos + 1 < base && is_joiner (info[new_reph_pos + 1]))
	  new_reph_pos++;
	goto reph_move;
      }
    }

    /*       6. Otherwise, reorder reph to the end of the syllable.
     */
    {
      new_reph_pos = end - 1;
      while (new_reph_pos > start && info[new_reph_pos].indic_position() == POS_SMVD)
	new_reph_pos--;

      /*
       * If the Reph is to be ending up after a Matra,Halant sequence,
       * position it before that Halant so it can interact with the Matra.
       * However, if it's a plain Consonant,Halant we shouldn't do that.
       * Uniscribe doesn't do this.
       * TEST: U+0930,U+094D,U+0915,U+094B,U+094D
       */
      if (!hb_options ().uniscribe_bug_compatible &&
	  unlikely (is_halant_or_coeng (info[new_reph_pos]))) {
	for (unsigned int i = base + 1; i < new_reph_pos; i++)
	  if (info[i].indic_category() == OT_M) {
	    /* Ok, got it. */
	    new_reph_pos--;
	  }
      }
      goto reph_move;
    }

    reph_move:
    {
      buffer->merge_clusters (start, new_reph_pos + 1);

      /* Move */
      hb_glyph_info_t reph = info[start];
      memmove (&info[start], &info[start + 1], (new_reph_pos - start) * sizeof (info[0]));
      info[new_reph_pos] = reph;
      if (start < base && base <= new_reph_pos)
	base--;
    }
  }


  /*   o Reorder pre-base reordering consonants:
   *
   *     If a pre-base reordering consonant is found, reorder it according to
   *     the following rules:
   */

  if (try_pref && base + 1 < end) /* Otherwise there can't be any pre-base reordering Ra. */
  {
    unsigned int pref_len = indic_plan->config->pref_len;
    for (unsigned int i = base + 1; i < end; i++)
      if ((info[i].mask & indic_plan->mask_array[PREF]) != 0)
      {
	/*       1. Only reorder a glyph produced by substitution during application
	 *          of the <pref> feature. (Note that a font may shape a Ra consonant with
	 *          the feature generally but block it in certain contexts.)
	 */
        /* Note: We just check that something got substituted.  We don't check that
	 * the <pref> feature actually did it...
	 *
	 * If pref len is longer than one, then only reorder if it ligated.  If
	 * pref len is one, only reorder if it didn't ligate with other things. */
	if (_hb_glyph_info_substituted (&info[i]) &&
	    ((pref_len == 1) ^ _hb_glyph_info_ligated_and_didnt_multiply (&info[i])))
	{
	  /*
	   *       2. Try to find a target position the same way as for pre-base matra.
	   *          If it is found, reorder pre-base consonant glyph.
	   *
	   *       3. If position is not found, reorder immediately before main
	   *          consonant.
	   */

	  unsigned int new_pos = base;
	  /* Malayalam / Tamil do not have "half" forms or explicit virama forms.
	   * The glyphs formed by 'half' are Chillus or ligated explicit viramas.
	   * We want to position matra after them.
	   */
	  if (buffer->props.script != HB_SCRIPT_MALAYALAM && buffer->props.script != HB_SCRIPT_TAMIL)
	  {
	    while (new_pos > start &&
		   !(is_one_of (info[new_pos - 1], FLAG(OT_M) | HALANT_OR_COENG_FLAGS)))
	      new_pos--;

	    /* In Khmer coeng model, a H,Ra can go *after* matras.  If it goes after a
	     * split matra, it should be reordered to *before* the left part of such matra. */
	    if (new_pos > start && info[new_pos - 1].indic_category() == OT_M)
	    {
	      unsigned int old_pos = i;
	      for (unsigned int i = base + 1; i < old_pos; i++)
		if (info[i].indic_category() == OT_M)
		{
		  new_pos--;
		  break;
		}
	    }
	  }

	  if (new_pos > start && is_halant_or_coeng (info[new_pos - 1]))
	  {
	    /* -> If ZWJ or ZWNJ follow this halant, position is moved after it. */
	    if (new_pos < end && is_joiner (info[new_pos]))
	      new_pos++;
	  }

	  {
	    unsigned int old_pos = i;
	    buffer->merge_clusters (new_pos, old_pos + 1);
	    hb_glyph_info_t tmp = info[old_pos];
	    memmove (&info[new_pos + 1], &info[new_pos], (old_pos - new_pos) * sizeof (info[0]));
	    info[new_pos] = tmp;
	    if (new_pos <= base && base < old_pos)
	      base++;
	  }
	}

        break;
      }
  }


  /* Apply 'init' to the Left Matra if it's a word start. */
  if (info[start].indic_position () == POS_PRE_M &&
      (!start ||
       !(FLAG (_hb_glyph_info_get_general_category (&info[start - 1])) &
	 FLAG_RANGE (HB_UNICODE_GENERAL_CATEGORY_FORMAT, HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK))))
    info[start].mask |= indic_plan->mask_array[INIT];


  /*
   * Finish off the clusters and go home!
   */
  if (hb_options ().uniscribe_bug_compatible)
  {
    switch ((hb_tag_t) plan->props.script)
    {
      case HB_SCRIPT_TAMIL:
      case HB_SCRIPT_SINHALA:
        break;

      default:
	/* Uniscribe merges the entire cluster... Except for Tamil & Sinhala.
	 * This means, half forms are submerged into the main consonants cluster.
	 * This is unnecessary, and makes cursor positioning harder, but that's what
	 * Uniscribe does. */
	buffer->merge_clusters (start, end);
	break;
    }
  }
}


static void
final_reordering (const hb_ot_shape_plan_t *plan,
		  hb_font_t *font HB_UNUSED,
		  hb_buffer_t *buffer)
{
  unsigned int count = buffer->len;
  if (unlikely (!count)) return;

  hb_glyph_info_t *info = buffer->info;
  unsigned int last = 0;
  unsigned int last_syllable = info[0].syllable();
  for (unsigned int i = 1; i < count; i++)
    if (last_syllable != info[i].syllable()) {
      final_reordering_syllable (plan, buffer, last, i);
      last = i;
      last_syllable = info[last].syllable();
    }
  final_reordering_syllable (plan, buffer, last, count);

  HB_BUFFER_DEALLOCATE_VAR (buffer, indic_category);
  HB_BUFFER_DEALLOCATE_VAR (buffer, indic_position);
}


static void
clear_syllables (const hb_ot_shape_plan_t *plan HB_UNUSED,
		 hb_font_t *font HB_UNUSED,
		 hb_buffer_t *buffer)
{
  hb_glyph_info_t *info = buffer->info;
  unsigned int count = buffer->len;
  for (unsigned int i = 0; i < count; i++)
    info[i].syllable() = 0;
}


static bool
decompose_indic (const hb_ot_shape_normalize_context_t *c,
		 hb_codepoint_t  ab,
		 hb_codepoint_t *a,
		 hb_codepoint_t *b)
{
  switch (ab)
  {
    /* Don't decompose these. */
    case 0x0931u  : return false;
    case 0x0B94u  : return false;


    /*
     * Decompose split matras that don't have Unicode decompositions.
     */

    case 0x0F77u  : *a = 0x0FB2u; *b= 0x0F81u; return true;
    case 0x0F79u  : *a = 0x0FB3u; *b= 0x0F81u; return true;
    case 0x17BEu  : *a = 0x17C1u; *b= 0x17BEu; return true;
    case 0x17BFu  : *a = 0x17C1u; *b= 0x17BFu; return true;
    case 0x17C0u  : *a = 0x17C1u; *b= 0x17C0u; return true;
    case 0x17C4u  : *a = 0x17C1u; *b= 0x17C4u; return true;
    case 0x17C5u  : *a = 0x17C1u; *b= 0x17C5u; return true;
    case 0x1925u  : *a = 0x1920u; *b= 0x1923u; return true;
    case 0x1926u  : *a = 0x1920u; *b= 0x1924u; return true;
    case 0x1B3Cu  : *a = 0x1B42u; *b= 0x1B3Cu; return true;
    case 0x1112Eu  : *a = 0x11127u; *b= 0x11131u; return true;
    case 0x1112Fu  : *a = 0x11127u; *b= 0x11132u; return true;
#if 0
    /* This one has no decomposition in Unicode, but needs no decomposition either. */
    /* case 0x0AC9u  : return false; */
    case 0x0B57u  : *a = no decomp, -> RIGHT; return true;
    case 0x1C29u  : *a = no decomp, -> LEFT; return true;
    case 0xA9C0u  : *a = no decomp, -> RIGHT; return true;
    case 0x111BuF  : *a = no decomp, -> ABOVE; return true;
#endif
  }

  if ((ab == 0x0DDAu || hb_in_range (ab, 0x0DDCu, 0x0DDEu)))
  {
    /*
     * Sinhala split matras...  Let the fun begin.
     *
     * These four characters have Unicode decompositions.  However, Uniscribe
     * decomposes them "Khmer-style", that is, it uses the character itself to
     * get the second half.  The first half of all four decompositions is always
     * U+0DD9.
     *
     * Now, there are buggy fonts, namely, the widely used lklug.ttf, that are
     * broken with Uniscribe.  But we need to support them.  As such, we only
     * do the Uniscribe-style decomposition if the character is transformed into
     * its "sec.half" form by the 'pstf' feature.  Otherwise, we fall back to
     * Unicode decomposition.
     *
     * Note that we can't unconditionally use Unicode decomposition.  That would
     * break some other fonts, that are designed to work with Uniscribe, and
     * don't have positioning features for the Unicode-style decomposition.
     *
     * Argh...
     *
     * The Uniscribe behavior is now documented in the newly published Sinhala
     * spec in 2012:
     *
     *   http://www.microsoft.com/typography/OpenTypeDev/sinhala/intro.htm#shaping
     */

    const indic_shape_plan_t *indic_plan = (const indic_shape_plan_t *) c->plan->data;

    hb_codepoint_t glyph;

    if (hb_options ().uniscribe_bug_compatible ||
	(c->font->get_glyph (ab, 0, &glyph) &&
	 indic_plan->pstf.would_substitute (&glyph, 1, c->font->face)))
    {
      /* Ok, safe to use Uniscribe-style decomposition. */
      *a = 0x0DD9u;
      *b = ab;
      return true;
    }
  }

  return c->unicode->decompose (ab, a, b);
}

static bool
compose_indic (const hb_ot_shape_normalize_context_t *c,
	       hb_codepoint_t  a,
	       hb_codepoint_t  b,
	       hb_codepoint_t *ab)
{
  /* Avoid recomposing split matras. */
  if (HB_UNICODE_GENERAL_CATEGORY_IS_MARK (c->unicode->general_category (a)))
    return false;

  /* Composition-exclusion exceptions that we want to recompose. */
  if (a == 0x09AFu && b == 0x09BCu) { *ab = 0x09DFu; return true; }

  return c->unicode->compose (a, b, ab);
}


const hb_ot_complex_shaper_t _hb_ot_complex_shaper_indic =
{
  "indic",
  collect_features_indic,
  override_features_indic,
  data_create_indic,
  data_destroy_indic,
  NULL, /* preprocess_text */
  HB_OT_SHAPE_NORMALIZATION_MODE_COMPOSED_DIACRITICS_NO_SHORT_CIRCUIT,
  decompose_indic,
  compose_indic,
  setup_masks_indic,
  HB_OT_SHAPE_ZERO_WIDTH_MARKS_NONE,
  false, /* fallback_position */
};
