/* -*- mode: C; c-file-style: "gnu" -*- */
/* xdgmimealias.c: Private file.  mmappable caches for mime data
 *
 * More info can be found at http://www.freedesktop.org/standards/
 *
 * Copyright (C) 2005  Matthias Clasen <mclasen@redhat.com>
 *
 * Licensed under the Academic Free License version 2.0
 * Or under the following terms:
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>
#include <fnmatch.h>
#include <assert.h>

#include <netinet/in.h> /* for ntohl/ntohs */

#define HAVE_MMAP 1

#ifdef HAVE_MMAP
#include <sys/mman.h>
#else
#warning Building xdgmime without MMAP support. Binary "mime.cache" files will not be used.
#endif

#include <sys/stat.h>
#include <sys/types.h>

#include "xdgmimecache.h"
#include "xdgmimeint.h"

#ifndef MAX
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#endif

#ifndef	FALSE
#define	FALSE	(0)
#endif

#ifndef	TRUE
#define	TRUE	(!FALSE)
#endif

#ifndef _O_BINARY
#define _O_BINARY 0
#endif

#ifndef MAP_FAILED
#define MAP_FAILED ((void *) -1)
#endif

#define MAJOR_VERSION 1
#define MINOR_VERSION_MIN 1
#define MINOR_VERSION_MAX 2

struct _XdgMimeCache
{
  int ref_count;
  int minor;

  size_t  size;
  char   *buffer;
};

#define GET_UINT16(cache,offset) (ntohs(*(xdg_uint16_t*)((cache) + (offset))))
#define GET_UINT32(cache,offset) (ntohl(*(xdg_uint32_t*)((cache) + (offset))))

XdgMimeCache *
_xdg_mime_cache_ref (XdgMimeCache *cache)
{
  cache->ref_count++;
  return cache;
}

void
_xdg_mime_cache_unref (XdgMimeCache *cache)
{
  cache->ref_count--;

  if (cache->ref_count == 0)
    {
#ifdef HAVE_MMAP
      munmap (cache->buffer, cache->size);
#endif
      free (cache);
    }
}

XdgMimeCache *
_xdg_mime_cache_new_from_file (const char *file_name)
{
  XdgMimeCache *cache = NULL;

#ifdef HAVE_MMAP
  int fd = -1;
  struct stat st;
  char *buffer = NULL;
  int minor;

  /* Open the file and map it into memory */
  fd = open (file_name, O_RDONLY|_O_BINARY, 0);

  if (fd < 0)
    return NULL;
  
  if (fstat (fd, &st) < 0 || st.st_size < 4)
    goto done;

  buffer = (char *) mmap (NULL, st.st_size, PROT_READ, MAP_SHARED, fd, 0);

  if (buffer == MAP_FAILED)
    goto done;

  minor = GET_UINT16 (buffer, 2);
  /* Verify version */
  if (GET_UINT16 (buffer, 0) != MAJOR_VERSION ||
      (minor < MINOR_VERSION_MIN ||
       minor > MINOR_VERSION_MAX))
    {
      munmap (buffer, st.st_size);

      goto done;
    }
  
  cache = (XdgMimeCache *) malloc (sizeof (XdgMimeCache));
  cache->minor = minor;
  cache->ref_count = 1;
  cache->buffer = buffer;
  cache->size = st.st_size;

 done:
  if (fd != -1)
    close (fd);

#endif  /* HAVE_MMAP */

  return cache;
}

static int
cache_magic_matchlet_compare_to_data (XdgMimeCache *cache, 
				      xdg_uint32_t  offset,
				      const void   *data,
				      size_t        len)
{
  xdg_uint32_t range_start = GET_UINT32 (cache->buffer, offset);
  xdg_uint32_t range_length = GET_UINT32 (cache->buffer, offset + 4);
  xdg_uint32_t data_length = GET_UINT32 (cache->buffer, offset + 12);
  xdg_uint32_t data_offset = GET_UINT32 (cache->buffer, offset + 16);
  xdg_uint32_t mask_offset = GET_UINT32 (cache->buffer, offset + 20);
  
  int i, j;

  for (i = range_start; i < range_start + range_length; i++)
    {
      int valid_matchlet = TRUE;
      
      if (i + data_length > len)
	return FALSE;

      if (mask_offset)
	{
	  for (j = 0; j < data_length; j++)
	    {
	      if ((((unsigned char *)cache->buffer)[data_offset + j] & ((unsigned char *)cache->buffer)[mask_offset + j]) !=
		  ((((unsigned char *) data)[j + i]) & ((unsigned char *)cache->buffer)[mask_offset + j]))
		{
		  valid_matchlet = FALSE;
		  break;
		}
	    }
	}
      else
	{
	  valid_matchlet = memcmp(cache->buffer + data_offset, data + i, data_length) == 0;
	}

      if (valid_matchlet)
	return TRUE;
    }
  
  return FALSE;  
}

static int
cache_magic_matchlet_compare (XdgMimeCache *cache, 
			      xdg_uint32_t  offset,
			      const void   *data,
			      size_t        len)
{
  xdg_uint32_t n_children = GET_UINT32 (cache->buffer, offset + 24);
  xdg_uint32_t child_offset = GET_UINT32 (cache->buffer, offset + 28);

  int i;
  
  if (cache_magic_matchlet_compare_to_data (cache, offset, data, len))
    {
      if (n_children == 0)
	return TRUE;
      
      for (i = 0; i < n_children; i++)
	{
	  if (cache_magic_matchlet_compare (cache, child_offset + 32 * i,
					    data, len))
	    return TRUE;
	}
    }
  
  return FALSE;  
}

static const char *
cache_magic_compare_to_data (XdgMimeCache *cache, 
			     xdg_uint32_t  offset,
			     const void   *data, 
			     size_t        len, 
			     int          *prio)
{
  xdg_uint32_t priority = GET_UINT32 (cache->buffer, offset);
  xdg_uint32_t mimetype_offset = GET_UINT32 (cache->buffer, offset + 4);
  xdg_uint32_t n_matchlets = GET_UINT32 (cache->buffer, offset + 8);
  xdg_uint32_t matchlet_offset = GET_UINT32 (cache->buffer, offset + 12);

  int i;

  for (i = 0; i < n_matchlets; i++)
    {
      if (cache_magic_matchlet_compare (cache, matchlet_offset + i * 32, 
					data, len))
	{
	  *prio = priority;
	  
	  return cache->buffer + mimetype_offset;
	}
    }

  return NULL;
}

static const char *
cache_magic_lookup_data (XdgMimeCache *cache, 
			 const void   *data, 
			 size_t        len, 
			 int          *prio,
			 const char   *mime_types[],
			 int           n_mime_types)
{
  xdg_uint32_t list_offset;
  xdg_uint32_t n_entries;
  xdg_uint32_t offset;

  int j, n;

  *prio = 0;

  list_offset = GET_UINT32 (cache->buffer, 24);
  n_entries = GET_UINT32 (cache->buffer, list_offset);
  offset = GET_UINT32 (cache->buffer, list_offset + 8);
  
  for (j = 0; j < n_entries; j++)
    {
      const char *match;

      match = cache_magic_compare_to_data (cache, offset + 16 * j, 
					   data, len, prio);
      if (match)
	return match;
      else
	{
	  xdg_uint32_t mimetype_offset;
	  const char *non_match;
	  
	  mimetype_offset = GET_UINT32 (cache->buffer, offset + 16 * j + 4);
	  non_match = cache->buffer + mimetype_offset;

	  for (n = 0; n < n_mime_types; n++)
	    {
	      if (mime_types[n] && 
		  _xdg_mime_mime_type_equal (mime_types[n], non_match))
		mime_types[n] = NULL;
	    }
	}
    }

  return NULL;
}

static const char *
cache_alias_lookup (const char *alias)
{
  const char *ptr;
  int i, min, max, mid, cmp;

  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];
      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 4);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);
      xdg_uint32_t offset;

      min = 0; 
      max = n_entries - 1;
      while (max >= min) 
	{
	  mid = (min + max) / 2;

	  offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * mid);
	  ptr = cache->buffer + offset;
	  cmp = strcmp (ptr, alias);
	  
	  if (cmp < 0)
	    min = mid + 1;
	  else if (cmp > 0)
	    max = mid - 1;
	  else
	    {
	      offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * mid + 4);
	      return cache->buffer + offset;
	    }
	}
    }

  return NULL;
}

typedef struct {
  const char *mime;
  int weight;
} MimeWeight;

static int
cache_glob_lookup_literal (const char *file_name,
			   const char *mime_types[],
			   int         n_mime_types,
			   int         case_sensitive_check)
{
  const char *ptr;
  int i, min, max, mid, cmp;

  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];
      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 12);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);
      xdg_uint32_t offset;

      min = 0; 
      max = n_entries - 1;
      while (max >= min) 
	{
	  mid = (min + max) / 2;

	  offset = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * mid);
	  ptr = cache->buffer + offset;
	  cmp = strcmp (ptr, file_name);

	  if (cmp < 0)
	    min = mid + 1;
	  else if (cmp > 0)
	    max = mid - 1;
	  else
	    {
	      int weight = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * mid + 8);
	      int case_sensitive = weight & 0x100;
	      weight = weight & 0xff;

	      if (case_sensitive_check || !case_sensitive)
		{
		  offset = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * mid + 4);
		  mime_types[0] = (const char *)(cache->buffer + offset);

		  return 1;
		}
	      return 0;
	    }
	}
    }

  return 0;
}

static int
cache_glob_lookup_fnmatch (const char *file_name,
			   MimeWeight  mime_types[],
			   int         n_mime_types,
			   int         case_sensitive_check)
{
  const char *mime_type;
  const char *ptr;

  int i, j, n;

  n = 0;
  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];

      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 20);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);

      for (j = 0; j < n_entries && n < n_mime_types; j++)
	{
	  xdg_uint32_t offset = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * j);
	  xdg_uint32_t mimetype_offset = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * j + 4);
	  int weight = GET_UINT32 (cache->buffer, list_offset + 4 + 12 * j + 8);
	  int case_sensitive = weight & 0x100;
	  weight = weight & 0xff;
	  ptr = cache->buffer + offset;
	  mime_type = cache->buffer + mimetype_offset;
	  if (case_sensitive_check || !case_sensitive)
	    {
	      /* FIXME: Not UTF-8 safe */
	      if (fnmatch (ptr, file_name, 0) == 0)
	        {
	          mime_types[n].mime = mime_type;
	          mime_types[n].weight = weight;
	          n++;
	        }
	    }
	}

      if (n > 0)
	return n;
    }
  
  return 0;
}

static int
cache_glob_node_lookup_suffix (XdgMimeCache  *cache,
			       xdg_uint32_t   n_entries,
			       xdg_uint32_t   offset,
			       const char    *file_name,
			       int            len,
			       int            case_sensitive_check,
			       MimeWeight     mime_types[],
			       int            n_mime_types)
{
  xdg_unichar_t character;
  xdg_unichar_t match_char;
  xdg_uint32_t mimetype_offset;
  xdg_uint32_t n_children;
  xdg_uint32_t child_offset; 
  int weight;
  int case_sensitive;

  int min, max, mid, n, i;

  character = file_name[len - 1];

  assert (character != 0);

  min = 0;
  max = n_entries - 1;
  while (max >= min)
    {
      mid = (min + max) /  2;
      match_char = GET_UINT32 (cache->buffer, offset + 12 * mid);
      if (match_char < character)
	min = mid + 1;
      else if (match_char > character)
	max = mid - 1;
      else 
	{
          len--;
          n = 0;
          n_children = GET_UINT32 (cache->buffer, offset + 12 * mid + 4);
          child_offset = GET_UINT32 (cache->buffer, offset + 12 * mid + 8);
      
          if (len > 0)
            {
              n = cache_glob_node_lookup_suffix (cache, 
                                                 n_children, child_offset,
                                                 file_name, len, 
                                                 case_sensitive_check,
                                                 mime_types,
                                                 n_mime_types);
            }
          if (n == 0)
            {
	      i = 0;
	      while (n < n_mime_types && i < n_children)
		{
		  match_char = GET_UINT32 (cache->buffer, child_offset + 12 * i);
		  if (match_char != 0)
		    break;

		  mimetype_offset = GET_UINT32 (cache->buffer, child_offset + 12 * i + 4);
		  weight = GET_UINT32 (cache->buffer, child_offset + 12 * i + 8);
		  case_sensitive = weight & 0x100;
		  weight = weight & 0xff;

		  if (case_sensitive_check || !case_sensitive)
		    {
		      mime_types[n].mime = cache->buffer + mimetype_offset;
		      mime_types[n].weight = weight;
		      n++;
		    }
		  i++;
		}
	    }
	  return n;
	}
    }
  return 0;
}

static int
cache_glob_lookup_suffix (const char *file_name,
			  int         len,
			  int         ignore_case,
			  MimeWeight  mime_types[],
			  int         n_mime_types)
{
  int i, n;

  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];

      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 16);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);
      xdg_uint32_t offset = GET_UINT32 (cache->buffer, list_offset + 4);

      n = cache_glob_node_lookup_suffix (cache, 
					 n_entries, offset, 
					 file_name, len,
					 ignore_case,
					 mime_types,
					 n_mime_types);
      if (n > 0)
	return n;
    }

  return 0;
}

static int compare_mime_weight (const void *a, const void *b)
{
  const MimeWeight *aa = (const MimeWeight *)a;
  const MimeWeight *bb = (const MimeWeight *)b;

  return bb->weight - aa->weight;
}

#define ISUPPER(c)		((c) >= 'A' && (c) <= 'Z')
static char *
ascii_tolower (const char *str)
{
  char *p, *lower;

  lower = strdup (str);
  p = lower;
  while (*p != 0)
    {
      char c = *p;
      *p++ = ISUPPER (c) ? c - 'A' + 'a' : c;
    }
  return lower;
}

static int
cache_glob_lookup_file_name (const char *file_name, 
			     const char *mime_types[],
			     int         n_mime_types)
{
  int n;
  MimeWeight mimes[10];
  int n_mimes = 10;
  int i;
  int len;
  char *lower_case;

  assert (file_name != NULL && n_mime_types > 0);

  /* First, check the literals */

  lower_case = ascii_tolower (file_name);

  n = cache_glob_lookup_literal (lower_case, mime_types, n_mime_types, FALSE);
  if (n > 0)
    {
      free (lower_case);
      return n;
    }

  n = cache_glob_lookup_literal (file_name, mime_types, n_mime_types, TRUE);
  if (n > 0)
    {
      free (lower_case);
      return n;
    }

  len = strlen (file_name);
  n = cache_glob_lookup_suffix (lower_case, len, FALSE, mimes, n_mimes);
  if (n == 0)
    n = cache_glob_lookup_suffix (file_name, len, TRUE, mimes, n_mimes);

  /* Last, try fnmatch */
  if (n == 0)
    n = cache_glob_lookup_fnmatch (lower_case, mimes, n_mimes, FALSE);
  if (n == 0)
    n = cache_glob_lookup_fnmatch (file_name, mimes, n_mimes, TRUE);

  free (lower_case);

  qsort (mimes, n, sizeof (MimeWeight), compare_mime_weight);

  if (n_mime_types < n)
    n = n_mime_types;

  for (i = 0; i < n; i++)
    mime_types[i] = mimes[i].mime;

  return n;
}

int
_xdg_mime_cache_get_max_buffer_extents (void)
{
  xdg_uint32_t offset;
  xdg_uint32_t max_extent;
  int i;

  max_extent = 0;
  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];

      offset = GET_UINT32 (cache->buffer, 24);
      max_extent = MAX (max_extent, GET_UINT32 (cache->buffer, offset + 4));
    }

  return max_extent;
}

static const char *
cache_get_mime_type_for_data (const void *data,
			      size_t      len,
			      int        *result_prio,
			      const char *mime_types[],
			      int         n_mime_types)
{
  const char *mime_type;
  int i, n, priority;

  priority = 0;
  mime_type = NULL;
  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];

      int prio;
      const char *match;

      match = cache_magic_lookup_data (cache, data, len, &prio, 
				       mime_types, n_mime_types);
      if (prio > priority)
	{
	  priority = prio;
	  mime_type = match;
	}
    }

  if (result_prio)
    *result_prio = priority;

  if (priority > 0)
    {
      /* Pick glob-result R where mime_type inherits from R */
      for (n = 0; n < n_mime_types; n++)
        {
          if (mime_types[n] && _xdg_mime_cache_mime_type_subclass(mime_types[n], mime_type))
              return mime_types[n];
        }

      /* Return magic match */
      return mime_type;
    }

  /* Pick first glob result, as fallback */
  for (n = 0; n < n_mime_types; n++)
    {
      if (mime_types[n])
        return mime_types[n];
    }

  return NULL;
}

const char *
_xdg_mime_cache_get_mime_type_for_data (const void *data,
					size_t      len,
					int        *result_prio)
{
  return cache_get_mime_type_for_data (data, len, result_prio, NULL, 0);
}

const char *
_xdg_mime_cache_get_mime_type_for_file (const char  *file_name,
					struct stat *statbuf)
{
  const char *mime_type;
  const char *mime_types[10];
  FILE *file;
  unsigned char *data;
  int max_extent;
  int bytes_read;
  struct stat buf;
  const char *base_name;
  int n;

  if (file_name == NULL)
    return NULL;

  if (! _xdg_utf8_validate (file_name))
    return NULL;

  base_name = _xdg_get_base_name (file_name);
  n = cache_glob_lookup_file_name (base_name, mime_types, 10);

  if (n == 1)
    return mime_types[0];

  if (!statbuf)
    {
      if (stat (file_name, &buf) != 0)
	return XDG_MIME_TYPE_UNKNOWN;

      statbuf = &buf;
    }

  if (statbuf->st_size == 0)
    return XDG_MIME_TYPE_EMPTY;

  if (!S_ISREG (statbuf->st_mode))
    return XDG_MIME_TYPE_UNKNOWN;

  /* FIXME: Need to make sure that max_extent isn't totally broken.  This could
   * be large and need getting from a stream instead of just reading it all
   * in. */
  max_extent = _xdg_mime_cache_get_max_buffer_extents ();
  data = malloc (max_extent);
  if (data == NULL)
    return XDG_MIME_TYPE_UNKNOWN;
        
  file = fopen (file_name, "r");
  if (file == NULL)
    {
      free (data);
      return XDG_MIME_TYPE_UNKNOWN;
    }

  bytes_read = fread (data, 1, max_extent, file);
  if (ferror (file))
    {
      free (data);
      fclose (file);
      return XDG_MIME_TYPE_UNKNOWN;
    }

  mime_type = cache_get_mime_type_for_data (data, bytes_read, NULL,
					    mime_types, n);

  if (!mime_type)
    mime_type = _xdg_binary_or_text_fallback(data, bytes_read);

  free (data);
  fclose (file);

  return mime_type;
}

const char *
_xdg_mime_cache_get_mime_type_from_file_name (const char *file_name)
{
  const char *mime_type;

  if (cache_glob_lookup_file_name (file_name, &mime_type, 1))
    return mime_type;
  else
    return XDG_MIME_TYPE_UNKNOWN;
}

int
_xdg_mime_cache_get_mime_types_from_file_name (const char *file_name,
					       const char  *mime_types[],
					       int          n_mime_types)
{
  return cache_glob_lookup_file_name (file_name, mime_types, n_mime_types);
}

#if 1
static int
is_super_type (const char *mime)
{
  int length;
  const char *type;

  length = strlen (mime);
  type = &(mime[length - 2]);

  if (strcmp (type, "/*") == 0)
    return 1;

  return 0;
}
#endif

int
_xdg_mime_cache_mime_type_subclass (const char *mime,
				    const char *base)
{
  const char *umime, *ubase;

  int i, j, min, max, med, cmp;
  
  umime = _xdg_mime_cache_unalias_mime_type (mime);
  ubase = _xdg_mime_cache_unalias_mime_type (base);

  if (strcmp (umime, ubase) == 0)
    return 1;

  /* We really want to handle text/ * in GtkFileFilter, so we just
   * turn on the supertype matching
   */
#if 1
  /* Handle supertypes */
  if (is_super_type (ubase) &&
      xdg_mime_media_type_equal (umime, ubase))
    return 1;
#endif

  /*  Handle special cases text/plain and application/octet-stream */
  if (strcmp (ubase, "text/plain") == 0 && 
      strncmp (umime, "text/", 5) == 0)
    return 1;

  if (strcmp (ubase, "application/octet-stream") == 0)
    return 1;
 
  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];
      
      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 8);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);
      xdg_uint32_t offset, n_parents, parent_offset;

      min = 0; 
      max = n_entries - 1;
      while (max >= min)
	{
	  med = (min + max)/2;
	  
	  offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * med);
	  cmp = strcmp (cache->buffer + offset, umime);
	  if (cmp < 0)
	    min = med + 1;
	  else if (cmp > 0)
	    max = med - 1;
	  else
	    {
	      offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * med + 4);
	      n_parents = GET_UINT32 (cache->buffer, offset);
	      
	      for (j = 0; j < n_parents; j++)
		{
		  parent_offset = GET_UINT32 (cache->buffer, offset + 4 + 4 * j);
		  if (_xdg_mime_cache_mime_type_subclass (cache->buffer + parent_offset, ubase))
		    return 1;
		}

	      break;
	    }
	}
    }

  return 0;
}

const char *
_xdg_mime_cache_unalias_mime_type (const char *mime)
{
  const char *lookup;
  
  lookup = cache_alias_lookup (mime);
  
  if (lookup)
    return lookup;
  
  return mime;  
}

char **
_xdg_mime_cache_list_mime_parents (const char *mime)
{
  int i, j, k, l, p;
  char *all_parents[128]; /* we'll stop at 128 */ 
  char **result;

  mime = xdg_mime_unalias_mime_type (mime);

  p = 0;
  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];
  
      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, 8);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);

      for (j = 0; j < n_entries; j++)
	{
	  xdg_uint32_t mimetype_offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * j);
	  xdg_uint32_t parents_offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * j + 4);

	  if (strcmp (cache->buffer + mimetype_offset, mime) == 0)
	    {
	      xdg_uint32_t parent_mime_offset;
	      xdg_uint32_t n_parents = GET_UINT32 (cache->buffer, parents_offset);

	      for (k = 0; k < n_parents && p < 127; k++)
		{
		  parent_mime_offset = GET_UINT32 (cache->buffer, parents_offset + 4 + 4 * k);

		  /* Don't add same parent multiple times.
		   * This can happen for instance if the same type is listed in multiple directories
		   */
		  for (l = 0; l < p; l++)
		    {
		      if (strcmp (all_parents[l], cache->buffer + parent_mime_offset) == 0)
			break;
		    }

		  if (l == p)
		    all_parents[p++] = cache->buffer + parent_mime_offset;
		}

	      break;
	    }
	}
    }
  all_parents[p++] = NULL;
  
  result = (char **) malloc (p * sizeof (char *));
  memcpy (result, all_parents, p * sizeof (char *));

  return result;
}

static const char *
cache_lookup_icon (const char *mime, int header)
{
  const char *ptr;
  int i, min, max, mid, cmp;

  for (i = 0; _caches[i]; i++)
    {
      XdgMimeCache *cache = _caches[i];
      xdg_uint32_t list_offset = GET_UINT32 (cache->buffer, header);
      xdg_uint32_t n_entries = GET_UINT32 (cache->buffer, list_offset);
      xdg_uint32_t offset;

      min = 0; 
      max = n_entries - 1;
      while (max >= min) 
        {
          mid = (min + max) / 2;

          offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * mid);
          ptr = cache->buffer + offset;
          cmp = strcmp (ptr, mime);
         
          if (cmp < 0)
            min = mid + 1;
          else if (cmp > 0)
            max = mid - 1;
          else
            {
              offset = GET_UINT32 (cache->buffer, list_offset + 4 + 8 * mid + 4);
              return cache->buffer + offset;
            }
        }
    }

  return NULL;
}

const char *
_xdg_mime_cache_get_generic_icon (const char *mime)
{
  return cache_lookup_icon (mime, 36);
}

const char *
_xdg_mime_cache_get_icon (const char *mime)
{
  return cache_lookup_icon (mime, 32);
}

static void
dump_glob_node (XdgMimeCache *cache,
		xdg_uint32_t  offset,
		int           depth)
{
  xdg_unichar_t character;
  xdg_uint32_t mime_offset;
  xdg_uint32_t n_children;
  xdg_uint32_t child_offset;
  int i;

  character = GET_UINT32 (cache->buffer, offset);
  mime_offset = GET_UINT32 (cache->buffer, offset + 4);
  n_children = GET_UINT32 (cache->buffer, offset + 8);
  child_offset = GET_UINT32 (cache->buffer, offset + 12);
  for (i = 0; i < depth; i++)
    printf (" ");
  printf ("%c", character);
  if (mime_offset)
    printf (" - %s", cache->buffer + mime_offset);
  printf ("\n");
  if (child_offset)
  {
    for (i = 0; i < n_children; i++)
      dump_glob_node (cache, child_offset + 20 * i, depth + 1);
  }
}

void
_xdg_mime_cache_glob_dump (void)
{
  int i, j;
  for (i = 0; _caches[i]; i++)
  {
    XdgMimeCache *cache = _caches[i];
    xdg_uint32_t list_offset;
    xdg_uint32_t n_entries;
    xdg_uint32_t offset;
    list_offset = GET_UINT32 (cache->buffer, 16);
    n_entries = GET_UINT32 (cache->buffer, list_offset);
    offset = GET_UINT32 (cache->buffer, list_offset + 4);
    for (j = 0; j < n_entries; j++)
	    dump_glob_node (cache, offset + 20 * j, 0);
  }
}
