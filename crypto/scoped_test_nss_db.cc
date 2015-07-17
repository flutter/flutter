// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/scoped_test_nss_db.h"

#include "base/logging.h"
#include "base/threading/thread_restrictions.h"
#include "crypto/nss_util.h"
#include "crypto/nss_util_internal.h"

namespace crypto {

ScopedTestNSSDB::ScopedTestNSSDB() {
  EnsureNSSInit();
  // NSS is allowed to do IO on the current thread since dispatching
  // to a dedicated thread would still have the affect of blocking
  // the current thread, due to NSS's internal locking requirements
  base::ThreadRestrictions::ScopedAllowIO allow_io;

  if (!temp_dir_.CreateUniqueTempDir())
    return;

  const char kTestDescription[] = "Test DB";
  slot_ = OpenSoftwareNSSDB(temp_dir_.path(), kTestDescription);
}

ScopedTestNSSDB::~ScopedTestNSSDB() {
  // Don't close when NSS is < 3.15.1, because it would require an additional
  // sleep for 1 second after closing the database, due to
  // http://bugzil.la/875601.
  if (!NSS_VersionCheck("3.15.1")) {
    LOG(ERROR) << "NSS version is < 3.15.1, test DB will not be closed.";
    temp_dir_.Take();
    return;
  }

  // NSS is allowed to do IO on the current thread since dispatching
  // to a dedicated thread would still have the affect of blocking
  // the current thread, due to NSS's internal locking requirements
  base::ThreadRestrictions::ScopedAllowIO allow_io;

  if (slot_) {
    SECStatus status = SECMOD_CloseUserDB(slot_.get());
    if (status != SECSuccess)
      PLOG(ERROR) << "SECMOD_CloseUserDB failed: " << PORT_GetError();
  }

  if (!temp_dir_.Delete())
    LOG(ERROR) << "Could not delete temporary directory.";
}

}  // namespace crypto
