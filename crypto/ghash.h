// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "crypto/crypto_export.h"

namespace crypto {

// GaloisHash implements the polynomial authenticator part of GCM as specified
// in http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf
// Specifically it implements the GHASH function, defined in section 2.3 of
// that document.
//
// In SP-800-38D, GHASH is defined differently and takes only a single data
// argument. But it is always called with an argument of a certain form:
//   GHASH_H (A || 0^v || C || 0^u || [len(A)]_64 || [len(C)]_64)
// This mirrors how the gcm-revised-spec.pdf version of GHASH handles its two
// data arguments. The two GHASH functions therefore differ only in whether the
// data is formatted inside or outside of the function.
//
// WARNING: do not use this as a generic authenticator. Polynomial
// authenticators must be used in the correct manner and any use outside of GCM
// requires careful consideration.
//
// WARNING: this code is not constant time. However, in all likelihood, nor is
// the implementation of AES that is used.
class CRYPTO_EXPORT_PRIVATE GaloisHash {
 public:
  explicit GaloisHash(const uint8 key[16]);

  // Reset prepares to digest a fresh message with the same key. This is more
  // efficient than creating a fresh object.
  void Reset();

  // UpdateAdditional hashes in `additional' data. This is data that is not
  // encrypted, but is covered by the authenticator. All additional data must
  // be written before any ciphertext is written.
  void UpdateAdditional(const uint8* data, size_t length);

  // UpdateCiphertext hashes in ciphertext to be authenticated.
  void UpdateCiphertext(const uint8* data, size_t length);

  // Finish completes the hash computation and writes at most |len| bytes of
  // the result to |output|.
  void Finish(void* output, size_t len);

 private:
  enum State {
    kHashingAdditionalData,
    kHashingCiphertext,
    kComplete,
  };

  struct FieldElement {
    uint64 low, hi;
  };

  // Add returns |x|+|y|.
  static FieldElement Add(const FieldElement& x, const FieldElement& y);
  // Double returns 2*|x|.
  static FieldElement Double(const FieldElement& x);
  // MulAfterPrecomputation sets |x| = |x|*h where h is |table[1]| and
  // table[i] = i*h for i=0..15.
  static void MulAfterPrecomputation(const FieldElement* table,
                                     FieldElement* x);
  // Mul16 sets |x| = 16*|x|.
  static void Mul16(FieldElement* x);

  // UpdateBlocks processes |num_blocks| 16-bytes blocks from |bytes|.
  void UpdateBlocks(const uint8* bytes, size_t num_blocks);
  // Update processes |length| bytes from |bytes| and calls UpdateBlocks on as
  // much data as possible. It uses |buf_| to buffer any remaining data and
  // always consumes all of |bytes|.
  void Update(const uint8* bytes, size_t length);

  FieldElement y_;
  State state_;
  size_t additional_bytes_;
  size_t ciphertext_bytes_;
  uint8 buf_[16];
  size_t buf_used_;
  FieldElement product_table_[16];
};

}  // namespace crypto
