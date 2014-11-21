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
#include "sky/engine/bindings/core/v8/V8GCController.h"

#include <algorithm>
#include "bindings/core/v8/V8MutationObserver.h"
#include "bindings/core/v8/V8Node.h"
#include "sky/engine/bindings/core/v8/RetainedDOMInfo.h"
#include "sky/engine/bindings/core/v8/V8AbstractEventListener.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8ScriptRunner.h"
#include "sky/engine/bindings/core/v8/WrapperTypeInfo.h"
#include "sky/engine/core/dom/Attr.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/TemplateContentDocumentFragment.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/core/html/HTMLTemplateElement.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/platform/Partitions.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

// FIXME: This should use opaque GC roots.
static void addReferencesForNodeWithEventListeners(v8::Isolate* isolate, Node* node, const v8::Persistent<v8::Object>& wrapper)
{
    ASSERT(node->hasEventListeners());

    EventListenerIterator iterator(node);
    while (EventListener* listener = iterator.nextListener()) {
        V8AbstractEventListener* v8listener = static_cast<V8AbstractEventListener*>(listener);
        if (!v8listener->hasExistingListenerObject())
            continue;

        isolate->SetReference(wrapper, v8::Persistent<v8::Value>::Cast(v8listener->existingListenerObjectPersistentHandle()));
    }
}

Node* V8GCController::opaqueRootForGC(Node* node, v8::Isolate*)
{
    ASSERT(node);
    // FIXME: Remove the special handling for image elements.
    // The same special handling is in V8GCController::gcTree().
    // Maybe should image elements be active DOM nodes?
    // See https://code.google.com/p/chromium/issues/detail?id=164882
    if (node->inDocument() || (isHTMLImageElement(*node) && toHTMLImageElement(*node).hasPendingActivity())) {
        Document& document = node->document();
        if (HTMLImportsController* controller = document.importsController())
            return controller->master();
        return &document;
    }

    while (Node* parent = node->parentOrShadowHostOrTemplateHostNode())
        node = parent;

    return node;
}

// Regarding a minor GC algorithm for DOM nodes, see this document:
// https://docs.google.com/a/google.com/presentation/d/1uifwVYGNYTZDoGLyCb7sXa7g49mWNMW2gaWvMN5NLk8/edit#slide=id.p
class MinorGCWrapperVisitor : public v8::PersistentHandleVisitor {
public:
    explicit MinorGCWrapperVisitor(v8::Isolate* isolate)
        : m_isolate(isolate)
    { }

    virtual void VisitPersistentHandle(v8::Persistent<v8::Value>* value, uint16_t classId) override
    {
        // A minor DOM GC can collect only Nodes.
        if (classId != WrapperTypeInfo::NodeClassId)
            return;

        // To make minor GC cycle time bounded, we limit the number of wrappers handled
        // by each minor GC cycle to 10000. This value was selected so that the minor
        // GC cycle time is bounded to 20 ms in a case where the new space size
        // is 16 MB and it is full of wrappers (which is almost the worst case).
        // Practically speaking, as far as I crawled real web applications,
        // the number of wrappers handled by each minor GC cycle is at most 3000.
        // So this limit is mainly for pathological micro benchmarks.
        const unsigned wrappersHandledByEachMinorGC = 10000;
        if (m_nodesInNewSpace.size() >= wrappersHandledByEachMinorGC)
            return;

        // Casting to a Handle is safe here, since the Persistent doesn't get GCd
        // during the GC prologue.
        ASSERT((*reinterpret_cast<v8::Handle<v8::Value>*>(value))->IsObject());
        v8::Handle<v8::Object>* wrapper = reinterpret_cast<v8::Handle<v8::Object>*>(value);
        ASSERT(V8DOMWrapper::isDOMWrapper(*wrapper));
        ASSERT(V8Node::hasInstance(*wrapper, m_isolate));
        Node* node = V8Node::toNative(*wrapper);
        // A minor DOM GC can handle only node wrappers in the main world.
        // Note that node->wrapper().IsEmpty() returns true for nodes that
        // do not have wrappers in the main world.
        if (node->containsWrapper()) {
            const WrapperTypeInfo* type = toWrapperTypeInfo(*wrapper);
            ActiveDOMObject* activeDOMObject = type->toActiveDOMObject(*wrapper);
            if (activeDOMObject && activeDOMObject->hasPendingActivity())
                return;
            // FIXME: Remove the special handling for image elements.
            // The same special handling is in V8GCController::opaqueRootForGC().
            // Maybe should image elements be active DOM nodes?
            // See https://code.google.com/p/chromium/issues/detail?id=164882
            if (isHTMLImageElement(*node) && toHTMLImageElement(*node).hasPendingActivity())
                return;

            m_nodesInNewSpace.append(node);
            node->markV8CollectableDuringMinorGC();
        }
    }

    void notifyFinished()
    {
        for (size_t i = 0; i < m_nodesInNewSpace.size(); i++) {
            Node* node = m_nodesInNewSpace[i];
            ASSERT(node->containsWrapper());
            if (node->isV8CollectableDuringMinorGC()) { // This branch is just for performance.
                gcTree(m_isolate, node);
                node->clearV8CollectableDuringMinorGC();
            }
        }
    }

private:
    bool traverseTree(Node* rootNode, Vector<RawPtr<Node>, initialNodeVectorSize>* partiallyDependentNodes)
    {
        // To make each minor GC time bounded, we might need to give up
        // traversing at some point for a large DOM tree. That being said,
        // I could not observe the need even in pathological test cases.
        for (Node* node = rootNode; node; node = NodeTraversal::next(*node)) {
            if (node->containsWrapper()) {
                if (!node->isV8CollectableDuringMinorGC()) {
                    // This node is not in the new space of V8. This indicates that
                    // the minor GC cannot anyway judge reachability of this DOM tree.
                    // Thus we give up traversing the DOM tree.
                    return false;
                }
                node->clearV8CollectableDuringMinorGC();
                partiallyDependentNodes->append(node);
            }
            if (ShadowRoot* shadowRoot = node->youngestShadowRoot()) {
                if (!traverseTree(shadowRoot, partiallyDependentNodes))
                    return false;
            } else if (node->isShadowRoot()) {
                if (ShadowRoot* shadowRoot = toShadowRoot(node)->olderShadowRoot()) {
                    if (!traverseTree(shadowRoot, partiallyDependentNodes))
                        return false;
                }
            }
            // <template> has a |content| property holding a DOM fragment which we must traverse,
            // just like we do for the shadow trees above.
            if (isHTMLTemplateElement(*node)) {
                if (!traverseTree(toHTMLTemplateElement(*node).content(), partiallyDependentNodes))
                    return false;
            }

            // Document maintains the list of imported documents through HTMLImportsController.
            if (node->isDocumentNode()) {
                Document* document = toDocument(node);
                HTMLImportsController* controller = document->importsController();
                if (controller && document == controller->master()) {
                    for (unsigned i = 0; i < controller->loaderCount(); ++i) {
                        if (!traverseTree(controller->loaderDocumentAt(i), partiallyDependentNodes))
                            return false;
                    }
                }
            }
        }
        return true;
    }

    void gcTree(v8::Isolate* isolate, Node* startNode)
    {
        Vector<RawPtr<Node>, initialNodeVectorSize> partiallyDependentNodes;

        Node* node = startNode;
        while (Node* parent = node->parentOrShadowHostOrTemplateHostNode())
            node = parent;

        if (!traverseTree(node, &partiallyDependentNodes))
            return;

        // We completed the DOM tree traversal. All wrappers in the DOM tree are
        // stored in partiallyDependentNodes and are expected to exist in the new space of V8.
        // We report those wrappers to V8 as an object group.
        if (!partiallyDependentNodes.size())
            return;
        Node* groupRoot = partiallyDependentNodes[0];
        for (size_t i = 0; i < partiallyDependentNodes.size(); i++) {
            partiallyDependentNodes[i]->markAsDependentGroup(groupRoot, isolate);
        }
    }

    Vector<RawPtr<Node> > m_nodesInNewSpace;
    v8::Isolate* m_isolate;
};

class MajorGCWrapperVisitor : public v8::PersistentHandleVisitor {
public:
    explicit MajorGCWrapperVisitor(v8::Isolate* isolate, bool constructRetainedObjectInfos)
        : m_isolate(isolate)
        , m_liveRootGroupIdSet(false)
        , m_constructRetainedObjectInfos(constructRetainedObjectInfos)
    {
    }

    virtual void VisitPersistentHandle(v8::Persistent<v8::Value>* value, uint16_t classId) override
    {
        if (classId != WrapperTypeInfo::NodeClassId && classId != WrapperTypeInfo::ObjectClassId)
            return;

        // Casting to a Handle is safe here, since the Persistent doesn't get GCd
        // during the GC prologue.
        ASSERT((*reinterpret_cast<v8::Handle<v8::Value>*>(value))->IsObject());
        v8::Handle<v8::Object>* wrapper = reinterpret_cast<v8::Handle<v8::Object>*>(value);
        ASSERT(V8DOMWrapper::isDOMWrapper(*wrapper));

        if (value->IsIndependent())
            return;

        const WrapperTypeInfo* type = toWrapperTypeInfo(*wrapper);

        ActiveDOMObject* activeDOMObject = type->toActiveDOMObject(*wrapper);
        if (activeDOMObject && activeDOMObject->hasPendingActivity())
            m_isolate->SetObjectGroupId(*value, liveRootId());

        if (classId == WrapperTypeInfo::NodeClassId) {
            ASSERT(V8Node::hasInstance(*wrapper, m_isolate));
            Node* node = V8Node::toNative(*wrapper);
            if (node->hasEventListeners())
                addReferencesForNodeWithEventListeners(m_isolate, node, v8::Persistent<v8::Object>::Cast(*value));
            Node* root = V8GCController::opaqueRootForGC(node, m_isolate);
            m_isolate->SetObjectGroupId(*value, v8::UniqueId(reinterpret_cast<intptr_t>(root)));
            if (m_constructRetainedObjectInfos)
                m_groupsWhichNeedRetainerInfo.append(root);
        } else if (classId == WrapperTypeInfo::ObjectClassId) {
            type->visitDOMWrapper(toScriptWrappableBase(*wrapper), v8::Persistent<v8::Object>::Cast(*value), m_isolate);
        } else {
            ASSERT_NOT_REACHED();
        }
    }

    void notifyFinished()
    {
        if (!m_constructRetainedObjectInfos)
            return;
        std::sort(m_groupsWhichNeedRetainerInfo.begin(), m_groupsWhichNeedRetainerInfo.end());
        Node* alreadyAdded = 0;
        v8::HeapProfiler* profiler = m_isolate->GetHeapProfiler();
        for (size_t i = 0; i < m_groupsWhichNeedRetainerInfo.size(); ++i) {
            Node* root = m_groupsWhichNeedRetainerInfo[i];
            if (root != alreadyAdded) {
                profiler->SetRetainedObjectInfo(v8::UniqueId(reinterpret_cast<intptr_t>(root)), new RetainedDOMInfo(root));
                alreadyAdded = root;
            }
        }
    }

private:
    v8::UniqueId liveRootId()
    {
        const v8::Persistent<v8::Value>& liveRoot = V8PerIsolateData::from(m_isolate)->ensureLiveRoot();
        const intptr_t* idPointer = reinterpret_cast<const intptr_t*>(&liveRoot);
        v8::UniqueId id(*idPointer);
        if (!m_liveRootGroupIdSet) {
            m_isolate->SetObjectGroupId(liveRoot, id);
            m_liveRootGroupIdSet = true;
        }
        return id;
    }

    v8::Isolate* m_isolate;
    Vector<RawPtr<Node> > m_groupsWhichNeedRetainerInfo;
    bool m_liveRootGroupIdSet;
    bool m_constructRetainedObjectInfos;
};

static unsigned long long usedHeapSize(v8::Isolate* isolate)
{
    v8::HeapStatistics heapStatistics;
    isolate->GetHeapStatistics(&heapStatistics);
    return heapStatistics.used_heap_size();
}

void V8GCController::gcPrologue(v8::GCType type, v8::GCCallbackFlags flags)
{
    // FIXME: It would be nice if the GC callbacks passed the Isolate directly....
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "GCEvent", "usedHeapSizeBefore", usedHeapSize(isolate));
    if (type == v8::kGCTypeScavenge)
        minorGCPrologue(isolate);
    else if (type == v8::kGCTypeMarkSweepCompact)
        majorGCPrologue(flags & v8::kGCCallbackFlagConstructRetainedObjectInfos, isolate);
}

void V8GCController::minorGCPrologue(v8::Isolate* isolate)
{
    TRACE_EVENT_BEGIN0("v8", "minorGC");
    if (isMainThread()) {
        ScriptForbiddenScope::enter();
        {
            TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "DOMMinorGC");
            v8::HandleScope scope(isolate);
            MinorGCWrapperVisitor visitor(isolate);
            v8::V8::VisitHandlesForPartialDependence(isolate, &visitor);
            visitor.notifyFinished();
        }
        V8PerIsolateData::from(isolate)->setPreviousSamplingState(TRACE_EVENT_GET_SAMPLING_STATE());
        TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8MinorGC");
    }
}

// Create object groups for DOM tree nodes.
void V8GCController::majorGCPrologue(bool constructRetainedObjectInfos, v8::Isolate* isolate)
{
    v8::HandleScope scope(isolate);
    TRACE_EVENT_BEGIN0("v8", "majorGC");
    if (isMainThread()) {
        ScriptForbiddenScope::enter();
        {
            TRACE_EVENT_SCOPED_SAMPLING_STATE("blink", "DOMMajorGC");
            MajorGCWrapperVisitor visitor(isolate, constructRetainedObjectInfos);
            v8::V8::VisitHandlesWithClassIds(&visitor);
            visitor.notifyFinished();
        }
        V8PerIsolateData::from(isolate)->setPreviousSamplingState(TRACE_EVENT_GET_SAMPLING_STATE());
        TRACE_EVENT_SET_SAMPLING_STATE("v8", "V8MajorGC");
    } else {
        MajorGCWrapperVisitor visitor(isolate, constructRetainedObjectInfos);
        v8::V8::VisitHandlesWithClassIds(&visitor);
        visitor.notifyFinished();
    }
}

void V8GCController::gcEpilogue(v8::GCType type, v8::GCCallbackFlags flags)
{
    // FIXME: It would be nice if the GC callbacks passed the Isolate directly....
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    if (type == v8::kGCTypeScavenge)
        minorGCEpilogue(isolate);
    else if (type == v8::kGCTypeMarkSweepCompact)
        majorGCEpilogue(isolate);

    TRACE_EVENT_END1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "GCEvent", "usedHeapSizeAfter", usedHeapSize(isolate));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", TRACE_EVENT_SCOPE_PROCESS, "data", InspectorUpdateCountersEvent::data());
}

void V8GCController::minorGCEpilogue(v8::Isolate* isolate)
{
    TRACE_EVENT_END0("v8", "minorGC");
    if (isMainThread())
        ScriptForbiddenScope::exit();
}

void V8GCController::majorGCEpilogue(v8::Isolate* isolate)
{
    v8::HandleScope scope(isolate);

    TRACE_EVENT_END0("v8", "majorGC");
    if (isMainThread())
        ScriptForbiddenScope::exit();
}

void V8GCController::collectGarbage(v8::Isolate* isolate)
{
    v8::HandleScope handleScope(isolate);
    RefPtr<ScriptState> scriptState = ScriptState::create(v8::Context::New(isolate), DOMWrapperWorld::create());
    ScriptState::Scope scope(scriptState.get());
    V8ScriptRunner::compileAndRunInternalScript(v8String(isolate, "if (gc) gc();"), isolate);
    scriptState->disposePerContextData();
}

void V8GCController::reportDOMMemoryUsageToV8(v8::Isolate* isolate)
{
    if (!isMainThread())
        return;

    static size_t lastUsageReportedToV8 = 0;

    size_t currentUsage = Partitions::currentDOMMemoryUsage();
    int64_t diff = static_cast<int64_t>(currentUsage) - static_cast<int64_t>(lastUsageReportedToV8);
    isolate->AdjustAmountOfExternalAllocatedMemory(diff);

    lastUsageReportedToV8 = currentUsage;
}

} // namespace blink
