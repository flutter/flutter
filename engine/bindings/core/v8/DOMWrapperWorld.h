/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_DOMWRAPPERWORLD_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_DOMWRAPPERWORLD_H_

#include "sky/engine/bindings/core/v8/ScriptState.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/MainThread.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/WTFString.h"
#include "v8/include/v8.h"

namespace blink {

class DOMDataStore;
class ExecutionContext;
class ScriptController;

enum WorldIdConstants {
    MainWorldId = 0,
    // Embedder isolated worlds can use IDs in [1, 1<<29).
    EmbedderWorldIdLimit = (1 << 29),
    IsolatedWorldIdLimit,
    TestingWorldId,
};

// This class represent a collection of DOM wrappers for a specific world.
class DOMWrapperWorld : public RefCounted<DOMWrapperWorld> {
public:
    static PassRefPtr<DOMWrapperWorld> create(int worldId = -1, int extensionGroup = -1);

    static const int mainWorldExtensionGroup = 0;
    static PassRefPtr<DOMWrapperWorld> ensureIsolatedWorld(int worldId, int extensionGroup);
    ~DOMWrapperWorld();
    void dispose();

    static bool isolatedWorldsExist() { return isolatedWorldCount; }
    static void allWorldsInMainThread(Vector<RefPtr<DOMWrapperWorld> >& worlds);

    static DOMWrapperWorld& world(v8::Handle<v8::Context> context)
    {
        return ScriptState::from(context)->world();
    }

    static DOMWrapperWorld& current(v8::Isolate* isolate)
    {
        if (isMainThread() && worldOfInitializingWindow) {
            // It's possible that current() is being called while window is being initialized.
            // In order to make current() workable during the initialization phase,
            // we cache the world of the initializing window on worldOfInitializingWindow.
            // If there is no initiazing window, worldOfInitializingWindow is 0.
            return *worldOfInitializingWindow;
        }
        return world(isolate->GetCurrentContext());
    }

    static DOMWrapperWorld& mainWorld();

    static void setIsolatedWorldHumanReadableName(int worldID, const String&);
    String isolatedWorldHumanReadableName();

    bool isMainWorld() const { return m_worldId == MainWorldId; }
    bool isIsolatedWorld() const { return MainWorldId < m_worldId  && m_worldId < IsolatedWorldIdLimit; }

    int worldId() const { return m_worldId; }
    int extensionGroup() const { return m_extensionGroup; }
    DOMDataStore& domDataStore() const { return *m_domDataStore; }

    static void setWorldOfInitializingWindow(DOMWrapperWorld* world)
    {
        ASSERT(isMainThread());
        worldOfInitializingWindow = world;
    }
    // FIXME: Remove this method once we fix crbug.com/345014.
    static bool windowIsBeingInitialized() { return !!worldOfInitializingWindow; }

private:
    class DOMObjectHolderBase {
    public:
        DOMObjectHolderBase(v8::Isolate* isolate, v8::Handle<v8::Value> wrapper)
            : m_wrapper(isolate, wrapper)
            , m_world(0)
        {
        }
        virtual ~DOMObjectHolderBase() { }

        DOMWrapperWorld* world() const { return m_world; }
        void setWorld(DOMWrapperWorld* world) { m_world = world; }
        void setWeak(void (*callback)(const v8::WeakCallbackData<v8::Value, DOMObjectHolderBase>&))
        {
            m_wrapper.setWeak(this, callback);
        }

    private:
        ScopedPersistent<v8::Value> m_wrapper;
        DOMWrapperWorld* m_world;
    };

    template<typename T>
    class DOMObjectHolder : public DOMObjectHolderBase {
    public:
        static PassOwnPtr<DOMObjectHolder<T> > create(v8::Isolate* isolate, T* object, v8::Handle<v8::Value> wrapper)
        {
            return adoptPtr(new DOMObjectHolder(isolate, object, wrapper));
        }

    private:
        DOMObjectHolder(v8::Isolate* isolate, T* object, v8::Handle<v8::Value> wrapper)
            : DOMObjectHolderBase(isolate, wrapper)
            , m_object(object)
        {
        }

        OwnPtr<T> m_object;
    };

public:
    template<typename T>
    void registerDOMObjectHolder(v8::Isolate* isolate, T* object, v8::Handle<v8::Value> wrapper)
    {
        registerDOMObjectHolderInternal(DOMObjectHolder<T>::create(isolate, object, wrapper));
    }

private:
    DOMWrapperWorld(int worldId, int extensionGroup);

    static void weakCallbackForDOMObjectHolder(const v8::WeakCallbackData<v8::Value, DOMObjectHolderBase>&);
    void registerDOMObjectHolderInternal(PassOwnPtr<DOMObjectHolderBase>);
    void unregisterDOMObjectHolder(DOMObjectHolderBase*);

    static unsigned isolatedWorldCount;
    static DOMWrapperWorld* worldOfInitializingWindow;

    const int m_worldId;
    const int m_extensionGroup;
    OwnPtr<DOMDataStore> m_domDataStore;
    HashSet<OwnPtr<DOMObjectHolderBase> > m_domObjectHolders;
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_DOMWRAPPERWORLD_H_
