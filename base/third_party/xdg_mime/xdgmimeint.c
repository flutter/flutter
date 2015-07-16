/* -*- mode: C; c-file-style: "gnu" -*- */
/* xdgmimeint.c: Internal defines and functions.
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

#include "xdgmimeint.h"
#include <ctype.h>
#include <string.h>

#ifndef	FALSE
#define	FALSE	(0)
#endif

#ifndef	TRUE
#define	TRUE	(!FALSE)
#endif

static const char _xdg_utf8_skip_data[256] = {
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,6,6,1,1
};

const char * const _xdg_utf8_skip = _xdg_utf8_skip_data;



/* Returns the number of unprocessed characters. */
xdg_unichar_t
_xdg_utf8_to_ucs4(const char *source)
{
  xdg_unichar_t ucs32;
  if( ! ( *source & 0x80 ) )
    {
      ucs32 = *source;
    }
  else
    {
      int bytelength = 0;
      xdg_unichar_t result;
      if ( ! (*source & 0x40) )
	{
	  ucs32 = *source;
	}
      else
	{
	  if ( ! (*source & 0x20) )
	    {
	      result = *source++ & 0x1F;
	      bytelength = 2;
	    }
	  else if ( ! (*source & 0x10) )
	    {
	      result = *source++ & 0x0F;
	      bytelength = 3;
	    }
	  else if ( ! (*source & 0x08) )
	    {
	      result = *source++ & 0x07;
	      bytelength = 4;
	    }
	  else if ( ! (*source & 0x04) )
	    {
	      result = *source++ & 0x03;
	      bytelength = 5;
	    }
	  else if ( ! (*source & 0x02) )
	    {
	      result = *source++ & 0x01;
	      bytelength = 6;
	    }
	  else
	    {
	      result = *source++;
	      bytelength = 1;
	    }

	  for ( bytelength --; bytelength > 0; bytelength -- )
	    {
	      result <<= 6;
	      result |= *source++ & 0x3F;
	    }
	  ucs32 = result;
	}
    }
  return ucs32;
}


/* hullo.  this is great code.  don't rewrite it */

xdg_unichar_t
_xdg_ucs4_to_lower (xdg_unichar_t source)
{
  /* FIXME: Do a real to_upper sometime */
  /* CaseFolding-3.2.0.txt has a table of rules. */
  if ((source & 0xFF) == source)
    return (xdg_unichar_t) tolower ((unsigned char) source);
  return source;
}

int
_xdg_utf8_validate (const char *source)
{
  /* FIXME: actually write */
  return TRUE;
}

const char *
_xdg_get_base_name (const char *file_name)
{
  const char *base_name;

  if (file_name == NULL)
    return NULL;

  base_name = strrchr (file_name, '/');

  if (base_name == NULL)
    return file_name;
  else
    return base_name + 1;
}

xdg_unichar_t *
_xdg_convert_to_ucs4 (const char *source, int *len)
{
  xdg_unichar_t *out;
  int i;
  const char *p;

  out = malloc (sizeof (xdg_unichar_t) * (strlen (source) + 1));

  p = source;
  i = 0;
  while (*p) 
    {
      out[i++] = _xdg_utf8_to_ucs4 (p);
      p = _xdg_utf8_next_char (p); 
    }
  out[i] = 0;
  *len = i;
 
  return out;
}

void
_xdg_reverse_ucs4 (xdg_unichar_t *source, int len)
{
  xdg_unichar_t c;
  int i;

  for (i = 0; i < len - i - 1; i++) 
    {
      c = source[i]; 
      source[i] = source[len - i - 1];
      source[len - i - 1] = c;
    }
}

const char *
_xdg_binary_or_text_fallback(const void *data, size_t len)
{
  unsigned char *chardata;
  int i;

  chardata = (unsigned char *) data;
  for (i = 0; i < 32 && i < len; ++i)
    {
       if (chardata[i] < 32 && chardata[i] != 9 && chardata[i] != 10 && chardata[i] != 13)
         return XDG_MIME_TYPE_UNKNOWN; /* binary data */
    }

  return XDG_MIME_TYPE_TEXTPLAIN;
}
