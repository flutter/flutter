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

#ifndef SKY_ENGINE_V8_INSPECTOR_INSPECTORBASEAGENT_H_
#define SKY_ENGINE_V8_INSPECTOR_INSPECTORBASEAGENT_H_

#include "gen/v8_inspector/InspectorBackendDispatcher.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class InspectorFrontend;
class InspectorCompositeState;
class InspectorState;
class InstrumentingAgents;

class InspectorAgent {
public:
    explicit InspectorAgent(const String&);
    virtual ~InspectorAgent();

    void init(InstrumentingAgents* agents, InspectorState* inspectorState);

    virtual void setFrontend(InspectorFrontend*) { }
    virtual void clearFrontend() { }
    virtual void restore() { }
    virtual void discardAgent() { }
    virtual void didCommitLoadForMainFrame() { }
    virtual void flushPendingFrontendMessages() { }

private:
    virtual void virtualInit() { }

    String name() { return m_name; }

protected:
    RawPtr<InstrumentingAgents> m_instrumentingAgents;
    RawPtr<InspectorState> m_state;

private:
    String m_name;
};

template<typename T>
class InspectorBaseAgent : public InspectorAgent {
public:
    virtual ~InspectorBaseAgent() { }

protected:
    explicit InspectorBaseAgent(const String& name) : InspectorAgent(name)
    {
    }
};

inline bool asBool(const bool* const b)
{
    return b ? *b : false;
}

} // namespace blink

#endif  // SKY_ENGINE_V8_INSPECTOR_INSPECTORBASEAGENT_H_
