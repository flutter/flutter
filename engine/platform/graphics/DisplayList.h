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

#ifndef DisplayList_h
#define DisplayList_h

#include "platform/geometry/FloatRect.h"

#include "wtf/FastAllocBase.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

class SkCanvas;
class SkPicture;
class SkPictureRecorder;

namespace blink {

class IntSize;

class PLATFORM_EXPORT DisplayList FINAL : public WTF::RefCounted<DisplayList> {
    WTF_MAKE_FAST_ALLOCATED;
    WTF_MAKE_NONCOPYABLE(DisplayList);
public:
    DisplayList(const FloatRect&);
    ~DisplayList();

    const FloatRect& bounds() const;

    // This entry point will return 0 when the DisplayList is in the
    // midst of recording (i.e., between a beginRecording/endRecording pair)
    // and if no recording has ever been completed. Otherwise it will return
    // the picture created by the last endRecording call.
    SkPicture* picture() const;

    SkCanvas* beginRecording(const IntSize&, uint32_t recordFlags = 0);
    bool isRecording() const { return m_recorder; }
    void endRecording();

private:
    FloatRect m_bounds;
    RefPtr<SkPicture> m_picture;
    OwnPtr<SkPictureRecorder> m_recorder;
};

} // namespace blink

#endif // DisplayList_h
