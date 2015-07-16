// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/mock_entropy_provider.h"

namespace base {

MockEntropyProvider::~MockEntropyProvider() {}

double MockEntropyProvider::GetEntropyForTrial(
    const std::string& trial_name, uint32 randomization_seed) const {
  return 0.5;
}

}  // namespace base
