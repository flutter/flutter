/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef DartPageDebuggerAgent_h
#define DartPageDebuggerAgent_h

#include "bindings/core/dart/DartInspectorDebuggerAgent.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "core/inspector/InspectorDebuggerAgent.h"
#include "core/inspector/InspectorOverlayHost.h"

namespace blink {

class DocumentLoader;
class InspectorOverlay;
class InspectorPageAgent;
class Page;
class UnifiedScriptDebugServer;
class ScriptSourceCode;

class DartPageDebuggerAgent FINAL
    : public DartInspectorDebuggerAgent
    , public InspectorOverlayHost::Listener {
    WTF_MAKE_NONCOPYABLE(DartPageDebuggerAgent);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(DartPageDebuggerAgent);
public:
    static PassOwnPtrWillBeRawPtr<DartPageDebuggerAgent> create(DartScriptDebugServer*, InspectorDebuggerAgent*, InspectorPageAgent*, DartInjectedScriptManager*, InspectorOverlay*);
    virtual ~DartPageDebuggerAgent();

    void didClearDocumentOfWindowObject(LocalFrame*);
    void didCommitLoad(LocalFrame*, DocumentLoader*);

private:
    virtual void startListeningScriptDebugServer() OVERRIDE;
    virtual void stopListeningScriptDebugServer() OVERRIDE;
    virtual DartScriptDebugServer& scriptDebugServer() OVERRIDE;
    virtual void muteConsole() OVERRIDE;
    virtual void unmuteConsole() OVERRIDE;

    // InspectorOverlayHost::Listener implementation.
    virtual void overlayResumed() OVERRIDE;
    virtual void overlaySteppedOver() OVERRIDE;

    virtual DartInjectedScript* injectedScriptForEval(ErrorString*, const int* executionContextId) OVERRIDE;
    virtual void setOverlayMessage(ErrorString*, const String*) OVERRIDE;

    DartPageDebuggerAgent(DartScriptDebugServer*, InspectorDebuggerAgent*, InspectorPageAgent*, DartInjectedScriptManager*, InspectorOverlay*);
    // FIXME: with Oilpan we may need to move m_scriptDebugServer to heap in follow-up CL.
    DartScriptDebugServer* m_scriptDebugServer;
    InspectorOverlay* m_overlay;
};

} // namespace blink


#endif // !defined(DartPageDebuggerAgent_h)
