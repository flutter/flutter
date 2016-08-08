/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_
#define SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_

#include <string>

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebVector.h"

namespace ftl {
class TaskRunner;
}

namespace blink {
class WebDiscardableMemory;

class Platform {
 public:
  // HTML5 Database ------------------------------------------------------
  typedef int FileHandle;

  BLINK_PLATFORM_EXPORT static void initialize(Platform*);
  BLINK_PLATFORM_EXPORT static void shutdown();
  BLINK_PLATFORM_EXPORT static Platform* current();

  // Allocates discardable memory. May return 0, even if the platform supports
  // discardable memory. If nonzero, however, then the WebDiscardableMmeory is
  // returned in an locked state. You may use its underlying data() member
  // directly, taking care to unlock it when you are ready to let it become
  // discardable.
  virtual WebDiscardableMemory* allocateAndLockDiscardableMemory(size_t bytes) {
    return 0;
  }

  // System --------------------------------------------------------------

  // Returns a value such as "en-US".
  virtual std::string defaultLocale() { return std::string(); }

  virtual ftl::TaskRunner* GetUITaskRunner() { return nullptr; }
  virtual ftl::TaskRunner* GetIOTaskRunner() { return nullptr; }

 protected:
  virtual ~Platform() {}
};

}  // namespace blink

#endif  // SKY_ENGINE_PUBLIC_PLATFORM_PLATFORM_H_
