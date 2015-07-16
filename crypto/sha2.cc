// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/sha2.h"

#include "base/memory/scoped_ptr.h"
#include "base/stl_util.h"
#include "crypto/secure_hash.h"

namespace crypto {

void SHA256HashString(const base::StringPiece& str, void* output, size_t len) {
  scoped_ptr<SecureHash> ctx(SecureHash::Create(SecureHash::SHA256));
  ctx->Update(str.data(), str.length());
  ctx->Finish(output, len);
}

std::string SHA256HashString(const base::StringPiece& str) {
  std::string output(kSHA256Length, 0);
  SHA256HashString(str, string_as_array(&output), output.size());
  return output;
}

}  // namespace crypto
