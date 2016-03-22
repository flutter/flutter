// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_INTERNAL_H_
#define MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_INTERNAL_H_

#include "base/callback_forward.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {
namespace common {

// Read data from the source pipe and invoke the callback for each chunk.
bool BlockingCopyHelper(
    ScopedDataPipeConsumerHandle source,
    const base::Callback<size_t(const void*, uint32_t)>& write_bytes);

}  // namespace common
}  // namespace mojo

#endif  // MOJO_DATA_PIPE_UTILS_DATA_PIPE_UTILS_INTERNAL_H_
