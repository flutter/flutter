// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/services/icu/icu.h"

#include "lib/ftl/build_config.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/icu_data/interfaces/icu_data.mojom.h"
#include "flutter/services/icu/constants.h"
#include "third_party/icu/source/common/unicode/putil.h"
#include "third_party/icu/source/common/unicode/udata.h"

#if !defined(OS_ANDROID)
#include "base/i18n/icu_util.h"
#endif

namespace mojo {
namespace icu {
namespace {

class Callback {
 public:
  void Run(mojo::ScopedSharedBufferHandle handle) const {
    void* ptr = nullptr;
    mojo::MapBuffer(handle.get(), 0, kDataSize, &ptr,
                    MOJO_MAP_BUFFER_FLAG_NONE);
    UErrorCode err = U_ZERO_ERROR;
    udata_setCommonData(ptr, &err);
    // Leak the handle because we never unmap the buffer.
    (void)handle.release();
  };
};

}  // namespace

void Initialize(ApplicationConnector* application_connector) {
#if !defined(OS_ANDROID)
  // On desktop platforms, the icu data table is stored in a file on disk, which
  // can be loaded using base.
  base::i18n::InitializeICU();
  return;
#endif

  icu_data::ICUDataPtr icu_data;
  ConnectToService(application_connector, "mojo:icu_data", GetProxy(&icu_data));
  icu_data->Map(kDataHash, Callback());
  icu_data.WaitForIncomingResponse();
}

}  // namespace icu
}  // namespace mojo
