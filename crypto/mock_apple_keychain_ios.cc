// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/time/time.h"
#include "crypto/mock_apple_keychain.h"

namespace crypto {

MockAppleKeychain::MockAppleKeychain()
    : find_generic_result_(noErr),
      called_add_generic_(false),
      password_data_count_(0) {
}

MockAppleKeychain::~MockAppleKeychain() {
}

}  // namespace crypto
