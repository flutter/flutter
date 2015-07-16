/* -*- mode: C; c-file-style: "gnu" -*- */
/* xdgmimeint.h: Internal defines and functions.
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

#ifndef __XDG_MIME_INT_H__
#define __XDG_MIME_INT_H__

#include "xdgmime.h"


#ifndef	FALSE
#define	FALSE (0)
#endif

#ifndef	TRUE
#define	TRUE (!FALSE)
#endif

/* FIXME: Needs to be configure check */
typedef unsigned int   xdg_unichar_t;
typedef unsigned char  xdg_uchar8_t;
typedef unsigned short xdg_uint16_t;
typedef unsigned int   xdg_uint32_t;

#ifdef XDG_PREFIX
#define _xdg_utf8_skip       XDG_RESERVED_ENTRY(utf8_skip)
#define _xdg_utf8_to_ucs4    XDG_RESERVED_ENTRY(utf8_to_ucs4)
#define _xdg_ucs4_to_lower   XDG_RESERVED_ENTRY(ucs4_to_lower)
#define _xdg_utf8_validate   XDG_RESERVED_ENTRY(utf8_validate)
#define _xdg_get_base_name   XDG_RESERVED_ENTRY(get_base_name)
#define _xdg_convert_to_ucs4 XDG_RESERVED_ENTRY(convert_to_ucs4)
#define _xdg_reverse_ucs4    XDG_RESERVED_ENTRY(reverse_ucs4)
#endif

#define SWAP_BE16_TO_LE16(val) (xdg_uint16_t)(((xdg_uint16_t)(val) << 8)|((xdg_uint16_t)(val) >> 8))

#define SWAP_BE32_TO_LE32(val) (xdg_uint32_t)((((xdg_uint32_t)(val) & 0xFF000000U) >> 24) |	\
					      (((xdg_uint32_t)(val) & 0x00FF0000U) >> 8) |	\
					      (((xdg_uint32_t)(val) & 0x0000FF00U) << 8) |	\
					      (((xdg_uint32_t)(val) & 0x000000FFU) << 24))
/* UTF-8 utils
 */
extern const char *const _xdg_utf8_skip;
#define _xdg_utf8_next_char(p) (char *)((p) + _xdg_utf8_skip[*(unsigned char *)(p)])
#define _xdg_utf8_char_size(p) (int) (_xdg_utf8_skip[*(unsigned char *)(p)])

xdg_unichar_t  _xdg_utf8_to_ucs4  (const char    *source);
xdg_unichar_t  _xdg_ucs4_to_lower (xdg_unichar_t  source);
int            _xdg_utf8_validate (const char    *source);
xdg_unichar_t *_xdg_convert_to_ucs4 (const char *source, int *len);
void           _xdg_reverse_ucs4 (xdg_unichar_t *source, int len);
const char    *_xdg_get_base_name (const char    *file_name);
const char    *_xdg_binary_or_text_fallback(const void *data, size_t len);

#endif /* __XDG_MIME_INT_H__ */
