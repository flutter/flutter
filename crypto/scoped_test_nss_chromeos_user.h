// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef CRYPTO_SCOPED_TEST_NSS_CHROMEOS_USER_H_
#define CRYPTO_SCOPED_TEST_NSS_CHROMEOS_USER_H_

#include <string>

#include "base/files/scoped_temp_dir.h"
#include "base/macros.h"
#include "crypto/crypto_export.h"

namespace crypto {

// Opens a persistent NSS software database in a temporary directory for the
// user with |username_hash|. This database will be used for both the user's
// public and private slot.
class CRYPTO_EXPORT_PRIVATE ScopedTestNSSChromeOSUser {
 public:
  // Opens the software database and sets the public slot for the user. The
  // private slot will not be initialized until FinishInit() is called.
  explicit ScopedTestNSSChromeOSUser(const std::string& username_hash);
  ~ScopedTestNSSChromeOSUser();

  std::string username_hash() const { return username_hash_; }
  bool constructed_successfully() const { return constructed_successfully_; }

  // Completes initialization of user. Causes any waiting private slot callbacks
  // to run, see GetPrivateSlotForChromeOSUser().
  void FinishInit();

 private:
  const std::string username_hash_;
  base::ScopedTempDir temp_dir_;
  bool constructed_successfully_;

  DISALLOW_COPY_AND_ASSIGN(ScopedTestNSSChromeOSUser);
};

}  // namespace crypto

#endif  // CRYPTO_SCOPED_TEST_NSS_CHROMEOS_USER_H_
