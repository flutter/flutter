// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_SK_DISCARDABLE_MEMORY_CHROME_H_
#define SKIA_EXT_SK_DISCARDABLE_MEMORY_CHROME_H_

#include "base/memory/scoped_ptr.h"
#include "third_party/skia/src/core/SkDiscardableMemory.h"

namespace base {
class DiscardableMemory;
}

// This class implements the SkDiscardableMemory interface using
// base::DiscardableMemory.
class SK_API SkDiscardableMemoryChrome : public SkDiscardableMemory {
public:
 ~SkDiscardableMemoryChrome() override;

  // SkDiscardableMemory:
 bool lock() override;
 void* data() override;
 void unlock() override;

private:
  friend class SkDiscardableMemory;

  SkDiscardableMemoryChrome(scoped_ptr<base::DiscardableMemory> memory);

  scoped_ptr<base::DiscardableMemory> discardable_;
};

#endif  // SKIA_EXT_SK_DISCARDABLE_MEMORY_CHROME_H_
