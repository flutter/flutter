/* -*- Mode: C; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is mozilla.org code.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

/*
 * jconfig.h to configure the IJG JPEG library for the Mozilla/Netscape
 * environment.  Note that there are also Mozilla mods in jmorecfg.h.
 */

/* We assume an ANSI C or C++ compilation environment */
#define HAVE_PROTOTYPES 
#define HAVE_UNSIGNED_CHAR 
#define HAVE_UNSIGNED_SHORT 
/* #define void char */
/* #define const */
#ifndef HAVE_STDDEF_H 
#define HAVE_STDDEF_H 
#endif /* HAVE_STDDEF_H */
#ifndef HAVE_STDLIB_H
#define HAVE_STDLIB_H 
#endif /* HAVE_STDLIB_H */
#undef NEED_BSD_STRINGS
#undef NEED_SYS_TYPES_H
#undef NEED_FAR_POINTERS
#undef NEED_SHORT_EXTERNAL_NAMES
/* Define this if you get warnings about undefined structures. */
#undef INCOMPLETE_TYPES_BROKEN

/* With this setting, the IJG code will work regardless of whether
 * type "char" is signed or unsigned.
 */
#undef CHAR_IS_UNSIGNED


/* defines that need not be visible to callers of the IJG library */

#ifdef JPEG_INTERNALS

/* If right shift of "long" quantities is unsigned on your machine,
 * you'll have to define this.  Fortunately few people should need it.
 */
#undef RIGHT_SHIFT_IS_UNSIGNED

#ifdef XP_MAC                   /* Macintosh */

#define ALIGN_TYPE long         /* for sane memory alignment */
#define NO_GETENV               /* we do have the function, but it's dead */

#endif /* XP_MAC */

#endif /* JPEG_INTERNALS */


/* these defines are not interesting for building just the IJG library,
 * but we leave 'em here anyway.
 */
#ifdef JPEG_CJPEG_DJPEG

#define BMP_SUPPORTED		/* BMP image file format */
#define GIF_SUPPORTED		/* GIF image file format */
#define PPM_SUPPORTED		/* PBMPLUS PPM/PGM image file format */
#undef RLE_SUPPORTED		/* Utah RLE image file format */
#define TARGA_SUPPORTED		/* Targa image file format */

#undef TWO_FILE_COMMANDLINE
#undef NEED_SIGNAL_CATCHER
#undef DONT_USE_B_MODE
#undef PROGRESS_REPORT

#endif /* JPEG_CJPEG_DJPEG */
