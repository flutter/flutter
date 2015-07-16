// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/async_pixel_transfer_delegate_mock.h"

namespace gpu {

MockAsyncPixelTransferDelegate::MockAsyncPixelTransferDelegate() {
}

MockAsyncPixelTransferDelegate::~MockAsyncPixelTransferDelegate() {
  Destroy();
}

}  // namespace gpu

