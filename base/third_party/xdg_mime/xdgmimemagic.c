/* -*- mode: C; c-file-style: "gnu" -*- */
/* xdgmimemagic.: Private file.  Datastructure for storing magic files.
 *
 * More info can be found at http://www.freedesktop.org/standards/
 *
 * Copyright (C) 2003  Red Hat, Inc.
 * Copyright (C) 2003  Jonathan Blandford <jrb@alum.mit.edu>
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

#include <assert.h>
#include "xdgmimemagic.h"
#include "xdgmimeint.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>

#ifndef	FALSE
#define	FALSE	(0)
#endif

#ifndef	TRUE
#define	TRUE	(!FALSE)
#endif

#if !defined getc_unlocked && !defined HAVE_GETC_UNLOCKED
# define getc_unlocked(fp) getc (fp)
#endif

typedef struct XdgMimeMagicMatch XdgMimeMagicMatch;
typedef struct XdgMimeMagicMatchlet XdgMimeMagicMatchlet;

typedef enum
{
  XDG_MIME_MAGIC_SECTION,
  XDG_MIME_MAGIC_MAGIC,
  XDG_MIME_MAGIC_ERROR,
  XDG_MIME_MAGIC_EOF
} XdgMimeMagicState;

struct XdgMimeMagicMatch
{
  const char *mime_type;
  int priority;
  XdgMimeMagicMatchlet *matchlet;
  XdgMimeMagicMatch *next;
};


struct XdgMimeMagicMatchlet
{
  int indent;
  int offset;
  unsigned int value_length;
  unsigned char *value;
  unsigned char *mask;
  unsigned int range_length;
  unsigned int word_size;
  XdgMimeMagicMatchlet *next;
};


struct XdgMimeMagic
{
  XdgMimeMagicMatch *match_list;
  int max_extent;
};

static XdgMimeMagicMatch *
_xdg_mime_magic_match_new (void)
{
  return calloc (1, sizeof (XdgMimeMagicMatch));
}


static XdgMimeMagicMatchlet *
_xdg_mime_magic_matchlet_new (void)
{
  XdgMimeMagicMatchlet *matchlet;

  matchlet = malloc (sizeof (XdgMimeMagicMatchlet));

  matchlet->indent = 0;
  matchlet->offset = 0;
  matchlet->value_length = 0;
  matchlet->value = NULL;
  matchlet->mask = NULL;
  matchlet->range_length = 1;
  matchlet->word_size = 1;
  matchlet->next = NULL;

  return matchlet;
}


static void
_xdg_mime_magic_matchlet_free (XdgMimeMagicMatchlet *mime_magic_matchlet)
{
  if (mime_magic_matchlet)
    {
      if (mime_magic_matchlet->next)
	_xdg_mime_magic_matchlet_free (mime_magic_matchlet->next);
      if (mime_magic_matchlet->value)
	free (mime_magic_matchlet->value);
      if (mime_magic_matchlet->mask)
	free (mime_magic_matchlet->mask);
      free (mime_magic_matchlet);
    }
}


/* Frees mime_magic_match and the remainder of its list
 */
static void
_xdg_mime_magic_match_free (XdgMimeMagicMatch *mime_magic_match)
{
  XdgMimeMagicMatch *ptr, *next;

  ptr = mime_magic_match;
  while (ptr)
    {
      next = ptr->next;

      if (ptr->mime_type)
	free ((void *) ptr->mime_type);
      if (ptr->matchlet)
	_xdg_mime_magic_matchlet_free (ptr->matchlet);
      free (ptr);

      ptr = next;
    }
}

/* Reads in a hunk of data until a newline character or a '\000' is hit.  The
 * returned string is null terminated, and doesn't include the newline.
 */
static unsigned char *
_xdg_mime_magic_read_to_newline (FILE *magic_file,
				 int  *end_of_file)
{
  unsigned char *retval;
  int c;
  int len, pos;

  len = 128;
  pos = 0;
  retval = malloc (len);
  *end_of_file = FALSE;

  while (TRUE)
    {
      c = getc_unlocked (magic_file);
      if (c == EOF)
	{
	  *end_of_file = TRUE;
	  break;
	}
      if (c == '\n' || c == '\000')
	break;
      retval[pos++] = (unsigned char) c;
      if (pos % 128 == 127)
	{
	  len = len + 128;
	  retval = realloc (retval, len);
	}
    }

  retval[pos] = '\000';
  return retval;
}

/* Returns the number read from the file, or -1 if no number could be read.
 */
static int
_xdg_mime_magic_read_a_number (FILE *magic_file,
			       int  *end_of_file)
{
  /* LONG_MAX is about 20 characters on my system */
#define MAX_NUMBER_SIZE 30
  char number_string[MAX_NUMBER_SIZE + 1];
  int pos = 0;
  int c;
  long retval = -1;

  while (TRUE)
    {
      c = getc_unlocked (magic_file);

      if (c == EOF)
	{
	  *end_of_file = TRUE;
	  break;
	}
      if (! isdigit (c))
	{
	  ungetc (c, magic_file);
	  break;
	}
      number_string[pos] = (char) c;
      pos++;
      if (pos == MAX_NUMBER_SIZE)
	break;
    }
  if (pos > 0)
    {
      number_string[pos] = '\000';
      errno = 0;
      retval = strtol (number_string, NULL, 10);

      if ((retval < INT_MIN) || (retval > INT_MAX) || (errno != 0))
	return -1;
    }

  return retval;
}

/* Headers are of the format:
 * [<priority>:<mime-type>]
 */
static XdgMimeMagicState
_xdg_mime_magic_parse_header (FILE *magic_file, XdgMimeMagicMatch *match)
{
  int c;
  char *buffer;
  char *end_ptr;
  int end_of_file = 0;

  assert (magic_file != NULL);
  assert (match != NULL);

  c = getc_unlocked (magic_file);
  if (c == EOF)
    return XDG_MIME_MAGIC_EOF;
  if (c != '[')
    return XDG_MIME_MAGIC_ERROR;

  match->priority = _xdg_mime_magic_read_a_number (magic_file, &end_of_file);
  if (end_of_file)
    return XDG_MIME_MAGIC_EOF;
  if (match->priority == -1)
    return XDG_MIME_MAGIC_ERROR;

  c = getc_unlocked (magic_file);
  if (c == EOF)
    return XDG_MIME_MAGIC_EOF;
  if (c != ':')
    return XDG_MIME_MAGIC_ERROR;

  buffer = (char *)_xdg_mime_magic_read_to_newline (magic_file, &end_of_file);
  if (end_of_file)
    return XDG_MIME_MAGIC_EOF;

  end_ptr = buffer;
  while (*end_ptr != ']' && *end_ptr != '\000' && *end_ptr != '\n')
    end_ptr++;
  if (*end_ptr != ']')
    {
      free (buffer);
      return XDG_MIME_MAGIC_ERROR;
    }
  *end_ptr = '\000';

  match->mime_type = strdup (buffer);
  free (buffer);

  return XDG_MIME_MAGIC_MAGIC;
}

static XdgMimeMagicState
_xdg_mime_magic_parse_error (FILE *magic_file)
{
  int c;

  while (1)
    {
      c = getc_unlocked (magic_file);
      if (c == EOF)
	return XDG_MIME_MAGIC_EOF;
      if (c == '\n')
	return XDG_MIME_MAGIC_SECTION;
    }
}

/* Headers are of the format:
 * [ indent ] ">" start-offset "=" value
 * [ "&" mask ] [ "~" word-size ] [ "+" range-length ] "\n"
 */
static XdgMimeMagicState
_xdg_mime_magic_parse_magic_line (FILE              *magic_file,
				  XdgMimeMagicMatch *match)
{
  XdgMimeMagicMatchlet *matchlet;
  int c;
  int end_of_file;
  int indent = 0;
  int bytes_read;

  assert (magic_file != NULL);

  /* Sniff the buffer to make sure it's a valid line */
  c = getc_unlocked (magic_file);
  if (c == EOF)
    return XDG_MIME_MAGIC_EOF;
  else if (c == '[')
    {
      ungetc (c, magic_file);
      return XDG_MIME_MAGIC_SECTION;
    }
  else if (c == '\n')
    return XDG_MIME_MAGIC_MAGIC;

  /* At this point, it must be a digit or a '>' */
  end_of_file = FALSE;
  if (isdigit (c))
    {
      ungetc (c, magic_file);
      indent = _xdg_mime_magic_read_a_number (magic_file, &end_of_file);
      if (end_of_file)
	return XDG_MIME_MAGIC_EOF;
      if (indent == -1)
	return XDG_MIME_MAGIC_ERROR;
      c = getc_unlocked (magic_file);
      if (c == EOF)
	return XDG_MIME_MAGIC_EOF;
    }

  if (c != '>')
    return XDG_MIME_MAGIC_ERROR;

  matchlet = _xdg_mime_magic_matchlet_new ();
  matchlet->indent = indent;
  matchlet->offset = _xdg_mime_magic_read_a_number (magic_file, &end_of_file);
  if (end_of_file)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_EOF;
    }
  if (matchlet->offset == -1)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_ERROR;
    }
  c = getc_unlocked (magic_file);
  if (c == EOF)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_EOF;
    }
  else if (c != '=')
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_ERROR;
    }

  /* Next two bytes determine how long the value is */
  matchlet->value_length = 0;
  c = getc_unlocked (magic_file);
  if (c == EOF)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_EOF;
    }
  matchlet->value_length = c & 0xFF;
  matchlet->value_length = matchlet->value_length << 8;

  c = getc_unlocked (magic_file);
  if (c == EOF)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_EOF;
    }
  matchlet->value_length = matchlet->value_length + (c & 0xFF);

  matchlet->value = malloc (matchlet->value_length);

  /* OOM */
  if (matchlet->value == NULL)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      return XDG_MIME_MAGIC_ERROR;
    }
  bytes_read = fread (matchlet->value, 1, matchlet->value_length, magic_file);
  if (bytes_read != matchlet->value_length)
    {
      _xdg_mime_magic_matchlet_free (matchlet);
      if (feof (magic_file))
	return XDG_MIME_MAGIC_EOF;
      else
	return XDG_MIME_MAGIC_ERROR;
    }

  c = getc_unlocked (magic_file);
  if (c == '&')
    {
      matchlet->mask = malloc (matchlet->value_length);
      /* OOM */
      if (matchlet->mask == NULL)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  return XDG_MIME_MAGIC_ERROR;
	}
      bytes_read = fread (matchlet->mask, 1, matchlet->value_length, magic_file);
      if (bytes_read != matchlet->value_length)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  if (feof (magic_file))
	    return XDG_MIME_MAGIC_EOF;
	  else
	    return XDG_MIME_MAGIC_ERROR;
	}
      c = getc_unlocked (magic_file);
    }

  if (c == '~')
    {
      matchlet->word_size = _xdg_mime_magic_read_a_number (magic_file, &end_of_file);
      if (end_of_file)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  return XDG_MIME_MAGIC_EOF;
	}
      if (matchlet->word_size != 0 &&
	  matchlet->word_size != 1 &&
	  matchlet->word_size != 2 &&
	  matchlet->word_size != 4)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  return XDG_MIME_MAGIC_ERROR;
	}
      c = getc_unlocked (magic_file);
    }

  if (c == '+')
    {
      matchlet->range_length = _xdg_mime_magic_read_a_number (magic_file, &end_of_file);
      if (end_of_file)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  return XDG_MIME_MAGIC_EOF;
	}
      if (matchlet->range_length == -1)
	{
	  _xdg_mime_magic_matchlet_free (matchlet);
	  return XDG_MIME_MAGIC_ERROR;
	}
      c = getc_unlocked (magic_file);
    }


  if (c == '\n')
    {
      /* We clean up the matchlet, byte swapping if needed */
      if (matchlet->word_size > 1)
	{
	  int i;
	  if (matchlet->value_length % matchlet->word_size != 0)
	    {
	      _xdg_mime_magic_matchlet_free (matchlet);
	      return XDG_MIME_MAGIC_ERROR;
	    }
	  /* FIXME: need to get this defined in a <config.h> style file */
#if LITTLE_ENDIAN
	  for (i = 0; i < matchlet->value_length; i = i + matchlet->word_size)
	    {
	      if (matchlet->word_size == 2)
		*((xdg_uint16_t *) matchlet->value + i) = SWAP_BE16_TO_LE16 (*((xdg_uint16_t *) (matchlet->value + i)));
	      else if (matchlet->word_size == 4)
		*((xdg_uint32_t *) matchlet->value + i) = SWAP_BE32_TO_LE32 (*((xdg_uint32_t *) (matchlet->value + i)));
	      if (matchlet->mask)
		{
		  if (matchlet->word_size == 2)
		    *((xdg_uint16_t *) matchlet->mask + i) = SWAP_BE16_TO_LE16 (*((xdg_uint16_t *) (matchlet->mask + i)));
		  else if (matchlet->word_size == 4)
		    *((xdg_uint32_t *) matchlet->mask + i) = SWAP_BE32_TO_LE32 (*((xdg_uint32_t *) (matchlet->mask + i)));

		}
	    }
#endif
	}

      matchlet->next = match->matchlet;
      match->matchlet = matchlet;


      return XDG_MIME_MAGIC_MAGIC;
    }

  _xdg_mime_magic_matchlet_free (matchlet);
  if (c == EOF)
    return XDG_MIME_MAGIC_EOF;

  return XDG_MIME_MAGIC_ERROR;
}

static int
_xdg_mime_magic_matchlet_compare_to_data (XdgMimeMagicMatchlet *matchlet,
					  const void           *data,
					  size_t                len)
{
  int i, j;
  for (i = matchlet->offset; i < matchlet->offset + matchlet->range_length; i++)
    {
      int valid_matchlet = TRUE;

      if (i + matchlet->value_length > len)
	return FALSE;

      if (matchlet->mask)
	{
	  for (j = 0; j < matchlet->value_length; j++)
	    {
	      if ((matchlet->value[j] & matchlet->mask[j]) !=
		  ((((unsigned char *) data)[j + i]) & matchlet->mask[j]))
		{
		  valid_matchlet = FALSE;
		  break;
		}
	    }
	}
      else
	{
	  for (j = 0; j <  matchlet->value_length; j++)
	    {
	      if (matchlet->value[j] != ((unsigned char *) data)[j + i])
		{
		  valid_matchlet = FALSE;
		  break;
		}
	    }
	}
      if (valid_matchlet)
	return TRUE;
    }
  return FALSE;
}

static int
_xdg_mime_magic_matchlet_compare_level (XdgMimeMagicMatchlet *matchlet,
					const void           *data,
					size_t                len,
					int                   indent)
{
  while ((matchlet != NULL) && (matchlet->indent == indent))
    {
      if (_xdg_mime_magic_matchlet_compare_to_data (matchlet, data, len))
	{
	  if ((matchlet->next == NULL) ||
	      (matchlet->next->indent <= indent))
	    return TRUE;

	  if (_xdg_mime_magic_matchlet_compare_level (matchlet->next,
						      data,
						      len,
						      indent + 1))
	    return TRUE;
	}

      do
	{
	  matchlet = matchlet->next;
	}
      while (matchlet && matchlet->indent > indent);
    }

  return FALSE;
}

static int
_xdg_mime_magic_match_compare_to_data (XdgMimeMagicMatch *match,
				       const void        *data,
				       size_t             len)
{
  return _xdg_mime_magic_matchlet_compare_level (match->matchlet, data, len, 0);
}

static void
_xdg_mime_magic_insert_match (XdgMimeMagic      *mime_magic,
			      XdgMimeMagicMatch *match)
{
  XdgMimeMagicMatch *list;

  if (mime_magic->match_list == NULL)
    {
      mime_magic->match_list = match;
      return;
    }

  if (match->priority > mime_magic->match_list->priority)
    {
      match->next = mime_magic->match_list;
      mime_magic->match_list = match;
      return;
    }

  list = mime_magic->match_list;
  while (list->next != NULL)
    {
      if (list->next->priority < match->priority)
	{
	  match->next = list->next;
	  list->next = match;
	  return;
	}
      list = list->next;
    }
  list->next = match;
  match->next = NULL;
}

XdgMimeMagic *
_xdg_mime_magic_new (void)
{
  return calloc (1, sizeof (XdgMimeMagic));
}

void
_xdg_mime_magic_free (XdgMimeMagic *mime_magic)
{
  if (mime_magic) {
    _xdg_mime_magic_match_free (mime_magic->match_list);
    free (mime_magic);
  }
}

int
_xdg_mime_magic_get_buffer_extents (XdgMimeMagic *mime_magic)
{
  return mime_magic->max_extent;
}

const char *
_xdg_mime_magic_lookup_data (XdgMimeMagic *mime_magic,
			     const void   *data,
			     size_t        len,
			     int           *result_prio,
                             const char   *mime_types[],
                             int           n_mime_types)
{
  XdgMimeMagicMatch *match;
  const char *mime_type;
  int n;
  int prio;

  prio = 0;
  mime_type = NULL;
  for (match = mime_magic->match_list; match; match = match->next)
    {
      if (_xdg_mime_magic_match_compare_to_data (match, data, len))
	{
	  prio = match->priority;
	  mime_type = match->mime_type;
	  break;
	}
      else 
	{
	  for (n = 0; n < n_mime_types; n++)
	    {
	      if (mime_types[n] && 
		  _xdg_mime_mime_type_equal (mime_types[n], match->mime_type))
		mime_types[n] = NULL;
	    }
	}
    }

  if (mime_type == NULL)
    {
      for (n = 0; n < n_mime_types; n++)
	{
	  if (mime_types[n])
	    mime_type = mime_types[n];
	}
    }
  
  if (result_prio)
    *result_prio = prio;

  return mime_type;
}

static void
_xdg_mime_update_mime_magic_extents (XdgMimeMagic *mime_magic)
{
  XdgMimeMagicMatch *match;
  int max_extent = 0;

  for (match = mime_magic->match_list; match; match = match->next)
    {
      XdgMimeMagicMatchlet *matchlet;

      for (matchlet = match->matchlet; matchlet; matchlet = matchlet->next)
	{
	  int extent;

	  extent = matchlet->value_length + matchlet->offset + matchlet->range_length;
	  if (max_extent < extent)
	    max_extent = extent;
	}
    }

  mime_magic->max_extent = max_extent;
}

static XdgMimeMagicMatchlet *
_xdg_mime_magic_matchlet_mirror (XdgMimeMagicMatchlet *matchlets)
{
  XdgMimeMagicMatchlet *new_list;
  XdgMimeMagicMatchlet *tmp;

  if ((matchlets == NULL) || (matchlets->next == NULL))
    return matchlets;

  new_list = NULL;
  tmp = matchlets;
  while (tmp != NULL)
    {
      XdgMimeMagicMatchlet *matchlet;

      matchlet = tmp;
      tmp = tmp->next;
      matchlet->next = new_list;
      new_list = matchlet;
    }

  return new_list;

}

static void
_xdg_mime_magic_read_magic_file (XdgMimeMagic *mime_magic,
				 FILE         *magic_file)
{
  XdgMimeMagicState state;
  XdgMimeMagicMatch *match = NULL; /* Quiet compiler */

  state = XDG_MIME_MAGIC_SECTION;

  while (state != XDG_MIME_MAGIC_EOF)
    {
      switch (state)
	{
	case XDG_MIME_MAGIC_SECTION:
	  match = _xdg_mime_magic_match_new ();
	  state = _xdg_mime_magic_parse_header (magic_file, match);
	  if (state == XDG_MIME_MAGIC_EOF || state == XDG_MIME_MAGIC_ERROR)
	    _xdg_mime_magic_match_free (match);
	  break;
	case XDG_MIME_MAGIC_MAGIC:
	  state = _xdg_mime_magic_parse_magic_line (magic_file, match);
	  if (state == XDG_MIME_MAGIC_SECTION ||
	      (state == XDG_MIME_MAGIC_EOF && match->mime_type))
	    {
	      match->matchlet = _xdg_mime_magic_matchlet_mirror (match->matchlet);
	      _xdg_mime_magic_insert_match (mime_magic, match);
	    }
	  else if (state == XDG_MIME_MAGIC_EOF || state == XDG_MIME_MAGIC_ERROR)
	    _xdg_mime_magic_match_free (match);
	  break;
	case XDG_MIME_MAGIC_ERROR:
	  state = _xdg_mime_magic_parse_error (magic_file);
	  break;
	case XDG_MIME_MAGIC_EOF:
	default:
	  /* Make the compiler happy */
	  assert (0);
	}
    }
  _xdg_mime_update_mime_magic_extents (mime_magic);
}

void
_xdg_mime_magic_read_from_file (XdgMimeMagic *mime_magic,
				const char   *file_name)
{
  FILE *magic_file;
  char header[12];

  magic_file = fopen (file_name, "r");

  if (magic_file == NULL)
    return;

  if (fread (header, 1, 12, magic_file) == 12)
    {
      if (memcmp ("MIME-Magic\0\n", header, 12) == 0)
        _xdg_mime_magic_read_magic_file (mime_magic, magic_file);
    }

  fclose (magic_file);
}
