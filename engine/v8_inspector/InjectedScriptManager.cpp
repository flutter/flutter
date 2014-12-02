/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Matt Lilek <webkit@mattlilek.com>
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/v8_inspector/InjectedScriptManager.h"

#include "sky/engine/bindings/core/v8/ScriptValue.h"
#include "sky/engine/core/inspector/InjectedScriptHost.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebData.h"
#include "sky/engine/v8_inspector/InjectedScript.h"
#include "sky/engine/v8_inspector/JSONParser.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

PassOwnPtr<InjectedScriptManager> InjectedScriptManager::createForPage()
{
    return adoptPtr(new InjectedScriptManager);
}

InjectedScriptManager::InjectedScriptManager()
    : m_nextInjectedScriptId(1)
    , m_injectedScriptHost(InjectedScriptHost::create())
{
}

InjectedScriptManager::~InjectedScriptManager()
{
}

void InjectedScriptManager::disconnect()
{
    m_injectedScriptHost->disconnect();
    m_injectedScriptHost.clear();
}

InjectedScriptHost* InjectedScriptManager::injectedScriptHost()
{
    return m_injectedScriptHost.get();
}

InjectedScript InjectedScriptManager::injectedScriptForId(int id)
{
    IdToInjectedScriptMap::iterator it = m_idToInjectedScript.find(id);
    if (it != m_idToInjectedScript.end())
        return it->value;
    for (ScriptStateToId::iterator it = m_scriptStateToId.begin(); it != m_scriptStateToId.end(); ++it) {
        if (it->value == id)
            return injectedScriptFor(it->key.get());
    }
    return InjectedScript();
}

int InjectedScriptManager::injectedScriptIdFor(ScriptState* scriptState)
{
    ScriptStateToId::iterator it = m_scriptStateToId.find(scriptState);
    if (it != m_scriptStateToId.end())
        return it->value;
    int id = m_nextInjectedScriptId++;
    m_scriptStateToId.set(scriptState, id);
    return id;
}

InjectedScript InjectedScriptManager::injectedScriptForObjectId(const String& objectId)
{
    RefPtr<JSONValue> parsedObjectId = parseJSON(objectId);
    if (parsedObjectId && parsedObjectId->type() == JSONValue::TypeObject) {
        long injectedScriptId = 0;
        bool success = parsedObjectId->asObject()->getNumber("injectedScriptId", &injectedScriptId);
        if (success)
            return m_idToInjectedScript.get(injectedScriptId);
    }
    return InjectedScript();
}

void InjectedScriptManager::discardInjectedScripts()
{
    m_idToInjectedScript.clear();
    m_scriptStateToId.clear();
}

void InjectedScriptManager::discardInjectedScriptsFor(LocalDOMWindow* window)
{
    if (m_scriptStateToId.isEmpty())
        return;

    Vector<long> idsToRemove;
    IdToInjectedScriptMap::iterator end = m_idToInjectedScript.end();
    for (IdToInjectedScriptMap::iterator it = m_idToInjectedScript.begin(); it != end; ++it) {
        ScriptState* scriptState = it->value.scriptState();
        if (window != scriptState->domWindow())
            continue;
        m_scriptStateToId.remove(scriptState);
        idsToRemove.append(it->key);
    }
    m_idToInjectedScript.removeAll(idsToRemove);

    // Now remove script states that have id but no injected script.
    Vector<ScriptState*> scriptStatesToRemove;
    for (ScriptStateToId::iterator it = m_scriptStateToId.begin(); it != m_scriptStateToId.end(); ++it) {
        ScriptState* scriptState = it->key.get();
        if (window == scriptState->domWindow())
            scriptStatesToRemove.append(scriptState);
    }
    m_scriptStateToId.removeAll(scriptStatesToRemove);
}

void InjectedScriptManager::releaseObjectGroup(const String& objectGroup)
{
    Vector<int> keys;
    keys.appendRange(m_idToInjectedScript.keys().begin(), m_idToInjectedScript.keys().end());
    for (Vector<int>::iterator k = keys.begin(); k != keys.end(); ++k) {
        IdToInjectedScriptMap::iterator s = m_idToInjectedScript.find(*k);
        if (s != m_idToInjectedScript.end())
            s->value.releaseObjectGroup(objectGroup); // m_idToInjectedScript may change here.
    }
}

String InjectedScriptManager::injectedScriptSource()
{
    const blink::WebData& injectedScriptSourceResource = blink::Platform::current()->loadResource("InjectedScriptSource.js");
    return String(injectedScriptSourceResource.data(), injectedScriptSourceResource.size());
}

InjectedScript InjectedScriptManager::injectedScriptFor(ScriptState* inspectedScriptState)
{
    ScriptStateToId::iterator it = m_scriptStateToId.find(inspectedScriptState);
    if (it != m_scriptStateToId.end()) {
        IdToInjectedScriptMap::iterator it1 = m_idToInjectedScript.find(it->value);
        if (it1 != m_idToInjectedScript.end())
            return it1->value;
    }

    int id = injectedScriptIdFor(inspectedScriptState);
    ScriptValue injectedScriptValue = createInjectedScript(injectedScriptSource(), inspectedScriptState, id);
    InjectedScript result(injectedScriptValue);
    m_idToInjectedScript.set(id, result);

    // TODO(yurys): InjecedScript should be available as a regular module rather that using a global variable.
    v8::Isolate* isolate = inspectedScriptState->isolate();
    v8::Local<v8::Object> global = inspectedScriptState->context()->Global();
    global->Set(v8::String::NewFromUtf8(isolate, "injectedScript"), injectedScriptValue.v8ValueUnsafe());
    return result;
}

} // namespace blink

