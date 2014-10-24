/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef RetainedDOMInfo_h
#define RetainedDOMInfo_h

#include "bindings/core/v8/RetainedObjectInfo.h"
#include <v8-profiler.h>

namespace blink {

class Node;

// Implements v8::RetainedObjectInfo.
class RetainedDOMInfo final : public RetainedObjectInfo {
public:
    explicit RetainedDOMInfo(Node* root);
    virtual ~RetainedDOMInfo();
    virtual void Dispose() override;
    virtual bool IsEquivalent(v8::RetainedObjectInfo* other) override;
    virtual intptr_t GetHash() override;
    virtual const char* GetGroupLabel() override;
    virtual const char* GetLabel() override;
    virtual intptr_t GetElementCount() override;
    virtual intptr_t GetEquivalenceClass() override;

private:
    // V8 guarantees to keep RetainedObjectInfos alive only during a GC or heap snapshotting round, when renderer
    // doesn't get control. This allows us to use raw pointers.
    Node* m_root;
};

} // namespace blink

#endif // RetainedDOMInfo_h
