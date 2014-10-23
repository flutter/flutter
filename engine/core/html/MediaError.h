/*
 * Copyright (C) 2007 Apple Inc.  All rights reserved.
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

#ifndef MediaError_h
#define MediaError_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class MediaError FINAL : public RefCountedWillBeGarbageCollectedFinalized<MediaError>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum Code {
        MEDIA_ERR_ABORTED = 1,
        MEDIA_ERR_NETWORK,
        MEDIA_ERR_DECODE,
        MEDIA_ERR_SRC_NOT_SUPPORTED,
        MEDIA_ERR_ENCRYPTED
    };

    static PassRefPtrWillBeRawPtr<MediaError> create(Code code)
    {
        return adoptRefWillBeNoop(new MediaError(code));
    }

    Code code() const { return m_code; }

    void trace(Visitor*) { }

private:
    MediaError(Code code) : m_code(code)
    {
        ScriptWrappable::init(this);
    }

    Code m_code;
};

} // namespace blink

#endif // MediaError_h
