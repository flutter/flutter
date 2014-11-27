// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_INSPECTORTRACEEVENTS_H_
#define SKY_ENGINE_CORE_INSPECTOR_INSPECTORTRACEEVENTS_H_

#include "sky/engine/platform/EventTracer.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/wtf/Forward.h"

namespace blink {

class Document;
class Event;
class ExecutionContext;
class FrameView;
class GraphicsContext;
class KURL;
class LayoutRect;
class LocalFrame;
class RenderObject;
class RenderImage;
class ResourceRequest;
class ResourceResponse;
class ScriptSourceCode;
class ScriptCallStack;

class InspectorLayoutEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> beginData(FrameView*);
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> endData(RenderObject* rootForThisLayout);
};

class InspectorSendRequestEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(unsigned long identifier, LocalFrame*, const ResourceRequest&);
};

class InspectorReceiveResponseEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(unsigned long identifier, LocalFrame*, const ResourceResponse&);
};

class InspectorReceiveDataEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(unsigned long identifier, LocalFrame*, int encodedDataLength);
};

class InspectorResourceFinishEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(unsigned long identifier, double finishTime, bool didFail);
};

class InspectorTimerInstallEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(ExecutionContext*, int timerId, int timeout, bool singleShot);
};

class InspectorTimerRemoveEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(ExecutionContext*, int timerId);
};

class InspectorTimerFireEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(ExecutionContext*, int timerId);
};

class InspectorAnimationFrameEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(Document*, int callbackId);
};

class InspectorParseHtmlEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> beginData(Document*, unsigned startLine);
};

class InspectorPaintEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(RenderObject*, const LayoutRect& clipRect);
};

class InspectorPaintImageEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(const RenderImage&);
};

class InspectorMarkLoadEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(LocalFrame*);
};

class InspectorScrollLayerEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(RenderObject*);
};

class InspectorEvaluateScriptEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(LocalFrame*, const String& url, int lineNumber);
};

class InspectorFunctionCallEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(ExecutionContext*, int scriptId, const String& scriptName, int scriptLine);
};

class InspectorUpdateCountersEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data();
};

class InspectorCallStackEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> currentCallStack();
};

class InspectorEventDispatchEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(const Event&);
};

class InspectorTimeStampEvent {
public:
    static PassRefPtr<TraceEvent::ConvertableToTraceFormat> data(ExecutionContext*, const String& message);
};

} // namespace blink


#endif  // SKY_ENGINE_CORE_INSPECTOR_INSPECTORTRACEEVENTS_H_
