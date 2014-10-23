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

#ifndef GraphicsContextRecorder_h
#define GraphicsContextRecorder_h

#include "platform/JSONValues.h"
#include "platform/PlatformExport.h"
#include "platform/graphics/GraphicsContext.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "wtf/RefCounted.h"

namespace blink {

class PLATFORM_EXPORT GraphicsContextSnapshot : public RefCounted<GraphicsContextSnapshot> {
WTF_MAKE_NONCOPYABLE(GraphicsContextSnapshot);
public:
    typedef Vector<Vector<double> > Timings;

    static PassRefPtr<GraphicsContextSnapshot> load(const char*, size_t);

    PassOwnPtr<Vector<char> > replay(unsigned fromStep = 0, unsigned toStep = 0, double scale = 1.0) const;
    PassOwnPtr<Timings> profile(unsigned minIterations, double minDuration) const;
    PassRefPtr<JSONArray> snapshotCommandLog() const;

private:
    friend class GraphicsContextRecorder;
    GraphicsContextSnapshot(PassRefPtr<SkPicture>);

    PassOwnPtr<SkBitmap> createBitmap() const;

    RefPtr<SkPicture> m_picture;
};

class PLATFORM_EXPORT GraphicsContextRecorder {
WTF_MAKE_NONCOPYABLE(GraphicsContextRecorder);
public:
    GraphicsContextRecorder() { }
    GraphicsContext* record(const IntSize&, bool isCertainlyOpaque);
    PassRefPtr<GraphicsContextSnapshot> stop();

private:
    RefPtr<SkPicture> m_picture;
    OwnPtr<GraphicsContext> m_context;
    OwnPtr<SkPictureRecorder> m_recorder;
    bool m_isCertainlyOpaque;
};

} // namespace blink

#endif // GraphicsContextRecorder_h
