/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "bindings/core/dart/DartInspectorConsoleMessage.h"

#include "bindings/common/ScriptValue.h"
#include "bindings/core/dart/DartInjectedScript.h"
#include "bindings/core/dart/DartInjectedScriptManager.h"
#include "core/inspector/InjectedScriptManager.h"
#include "core/inspector/InspectorConsoleMessage.h"
#include "core/inspector/ScriptCallStack.h"

namespace blink {

void DartInspectorConsoleMessage::addToFrontend(InspectorFrontend::Console* frontend, InjectedScriptManager* injectedScriptManager, bool generatePreview, InspectorConsoleMessage* consoleMessage, RefPtr<TypeBuilder::Console::ConsoleMessage> jsonObj)
{
    ScriptState* scriptState = consoleMessage->m_scriptState.get();

    DartInjectedScriptManager* dartInjectedScriptManager = injectedScriptManager->dartInjectedScriptManager();
    jsonObj->setExecutionContextId(dartInjectedScriptManager->injectedScriptIdFor(scriptState));
    if (consoleMessage->m_source == NetworkMessageSource && !consoleMessage->m_requestId.isEmpty())
        jsonObj->setNetworkRequestId(consoleMessage->m_requestId);
    if (consoleMessage->m_arguments && consoleMessage->m_arguments->argumentCount()) {
        DartInjectedScript* injectedScript = dartInjectedScriptManager->injectedScriptFor(consoleMessage->m_arguments->scriptState());

        if (injectedScript) {
            RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::RemoteObject> > jsonArgs = TypeBuilder::Array<TypeBuilder::Runtime::RemoteObject>::create();
            if (consoleMessage->m_type == TableMessageType && generatePreview && consoleMessage->m_arguments->argumentCount()) {
                ScriptValue table = consoleMessage->m_arguments->argumentAt(0);
                ScriptValue columns = consoleMessage->m_arguments->argumentCount() > 1 ? consoleMessage->m_arguments->argumentAt(1) : ScriptValue();
                RefPtr<TypeBuilder::Runtime::RemoteObject> inspectorValue = injectedScript->wrapTable(table, columns);
                if (!inspectorValue) {
                    ASSERT_NOT_REACHED();
                    return;
                }
                jsonArgs->addItem(inspectorValue);
            } else {
                for (unsigned i = 0; i < consoleMessage->m_arguments->argumentCount(); ++i) {
                    ScriptValue value = consoleMessage->m_arguments->argumentAt(i);
                    RefPtr<TypeBuilder::Runtime::RemoteObject> inspectorValue;
                    inspectorValue = injectedScript->wrapObject(consoleMessage->m_arguments->argumentAt(i), "console", generatePreview);
                    if (!inspectorValue) {
                        ASSERT_NOT_REACHED();
                        return;
                    }
                    jsonArgs->addItem(inspectorValue);
                }
            }
            jsonObj->setParameters(jsonArgs);
        }
    }
    if (consoleMessage->m_callStack) {
        // FIXMEDART: is the call stack right?
        jsonObj->setStackTrace(consoleMessage->m_callStack->buildInspectorArray());
    }
    frontend->messageAdded(jsonObj);
    frontend->flush();
}

} // namespace blink
