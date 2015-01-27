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
#include "bindings/core/dart/DartGCController.h"

#include "core/HTMLNames.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartEventListener.h"
#include "bindings/core/dart/DartUtilities.h"
#include "core/dom/ActiveDOMObject.h"
#include "core/dom/Attr.h"
#include "core/dom/Document.h"
#include "core/dom/Node.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/html/HTMLImageElement.h"

#include <wtf/Vector.h>

namespace blink {

typedef HashMap<Node*, Dart_WeakReferenceSet> WeakReferenceSetForRootMap;

static Node* calculateRootNode(Node*);
static void collectEventListenerWrappers(EventTarget*, Dart_WeakReferenceSet);

static void createWeakReferenceSetForNode(
    DartDOMData* domData,
    Dart_WeakReferenceSetBuilder setBuilder,
    Node* node,
    Dart_WeakPersistentHandle wrapper,
    WeakReferenceSetForRootMap* weakReferenceSetForRootMap)
{
    Dart_WeakReferenceSet weakReferenceSet = 0;
    ASSERT(node);

    Node* root = 0;
    if (node->inDocument() || (node->hasTagName(HTMLNames::imgTag) && static_cast<HTMLImageElement*>(node)->hasPendingActivity())) {
        root = &node->document();
    } else {
        root = calculateRootNode(node);
        if (!root)
            return;
    }
    ASSERT(root);

    Document* document = static_cast<Document*>(domData->scriptExecutionContext());
    if (root == document) {
        weakReferenceSet = domData->documentWeakReferenceSet();
        Dart_AppendToWeakReferenceSet(weakReferenceSet, wrapper, wrapper);
    } else {
        WeakReferenceSetForRootMap::const_iterator weakReferenceSetIterator = weakReferenceSetForRootMap->find(root);
        if (weakReferenceSetIterator != weakReferenceSetForRootMap->end()) {
            weakReferenceSet = weakReferenceSetIterator->value;
            Dart_AppendToWeakReferenceSet(weakReferenceSet, wrapper, wrapper);
        }
        else {
            weakReferenceSet = Dart_NewWeakReferenceSet(setBuilder, wrapper, wrapper);
            weakReferenceSetForRootMap->set(root, weakReferenceSet);
        }
    }
    EventTarget* eventTarget = node;
    if (eventTarget->hasEventListeners())
        collectEventListenerWrappers(node, weakReferenceSet);
}

static void collectRetainedActiveDOMObjectWrappers(DartDOMData* domData, Dart_WeakReferenceSet set)
{
    DartMessagePortMap* messagePortMap = domData->messagePortMap();
    for (DartMessagePortMap::const_iterator it = messagePortMap->begin(); it != messagePortMap->end(); ++it) {
        MessagePort* messagePort = it->key;
        if (messagePort->isEntangled() || messagePort->hasPendingActivity()) {
            Dart_AppendValueToWeakReferenceSet(set, it->value);
        }
    }
}

static Node* calculateRootNode(Node* node)
{
    Node* root = node;
    if (node->isAttributeNode()) {
        root = static_cast<Attr*>(node)->ownerElement();
        // If the attribute has no element, no need to put it in the group,
        // because it'll always be a group of 1.
        if (!root)
            return 0;
    } else {
        while (Node* parent = root->parentOrShadowHostOrTemplateHostNode())
            root = parent;
    }
    return root;
}

static void collectEventListenerWrappers(EventTarget* eventTarget, Dart_WeakReferenceSet weakReferenceSet)
{
    EventListenerIterator iterator(eventTarget);
    while (EventListener* listener = iterator.nextListener()) {
        if (static_cast<int>(listener->type()) != DartEventListenerType)
            continue;
        DartEventListener* dartListener = static_cast<DartEventListener*>(listener);
        if (dartListener->isolate() != Dart_CurrentIsolate())
            continue;
        Dart_AppendValueToWeakReferenceSet(weakReferenceSet, dartListener->listenerObject());
    }
}

void DartGCController::prologueCallback()
{
    Dart_EnterScope();

    DartDOMData* domData = DartDOMData::current();
    ASSERT(domData->isDOMEnabled());
    ASSERT(domData->reachableWeakHandle());

    // Setup weak reference set builder.
    Dart_WeakReferenceSetBuilder setBuilder = Dart_NewWeakReferenceSetBuilder();
    ASSERT(setBuilder);
    domData->setWeakReferenceSetBuilder(setBuilder);

    // Setup root <=> weak_reference_set map.
    WeakReferenceSetForRootMap weakReferenceSetForRootMap;
    domData->setWeakReferenceSetForRootMap(&weakReferenceSetForRootMap);

    // Create dedicated weak reference set for a document.
    // ActiveDOMObjects with pending activity and active Message ports
    // will be added to this set.
    ASSERT(domData->scriptExecutionContext()->isDocument());
    Document* document = static_cast<Document*>(domData->scriptExecutionContext());
    Dart_WeakReferenceSet documentWeakReferenceSet =
        Dart_NewWeakReferenceSet(setBuilder, domData->reachableWeakHandle(), 0);
    domData->setDocumentWeakReferenceSet(documentWeakReferenceSet);
    weakReferenceSetForRootMap.set(document, documentWeakReferenceSet);

    // Now visit all the prolog weak handles.
    Dart_Handle ALLOW_UNUSED result = Dart_VisitPrologueWeakHandles(prologueWeakHandleCallback);
    collectRetainedActiveDOMObjectWrappers(domData, documentWeakReferenceSet);
}

void DartGCController::epilogueCallback()
{
    Dart_ExitScope();
}

void DartGCController::prologueWeakHandleCallback(void* isolateCallbackData, Dart_WeakPersistentHandle obj, intptr_t numNativeFields, intptr_t* nativeFields)
{
    if (!numNativeFields)
        return;
    ASSERT(numNativeFields == DartDOMWrapper::NativeFieldCount);

    DartDOMData* domData = reinterpret_cast<DartDOMData*>(isolateCallbackData);
    ASSERT(domData->isDOMEnabled());

    intptr_t cid = nativeFields[DartDOMWrapper::NativeTypeIndex];
    void* nativeObject = reinterpret_cast<void*>(nativeFields[DartDOMWrapper::NativeImplementationIndex]);
    const DartWrapperTypeInfo& typeInfo = DartWebkitClassInfo[cid];
    ASSERT(typeInfo.toNode);
    Node* node = typeInfo.toNode(nativeObject);
    if (node) {
        Dart_WeakReferenceSetBuilder setBuilder = domData->weakReferenceSetBuilder();
        WeakReferenceSetForRootMap* weakReferenceSetForRootMap = domData->weakReferenceSetForRootMap();
        createWeakReferenceSetForNode(domData, setBuilder, node, obj, weakReferenceSetForRootMap);
        return;
    }
    ASSERT(typeInfo.toEventTarget);
    EventTarget* eventTarget = typeInfo.toEventTarget(nativeObject);
    if (eventTarget) {
        if (eventTarget->hasEventListeners()) {
            Dart_WeakReferenceSetBuilder setBuilder = domData->weakReferenceSetBuilder();
            Dart_WeakReferenceSet set = Dart_NewWeakReferenceSet(setBuilder, obj, 0);

            collectEventListenerWrappers(eventTarget, set);
        }
    }
    ASSERT(typeInfo.toActiveDOMObject);
    ActiveDOMObject* activeDOMObject = typeInfo.toActiveDOMObject(nativeObject);
    if (activeDOMObject && activeDOMObject->hasPendingActivity()) {
        Dart_WeakReferenceSet documentWeakReferenceSet = domData->documentWeakReferenceSet();
        Dart_AppendValueToWeakReferenceSet(documentWeakReferenceSet, obj);
    }
}

}
