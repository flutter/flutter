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

#ifndef DartDOMData_h
#define DartDOMData_h

#include "bindings/core/dart/DartCustomElementBinding.h"
#include "bindings/core/dart/DartJsInteropData.h"
#include "bindings/core/dart/DartLibraryIds.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/DartStringCache.h"
#include "bindings/dart/DartWebkitClassIds.h"

#include "wtf/HashMap.h"
#include "wtf/HashSet.h"
#include "wtf/RefPtr.h"
#include "wtf/Threading.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

#include <dart_api.h>

namespace blink {

class ActiveDOMObject;
class CustomElementDefinition;
class DartApplicationLoader;
class DartEventListener;
class DartIsolateDestructionObserver;
class EventTarget;
class ExecutionContext;
class LocalDOMWindow;
class MessagePort;
class Node;
class ThreadSafeDartIsolateWrapper;

typedef HashMap<void*, Dart_WeakPersistentHandle> DartDOMObjectMap;
typedef HashMap<MessagePort*, Dart_WeakPersistentHandle> DartMessagePortMap;
typedef HashSet<DartIsolateDestructionObserver*> DartIsolateDestructionObservers;
typedef HashMap<CustomElementDefinition*, OwnPtr<DartCustomElementBinding> > DartCustomElementBindingMap;
typedef Dart_PersistentHandle ClassTable[NumWebkitClassIds];
typedef Dart_PersistentHandle LibraryTable[NumDartLibraryIds];
typedef HashMap<Node*, Dart_WeakReferenceSet> WeakReferenceSetForRootMap;

class DartDOMData {
public:
    DartDOMData(ExecutionContext*, const char* scriptURL, bool isDOMEnabled);
    ~DartDOMData();

    static DartDOMData* current();

    char* scriptURL() const { return m_scriptURL; }
    ExecutionContext* scriptExecutionContext() { return m_scriptExecutionContext; }
    bool isDOMEnabled() { return m_isDOMEnabled; }

    // We track the Dart specific recursion level here as well as the global
    // recursion level tracked by m_recursionScope due to dartbug.com/14183.
    int* recursion() { return &m_recursion; }
    DartStringCache& stringCache() { return m_stringCache; }

    void setThreadSafeIsolateWrapper(PassRefPtr<ThreadSafeDartIsolateWrapper>);
    PassRefPtr<ThreadSafeDartIsolateWrapper> threadSafeIsolateWrapper();

    void setApplicationLoader(PassRefPtr<DartApplicationLoader>);
    PassRefPtr<DartApplicationLoader> applicationLoader();

    Vector<uint8_t>* applicationSnapshot() { return &m_applicationSnapshot; }

    void setReachableWeakHandle(Dart_WeakPersistentHandle reachableWeakHandle)
    {
        m_reachableWeakHandle = reachableWeakHandle;
    }
    Dart_WeakPersistentHandle reachableWeakHandle() { return m_reachableWeakHandle; }

    DartDOMObjectMap* objectMap() { return &m_objectMap; }
    DartMessagePortMap* messagePortMap() { return &m_messagePortMap; }
    DartIsolateDestructionObservers* isolateDestructionObservers()
    {
        return &m_isolateDestructionObservers;
    }
    ClassTable* classHandleCache() { return &m_classHandleCache; }

    void addCustomElementBinding(CustomElementDefinition*, PassOwnPtr<DartCustomElementBinding>);
    void clearCustomElementBinding(CustomElementDefinition*);
    DartCustomElementBinding* customElementBinding(CustomElementDefinition*);

    Dart_PersistentHandle library(int libraryId) const { return m_libraryHandleCache[libraryId]; }

    Dart_PersistentHandle blinkLibrary() const
    {
        return m_libraryHandleCache[DartBlinkLibraryId];
    }
    void setBlinkLibrary(Dart_PersistentHandle lib)
    {
        m_libraryHandleCache[DartBlinkLibraryId] = lib;
    }

    Dart_PersistentHandle htmlLibrary() const
    {
        return m_libraryHandleCache[DartHtmlLibraryId];
    }
    void setHtmlLibrary(Dart_PersistentHandle lib)
    {
        m_libraryHandleCache[DartHtmlLibraryId] = lib;
    }

    Dart_PersistentHandle svgLibrary()
    {
        Dart_PersistentHandle lib = m_libraryHandleCache[DartSvgLibraryId];
        if (!lib) {
            lib = getLibrary(DartSvgLibraryId, "dart:svg");
            m_libraryHandleCache[DartSvgLibraryId] = lib;
        }
        return lib;
    }
    void setSvgLibrary(Dart_PersistentHandle lib)
    {
        m_libraryHandleCache[DartSvgLibraryId] = lib;
    }

    Dart_PersistentHandle jsLibrary() const
    {
        return m_libraryHandleCache[DartJsLibraryId];
    }
    void setJsLibrary(Dart_PersistentHandle lib)
    {
        m_libraryHandleCache[DartJsLibraryId] = lib;
    }

    Dart_Handle emptyString() const
    {
        return Dart_EmptyString();
    }

    Dart_PersistentHandle functionType() const
    {
        return m_functionType;
    }
    void setFunctionType(Dart_PersistentHandle functionType)
    {
        m_functionType = functionType;
    }

    DartJsInteropData* jsInteropData()
    {
        return &m_jsInteropData;
    }

    DartScriptState* rootScriptState()
    {
        return m_rootScriptState;
    }

    void setRootScriptState(DartScriptState* scriptState)
    {
        m_rootScriptState = scriptState;
    }

    Dart_PersistentHandle currentException() const
    {
        return m_currentException;
    }
    void setCurrentException(Dart_PersistentHandle exception)
    {
        m_currentException = exception;
    }

    WeakReferenceSetForRootMap* weakReferenceSetForRootMap() const
    {
        return m_weakReferenceSetForRootMap;
    }
    void setWeakReferenceSetForRootMap(WeakReferenceSetForRootMap* map)
    {
        m_weakReferenceSetForRootMap = map;
    }

    Dart_WeakReferenceSet documentWeakReferenceSet() const
    {
        return m_documentWeakReferenceSet;
    }
    void setDocumentWeakReferenceSet(Dart_WeakReferenceSet set)
    {
        m_documentWeakReferenceSet = set;
    }

    Dart_WeakReferenceSetBuilder weakReferenceSetBuilder() const
    {
        return m_weakReferenceSetBuilder;
    }
    void setWeakReferenceSetBuilder(Dart_WeakReferenceSetBuilder setBuilder)
    {
        m_weakReferenceSetBuilder = setBuilder;
    }

    bool isObservatoryFakeDartDOMData() const
    {
        return m_isObservatoryFakeDartDOMData;
    }
    void setIsObservatoryFakeDartDOMData(bool isObservatoryFakeDartDOMData)
    {
        m_isObservatoryFakeDartDOMData = isObservatoryFakeDartDOMData;
    }

private:
    Dart_PersistentHandle getLibrary(int libraryId, const char* name);

    char* m_scriptURL;
    ExecutionContext* m_scriptExecutionContext;
    bool m_isDOMEnabled;
    int m_recursion;
    DartStringCache m_stringCache;
    RefPtr<ThreadSafeDartIsolateWrapper> m_threadSafeIsolateWrapper;
    Mutex m_isolateWrapperMutex;
    RefPtr<DartApplicationLoader> m_applicationLoader;
    Vector<uint8_t> m_applicationSnapshot;
    Dart_WeakPersistentHandle m_reachableWeakHandle;

    DartJsInteropData m_jsInteropData;
    DartDOMObjectMap m_objectMap;
    DartMessagePortMap m_messagePortMap;
    DartIsolateDestructionObservers m_isolateDestructionObservers;
    DartCustomElementBindingMap m_customElementBindings;
    ClassTable m_classHandleCache;
    LibraryTable m_libraryHandleCache;
    Dart_PersistentHandle m_functionType;
    Dart_PersistentHandle m_currentException;
    DartScriptState* m_rootScriptState;

    WeakReferenceSetForRootMap* m_weakReferenceSetForRootMap;
    Dart_WeakReferenceSet m_documentWeakReferenceSet;
    Dart_WeakReferenceSetBuilder m_weakReferenceSetBuilder;

    // FIXME(dartbug.com/20303): remove this field once we support service
    // isolates.
    bool m_isObservatoryFakeDartDOMData;
};

}

#endif // DartDOMData_h
