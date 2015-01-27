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

#include "config.h"
#include "bindings/core/dart/DartPageDebuggerAgent.h"

#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/v8/DOMWrapperWorld.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "core/frame/FrameConsole.h"
#include "core/frame/LocalFrame.h"
#include "core/inspector/InspectorOverlay.h"
#include "core/inspector/InspectorPageAgent.h"
#include "core/inspector/InstrumentingAgents.h"
#include "core/loader/DocumentLoader.h"
#include "core/page/Page.h"

namespace blink {

PassOwnPtrWillBeRawPtr<DartPageDebuggerAgent> DartPageDebuggerAgent::create(DartScriptDebugServer* scriptDebugServer, InspectorDebuggerAgent* debuggerAgent, InspectorPageAgent* pageAgent, DartInjectedScriptManager* injectedScriptManager, InspectorOverlay* overlay)
{
    return adoptPtrWillBeNoop(new DartPageDebuggerAgent(scriptDebugServer, debuggerAgent, pageAgent, injectedScriptManager, overlay));
}

DartPageDebuggerAgent::DartPageDebuggerAgent(DartScriptDebugServer* scriptDebugServer, InspectorDebuggerAgent* debuggerAgent, InspectorPageAgent* pageAgent, DartInjectedScriptManager* injectedScriptManager, InspectorOverlay* overlay)
    : DartInspectorDebuggerAgent(injectedScriptManager, debuggerAgent, pageAgent)
    , m_scriptDebugServer(scriptDebugServer)
    , m_overlay(overlay)
{
    scriptDebugServer->setInjectedScriptManager(injectedScriptManager);
    ASSERT(m_scriptDebugServer);
    m_overlay->overlayHost()->setListener(this);
}

DartPageDebuggerAgent::~DartPageDebuggerAgent()
{
}

void DartPageDebuggerAgent::startListeningScriptDebugServer()
{
    m_scriptDebugServer->addListener(this, m_pageAgent->page());
}

void DartPageDebuggerAgent::stopListeningScriptDebugServer()
{
    m_scriptDebugServer->removeListener(this, m_pageAgent->page());
}

DartScriptDebugServer& DartPageDebuggerAgent::scriptDebugServer()
{
    return *m_scriptDebugServer;
}

void DartPageDebuggerAgent::muteConsole()
{
    FrameConsole::mute();
}

void DartPageDebuggerAgent::unmuteConsole()
{
    FrameConsole::unmute();
}

void DartPageDebuggerAgent::overlayResumed()
{
    ErrorString error;
    resume(&error);
}

void DartPageDebuggerAgent::overlaySteppedOver()
{
    ErrorString error;
    stepOver(&error);
}

DartInjectedScript* DartPageDebuggerAgent::injectedScriptForEval(ErrorString* errorString, const int* executionContextId)
{
    ASSERT(executionContextId);
    DartInjectedScript* injectedScript = injectedScriptManager()->injectedScriptForId(*executionContextId);
    if (!injectedScript)
        *errorString = "Execution context with given id not found.";
    return injectedScript;
}

void DartPageDebuggerAgent::setOverlayMessage(ErrorString*, const String* message)
{
    m_overlay->setPausedInDebuggerMessage(message);
}

void DartPageDebuggerAgent::didClearDocumentOfWindowObject(LocalFrame* frame)
{
    if (frame != m_pageAgent->mainFrame())
        return;

    reset();
}

void DartPageDebuggerAgent::didCommitLoad(LocalFrame* frame, DocumentLoader* loader)
{
    Frame* mainFrame = frame->page()->deprecatedLocalMainFrame();
    if (loader->frame() == mainFrame)
        pageDidCommitLoad();
}

} // namespace blink

