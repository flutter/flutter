/*
 * Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008-2009 Torch Mobile, Inc.
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

#ifndef FrameData_h
#define FrameData_h

#include "platform/graphics/ImageOrientation.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefPtr.h"
#include "wtf/VectorTraits.h"

namespace blink {

class NativeImageSkia;

struct FrameData {
    WTF_MAKE_NONCOPYABLE(FrameData);
public:
    FrameData();
    ~FrameData();

    // Clear the cached image data on the frame, and (optionally) the metadata.
    // Returns whether there was cached image data to clear.
    bool clear(bool clearMetadata);

    RefPtr<NativeImageSkia> m_frame;
    ImageOrientation m_orientation;
    float m_duration;
    bool m_haveMetadata : 1;
    bool m_isComplete : 1;
    bool m_hasAlpha : 1;
    unsigned m_frameBytes;
};

} // namespace blink

namespace WTF {
template<> struct VectorTraits<blink::FrameData> : public SimpleClassVectorTraits<blink::FrameData> {
    static const bool canInitializeWithMemset = false; // Not all FrameData members initialize to 0.
};
}

#endif // FrameData_h
