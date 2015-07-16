/*
*******************************************************************************
*
*   Copyright (C) 1999-2004, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
*******************************************************************************
*   file name:  utf.h
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 1999sep09
*   created by: Markus W. Scherer
*/

#ifndef BASE_THIRD_PARTY_ICU_ICU_UTF_H_
#define BASE_THIRD_PARTY_ICU_ICU_UTF_H_

#include "base/basictypes.h"

namespace base_icu {

typedef int32 UChar32;
typedef uint16 UChar;
typedef int8 UBool;

// General ---------------------------------------------------------------------
// from utf.h

/**
 * This value is intended for sentinel values for APIs that
 * (take or) return single code points (UChar32).
 * It is outside of the Unicode code point range 0..0x10ffff.
 *
 * For example, a "done" or "error" value in a new API
 * could be indicated with CBU_SENTINEL.
 *
 * ICU APIs designed before ICU 2.4 usually define service-specific "done"
 * values, mostly 0xffff.
 * Those may need to be distinguished from
 * actual U+ffff text contents by calling functions like
 * CharacterIterator::hasNext() or UnicodeString::length().
 *
 * @return -1
 * @see UChar32
 * @stable ICU 2.4
 */
#define CBU_SENTINEL (-1)

/**
 * Is this code point a Unicode noncharacter?
 * @param c 32-bit code point
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU_IS_UNICODE_NONCHAR(c) \
    ((c)>=0xfdd0 && \
     ((uint32)(c)<=0xfdef || ((c)&0xfffe)==0xfffe) && \
     (uint32)(c)<=0x10ffff)

/**
 * Is c a Unicode code point value (0..U+10ffff)
 * that can be assigned a character?
 *
 * Code points that are not characters include:
 * - single surrogate code points (U+d800..U+dfff, 2048 code points)
 * - the last two code points on each plane (U+__fffe and U+__ffff, 34 code points)
 * - U+fdd0..U+fdef (new with Unicode 3.1, 32 code points)
 * - the highest Unicode code point value is U+10ffff
 *
 * This means that all code points below U+d800 are character code points,
 * and that boundary is tested first for performance.
 *
 * @param c 32-bit code point
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU_IS_UNICODE_CHAR(c) \
    ((uint32)(c)<0xd800 || \
        ((uint32)(c)>0xdfff && \
         (uint32)(c)<=0x10ffff && \
         !CBU_IS_UNICODE_NONCHAR(c)))

/**
 * Is this code point a surrogate (U+d800..U+dfff)?
 * @param c 32-bit code point
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU_IS_SURROGATE(c) (((c)&0xfffff800)==0xd800)

/**
 * Assuming c is a surrogate code point (U_IS_SURROGATE(c)),
 * is it a lead surrogate?
 * @param c 32-bit code point
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU_IS_SURROGATE_LEAD(c) (((c)&0x400)==0)


// UTF-8 macros ----------------------------------------------------------------
// from utf8.h

extern const uint8 utf8_countTrailBytes[256];

/**
 * Count the trail bytes for a UTF-8 lead byte.
 * @internal
 */
#define CBU8_COUNT_TRAIL_BYTES(leadByte) (base_icu::utf8_countTrailBytes[(uint8)leadByte])

/**
 * Mask a UTF-8 lead byte, leave only the lower bits that form part of the code point value.
 * @internal
 */
#define CBU8_MASK_LEAD_BYTE(leadByte, countTrailBytes) ((leadByte)&=(1<<(6-(countTrailBytes)))-1)

/**
 * Does this code unit (byte) encode a code point by itself (US-ASCII 0..0x7f)?
 * @param c 8-bit code unit (byte)
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU8_IS_SINGLE(c) (((c)&0x80)==0)

/**
 * Is this code unit (byte) a UTF-8 lead byte?
 * @param c 8-bit code unit (byte)
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU8_IS_LEAD(c) ((uint8)((c)-0xc0)<0x3e)

/**
 * Is this code unit (byte) a UTF-8 trail byte?
 * @param c 8-bit code unit (byte)
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU8_IS_TRAIL(c) (((c)&0xc0)==0x80)

/**
 * How many code units (bytes) are used for the UTF-8 encoding
 * of this Unicode code point?
 * @param c 32-bit code point
 * @return 1..4, or 0 if c is a surrogate or not a Unicode code point
 * @stable ICU 2.4
 */
#define CBU8_LENGTH(c) \
    ((uint32)(c)<=0x7f ? 1 : \
        ((uint32)(c)<=0x7ff ? 2 : \
            ((uint32)(c)<=0xd7ff ? 3 : \
                ((uint32)(c)<=0xdfff || (uint32)(c)>0x10ffff ? 0 : \
                    ((uint32)(c)<=0xffff ? 3 : 4)\
                ) \
            ) \
        ) \
    )

/**
 * The maximum number of UTF-8 code units (bytes) per Unicode code point (U+0000..U+10ffff).
 * @return 4
 * @stable ICU 2.4
 */
#define CBU8_MAX_LENGTH 4

/**
 * Function for handling "next code point" with error-checking.
 * @internal
 */
UChar32 utf8_nextCharSafeBody(const uint8 *s, int32 *pi, int32 length, UChar32 c, UBool strict);

/**
 * Get a code point from a string at a code point boundary offset,
 * and advance the offset to the next code point boundary.
 * (Post-incrementing forward iteration.)
 * "Safe" macro, checks for illegal sequences and for string boundaries.
 *
 * The offset may point to the lead byte of a multi-byte sequence,
 * in which case the macro will read the whole sequence.
 * If the offset points to a trail byte or an illegal UTF-8 sequence, then
 * c is set to a negative value.
 *
 * @param s const uint8 * string
 * @param i string offset, i<length
 * @param length string length
 * @param c output UChar32 variable, set to <0 in case of an error
 * @see CBU8_NEXT_UNSAFE
 * @stable ICU 2.4
 */
#define CBU8_NEXT(s, i, length, c) { \
    (c)=(s)[(i)++]; \
    if(((uint8)(c))>=0x80) { \
        if(CBU8_IS_LEAD(c)) { \
            (c)=base_icu::utf8_nextCharSafeBody((const uint8 *)s, &(i), (int32)(length), c, -1); \
        } else { \
            (c)=CBU_SENTINEL; \
        } \
    } \
}

/**
 * Append a code point to a string, overwriting 1 to 4 bytes.
 * The offset points to the current end of the string contents
 * and is advanced (post-increment).
 * "Unsafe" macro, assumes a valid code point and sufficient space in the string.
 * Otherwise, the result is undefined.
 *
 * @param s const uint8 * string buffer
 * @param i string offset
 * @param c code point to append
 * @see CBU8_APPEND
 * @stable ICU 2.4
 */
#define CBU8_APPEND_UNSAFE(s, i, c) { \
    if((uint32)(c)<=0x7f) { \
        (s)[(i)++]=(uint8)(c); \
    } else { \
        if((uint32)(c)<=0x7ff) { \
            (s)[(i)++]=(uint8)(((c)>>6)|0xc0); \
        } else { \
            if((uint32)(c)<=0xffff) { \
                (s)[(i)++]=(uint8)(((c)>>12)|0xe0); \
            } else { \
                (s)[(i)++]=(uint8)(((c)>>18)|0xf0); \
                (s)[(i)++]=(uint8)((((c)>>12)&0x3f)|0x80); \
            } \
            (s)[(i)++]=(uint8)((((c)>>6)&0x3f)|0x80); \
        } \
        (s)[(i)++]=(uint8)(((c)&0x3f)|0x80); \
    } \
}

// UTF-16 macros ---------------------------------------------------------------
// from utf16.h

/**
 * Does this code unit alone encode a code point (BMP, not a surrogate)?
 * @param c 16-bit code unit
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU16_IS_SINGLE(c) !CBU_IS_SURROGATE(c)

/**
 * Is this code unit a lead surrogate (U+d800..U+dbff)?
 * @param c 16-bit code unit
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU16_IS_LEAD(c) (((c)&0xfffffc00)==0xd800)

/**
 * Is this code unit a trail surrogate (U+dc00..U+dfff)?
 * @param c 16-bit code unit
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU16_IS_TRAIL(c) (((c)&0xfffffc00)==0xdc00)

/**
 * Is this code unit a surrogate (U+d800..U+dfff)?
 * @param c 16-bit code unit
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU16_IS_SURROGATE(c) CBU_IS_SURROGATE(c)

/**
 * Assuming c is a surrogate code point (U16_IS_SURROGATE(c)),
 * is it a lead surrogate?
 * @param c 16-bit code unit
 * @return TRUE or FALSE
 * @stable ICU 2.4
 */
#define CBU16_IS_SURROGATE_LEAD(c) (((c)&0x400)==0)

/**
 * Helper constant for CBU16_GET_SUPPLEMENTARY.
 * @internal
 */
#define CBU16_SURROGATE_OFFSET ((0xd800<<10UL)+0xdc00-0x10000)

/**
 * Get a supplementary code point value (U+10000..U+10ffff)
 * from its lead and trail surrogates.
 * The result is undefined if the input values are not
 * lead and trail surrogates.
 *
 * @param lead lead surrogate (U+d800..U+dbff)
 * @param trail trail surrogate (U+dc00..U+dfff)
 * @return supplementary code point (U+10000..U+10ffff)
 * @stable ICU 2.4
 */
#define CBU16_GET_SUPPLEMENTARY(lead, trail) \
    (((base_icu::UChar32)(lead)<<10UL)+(base_icu::UChar32)(trail)-CBU16_SURROGATE_OFFSET)


/**
 * Get the lead surrogate (0xd800..0xdbff) for a
 * supplementary code point (0x10000..0x10ffff).
 * @param supplementary 32-bit code point (U+10000..U+10ffff)
 * @return lead surrogate (U+d800..U+dbff) for supplementary
 * @stable ICU 2.4
 */
#define CBU16_LEAD(supplementary) \
    (base_icu::UChar)(((supplementary)>>10)+0xd7c0)

/**
 * Get the trail surrogate (0xdc00..0xdfff) for a
 * supplementary code point (0x10000..0x10ffff).
 * @param supplementary 32-bit code point (U+10000..U+10ffff)
 * @return trail surrogate (U+dc00..U+dfff) for supplementary
 * @stable ICU 2.4
 */
#define CBU16_TRAIL(supplementary) \
    (base_icu::UChar)(((supplementary)&0x3ff)|0xdc00)

/**
 * How many 16-bit code units are used to encode this Unicode code point? (1 or 2)
 * The result is not defined if c is not a Unicode code point (U+0000..U+10ffff).
 * @param c 32-bit code point
 * @return 1 or 2
 * @stable ICU 2.4
 */
#define CBU16_LENGTH(c) ((uint32)(c)<=0xffff ? 1 : 2)

/**
 * The maximum number of 16-bit code units per Unicode code point (U+0000..U+10ffff).
 * @return 2
 * @stable ICU 2.4
 */
#define CBU16_MAX_LENGTH 2

/**
 * Get a code point from a string at a code point boundary offset,
 * and advance the offset to the next code point boundary.
 * (Post-incrementing forward iteration.)
 * "Safe" macro, handles unpaired surrogates and checks for string boundaries.
 *
 * The offset may point to the lead surrogate unit
 * for a supplementary code point, in which case the macro will read
 * the following trail surrogate as well.
 * If the offset points to a trail surrogate or
 * to a single, unpaired lead surrogate, then that itself
 * will be returned as the code point.
 *
 * @param s const UChar * string
 * @param i string offset, i<length
 * @param length string length
 * @param c output UChar32 variable
 * @stable ICU 2.4
 */
#define CBU16_NEXT(s, i, length, c) { \
    (c)=(s)[(i)++]; \
    if(CBU16_IS_LEAD(c)) { \
        uint16 __c2; \
        if((i)<(length) && CBU16_IS_TRAIL(__c2=(s)[(i)])) { \
            ++(i); \
            (c)=CBU16_GET_SUPPLEMENTARY((c), __c2); \
        } \
    } \
}

/**
 * Append a code point to a string, overwriting 1 or 2 code units.
 * The offset points to the current end of the string contents
 * and is advanced (post-increment).
 * "Unsafe" macro, assumes a valid code point and sufficient space in the string.
 * Otherwise, the result is undefined.
 *
 * @param s const UChar * string buffer
 * @param i string offset
 * @param c code point to append
 * @see CBU16_APPEND
 * @stable ICU 2.4
 */
#define CBU16_APPEND_UNSAFE(s, i, c) { \
    if((uint32)(c)<=0xffff) { \
        (s)[(i)++]=(uint16)(c); \
    } else { \
        (s)[(i)++]=(uint16)(((c)>>10)+0xd7c0); \
        (s)[(i)++]=(uint16)(((c)&0x3ff)|0xdc00); \
    } \
}

}  // namesapce base_icu

#endif  // BASE_THIRD_PARTY_ICU_ICU_UTF_H_
