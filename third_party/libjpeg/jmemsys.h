/*
 * jmemsys.h
 *
 * Copyright (C) 1992-1997, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This include file defines the interface between the system-independent
 * and system-dependent portions of the JPEG memory manager.  No other
 * modules need include it.  (The system-independent portion is jmemmgr.c;
 * there are several different versions of the system-dependent portion.)
 *
 * This file works as-is for the system-dependent memory managers supplied
 * in the IJG distribution.  You may need to modify it if you write a
 * custom memory manager.  If system-dependent changes are needed in
 * this file, the best method is to #ifdef them based on a configuration
 * symbol supplied in jconfig.h, as we have done with USE_MSDOS_MEMMGR
 * and USE_MAC_MEMMGR.
 */


/* Short forms of external names for systems with brain-damaged linkers. */

#ifdef NEED_SHORT_EXTERNAL_NAMES
#define jpeg_get_small		jGetSmall
#define jpeg_free_small		jFreeSmall
#define jpeg_get_large		jGetLarge
#define jpeg_free_large		jFreeLarge
#define jpeg_mem_available	jMemAvail
#define jpeg_open_backing_store	jOpenBackStore
#define jpeg_mem_init		jMemInit
#define jpeg_mem_term		jMemTerm
#endif /* NEED_SHORT_EXTERNAL_NAMES */


/*
 * These two functions are used to allocate and release small chunks of
 * memory.  (Typically the total amount requested through jpeg_get_small is
 * no more than 20K or so; this will be requested in chunks of a few K each.)
 * Behavior should be the same as for the standard library functions malloc
 * and free; in particular, jpeg_get_small must return NULL on failure.
 * On most systems, these ARE malloc and free.  jpeg_free_small is passed the
 * size of the object being freed, just in case it's needed.
 * On an 80x86 machine using small-data memory model, these manage near heap.
 */

EXTERN(void *) jpeg_get_small JPP((j_common_ptr cinfo, size_t sizeofobject));
EXTERN(void) jpeg_free_small JPP((j_common_ptr cinfo, void * object,
				  size_t sizeofobject));

/*
 * These two functions are used to allocate and release large chunks of
 * memory (up to the total free space designated by jpeg_mem_available).
 * The interface is the same as above, except that on an 80x86 machine,
 * far pointers are used.  On most other machines these are identical to
 * the jpeg_get/free_small routines; but we keep them separate anyway,
 * in case a different allocation strategy is desirable for large chunks.
 */

EXTERN(void FAR *) jpeg_get_large JPP((j_common_ptr cinfo,
				       size_t sizeofobject));
EXTERN(void) jpeg_free_large JPP((j_common_ptr cinfo, void FAR * object,
				  size_t sizeofobject));

/*
 * The macro MAX_ALLOC_CHUNK designates the maximum number of bytes that may
 * be requested in a single call to jpeg_get_large (and jpeg_get_small for that
 * matter, but that case should never come into play).  This macro is needed
 * to model the 64Kb-segment-size limit of far addressing on 80x86 machines.
 * On those machines, we expect that jconfig.h will provide a proper value.
 * On machines with 32-bit flat address spaces, any large constant may be used.
 *
 * NB: jmemmgr.c expects that MAX_ALLOC_CHUNK will be representable as type
 * size_t and will be a multiple of sizeof(align_type).
 */

#ifndef MAX_ALLOC_CHUNK		/* may be overridden in jconfig.h */
#define MAX_ALLOC_CHUNK  1000000000L
#endif

/*
 * This routine computes the total space still available for allocation by
 * jpeg_get_large.  If more space than this is needed, backing store will be
 * used.  NOTE: any memory already allocated must not be counted.
 *
 * There is a minimum space requirement, corresponding to the minimum
 * feasible buffer sizes; jmemmgr.c will request that much space even if
 * jpeg_mem_available returns zero.  The maximum space needed, enough to hold
 * all working storage in memory, is also passed in case it is useful.
 * Finally, the total space already allocated is passed.  If no better
 * method is available, cinfo->mem->max_memory_to_use - already_allocated
 * is often a suitable calculation.
 *
 * It is OK for jpeg_mem_available to underestimate the space available
 * (that'll just lead to more backing-store access than is really necessary).
 * However, an overestimate will lead to failure.  Hence it's wise to subtract
 * a slop factor from the true available space.  5% should be enough.
 *
 * On machines with lots of virtual memory, any large constant may be returned.
 * Conversely, zero may be returned to always use the minimum amount of memory.
 */

EXTERN(long) jpeg_mem_available JPP((j_common_ptr cinfo,
				     long min_bytes_needed,
				     long max_bytes_needed,
				     long already_allocated));


/*
 * This structure holds whatever state is needed to access a single
 * backing-store object.  The read/write/close method pointers are called
 * by jmemmgr.c to manipulate the backing-store object; all other fields
 * are private to the system-dependent backing store routines.
 */

#define TEMP_NAME_LENGTH   64	/* max length of a temporary file's name */


#ifdef USE_MSDOS_MEMMGR		/* DOS-specific junk */

typedef unsigned short XMSH;	/* type of extended-memory handles */
typedef unsigned short EMSH;	/* type of expanded-memory handles */

typedef union {
  short file_handle;		/* DOS file handle if it's a temp file */
  XMSH xms_handle;		/* handle if it's a chunk of XMS */
  EMSH ems_handle;		/* handle if it's a chunk of EMS */
} handle_union;

#endif /* USE_MSDOS_MEMMGR */

#ifdef USE_MAC_MEMMGR		/* Mac-specific junk */
#include <Files.h>
#endif /* USE_MAC_MEMMGR */


typedef struct backing_store_struct * backing_store_ptr;

typedef struct backing_store_struct {
  /* Methods for reading/writing/closing this backing-store object */
  JMETHOD(void, read_backing_store, (j_common_ptr cinfo,
				     backing_store_ptr info,
				     void FAR * buffer_address,
				     long file_offset, long byte_count));
  JMETHOD(void, write_backing_store, (j_common_ptr cinfo,
				      backing_store_ptr info,
				      void FAR * buffer_address,
				      long file_offset, long byte_count));
  JMETHOD(void, close_backing_store, (j_common_ptr cinfo,
				      backing_store_ptr info));

  /* Private fields for system-dependent backing-store management */
#ifdef USE_MSDOS_MEMMGR
  /* For the MS-DOS manager (jmemdos.c), we need: */
  handle_union handle;		/* reference to backing-store storage object */
  char temp_name[TEMP_NAME_LENGTH]; /* name if it's a file */
#else
#ifdef USE_MAC_MEMMGR
  /* For the Mac manager (jmemmac.c), we need: */
  short temp_file;		/* file reference number to temp file */
  FSSpec tempSpec;		/* the FSSpec for the temp file */
  char temp_name[TEMP_NAME_LENGTH]; /* name if it's a file */
#else
  /* For a typical implementation with temp files, we need: */
  FILE * temp_file;		/* stdio reference to temp file */
  char temp_name[TEMP_NAME_LENGTH]; /* name of temp file */
#endif
#endif
} backing_store_info;


/*
 * Initial opening of a backing-store object.  This must fill in the
 * read/write/close pointers in the object.  The read/write routines
 * may take an error exit if the specified maximum file size is exceeded.
 * (If jpeg_mem_available always returns a large value, this routine can
 * just take an error exit.)
 */

EXTERN(void) jpeg_open_backing_store JPP((j_common_ptr cinfo,
					  backing_store_ptr info,
					  long total_bytes_needed));


/*
 * These routines take care of any system-dependent initialization and
 * cleanup required.  jpeg_mem_init will be called before anything is
 * allocated (and, therefore, nothing in cinfo is of use except the error
 * manager pointer).  It should return a suitable default value for
 * max_memory_to_use; this may subsequently be overridden by the surrounding
 * application.  (Note that max_memory_to_use is only important if
 * jpeg_mem_available chooses to consult it ... no one else will.)
 * jpeg_mem_term may assume that all requested memory has been freed and that
 * all opened backing-store objects have been closed.
 */

EXTERN(long) jpeg_mem_init JPP((j_common_ptr cinfo));
EXTERN(void) jpeg_mem_term JPP((j_common_ptr cinfo));
