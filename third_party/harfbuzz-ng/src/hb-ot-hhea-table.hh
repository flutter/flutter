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

#ifndef HB_OT_HHEA_TABLE_HH
#define HB_OT_HHEA_TABLE_HH

#include "hb-open-type-private.hh"


namespace OT {


/*
 * hhea -- The Horizontal Header Table
 * vhea -- The Vertical Header Table
 */

#define HB_OT_TAG_hhea HB_TAG('h','h','e','a')
#define HB_OT_TAG_vhea HB_TAG('v','h','e','a')


struct _hea
{
  static const hb_tag_t tableTag = HB_TAG('_','h','e','a');

  static const hb_tag_t hheaTag	= HB_OT_TAG_hhea;
  static const hb_tag_t vheaTag	= HB_OT_TAG_vhea;

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && likely (version.major == 1));
  }

  public:
  FixedVersion	version;		/* 0x00010000u for version 1.0. */
  FWORD		ascender;		/* Typographic ascent. */
  FWORD		descender;		/* Typographic descent. */
  FWORD		lineGap;		/* Typographic line gap. */
  UFWORD	advanceMax;		/* Maximum advance width/height value in
					 * metrics table. */
  FWORD		minLeadingBearing;	/* Minimum left/top sidebearing value in
					 * metrics table. */
  FWORD		minTrailingBearing;	/* Minimum right/bottom sidebearing value;
					 * calculated as Min(aw - lsb -
					 * (xMax - xMin)) for horizontal. */
  FWORD		maxExtent;		/* horizontal: Max(lsb + (xMax - xMin)),
					 * vertical: minLeadingBearing+(yMax-yMin). */
  SHORT		caretSlopeRise;		/* Used to calculate the slope of the
					 * cursor (rise/run); 1 for vertical caret,
					 * 0 for horizontal.*/
  SHORT		caretSlopeRun;		/* 0 for vertical caret, 1 for horizontal. */
  SHORT		caretOffset;		/* The amount by which a slanted
					 * highlight on a glyph needs
					 * to be shifted to produce the
					 * best appearance. Set to 0 for
					 * non-slanted fonts. */
  SHORT		reserved1;		/* Set to 0. */
  SHORT		reserved2;		/* Set to 0. */
  SHORT		reserved3;		/* Set to 0. */
  SHORT		reserved4;		/* Set to 0. */
  SHORT		metricDataFormat;	/* 0 for current format. */
  USHORT	numberOfLongMetrics;	/* Number of LongMetric entries in metric
					 * table. */
  public:
  DEFINE_SIZE_STATIC (36);
};

struct hhea : _hea {
  static const hb_tag_t tableTag	= HB_OT_TAG_hhea;
};
struct vhea : _hea {
  static const hb_tag_t tableTag	= HB_OT_TAG_vhea;
};


} /* namespace OT */


#endif /* HB_OT_HHEA_TABLE_HH */
