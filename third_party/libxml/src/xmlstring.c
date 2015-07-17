/*
 * string.c : an XML string utilities module
 *
 * This module provides various utility functions for manipulating
 * the xmlChar* type. All functions named xmlStr* have been moved here
 * from the parser.c file (their original home).
 *
 * See Copyright for the status of this software.
 *
 * UTF8 string routines from:
 * William Brack <wbrack@mmm.com.hk>
 *
 * daniel@veillard.com
 */

#define IN_LIBXML
#include "libxml.h"

#include <stdlib.h>
#include <string.h>
#include <libxml/xmlmemory.h>
#include <libxml/parserInternals.h>
#include <libxml/xmlstring.h>

/************************************************************************
 *                                                                      *
 *                Commodity functions to handle xmlChars                *
 *                                                                      *
 ************************************************************************/

/**
 * xmlStrndup:
 * @cur:  the input xmlChar *
 * @len:  the len of @cur
 *
 * a strndup for array of xmlChar's
 *
 * Returns a new xmlChar * or NULL
 */
xmlChar *
xmlStrndup(const xmlChar *cur, int len) {
    xmlChar *ret;

    if ((cur == NULL) || (len < 0)) return(NULL);
    ret = (xmlChar *) xmlMallocAtomic((len + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlErrMemory(NULL, NULL);
        return(NULL);
    }
    memcpy(ret, cur, len * sizeof(xmlChar));
    ret[len] = 0;
    return(ret);
}

/**
 * xmlStrdup:
 * @cur:  the input xmlChar *
 *
 * a strdup for array of xmlChar's. Since they are supposed to be
 * encoded in UTF-8 or an encoding with 8bit based chars, we assume
 * a termination mark of '0'.
 *
 * Returns a new xmlChar * or NULL
 */
xmlChar *
xmlStrdup(const xmlChar *cur) {
    const xmlChar *p = cur;

    if (cur == NULL) return(NULL);
    while (*p != 0) p++; /* non input consuming */
    return(xmlStrndup(cur, p - cur));
}

/**
 * xmlCharStrndup:
 * @cur:  the input char *
 * @len:  the len of @cur
 *
 * a strndup for char's to xmlChar's
 *
 * Returns a new xmlChar * or NULL
 */

xmlChar *
xmlCharStrndup(const char *cur, int len) {
    int i;
    xmlChar *ret;

    if ((cur == NULL) || (len < 0)) return(NULL);
    ret = (xmlChar *) xmlMallocAtomic((len + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlErrMemory(NULL, NULL);
        return(NULL);
    }
    for (i = 0;i < len;i++) {
        ret[i] = (xmlChar) cur[i];
        if (ret[i] == 0) return(ret);
    }
    ret[len] = 0;
    return(ret);
}

/**
 * xmlCharStrdup:
 * @cur:  the input char *
 *
 * a strdup for char's to xmlChar's
 *
 * Returns a new xmlChar * or NULL
 */

xmlChar *
xmlCharStrdup(const char *cur) {
    const char *p = cur;

    if (cur == NULL) return(NULL);
    while (*p != '\0') p++; /* non input consuming */
    return(xmlCharStrndup(cur, p - cur));
}

/**
 * xmlStrcmp:
 * @str1:  the first xmlChar *
 * @str2:  the second xmlChar *
 *
 * a strcmp for xmlChar's
 *
 * Returns the integer result of the comparison
 */

int
xmlStrcmp(const xmlChar *str1, const xmlChar *str2) {
    register int tmp;

    if (str1 == str2) return(0);
    if (str1 == NULL) return(-1);
    if (str2 == NULL) return(1);
    do {
        tmp = *str1++ - *str2;
        if (tmp != 0) return(tmp);
    } while (*str2++ != 0);
    return 0;
}

/**
 * xmlStrEqual:
 * @str1:  the first xmlChar *
 * @str2:  the second xmlChar *
 *
 * Check if both strings are equal of have same content.
 * Should be a bit more readable and faster than xmlStrcmp()
 *
 * Returns 1 if they are equal, 0 if they are different
 */

int
xmlStrEqual(const xmlChar *str1, const xmlChar *str2) {
    if (str1 == str2) return(1);
    if (str1 == NULL) return(0);
    if (str2 == NULL) return(0);
    do {
        if (*str1++ != *str2) return(0);
    } while (*str2++);
    return(1);
}

/**
 * xmlStrQEqual:
 * @pref:  the prefix of the QName
 * @name:  the localname of the QName
 * @str:  the second xmlChar *
 *
 * Check if a QName is Equal to a given string
 *
 * Returns 1 if they are equal, 0 if they are different
 */

int
xmlStrQEqual(const xmlChar *pref, const xmlChar *name, const xmlChar *str) {
    if (pref == NULL) return(xmlStrEqual(name, str));
    if (name == NULL) return(0);
    if (str == NULL) return(0);

    do {
        if (*pref++ != *str) return(0);
    } while ((*str++) && (*pref));
    if (*str++ != ':') return(0);
    do {
        if (*name++ != *str) return(0);
    } while (*str++);
    return(1);
}

/**
 * xmlStrncmp:
 * @str1:  the first xmlChar *
 * @str2:  the second xmlChar *
 * @len:  the max comparison length
 *
 * a strncmp for xmlChar's
 *
 * Returns the integer result of the comparison
 */

int
xmlStrncmp(const xmlChar *str1, const xmlChar *str2, int len) {
    register int tmp;

    if (len <= 0) return(0);
    if (str1 == str2) return(0);
    if (str1 == NULL) return(-1);
    if (str2 == NULL) return(1);
#ifdef __GNUC__
    tmp = strncmp((const char *)str1, (const char *)str2, len);
    return tmp;
#else
    do {
        tmp = *str1++ - *str2;
        if (tmp != 0 || --len == 0) return(tmp);
    } while (*str2++ != 0);
    return 0;
#endif
}

static const xmlChar casemap[256] = {
    0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
    0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,
    0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,
    0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,
    0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,
    0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,
    0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,
    0x38,0x39,0x3A,0x3B,0x3C,0x3D,0x3E,0x3F,
    0x40,0x61,0x62,0x63,0x64,0x65,0x66,0x67,
    0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,
    0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,
    0x78,0x79,0x7A,0x7B,0x5C,0x5D,0x5E,0x5F,
    0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,
    0x68,0x69,0x6A,0x6B,0x6C,0x6D,0x6E,0x6F,
    0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,
    0x78,0x79,0x7A,0x7B,0x7C,0x7D,0x7E,0x7F,
    0x80,0x81,0x82,0x83,0x84,0x85,0x86,0x87,
    0x88,0x89,0x8A,0x8B,0x8C,0x8D,0x8E,0x8F,
    0x90,0x91,0x92,0x93,0x94,0x95,0x96,0x97,
    0x98,0x99,0x9A,0x9B,0x9C,0x9D,0x9E,0x9F,
    0xA0,0xA1,0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,
    0xA8,0xA9,0xAA,0xAB,0xAC,0xAD,0xAE,0xAF,
    0xB0,0xB1,0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,
    0xB8,0xB9,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF,
    0xC0,0xC1,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,
    0xC8,0xC9,0xCA,0xCB,0xCC,0xCD,0xCE,0xCF,
    0xD0,0xD1,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,
    0xD8,0xD9,0xDA,0xDB,0xDC,0xDD,0xDE,0xDF,
    0xE0,0xE1,0xE2,0xE3,0xE4,0xE5,0xE6,0xE7,
    0xE8,0xE9,0xEA,0xEB,0xEC,0xED,0xEE,0xEF,
    0xF0,0xF1,0xF2,0xF3,0xF4,0xF5,0xF6,0xF7,
    0xF8,0xF9,0xFA,0xFB,0xFC,0xFD,0xFE,0xFF
};

/**
 * xmlStrcasecmp:
 * @str1:  the first xmlChar *
 * @str2:  the second xmlChar *
 *
 * a strcasecmp for xmlChar's
 *
 * Returns the integer result of the comparison
 */

int
xmlStrcasecmp(const xmlChar *str1, const xmlChar *str2) {
    register int tmp;

    if (str1 == str2) return(0);
    if (str1 == NULL) return(-1);
    if (str2 == NULL) return(1);
    do {
        tmp = casemap[*str1++] - casemap[*str2];
        if (tmp != 0) return(tmp);
    } while (*str2++ != 0);
    return 0;
}

/**
 * xmlStrncasecmp:
 * @str1:  the first xmlChar *
 * @str2:  the second xmlChar *
 * @len:  the max comparison length
 *
 * a strncasecmp for xmlChar's
 *
 * Returns the integer result of the comparison
 */

int
xmlStrncasecmp(const xmlChar *str1, const xmlChar *str2, int len) {
    register int tmp;

    if (len <= 0) return(0);
    if (str1 == str2) return(0);
    if (str1 == NULL) return(-1);
    if (str2 == NULL) return(1);
    do {
        tmp = casemap[*str1++] - casemap[*str2];
        if (tmp != 0 || --len == 0) return(tmp);
    } while (*str2++ != 0);
    return 0;
}

/**
 * xmlStrchr:
 * @str:  the xmlChar * array
 * @val:  the xmlChar to search
 *
 * a strchr for xmlChar's
 *
 * Returns the xmlChar * for the first occurrence or NULL.
 */

const xmlChar *
xmlStrchr(const xmlChar *str, xmlChar val) {
    if (str == NULL) return(NULL);
    while (*str != 0) { /* non input consuming */
        if (*str == val) return((xmlChar *) str);
        str++;
    }
    return(NULL);
}

/**
 * xmlStrstr:
 * @str:  the xmlChar * array (haystack)
 * @val:  the xmlChar to search (needle)
 *
 * a strstr for xmlChar's
 *
 * Returns the xmlChar * for the first occurrence or NULL.
 */

const xmlChar *
xmlStrstr(const xmlChar *str, const xmlChar *val) {
    int n;

    if (str == NULL) return(NULL);
    if (val == NULL) return(NULL);
    n = xmlStrlen(val);

    if (n == 0) return(str);
    while (*str != 0) { /* non input consuming */
        if (*str == *val) {
            if (!xmlStrncmp(str, val, n)) return((const xmlChar *) str);
        }
        str++;
    }
    return(NULL);
}

/**
 * xmlStrcasestr:
 * @str:  the xmlChar * array (haystack)
 * @val:  the xmlChar to search (needle)
 *
 * a case-ignoring strstr for xmlChar's
 *
 * Returns the xmlChar * for the first occurrence or NULL.
 */

const xmlChar *
xmlStrcasestr(const xmlChar *str, const xmlChar *val) {
    int n;

    if (str == NULL) return(NULL);
    if (val == NULL) return(NULL);
    n = xmlStrlen(val);

    if (n == 0) return(str);
    while (*str != 0) { /* non input consuming */
        if (casemap[*str] == casemap[*val])
            if (!xmlStrncasecmp(str, val, n)) return(str);
        str++;
    }
    return(NULL);
}

/**
 * xmlStrsub:
 * @str:  the xmlChar * array (haystack)
 * @start:  the index of the first char (zero based)
 * @len:  the length of the substring
 *
 * Extract a substring of a given string
 *
 * Returns the xmlChar * for the first occurrence or NULL.
 */

xmlChar *
xmlStrsub(const xmlChar *str, int start, int len) {
    int i;

    if (str == NULL) return(NULL);
    if (start < 0) return(NULL);
    if (len < 0) return(NULL);

    for (i = 0;i < start;i++) {
        if (*str == 0) return(NULL);
        str++;
    }
    if (*str == 0) return(NULL);
    return(xmlStrndup(str, len));
}

/**
 * xmlStrlen:
 * @str:  the xmlChar * array
 *
 * length of a xmlChar's string
 *
 * Returns the number of xmlChar contained in the ARRAY.
 */

int
xmlStrlen(const xmlChar *str) {
    int len = 0;

    if (str == NULL) return(0);
    while (*str != 0) { /* non input consuming */
        str++;
        len++;
    }
    return(len);
}

/**
 * xmlStrncat:
 * @cur:  the original xmlChar * array
 * @add:  the xmlChar * array added
 * @len:  the length of @add
 *
 * a strncat for array of xmlChar's, it will extend @cur with the len
 * first bytes of @add. Note that if @len < 0 then this is an API error
 * and NULL will be returned.
 *
 * Returns a new xmlChar *, the original @cur is reallocated if needed
 * and should not be freed
 */

xmlChar *
xmlStrncat(xmlChar *cur, const xmlChar *add, int len) {
    int size;
    xmlChar *ret;

    if ((add == NULL) || (len == 0))
        return(cur);
    if (len < 0)
	return(NULL);
    if (cur == NULL)
        return(xmlStrndup(add, len));

    size = xmlStrlen(cur);
    ret = (xmlChar *) xmlRealloc(cur, (size + len + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlErrMemory(NULL, NULL);
        return(cur);
    }
    memcpy(&ret[size], add, len * sizeof(xmlChar));
    ret[size + len] = 0;
    return(ret);
}

/**
 * xmlStrncatNew:
 * @str1:  first xmlChar string
 * @str2:  second xmlChar string
 * @len:  the len of @str2 or < 0
 *
 * same as xmlStrncat, but creates a new string.  The original
 * two strings are not freed. If @len is < 0 then the length
 * will be calculated automatically.
 *
 * Returns a new xmlChar * or NULL
 */
xmlChar *
xmlStrncatNew(const xmlChar *str1, const xmlChar *str2, int len) {
    int size;
    xmlChar *ret;

    if (len < 0)
        len = xmlStrlen(str2);
    if ((str2 == NULL) || (len == 0))
        return(xmlStrdup(str1));
    if (str1 == NULL)
        return(xmlStrndup(str2, len));

    size = xmlStrlen(str1);
    ret = (xmlChar *) xmlMalloc((size + len + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlErrMemory(NULL, NULL);
        return(xmlStrndup(str1, size));
    }
    memcpy(ret, str1, size * sizeof(xmlChar));
    memcpy(&ret[size], str2, len * sizeof(xmlChar));
    ret[size + len] = 0;
    return(ret);
}

/**
 * xmlStrcat:
 * @cur:  the original xmlChar * array
 * @add:  the xmlChar * array added
 *
 * a strcat for array of xmlChar's. Since they are supposed to be
 * encoded in UTF-8 or an encoding with 8bit based chars, we assume
 * a termination mark of '0'.
 *
 * Returns a new xmlChar * containing the concatenated string.
 */
xmlChar *
xmlStrcat(xmlChar *cur, const xmlChar *add) {
    const xmlChar *p = add;

    if (add == NULL) return(cur);
    if (cur == NULL)
        return(xmlStrdup(add));

    while (*p != 0) p++; /* non input consuming */
    return(xmlStrncat(cur, add, p - add));
}

/**
 * xmlStrPrintf:
 * @buf:   the result buffer.
 * @len:   the result buffer length.
 * @msg:   the message with printf formatting.
 * @...:   extra parameters for the message.
 *
 * Formats @msg and places result into @buf.
 *
 * Returns the number of characters written to @buf or -1 if an error occurs.
 */
int XMLCDECL
xmlStrPrintf(xmlChar *buf, int len, const xmlChar *msg, ...) {
    va_list args;
    int ret;

    if((buf == NULL) || (msg == NULL)) {
        return(-1);
    }

    va_start(args, msg);
    ret = vsnprintf((char *) buf, len, (const char *) msg, args);
    va_end(args);
    buf[len - 1] = 0; /* be safe ! */

    return(ret);
}

/**
 * xmlStrVPrintf:
 * @buf:   the result buffer.
 * @len:   the result buffer length.
 * @msg:   the message with printf formatting.
 * @ap:    extra parameters for the message.
 *
 * Formats @msg and places result into @buf.
 *
 * Returns the number of characters written to @buf or -1 if an error occurs.
 */
int
xmlStrVPrintf(xmlChar *buf, int len, const xmlChar *msg, va_list ap) {
    int ret;

    if((buf == NULL) || (msg == NULL)) {
        return(-1);
    }

    ret = vsnprintf((char *) buf, len, (const char *) msg, ap);
    buf[len - 1] = 0; /* be safe ! */

    return(ret);
}

/************************************************************************
 *                                                                      *
 *              Generic UTF8 handling routines                          *
 *                                                                      *
 * From rfc2044: encoding of the Unicode values on UTF-8:               *
 *                                                                      *
 * UCS-4 range (hex.)           UTF-8 octet sequence (binary)           *
 * 0000 0000-0000 007F   0xxxxxxx                                       *
 * 0000 0080-0000 07FF   110xxxxx 10xxxxxx                              *
 * 0000 0800-0000 FFFF   1110xxxx 10xxxxxx 10xxxxxx                     *
 *                                                                      *
 * I hope we won't use values > 0xFFFF anytime soon !                   *
 *                                                                      *
 ************************************************************************/


/**
 * xmlUTF8Size:
 * @utf: pointer to the UTF8 character
 *
 * calculates the internal size of a UTF8 character
 *
 * returns the numbers of bytes in the character, -1 on format error
 */
int
xmlUTF8Size(const xmlChar *utf) {
    xmlChar mask;
    int len;

    if (utf == NULL)
        return -1;
    if (*utf < 0x80)
        return 1;
    /* check valid UTF8 character */
    if (!(*utf & 0x40))
        return -1;
    /* determine number of bytes in char */
    len = 2;
    for (mask=0x20; mask != 0; mask>>=1) {
        if (!(*utf & mask))
            return len;
        len++;
    }
    return -1;
}

/**
 * xmlUTF8Charcmp:
 * @utf1: pointer to first UTF8 char
 * @utf2: pointer to second UTF8 char
 *
 * compares the two UCS4 values
 *
 * returns result of the compare as with xmlStrncmp
 */
int
xmlUTF8Charcmp(const xmlChar *utf1, const xmlChar *utf2) {

    if (utf1 == NULL ) {
        if (utf2 == NULL)
            return 0;
        return -1;
    }
    return xmlStrncmp(utf1, utf2, xmlUTF8Size(utf1));
}

/**
 * xmlUTF8Strlen:
 * @utf:  a sequence of UTF-8 encoded bytes
 *
 * compute the length of an UTF8 string, it doesn't do a full UTF8
 * checking of the content of the string.
 *
 * Returns the number of characters in the string or -1 in case of error
 */
int
xmlUTF8Strlen(const xmlChar *utf) {
    int ret = 0;

    if (utf == NULL)
        return(-1);

    while (*utf != 0) {
        if (utf[0] & 0x80) {
            if ((utf[1] & 0xc0) != 0x80)
                return(-1);
            if ((utf[0] & 0xe0) == 0xe0) {
                if ((utf[2] & 0xc0) != 0x80)
                    return(-1);
                if ((utf[0] & 0xf0) == 0xf0) {
                    if ((utf[0] & 0xf8) != 0xf0 || (utf[3] & 0xc0) != 0x80)
                        return(-1);
                    utf += 4;
                } else {
                    utf += 3;
                }
            } else {
                utf += 2;
            }
        } else {
            utf++;
        }
        ret++;
    }
    return(ret);
}

/**
 * xmlGetUTF8Char:
 * @utf:  a sequence of UTF-8 encoded bytes
 * @len:  a pointer to the minimum number of bytes present in
 *        the sequence.  This is used to assure the next character
 *        is completely contained within the sequence.
 *
 * Read the first UTF8 character from @utf
 *
 * Returns the char value or -1 in case of error, and sets *len to
 *        the actual number of bytes consumed (0 in case of error)
 */
int
xmlGetUTF8Char(const unsigned char *utf, int *len) {
    unsigned int c;

    if (utf == NULL)
        goto error;
    if (len == NULL)
        goto error;
    if (*len < 1)
        goto error;

    c = utf[0];
    if (c & 0x80) {
        if (*len < 2)
            goto error;
        if ((utf[1] & 0xc0) != 0x80)
            goto error;
        if ((c & 0xe0) == 0xe0) {
            if (*len < 3)
                goto error;
            if ((utf[2] & 0xc0) != 0x80)
                goto error;
            if ((c & 0xf0) == 0xf0) {
                if (*len < 4)
                    goto error;
                if ((c & 0xf8) != 0xf0 || (utf[3] & 0xc0) != 0x80)
                    goto error;
                *len = 4;
                /* 4-byte code */
                c = (utf[0] & 0x7) << 18;
                c |= (utf[1] & 0x3f) << 12;
                c |= (utf[2] & 0x3f) << 6;
                c |= utf[3] & 0x3f;
            } else {
              /* 3-byte code */
                *len = 3;
                c = (utf[0] & 0xf) << 12;
                c |= (utf[1] & 0x3f) << 6;
                c |= utf[2] & 0x3f;
            }
        } else {
          /* 2-byte code */
            *len = 2;
            c = (utf[0] & 0x1f) << 6;
            c |= utf[1] & 0x3f;
        }
    } else {
        /* 1-byte code */
        *len = 1;
    }
    return(c);

error:
    if (len != NULL)
	*len = 0;
    return(-1);
}

/**
 * xmlCheckUTF8:
 * @utf: Pointer to putative UTF-8 encoded string.
 *
 * Checks @utf for being valid UTF-8. @utf is assumed to be
 * null-terminated. This function is not super-strict, as it will
 * allow longer UTF-8 sequences than necessary. Note that Java is
 * capable of producing these sequences if provoked. Also note, this
 * routine checks for the 4-byte maximum size, but does not check for
 * 0x10ffff maximum value.
 *
 * Return value: true if @utf is valid.
 **/
int
xmlCheckUTF8(const unsigned char *utf)
{
    int ix;
    unsigned char c;

    if (utf == NULL)
        return(0);
    /*
     * utf is a string of 1, 2, 3 or 4 bytes.  The valid strings
     * are as follows (in "bit format"):
     *    0xxxxxxx                                      valid 1-byte
     *    110xxxxx 10xxxxxx                             valid 2-byte
     *    1110xxxx 10xxxxxx 10xxxxxx                    valid 3-byte
     *    11110xxx 10xxxxxx 10xxxxxx 10xxxxxx           valid 4-byte
     */
    for (ix = 0; (c = utf[ix]);) {      /* string is 0-terminated */
        if ((c & 0x80) == 0x00) {	/* 1-byte code, starts with 10 */
            ix++;
	} else if ((c & 0xe0) == 0xc0) {/* 2-byte code, starts with 110 */
	    if ((utf[ix+1] & 0xc0 ) != 0x80)
	        return 0;
	    ix += 2;
	} else if ((c & 0xf0) == 0xe0) {/* 3-byte code, starts with 1110 */
	    if (((utf[ix+1] & 0xc0) != 0x80) ||
	        ((utf[ix+2] & 0xc0) != 0x80))
		    return 0;
	    ix += 3;
	} else if ((c & 0xf8) == 0xf0) {/* 4-byte code, starts with 11110 */
	    if (((utf[ix+1] & 0xc0) != 0x80) ||
	        ((utf[ix+2] & 0xc0) != 0x80) ||
		((utf[ix+3] & 0xc0) != 0x80))
		    return 0;
	    ix += 4;
	} else				/* unknown encoding */
	    return 0;
      }
      return(1);
}

/**
 * xmlUTF8Strsize:
 * @utf:  a sequence of UTF-8 encoded bytes
 * @len:  the number of characters in the array
 *
 * storage size of an UTF8 string
 * the behaviour is not garanteed if the input string is not UTF-8
 *
 * Returns the storage size of
 * the first 'len' characters of ARRAY
 */

int
xmlUTF8Strsize(const xmlChar *utf, int len) {
    const xmlChar   *ptr=utf;
    xmlChar         ch;

    if (utf == NULL)
        return(0);

    if (len <= 0)
        return(0);

    while ( len-- > 0) {
        if ( !*ptr )
            break;
        if ( (ch = *ptr++) & 0x80)
            while ((ch<<=1) & 0x80 ) {
                ptr++;
		if (*ptr == 0) break;
	    }
    }
    return (ptr - utf);
}


/**
 * xmlUTF8Strndup:
 * @utf:  the input UTF8 *
 * @len:  the len of @utf (in chars)
 *
 * a strndup for array of UTF8's
 *
 * Returns a new UTF8 * or NULL
 */
xmlChar *
xmlUTF8Strndup(const xmlChar *utf, int len) {
    xmlChar *ret;
    int i;

    if ((utf == NULL) || (len < 0)) return(NULL);
    i = xmlUTF8Strsize(utf, len);
    ret = (xmlChar *) xmlMallocAtomic((i + 1) * sizeof(xmlChar));
    if (ret == NULL) {
        xmlGenericError(xmlGenericErrorContext,
                "malloc of %ld byte failed\n",
                (len + 1) * (long)sizeof(xmlChar));
        return(NULL);
    }
    memcpy(ret, utf, i * sizeof(xmlChar));
    ret[i] = 0;
    return(ret);
}

/**
 * xmlUTF8Strpos:
 * @utf:  the input UTF8 *
 * @pos:  the position of the desired UTF8 char (in chars)
 *
 * a function to provide the equivalent of fetching a
 * character from a string array
 *
 * Returns a pointer to the UTF8 character or NULL
 */
const xmlChar *
xmlUTF8Strpos(const xmlChar *utf, int pos) {
    xmlChar ch;

    if (utf == NULL) return(NULL);
    if (pos < 0)
        return(NULL);
    while (pos--) {
        if ((ch=*utf++) == 0) return(NULL);
        if ( ch & 0x80 ) {
            /* if not simple ascii, verify proper format */
            if ( (ch & 0xc0) != 0xc0 )
                return(NULL);
            /* then skip over remaining bytes for this char */
            while ( (ch <<= 1) & 0x80 )
                if ( (*utf++ & 0xc0) != 0x80 )
                    return(NULL);
        }
    }
    return((xmlChar *)utf);
}

/**
 * xmlUTF8Strloc:
 * @utf:  the input UTF8 *
 * @utfchar:  the UTF8 character to be found
 *
 * a function to provide the relative location of a UTF8 char
 *
 * Returns the relative character position of the desired char
 * or -1 if not found
 */
int
xmlUTF8Strloc(const xmlChar *utf, const xmlChar *utfchar) {
    int i, size;
    xmlChar ch;

    if (utf==NULL || utfchar==NULL) return -1;
    size = xmlUTF8Strsize(utfchar, 1);
        for(i=0; (ch=*utf) != 0; i++) {
            if (xmlStrncmp(utf, utfchar, size)==0)
                return(i);
            utf++;
            if ( ch & 0x80 ) {
                /* if not simple ascii, verify proper format */
                if ( (ch & 0xc0) != 0xc0 )
                    return(-1);
                /* then skip over remaining bytes for this char */
                while ( (ch <<= 1) & 0x80 )
                    if ( (*utf++ & 0xc0) != 0x80 )
                        return(-1);
            }
        }

    return(-1);
}
/**
 * xmlUTF8Strsub:
 * @utf:  a sequence of UTF-8 encoded bytes
 * @start: relative pos of first char
 * @len:   total number to copy
 *
 * Create a substring from a given UTF-8 string
 * Note:  positions are given in units of UTF-8 chars
 *
 * Returns a pointer to a newly created string
 * or NULL if any problem
 */

xmlChar *
xmlUTF8Strsub(const xmlChar *utf, int start, int len) {
    int            i;
    xmlChar ch;

    if (utf == NULL) return(NULL);
    if (start < 0) return(NULL);
    if (len < 0) return(NULL);

    /*
     * Skip over any leading chars
     */
    for (i = 0;i < start;i++) {
        if ((ch=*utf++) == 0) return(NULL);
        if ( ch & 0x80 ) {
            /* if not simple ascii, verify proper format */
            if ( (ch & 0xc0) != 0xc0 )
                return(NULL);
            /* then skip over remaining bytes for this char */
            while ( (ch <<= 1) & 0x80 )
                if ( (*utf++ & 0xc0) != 0x80 )
                    return(NULL);
        }
    }

    return(xmlUTF8Strndup(utf, len));
}

#define bottom_xmlstring
#include "elfgcchack.h"
