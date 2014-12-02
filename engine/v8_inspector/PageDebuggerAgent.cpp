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

#include "sky/engine/config.h"
#include "sky/engine/v8_inspector/PageDebuggerAgent.h"

#include "sky/engine/bindings/core/v8/DOMWrapperWorld.h"
#include "sky/engine/bindings/core/v8/ScriptController.h"
#include "sky/engine/bindings/core/v8/ScriptSourceCode.h"
#include "sky/engine/core/frame/FrameConsole.h"
#include "sky/engine/v8_inspector/inspector_host.h"

namespace blink {

PassOwnPtr<PageDebuggerAgent> PageDebuggerAgent::create(PageScriptDebugServer* pageScriptDebugServer, inspector::InspectorHost* host, InjectedScriptManager* injectedScriptManager)
{
    return adoptPtr(new PageDebuggerAgent(pageScriptDebugServer, host, injectedScriptManager));
}

PageDebuggerAgent::PageDebuggerAgent(PageScriptDebugServer* pageScriptDebugServer, inspector::InspectorHost* host, InjectedScriptManager* injectedScriptManager)
    : InspectorDebuggerAgent(injectedScriptManager)
    , m_pageScriptDebugServer(pageScriptDebugServer)
    , m_host(host)
{
}

PageDebuggerAgent::~PageDebuggerAgent()
{
}

void PageDebuggerAgent::startListeningScriptDebugServer()
{
    scriptDebugServer().addListener(this, m_host);
}

void PageDebuggerAgent::stopListeningScriptDebugServer()
{
    scriptDebugServer().removeListener(this, m_host);
}

PageScriptDebugServer& PageDebuggerAgent::scriptDebugServer()
{
    return *m_pageScriptDebugServer;
}

void PageDebuggerAgent::muteConsole()
{
    FrameConsole::mute();
}

void PageDebuggerAgent::unmuteConsole()
{
    FrameConsole::unmute();
}

InjectedScript PageDebuggerAgent::injectedScriptForEval(ErrorString* errorString, const int* executionContextId)
{
    if (!executionContextId) {
        ScriptState* scriptState = ScriptState::from(m_host->GetContext());
        return injectedScriptManager()->injectedScriptFor(scriptState);
    }
    InjectedScript injectedScript = injectedScriptManager()->injectedScriptForId(*executionContextId);
    if (injectedScript.isEmpty())
        *errorString = "Execution context with given id not found.";
    return injectedScript;
}

void PageDebuggerAgent::setOverlayMessage(ErrorString*, const String* message)
{
    if (message)
        printf("OVERLAY MESSAGE: %s\n", message->ascii().data());
    else
        printf("OVERLAY REMOVED\n");
}

void PageDebuggerAgent::didClearDocumentOfWindowObject(LocalFrame* frame)
{
    reset();
    scriptDebugServer().setPreprocessorSource(String());
}

} // namespace blink
