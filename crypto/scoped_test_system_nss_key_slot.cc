// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/scoped_test_system_nss_key_slot.h"

#include "crypto/nss_util_internal.h"
#include "crypto/scoped_test_nss_db.h"

namespace crypto {

ScopedTestSystemNSSKeySlot::ScopedTestSystemNSSKeySlot()
    : test_db_(new ScopedTestNSSDB) {
  if (!test_db_->is_open())
    return;
  SetSystemKeySlotForTesting(
      ScopedPK11Slot(PK11_ReferenceSlot(test_db_->slot())));
}

ScopedTestSystemNSSKeySlot::~ScopedTestSystemNSSKeySlot() {
  SetSystemKeySlotForTesting(ScopedPK11Slot());
}

bool ScopedTestSystemNSSKeySlot::ConstructedSuccessfully() const {
  return test_db_->is_open();
}

PK11SlotInfo* ScopedTestSystemNSSKeySlot::slot() const {
  return test_db_->slot();
}

}  // namespace crypto
