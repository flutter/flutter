/* -*- mode: C; c-file-style: "gnu" -*- */
/* xdgmimeglob.h: Private file.  Datastructure for storing the globs.
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

#ifndef __XDG_MIME_GLOB_H__
#define __XDG_MIME_GLOB_H__

#include "xdgmime.h"

typedef struct XdgGlobHash XdgGlobHash;

typedef enum
{
  XDG_GLOB_LITERAL, /* Makefile */
  XDG_GLOB_SIMPLE,  /* *.gif */
  XDG_GLOB_FULL     /* x*.[ch] */
} XdgGlobType;

  
#ifdef XDG_PREFIX
#define _xdg_mime_glob_read_from_file         XDG_RESERVED_ENTRY(glob_read_from_file)
#define _xdg_glob_hash_new                    XDG_RESERVED_ENTRY(hash_new)
#define _xdg_glob_hash_free                   XDG_RESERVED_ENTRY(hash_free)
#define _xdg_glob_hash_lookup_file_name       XDG_RESERVED_ENTRY(hash_lookup_file_name)
#define _xdg_glob_hash_append_glob            XDG_RESERVED_ENTRY(hash_append_glob)
#define _xdg_glob_determine_type              XDG_RESERVED_ENTRY(determine_type)
#define _xdg_glob_hash_dump                   XDG_RESERVED_ENTRY(hash_dump)
#endif

void         _xdg_mime_glob_read_from_file   (XdgGlobHash *glob_hash,
					      const char  *file_name,
					      int          version_two);
XdgGlobHash *_xdg_glob_hash_new              (void);
void         _xdg_glob_hash_free             (XdgGlobHash *glob_hash);
int          _xdg_glob_hash_lookup_file_name (XdgGlobHash *glob_hash,
					      const char  *text,
					      const char  *mime_types[],
					      int          n_mime_types);
void         _xdg_glob_hash_append_glob      (XdgGlobHash *glob_hash,
					      const char  *glob,
					      const char  *mime_type,
					      int          weight,
					      int          case_sensitive);
XdgGlobType  _xdg_glob_determine_type        (const char  *glob);
void         _xdg_glob_hash_dump             (XdgGlobHash *glob_hash);

#endif /* __XDG_MIME_GLOB_H__ */
