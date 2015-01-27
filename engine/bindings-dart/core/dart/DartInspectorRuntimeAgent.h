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

#ifndef DartInspectorRuntimeAgent_h
#define DartInspectorRuntimeAgent_h

#include "core/InspectorFrontend.h"
#include "core/inspector/InspectorBaseAgent.h"
#include "core/inspector/InspectorRuntimeAgent.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"

namespace blink {

class DartInjectedScript;
class InjectedScriptManager;
class InstrumentingAgents;
class JSONArray;
class ScriptState;
class DartInjectedScriptManager;

typedef String ErrorString;

class DartInspectorRuntimeAgent {
    WTF_MAKE_NONCOPYABLE(DartInspectorRuntimeAgent);
public:
    DartInspectorRuntimeAgent(DartInjectedScriptManager*, InspectorRuntimeAgent*);

    void evaluate(ErrorString*,
        const String& expression,
        const String* objectGroup,
        const bool* includeCommandLineAPI,
        const bool* doNotPauseOnExceptionsAndMuteConsole,
        const int* executionContextId,
        const bool* returnByValue,
        const bool* generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>& result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>&);

    void callFunctionOn(ErrorString*,
        const String& objectId,
        const String& expression,
        const RefPtr<JSONArray>* optionalArguments,
        const bool* doNotPauseOnExceptionsAndMuteConsole,
        const bool* returnByValue,
        const bool* generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>& result,
        TypeBuilder::OptOutput<bool>* wasThrown);
    void releaseObject(ErrorString*, const String& objectId);
    void getCompletions(ErrorString*,
        const String& expression,
        const int* executionContextId,
        RefPtr<TypeBuilder::Array<String> >& result);

    void releaseObjectGroup(ErrorString*, const String& objectGroup);

    void getProperties(ErrorString*, const String& objectId, const bool* ownProperties, const bool* accessorPropertiesOnly, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::PropertyDescriptor> >& result, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::InternalPropertyDescriptor> >& internalProperties);
    void getProperty(ErrorString*, const String& objectId, const RefPtr<JSONArray>& propertyPath, RefPtr<TypeBuilder::Runtime::RemoteObject>& result, TypeBuilder::OptOutput<bool>* wasThrown);

    int addExecutionContextToFrontendHelper(ScriptState*, bool isPageContext, const String& name, const String& frameId);
private:
    DartInjectedScript* injectedScriptForEval(ErrorString*, const int* executionContextId);

    DartInjectedScriptManager* m_injectedScriptManager;
    InspectorRuntimeAgent* m_inspectorRuntimeAgent;
};

} // namespace blink

#endif // InspectorRuntimeAgent_h
