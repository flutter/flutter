/*
 * Copyright (C) 2013 Google, Inc. All rights reserved.
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
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FetchInitiatorInfo_h
#define FetchInitiatorInfo_h

#include "wtf/text/AtomicString.h"
#include "wtf/text/TextPosition.h"

namespace blink {

struct FetchInitiatorInfo {
    FetchInitiatorInfo()
        : name()
        , position(TextPosition::belowRangePosition())
        , startTime(0.0)
    {
    }

    // When adding members, CrossThreadFetchInitiatorInfoData should be
    // updated.
    AtomicString name;
    TextPosition position;
    double startTime;
};

// Encode AtomicString as String to cross threads.
struct CrossThreadFetchInitiatorInfoData {
    explicit CrossThreadFetchInitiatorInfoData(const FetchInitiatorInfo& info)
        : name(info.name.string().isolatedCopy())
        , position(info.position)
        , startTime(info.startTime)
    {
    }

    operator FetchInitiatorInfo() const
    {
        FetchInitiatorInfo info;
        info.name = AtomicString(name);
        info.position = position;
        info.startTime = startTime;
        return info;
    }

    String name;
    TextPosition position;
    double startTime;
};

} // namespace blink

#endif
