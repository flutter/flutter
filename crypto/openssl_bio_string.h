// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_OPENSSL_BIO_STRING_H_
#define CRYPTO_OPENSSL_BIO_STRING_H_

#include <string>

#include "crypto/crypto_export.h"

// From <openssl/bio.h>
typedef struct bio_st BIO;

namespace crypto {

// Creates a new BIO that can be used with OpenSSL's various output functions,
// and which will write all output directly into |out|. This is primarily
// intended as a utility to reduce the amount of copying and separate
// allocations when performing extensive string modifications or streaming
// within OpenSSL.
//
// Note: |out| must remain valid for the duration of the BIO.
CRYPTO_EXPORT BIO* BIO_new_string(std::string* out);

}  // namespace crypto

#endif  // CRYPTO_OPENSSL_BIO_STRING_H_

