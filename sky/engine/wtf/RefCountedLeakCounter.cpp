/*
 *  Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#include "flutter/sky/engine/wtf/RefCountedLeakCounter.h"
#include "flutter/sky/engine/wtf/Assertions.h"

#if ENABLE(ASSERT)
#include "flutter/sky/engine/wtf/Atomics.h"
#include "flutter/sky/engine/wtf/HashCountedSet.h"
#endif

namespace WTF {

#if !ENABLE(ASSERT)

void RefCountedLeakCounter::suppressMessages(const char*) {}
void RefCountedLeakCounter::cancelMessageSuppression(const char*) {}

RefCountedLeakCounter::RefCountedLeakCounter(const char*) {}
RefCountedLeakCounter::~RefCountedLeakCounter() {}

void RefCountedLeakCounter::increment() {}
void RefCountedLeakCounter::decrement() {}

#else

#define LOG_CHANNEL_PREFIX Log
static WTFLogChannel LogRefCountedLeaks = {WTFLogChannelOn};

typedef HashCountedSet<const char*, PtrHash<const char*>> ReasonSet;
static ReasonSet* leakMessageSuppressionReasons;

void RefCountedLeakCounter::suppressMessages(const char* reason) {
  if (!leakMessageSuppressionReasons)
    leakMessageSuppressionReasons = new ReasonSet;
  leakMessageSuppressionReasons->add(reason);
}

void RefCountedLeakCounter::cancelMessageSuppression(const char* reason) {
  ASSERT(leakMessageSuppressionReasons);
  ASSERT(leakMessageSuppressionReasons->contains(reason));
  leakMessageSuppressionReasons->remove(reason);
}

RefCountedLeakCounter::RefCountedLeakCounter(const char* description)
    : m_description(description) {}

RefCountedLeakCounter::~RefCountedLeakCounter() {
  static bool loggedSuppressionReason;
  if (m_count) {
    if (!leakMessageSuppressionReasons ||
        leakMessageSuppressionReasons->isEmpty())
      WTF_LOG(RefCountedLeaks, "LEAK: %u %s", m_count, m_description);
    else if (!loggedSuppressionReason) {
      // This logs only one reason. Later we could change it so we log all the
      // reasons.
      WTF_LOG(RefCountedLeaks, "No leak checking done: %s",
              leakMessageSuppressionReasons->begin()->key);
      loggedSuppressionReason = true;
    }
  }
}

void RefCountedLeakCounter::increment() {
  atomicIncrement(&m_count);
}

void RefCountedLeakCounter::decrement() {
  atomicDecrement(&m_count);
}

#endif

}  // namespace WTF
