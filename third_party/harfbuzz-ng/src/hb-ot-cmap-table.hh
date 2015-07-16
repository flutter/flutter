/*
 * Copyright © 2014  Google, Inc.
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

#ifndef HB_OT_CMAP_TABLE_HH
#define HB_OT_CMAP_TABLE_HH

#include "hb-open-type-private.hh"


namespace OT {


/*
 * cmap -- Character To Glyph Index Mapping Table
 */

#define HB_OT_TAG_cmap HB_TAG('c','m','a','p')


struct CmapSubtableFormat0
{
  inline bool get_glyph (hb_codepoint_t codepoint, hb_codepoint_t *glyph) const
  {
    hb_codepoint_t gid = codepoint < 256 ? glyphIdArray[codepoint] : 0;
    if (!gid)
      return false;
    *glyph = gid;
    return true;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this));
  }

  protected:
  USHORT	format;		/* Format number is set to 0. */
  USHORT	lengthZ;	/* Byte length of this subtable. */
  USHORT	languageZ;	/* Ignore. */
  BYTE		glyphIdArray[256];/* An array that maps character
				 * code to glyph index values. */
  public:
  DEFINE_SIZE_STATIC (6 + 256);
};

struct CmapSubtableFormat4
{
  inline bool get_glyph (hb_codepoint_t codepoint, hb_codepoint_t *glyph) const
  {
    unsigned int segCount;
    const USHORT *endCount;
    const USHORT *startCount;
    const USHORT *idDelta;
    const USHORT *idRangeOffset;
    const USHORT *glyphIdArray;
    unsigned int glyphIdArrayLength;

    segCount = this->segCountX2 / 2;
    endCount = this->values;
    startCount = endCount + segCount + 1;
    idDelta = startCount + segCount;
    idRangeOffset = idDelta + segCount;
    glyphIdArray = idRangeOffset + segCount;
    glyphIdArrayLength = (this->length - 16 - 8 * segCount) / 2;

    /* Custom two-array bsearch. */
    int min = 0, max = (int) segCount - 1;
    unsigned int i;
    while (min <= max)
    {
      int mid = (min + max) / 2;
      if (codepoint < startCount[mid])
        max = mid - 1;
      else if (codepoint > endCount[mid])
        min = mid + 1;
      else
      {
	i = mid;
	goto found;
      }
    }
    return false;

  found:
    hb_codepoint_t gid;
    unsigned int rangeOffset = idRangeOffset[i];
    if (rangeOffset == 0)
      gid = codepoint + idDelta[i];
    else
    {
      /* Somebody has been smoking... */
      unsigned int index = rangeOffset / 2 + (codepoint - startCount[i]) + i - segCount;
      if (unlikely (index >= glyphIdArrayLength))
	return false;
      gid = glyphIdArray[index];
      if (unlikely (!gid))
	return false;
      gid += idDelta[i];
    }

    *glyph = gid & 0xFFFFu;
    return true;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    if (unlikely (!c->check_struct (this)))
      return TRACE_RETURN (false);

    if (unlikely (!c->check_range (this, length)))
    {
      /* Some broken fonts have too long of a "length" value.
       * If that is the case, just change the value to truncate
       * the subtable at the end of the blob. */
      uint16_t new_length = (uint16_t) MIN ((uintptr_t) 65535,
					    (uintptr_t) (c->end -
							 (char *) this));
      if (!c->try_set (&length, new_length))
	return TRACE_RETURN (false);
    }

    return TRACE_RETURN (16 + 4 * (unsigned int) segCountX2 <= length);
  }

  protected:
  USHORT	format;		/* Format number is set to 4. */
  USHORT	length;		/* This is the length in bytes of the
				 * subtable. */
  USHORT	languageZ;	/* Ignore. */
  USHORT	segCountX2;	/* 2 x segCount. */
  USHORT	searchRangeZ;	/* 2 * (2**floor(log2(segCount))) */
  USHORT	entrySelectorZ;	/* log2(searchRange/2) */
  USHORT	rangeShiftZ;	/* 2 x segCount - searchRange */

  USHORT	values[VAR];
#if 0
  USHORT	endCount[segCount];	/* End characterCode for each segment,
					 * last=0xFFFFu. */
  USHORT	reservedPad;		/* Set to 0. */
  USHORT	startCount[segCount];	/* Start character code for each segment. */
  SHORT		idDelta[segCount];	/* Delta for all character codes in segment. */
  USHORT	idRangeOffset[segCount];/* Offsets into glyphIdArray or 0 */
  USHORT	glyphIdArray[VAR];	/* Glyph index array (arbitrary length) */
#endif

  public:
  DEFINE_SIZE_ARRAY (14, values);
};

struct CmapSubtableLongGroup
{
  friend struct CmapSubtableFormat12;
  friend struct CmapSubtableFormat13;

  int cmp (hb_codepoint_t codepoint) const
  {
    if (codepoint < startCharCode) return -1;
    if (codepoint > endCharCode)   return +1;
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this));
  }

  private:
  ULONG		startCharCode;	/* First character code in this group. */
  ULONG		endCharCode;	/* Last character code in this group. */
  ULONG		glyphID;	/* Glyph index; interpretation depends on
				 * subtable format. */
  public:
  DEFINE_SIZE_STATIC (12);
};

template <typename UINT>
struct CmapSubtableTrimmed
{
  inline bool get_glyph (hb_codepoint_t codepoint, hb_codepoint_t *glyph) const
  {
    /* Rely on our implicit array bound-checking. */
    hb_codepoint_t gid = glyphIdArray[codepoint - startCharCode];
    if (!gid)
      return false;
    *glyph = gid;
    return true;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && glyphIdArray.sanitize (c));
  }

  protected:
  UINT		formatReserved;	/* Subtable format and (maybe) padding. */
  UINT		lengthZ;	/* Byte length of this subtable. */
  UINT		languageZ;	/* Ignore. */
  UINT		startCharCode;	/* First character code covered. */
  ArrayOf<GlyphID, UINT>
		glyphIdArray;	/* Array of glyph index values for character
				 * codes in the range. */
  public:
  DEFINE_SIZE_ARRAY (5 * sizeof (UINT), glyphIdArray);
};

struct CmapSubtableFormat6  : CmapSubtableTrimmed<USHORT> {};
struct CmapSubtableFormat10 : CmapSubtableTrimmed<ULONG > {};

template <typename T>
struct CmapSubtableLongSegmented
{
  inline bool get_glyph (hb_codepoint_t codepoint, hb_codepoint_t *glyph) const
  {
    int i = groups.bsearch (codepoint);
    if (i == -1)
      return false;
    *glyph = T::group_get_glyph (groups[i], codepoint);
    return true;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && groups.sanitize (c));
  }

  protected:
  USHORT	format;		/* Subtable format; set to 12. */
  USHORT	reservedZ;	/* Reserved; set to 0. */
  ULONG		lengthZ;	/* Byte length of this subtable. */
  ULONG		languageZ;	/* Ignore. */
  SortedArrayOf<CmapSubtableLongGroup, ULONG>
		groups;		/* Groupings. */
  public:
  DEFINE_SIZE_ARRAY (16, groups);
};

struct CmapSubtableFormat12 : CmapSubtableLongSegmented<CmapSubtableFormat12>
{
  static inline hb_codepoint_t group_get_glyph (const CmapSubtableLongGroup &group,
						hb_codepoint_t u)
  { return group.glyphID + (u - group.startCharCode); }
};

struct CmapSubtableFormat13 : CmapSubtableLongSegmented<CmapSubtableFormat13>
{
  static inline hb_codepoint_t group_get_glyph (const CmapSubtableLongGroup &group,
						hb_codepoint_t u HB_UNUSED)
  { return group.glyphID; }
};

typedef enum
{
  GLYPH_VARIANT_NOT_FOUND = 0,
  GLYPH_VARIANT_FOUND = 1,
  GLYPH_VARIANT_USE_DEFAULT = 2
} glyph_variant_t;

struct UnicodeValueRange
{
  inline int cmp (const hb_codepoint_t &codepoint) const
  {
    if (codepoint < startUnicodeValue) return -1;
    if (codepoint > startUnicodeValue + additionalCount) return +1;
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this));
  }

  UINT24	startUnicodeValue;	/* First value in this range. */
  BYTE		additionalCount;	/* Number of additional values in this
					 * range. */
  public:
  DEFINE_SIZE_STATIC (4);
};

typedef SortedArrayOf<UnicodeValueRange, ULONG> DefaultUVS;

struct UVSMapping
{
  inline int cmp (const hb_codepoint_t &codepoint) const
  {
    return unicodeValue.cmp (codepoint);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this));
  }

  UINT24	unicodeValue;	/* Base Unicode value of the UVS */
  GlyphID	glyphID;	/* Glyph ID of the UVS */
  public:
  DEFINE_SIZE_STATIC (5);
};

typedef SortedArrayOf<UVSMapping, ULONG> NonDefaultUVS;

struct VariationSelectorRecord
{
  inline glyph_variant_t get_glyph (hb_codepoint_t codepoint,
				    hb_codepoint_t *glyph,
				    const void *base) const
  {
    int i;
    const DefaultUVS &defaults = base+defaultUVS;
    i = defaults.bsearch (codepoint);
    if (i != -1)
      return GLYPH_VARIANT_USE_DEFAULT;
    const NonDefaultUVS &nonDefaults = base+nonDefaultUVS;
    i = nonDefaults.bsearch (codepoint);
    if (i != -1)
    {
      *glyph = nonDefaults[i].glyphID;
       return GLYPH_VARIANT_FOUND;
    }
    return GLYPH_VARIANT_NOT_FOUND;
  }

  inline int cmp (const hb_codepoint_t &variation_selector) const
  {
    return varSelector.cmp (variation_selector);
  }

  inline bool sanitize (hb_sanitize_context_t *c, const void *base) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 defaultUVS.sanitize (c, base) &&
			 nonDefaultUVS.sanitize (c, base));
  }

  UINT24	varSelector;	/* Variation selector. */
  OffsetTo<DefaultUVS, ULONG>
		defaultUVS;	/* Offset to Default UVS Table. May be 0. */
  OffsetTo<NonDefaultUVS, ULONG>
		nonDefaultUVS;	/* Offset to Non-Default UVS Table. May be 0. */
  public:
  DEFINE_SIZE_STATIC (11);
};

struct CmapSubtableFormat14
{
  inline glyph_variant_t get_glyph_variant (hb_codepoint_t codepoint,
					    hb_codepoint_t variation_selector,
					    hb_codepoint_t *glyph) const
  {
    return record[record.bsearch(variation_selector)].get_glyph (codepoint, glyph, this);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 record.sanitize (c, this));
  }

  protected:
  USHORT	format;		/* Format number is set to 0. */
  ULONG		lengthZ;	/* Byte length of this subtable. */
  SortedArrayOf<VariationSelectorRecord, ULONG>
		record;		/* Variation selector records; sorted
				 * in increasing order of `varSelector'. */
  public:
  DEFINE_SIZE_ARRAY (10, record);
};

struct CmapSubtable
{
  /* Note: We intentionally do NOT implement subtable formats 2 and 8. */

  inline bool get_glyph (hb_codepoint_t codepoint,
			 hb_codepoint_t *glyph) const
  {
    switch (u.format) {
    case  0: return u.format0 .get_glyph(codepoint, glyph);
    case  4: return u.format4 .get_glyph(codepoint, glyph);
    case  6: return u.format6 .get_glyph(codepoint, glyph);
    case 10: return u.format10.get_glyph(codepoint, glyph);
    case 12: return u.format12.get_glyph(codepoint, glyph);
    case 13: return u.format13.get_glyph(codepoint, glyph);
    case 14:
    default: return false;
    }
  }

  inline glyph_variant_t get_glyph_variant (hb_codepoint_t codepoint,
					    hb_codepoint_t variation_selector,
					    hb_codepoint_t *glyph) const
  {
    switch (u.format) {
    case 14: return u.format14.get_glyph_variant(codepoint, variation_selector, glyph);
    default: return GLYPH_VARIANT_NOT_FOUND;
    }
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    if (!u.format.sanitize (c)) return TRACE_RETURN (false);
    switch (u.format) {
    case  0: return TRACE_RETURN (u.format0 .sanitize (c));
    case  4: return TRACE_RETURN (u.format4 .sanitize (c));
    case  6: return TRACE_RETURN (u.format6 .sanitize (c));
    case 10: return TRACE_RETURN (u.format10.sanitize (c));
    case 12: return TRACE_RETURN (u.format12.sanitize (c));
    case 13: return TRACE_RETURN (u.format13.sanitize (c));
    case 14: return TRACE_RETURN (u.format14.sanitize (c));
    default:return TRACE_RETURN (true);
    }
  }

  protected:
  union {
  USHORT		format;		/* Format identifier */
  CmapSubtableFormat0	format0;
  CmapSubtableFormat4	format4;
  CmapSubtableFormat6	format6;
  CmapSubtableFormat10	format10;
  CmapSubtableFormat12	format12;
  CmapSubtableFormat13	format13;
  CmapSubtableFormat14	format14;
  } u;
  public:
  DEFINE_SIZE_UNION (2, format);
};


struct EncodingRecord
{
  inline int cmp (const EncodingRecord &other) const
  {
    int ret;
    ret = platformID.cmp (other.platformID);
    if (ret) return ret;
    ret = encodingID.cmp (other.encodingID);
    if (ret) return ret;
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c, const void *base) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 subtable.sanitize (c, base));
  }

  USHORT	platformID;	/* Platform ID. */
  USHORT	encodingID;	/* Platform-specific encoding ID. */
  OffsetTo<CmapSubtable, ULONG>
		subtable;	/* Byte offset from beginning of table to the subtable for this encoding. */
  public:
  DEFINE_SIZE_STATIC (8);
};

struct cmap
{
  static const hb_tag_t tableTag	= HB_OT_TAG_cmap;

  inline const CmapSubtable *find_subtable (unsigned int platform_id,
					    unsigned int encoding_id) const
  {
    EncodingRecord key;
    key.platformID.set (platform_id);
    key.encodingID.set (encoding_id);

    /* Note: We can use bsearch, but since it has no performance
     * implications, we use lsearch and as such accept fonts with
     * unsorted subtable list. */
    int result = encodingRecord./*bsearch*/lsearch (key);
    if (result == -1 || !encodingRecord[result].subtable)
      return NULL;

    return &(this+encodingRecord[result].subtable);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 likely (version == 0) &&
			 encodingRecord.sanitize (c, this));
  }

  USHORT		version;	/* Table version number (0). */
  SortedArrayOf<EncodingRecord>
			encodingRecord;	/* Encoding tables. */
  public:
  DEFINE_SIZE_ARRAY (4, encodingRecord);
};


} /* namespace OT */


#endif /* HB_OT_CMAP_TABLE_HH */
