/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPTMANAGER_H_
#define SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPTMANAGER_H_

#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "v8/include/v8.h"

namespace blink {

class LocalDOMWindow;
class InjectedScript;
class InjectedScriptHost;
class ScriptValue;

class InjectedScriptManager {
    WTF_MAKE_NONCOPYABLE(InjectedScriptManager);
    WTF_MAKE_FAST_ALLOCATED;
public:
    struct CallbackData {
        ScopedPersistent<v8::Object> handle;
        RefPtr<InjectedScriptHost> host;
        InjectedScriptManager* injectedScriptManager;
    };

    static PassOwnPtr<InjectedScriptManager> createForPage();
    ~InjectedScriptManager();

    void disconnect();

    InjectedScriptHost* injectedScriptHost();

    InjectedScript injectedScriptFor(ScriptState*);
    InjectedScript injectedScriptForId(int);
    int injectedScriptIdFor(ScriptState*);
    InjectedScript injectedScriptForObjectId(const String& objectId);
    void discardInjectedScripts();
    void discardInjectedScriptsFor(LocalDOMWindow*);
    void releaseObjectGroup(const String& objectGroup);

    static void setWeakCallback(const v8::WeakCallbackData<v8::Object, CallbackData>&);
    CallbackData* createCallbackData(InjectedScriptManager*);
    void removeCallbackData(CallbackData*);

private:
    explicit InjectedScriptManager();

    String injectedScriptSource();
    ScriptValue createInjectedScript(const String& source, ScriptState*, int id);

    int m_nextInjectedScriptId;
    typedef HashMap<int, InjectedScript> IdToInjectedScriptMap;
    IdToInjectedScriptMap m_idToInjectedScript;
    RefPtr<InjectedScriptHost> m_injectedScriptHost;
    typedef HashMap<RefPtr<ScriptState>, int> ScriptStateToId;
    ScriptStateToId m_scriptStateToId;
    HashSet<OwnPtr<CallbackData> > m_callbackDataSet;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_INSPECTOR_INJECTEDSCRIPTMANAGER_H_
