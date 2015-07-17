/*
 * dict.c: dictionary of reusable strings, just used to avoid allocation
 *         and freeing operations.
 *
 * Copyright (C) 2003-2012 Daniel Veillard.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE AUTHORS AND
 * CONTRIBUTORS ACCEPT NO RESPONSIBILITY IN ANY CONCEIVABLE MANNER.
 *
 * Author: daniel@veillard.com
 */

#define IN_LIBXML
#include "libxml.h"

#include <limits.h>
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif

/*
 * Following http://www.ocert.org/advisories/ocert-2011-003.html
 * it seems that having hash randomization might be a good idea
 * when using XML with untrusted data
 * Note1: that it works correctly only if compiled with WITH_BIG_KEY
 *  which is the default.
 * Note2: the fast function used for a small dict won't protect very
 *  well but since the attack is based on growing a very big hash
 *  list we will use the BigKey algo as soon as the hash size grows
 *  over MIN_DICT_SIZE so this actually works
 */
#if defined(HAVE_RAND) && defined(HAVE_SRAND) && defined(HAVE_TIME)
#define DICT_RANDOMIZATION
#endif

#include <string.h>
#ifdef HAVE_STDINT_H
#include <stdint.h>
#else
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#elif defined(WIN32)
typedef unsigned __int32 uint32_t;
#endif
#endif
#include <libxml/tree.h>
#include <libxml/dict.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlerror.h>
#include <libxml/globals.h>

/* #define DEBUG_GROW */
/* #define DICT_DEBUG_PATTERNS */

#define MAX_HASH_LEN 3
#define MIN_DICT_SIZE 128
#define MAX_DICT_HASH 8 * 2048
#define WITH_BIG_KEY

#ifdef WITH_BIG_KEY
#define xmlDictComputeKey(dict, name, len)                              \
    (((dict)->size == MIN_DICT_SIZE) ?                                  \
     xmlDictComputeFastKey(name, len, (dict)->seed) :                   \
     xmlDictComputeBigKey(name, len, (dict)->seed))

#define xmlDictComputeQKey(dict, prefix, plen, name, len)               \
    (((prefix) == NULL) ?                                               \
      (xmlDictComputeKey(dict, name, len)) :                             \
      (((dict)->size == MIN_DICT_SIZE) ?                                \
       xmlDictComputeFastQKey(prefix, plen, name, len, (dict)->seed) :	\
       xmlDictComputeBigQKey(prefix, plen, name, len, (dict)->seed)))

#else /* !WITH_BIG_KEY */
#define xmlDictComputeKey(dict, name, len)                              \
        xmlDictComputeFastKey(name, len, (dict)->seed)
#define xmlDictComputeQKey(dict, prefix, plen, name, len)               \
        xmlDictComputeFastQKey(prefix, plen, name, len, (dict)->seed)
#endif /* WITH_BIG_KEY */

/*
 * An entry in the dictionnary
 */
typedef struct _xmlDictEntry xmlDictEntry;
typedef xmlDictEntry *xmlDictEntryPtr;
struct _xmlDictEntry {
    struct _xmlDictEntry *next;
    const xmlChar *name;
    unsigned int len;
    int valid;
    unsigned long okey;
};

typedef struct _xmlDictStrings xmlDictStrings;
typedef xmlDictStrings *xmlDictStringsPtr;
struct _xmlDictStrings {
    xmlDictStringsPtr next;
    xmlChar *free;
    xmlChar *end;
    size_t size;
    size_t nbStrings;
    xmlChar array[1];
};
/*
 * The entire dictionnary
 */
struct _xmlDict {
    int ref_counter;

    struct _xmlDictEntry *dict;
    size_t size;
    unsigned int nbElems;
    xmlDictStringsPtr strings;

    struct _xmlDict *subdict;
    /* used for randomization */
    int seed;
    /* used to impose a limit on size */
    size_t limit;
};

/*
 * A mutex for modifying the reference counter for shared
 * dictionaries.
 */
static xmlRMutexPtr xmlDictMutex = NULL;

/*
 * Whether the dictionary mutex was initialized.
 */
static int xmlDictInitialized = 0;

#ifdef DICT_RANDOMIZATION
#ifdef HAVE_RAND_R
/*
 * Internal data for random function, protected by xmlDictMutex
 */
static unsigned int rand_seed = 0;
#endif
#endif

/**
 * xmlInitializeDict:
 *
 * Do the dictionary mutex initialization.
 * this function is deprecated
 *
 * Returns 0 if initialization was already done, and 1 if that
 * call led to the initialization
 */
int xmlInitializeDict(void) {
    return(0);
}

/**
 * __xmlInitializeDict:
 *
 * This function is not public
 * Do the dictionary mutex initialization.
 * this function is not thread safe, initialization should
 * normally be done once at setup when called from xmlOnceInit()
 * we may also land in this code if thread support is not compiled in
 *
 * Returns 0 if initialization was already done, and 1 if that
 * call led to the initialization
 */
int __xmlInitializeDict(void) {
    if (xmlDictInitialized)
        return(1);

    if ((xmlDictMutex = xmlNewRMutex()) == NULL)
        return(0);
    xmlRMutexLock(xmlDictMutex);

#ifdef DICT_RANDOMIZATION
#ifdef HAVE_RAND_R
    rand_seed = time(NULL);
    rand_r(& rand_seed);
#else
    srand(time(NULL));
#endif
#endif
    xmlDictInitialized = 1;
    xmlRMutexUnlock(xmlDictMutex);
    return(1);
}

#ifdef DICT_RANDOMIZATION
int __xmlRandom(void) {
    int ret;

    if (xmlDictInitialized == 0)
        __xmlInitializeDict();

    xmlRMutexLock(xmlDictMutex);
#ifdef HAVE_RAND_R
    ret = rand_r(& rand_seed);
#else
    ret = rand();
#endif
    xmlRMutexUnlock(xmlDictMutex);
    return(ret);
}
#endif

/**
 * xmlDictCleanup:
 *
 * Free the dictionary mutex. Do not call unless sure the library
 * is not in use anymore !
 */
void
xmlDictCleanup(void) {
    if (!xmlDictInitialized)
        return;

    xmlFreeRMutex(xmlDictMutex);

    xmlDictInitialized = 0;
}

/*
 * xmlDictAddString:
 * @dict: the dictionnary
 * @name: the name of the userdata
 * @len: the length of the name
 *
 * Add the string to the array[s]
 *
 * Returns the pointer of the local string, or NULL in case of error.
 */
static const xmlChar *
xmlDictAddString(xmlDictPtr dict, const xmlChar *name, unsigned int namelen) {
    xmlDictStringsPtr pool;
    const xmlChar *ret;
    size_t size = 0; /* + sizeof(_xmlDictStrings) == 1024 */
    size_t limit = 0;

#ifdef DICT_DEBUG_PATTERNS
    fprintf(stderr, "-");
#endif
    pool = dict->strings;
    while (pool != NULL) {
	if (pool->end - pool->free > namelen)
	    goto found_pool;
	if (pool->size > size) size = pool->size;
        limit += pool->size;
	pool = pool->next;
    }
    /*
     * Not found, need to allocate
     */
    if (pool == NULL) {
        if ((dict->limit > 0) && (limit > dict->limit)) {
            return(NULL);
        }

        if (size == 0) size = 1000;
	else size *= 4; /* exponential growth */
        if (size < 4 * namelen)
	    size = 4 * namelen; /* just in case ! */
	pool = (xmlDictStringsPtr) xmlMalloc(sizeof(xmlDictStrings) + size);
	if (pool == NULL)
	    return(NULL);
	pool->size = size;
	pool->nbStrings = 0;
	pool->free = &pool->array[0];
	pool->end = &pool->array[size];
	pool->next = dict->strings;
	dict->strings = pool;
#ifdef DICT_DEBUG_PATTERNS
        fprintf(stderr, "+");
#endif
    }
found_pool:
    ret = pool->free;
    memcpy(pool->free, name, namelen);
    pool->free += namelen;
    *(pool->free++) = 0;
    pool->nbStrings++;
    return(ret);
}

/*
 * xmlDictAddQString:
 * @dict: the dictionnary
 * @prefix: the prefix of the userdata
 * @plen: the prefix length
 * @name: the name of the userdata
 * @len: the length of the name
 *
 * Add the QName to the array[s]
 *
 * Returns the pointer of the local string, or NULL in case of error.
 */
static const xmlChar *
xmlDictAddQString(xmlDictPtr dict, const xmlChar *prefix, unsigned int plen,
                 const xmlChar *name, unsigned int namelen)
{
    xmlDictStringsPtr pool;
    const xmlChar *ret;
    size_t size = 0; /* + sizeof(_xmlDictStrings) == 1024 */
    size_t limit = 0;

    if (prefix == NULL) return(xmlDictAddString(dict, name, namelen));

#ifdef DICT_DEBUG_PATTERNS
    fprintf(stderr, "=");
#endif
    pool = dict->strings;
    while (pool != NULL) {
	if (pool->end - pool->free > namelen + plen + 1)
	    goto found_pool;
	if (pool->size > size) size = pool->size;
        limit += pool->size;
	pool = pool->next;
    }
    /*
     * Not found, need to allocate
     */
    if (pool == NULL) {
        if ((dict->limit > 0) && (limit > dict->limit)) {
            return(NULL);
        }

        if (size == 0) size = 1000;
	else size *= 4; /* exponential growth */
        if (size < 4 * (namelen + plen + 1))
	    size = 4 * (namelen + plen + 1); /* just in case ! */
	pool = (xmlDictStringsPtr) xmlMalloc(sizeof(xmlDictStrings) + size);
	if (pool == NULL)
	    return(NULL);
	pool->size = size;
	pool->nbStrings = 0;
	pool->free = &pool->array[0];
	pool->end = &pool->array[size];
	pool->next = dict->strings;
	dict->strings = pool;
#ifdef DICT_DEBUG_PATTERNS
        fprintf(stderr, "+");
#endif
    }
found_pool:
    ret = pool->free;
    memcpy(pool->free, prefix, plen);
    pool->free += plen;
    *(pool->free++) = ':';
    memcpy(pool->free, name, namelen);
    pool->free += namelen;
    *(pool->free++) = 0;
    pool->nbStrings++;
    return(ret);
}

#ifdef WITH_BIG_KEY
/*
 * xmlDictComputeBigKey:
 *
 * Calculate a hash key using a good hash function that works well for
 * larger hash table sizes.
 *
 * Hash function by "One-at-a-Time Hash" see
 * http://burtleburtle.net/bob/hash/doobs.html
 */

static uint32_t
xmlDictComputeBigKey(const xmlChar* data, int namelen, int seed) {
    uint32_t hash;
    int i;

    if (namelen <= 0 || data == NULL) return(0);

    hash = seed;

    for (i = 0;i < namelen; i++) {
        hash += data[i];
	hash += (hash << 10);
	hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);

    return hash;
}

/*
 * xmlDictComputeBigQKey:
 *
 * Calculate a hash key for two strings using a good hash function
 * that works well for larger hash table sizes.
 *
 * Hash function by "One-at-a-Time Hash" see
 * http://burtleburtle.net/bob/hash/doobs.html
 *
 * Neither of the two strings must be NULL.
 */
static unsigned long
xmlDictComputeBigQKey(const xmlChar *prefix, int plen,
                      const xmlChar *name, int len, int seed)
{
    uint32_t hash;
    int i;

    hash = seed;

    for (i = 0;i < plen; i++) {
        hash += prefix[i];
	hash += (hash << 10);
	hash ^= (hash >> 6);
    }
    hash += ':';
    hash += (hash << 10);
    hash ^= (hash >> 6);

    for (i = 0;i < len; i++) {
        hash += name[i];
	hash += (hash << 10);
	hash ^= (hash >> 6);
    }
    hash += (hash << 3);
    hash ^= (hash >> 11);
    hash += (hash << 15);

    return hash;
}
#endif /* WITH_BIG_KEY */

/*
 * xmlDictComputeFastKey:
 *
 * Calculate a hash key using a fast hash function that works well
 * for low hash table fill.
 */
static unsigned long
xmlDictComputeFastKey(const xmlChar *name, int namelen, int seed) {
    unsigned long value = seed;

    if (name == NULL) return(0);
    value = *name;
    value <<= 5;
    if (namelen > 10) {
        value += name[namelen - 1];
        namelen = 10;
    }
    switch (namelen) {
        case 10: value += name[9];
        case 9: value += name[8];
        case 8: value += name[7];
        case 7: value += name[6];
        case 6: value += name[5];
        case 5: value += name[4];
        case 4: value += name[3];
        case 3: value += name[2];
        case 2: value += name[1];
        default: break;
    }
    return(value);
}

/*
 * xmlDictComputeFastQKey:
 *
 * Calculate a hash key for two strings using a fast hash function
 * that works well for low hash table fill.
 *
 * Neither of the two strings must be NULL.
 */
static unsigned long
xmlDictComputeFastQKey(const xmlChar *prefix, int plen,
                       const xmlChar *name, int len, int seed)
{
    unsigned long value = (unsigned long) seed;

    if (plen == 0)
	value += 30 * (unsigned long) ':';
    else
	value += 30 * (*prefix);

    if (len > 10) {
        value += name[len - (plen + 1 + 1)];
        len = 10;
	if (plen > 10)
	    plen = 10;
    }
    switch (plen) {
        case 10: value += prefix[9];
        case 9: value += prefix[8];
        case 8: value += prefix[7];
        case 7: value += prefix[6];
        case 6: value += prefix[5];
        case 5: value += prefix[4];
        case 4: value += prefix[3];
        case 3: value += prefix[2];
        case 2: value += prefix[1];
        case 1: value += prefix[0];
        default: break;
    }
    len -= plen;
    if (len > 0) {
        value += (unsigned long) ':';
	len--;
    }
    switch (len) {
        case 10: value += name[9];
        case 9: value += name[8];
        case 8: value += name[7];
        case 7: value += name[6];
        case 6: value += name[5];
        case 5: value += name[4];
        case 4: value += name[3];
        case 3: value += name[2];
        case 2: value += name[1];
        case 1: value += name[0];
        default: break;
    }
    return(value);
}

/**
 * xmlDictCreate:
 *
 * Create a new dictionary
 *
 * Returns the newly created dictionnary, or NULL if an error occured.
 */
xmlDictPtr
xmlDictCreate(void) {
    xmlDictPtr dict;

    if (!xmlDictInitialized)
        if (!__xmlInitializeDict())
            return(NULL);

#ifdef DICT_DEBUG_PATTERNS
    fprintf(stderr, "C");
#endif

    dict = xmlMalloc(sizeof(xmlDict));
    if (dict) {
        dict->ref_counter = 1;
        dict->limit = 0;

        dict->size = MIN_DICT_SIZE;
	dict->nbElems = 0;
        dict->dict = xmlMalloc(MIN_DICT_SIZE * sizeof(xmlDictEntry));
	dict->strings = NULL;
	dict->subdict = NULL;
        if (dict->dict) {
	    memset(dict->dict, 0, MIN_DICT_SIZE * sizeof(xmlDictEntry));
#ifdef DICT_RANDOMIZATION
            dict->seed = __xmlRandom();
#else
            dict->seed = 0;
#endif
	    return(dict);
        }
        xmlFree(dict);
    }
    return(NULL);
}

/**
 * xmlDictCreateSub:
 * @sub: an existing dictionnary
 *
 * Create a new dictionary, inheriting strings from the read-only
 * dictionnary @sub. On lookup, strings are first searched in the
 * new dictionnary, then in @sub, and if not found are created in the
 * new dictionnary.
 *
 * Returns the newly created dictionnary, or NULL if an error occured.
 */
xmlDictPtr
xmlDictCreateSub(xmlDictPtr sub) {
    xmlDictPtr dict = xmlDictCreate();

    if ((dict != NULL) && (sub != NULL)) {
#ifdef DICT_DEBUG_PATTERNS
        fprintf(stderr, "R");
#endif
        dict->seed = sub->seed;
        dict->subdict = sub;
	xmlDictReference(dict->subdict);
    }
    return(dict);
}

/**
 * xmlDictReference:
 * @dict: the dictionnary
 *
 * Increment the reference counter of a dictionary
 *
 * Returns 0 in case of success and -1 in case of error
 */
int
xmlDictReference(xmlDictPtr dict) {
    if (!xmlDictInitialized)
        if (!__xmlInitializeDict())
            return(-1);

    if (dict == NULL) return -1;
    xmlRMutexLock(xmlDictMutex);
    dict->ref_counter++;
    xmlRMutexUnlock(xmlDictMutex);
    return(0);
}

/**
 * xmlDictGrow:
 * @dict: the dictionnary
 * @size: the new size of the dictionnary
 *
 * resize the dictionnary
 *
 * Returns 0 in case of success, -1 in case of failure
 */
static int
xmlDictGrow(xmlDictPtr dict, size_t size) {
    unsigned long key, okey;
    size_t oldsize, i;
    xmlDictEntryPtr iter, next;
    struct _xmlDictEntry *olddict;
#ifdef DEBUG_GROW
    unsigned long nbElem = 0;
#endif
    int ret = 0;
    int keep_keys = 1;

    if (dict == NULL)
	return(-1);
    if (size < 8)
        return(-1);
    if (size > 8 * 2048)
	return(-1);

#ifdef DICT_DEBUG_PATTERNS
    fprintf(stderr, "*");
#endif

    oldsize = dict->size;
    olddict = dict->dict;
    if (olddict == NULL)
        return(-1);
    if (oldsize == MIN_DICT_SIZE)
        keep_keys = 0;

    dict->dict = xmlMalloc(size * sizeof(xmlDictEntry));
    if (dict->dict == NULL) {
	dict->dict = olddict;
	return(-1);
    }
    memset(dict->dict, 0, size * sizeof(xmlDictEntry));
    dict->size = size;

    /*	If the two loops are merged, there would be situations where
	a new entry needs to allocated and data copied into it from
	the main dict. It is nicer to run through the array twice, first
	copying all the elements in the main array (less probability of
	allocate) and then the rest, so we only free in the second loop.
    */
    for (i = 0; i < oldsize; i++) {
	if (olddict[i].valid == 0)
	    continue;

	if (keep_keys)
	    okey = olddict[i].okey;
	else
	    okey = xmlDictComputeKey(dict, olddict[i].name, olddict[i].len);
	key = okey % dict->size;

	if (dict->dict[key].valid == 0) {
	    memcpy(&(dict->dict[key]), &(olddict[i]), sizeof(xmlDictEntry));
	    dict->dict[key].next = NULL;
	    dict->dict[key].okey = okey;
	} else {
	    xmlDictEntryPtr entry;

	    entry = xmlMalloc(sizeof(xmlDictEntry));
	    if (entry != NULL) {
		entry->name = olddict[i].name;
		entry->len = olddict[i].len;
		entry->okey = okey;
		entry->next = dict->dict[key].next;
		entry->valid = 1;
		dict->dict[key].next = entry;
	    } else {
	        /*
		 * we don't have much ways to alert from herei
		 * result is loosing an entry and unicity garantee
		 */
	        ret = -1;
	    }
	}
#ifdef DEBUG_GROW
	nbElem++;
#endif
    }

    for (i = 0; i < oldsize; i++) {
	iter = olddict[i].next;
	while (iter) {
	    next = iter->next;

	    /*
	     * put back the entry in the new dict
	     */

	    if (keep_keys)
		okey = iter->okey;
	    else
		okey = xmlDictComputeKey(dict, iter->name, iter->len);
	    key = okey % dict->size;
	    if (dict->dict[key].valid == 0) {
		memcpy(&(dict->dict[key]), iter, sizeof(xmlDictEntry));
		dict->dict[key].next = NULL;
		dict->dict[key].valid = 1;
		dict->dict[key].okey = okey;
		xmlFree(iter);
	    } else {
		iter->next = dict->dict[key].next;
		iter->okey = okey;
		dict->dict[key].next = iter;
	    }

#ifdef DEBUG_GROW
	    nbElem++;
#endif

	    iter = next;
	}
    }

    xmlFree(olddict);

#ifdef DEBUG_GROW
    xmlGenericError(xmlGenericErrorContext,
	    "xmlDictGrow : from %lu to %lu, %u elems\n", oldsize, size, nbElem);
#endif

    return(ret);
}

/**
 * xmlDictFree:
 * @dict: the dictionnary
 *
 * Free the hash @dict and its contents. The userdata is
 * deallocated with @f if provided.
 */
void
xmlDictFree(xmlDictPtr dict) {
    size_t i;
    xmlDictEntryPtr iter;
    xmlDictEntryPtr next;
    int inside_dict = 0;
    xmlDictStringsPtr pool, nextp;

    if (dict == NULL)
	return;

    if (!xmlDictInitialized)
        if (!__xmlInitializeDict())
            return;

    /* decrement the counter, it may be shared by a parser and docs */
    xmlRMutexLock(xmlDictMutex);
    dict->ref_counter--;
    if (dict->ref_counter > 0) {
        xmlRMutexUnlock(xmlDictMutex);
        return;
    }

    xmlRMutexUnlock(xmlDictMutex);

    if (dict->subdict != NULL) {
        xmlDictFree(dict->subdict);
    }

    if (dict->dict) {
	for(i = 0; ((i < dict->size) && (dict->nbElems > 0)); i++) {
	    iter = &(dict->dict[i]);
	    if (iter->valid == 0)
		continue;
	    inside_dict = 1;
	    while (iter) {
		next = iter->next;
		if (!inside_dict)
		    xmlFree(iter);
		dict->nbElems--;
		inside_dict = 0;
		iter = next;
	    }
	}
	xmlFree(dict->dict);
    }
    pool = dict->strings;
    while (pool != NULL) {
        nextp = pool->next;
	xmlFree(pool);
	pool = nextp;
    }
    xmlFree(dict);
}

/**
 * xmlDictLookup:
 * @dict: the dictionnary
 * @name: the name of the userdata
 * @len: the length of the name, if -1 it is recomputed
 *
 * Add the @name to the dictionnary @dict if not present.
 *
 * Returns the internal copy of the name or NULL in case of internal error
 */
const xmlChar *
xmlDictLookup(xmlDictPtr dict, const xmlChar *name, int len) {
    unsigned long key, okey, nbi = 0;
    xmlDictEntryPtr entry;
    xmlDictEntryPtr insert;
    const xmlChar *ret;
    unsigned int l;

    if ((dict == NULL) || (name == NULL))
	return(NULL);

    if (len < 0)
        l = strlen((const char *) name);
    else
        l = len;

    if (((dict->limit > 0) && (l >= dict->limit)) ||
        (l > INT_MAX / 2))
        return(NULL);

    /*
     * Check for duplicate and insertion location.
     */
    okey = xmlDictComputeKey(dict, name, l);
    key = okey % dict->size;
    if (dict->dict[key].valid == 0) {
	insert = NULL;
    } else {
	for (insert = &(dict->dict[key]); insert->next != NULL;
	     insert = insert->next) {
#ifdef __GNUC__
	    if ((insert->okey == okey) && (insert->len == l)) {
		if (!memcmp(insert->name, name, l))
		    return(insert->name);
	    }
#else
	    if ((insert->okey == okey) && (insert->len == l) &&
	        (!xmlStrncmp(insert->name, name, l)))
		return(insert->name);
#endif
	    nbi++;
	}
#ifdef __GNUC__
	if ((insert->okey == okey) && (insert->len == l)) {
	    if (!memcmp(insert->name, name, l))
		return(insert->name);
	}
#else
	if ((insert->okey == okey) && (insert->len == l) &&
	    (!xmlStrncmp(insert->name, name, l)))
	    return(insert->name);
#endif
    }

    if (dict->subdict) {
        unsigned long skey;

        /* we cannot always reuse the same okey for the subdict */
        if (((dict->size == MIN_DICT_SIZE) &&
	     (dict->subdict->size != MIN_DICT_SIZE)) ||
            ((dict->size != MIN_DICT_SIZE) &&
	     (dict->subdict->size == MIN_DICT_SIZE)))
	    skey = xmlDictComputeKey(dict->subdict, name, l);
	else
	    skey = okey;

	key = skey % dict->subdict->size;
	if (dict->subdict->dict[key].valid != 0) {
	    xmlDictEntryPtr tmp;

	    for (tmp = &(dict->subdict->dict[key]); tmp->next != NULL;
		 tmp = tmp->next) {
#ifdef __GNUC__
		if ((tmp->okey == skey) && (tmp->len == l)) {
		    if (!memcmp(tmp->name, name, l))
			return(tmp->name);
		}
#else
		if ((tmp->okey == skey) && (tmp->len == l) &&
		    (!xmlStrncmp(tmp->name, name, l)))
		    return(tmp->name);
#endif
		nbi++;
	    }
#ifdef __GNUC__
	    if ((tmp->okey == skey) && (tmp->len == l)) {
		if (!memcmp(tmp->name, name, l))
		    return(tmp->name);
	    }
#else
	    if ((tmp->okey == skey) && (tmp->len == l) &&
		(!xmlStrncmp(tmp->name, name, l)))
		return(tmp->name);
#endif
	}
	key = okey % dict->size;
    }

    ret = xmlDictAddString(dict, name, l);
    if (ret == NULL)
        return(NULL);
    if (insert == NULL) {
	entry = &(dict->dict[key]);
    } else {
	entry = xmlMalloc(sizeof(xmlDictEntry));
	if (entry == NULL)
	     return(NULL);
    }
    entry->name = ret;
    entry->len = l;
    entry->next = NULL;
    entry->valid = 1;
    entry->okey = okey;


    if (insert != NULL)
	insert->next = entry;

    dict->nbElems++;

    if ((nbi > MAX_HASH_LEN) &&
        (dict->size <= ((MAX_DICT_HASH / 2) / MAX_HASH_LEN))) {
	if (xmlDictGrow(dict, MAX_HASH_LEN * 2 * dict->size) != 0)
	    return(NULL);
    }
    /* Note that entry may have been freed at this point by xmlDictGrow */

    return(ret);
}

/**
 * xmlDictExists:
 * @dict: the dictionnary
 * @name: the name of the userdata
 * @len: the length of the name, if -1 it is recomputed
 *
 * Check if the @name exists in the dictionnary @dict.
 *
 * Returns the internal copy of the name or NULL if not found.
 */
const xmlChar *
xmlDictExists(xmlDictPtr dict, const xmlChar *name, int len) {
    unsigned long key, okey, nbi = 0;
    xmlDictEntryPtr insert;
    unsigned int l;

    if ((dict == NULL) || (name == NULL))
	return(NULL);

    if (len < 0)
        l = strlen((const char *) name);
    else
        l = len;
    if (((dict->limit > 0) && (l >= dict->limit)) ||
        (l > INT_MAX / 2))
        return(NULL);

    /*
     * Check for duplicate and insertion location.
     */
    okey = xmlDictComputeKey(dict, name, l);
    key = okey % dict->size;
    if (dict->dict[key].valid == 0) {
	insert = NULL;
    } else {
	for (insert = &(dict->dict[key]); insert->next != NULL;
	     insert = insert->next) {
#ifdef __GNUC__
	    if ((insert->okey == okey) && (insert->len == l)) {
		if (!memcmp(insert->name, name, l))
		    return(insert->name);
	    }
#else
	    if ((insert->okey == okey) && (insert->len == l) &&
	        (!xmlStrncmp(insert->name, name, l)))
		return(insert->name);
#endif
	    nbi++;
	}
#ifdef __GNUC__
	if ((insert->okey == okey) && (insert->len == l)) {
	    if (!memcmp(insert->name, name, l))
		return(insert->name);
	}
#else
	if ((insert->okey == okey) && (insert->len == l) &&
	    (!xmlStrncmp(insert->name, name, l)))
	    return(insert->name);
#endif
    }

    if (dict->subdict) {
        unsigned long skey;

        /* we cannot always reuse the same okey for the subdict */
        if (((dict->size == MIN_DICT_SIZE) &&
	     (dict->subdict->size != MIN_DICT_SIZE)) ||
            ((dict->size != MIN_DICT_SIZE) &&
	     (dict->subdict->size == MIN_DICT_SIZE)))
	    skey = xmlDictComputeKey(dict->subdict, name, l);
	else
	    skey = okey;

	key = skey % dict->subdict->size;
	if (dict->subdict->dict[key].valid != 0) {
	    xmlDictEntryPtr tmp;

	    for (tmp = &(dict->subdict->dict[key]); tmp->next != NULL;
		 tmp = tmp->next) {
#ifdef __GNUC__
		if ((tmp->okey == skey) && (tmp->len == l)) {
		    if (!memcmp(tmp->name, name, l))
			return(tmp->name);
		}
#else
		if ((tmp->okey == skey) && (tmp->len == l) &&
		    (!xmlStrncmp(tmp->name, name, l)))
		    return(tmp->name);
#endif
		nbi++;
	    }
#ifdef __GNUC__
	    if ((tmp->okey == skey) && (tmp->len == l)) {
		if (!memcmp(tmp->name, name, l))
		    return(tmp->name);
	    }
#else
	    if ((tmp->okey == skey) && (tmp->len == l) &&
		(!xmlStrncmp(tmp->name, name, l)))
		return(tmp->name);
#endif
	}
    }

    /* not found */
    return(NULL);
}

/**
 * xmlDictQLookup:
 * @dict: the dictionnary
 * @prefix: the prefix
 * @name: the name
 *
 * Add the QName @prefix:@name to the hash @dict if not present.
 *
 * Returns the internal copy of the QName or NULL in case of internal error
 */
const xmlChar *
xmlDictQLookup(xmlDictPtr dict, const xmlChar *prefix, const xmlChar *name) {
    unsigned long okey, key, nbi = 0;
    xmlDictEntryPtr entry;
    xmlDictEntryPtr insert;
    const xmlChar *ret;
    unsigned int len, plen, l;

    if ((dict == NULL) || (name == NULL))
	return(NULL);
    if (prefix == NULL)
        return(xmlDictLookup(dict, name, -1));

    l = len = strlen((const char *) name);
    plen = strlen((const char *) prefix);
    len += 1 + plen;

    /*
     * Check for duplicate and insertion location.
     */
    okey = xmlDictComputeQKey(dict, prefix, plen, name, l);
    key = okey % dict->size;
    if (dict->dict[key].valid == 0) {
	insert = NULL;
    } else {
	for (insert = &(dict->dict[key]); insert->next != NULL;
	     insert = insert->next) {
	    if ((insert->okey == okey) && (insert->len == len) &&
	        (xmlStrQEqual(prefix, name, insert->name)))
		return(insert->name);
	    nbi++;
	}
	if ((insert->okey == okey) && (insert->len == len) &&
	    (xmlStrQEqual(prefix, name, insert->name)))
	    return(insert->name);
    }

    if (dict->subdict) {
        unsigned long skey;

        /* we cannot always reuse the same okey for the subdict */
        if (((dict->size == MIN_DICT_SIZE) &&
	     (dict->subdict->size != MIN_DICT_SIZE)) ||
            ((dict->size != MIN_DICT_SIZE) &&
	     (dict->subdict->size == MIN_DICT_SIZE)))
	    skey = xmlDictComputeQKey(dict->subdict, prefix, plen, name, l);
	else
	    skey = okey;

	key = skey % dict->subdict->size;
	if (dict->subdict->dict[key].valid != 0) {
	    xmlDictEntryPtr tmp;
	    for (tmp = &(dict->subdict->dict[key]); tmp->next != NULL;
		 tmp = tmp->next) {
		if ((tmp->okey == skey) && (tmp->len == len) &&
		    (xmlStrQEqual(prefix, name, tmp->name)))
		    return(tmp->name);
		nbi++;
	    }
	    if ((tmp->okey == skey) && (tmp->len == len) &&
		(xmlStrQEqual(prefix, name, tmp->name)))
		return(tmp->name);
	}
	key = okey % dict->size;
    }

    ret = xmlDictAddQString(dict, prefix, plen, name, l);
    if (ret == NULL)
        return(NULL);
    if (insert == NULL) {
	entry = &(dict->dict[key]);
    } else {
	entry = xmlMalloc(sizeof(xmlDictEntry));
	if (entry == NULL)
	     return(NULL);
    }
    entry->name = ret;
    entry->len = len;
    entry->next = NULL;
    entry->valid = 1;
    entry->okey = okey;

    if (insert != NULL)
	insert->next = entry;

    dict->nbElems++;

    if ((nbi > MAX_HASH_LEN) &&
        (dict->size <= ((MAX_DICT_HASH / 2) / MAX_HASH_LEN)))
	xmlDictGrow(dict, MAX_HASH_LEN * 2 * dict->size);
    /* Note that entry may have been freed at this point by xmlDictGrow */

    return(ret);
}

/**
 * xmlDictOwns:
 * @dict: the dictionnary
 * @str: the string
 *
 * check if a string is owned by the disctionary
 *
 * Returns 1 if true, 0 if false and -1 in case of error
 * -1 in case of error
 */
int
xmlDictOwns(xmlDictPtr dict, const xmlChar *str) {
    xmlDictStringsPtr pool;

    if ((dict == NULL) || (str == NULL))
	return(-1);
    pool = dict->strings;
    while (pool != NULL) {
        if ((str >= &pool->array[0]) && (str <= pool->free))
	    return(1);
	pool = pool->next;
    }
    if (dict->subdict)
        return(xmlDictOwns(dict->subdict, str));
    return(0);
}

/**
 * xmlDictSize:
 * @dict: the dictionnary
 *
 * Query the number of elements installed in the hash @dict.
 *
 * Returns the number of elements in the dictionnary or
 * -1 in case of error
 */
int
xmlDictSize(xmlDictPtr dict) {
    if (dict == NULL)
	return(-1);
    if (dict->subdict)
        return(dict->nbElems + dict->subdict->nbElems);
    return(dict->nbElems);
}

/**
 * xmlDictSetLimit:
 * @dict: the dictionnary
 * @limit: the limit in bytes
 *
 * Set a size limit for the dictionary
 * Added in 2.9.0
 *
 * Returns the previous limit of the dictionary or 0
 */
size_t
xmlDictSetLimit(xmlDictPtr dict, size_t limit) {
    size_t ret;

    if (dict == NULL)
	return(0);
    ret = dict->limit;
    dict->limit = limit;
    return(ret);
}

/**
 * xmlDictGetUsage:
 * @dict: the dictionnary
 *
 * Get how much memory is used by a dictionary for strings
 * Added in 2.9.0
 *
 * Returns the amount of strings allocated
 */
size_t
xmlDictGetUsage(xmlDictPtr dict) {
    xmlDictStringsPtr pool;
    size_t limit = 0;

    if (dict == NULL)
	return(0);
    pool = dict->strings;
    while (pool != NULL) {
        limit += pool->size;
	pool = pool->next;
    }
    return(limit);
}

#define bottom_dict
#include "elfgcchack.h"
