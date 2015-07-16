// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/mailbox.h"

#include <string.h>

#include "base/logging.h"
#include "base/rand_util.h"

namespace gpu {

Mailbox::Mailbox() {
  memset(name, 0, sizeof(name));
}

bool Mailbox::IsZero() const {
  for (size_t i = 0; i < arraysize(name); ++i) {
    if (name[i])
      return false;
  }
  return true;
}

void Mailbox::SetZero() {
  memset(name, 0, sizeof(name));
}

void Mailbox::SetName(const int8* n) {
  DCHECK(IsZero() || !memcmp(name, n, sizeof(name)));
  memcpy(name, n, sizeof(name));
}

Mailbox Mailbox::Generate() {
  Mailbox result;
  // Generates cryptographically-secure bytes.
  base::RandBytes(result.name, sizeof(result.name));
#if !defined(NDEBUG)
  int8 value = 1;
  for (size_t i = 1; i < sizeof(result.name); ++i)
    value ^= result.name[i];
  result.name[0] = value;
#endif
  return result;
}

bool Mailbox::Verify() const {
#if !defined(NDEBUG)
  int8 value = 1;
  for (size_t i = 0; i < sizeof(name); ++i)
    value ^= name[i];
  return value == 0;
#else
  return true;
#endif
}

}  // namespace gpu
