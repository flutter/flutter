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
 * The Original Code is the Netscape security libraries.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 2002
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

/* Emulates the real prtypes.h. Defines the types and macros that sha512.cc
 * needs. */

#ifndef CRYPTO_THIRD_PARTY_NSS_CHROMIUM_PRTYPES_H_
#define CRYPTO_THIRD_PARTY_NSS_CHROMIUM_PRTYPES_H_

#include <limits.h>
#include <stdint.h>

#include "build/build_config.h"

#if defined(ARCH_CPU_LITTLE_ENDIAN)
#define IS_LITTLE_ENDIAN 1
#else
#define IS_BIG_ENDIAN 1
#endif

/*
 * The C language requires that 'long' be at least 32 bits. 2147483647 is the
 * largest signed 32-bit integer.
 */
#if LONG_MAX > 2147483647L
#define PR_BYTES_PER_LONG 8
#else
#define PR_BYTES_PER_LONG 4
#endif

#define HAVE_LONG_LONG

#if defined(__linux__)
#define LINUX
#endif

typedef uint8_t PRUint8;
typedef uint32_t PRUint32;

typedef int PRBool;

#define PR_MIN(x,y) ((x)<(y)?(x):(y))

#endif  /* CRYPTO_THIRD_PARTY_NSS_CHROMIUM_PRTYPES_H_ */
