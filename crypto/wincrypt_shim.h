// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_CRYPTO_WINCRYPT_SHIM_H_
#define NET_CRYPTO_WINCRYPT_SHIM_H_

// wincrypt.h defines macros which conflict with OpenSSL's types. This header
// includes wincrypt and undefines the OpenSSL macros which conflict. Any
// Chromium headers which include wincrypt should instead include this header.

#include <windows.h>
#include <wincrypt.h>

// Undefine the macros which conflict with OpenSSL and define replacements. See
// http://msdn.microsoft.com/en-us/library/windows/desktop/aa378145(v=vs.85).aspx
#undef X509_CERT_PAIR
#undef X509_EXTENSIONS
#undef X509_NAME

#define WINCRYPT_X509_CERT_PAIR ((LPCSTR) 53)
#define WINCRYPT_X509_EXTENSIONS ((LPCSTR) 5)
#define WINCRYPT_X509_NAME ((LPCSTR) 7)

#endif  // NET_CRYPTO_WINCRYPT_SHIM_H_