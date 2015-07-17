/*
 * blapit.h - public data structures for the crypto library
 *
 * ***** BEGIN LICENSE BLOCK *****
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
 * Portions created by the Initial Developer are Copyright (C) 1994-2000
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Dr Vipul Gupta <vipul.gupta@sun.com> and
 *   Douglas Stebila <douglas@stebila.ca>, Sun Microsystems Laboratories
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
/* $Id: blapit.h,v 1.20 2007/02/28 19:47:37 rrelyea%redhat.com Exp $ */

#ifndef CRYPTO_THIRD_PARTY_NSS_CHROMIUM_BLAPIT_H_
#define CRYPTO_THIRD_PARTY_NSS_CHROMIUM_BLAPIT_H_

#include "crypto/third_party/nss/chromium-prtypes.h"

/*
** A status code. Status's are used by procedures that return status
** values. Again the motivation is so that a compiler can generate
** warnings when return values are wrong. Correct testing of status codes:
**
**      SECStatus rv;
**      rv = some_function (some_argument);
**      if (rv != SECSuccess)
**              do_an_error_thing();
**
*/
typedef enum _SECStatus {
    SECWouldBlock = -2,
    SECFailure = -1,
    SECSuccess = 0
} SECStatus;

#define SHA256_LENGTH 		32 	/* bytes */
#define SHA384_LENGTH 		48 	/* bytes */
#define SHA512_LENGTH 		64 	/* bytes */
#define HASH_LENGTH_MAX         SHA512_LENGTH

/*
 * Input block size for each hash algorithm.
 */

#define SHA256_BLOCK_LENGTH      64     /* bytes */
#define SHA384_BLOCK_LENGTH     128     /* bytes */
#define SHA512_BLOCK_LENGTH     128     /* bytes */
#define HASH_BLOCK_LENGTH_MAX   SHA512_BLOCK_LENGTH

/***************************************************************************
** Opaque objects
*/

struct SHA256ContextStr     ;
struct SHA512ContextStr     ;

typedef struct SHA256ContextStr     SHA256Context;
typedef struct SHA512ContextStr     SHA512Context;
/* SHA384Context is really a SHA512ContextStr.  This is not a mistake. */
typedef struct SHA512ContextStr     SHA384Context;

#endif /* CRYPTO_THIRD_PARTY_NSS_CHROMIUM_BLAPIT_H_ */
