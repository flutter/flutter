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

#include "sky/engine/config.h"
#include "sky/engine/bindings/core/v8/DOMWrapperWorld.h"

#include "bindings/core/v8/V8Window.h"
#include "sky/engine/bindings/core/v8/DOMDataStore.h"
#include "sky/engine/bindings/core/v8/ScriptController.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8DOMWrapper.h"
#include "sky/engine/bindings/core/v8/WindowProxy.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/wtf/HashTraits.h"
#include "sky/engine/wtf/StdLibExtras.h"

namespace blink {

unsigned DOMWrapperWorld::isolatedWorldCount = 0;
DOMWrapperWorld* DOMWrapperWorld::worldOfInitializingWindow = 0;

PassRefPtr<DOMWrapperWorld> DOMWrapperWorld::create(int worldId, int extensionGroup)
{
    return adoptRef(new DOMWrapperWorld(worldId, extensionGroup));
}

DOMWrapperWorld::DOMWrapperWorld(int worldId, int extensionGroup)
    : m_worldId(worldId)
    , m_extensionGroup(extensionGroup)
    , m_domDataStore(adoptPtr(new DOMDataStore(isMainWorld())))
{
}

DOMWrapperWorld& DOMWrapperWorld::mainWorld()
{
    ASSERT(isMainThread());
    DEFINE_STATIC_REF(DOMWrapperWorld, cachedMainWorld, (DOMWrapperWorld::create(MainWorldId, mainWorldExtensionGroup)));
    return *cachedMainWorld;
}

typedef HashMap<int, DOMWrapperWorld*> WorldMap;
static WorldMap& isolatedWorldMap()
{
    ASSERT(isMainThread());
    DEFINE_STATIC_LOCAL(WorldMap, map, ());
    return map;
}

void DOMWrapperWorld::allWorldsInMainThread(Vector<RefPtr<DOMWrapperWorld> >& worlds)
{
    ASSERT(isMainThread());
    worlds.append(&mainWorld());
    WorldMap& isolatedWorlds = isolatedWorldMap();
    for (WorldMap::iterator it = isolatedWorlds.begin(); it != isolatedWorlds.end(); ++it)
        worlds.append(it->value);
}

DOMWrapperWorld::~DOMWrapperWorld()
{
    ASSERT(!isMainWorld());

    dispose();

    if (!isIsolatedWorld())
        return;

    WorldMap& map = isolatedWorldMap();
    WorldMap::iterator it = map.find(m_worldId);
    if (it == map.end()) {
        ASSERT_NOT_REACHED();
        return;
    }
    ASSERT(it->value == this);

    map.remove(it);
    isolatedWorldCount--;
}

void DOMWrapperWorld::dispose()
{
    m_domObjectHolders.clear();
    m_domDataStore.clear();
}

#if ENABLE(ASSERT)
static bool isIsolatedWorldId(int worldId)
{
    return MainWorldId < worldId  && worldId < IsolatedWorldIdLimit;
}
#endif

PassRefPtr<DOMWrapperWorld> DOMWrapperWorld::ensureIsolatedWorld(int worldId, int extensionGroup)
{
    ASSERT(isIsolatedWorldId(worldId));

    WorldMap& map = isolatedWorldMap();
    WorldMap::AddResult result = map.add(worldId, 0);
    RefPtr<DOMWrapperWorld> world = result.storedValue->value;
    if (world) {
        ASSERT(world->worldId() == worldId);
        ASSERT(world->extensionGroup() == extensionGroup);
        return world.release();
    }

    world = DOMWrapperWorld::create(worldId, extensionGroup);
    result.storedValue->value = world.get();
    isolatedWorldCount++;
    return world.release();
}

typedef HashMap<int, String > IsolatedWorldHumanReadableNameMap;
static IsolatedWorldHumanReadableNameMap& isolatedWorldHumanReadableNames()
{
    ASSERT(isMainThread());
    DEFINE_STATIC_LOCAL(IsolatedWorldHumanReadableNameMap, map, ());
    return map;
}

String DOMWrapperWorld::isolatedWorldHumanReadableName()
{
    ASSERT(this->isIsolatedWorld());
    return isolatedWorldHumanReadableNames().get(worldId());
}

void DOMWrapperWorld::setIsolatedWorldHumanReadableName(int worldId, const String& humanReadableName)
{
    ASSERT(isIsolatedWorldId(worldId));
    isolatedWorldHumanReadableNames().set(worldId, humanReadableName);
}

void DOMWrapperWorld::registerDOMObjectHolderInternal(PassOwnPtr<DOMObjectHolderBase> holderBase)
{
    ASSERT(!m_domObjectHolders.contains(holderBase.get()));
    holderBase->setWorld(this);
    holderBase->setWeak(&DOMWrapperWorld::weakCallbackForDOMObjectHolder);
    m_domObjectHolders.add(holderBase);
}

void DOMWrapperWorld::unregisterDOMObjectHolder(DOMObjectHolderBase* holderBase)
{
    ASSERT(m_domObjectHolders.contains(holderBase));
    m_domObjectHolders.remove(holderBase);
}

void DOMWrapperWorld::weakCallbackForDOMObjectHolder(const v8::WeakCallbackData<v8::Value, DOMObjectHolderBase>& data)
{
    DOMObjectHolderBase* holderBase = data.GetParameter();
    holderBase->world()->unregisterDOMObjectHolder(holderBase);
}

} // namespace blink
