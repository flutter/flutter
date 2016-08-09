/*
 * Copyright (c) 2000-2004 Apple Computer, Inc. All Rights Reserved.
 * 
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 *
 * cssmapplePriv.h -- Private CSSM features specific to Apple's Implementation
 */
 
#ifndef _CSSMAPPLE_PRIV_H_
#define _CSSMAPPLE_PRIV_H_  1

#include <Security/cssmtype.h>
#include <Security/cssmapple.h>

#ifdef __cplusplus
extern "C" {
#endif
 
/* 
 * Options for X509TP's CSSM_TP_CertGroupVerify for policy 
 * CSSMOID_APPLE_TP_REVOCATION_OCSP. A pointer to, and length of, one 
 * of these is optionally placed in 
 * CSSM_TP_VERIFY_CONTEXT.Cred->Policy.PolicyIds[n].FieldValue.
 */

#define CSSM_APPLE_TP_OCSP_OPTS_VERSION		0

typedef uint32 CSSM_APPLE_TP_OCSP_OPT_FLAGS;
enum {
	// require OCSP verification for each cert; default is "try"
	CSSM_TP_ACTION_OCSP_REQUIRE_PER_CERT			= 0x00000001,
	// require OCSP verification for certs which claim an OCSP responder
	CSSM_TP_ACTION_OCSP_REQUIRE_IF_RESP_PRESENT 	= 0x00000002,
	// disable network OCSP transactions
	CSSM_TP_ACTION_OCSP_DISABLE_NET					= 0x00000004,
	// disable reads from local OCSP cache
	CSSM_TP_ACTION_OCSP_CACHE_READ_DISABLE			= 0x00000008,
	// disable reads from local OCSP cache
	CSSM_TP_ACTION_OCSP_CACHE_WRITE_DISABLE			= 0x00000010,
	// if set and positive OCSP verify for given cert, no further revocation
	// checking need be done on that cert
	CSSM_TP_ACTION_OCSP_SUFFICIENT					= 0x00000020,
	// generate nonce in OCSP request
	CSSM_TP_OCSP_GEN_NONCE							= 0x00000040,
	// when generating nonce, require matching nonce in response
	CSSM_TP_OCSP_REQUIRE_RESP_NONCE					= 0x00000080
};

typedef struct {
	uint32							Version;	
	CSSM_APPLE_TP_OCSP_OPT_FLAGS	Flags;
	CSSM_DATA_PTR					LocalResponder;		/* URI */
	CSSM_DATA_PTR					LocalResponderCert;	/* X509 DER encoded cert */
} CSSM_APPLE_TP_OCSP_OPTIONS;

#ifdef __cplusplus
}
#endif

#endif	/* _CSSMAPPLE_PRIV_H_ */
