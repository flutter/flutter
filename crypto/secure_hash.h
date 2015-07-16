// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SECURE_HASH_H_
#define CRYPTO_SECURE_HASH_H_

#include "base/basictypes.h"
#include "crypto/crypto_export.h"

namespace base {
class Pickle;
class PickleIterator;
}

namespace crypto {

// A wrapper to calculate secure hashes incrementally, allowing to
// be used when the full input is not known in advance.
class CRYPTO_EXPORT SecureHash {
 public:
  enum Algorithm {
    SHA256,
  };
  virtual ~SecureHash() {}

  static SecureHash* Create(Algorithm type);

  virtual void Update(const void* input, size_t len) = 0;
  virtual void Finish(void* output, size_t len) = 0;

  // Serialize the context, so it can be restored at a later time.
  // |pickle| will contain the serialized data.
  // Returns whether or not |pickle| was filled.
  virtual bool Serialize(base::Pickle* pickle) = 0;

  // Restore the context that was saved earlier.
  // |data_iterator| allows this to be used as part of a larger pickle.
  // |pickle| holds the saved data.
  // Returns success or failure.
  virtual bool Deserialize(base::PickleIterator* data_iterator) = 0;

 protected:
  SecureHash() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(SecureHash);
};

}  // namespace crypto

#endif  // CRYPTO_SECURE_HASH_H_
