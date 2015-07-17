// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/scoped_test_nss_chromeos_user.h"

#include "base/logging.h"
#include "crypto/nss_util.h"
#include "crypto/nss_util_internal.h"

namespace crypto {

ScopedTestNSSChromeOSUser::ScopedTestNSSChromeOSUser(
    const std::string& username_hash)
    : username_hash_(username_hash), constructed_successfully_(false) {
  if (!temp_dir_.CreateUniqueTempDir())
    return;
  // This opens a software DB in the given folder. In production code that is in
  // the home folder, but for testing the temp folder is used.
  constructed_successfully_ =
      InitializeNSSForChromeOSUser(username_hash, temp_dir_.path());
}

ScopedTestNSSChromeOSUser::~ScopedTestNSSChromeOSUser() {
  if (constructed_successfully_)
    CloseChromeOSUserForTesting(username_hash_);
}

void ScopedTestNSSChromeOSUser::FinishInit() {
  DCHECK(constructed_successfully_);
  if (!ShouldInitializeTPMForChromeOSUser(username_hash_))
    return;
  WillInitializeTPMForChromeOSUser(username_hash_);
  InitializePrivateSoftwareSlotForChromeOSUser(username_hash_);
}

}  // namespace crypto
