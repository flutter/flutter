// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/mailbox_holder.h"

namespace gpu {

MailboxHolder::MailboxHolder() : texture_target(0), sync_point(0) {}

MailboxHolder::MailboxHolder(const Mailbox& mailbox,
                             uint32_t texture_target,
                             uint32_t sync_point)
    : mailbox(mailbox),
      texture_target(texture_target),
      sync_point(sync_point) {}

}  // namespace gpu
