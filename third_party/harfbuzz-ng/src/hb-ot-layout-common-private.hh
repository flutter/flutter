/*
 * Copyright © 2007,2008,2009  Red Hat, Inc.
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
 * Red Hat Author(s): Behdad Esfahbod
 * Google Author(s): Behdad Esfahbod
 */

#ifndef HB_OT_LAYOUT_COMMON_PRIVATE_HH
#define HB_OT_LAYOUT_COMMON_PRIVATE_HH

#include "hb-ot-layout-private.hh"
#include "hb-open-type-private.hh"
#include "hb-set-private.hh"


namespace OT {


#define TRACE_DISPATCH(this, format) \
	hb_auto_trace_t<context_t::max_debug_depth, typename context_t::return_t> trace \
	(&c->debug_depth, c->get_name (), this, HB_FUNC, \
	 "format %d", (int) format);


#define NOT_COVERED		((unsigned int) -1)
#define MAX_NESTING_LEVEL	8
#define MAX_CONTEXT_LENGTH	64



/*
 *
 * OpenType Layout Common Table Formats
 *
 */


/*
 * Script, ScriptList, LangSys, Feature, FeatureList, Lookup, LookupList
 */

template <typename Type>
struct Record
{
  inline int cmp (hb_tag_t a) const {
    return tag.cmp (a);
  }

  struct sanitize_closure_t {
    hb_tag_t tag;
    const void *list_base;
  };
  inline bool sanitize (hb_sanitize_context_t *c, const void *base) const
  {
    TRACE_SANITIZE (this);
    const sanitize_closure_t closure = {tag, base};
    return TRACE_RETURN (c->check_struct (this) && offset.sanitize (c, base, &closure));
  }

  Tag		tag;		/* 4-byte Tag identifier */
  OffsetTo<Type>
		offset;		/* Offset from beginning of object holding
				 * the Record */
  public:
  DEFINE_SIZE_STATIC (6);
};

template <typename Type>
struct RecordArrayOf : SortedArrayOf<Record<Type> > {
  inline const Tag& get_tag (unsigned int i) const
  {
    /* We cheat slightly and don't define separate Null objects
     * for Record types.  Instead, we return the correct Null(Tag)
     * here. */
    if (unlikely (i >= this->len)) return Null(Tag);
    return (*this)[i].tag;
  }
  inline unsigned int get_tags (unsigned int start_offset,
				unsigned int *record_count /* IN/OUT */,
				hb_tag_t     *record_tags /* OUT */) const
  {
    if (record_count) {
      const Record<Type> *arr = this->sub_array (start_offset, record_count);
      unsigned int count = *record_count;
      for (unsigned int i = 0; i < count; i++)
	record_tags[i] = arr[i].tag;
    }
    return this->len;
  }
  inline bool find_index (hb_tag_t tag, unsigned int *index) const
  {
    /* If we want to allow non-sorted data, we can lsearch(). */
    int i = this->/*lsearch*/bsearch (tag);
    if (i != -1) {
        if (index) *index = i;
        return true;
    } else {
      if (index) *index = Index::NOT_FOUND_INDEX;
      return false;
    }
  }
};

template <typename Type>
struct RecordListOf : RecordArrayOf<Type>
{
  inline const Type& operator [] (unsigned int i) const
  { return this+RecordArrayOf<Type>::operator [](i).offset; }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (RecordArrayOf<Type>::sanitize (c, this));
  }
};


struct RangeRecord
{
  inline int cmp (hb_codepoint_t g) const {
    return g < start ? -1 : g <= end ? 0 : +1 ;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this));
  }

  inline bool intersects (const hb_set_t *glyphs) const {
    return glyphs->intersects (start, end);
  }

  template <typename set_t>
  inline void add_coverage (set_t *glyphs) const {
    glyphs->add_range (start, end);
  }

  GlyphID	start;		/* First GlyphID in the range */
  GlyphID	end;		/* Last GlyphID in the range */
  USHORT	value;		/* Value */
  public:
  DEFINE_SIZE_STATIC (6);
};
DEFINE_NULL_DATA (RangeRecord, "\000\001");


struct IndexArray : ArrayOf<Index>
{
  inline unsigned int get_indexes (unsigned int start_offset,
				   unsigned int *_count /* IN/OUT */,
				   unsigned int *_indexes /* OUT */) const
  {
    if (_count) {
      const USHORT *arr = this->sub_array (start_offset, _count);
      unsigned int count = *_count;
      for (unsigned int i = 0; i < count; i++)
	_indexes[i] = arr[i];
    }
    return this->len;
  }
};


struct Script;
struct LangSys;
struct Feature;


struct LangSys
{
  inline unsigned int get_feature_count (void) const
  { return featureIndex.len; }
  inline hb_tag_t get_feature_index (unsigned int i) const
  { return featureIndex[i]; }
  inline unsigned int get_feature_indexes (unsigned int start_offset,
					   unsigned int *feature_count /* IN/OUT */,
					   unsigned int *feature_indexes /* OUT */) const
  { return featureIndex.get_indexes (start_offset, feature_count, feature_indexes); }

  inline bool has_required_feature (void) const { return reqFeatureIndex != 0xFFFFu; }
  inline unsigned int get_required_feature_index (void) const
  {
    if (reqFeatureIndex == 0xFFFFu)
      return Index::NOT_FOUND_INDEX;
   return reqFeatureIndex;;
  }

  inline bool sanitize (hb_sanitize_context_t *c,
			const Record<LangSys>::sanitize_closure_t * = NULL) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && featureIndex.sanitize (c));
  }

  Offset<>	lookupOrderZ;	/* = Null (reserved for an offset to a
				 * reordering table) */
  USHORT	reqFeatureIndex;/* Index of a feature required for this
				 * language system--if no required features
				 * = 0xFFFFu */
  IndexArray	featureIndex;	/* Array of indices into the FeatureList */
  public:
  DEFINE_SIZE_ARRAY (6, featureIndex);
};
DEFINE_NULL_DATA (LangSys, "\0\0\xFF\xFF");


struct Script
{
  inline unsigned int get_lang_sys_count (void) const
  { return langSys.len; }
  inline const Tag& get_lang_sys_tag (unsigned int i) const
  { return langSys.get_tag (i); }
  inline unsigned int get_lang_sys_tags (unsigned int start_offset,
					 unsigned int *lang_sys_count /* IN/OUT */,
					 hb_tag_t     *lang_sys_tags /* OUT */) const
  { return langSys.get_tags (start_offset, lang_sys_count, lang_sys_tags); }
  inline const LangSys& get_lang_sys (unsigned int i) const
  {
    if (i == Index::NOT_FOUND_INDEX) return get_default_lang_sys ();
    return this+langSys[i].offset;
  }
  inline bool find_lang_sys_index (hb_tag_t tag, unsigned int *index) const
  { return langSys.find_index (tag, index); }

  inline bool has_default_lang_sys (void) const { return defaultLangSys != 0; }
  inline const LangSys& get_default_lang_sys (void) const { return this+defaultLangSys; }

  inline bool sanitize (hb_sanitize_context_t *c,
			const Record<Script>::sanitize_closure_t * = NULL) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (defaultLangSys.sanitize (c, this) && langSys.sanitize (c, this));
  }

  protected:
  OffsetTo<LangSys>
		defaultLangSys;	/* Offset to DefaultLangSys table--from
				 * beginning of Script table--may be Null */
  RecordArrayOf<LangSys>
		langSys;	/* Array of LangSysRecords--listed
				 * alphabetically by LangSysTag */
  public:
  DEFINE_SIZE_ARRAY (4, langSys);
};

typedef RecordListOf<Script> ScriptList;


/* http://www.microsoft.com/typography/otspec/features_pt.htm#size */
struct FeatureParamsSize
{
  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    if (unlikely (!c->check_struct (this))) return TRACE_RETURN (false);

    /* This subtable has some "history", if you will.  Some earlier versions of
     * Adobe tools calculated the offset of the FeatureParams sutable from the
     * beginning of the FeatureList table!  Now, that is dealt with in the
     * Feature implementation.  But we still need to be able to tell junk from
     * real data.  Note: We don't check that the nameID actually exists.
     *
     * Read Roberts wrote on 9/15/06 on opentype-list@indx.co.uk :
     *
     * Yes, it is correct that a new version of the AFDKO (version 2.0) will be
     * coming out soon, and that the makeotf program will build a font with a
     * 'size' feature that is correct by the specification.
     *
     * The specification for this feature tag is in the "OpenType Layout Tag
     * Registry". You can see a copy of this at:
     * http://partners.adobe.com/public/developer/opentype/index_tag8.html#size
     *
     * Here is one set of rules to determine if the 'size' feature is built
     * correctly, or as by the older versions of MakeOTF. You may be able to do
     * better.
     *
     * Assume that the offset to the size feature is according to specification,
     * and make the following value checks. If it fails, assume the the size
     * feature is calculated as versions of MakeOTF before the AFDKO 2.0 built it.
     * If this fails, reject the 'size' feature. The older makeOTF's calculated the
     * offset from the beginning of the FeatureList table, rather than from the
     * beginning of the 'size' Feature table.
     *
     * If "design size" == 0:
     *     fails check
     *
     * Else if ("subfamily identifier" == 0 and
     *     "range start" == 0 and
     *     "range end" == 0 and
     *     "range start" == 0 and
     *     "menu name ID" == 0)
     *     passes check: this is the format used when there is a design size
     * specified, but there is no recommended size range.
     *
     * Else if ("design size" <  "range start" or
     *     "design size" >   "range end" or
     *     "range end" <= "range start" or
     *     "menu name ID"  < 256 or
     *     "menu name ID"  > 32767 or
     *     menu name ID is not a name ID which is actually in the name table)
     *     fails test
     * Else
     *     passes test.
     */

    if (!designSize)
      return TRACE_RETURN (false);
    else if (subfamilyID == 0 &&
	     subfamilyNameID == 0 &&
	     rangeStart == 0 &&
	     rangeEnd == 0)
      return TRACE_RETURN (true);
    else if (designSize < rangeStart ||
	     designSize > rangeEnd ||
	     subfamilyNameID < 256 ||
	     subfamilyNameID > 32767)
      return TRACE_RETURN (false);
    else
      return TRACE_RETURN (true);
  }

  USHORT	designSize;	/* Represents the design size in 720/inch
				 * units (decipoints).  The design size entry
				 * must be non-zero.  When there is a design
				 * size but no recommended size range, the
				 * rest of the array will consist of zeros. */
  USHORT	subfamilyID;	/* Has no independent meaning, but serves
				 * as an identifier that associates fonts
				 * in a subfamily. All fonts which share a
				 * Preferred or Font Family name and which
				 * differ only by size range shall have the
				 * same subfamily value, and no fonts which
				 * differ in weight or style shall have the
				 * same subfamily value. If this value is
				 * zero, the remaining fields in the array
				 * will be ignored. */
  USHORT	subfamilyNameID;/* If the preceding value is non-zero, this
				 * value must be set in the range 256 - 32767
				 * (inclusive). It records the value of a
				 * field in the name table, which must
				 * contain English-language strings encoded
				 * in Windows Unicode and Macintosh Roman,
				 * and may contain additional strings
				 * localized to other scripts and languages.
				 * Each of these strings is the name an
				 * application should use, in combination
				 * with the family name, to represent the
				 * subfamily in a menu.  Applications will
				 * choose the appropriate version based on
				 * their selection criteria. */
  USHORT	rangeStart;	/* Large end of the recommended usage range
				 * (inclusive), stored in 720/inch units
				 * (decipoints). */
  USHORT	rangeEnd;	/* Small end of the recommended usage range
				   (exclusive), stored in 720/inch units
				 * (decipoints). */
  public:
  DEFINE_SIZE_STATIC (10);
};

/* http://www.microsoft.com/typography/otspec/features_pt.htm#ssxx */
struct FeatureParamsStylisticSet
{
  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    /* Right now minorVersion is at zero.  Which means, any table supports
     * the uiNameID field. */
    return TRACE_RETURN (c->check_struct (this));
  }

  USHORT	version;	/* (set to 0): This corresponds to a “minor”
				 * version number. Additional data may be
				 * added to the end of this Feature Parameters
				 * table in the future. */

  USHORT	uiNameID;	/* The 'name' table name ID that specifies a
				 * string (or strings, for multiple languages)
				 * for a user-interface label for this
				 * feature.  The values of uiLabelNameId and
				 * sampleTextNameId are expected to be in the
				 * font-specific name ID range (256-32767),
				 * though that is not a requirement in this
				 * Feature Parameters specification. The
				 * user-interface label for the feature can
				 * be provided in multiple languages. An
				 * English string should be included as a
				 * fallback. The string should be kept to a
				 * minimal length to fit comfortably with
				 * different application interfaces. */
  public:
  DEFINE_SIZE_STATIC (4);
};

/* http://www.microsoft.com/typography/otspec/features_ae.htm#cv01-cv99 */
struct FeatureParamsCharacterVariants
{
  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 characters.sanitize (c));
  }

  USHORT	format;			/* Format number is set to 0. */
  USHORT	featUILableNameID;	/* The ‘name’ table name ID that
					 * specifies a string (or strings,
					 * for multiple languages) for a
					 * user-interface label for this
					 * feature. (May be NULL.) */
  USHORT	featUITooltipTextNameID;/* The ‘name’ table name ID that
					 * specifies a string (or strings,
					 * for multiple languages) that an
					 * application can use for tooltip
					 * text for this feature. (May be
					 * NULL.) */
  USHORT	sampleTextNameID;	/* The ‘name’ table name ID that
					 * specifies sample text that
					 * illustrates the effect of this
					 * feature. (May be NULL.) */
  USHORT	numNamedParameters;	/* Number of named parameters. (May
					 * be zero.) */
  USHORT	firstParamUILabelNameID;/* The first ‘name’ table name ID
					 * used to specify strings for
					 * user-interface labels for the
					 * feature parameters. (Must be zero
					 * if numParameters is zero.) */
  ArrayOf<UINT24>
		characters;		/* Array of the Unicode Scalar Value
					 * of the characters for which this
					 * feature provides glyph variants.
					 * (May be zero.) */
  public:
  DEFINE_SIZE_ARRAY (14, characters);
};

struct FeatureParams
{
  inline bool sanitize (hb_sanitize_context_t *c, hb_tag_t tag) const
  {
    TRACE_SANITIZE (this);
    if (tag == HB_TAG ('s','i','z','e'))
      return TRACE_RETURN (u.size.sanitize (c));
    if ((tag & 0xFFFF0000u) == HB_TAG ('s','s','\0','\0')) /* ssXX */
      return TRACE_RETURN (u.stylisticSet.sanitize (c));
    if ((tag & 0xFFFF0000u) == HB_TAG ('c','v','\0','\0')) /* cvXX */
      return TRACE_RETURN (u.characterVariants.sanitize (c));
    return TRACE_RETURN (true);
  }

  inline const FeatureParamsSize& get_size_params (hb_tag_t tag) const
  {
    if (tag == HB_TAG ('s','i','z','e'))
      return u.size;
    return Null(FeatureParamsSize);
  }

  private:
  union {
  FeatureParamsSize			size;
  FeatureParamsStylisticSet		stylisticSet;
  FeatureParamsCharacterVariants	characterVariants;
  } u;
  DEFINE_SIZE_STATIC (17);
};

struct Feature
{
  inline unsigned int get_lookup_count (void) const
  { return lookupIndex.len; }
  inline hb_tag_t get_lookup_index (unsigned int i) const
  { return lookupIndex[i]; }
  inline unsigned int get_lookup_indexes (unsigned int start_index,
					  unsigned int *lookup_count /* IN/OUT */,
					  unsigned int *lookup_tags /* OUT */) const
  { return lookupIndex.get_indexes (start_index, lookup_count, lookup_tags); }

  inline const FeatureParams &get_feature_params (void) const
  { return this+featureParams; }

  inline bool sanitize (hb_sanitize_context_t *c,
			const Record<Feature>::sanitize_closure_t *closure) const
  {
    TRACE_SANITIZE (this);
    if (unlikely (!(c->check_struct (this) && lookupIndex.sanitize (c))))
      return TRACE_RETURN (false);

    /* Some earlier versions of Adobe tools calculated the offset of the
     * FeatureParams subtable from the beginning of the FeatureList table!
     *
     * If sanitizing "failed" for the FeatureParams subtable, try it with the
     * alternative location.  We would know sanitize "failed" if old value
     * of the offset was non-zero, but it's zeroed now.
     *
     * Only do this for the 'size' feature, since at the time of the faulty
     * Adobe tools, only the 'size' feature had FeatureParams defined.
     */

    OffsetTo<FeatureParams> orig_offset = featureParams;
    if (unlikely (!featureParams.sanitize (c, this, closure ? closure->tag : HB_TAG_NONE)))
      return TRACE_RETURN (false);

    if (likely (orig_offset.is_null ()))
      return TRACE_RETURN (true);

    if (featureParams == 0 && closure &&
	closure->tag == HB_TAG ('s','i','z','e') &&
	closure->list_base && closure->list_base < this)
    {
      unsigned int new_offset_int = (unsigned int) orig_offset -
				    (((char *) this) - ((char *) closure->list_base));

      OffsetTo<FeatureParams> new_offset;
      /* Check that it did not overflow. */
      new_offset.set (new_offset_int);
      if (new_offset == new_offset_int &&
	  c->try_set (&featureParams, new_offset) &&
	  !featureParams.sanitize (c, this, closure ? closure->tag : HB_TAG_NONE))
	return TRACE_RETURN (false);
    }

    return TRACE_RETURN (true);
  }

  OffsetTo<FeatureParams>
		 featureParams;	/* Offset to Feature Parameters table (if one
				 * has been defined for the feature), relative
				 * to the beginning of the Feature Table; = Null
				 * if not required */
  IndexArray	 lookupIndex;	/* Array of LookupList indices */
  public:
  DEFINE_SIZE_ARRAY (4, lookupIndex);
};

typedef RecordListOf<Feature> FeatureList;


struct LookupFlag : USHORT
{
  enum Flags {
    RightToLeft		= 0x0001u,
    IgnoreBaseGlyphs	= 0x0002u,
    IgnoreLigatures	= 0x0004u,
    IgnoreMarks		= 0x0008u,
    IgnoreFlags		= 0x000Eu,
    UseMarkFilteringSet	= 0x0010u,
    Reserved		= 0x00E0u,
    MarkAttachmentType	= 0xFF00u
  };
  public:
  DEFINE_SIZE_STATIC (2);
};

struct Lookup
{
  inline unsigned int get_subtable_count (void) const { return subTable.len; }

  template <typename SubTableType>
  inline const SubTableType& get_subtable (unsigned int i) const
  { return this+CastR<OffsetArrayOf<SubTableType> > (subTable)[i]; }

  template <typename SubTableType>
  inline const OffsetArrayOf<SubTableType>& get_subtables (void) const
  { return CastR<OffsetArrayOf<SubTableType> > (subTable); }
  template <typename SubTableType>
  inline OffsetArrayOf<SubTableType>& get_subtables (void)
  { return CastR<OffsetArrayOf<SubTableType> > (subTable); }

  inline unsigned int get_type (void) const { return lookupType; }

  /* lookup_props is a 32-bit integer where the lower 16-bit is LookupFlag and
   * higher 16-bit is mark-filtering-set if the lookup uses one.
   * Not to be confused with glyph_props which is very similar. */
  inline uint32_t get_props (void) const
  {
    unsigned int flag = lookupFlag;
    if (unlikely (flag & LookupFlag::UseMarkFilteringSet))
    {
      const USHORT &markFilteringSet = StructAfter<USHORT> (subTable);
      flag += (markFilteringSet << 16);
    }
    return flag;
  }

  template <typename SubTableType, typename context_t>
  inline typename context_t::return_t dispatch (context_t *c) const
  {
    unsigned int lookup_type = get_type ();
    TRACE_DISPATCH (this, lookup_type);
    unsigned int count = get_subtable_count ();
    for (unsigned int i = 0; i < count; i++) {
      typename context_t::return_t r = get_subtable<SubTableType> (i).dispatch (c, lookup_type);
      if (c->stop_sublookup_iteration (r))
        return TRACE_RETURN (r);
    }
    return TRACE_RETURN (c->default_return_value ());
  }

  inline bool serialize (hb_serialize_context_t *c,
			 unsigned int lookup_type,
			 uint32_t lookup_props,
			 unsigned int num_subtables)
  {
    TRACE_SERIALIZE (this);
    if (unlikely (!c->extend_min (*this))) return TRACE_RETURN (false);
    lookupType.set (lookup_type);
    lookupFlag.set (lookup_props & 0xFFFFu);
    if (unlikely (!subTable.serialize (c, num_subtables))) return TRACE_RETURN (false);
    if (lookupFlag & LookupFlag::UseMarkFilteringSet)
    {
      USHORT &markFilteringSet = StructAfter<USHORT> (subTable);
      markFilteringSet.set (lookup_props >> 16);
    }
    return TRACE_RETURN (true);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    /* Real sanitize of the subtables is done by GSUB/GPOS/... */
    if (!(c->check_struct (this) && subTable.sanitize (c))) return TRACE_RETURN (false);
    if (lookupFlag & LookupFlag::UseMarkFilteringSet)
    {
      const USHORT &markFilteringSet = StructAfter<USHORT> (subTable);
      if (!markFilteringSet.sanitize (c)) return TRACE_RETURN (false);
    }
    return TRACE_RETURN (true);
  }

  private:
  USHORT	lookupType;		/* Different enumerations for GSUB and GPOS */
  USHORT	lookupFlag;		/* Lookup qualifiers */
  ArrayOf<Offset<> >
		subTable;		/* Array of SubTables */
  USHORT	markFilteringSetX[VAR];	/* Index (base 0) into GDEF mark glyph sets
					 * structure. This field is only present if bit
					 * UseMarkFilteringSet of lookup flags is set. */
  public:
  DEFINE_SIZE_ARRAY2 (6, subTable, markFilteringSetX);
};

typedef OffsetListOf<Lookup> LookupList;


/*
 * Coverage Table
 */

struct CoverageFormat1
{
  friend struct Coverage;

  private:
  inline unsigned int get_coverage (hb_codepoint_t glyph_id) const
  {
    int i = glyphArray.bsearch (glyph_id);
    ASSERT_STATIC (((unsigned int) -1) == NOT_COVERED);
    return i;
  }

  inline bool serialize (hb_serialize_context_t *c,
			 Supplier<GlyphID> &glyphs,
			 unsigned int num_glyphs)
  {
    TRACE_SERIALIZE (this);
    if (unlikely (!c->extend_min (*this))) return TRACE_RETURN (false);
    glyphArray.len.set (num_glyphs);
    if (unlikely (!c->extend (glyphArray))) return TRACE_RETURN (false);
    for (unsigned int i = 0; i < num_glyphs; i++)
      glyphArray[i] = glyphs[i];
    glyphs.advance (num_glyphs);
    return TRACE_RETURN (true);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (glyphArray.sanitize (c));
  }

  inline bool intersects_coverage (const hb_set_t *glyphs, unsigned int index) const {
    return glyphs->has (glyphArray[index]);
  }

  template <typename set_t>
  inline void add_coverage (set_t *glyphs) const {
    unsigned int count = glyphArray.len;
    for (unsigned int i = 0; i < count; i++)
      glyphs->add (glyphArray[i]);
  }

  public:
  /* Older compilers need this to be public. */
  struct Iter {
    inline void init (const struct CoverageFormat1 &c_) { c = &c_; i = 0; };
    inline bool more (void) { return i < c->glyphArray.len; }
    inline void next (void) { i++; }
    inline uint16_t get_glyph (void) { return c->glyphArray[i]; }
    inline uint16_t get_coverage (void) { return i; }

    private:
    const struct CoverageFormat1 *c;
    unsigned int i;
  };
  private:

  protected:
  USHORT	coverageFormat;	/* Format identifier--format = 1 */
  SortedArrayOf<GlyphID>
		glyphArray;	/* Array of GlyphIDs--in numerical order */
  public:
  DEFINE_SIZE_ARRAY (4, glyphArray);
};

struct CoverageFormat2
{
  friend struct Coverage;

  private:
  inline unsigned int get_coverage (hb_codepoint_t glyph_id) const
  {
    int i = rangeRecord.bsearch (glyph_id);
    if (i != -1) {
      const RangeRecord &range = rangeRecord[i];
      return (unsigned int) range.value + (glyph_id - range.start);
    }
    return NOT_COVERED;
  }

  inline bool serialize (hb_serialize_context_t *c,
			 Supplier<GlyphID> &glyphs,
			 unsigned int num_glyphs)
  {
    TRACE_SERIALIZE (this);
    if (unlikely (!c->extend_min (*this))) return TRACE_RETURN (false);

    if (unlikely (!num_glyphs)) return TRACE_RETURN (true);

    unsigned int num_ranges = 1;
    for (unsigned int i = 1; i < num_glyphs; i++)
      if (glyphs[i - 1] + 1 != glyphs[i])
        num_ranges++;
    rangeRecord.len.set (num_ranges);
    if (unlikely (!c->extend (rangeRecord))) return TRACE_RETURN (false);

    unsigned int range = 0;
    rangeRecord[range].start = glyphs[0];
    rangeRecord[range].value.set (0);
    for (unsigned int i = 1; i < num_glyphs; i++)
      if (glyphs[i - 1] + 1 != glyphs[i]) {
	range++;
	rangeRecord[range].start = glyphs[i];
	rangeRecord[range].value.set (i);
        rangeRecord[range].end = glyphs[i];
      } else {
        rangeRecord[range].end = glyphs[i];
      }
    glyphs.advance (num_glyphs);
    return TRACE_RETURN (true);
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (rangeRecord.sanitize (c));
  }

  inline bool intersects_coverage (const hb_set_t *glyphs, unsigned int index) const {
    unsigned int i;
    unsigned int count = rangeRecord.len;
    for (i = 0; i < count; i++) {
      const RangeRecord &range = rangeRecord[i];
      if (range.value <= index &&
	  index < (unsigned int) range.value + (range.end - range.start) &&
	  range.intersects (glyphs))
        return true;
      else if (index < range.value)
        return false;
    }
    return false;
  }

  template <typename set_t>
  inline void add_coverage (set_t *glyphs) const {
    unsigned int count = rangeRecord.len;
    for (unsigned int i = 0; i < count; i++)
      rangeRecord[i].add_coverage (glyphs);
  }

  public:
  /* Older compilers need this to be public. */
  struct Iter {
    inline void init (const CoverageFormat2 &c_) {
      c = &c_;
      coverage = 0;
      i = 0;
      j = c->rangeRecord.len ? c_.rangeRecord[0].start : 0;
    }
    inline bool more (void) { return i < c->rangeRecord.len; }
    inline void next (void) {
      coverage++;
      if (j == c->rangeRecord[i].end) {
        i++;
	if (more ())
	  j = c->rangeRecord[i].start;
	return;
      }
      j++;
    }
    inline uint16_t get_glyph (void) { return j; }
    inline uint16_t get_coverage (void) { return coverage; }

    private:
    const struct CoverageFormat2 *c;
    unsigned int i, j, coverage;
  };
  private:

  protected:
  USHORT	coverageFormat;	/* Format identifier--format = 2 */
  SortedArrayOf<RangeRecord>
		rangeRecord;	/* Array of glyph ranges--ordered by
				 * Start GlyphID. rangeCount entries
				 * long */
  public:
  DEFINE_SIZE_ARRAY (4, rangeRecord);
};

struct Coverage
{
  inline unsigned int get_coverage (hb_codepoint_t glyph_id) const
  {
    switch (u.format) {
    case 1: return u.format1.get_coverage(glyph_id);
    case 2: return u.format2.get_coverage(glyph_id);
    default:return NOT_COVERED;
    }
  }

  inline bool serialize (hb_serialize_context_t *c,
			 Supplier<GlyphID> &glyphs,
			 unsigned int num_glyphs)
  {
    TRACE_SERIALIZE (this);
    if (unlikely (!c->extend_min (*this))) return TRACE_RETURN (false);
    unsigned int num_ranges = 1;
    for (unsigned int i = 1; i < num_glyphs; i++)
      if (glyphs[i - 1] + 1 != glyphs[i])
        num_ranges++;
    u.format.set (num_glyphs * 2 < num_ranges * 3 ? 1 : 2);
    switch (u.format) {
    case 1: return TRACE_RETURN (u.format1.serialize (c, glyphs, num_glyphs));
    case 2: return TRACE_RETURN (u.format2.serialize (c, glyphs, num_glyphs));
    default:return TRACE_RETURN (false);
    }
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    if (!u.format.sanitize (c)) return TRACE_RETURN (false);
    switch (u.format) {
    case 1: return TRACE_RETURN (u.format1.sanitize (c));
    case 2: return TRACE_RETURN (u.format2.sanitize (c));
    default:return TRACE_RETURN (true);
    }
  }

  inline bool intersects (const hb_set_t *glyphs) const {
    /* TODO speed this up */
    Coverage::Iter iter;
    for (iter.init (*this); iter.more (); iter.next ()) {
      if (glyphs->has (iter.get_glyph ()))
        return true;
    }
    return false;
  }

  inline bool intersects_coverage (const hb_set_t *glyphs, unsigned int index) const {
    switch (u.format) {
    case 1: return u.format1.intersects_coverage (glyphs, index);
    case 2: return u.format2.intersects_coverage (glyphs, index);
    default:return false;
    }
  }

  template <typename set_t>
  inline void add_coverage (set_t *glyphs) const {
    switch (u.format) {
    case 1: u.format1.add_coverage (glyphs); break;
    case 2: u.format2.add_coverage (glyphs); break;
    default:                                 break;
    }
  }

  struct Iter {
    Iter (void) : format (0) {};
    inline void init (const Coverage &c_) {
      format = c_.u.format;
      switch (format) {
      case 1: u.format1.init (c_.u.format1); return;
      case 2: u.format2.init (c_.u.format2); return;
      default:                               return;
      }
    }
    inline bool more (void) {
      switch (format) {
      case 1: return u.format1.more ();
      case 2: return u.format2.more ();
      default:return false;
      }
    }
    inline void next (void) {
      switch (format) {
      case 1: u.format1.next (); break;
      case 2: u.format2.next (); break;
      default:                   break;
      }
    }
    inline uint16_t get_glyph (void) {
      switch (format) {
      case 1: return u.format1.get_glyph ();
      case 2: return u.format2.get_glyph ();
      default:return 0;
      }
    }
    inline uint16_t get_coverage (void) {
      switch (format) {
      case 1: return u.format1.get_coverage ();
      case 2: return u.format2.get_coverage ();
      default:return -1;
      }
    }

    private:
    unsigned int format;
    union {
    CoverageFormat1::Iter	format1;
    CoverageFormat2::Iter	format2;
    } u;
  };

  protected:
  union {
  USHORT		format;		/* Format identifier */
  CoverageFormat1	format1;
  CoverageFormat2	format2;
  } u;
  public:
  DEFINE_SIZE_UNION (2, format);
};


/*
 * Class Definition Table
 */

struct ClassDefFormat1
{
  friend struct ClassDef;

  private:
  inline unsigned int get_class (hb_codepoint_t glyph_id) const
  {
    unsigned int i = (unsigned int) (glyph_id - startGlyph);
    if (unlikely (i < classValue.len))
      return classValue[i];
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && classValue.sanitize (c));
  }

  template <typename set_t>
  inline void add_class (set_t *glyphs, unsigned int klass) const {
    unsigned int count = classValue.len;
    for (unsigned int i = 0; i < count; i++)
      if (classValue[i] == klass)
        glyphs->add (startGlyph + i);
  }

  inline bool intersects_class (const hb_set_t *glyphs, unsigned int klass) const {
    unsigned int count = classValue.len;
    if (klass == 0)
    {
      /* Match if there's any glyph that is not listed! */
      hb_codepoint_t g = -1;
      if (!hb_set_next (glyphs, &g))
        return false;
      if (g < startGlyph)
        return true;
      g = startGlyph + count - 1;
      if (hb_set_next (glyphs, &g))
        return true;
      /* Fall through. */
    }
    for (unsigned int i = 0; i < count; i++)
      if (classValue[i] == klass && glyphs->has (startGlyph + i))
        return true;
    return false;
  }

  protected:
  USHORT	classFormat;		/* Format identifier--format = 1 */
  GlyphID	startGlyph;		/* First GlyphID of the classValueArray */
  ArrayOf<USHORT>
		classValue;		/* Array of Class Values--one per GlyphID */
  public:
  DEFINE_SIZE_ARRAY (6, classValue);
};

struct ClassDefFormat2
{
  friend struct ClassDef;

  private:
  inline unsigned int get_class (hb_codepoint_t glyph_id) const
  {
    int i = rangeRecord.bsearch (glyph_id);
    if (unlikely (i != -1))
      return rangeRecord[i].value;
    return 0;
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (rangeRecord.sanitize (c));
  }

  template <typename set_t>
  inline void add_class (set_t *glyphs, unsigned int klass) const {
    unsigned int count = rangeRecord.len;
    for (unsigned int i = 0; i < count; i++)
      if (rangeRecord[i].value == klass)
        rangeRecord[i].add_coverage (glyphs);
  }

  inline bool intersects_class (const hb_set_t *glyphs, unsigned int klass) const {
    unsigned int count = rangeRecord.len;
    if (klass == 0)
    {
      /* Match if there's any glyph that is not listed! */
      hb_codepoint_t g = (hb_codepoint_t) -1;
      for (unsigned int i = 0; i < count; i++)
      {
	if (!hb_set_next (glyphs, &g))
	  break;
	if (g < rangeRecord[i].start)
	  return true;
	g = rangeRecord[i].end;
      }
      if (g != (hb_codepoint_t) -1 && hb_set_next (glyphs, &g))
        return true;
      /* Fall through. */
    }
    for (unsigned int i = 0; i < count; i++)
      if (rangeRecord[i].value == klass && rangeRecord[i].intersects (glyphs))
        return true;
    return false;
  }

  protected:
  USHORT	classFormat;	/* Format identifier--format = 2 */
  SortedArrayOf<RangeRecord>
		rangeRecord;	/* Array of glyph ranges--ordered by
				 * Start GlyphID */
  public:
  DEFINE_SIZE_ARRAY (4, rangeRecord);
};

struct ClassDef
{
  inline unsigned int get_class (hb_codepoint_t glyph_id) const
  {
    switch (u.format) {
    case 1: return u.format1.get_class(glyph_id);
    case 2: return u.format2.get_class(glyph_id);
    default:return 0;
    }
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    if (!u.format.sanitize (c)) return TRACE_RETURN (false);
    switch (u.format) {
    case 1: return TRACE_RETURN (u.format1.sanitize (c));
    case 2: return TRACE_RETURN (u.format2.sanitize (c));
    default:return TRACE_RETURN (true);
    }
  }

  inline void add_class (hb_set_t *glyphs, unsigned int klass) const {
    switch (u.format) {
    case 1: u.format1.add_class (glyphs, klass); return;
    case 2: u.format2.add_class (glyphs, klass); return;
    default:return;
    }
  }

  inline bool intersects_class (const hb_set_t *glyphs, unsigned int klass) const {
    switch (u.format) {
    case 1: return u.format1.intersects_class (glyphs, klass);
    case 2: return u.format2.intersects_class (glyphs, klass);
    default:return false;
    }
  }

  protected:
  union {
  USHORT		format;		/* Format identifier */
  ClassDefFormat1	format1;
  ClassDefFormat2	format2;
  } u;
  public:
  DEFINE_SIZE_UNION (2, format);
};


/*
 * Device Tables
 */

struct Device
{

  inline hb_position_t get_x_delta (hb_font_t *font) const
  { return get_delta (font->x_ppem, font->x_scale); }

  inline hb_position_t get_y_delta (hb_font_t *font) const
  { return get_delta (font->y_ppem, font->y_scale); }

  inline int get_delta (unsigned int ppem, int scale) const
  {
    if (!ppem) return 0;

    int pixels = get_delta_pixels (ppem);

    if (!pixels) return 0;

    return (int) (pixels * (int64_t) scale / ppem);
  }


  inline int get_delta_pixels (unsigned int ppem_size) const
  {
    unsigned int f = deltaFormat;
    if (unlikely (f < 1 || f > 3))
      return 0;

    if (ppem_size < startSize || ppem_size > endSize)
      return 0;

    unsigned int s = ppem_size - startSize;

    unsigned int byte = deltaValue[s >> (4 - f)];
    unsigned int bits = (byte >> (16 - (((s & ((1 << (4 - f)) - 1)) + 1) << f)));
    unsigned int mask = (0xFFFFu >> (16 - (1 << f)));

    int delta = bits & mask;

    if ((unsigned int) delta >= ((mask + 1) >> 1))
      delta -= mask + 1;

    return delta;
  }

  inline unsigned int get_size (void) const
  {
    unsigned int f = deltaFormat;
    if (unlikely (f < 1 || f > 3 || startSize > endSize)) return 3 * USHORT::static_size;
    return USHORT::static_size * (4 + ((endSize - startSize) >> (4 - f)));
  }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) && c->check_range (this, this->get_size ()));
  }

  protected:
  USHORT	startSize;		/* Smallest size to correct--in ppem */
  USHORT	endSize;		/* Largest size to correct--in ppem */
  USHORT	deltaFormat;		/* Format of DeltaValue array data: 1, 2, or 3
					 * 1	Signed 2-bit value, 8 values per uint16
					 * 2	Signed 4-bit value, 4 values per uint16
					 * 3	Signed 8-bit value, 2 values per uint16
					 */
  USHORT	deltaValue[VAR];	/* Array of compressed data */
  public:
  DEFINE_SIZE_ARRAY (6, deltaValue);
};


} /* namespace OT */


#endif /* HB_OT_LAYOUT_COMMON_PRIVATE_HH */
