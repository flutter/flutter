// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "SkTypeface.h"

// ===== Begin Chrome-specific definitions =====

uint32_t SkTypeface::UniqueID(const SkTypeface* face)
{
    return 0;
}

void SkTypeface::serialize(SkWStream* stream) const {
}

SkTypeface* SkTypeface::Deserialize(SkStream* stream) {
  return NULL;
}

// ===== End Chrome-specific definitions =====
