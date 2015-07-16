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

#ifndef HB_OT_MAXP_TABLE_HH
#define HB_OT_MAXP_TABLE_HH

#include "hb-open-type-private.hh"


namespace OT {


/*
 * maxp -- The Maximum Profile Table
 */

#define HB_OT_TAG_maxp HB_TAG('m','a','x','p')

struct maxp
{
  static const hb_tag_t tableTag	= HB_OT_TAG_maxp;

  inline unsigned int get_num_glyphs (void) const
  {
    return numGlyphs;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 likely (version.major == 1 || (version.major == 0 && version.minor == 0x5000u)));
  }

  /* We only implement version 0.5 as none of the extra fields in version 1.0 are useful. */
  protected:
  FixedVersion	version;		/* Version of the maxp table (0.5 or 1.0),
					 * 0x00005000u or 0x00010000u. */
  USHORT	numGlyphs;		/* The number of glyphs in the font. */
  public:
  DEFINE_SIZE_STATIC (6);
};


} /* namespace OT */


#endif /* HB_OT_MAXP_TABLE_HH */
