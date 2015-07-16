/*
******************************************************************************
*
*   Copyright (C) 1999-2006, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
******************************************************************************
*   file name:  utf_impl.c
*   encoding:   US-ASCII
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 1999sep13
*   created by: Markus W. Scherer
*
*   This file provides implementation functions for macros in the utfXX.h
*   that would otherwise be too long as macros.
*/

#include "base/third_party/icu/icu_utf.h"

namespace base_icu {

/**
 * UTF8_ERROR_VALUE_1 and UTF8_ERROR_VALUE_2 are special error values for UTF-8,
 * which need 1 or 2 bytes in UTF-8:
 * \code
 * U+0015 = NAK = Negative Acknowledge, C0 control character
 * U+009f = highest C1 control character
 * \endcode
 *
 * These are used by UTF8_..._SAFE macros so that they can return an error value
 * that needs the same number of code units (bytes) as were seen by
 * a macro. They should be tested with UTF_IS_ERROR() or UTF_IS_VALID().
 *
 * @deprecated ICU 2.4. Obsolete, see utf_old.h.
 */
#define CBUTF8_ERROR_VALUE_1 0x15

/**
 * See documentation on UTF8_ERROR_VALUE_1 for details.
 *
 * @deprecated ICU 2.4. Obsolete, see utf_old.h.
 */
#define CBUTF8_ERROR_VALUE_2 0x9f


/**
 * Error value for all UTFs. This code point value will be set by macros with e>
 * checking if an error is detected.
 *
 * @deprecated ICU 2.4. Obsolete, see utf_old.h.
 */
#define CBUTF_ERROR_VALUE 0xffff

/*
 * This table could be replaced on many machines by
 * a few lines of assembler code using an
 * "index of first 0-bit from msb" instruction and
 * one or two more integer instructions.
 *
 * For example, on an i386, do something like
 * - MOV AL, leadByte
 * - NOT AL         (8-bit, leave b15..b8==0..0, reverse only b7..b0)
 * - MOV AH, 0
 * - BSR BX, AX     (16-bit)
 * - MOV AX, 6      (result)
 * - JZ finish      (ZF==1 if leadByte==0xff)
 * - SUB AX, BX (result)
 * -finish:
 * (BSR: Bit Scan Reverse, scans for a 1-bit, starting from the MSB)
 *
 * In Unicode, all UTF-8 byte sequences with more than 4 bytes are illegal;
 * lead bytes above 0xf4 are illegal.
 * We keep them in this table for skipping long ISO 10646-UTF-8 sequences.
 */
const uint8
utf8_countTrailBytes[256]={
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,

    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,

    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3,
    3, 3, 3,    /* illegal in Unicode */
    4, 4, 4, 4, /* illegal in Unicode */
    5, 5,       /* illegal in Unicode */
    0, 0        /* illegal bytes 0xfe and 0xff */
};

static const UChar32
utf8_minLegal[4]={ 0, 0x80, 0x800, 0x10000 };

static const UChar32
utf8_errorValue[6]={
    CBUTF8_ERROR_VALUE_1, CBUTF8_ERROR_VALUE_2, CBUTF_ERROR_VALUE, 0x10ffff,
    0x3ffffff, 0x7fffffff
};

/*
 * Handle the non-inline part of the U8_NEXT() macro and its obsolete sibling
 * UTF8_NEXT_CHAR_SAFE().
 *
 * The "strict" parameter controls the error behavior:
 * <0  "Safe" behavior of U8_NEXT(): All illegal byte sequences yield a negative
 *     code point result.
 *  0  Obsolete "safe" behavior of UTF8_NEXT_CHAR_SAFE(..., FALSE):
 *     All illegal byte sequences yield a positive code point such that this
 *     result code point would be encoded with the same number of bytes as
 *     the illegal sequence.
 * >0  Obsolete "strict" behavior of UTF8_NEXT_CHAR_SAFE(..., TRUE):
 *     Same as the obsolete "safe" behavior, but non-characters are also treated
 *     like illegal sequences.
 *
 * The special negative (<0) value -2 is used for lenient treatment of surrogate
 * code points as legal. Some implementations use this for roundtripping of
 * Unicode 16-bit strings that are not well-formed UTF-16, that is, they
 * contain unpaired surrogates.
 *
 * Note that a UBool is the same as an int8_t.
 */
UChar32
utf8_nextCharSafeBody(const uint8 *s, int32 *pi, int32 length, UChar32 c, UBool strict) {
    int32 i=*pi;
    uint8 count=CBU8_COUNT_TRAIL_BYTES(c);
    if((i)+count<=(length)) {
        uint8 trail, illegal=0;

        CBU8_MASK_LEAD_BYTE((c), count);
        /* count==0 for illegally leading trail bytes and the illegal bytes 0xfe and 0xff */
        switch(count) {
        /* each branch falls through to the next one */
        case 5:
        case 4:
            /* count>=4 is always illegal: no more than 3 trail bytes in Unicode's UTF-8 */
            illegal=1;
            break;
        case 3:
            trail=s[(i)++];
            (c)=((c)<<6)|(trail&0x3f);
            if(c<0x110) {
                illegal|=(trail&0xc0)^0x80;
            } else {
                /* code point>0x10ffff, outside Unicode */
                illegal=1;
                break;
            }
        case 2:
            trail=s[(i)++];
            (c)=((c)<<6)|(trail&0x3f);
            illegal|=(trail&0xc0)^0x80;
        case 1:
            trail=s[(i)++];
            (c)=((c)<<6)|(trail&0x3f);
            illegal|=(trail&0xc0)^0x80;
            break;
        case 0:
            if(strict>=0) {
                return CBUTF8_ERROR_VALUE_1;
            } else {
                return CBU_SENTINEL;
            }
        /* no default branch to optimize switch()  - all values are covered */
        }

        /*
         * All the error handling should return a value
         * that needs count bytes so that UTF8_GET_CHAR_SAFE() works right.
         *
         * Starting with Unicode 3.0.1, non-shortest forms are illegal.
         * Starting with Unicode 3.2, surrogate code points must not be
         * encoded in UTF-8, and there are no irregular sequences any more.
         *
         * U8_ macros (new in ICU 2.4) return negative values for error conditions.
         */

        /* correct sequence - all trail bytes have (b7..b6)==(10)? */
        /* illegal is also set if count>=4 */
        if(illegal || (c)<utf8_minLegal[count] || (CBU_IS_SURROGATE(c) && strict!=-2)) {
            /* error handling */
            uint8 errorCount=count;
            /* don't go beyond this sequence */
            i=*pi;
            while(count>0 && CBU8_IS_TRAIL(s[i])) {
                ++(i);
                --count;
            }
            if(strict>=0) {
                c=utf8_errorValue[errorCount-count];
            } else {
                c=CBU_SENTINEL;
            }
        } else if((strict)>0 && CBU_IS_UNICODE_NONCHAR(c)) {
            /* strict: forbid non-characters like U+fffe */
            c=utf8_errorValue[count];
        }
    } else /* too few bytes left */ {
        /* error handling */
        int32 i0=i;
        /* don't just set (i)=(length) in case there is an illegal sequence */
        while((i)<(length) && CBU8_IS_TRAIL(s[i])) {
            ++(i);
        }
        if(strict>=0) {
            c=utf8_errorValue[i-i0];
        } else {
            c=CBU_SENTINEL;
        }
    }
    *pi=i;
    return c;
}

}  // namespace base_icu
