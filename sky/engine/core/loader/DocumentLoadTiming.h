/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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

#ifndef SKY_ENGINE_CORE_LOADER_DOCUMENTLOADTIMING_H_
#define SKY_ENGINE_CORE_LOADER_DOCUMENTLOADTIMING_H_

#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

class LocalFrame;
class KURL;

class DocumentLoadTiming {
public:
    DocumentLoadTiming();

    double monotonicTimeToPseudoWallTime(double) const;

    void markNavigationStart();
    void setNavigationStart(double);

    void markUnloadEventStart() { m_unloadEventStart = monotonicallyIncreasingTime(); }
    void markUnloadEventEnd() { m_unloadEventEnd = monotonicallyIncreasingTime(); }
    void markFetchStart() { m_fetchStart = monotonicallyIncreasingTime(); }
    void setResponseEnd(double monotonicTime) { m_responseEnd = monotonicTime; }
    void markLoadEventStart() { m_loadEventStart = monotonicallyIncreasingTime(); }
    void markLoadEventEnd() { m_loadEventEnd = monotonicallyIncreasingTime(); }

    void setHasSameOriginAsPreviousDocument(bool value) { m_hasSameOriginAsPreviousDocument = value; }

    double navigationStart() const { return m_navigationStart; }
    double unloadEventStart() const { return m_unloadEventStart; }
    double unloadEventEnd() const { return m_unloadEventEnd; }
    double fetchStart() const { return m_fetchStart; }
    double responseEnd() const { return m_responseEnd; }
    double loadEventStart() const { return m_loadEventStart; }
    double loadEventEnd() const { return m_loadEventEnd; }
    bool hasSameOriginAsPreviousDocument() const { return m_hasSameOriginAsPreviousDocument; }

    double referenceMonotonicTime() const { return m_referenceMonotonicTime; }

private:
    double m_referenceMonotonicTime;
    double m_referenceWallTime;
    double m_navigationStart;
    double m_unloadEventStart;
    double m_unloadEventEnd;
    double m_fetchStart;
    double m_responseEnd;
    double m_loadEventStart;
    double m_loadEventEnd;
    bool m_hasSameOriginAsPreviousDocument;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_LOADER_DOCUMENTLOADTIMING_H_
