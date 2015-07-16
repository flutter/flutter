// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_MAILBOX_HOLDER_H_
#define GPU_COMMAND_BUFFER_MAILBOX_HOLDER_H_

#include <stdint.h>
#include <string.h>

#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/gpu_export.h"

namespace gpu {

struct GPU_EXPORT MailboxHolder {
  MailboxHolder();
  MailboxHolder(const gpu::Mailbox& mailbox,
                uint32_t texture_target,
                uint32_t sync_point);
  gpu::Mailbox mailbox;
  uint32_t texture_target;
  uint32_t sync_point;
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_MAILBOX_HOLDER_H_
