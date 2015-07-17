// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SCOPED_TEST_NSS_DB_H_
#define CRYPTO_SCOPED_TEST_NSS_DB_H_

#include "base/files/scoped_temp_dir.h"
#include "base/macros.h"
#include "crypto/crypto_export.h"
#include "crypto/scoped_nss_types.h"

namespace crypto {

// Opens a persistent NSS database in a temporary directory.
// Prior NSS version 3.15.1, because of http://bugzil.la/875601 , the opened DB
// will not be closed automatically.
class CRYPTO_EXPORT_PRIVATE ScopedTestNSSDB {
 public:
  ScopedTestNSSDB();
  ~ScopedTestNSSDB();

  bool is_open() const { return slot_; }
  PK11SlotInfo* slot() const { return slot_.get(); }

 private:
  base::ScopedTempDir temp_dir_;
  ScopedPK11Slot slot_;

  DISALLOW_COPY_AND_ASSIGN(ScopedTestNSSDB);
};

}  // namespace crypto

#endif  // CRYPTO_SCOPED_TEST_NSS_DB_H_
