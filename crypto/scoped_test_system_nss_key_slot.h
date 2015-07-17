// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SCOPED_TEST_SYSTEM_NSS_KEY_SLOT_H_
#define CRYPTO_SCOPED_TEST_SYSTEM_NSS_KEY_SLOT_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "crypto/crypto_export.h"

// Forward declaration, from <pk11pub.h>
typedef struct PK11SlotInfoStr PK11SlotInfo;

namespace crypto {

class ScopedTestNSSDB;

// Opens a persistent NSS software database in a temporary directory and sets
// the test system slot to the opened database. This helper should be created in
// tests to fake the system token that is usually provided by the Chaps module.
// |slot| is exposed through |GetSystemNSSKeySlot| and |IsTPMTokenReady| will
// return true.
// |InitializeTPMTokenAndSystemSlot|, which triggers the TPM initialization,
// does not have to be called if this helper is used.
// At most one instance of this helper must be used at a time.
class CRYPTO_EXPORT_PRIVATE ScopedTestSystemNSSKeySlot {
 public:
  explicit ScopedTestSystemNSSKeySlot();
  ~ScopedTestSystemNSSKeySlot();

  bool ConstructedSuccessfully() const;
  PK11SlotInfo* slot() const;

 private:
  scoped_ptr<ScopedTestNSSDB> test_db_;

  DISALLOW_COPY_AND_ASSIGN(ScopedTestSystemNSSKeySlot);
};

}  // namespace crypto

#endif  // CRYPTO_SCOPED_TEST_SYSTEM_NSS_KEY_SLOT_H_
