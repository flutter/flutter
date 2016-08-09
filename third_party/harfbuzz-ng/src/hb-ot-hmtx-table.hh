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

#ifndef HB_OT_HMTX_TABLE_HH
#define HB_OT_HMTX_TABLE_HH

#include "hb-open-type-private.hh"


namespace OT {


/*
 * hmtx -- The Horizontal Metrics Table
 * vmtx -- The Vertical Metrics Table
 */

#define HB_OT_TAG_hmtx HB_TAG('h','m','t','x')
#define HB_OT_TAG_vmtx HB_TAG('v','m','t','x')


struct LongMetric
{
  USHORT	advance; /* Advance width/height. */
  SHORT		lsb; /* Leading (left/top) side bearing. */
  public:
  DEFINE_SIZE_STATIC (4);
};

struct _mtx
{
  static const hb_tag_t tableTag = HB_TAG('_','m','t','x');

  static const hb_tag_t hmtxTag	= HB_OT_TAG_hmtx;
  static const hb_tag_t vmtxTag	= HB_OT_TAG_vmtx;

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    /* We don't check for anything specific here.  The users of the
     * struct do all the hard work... */
    return TRACE_RETURN (true);
  }

  public:
  LongMetric	longMetric[VAR];	/* Paired advance width and leading
					 * bearing values for each glyph. The
					 * value numOfHMetrics comes from
					 * the 'hhea' table. If the font is
					 * monospaced, only one entry need
					 * be in the array, but that entry is
					 * required. The last entry applies to
					 * all subsequent glyphs. */
  SHORT		leadingBearingX[VAR];	/* Here the advance is assumed
					 * to be the same as the advance
					 * for the last entry above. The
					 * number of entries in this array is
					 * derived from numGlyphs (from 'maxp'
					 * table) minus numberOfLongMetrics.
					 * This generally is used with a run
					 * of monospaced glyphs (e.g., Kanji
					 * fonts or Courier fonts). Only one
					 * run is allowed and it must be at
					 * the end. This allows a monospaced
					 * font to vary the side bearing
					 * values for each glyph. */
  public:
  DEFINE_SIZE_ARRAY2 (0, longMetric, leadingBearingX);
};

struct hmtx : _mtx {
  static const hb_tag_t tableTag	= HB_OT_TAG_hmtx;
};
struct vmtx : _mtx {
  static const hb_tag_t tableTag	= HB_OT_TAG_vmtx;
};

} /* namespace OT */


#endif /* HB_OT_HMTX_TABLE_HH */
