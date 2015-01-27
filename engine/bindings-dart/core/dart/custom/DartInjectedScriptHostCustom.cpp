// Copyright 2014, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartInjectedScriptHost.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartHandleProxy.h"
#include "bindings/core/dart/DartInjectedScript.h"
#include "bindings/core/dart/DartInjectedScriptManager.h"
#include "bindings/core/dart/DartNode.h"
#include "bindings/core/dart/DartScriptDebugServer.h"
#include "bindings/core/dart/V8Converter.h"
#include "core/events/EventTarget.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/inspector/InjectedScript.h"
#include "core/inspector/InjectedScriptHost.h"
#include "core/inspector/InjectedScriptManager.h"
#include "core/inspector/InspectorDOMAgent.h"
#include "modules/webdatabase/Database.h"
#include "platform/JSONValues.h"

namespace blink {

namespace DartInjectedScriptHostInternal {

void inspectCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        InjectedScriptHost* receiver = DartDOMWrapper::receiver< InjectedScriptHost >(args);
        Dart_Handle object = Dart_GetNativeArgument(args, 1);

        // Inspect is only allowed for nodes.
        if (DartDOMWrapper::subtypeOf(object, DartNode::dartClassId)) {
            Node* node = DartNode::toNative(object, exception);
            if (exception)
                goto fail;

            Document* document = node->isDocumentNode() ? &node->document() : node->ownerDocument();
            LocalFrame* frame = document ? document->frame() : 0;
            DartInjectedScriptManager* dartInjectedScriptManager = DartScriptDebugServer::shared().injectedScriptManager();
            if (!dartInjectedScriptManager) {
                // This should not happen but is possible if inspect is somehow
                // called before the devtools are opened.
                exception = Dart_NewApiError("Inspect failed due to an internal error");
                return;
            }
            InjectedScriptManager* injectedScriptManager = dartInjectedScriptManager->javaScriptInjectedScriptManager();
            InjectedScript injectedScript = injectedScriptManager->injectedScriptFor(V8ScriptState::forMainWorld(frame));

            // FIXME: read in the hint argument as well.
            ASSERT(!Dart_IsError(object));
            receiver->inspectImpl(injectedScript.wrapNode(node, ""),
                JSONObject::create());

            if (exception)
                goto fail;
        } else {
            exception = Dart_NewApiError("Inspect only allowed for nodes.");
        }
        return;
    }

fail:
    Dart_ThrowException(exception);
}

void inspectedObjectCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void internalConstructorNameCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void isHTMLAllCollectionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void typeCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void functionDetailsCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void getInternalPropertiesCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void getEventListenersCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void evaluateWithExceptionDetailsCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void debugFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void undebugFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void monitorFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void unmonitorFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void suppressWarningsAndCallCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void setFunctionVariableValueCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void evalCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void callFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void suppressWarningsAndCallFunctionCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

}

} // namespace blink
