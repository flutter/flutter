/*
 * list.c: lists handling implementation
 *
 * Copyright (C) 2000 Gary Pennington and Daniel Veillard.
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
 * Author: Gary.Pennington@uk.sun.com
 */

#define IN_LIBXML
#include "libxml.h"

#include <stdlib.h>
#include <string.h>
#include <libxml/xmlmemory.h>
#include <libxml/list.h>
#include <libxml/globals.h>

/*
 * Type definition are kept internal
 */

struct _xmlLink
{
    struct _xmlLink *next;
    struct _xmlLink *prev;
    void *data;
};

struct _xmlList
{
    xmlLinkPtr sentinel;
    void (*linkDeallocator)(xmlLinkPtr );
    int (*linkCompare)(const void *, const void*);
};

/************************************************************************
 *                                    *
 *                Interfaces                *
 *                                    *
 ************************************************************************/

/**
 * xmlLinkDeallocator:
 * @l:  a list
 * @lk:  a link
 *
 * Unlink and deallocate @lk from list @l
 */
static void
xmlLinkDeallocator(xmlListPtr l, xmlLinkPtr lk)
{
    (lk->prev)->next = lk->next;
    (lk->next)->prev = lk->prev;
    if(l->linkDeallocator)
        l->linkDeallocator(lk);
    xmlFree(lk);
}

/**
 * xmlLinkCompare:
 * @data0:  first data
 * @data1:  second data
 *
 * Compares two arbitrary data
 *
 * Returns -1, 0 or 1 depending on whether data1 is greater equal or smaller
 *          than data0
 */
static int
xmlLinkCompare(const void *data0, const void *data1)
{
    if (data0 < data1)
        return (-1);
    else if (data0 == data1)
	return (0);
    return (1);
}

/**
 * xmlListLowerSearch:
 * @l:  a list
 * @data:  a data
 *
 * Search data in the ordered list walking from the beginning
 *
 * Returns the link containing the data or NULL
 */
static xmlLinkPtr 
xmlListLowerSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;

    if (l == NULL)
        return(NULL);
    for(lk = l->sentinel->next;lk != l->sentinel && l->linkCompare(lk->data, data) <0 ;lk = lk->next);
    return lk;    
}

/**
 * xmlListHigherSearch:
 * @l:  a list
 * @data:  a data
 *
 * Search data in the ordered list walking backward from the end
 *
 * Returns the link containing the data or NULL
 */
static xmlLinkPtr 
xmlListHigherSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;

    if (l == NULL)
        return(NULL);
    for(lk = l->sentinel->prev;lk != l->sentinel && l->linkCompare(lk->data, data) >0 ;lk = lk->prev);
    return lk;    
}

/**
 * xmlListSearch:
 * @l:  a list
 * @data:  a data
 *
 * Search data in the list
 *
 * Returns the link containing the data or NULL
 */
static xmlLinkPtr 
xmlListLinkSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;
    if (l == NULL)
        return(NULL);
    lk = xmlListLowerSearch(l, data);
    if (lk == l->sentinel)
        return NULL;
    else {
        if (l->linkCompare(lk->data, data) ==0)
            return lk;
        return NULL;
    }
}

/**
 * xmlListLinkReverseSearch:
 * @l:  a list
 * @data:  a data
 *
 * Search data in the list processing backward
 *
 * Returns the link containing the data or NULL
 */
static xmlLinkPtr 
xmlListLinkReverseSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;
    if (l == NULL)
        return(NULL);
    lk = xmlListHigherSearch(l, data);
    if (lk == l->sentinel)
        return NULL;
    else {
        if (l->linkCompare(lk->data, data) ==0)
            return lk;
        return NULL;
    }
}

/**
 * xmlListCreate:
 * @deallocator:  an optional deallocator function
 * @compare:  an optional comparison function
 *
 * Create a new list
 *
 * Returns the new list or NULL in case of error
 */
xmlListPtr
xmlListCreate(xmlListDeallocator deallocator, xmlListDataCompare compare)
{
    xmlListPtr l;
    if (NULL == (l = (xmlListPtr )xmlMalloc( sizeof(xmlList)))) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for list");
        return (NULL);
    }
    /* Initialize the list to NULL */
    memset(l, 0, sizeof(xmlList));
    
    /* Add the sentinel */
    if (NULL ==(l->sentinel = (xmlLinkPtr )xmlMalloc(sizeof(xmlLink)))) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for sentinel");
	xmlFree(l);
        return (NULL);
    }
    l->sentinel->next = l->sentinel;
    l->sentinel->prev = l->sentinel;
    l->sentinel->data = NULL;
    
    /* If there is a link deallocator, use it */
    if (deallocator != NULL)
        l->linkDeallocator = deallocator;
    /* If there is a link comparator, use it */
    if (compare != NULL)
        l->linkCompare = compare;
    else /* Use our own */
        l->linkCompare = xmlLinkCompare;
    return l;
}
    
/**
 * xmlListSearch:
 * @l:  a list
 * @data:  a search value
 *
 * Search the list for an existing value of @data
 *
 * Returns the value associated to @data or NULL in case of error
 */
void *
xmlListSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;
    if (l == NULL)
        return(NULL);
    lk = xmlListLinkSearch(l, data);
    if (lk)
        return (lk->data);
    return NULL;
}

/**
 * xmlListReverseSearch:
 * @l:  a list
 * @data:  a search value
 *
 * Search the list in reverse order for an existing value of @data
 *
 * Returns the value associated to @data or NULL in case of error
 */
void *
xmlListReverseSearch(xmlListPtr l, void *data) 
{
    xmlLinkPtr lk;
    if (l == NULL)
        return(NULL);
    lk = xmlListLinkReverseSearch(l, data);
    if (lk)
        return (lk->data);
    return NULL;
}

/**
 * xmlListInsert:
 * @l:  a list
 * @data:  the data
 *
 * Insert data in the ordered list at the beginning for this value
 *
 * Returns 0 in case of success, 1 in case of failure
 */
int
xmlListInsert(xmlListPtr l, void *data) 
{
    xmlLinkPtr lkPlace, lkNew;

    if (l == NULL)
        return(1);
    lkPlace = xmlListLowerSearch(l, data);
    /* Add the new link */
    lkNew = (xmlLinkPtr) xmlMalloc(sizeof(xmlLink));
    if (lkNew == NULL) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for new link");
        return (1);
    }
    lkNew->data = data;
    lkPlace = lkPlace->prev;
    lkNew->next = lkPlace->next;
    (lkPlace->next)->prev = lkNew;
    lkPlace->next = lkNew;
    lkNew->prev = lkPlace;
    return 0;
}

/**
 * xmlListAppend:
 * @l:  a list
 * @data:  the data
 *
 * Insert data in the ordered list at the end for this value
 *
 * Returns 0 in case of success, 1 in case of failure
 */
int xmlListAppend(xmlListPtr l, void *data) 
{
    xmlLinkPtr lkPlace, lkNew;

    if (l == NULL)
        return(1);
    lkPlace = xmlListHigherSearch(l, data);
    /* Add the new link */
    lkNew = (xmlLinkPtr) xmlMalloc(sizeof(xmlLink));
    if (lkNew == NULL) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for new link");
        return (1);
    }
    lkNew->data = data;
    lkNew->next = lkPlace->next;
    (lkPlace->next)->prev = lkNew;
    lkPlace->next = lkNew;
    lkNew->prev = lkPlace;
    return 0;
}

/**
 * xmlListDelete:
 * @l:  a list
 *
 * Deletes the list and its associated data
 */
void xmlListDelete(xmlListPtr l)
{
    if (l == NULL)
        return;

    xmlListClear(l);
    xmlFree(l->sentinel);
    xmlFree(l);
}

/**
 * xmlListRemoveFirst:
 * @l:  a list
 * @data:  list data
 *
 * Remove the first instance associated to data in the list
 *
 * Returns 1 if a deallocation occured, or 0 if not found
 */
int
xmlListRemoveFirst(xmlListPtr l, void *data)
{
    xmlLinkPtr lk;
    
    if (l == NULL)
        return(0);
    /*Find the first instance of this data */
    lk = xmlListLinkSearch(l, data);
    if (lk != NULL) {
        xmlLinkDeallocator(l, lk);
        return 1;
    }
    return 0;
}

/**
 * xmlListRemoveLast:
 * @l:  a list
 * @data:  list data
 *
 * Remove the last instance associated to data in the list
 *
 * Returns 1 if a deallocation occured, or 0 if not found
 */
int
xmlListRemoveLast(xmlListPtr l, void *data)
{
    xmlLinkPtr lk;
    
    if (l == NULL)
        return(0);
    /*Find the last instance of this data */
    lk = xmlListLinkReverseSearch(l, data);
    if (lk != NULL) {
	xmlLinkDeallocator(l, lk);
        return 1;
    }
    return 0;
}

/**
 * xmlListRemoveAll:
 * @l:  a list
 * @data:  list data
 *
 * Remove the all instance associated to data in the list
 *
 * Returns the number of deallocation, or 0 if not found
 */
int
xmlListRemoveAll(xmlListPtr l, void *data)
{
    int count=0;
    
    if (l == NULL)
        return(0);

    while(xmlListRemoveFirst(l, data))
        count++;
    return count;
}

/**
 * xmlListClear:
 * @l:  a list
 *
 * Remove the all data in the list
 */
void
xmlListClear(xmlListPtr l)
{
    xmlLinkPtr  lk;
    
    if (l == NULL)
        return;
    lk = l->sentinel->next;
    while(lk != l->sentinel) {
        xmlLinkPtr next = lk->next;

        xmlLinkDeallocator(l, lk);
        lk = next;
    }
}

/**
 * xmlListEmpty:
 * @l:  a list
 *
 * Is the list empty ?
 *
 * Returns 1 if the list is empty, 0 if not empty and -1 in case of error
 */
int
xmlListEmpty(xmlListPtr l)
{
    if (l == NULL)
        return(-1);
    return (l->sentinel->next == l->sentinel);
}

/**
 * xmlListFront:
 * @l:  a list
 *
 * Get the first element in the list
 *
 * Returns the first element in the list, or NULL
 */
xmlLinkPtr 
xmlListFront(xmlListPtr l)
{
    if (l == NULL)
        return(NULL);
    return (l->sentinel->next);
}
    
/**
 * xmlListEnd:
 * @l:  a list
 *
 * Get the last element in the list
 *
 * Returns the last element in the list, or NULL
 */
xmlLinkPtr 
xmlListEnd(xmlListPtr l)
{
    if (l == NULL)
        return(NULL);
    return (l->sentinel->prev);
}
    
/**
 * xmlListSize:
 * @l:  a list
 *
 * Get the number of elements in the list
 *
 * Returns the number of elements in the list or -1 in case of error
 */
int
xmlListSize(xmlListPtr l)
{
    xmlLinkPtr lk;
    int count=0;

    if (l == NULL)
        return(-1);
    /* TODO: keep a counter in xmlList instead */
    for(lk = l->sentinel->next; lk != l->sentinel; lk = lk->next, count++);
    return count;
}

/**
 * xmlListPopFront:
 * @l:  a list
 *
 * Removes the first element in the list
 */
void
xmlListPopFront(xmlListPtr l)
{
    if(!xmlListEmpty(l))
        xmlLinkDeallocator(l, l->sentinel->next);
}

/**
 * xmlListPopBack:
 * @l:  a list
 *
 * Removes the last element in the list
 */
void
xmlListPopBack(xmlListPtr l)
{
    if(!xmlListEmpty(l))
        xmlLinkDeallocator(l, l->sentinel->prev);
}

/**
 * xmlListPushFront:
 * @l:  a list
 * @data:  new data
 *
 * add the new data at the beginning of the list
 *
 * Returns 1 if successful, 0 otherwise
 */
int
xmlListPushFront(xmlListPtr l, void *data) 
{
    xmlLinkPtr lkPlace, lkNew;

    if (l == NULL)
        return(0);
    lkPlace = l->sentinel;
    /* Add the new link */
    lkNew = (xmlLinkPtr) xmlMalloc(sizeof(xmlLink));
    if (lkNew == NULL) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for new link");
        return (0);
    }
    lkNew->data = data;
    lkNew->next = lkPlace->next;
    (lkPlace->next)->prev = lkNew;
    lkPlace->next = lkNew;
    lkNew->prev = lkPlace;
    return 1;
}

/**
 * xmlListPushBack:
 * @l:  a list
 * @data:  new data
 *
 * add the new data at the end of the list
 *
 * Returns 1 if successful, 0 otherwise
 */
int
xmlListPushBack(xmlListPtr l, void *data) 
{
    xmlLinkPtr lkPlace, lkNew;

    if (l == NULL)
        return(0);
    lkPlace = l->sentinel->prev;
    /* Add the new link */
    if (NULL ==(lkNew = (xmlLinkPtr )xmlMalloc(sizeof(xmlLink)))) {
        xmlGenericError(xmlGenericErrorContext, 
		        "Cannot initialize memory for new link");
        return (0);
    }
    lkNew->data = data;
    lkNew->next = lkPlace->next;
    (lkPlace->next)->prev = lkNew;
    lkPlace->next = lkNew;
    lkNew->prev = lkPlace;
    return 1;
}

/**
 * xmlLinkGetData:
 * @lk:  a link
 *
 * See Returns.
 *
 * Returns a pointer to the data referenced from this link
 */
void *
xmlLinkGetData(xmlLinkPtr lk)
{
    if (lk == NULL)
        return(NULL);
    return lk->data;
}

/**
 * xmlListReverse:
 * @l:  a list
 *
 * Reverse the order of the elements in the list
 */
void
xmlListReverse(xmlListPtr l)
{
    xmlLinkPtr lk;
    xmlLinkPtr lkPrev;

    if (l == NULL)
        return;
    lkPrev = l->sentinel;
    for (lk = l->sentinel->next; lk != l->sentinel; lk = lk->next) {
        lkPrev->next = lkPrev->prev;
        lkPrev->prev = lk;
        lkPrev = lk;
    }
    /* Fix up the last node */
    lkPrev->next = lkPrev->prev;
    lkPrev->prev = lk;
}

/**
 * xmlListSort:
 * @l:  a list
 *
 * Sort all the elements in the list
 */
void
xmlListSort(xmlListPtr l)
{
    xmlListPtr lTemp;
    
    if (l == NULL)
        return;
    if(xmlListEmpty(l))
        return;

    /* I think that the real answer is to implement quicksort, the
     * alternative is to implement some list copying procedure which
     * would be based on a list copy followed by a clear followed by
     * an insert. This is slow...
     */

    if (NULL ==(lTemp = xmlListDup(l)))
        return;
    xmlListClear(l);
    xmlListMerge(l, lTemp);
    xmlListDelete(lTemp);
    return;
}

/**
 * xmlListWalk:
 * @l:  a list
 * @walker:  a processing function
 * @user:  a user parameter passed to the walker function
 *
 * Walk all the element of the first from first to last and
 * apply the walker function to it
 */
void
xmlListWalk(xmlListPtr l, xmlListWalker walker, const void *user) {
    xmlLinkPtr lk;

    if ((l == NULL) || (walker == NULL))
        return;
    for(lk = l->sentinel->next; lk != l->sentinel; lk = lk->next) {
        if((walker(lk->data, user)) == 0)
                break;
    }
}

/**
 * xmlListReverseWalk:
 * @l:  a list
 * @walker:  a processing function
 * @user:  a user parameter passed to the walker function
 *
 * Walk all the element of the list in reverse order and
 * apply the walker function to it
 */
void
xmlListReverseWalk(xmlListPtr l, xmlListWalker walker, const void *user) {
    xmlLinkPtr lk;

    if ((l == NULL) || (walker == NULL))
        return;
    for(lk = l->sentinel->prev; lk != l->sentinel; lk = lk->prev) {
        if((walker(lk->data, user)) == 0)
                break;
    }
}

/**
 * xmlListMerge:
 * @l1:  the original list
 * @l2:  the new list
 *
 * include all the elements of the second list in the first one and
 * clear the second list
 */
void
xmlListMerge(xmlListPtr l1, xmlListPtr l2)
{
    xmlListCopy(l1, l2);
    xmlListClear(l2);
}

/**
 * xmlListDup:
 * @old:  the list
 *
 * Duplicate the list
 * 
 * Returns a new copy of the list or NULL in case of error
 */
xmlListPtr 
xmlListDup(const xmlListPtr old)
{
    xmlListPtr cur;

    if (old == NULL)
        return(NULL);
    /* Hmmm, how to best deal with allocation issues when copying
     * lists. If there is a de-allocator, should responsibility lie with
     * the new list or the old list. Surely not both. I'll arbitrarily
     * set it to be the old list for the time being whilst I work out
     * the answer
     */
    if (NULL ==(cur = xmlListCreate(NULL, old->linkCompare)))
        return (NULL);
    if (0 != xmlListCopy(cur, old))
        return NULL;
    return cur;
}

/**
 * xmlListCopy:
 * @cur:  the new list
 * @old:  the old list
 *
 * Move all the element from the old list in the new list
 * 
 * Returns 0 in case of success 1 in case of error
 */
int
xmlListCopy(xmlListPtr cur, const xmlListPtr old)
{
    /* Walk the old tree and insert the data into the new one */
    xmlLinkPtr lk;

    if ((old == NULL) || (cur == NULL))
        return(1);
    for(lk = old->sentinel->next; lk != old->sentinel; lk = lk->next) {
        if (0 !=xmlListInsert(cur, lk->data)) {
            xmlListDelete(cur);
            return (1);
        }
    }
    return (0);    
}
/* xmlListUnique() */
/* xmlListSwap */
#define bottom_list
#include "elfgcchack.h"
