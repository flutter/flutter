/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPT_H_
#define SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPT_H_

#include "gen/sky/core/InspectorTypeBuilder.h"
#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/core/inspector/InjectedScriptBase.h"
#include "sky/engine/core/inspector/InjectedScriptManager.h"
#include "sky/engine/core/inspector/ScriptArguments.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class InjectedScriptModule;
class Node;
class SerializedScriptValue;

class InjectedScript final : public InjectedScriptBase {
public:
    InjectedScript();
    virtual ~InjectedScript() { }

    void evaluate(
        ErrorString*,
        const String& expression,
        const String& objectGroup,
        bool includeCommandLineAPI,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>*);
    void callFunctionOn(
        ErrorString*,
        const String& objectId,
        const String& expression,
        const String& arguments,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown);
    void evaluateOnCallFrame(
        ErrorString*,
        const ScriptValue& callFrames,
        const Vector<ScriptValue>& asyncCallStacks,
        const String& callFrameId,
        const String& expression,
        const String& objectGroup,
        bool includeCommandLineAPI,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>*);
    void restartFrame(ErrorString*, const ScriptValue& callFrames, const String& callFrameId, RefPtr<JSONObject>* result);
    void getStepInPositions(ErrorString*, const ScriptValue& callFrames, const String& callFrameId, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::Location> >& positions);
    void setVariableValue(ErrorString*, const ScriptValue& callFrames, const String* callFrameIdOpt, const String* functionObjectIdOpt, int scopeNumber, const String& variableName, const String& newValueStr);
    void getFunctionDetails(ErrorString*, const String& functionId, RefPtr<TypeBuilder::Debugger::FunctionDetails>* result);
    void getCollectionEntries(ErrorString*, const String& objectId, RefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CollectionEntry> >* result);
    void getProperties(ErrorString*, const String& objectId, bool ownProperties, bool accessorPropertiesOnly, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::PropertyDescriptor> >* result);
    void getInternalProperties(ErrorString*, const String& objectId, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::InternalPropertyDescriptor> >* result);
    Node* nodeForObjectId(const String& objectId);
    void releaseObject(const String& objectId);

    PassRefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> > wrapCallFrames(const ScriptValue&, int asyncOrdinal);

    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapObject(const ScriptValue&, const String& groupName, bool generatePreview = false) const;
    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapTable(const ScriptValue& table, const ScriptValue& columns) const;
    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapNode(Node*, const String& groupName);
    ScriptValue findObjectById(const String& objectId) const;

    void inspectNode(Node*);
    void releaseObjectGroup(const String&);

private:
    friend class InjectedScriptModule;
    friend InjectedScript InjectedScriptManager::injectedScriptFor(ScriptState*);
    explicit InjectedScript(ScriptValue);

    ScriptValue nodeAsScriptValue(Node*);
};


} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPT_H_
