// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_MAILBOX_H_
#define GPU_COMMAND_BUFFER_MAILBOX_H_

#include <stdint.h>
#include <string.h>

#include "gpu/gpu_export.h"

// From gl2/gl2ext.h.
#ifndef GL_MAILBOX_SIZE_CHROMIUM
#define GL_MAILBOX_SIZE_CHROMIUM 64
#endif

namespace gpu {

struct GPU_EXPORT Mailbox {
  Mailbox();
  bool IsZero() const;
  void SetZero();
  void SetName(const int8_t* name);

  // Generate a unique unguessable mailbox name.
  static Mailbox Generate();

  // Verify that the mailbox was created through Mailbox::Generate. This only
  // works in Debug (always returns true in Release). This is not a secure
  // check, only to catch bugs where clients forgot to call Mailbox::Generate.
  bool Verify() const;

  int8_t name[GL_MAILBOX_SIZE_CHROMIUM];
  bool operator<(const Mailbox& other) const {
    return memcmp(this, &other, sizeof other) < 0;
  }
  bool operator==(const Mailbox& other) const {
    return memcmp(this, &other, sizeof other) == 0;
  }
  bool operator!=(const Mailbox& other) const {
    return !operator==(other);
  }
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_MAILBOX_H_

