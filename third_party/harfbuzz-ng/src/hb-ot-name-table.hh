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

#ifndef HB_OT_NAME_TABLE_HH
#define HB_OT_NAME_TABLE_HH

#include "hb-open-type-private.hh"


namespace OT {


/*
 * name -- The Naming Table
 */

#define HB_OT_TAG_name HB_TAG('n','a','m','e')


struct NameRecord
{
  static int cmp (const NameRecord *a, const NameRecord *b)
  {
    int ret;
    ret = b->platformID.cmp (a->platformID);
    if (ret) return ret;
    ret = b->encodingID.cmp (a->encodingID);
    if (ret) return ret;
    ret = b->languageID.cmp (a->languageID);
    if (ret) return ret;
    ret = b->nameID.cmp (a->nameID);
    if (ret) return ret;
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c, const void *base) const
  {
    TRACE_SANITIZE (this);
    /* We can check from base all the way up to the end of string... */
    return TRACE_RETURN (c->check_struct (this) && c->check_range ((char *) base, (unsigned int) length + offset));
  }

  USHORT	platformID;	/* Platform ID. */
  USHORT	encodingID;	/* Platform-specific encoding ID. */
  USHORT	languageID;	/* Language ID. */
  USHORT	nameID;		/* Name ID. */
  USHORT	length;		/* String length (in bytes). */
  USHORT	offset;		/* String offset from start of storage area (in bytes). */
  public:
  DEFINE_SIZE_STATIC (12);
};

struct name
{
  static const hb_tag_t tableTag	= HB_OT_TAG_name;

  inline unsigned int get_name (unsigned int platform_id,
				unsigned int encoding_id,
				unsigned int language_id,
				unsigned int name_id,
				void *buffer,
				unsigned int buffer_length) const
  {
    NameRecord key;
    key.platformID.set (platform_id);
    key.encodingID.set (encoding_id);
    key.languageID.set (language_id);
    key.nameID.set (name_id);
    NameRecord *match = (NameRecord *) bsearch (&key, nameRecord, count, sizeof (nameRecord[0]), (hb_compare_func_t) NameRecord::cmp);

    if (!match)
      return 0;

    unsigned int length = MIN (buffer_length, (unsigned int) match->length);
    memcpy (buffer, (char *) this + stringOffset + match->offset, length);
    return length;
  }

  inline unsigned int get_size (void) const
  { return min_size + count * nameRecord[0].min_size; }

  inline bool sanitize_records (hb_sanitize_context_t *c) const {
    TRACE_SANITIZE (this);
    char *string_pool = (char *) this + stringOffset;
    unsigned int _count = count;
    for (unsigned int i = 0; i < _count; i++)
      if (!nameRecord[i].sanitize (c, string_pool)) return TRACE_RETURN (false);
    return TRACE_RETURN (true);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 likely (format == 0 || format == 1) &&
			 c->check_array (nameRecord, nameRecord[0].static_size, count) &&
			 sanitize_records (c));
  }

  /* We only implement format 0 for now. */
  USHORT	format;			/* Format selector (=0/1). */
  USHORT	count;			/* Number of name records. */
  Offset<>	stringOffset;		/* Offset to start of string storage (from start of table). */
  NameRecord	nameRecord[VAR];	/* The name records where count is the number of records. */
  public:
  DEFINE_SIZE_ARRAY (6, nameRecord);
};


} /* namespace OT */


#endif /* HB_OT_NAME_TABLE_HH */
