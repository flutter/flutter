/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
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

#ifndef ScriptProfiler_h
#define ScriptProfiler_h

#include "bindings/core/v8/ScriptHeapSnapshot.h"
#include "core/inspector/ScriptProfile.h"

#include "wtf/Forward.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ExternalStringVisitor;
class WrappedNodeVisitor;
class Page;
class ScriptValue;

class ScriptProfiler {
    WTF_MAKE_NONCOPYABLE(ScriptProfiler);
public:
    class HeapSnapshotProgress {
    public:
        virtual ~HeapSnapshotProgress() { }
        virtual void Start(int totalWork) = 0;
        virtual void Worked(int workDone) = 0;
        virtual void Done() = 0;
        virtual bool isCanceled() = 0;
    };

    class OutputStream {
    public:
        virtual ~OutputStream() { }
        virtual void write(const uint32_t* chunk, const int size) = 0;
    };

    static void collectGarbage();
    static ScriptValue objectByHeapObjectId(unsigned id);
    static unsigned getHeapObjectId(const ScriptValue&);
    static void clearHeapObjectIds();
    static void setSamplingInterval(int intervalUs);
    static void start(const String& title);
    static PassRefPtrWillBeRawPtr<ScriptProfile> stop(const String& title);
    static PassRefPtr<ScriptHeapSnapshot> takeHeapSnapshot(const String& title, HeapSnapshotProgress*);
    static void startTrackingHeapObjects(bool trackAllocations);
    static void stopTrackingHeapObjects();
    static unsigned requestHeapStatsUpdate(OutputStream*);
    static void initialize();
    static void visitNodeWrappers(WrappedNodeVisitor*);
    static HashMap<String, double>* currentProfileNameIdleTimeMap();
    static void setIdle(bool isIdle);
};

} // namespace blink

#endif // ScriptProfiler_h
