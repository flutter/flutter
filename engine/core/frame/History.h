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

#ifndef SKY_ENGINE_CORE_FRAME_HISTORY_H_
#define SKY_ENGINE_CORE_FRAME_HISTORY_H_

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/bindings/core/v8/SerializedScriptValue.h"
#include "sky/engine/core/frame/DOMWindowProperty.h"
#include "sky/engine/core/loader/FrameLoaderTypes.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class LocalFrame;
class KURL;
class ExecutionContext;
class ExceptionState;

class History final : public RefCounted<History>, public ScriptWrappable, public DOMWindowProperty {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<History> create(LocalFrame* frame)
    {
        return adoptRef(new History(frame));
    }

    unsigned length() const;
    SerializedScriptValue* state();

    void back(ExecutionContext*);
    void forward(ExecutionContext*);
    void go(ExecutionContext*, int distance);

    bool stateChanged() const;
    bool isSameAsCurrentState(SerializedScriptValue*) const;

    void stateObjectAdded(PassRefPtr<SerializedScriptValue>, const String& title, const String& url, FrameLoadType, ExceptionState&);

private:
    explicit History(LocalFrame*);

    KURL urlForState(const String& url);

    SerializedScriptValue* stateInternal() const;

    RefPtr<SerializedScriptValue> m_lastStateObjectRequested;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_HISTORY_H_
