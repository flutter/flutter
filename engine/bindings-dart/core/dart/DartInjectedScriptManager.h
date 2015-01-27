/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
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

#ifndef DartInjectedScriptManager_h
#define DartInjectedScriptManager_h

#include "bindings/common/ScriptState.h"
#include "bindings/core/v8/ScopedPersistent.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class LocalDOMWindow;
class DartInjectedScript;
class InjectedScriptHost;
class ScriptValue;
class InjectedScriptManager;

// This is a snapshot of InjectedScriptManager at 38 refactored to only support Dart
// with functionality not of interest to Dart removed.
class DartInjectedScriptManager {
    WTF_MAKE_NONCOPYABLE(DartInjectedScriptManager);
public:
    typedef bool (*InspectedStateAccessCheck)(ScriptState*);

    explicit DartInjectedScriptManager(InspectedStateAccessCheck, InjectedScriptManager* javaScriptInjectedScriptManager);
    ~DartInjectedScriptManager();

    InjectedScriptHost* injectedScriptHost();

    DartInjectedScript* injectedScriptFor(ScriptState*);
    DartInjectedScript* injectedScriptForId(int);
    int injectedScriptIdFor(ScriptState*);
    DartInjectedScript* injectedScriptForObjectId(const String& objectId);
    void discardInjectedScripts();
    void discardInjectedScriptsFor(LocalDOMWindow*);
    void releaseObjectGroup(const String& objectGroup);

    InspectedStateAccessCheck inspectedStateAccessCheck() const { return m_inspectedStateAccessCheck; }

    InjectedScriptManager* javaScriptInjectedScriptManager() { return m_javaScriptInjectedScriptManager; }

private:
    static bool canAccessInspectedWindow(ScriptState*);
    static bool canAccessInspectedWorkerGlobalScope(ScriptState*);

    int m_nextInjectedScriptId;
    // FIXMEDART: use RefPtr<DartInjectedScript> instead.
    typedef HashMap<int, DartInjectedScript*> IdToInjectedScriptMap;
    IdToInjectedScriptMap m_idToInjectedScript;
    InspectedStateAccessCheck m_inspectedStateAccessCheck;
    typedef HashMap<RefPtr<ScriptState>, int> ScriptStateToId;
    ScriptStateToId m_scriptStateToId;
    InjectedScriptManager* m_javaScriptInjectedScriptManager;
};

} // namespace blink

#endif // !defined(DartInjectedScriptManager_h)
