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

PassRefPtr<DOMWrapperWorld> DOMWrapperWorld::create(FakeWorldMarker marker)
{
    return adoptRef(new DOMWrapperWorld(marker));
}

DOMWrapperWorld::DOMWrapperWorld(FakeWorldMarker marker)
    : m_isFakeWorld(marker == FakeWorld)
    , m_domDataStore(adoptPtr(new DOMDataStore(isMainWorld())))
{
}

DOMWrapperWorld& DOMWrapperWorld::mainWorld()
{
    ASSERT(isMainThread());
    DEFINE_STATIC_REF(DOMWrapperWorld, cachedMainWorld, (DOMWrapperWorld::create(MainWorld)));
    return *cachedMainWorld;
}

DOMWrapperWorld::~DOMWrapperWorld()
{
    ASSERT(!isMainWorld());

    dispose();
}

void DOMWrapperWorld::dispose()
{
    m_domObjectHolders.clear();
    m_domDataStore.clear();
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
