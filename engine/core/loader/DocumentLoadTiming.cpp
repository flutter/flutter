/*
 * Copyright (C) 2011 Google, Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/loader/DocumentLoadTiming.h"

#include "sky/engine/wtf/RefPtr.h"

namespace blink {

DocumentLoadTiming::DocumentLoadTiming()
    : m_referenceMonotonicTime(0.0)
    , m_referenceWallTime(0.0)
    , m_navigationStart(0.0)
    , m_unloadEventStart(0.0)
    , m_unloadEventEnd(0.0)
    , m_fetchStart(0.0)
    , m_responseEnd(0.0)
    , m_loadEventStart(0.0)
    , m_loadEventEnd(0.0)
    , m_hasSameOriginAsPreviousDocument(false)
{
}

double DocumentLoadTiming::monotonicTimeToPseudoWallTime(double monotonicTime) const
{
    if (!monotonicTime)
        return 0.0;
    return m_referenceWallTime + monotonicTime - m_referenceMonotonicTime;
}

void DocumentLoadTiming::markNavigationStart()
{
    ASSERT(!m_navigationStart && !m_referenceMonotonicTime && !m_referenceWallTime);

    m_navigationStart = m_referenceMonotonicTime = monotonicallyIncreasingTime();
    m_referenceWallTime = currentTime();
}

void DocumentLoadTiming::setNavigationStart(double navigationStart)
{
    ASSERT(m_referenceMonotonicTime && m_referenceWallTime);
    m_navigationStart = navigationStart;

    // |m_referenceMonotonicTime| and |m_referenceWallTime| represent
    // navigationStart. When the embedder sets navigationStart (because the
    // navigation started earlied on the browser side), we need to adjust these
    // as well.
    m_referenceWallTime = monotonicTimeToPseudoWallTime(navigationStart);
    m_referenceMonotonicTime = navigationStart;
}

} // namespace blink
