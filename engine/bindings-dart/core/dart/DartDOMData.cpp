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

#include "config.h"
#include "bindings/core/dart/DartDOMData.h"

#include "bindings/core/dart/DartApplicationLoader.h"
#include "bindings/core/dart/ThreadSafeDartIsolateWrapper.h"
#include "core/dom/ExecutionContext.h"

namespace blink {

DartDOMData::DartDOMData(ExecutionContext* context, const char* scriptURL, bool isDOMEnabled)
    : m_scriptURL(strdup(scriptURL))
    , m_scriptExecutionContext(context)
    , m_isDOMEnabled(isDOMEnabled)
    , m_recursion(0)
    , m_stringCache()
    , m_threadSafeIsolateWrapper()
    , m_isolateWrapperMutex()
    , m_applicationLoader()
    , m_applicationSnapshot()
    , m_reachableWeakHandle(0)
    , m_objectMap()
    , m_messagePortMap()
    , m_isolateDestructionObservers()
    , m_customElementBindings()
    , m_classHandleCache()
    , m_libraryHandleCache()
    , m_functionType(0)
    , m_currentException(0)
    , m_rootScriptState(0)
    , m_weakReferenceSetForRootMap(0)
    , m_documentWeakReferenceSet(0)
    , m_weakReferenceSetBuilder(0)
    , m_isObservatoryFakeDartDOMData(false)
{
}

DartDOMData::~DartDOMData()
{
    ASSERT(m_objectMap.isEmpty());
    ASSERT(m_messagePortMap.isEmpty());

    free(m_scriptURL);
    setApplicationLoader(nullptr);
}

DartDOMData* DartDOMData::current()
{
    ASSERT(Dart_CurrentIsolate());
    return static_cast<DartDOMData*>(Dart_CurrentIsolateData());
}

void DartDOMData::setApplicationLoader(PassRefPtr<DartApplicationLoader> applicationLoader)
{
    ASSERT(!m_applicationLoader || !applicationLoader);
    m_applicationLoader = applicationLoader;
}

PassRefPtr<DartApplicationLoader> DartDOMData::applicationLoader()
{
    ASSERT(m_applicationLoader);
    return m_applicationLoader;
}

void DartDOMData::setThreadSafeIsolateWrapper(PassRefPtr<ThreadSafeDartIsolateWrapper> threadSafeIsolateWrapper)
{
    ASSERT(!m_threadSafeIsolateWrapper);
    MutexLocker locker(m_isolateWrapperMutex);
    m_threadSafeIsolateWrapper = threadSafeIsolateWrapper;
}

PassRefPtr<ThreadSafeDartIsolateWrapper> DartDOMData::threadSafeIsolateWrapper()
{
    ASSERT(m_threadSafeIsolateWrapper);
    MutexLocker locker(m_isolateWrapperMutex);
    return m_threadSafeIsolateWrapper;
}

void DartDOMData::addCustomElementBinding(CustomElementDefinition* definition, PassOwnPtr<DartCustomElementBinding> binding)
{
    ASSERT(!m_customElementBindings.contains(definition));
    m_customElementBindings.add(definition, binding);
}

void DartDOMData::clearCustomElementBinding(CustomElementDefinition* definition)
{
    DartCustomElementBindingMap::iterator it = m_customElementBindings.find(definition);
    ASSERT(it != m_customElementBindings.end());
    m_customElementBindings.remove(it);
}

DartCustomElementBinding* DartDOMData::customElementBinding(CustomElementDefinition* definition)
{
    DartCustomElementBindingMap::const_iterator it = m_customElementBindings.find(definition);
    if (it == m_customElementBindings.end())
        return 0;
    return it->value.get();
}

Dart_PersistentHandle DartDOMData::getLibrary(int libraryId, const char* name)
{
    Dart_Handle lib = Dart_LookupLibrary(Dart_NewStringFromCString(name));
    ASSERT(!Dart_IsError(lib));
    Dart_PersistentHandle persistentLib = Dart_NewPersistentHandle(lib);
    m_libraryHandleCache[libraryId] = persistentLib;
    return persistentLib;
}

}
