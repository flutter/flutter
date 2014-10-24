/*
 * Copyright (C) 2012, 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef Path2D_h
#define Path2D_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/CanvasPathMethods.h"
#include "platform/heap/Handle.h"
#include "platform/transforms/AffineTransform.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class Path2D final : public RefCountedWillBeGarbageCollectedFinalized<Path2D>, public CanvasPathMethods, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    WTF_MAKE_NONCOPYABLE(Path2D);
public:
    static PassRefPtrWillBeRawPtr<Path2D> create() { return adoptRefWillBeNoop(new Path2D); }
    static PassRefPtrWillBeRawPtr<Path2D> create(Path2D* path) { return adoptRefWillBeNoop(new Path2D(path)); }

    static PassRefPtrWillBeRawPtr<Path2D> create(const Path& path) { return adoptRefWillBeNoop(new Path2D(path)); }

    const Path& path() const { return m_path; }

    void addPath(Path2D* path)
    {
        m_path.addPath(path->path(), AffineTransform(1, 0, 0, 1, 0, 0));
    }

    virtual ~Path2D() { }
    void trace(Visitor*) { }

private:
    Path2D() : CanvasPathMethods()
    {
        ScriptWrappable::init(this);
    }

    Path2D(const Path& path)
        : CanvasPathMethods(path)
    {
        ScriptWrappable::init(this);
    }

    Path2D(Path2D* path)
        : CanvasPathMethods(path->path())
    {
        ScriptWrappable::init(this);
    }
};

} // namespace blink

#endif // Path2D_h
