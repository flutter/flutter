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

#ifndef DartInjectedScript_h
#define DartInjectedScript_h

#include "bindings/common/ScriptState.h"
#include "bindings/common/ScriptValue.h"
#include "core/InspectorTypeBuilder.h"
#include "core/inspector/InjectedScript.h"
#include "core/inspector/InjectedScriptBase.h"
#include "core/inspector/InjectedScriptManager.h"
#include "core/inspector/ScriptArguments.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"

#include <dart_debugger_api.h>

namespace blink {

class DartScriptState;
class JSONValue;
class ScriptFunctionCall;

class DartDebuggerObject {
    WTF_MAKE_NONCOPYABLE(DartDebuggerObject);
public:
    // FIXME: consider merging ObjectClass and Class, and Object if possible.
    enum Kind {
        Object,
        ObjectClass,
        Function,
        Method,
        Class,
        StaticClass,
        Library,
        CurrentLibrary,
        Isolate,
        LocalVariables,
        Error
    };

    DartDebuggerObject(Dart_PersistentHandle, const String& objectGroup, Kind);
    ~DartDebuggerObject();
    const String& group() const { return m_group; }
    Dart_PersistentHandle persistentHandle() const { return m_handle; }
    Dart_Handle handle() const { return m_handle; }
    Kind kind() const { return m_kind; }

private:
    Dart_PersistentHandle m_handle;
    String m_group;
    Kind m_kind;
};

class DartInjectedScript {
public:
    DartInjectedScript();
    DartInjectedScript(DartScriptState*, InjectedScriptManager::InspectedStateAccessCheck, int injectedScriptId, InjectedScriptHost*, InjectedScriptManager*);
    ~DartInjectedScript();

    const String& name() const { return m_name; }

    void evaluate(ErrorString*,
        const String& expression,
        const String& objectGroup,
        bool includeCommandLineAPI,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>*);
    void callFunctionOn(ErrorString*,
        const String& objectId,
        const String& expression,
        const String& arguments,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown);
    void evaluateOnCallFrame(ErrorString*,
        const Dart_StackTrace callFrames,
        const String& callFrameId,
        const String& expression,
        const String& objectGroup,
        bool includeCommandLineAPI,
        bool returnByValue,
        bool generatePreview,
        RefPtr<TypeBuilder::Runtime::RemoteObject>* result,
        TypeBuilder::OptOutput<bool>* wasThrown,
        RefPtr<TypeBuilder::Debugger::ExceptionDetails>*);
    void getCompletionsOnCallFrame(
        ErrorString*,
        const Dart_StackTrace callFrames,
        const String& callFrameId,
        const String& expression,
        RefPtr<TypeBuilder::Array<String> >* result);
    void restartFrame(ErrorString*, const Dart_StackTrace callFrames, const String& callFrameId, RefPtr<JSONObject>* result);
    void setVariableValue(ErrorString*, const Dart_StackTrace callFrames, const String* callFrameIdOpt, const String* functionObjectIdOpt, int scopeNumber, const String& variableName, const String& newValueStr);
    void getFunctionDetails(ErrorString*, const String& functionId, RefPtr<TypeBuilder::Debugger::FunctionDetails>* result);
    void getCompletions(ErrorString*, const String& expression, RefPtr<TypeBuilder::Array<String> >* out_result);
    void getProperties(ErrorString*, const String& objectId, bool ownProperties, bool accessorPropertiesOnly, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::PropertyDescriptor> >* result);
    void getInternalProperties(ErrorString*, const String& objectId, RefPtr<TypeBuilder::Array<TypeBuilder::Runtime::InternalPropertyDescriptor> >* result);
    void getProperty(ErrorString*, const String& objectId, const RefPtr<JSONArray>& propertyPath, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);

    Node* nodeForObjectId(const String& objectId);
    void releaseObject(const String& objectId);

    PassRefPtr<TypeBuilder::Array<TypeBuilder::Debugger::CallFrame> > wrapCallFrames(const Dart_StackTrace, int asyncOrdinal);

    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapObject(const ScriptValue&, const String& groupName, bool generatePreview = false);
    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapTable(const ScriptValue& table, const ScriptValue& columns);

    ScriptValue findObjectById(const String& objectId) const;
    void inspectNode(Node*);
    void releaseObjectGroup(const String&);

    bool isEmpty() const { return !m_scriptState; }

    DartScriptState* scriptState() const;

    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapDartObject(Dart_Handle, const String& groupName, bool generatePreview = false);

    bool canAccessInspectedWindow() const;
    static bool isDartObjectId(const String& objectId);

    InjectedScriptManager* injectedScriptManager() { return m_injectedScriptManager; }
private:
    Dart_Handle library();

    friend class InjectedScriptModule;
    friend InjectedScript InjectedScriptManager::injectedScriptFor(ScriptState*);

    bool validateObjectId(const String& objectId);

    PassRefPtr<TypeBuilder::Runtime::RemoteObject> wrapDartHandle(Dart_Handle, DartDebuggerObject::Kind, const String& groupName, bool generatePreview);

    DartDebuggerObject::Kind inferKind(Dart_Handle);

    String cacheObject(Dart_Handle, const String& objectGroup, DartDebuggerObject::Kind);
    DartDebuggerObject* lookupObject(const String& objectId);

    void evaluateAndPackageResult(Dart_Handle target, const String& rawExpression, Dart_Handle localVariables, bool includeCommandLineAPI, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown, RefPtr<TypeBuilder::Debugger::ExceptionDetails>*);
    Dart_Handle evaluateHelper(Dart_Handle target, const String& rawExpression, Dart_Handle localVariables, bool includeCommandLineAPI, Dart_Handle& exception);
    PassRefPtr<TypeBuilder::Array<TypeBuilder::Console::CallFrame> > consoleCallFrames(Dart_StackTrace);

    void packageResult(Dart_Handle, DartDebuggerObject::Kind, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageObjectResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageObjectClassResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageLibraryResult(Dart_Handle, DartDebuggerObject::Kind, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageIsolateResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageClassResult(Dart_Handle, DartDebuggerObject::Kind, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageFunctionResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageMethodResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageLocalVariablesResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);
    void packageErrorResult(Dart_Handle, const String& objectGroup, ErrorString*, bool returnByValue, bool generatePreview, RefPtr<TypeBuilder::Runtime::RemoteObject>* result, TypeBuilder::OptOutput<bool>* wasThrown);

    String getCallFrameId(int ordinal, int asyncOrdinal);
    Dart_ActivationFrame callFrameForId(const Dart_StackTrace callFrames, const String& callFrameId);

    Dart_Handle consoleApi();

    String m_name;
    InjectedScriptManager::InspectedStateAccessCheck m_inspectedStateAccessCheck;

    typedef HashMap<String, Vector<String> > ObjectGroupMap;
    ObjectGroupMap m_objectGroups;

    // FIXME: use RefPtr<DartDebuggerObject> instead of DartDebuggerObject*
    typedef HashMap<String, DartDebuggerObject*> DebuggerObjectMap;
    DebuggerObjectMap m_objects;

    DartScriptState* m_scriptState;

    long m_nextObjectId;
    int m_injectedScriptId;
    InjectedScriptHost* m_host;
    InjectedScriptManager* m_injectedScriptManager;
    Dart_PersistentHandle m_consoleApi;
};

} // namespace blink

#endif
