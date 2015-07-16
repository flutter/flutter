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

#ifndef HB_OT_LAYOUT_JSTF_TABLE_HH
#define HB_OT_LAYOUT_JSTF_TABLE_HH

#include "hb-open-type-private.hh"
#include "hb-ot-layout-gpos-table.hh"


namespace OT {


/*
 * JstfModList -- Justification Modification List Tables
 */

typedef IndexArray JstfModList;


/*
 * JstfMax -- Justification Maximum Table
 */

typedef OffsetListOf<PosLookup> JstfMax;


/*
 * JstfPriority -- Justification Priority Table
 */

struct JstfPriority
{
  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (c->check_struct (this) &&
			 shrinkageEnableGSUB.sanitize (c, this) &&
			 shrinkageDisableGSUB.sanitize (c, this) &&
			 shrinkageEnableGPOS.sanitize (c, this) &&
			 shrinkageDisableGPOS.sanitize (c, this) &&
			 shrinkageJstfMax.sanitize (c, this) &&
			 extensionEnableGSUB.sanitize (c, this) &&
			 extensionDisableGSUB.sanitize (c, this) &&
			 extensionEnableGPOS.sanitize (c, this) &&
			 extensionDisableGPOS.sanitize (c, this) &&
			 extensionJstfMax.sanitize (c, this));
  }

  protected:
  OffsetTo<JstfModList>
		shrinkageEnableGSUB;	/* Offset to Shrinkage Enable GSUB
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		shrinkageDisableGSUB;	/* Offset to Shrinkage Disable GSUB
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		shrinkageEnableGPOS;	/* Offset to Shrinkage Enable GPOS
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		shrinkageDisableGPOS;	/* Offset to Shrinkage Disable GPOS
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfMax>
		shrinkageJstfMax;	/* Offset to Shrinkage JstfMax table--
					 * from beginning of JstfPriority table
					 * --may be NULL */
  OffsetTo<JstfModList>
		extensionEnableGSUB;	/* Offset to Extension Enable GSUB
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		extensionDisableGSUB;	/* Offset to Extension Disable GSUB
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		extensionEnableGPOS;	/* Offset to Extension Enable GPOS
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfModList>
		extensionDisableGPOS;	/* Offset to Extension Disable GPOS
					 * JstfModList table--from beginning of
					 * JstfPriority table--may be NULL */
  OffsetTo<JstfMax>
		extensionJstfMax;	/* Offset to Extension JstfMax table--
					 * from beginning of JstfPriority table
					 * --may be NULL */

  public:
  DEFINE_SIZE_STATIC (20);
};


/*
 * JstfLangSys -- Justification Language System Table
 */

struct JstfLangSys : OffsetListOf<JstfPriority>
{
  inline bool sanitize (hb_sanitize_context_t *c,
			const Record<JstfLangSys>::sanitize_closure_t * = NULL) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (OffsetListOf<JstfPriority>::sanitize (c));
  }
};


/*
 * ExtenderGlyphs -- Extender Glyph Table
 */

typedef SortedArrayOf<GlyphID> ExtenderGlyphs;


/*
 * JstfScript -- The Justification Table
 */

struct JstfScript
{
  inline unsigned int get_lang_sys_count (void) const
  { return langSys.len; }
  inline const Tag& get_lang_sys_tag (unsigned int i) const
  { return langSys.get_tag (i); }
  inline unsigned int get_lang_sys_tags (unsigned int start_offset,
					 unsigned int *lang_sys_count /* IN/OUT */,
					 hb_tag_t     *lang_sys_tags /* OUT */) const
  { return langSys.get_tags (start_offset, lang_sys_count, lang_sys_tags); }
  inline const JstfLangSys& get_lang_sys (unsigned int i) const
  {
    if (i == Index::NOT_FOUND_INDEX) return get_default_lang_sys ();
    return this+langSys[i].offset;
  }
  inline bool find_lang_sys_index (hb_tag_t tag, unsigned int *index) const
  { return langSys.find_index (tag, index); }

  inline bool has_default_lang_sys (void) const { return defaultLangSys != 0; }
  inline const JstfLangSys& get_default_lang_sys (void) const { return this+defaultLangSys; }

  inline bool sanitize (hb_sanitize_context_t *c,
			const Record<JstfScript>::sanitize_closure_t * = NULL) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (extenderGlyphs.sanitize (c, this) &&
			 defaultLangSys.sanitize (c, this) &&
			 langSys.sanitize (c, this));
  }

  protected:
  OffsetTo<ExtenderGlyphs>
		extenderGlyphs;	/* Offset to ExtenderGlyph table--from beginning
				 * of JstfScript table-may be NULL */
  OffsetTo<JstfLangSys>
		defaultLangSys;	/* Offset to DefaultJstfLangSys table--from
				 * beginning of JstfScript table--may be Null */
  RecordArrayOf<JstfLangSys>
		langSys;	/* Array of JstfLangSysRecords--listed
				 * alphabetically by LangSysTag */
  public:
  DEFINE_SIZE_ARRAY (6, langSys);
};


/*
 * JSTF -- The Justification Table
 */

struct JSTF
{
  static const hb_tag_t tableTag	= HB_OT_TAG_JSTF;

  inline unsigned int get_script_count (void) const
  { return scriptList.len; }
  inline const Tag& get_script_tag (unsigned int i) const
  { return scriptList.get_tag (i); }
  inline unsigned int get_script_tags (unsigned int start_offset,
				       unsigned int *script_count /* IN/OUT */,
				       hb_tag_t     *script_tags /* OUT */) const
  { return scriptList.get_tags (start_offset, script_count, script_tags); }
  inline const JstfScript& get_script (unsigned int i) const
  { return this+scriptList[i].offset; }
  inline bool find_script_index (hb_tag_t tag, unsigned int *index) const
  { return scriptList.find_index (tag, index); }

  inline bool sanitize (hb_sanitize_context_t *c) const
  {
    TRACE_SANITIZE (this);
    return TRACE_RETURN (version.sanitize (c) && likely (version.major == 1) &&
			 scriptList.sanitize (c, this));
  }

  protected:
  FixedVersion	version;	/* Version of the JSTF table--initially set
				 * to 0x00010000u */
  RecordArrayOf<JstfScript>
		scriptList;  	/* Array of JstfScripts--listed
				 * alphabetically by ScriptTag */
  public:
  DEFINE_SIZE_ARRAY (6, scriptList);
};


} /* namespace OT */


#endif /* HB_OT_LAYOUT_JSTF_TABLE_HH */
