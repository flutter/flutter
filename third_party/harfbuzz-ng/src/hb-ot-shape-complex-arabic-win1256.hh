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

#ifndef HB_OT_SHAPE_COMPLEX_ARABIC_WIN1256_HH


/*
 * The macros in the first part of this file are generic macros that can
 * be used to define the bytes for OpenType table data in code in a
 * readable manner.  We can move the macros to reside with their respective
 * struct types, but since we only use these to define one data table, the
 * Windows-1256 Arabic shaping table in this file, we keep them here.
 */


/* First we measure, then we cut. */
#ifndef OT_MEASURE
#define OT_MEASURE
#define OT_TABLE_START			static const struct TABLE_NAME {
#define OT_TABLE_END			}
#define OT_LABEL_START(Name)		unsigned char Name[
#define OT_LABEL_END			];
#define OT_BYTE(u8)			+1/*byte*/
#define OT_USHORT(u16)			+2/*bytes*/
#else
#undef  OT_MEASURE
#define OT_TABLE_START			TABLE_NAME = {
#define OT_TABLE_END			};
#define OT_LABEL_START(Name)		{
#define OT_LABEL_END			},
#define OT_BYTE(u8)			(u8),
#define OT_USHORT(u16)			(unsigned char)((u16)>>8), (unsigned char)((u16)&0xFFu),
#define OT_COUNT(Name, ItemSize)	((unsigned int) sizeof(((struct TABLE_NAME*)0)->Name) \
					 / (unsigned int)(ItemSize) \
					 /* OT_ASSERT it's divisible (and positive). */)
#define OT_DISTANCE(From,To)		((unsigned int) \
					 ((char*)(&((struct TABLE_NAME*)0)->To) - \
					  (char*)(&((struct TABLE_NAME*)0)->From)) \
					 /* OT_ASSERT it's positive. */)
#endif


#define OT_LABEL(Name) \
	OT_LABEL_END \
	OT_LABEL_START(Name)

/* Whenever we receive an argument that is a list, it will expand to
 * contain commas.  That cannot be passed to another macro because the
 * commas will throw off the preprocessor.  The solution is to wrap
 * the passed-in argument in OT_LIST() before passing to the next macro.
 * Unfortunately this trick requires vararg macros. */
#define OT_LIST(...) __VA_ARGS__


/*
 * Basic Types
 */

#define OT_TAG(a,b,c,d) \
	OT_BYTE(a) OT_BYTE(b) OT_BYTE(c) OT_BYTE(d)

#define OT_OFFSET(From, To) /* Offset from From to To in bytes */ \
	OT_USHORT(OT_DISTANCE(From, To))

#define OT_GLYPHID /* GlyphID */ \
	OT_USHORT

#define OT_UARRAY(Name, Items) \
	OT_LABEL_START(Name) \
	OT_USHORT(OT_COUNT(Name##Data, 2)) \
	OT_LABEL(Name##Data) \
	Items \
	OT_LABEL_END

#define OT_UHEADLESSARRAY(Name, Items) \
	OT_LABEL_START(Name) \
	OT_USHORT(OT_COUNT(Name##Data, 2) + 1) \
	OT_LABEL(Name##Data) \
	Items \
	OT_LABEL_END


/*
 * Common Types
 */

#define OT_LOOKUP_FLAG_IGNORE_MARKS	0x08u

#define OT_LOOKUP(Name, LookupType, LookupFlag, SubLookupOffsets) \
	OT_LABEL_START(Name) \
	OT_USHORT(LookupType) \
	OT_USHORT(LookupFlag) \
	OT_LABEL_END \
	OT_UARRAY(Name##SubLookupOffsetsArray, OT_LIST(SubLookupOffsets))

#define OT_SUBLOOKUP(Name, SubFormat, Items) \
	OT_LABEL_START(Name) \
	OT_USHORT(SubFormat) \
	Items

#define OT_COVERAGE1(Name, Items) \
	OT_LABEL_START(Name) \
	OT_USHORT(1) \
	OT_LABEL_END \
	OT_UARRAY(Name##Glyphs, OT_LIST(Items))


/*
 * GSUB
 */

#define OT_LOOKUP_TYPE_SUBST_SINGLE	1u
#define OT_LOOKUP_TYPE_SUBST_LIGATURE	4u

#define OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(Name, FromGlyphs, ToGlyphs) \
	OT_SUBLOOKUP(Name, 2, \
		OT_OFFSET(Name, Name##Coverage) \
		OT_LABEL_END \
		OT_UARRAY(Name##Substitute, OT_LIST(ToGlyphs)) \
	) \
	OT_COVERAGE1(Name##Coverage, OT_LIST(FromGlyphs)) \
	/* ASSERT_STATIC_EXPR len(FromGlyphs) == len(ToGlyphs) */

#define OT_SUBLOOKUP_LIGATURE_SUBST_FORMAT1(Name, FirstGlyphs, LigatureSetOffsets) \
	OT_SUBLOOKUP(Name, 1, \
		OT_OFFSET(Name, Name##Coverage) \
		OT_LABEL_END \
		OT_UARRAY(Name##LigatureSetOffsetsArray, OT_LIST(LigatureSetOffsets)) \
	) \
	OT_COVERAGE1(Name##Coverage, OT_LIST(FirstGlyphs)) \
	/* ASSERT_STATIC_EXPR len(FirstGlyphs) == len(LigatureSetOffsets) */

#define OT_LIGATURE_SET(Name, LigatureSetOffsets) \
	OT_UARRAY(Name, OT_LIST(LigatureSetOffsets))

#define OT_LIGATURE(Name, Components, LigGlyph) \
	OT_LABEL_START(Name) \
	LigGlyph \
	OT_LABEL_END \
	OT_UHEADLESSARRAY(Name##ComponentsArray, OT_LIST(Components))

/*
 *
 * Start of Windows-1256 shaping table.
 *
 */

/* Table name. */
#define TABLE_NAME arabic_win1256_gsub_lookups

/* Table manifest. */
#define MANIFEST(Items) \
	OT_LABEL_START(manifest) \
	OT_USHORT(OT_COUNT(manifestData, 6)) \
	OT_LABEL(manifestData) \
	Items \
	OT_LABEL_END

#define MANIFEST_LOOKUP(Tag, Name) \
	Tag \
	OT_OFFSET(manifest, Name)

/* Shorthand. */
#define G	OT_GLYPHID

/*
 * Table Start
 */
OT_TABLE_START


/*
 * Manifest
 */
MANIFEST(
	MANIFEST_LOOKUP(OT_TAG('r','l','i','g'), rligLookup)
	MANIFEST_LOOKUP(OT_TAG('i','n','i','t'), initLookup)
	MANIFEST_LOOKUP(OT_TAG('m','e','d','i'), mediLookup)
	MANIFEST_LOOKUP(OT_TAG('f','i','n','a'), finaLookup)
	MANIFEST_LOOKUP(OT_TAG('r','l','i','g'), rligMarksLookup)
)

/*
 * Lookups
 */
OT_LOOKUP(initLookup, OT_LOOKUP_TYPE_SUBST_SINGLE, OT_LOOKUP_FLAG_IGNORE_MARKS,
	OT_OFFSET(initLookup, initmediSubLookup)
	OT_OFFSET(initLookup, initSubLookup)
)
OT_LOOKUP(mediLookup, OT_LOOKUP_TYPE_SUBST_SINGLE, OT_LOOKUP_FLAG_IGNORE_MARKS,
	OT_OFFSET(mediLookup, initmediSubLookup)
	OT_OFFSET(mediLookup, mediSubLookup)
	OT_OFFSET(mediLookup, medifinaLamAlefSubLookup)
)
OT_LOOKUP(finaLookup, OT_LOOKUP_TYPE_SUBST_SINGLE, OT_LOOKUP_FLAG_IGNORE_MARKS,
	OT_OFFSET(finaLookup, finaSubLookup)
	/* We don't need this one currently as the sequence inherits masks
	 * from the first item.  Just in case we change that in the future
	 * to be smart about Arabic masks when ligating... */
	OT_OFFSET(finaLookup, medifinaLamAlefSubLookup)
)
OT_LOOKUP(rligLookup, OT_LOOKUP_TYPE_SUBST_LIGATURE, OT_LOOKUP_FLAG_IGNORE_MARKS,
	OT_OFFSET(rligLookup, lamAlefLigaturesSubLookup)
)
OT_LOOKUP(rligMarksLookup, OT_LOOKUP_TYPE_SUBST_LIGATURE, 0,
	OT_OFFSET(rligMarksLookup, shaddaLigaturesSubLookup)
)

/*
 * init/medi/fina forms
 */
OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(initmediSubLookup,
	G(198)	G(200)	G(201)	G(202)	G(203)	G(204)	G(205)	G(206)	G(211)
	G(212)	G(213)	G(214)	G(223)	G(225)	G(227)	G(228)	G(236)	G(237),
	G(162)	G(4)	G(5)	G(5)	G(6)	G(7)	G(9)	G(11)	G(13)
	G(14)	G(15)	G(26)	G(140)	G(141)	G(142)	G(143)	G(154)	G(154)
)
OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(initSubLookup,
	G(218)	G(219)	G(221)	G(222)	G(229),
	G(27)	G(30)	G(128)	G(131)	G(144)
)
OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(mediSubLookup,
	G(218)	G(219)	G(221)	G(222)	G(229),
	G(28)	G(31)	G(129)	G(138)	G(149)
)
OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(finaSubLookup,
	G(194)	G(195)	G(197)	G(198)	G(199)	G(201)	G(204)	G(205)	G(206)
	G(218)	G(219)	G(229)	G(236)	G(237),
	G(2)	G(1)	G(3)	G(181)	G(0)	G(159)	G(8)	G(10)	G(12)
	G(29)	G(127)	G(152) G(160)	G(156)
)
OT_SUBLOOKUP_SINGLE_SUBST_FORMAT2(medifinaLamAlefSubLookup,
	G(165)	G(178)	G(180)	G(252),
	G(170)	G(179)	G(185)	G(255)
)

/*
 * Lam+Alef ligatures
 */
OT_SUBLOOKUP_LIGATURE_SUBST_FORMAT1(lamAlefLigaturesSubLookup,
	G(225),
	OT_OFFSET(lamAlefLigaturesSubLookup, lamLigatureSet)
)
OT_LIGATURE_SET(lamLigatureSet,
	OT_OFFSET(lamLigatureSet, lamInitLigature1)
	OT_OFFSET(lamLigatureSet, lamInitLigature2)
	OT_OFFSET(lamLigatureSet, lamInitLigature3)
	OT_OFFSET(lamLigatureSet, lamInitLigature4)
)
OT_LIGATURE(lamInitLigature1, G(199), G(165))
OT_LIGATURE(lamInitLigature2, G(195), G(178))
OT_LIGATURE(lamInitLigature3, G(194), G(180))
OT_LIGATURE(lamInitLigature4, G(197), G(252))

/*
 * Shadda ligatures
 */
OT_SUBLOOKUP_LIGATURE_SUBST_FORMAT1(shaddaLigaturesSubLookup,
	G(248),
	OT_OFFSET(shaddaLigaturesSubLookup, shaddaLigatureSet)
)
OT_LIGATURE_SET(shaddaLigatureSet,
	OT_OFFSET(shaddaLigatureSet, shaddaLigature1)
	OT_OFFSET(shaddaLigatureSet, shaddaLigature2)
	OT_OFFSET(shaddaLigatureSet, shaddaLigature3)
)
OT_LIGATURE(shaddaLigature1, G(243), G(172))
OT_LIGATURE(shaddaLigature2, G(245), G(173))
OT_LIGATURE(shaddaLigature3, G(246), G(175))

/*
 * Table end
 */
OT_TABLE_END


/*
 * Clean up
 */
#undef OT_TABLE_START
#undef OT_TABLE_END
#undef OT_LABEL_START
#undef OT_LABEL_END
#undef OT_BYTE
#undef OT_USHORT
#undef OT_DISTANCE
#undef OT_COUNT

/*
 * Include a second time to get the table data...
 */
#if 0
#include "hb-private.hh" /* Make check-includes.sh happy. */
#endif
#ifdef OT_MEASURE
#include "hb-ot-shape-complex-arabic-win1256.hh"
#endif

#define HB_OT_SHAPE_COMPLEX_ARABIC_WIN1256_HH
#endif /* HB_OT_SHAPE_COMPLEX_ARABIC_WIN1256_HH */
