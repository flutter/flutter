/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/wtf/WTF.h"

#include "flutter/sky/engine/wtf/DefaultAllocator.h"
#include "flutter/sky/engine/wtf/FastMalloc.h"

namespace WTF {

extern void initializeThreading();

bool s_initialized;
bool s_shutdown;
bool Partitions::s_initialized;
PartitionAllocatorGeneric Partitions::m_bufferAllocator;

void initialize() {
  // WTF, and Blink in general, cannot handle being re-initialized, even if
  // shutdown first. Make that explicit here.
  ASSERT(!s_initialized);
  ASSERT(!s_shutdown);
  s_initialized = true;
  Partitions::initialize();
  initializeThreading();
}

void shutdown() {
  ASSERT(s_initialized);
  ASSERT(!s_shutdown);
  s_shutdown = true;
  Partitions::shutdown();
}

bool isShutdown() {
  return s_shutdown;
}

void Partitions::initialize() {
  static int lock = 0;
  // Guard against two threads hitting here in parallel.
  spinLockLock(&lock);
  if (!s_initialized) {
    m_bufferAllocator.init();
    s_initialized = true;
  }
  spinLockUnlock(&lock);
}

void Partitions::shutdown() {
  fastMallocShutdown();
  m_bufferAllocator.shutdown();
}

}  // namespace WTF
