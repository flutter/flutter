/*
 * Copyright (C) 2011, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MediaFragmentURIParser_h
#define MediaFragmentURIParser_h

#include "platform/weborigin/KURL.h"
#include "wtf/Vector.h"

namespace blink {

class KURL;

class MediaFragmentURIParser final {
public:

    MediaFragmentURIParser(const KURL&);

    double startTime();
    double endTime();

    static double invalidTimeValue();

private:

    void parseFragments();

    enum TimeFormat { None, Invalid, NormalPlayTime, SMPTETimeCode, WallClockTimeCode };
    void parseTimeFragment();
    bool parseNPTFragment(const LChar*, unsigned length, double& startTime, double& endTime);
    bool parseNPTTime(const LChar*, unsigned length, unsigned& offset, double& time);

    KURL m_url;
    TimeFormat m_timeFormat;
    double m_startTime;
    double m_endTime;
    Vector<std::pair<String, String> > m_fragments;
};

} // namespace blink

#endif
