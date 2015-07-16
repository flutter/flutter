// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/command_buffer_mock.h"

namespace gpu {

MockCommandBuffer::MockCommandBuffer() {
  ON_CALL(*this, GetTransferBuffer(testing::_))
      .WillByDefault(testing::Return(scoped_refptr<gpu::Buffer>()));
}

MockCommandBuffer::~MockCommandBuffer() {}

}  // namespace gpu
