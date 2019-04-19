// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/icu_util.h"

#include <mutex>

#include "flutter/fml/logging.h"
#include "third_party/icu/source/common/unicode/udata.h"

namespace fml {
namespace icu {

void InitializeICU(std::unique_ptr<const Mapping> mapping) {
  if (mapping == nullptr || mapping->GetSize() == 0) {
    return;
  }
  static std::once_flag g_icu_init_flag;
  std::call_once(g_icu_init_flag, [mapping = std::move(mapping)]() mutable {
    static auto icu_mapping = std::move(mapping);
    UErrorCode err_code = U_ZERO_ERROR;
    udata_setCommonData(icu_mapping->GetMapping(), &err_code);
    FML_CHECK(err_code == U_ZERO_ERROR) << "Must be able to initialize ICU.";
  });
}

}  // namespace icu
}  // namespace fml
