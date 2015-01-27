// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"

#include "sky/engine/bindings/core/v8/ScriptCallStackFactory.h"
#include "sky/engine/bindings/core/v8/ScriptGCEvent.h"
#include "sky/engine/bindings/core/v8/ScriptSourceCode.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/inspector/IdentifiersFactory.h"
#include "sky/engine/core/inspector/InspectorNodeIds.h"
#include "sky/engine/core/inspector/ScriptCallStack.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderImage.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/platform/network/ResourceRequest.h"
#include "sky/engine/platform/network/ResourceResponse.h"
#include "sky/engine/platform/TracedValue.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

namespace {

class JSCallStack : public TraceEvent::ConvertableToTraceFormat  {
public:
    explicit JSCallStack(PassRefPtr<ScriptCallStack> callstack)
    {
        ASSERT(m_serialized.isSafeToSendToAnotherThread());
    }
    virtual String asTraceFormat() const
    {
        return m_serialized;
    }

private:
    String m_serialized;
};

}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorLayoutEvent::beginData(FrameView* frameView)
{
    bool isPartial;
    unsigned needsLayoutObjects;
    unsigned totalObjects;
    frameView->countObjectsNeedingLayout(needsLayoutObjects, totalObjects, isPartial);

    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("dirtyObjects", needsLayoutObjects);
    value->setInteger("totalObjects", totalObjects);
    value->setBoolean("partialLayout", isPartial);
    return value;
}

static void createQuad(TracedValue* value, const char* name, const FloatQuad& quad)
{
    value->beginArray(name);
    value->pushDouble(quad.p1().x());
    value->pushDouble(quad.p1().y());
    value->pushDouble(quad.p2().x());
    value->pushDouble(quad.p2().y());
    value->pushDouble(quad.p3().x());
    value->pushDouble(quad.p3().y());
    value->pushDouble(quad.p4().x());
    value->pushDouble(quad.p4().y());
    value->endArray();
}

static void setGeneratingNodeId(TracedValue* value, const char* fieldName, const RenderObject* renderer)
{
    Node* node = 0;
    for (; renderer && !node; renderer = renderer->parent())
        node = renderer->node();
    if (!node)
        return;
    value->setInteger(fieldName, InspectorNodeIds::idForNode(node));
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorLayoutEvent::endData(RenderObject* rootForThisLayout)
{
    Vector<FloatQuad> quads;
    rootForThisLayout->absoluteQuads(quads);

    RefPtr<TracedValue> value = TracedValue::create();
    if (quads.size() >= 1) {
        createQuad(value.get(), "root", quads[0]);
        setGeneratingNodeId(value.get(), "rootNode", rootForThisLayout);
    } else {
        ASSERT_NOT_REACHED();
    }
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorSendRequestEvent::data(unsigned long identifier, const ResourceRequest& request)
{
    String requestId = IdentifiersFactory::requestId(identifier);

    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("requestId", requestId);
    value->setString("url", request.url().string());
    value->setString("requestMethod", request.httpMethod());
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorReceiveResponseEvent::data(unsigned long identifier, const ResourceResponse& response)
{
    String requestId = IdentifiersFactory::requestId(identifier);

    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("requestId", requestId);
    value->setInteger("statusCode", response.httpStatusCode());
    value->setString("mimeType", response.mimeType().string().isolatedCopy());
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorReceiveDataEvent::data(unsigned long identifier, int encodedDataLength)
{
    String requestId = IdentifiersFactory::requestId(identifier);

    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("requestId", requestId);
    value->setInteger("encodedDataLength", encodedDataLength);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorResourceFinishEvent::data(unsigned long identifier, double finishTime, bool didFail)
{
    String requestId = IdentifiersFactory::requestId(identifier);

    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("requestId", requestId);
    value->setBoolean("didFail", didFail);
    if (finishTime)
        value->setDouble("networkTime", finishTime);
    return value;
}

static PassRefPtr<TracedValue> genericTimerData(ExecutionContext* context, int timerId)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("timerId", timerId);
    return value.release();
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorTimerInstallEvent::data(ExecutionContext* context, int timerId, int timeout, bool singleShot)
{
    RefPtr<TracedValue> value = genericTimerData(context, timerId);
    value->setInteger("timeout", timeout);
    value->setBoolean("singleShot", singleShot);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorTimerRemoveEvent::data(ExecutionContext* context, int timerId)
{
    return genericTimerData(context, timerId);
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorTimerFireEvent::data(ExecutionContext* context, int timerId)
{
    return genericTimerData(context, timerId);
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorAnimationFrameEvent::data(Document* document, int callbackId)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("id", callbackId);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorParseHtmlEvent::beginData(Document* document, unsigned startLine)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setInteger("startLine", startLine);
    return value;
}

static void localToPageQuad(const RenderObject& renderer, const LayoutRect& rect, FloatQuad* quad)
{
    FloatQuad absolute = renderer.localToAbsoluteQuad(FloatQuad(rect));
    quad->setP1(roundedIntPoint(absolute.p1()));
    quad->setP2(roundedIntPoint(absolute.p2()));
    quad->setP3(roundedIntPoint(absolute.p3()));
    quad->setP4(roundedIntPoint(absolute.p4()));
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorPaintEvent::data(RenderObject* renderer, const LayoutRect& clipRect)
{
    RefPtr<TracedValue> value = TracedValue::create();
    FloatQuad quad;
    localToPageQuad(*renderer, clipRect, &quad);
    createQuad(value.get(), "clip", quad);
    setGeneratingNodeId(value.get(), "nodeId", renderer);
    value->setInteger("layerId", 0);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorMarkLoadEvent::data()
{
    return TracedValue::create();
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorEvaluateScriptEvent::data(const String& url, int lineNumber)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("url", url);
    value->setInteger("lineNumber", lineNumber);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorFunctionCallEvent::data(ExecutionContext* context, int scriptId, const String& scriptName, int scriptLine)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("scriptId", String::number(scriptId));
    value->setString("scriptName", scriptName);
    value->setInteger("scriptLine", scriptLine);
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorPaintImageEvent::data(const RenderImage& renderImage)
{
    RefPtr<TracedValue> value = TracedValue::create();
    setGeneratingNodeId(value.get(), "nodeId", &renderImage);
    if (const ImageResource* resource = renderImage.cachedImage())
        value->setString("url", resource->url().string());
    return value;
}

static size_t usedHeapSize()
{
    HeapInfo info;
    ScriptGCEvent::getHeapSize(info);
    return info.usedJSHeapSize;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorUpdateCountersEvent::data()
{
    RefPtr<TracedValue> value = TracedValue::create();
    if (isMainThread()) {
        value->setInteger("documents", InspectorCounters::counterValue(InspectorCounters::DocumentCounter));
        value->setInteger("nodes", InspectorCounters::counterValue(InspectorCounters::NodeCounter));
        value->setInteger("jsEventListeners", InspectorCounters::counterValue(InspectorCounters::JSEventListenerCounter));
    }
    value->setDouble("jsHeapSizeUsed", static_cast<double>(usedHeapSize()));
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorCallStackEvent::currentCallStack()
{
    return adoptRef(new JSCallStack(createScriptCallStack(ScriptCallStack::maxCallStackSizeToCapture, true)));
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorEventDispatchEvent::data(const Event& event)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("type", event.type());
    return value;
}

PassRefPtr<TraceEvent::ConvertableToTraceFormat> InspectorTimeStampEvent::data(ExecutionContext* context, const String& message)
{
    RefPtr<TracedValue> value = TracedValue::create();
    value->setString("message", message);
    return value;
}

}
