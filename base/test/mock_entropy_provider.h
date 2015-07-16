// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_MOCK_ENTROPY_PROVIDER_H_
#define BASE_TEST_MOCK_ENTROPY_PROVIDER_H_

#include "base/metrics/field_trial.h"

namespace base {

class MockEntropyProvider : public base::FieldTrial::EntropyProvider {
 public:
  ~MockEntropyProvider() override;

  // base::FieldTrial::EntropyProvider:
  double GetEntropyForTrial(const std::string& trial_name,
                            uint32 randomization_seed) const override;
};

}  // namespace base

#endif  // BASE_TEST_MOCK_ENTROPY_PROVIDER_H_
