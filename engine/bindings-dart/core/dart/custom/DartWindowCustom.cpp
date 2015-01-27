// Copyright 2011, Google Inc.
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
#include "bindings/core/dart/DartWindow.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartEventListener.h"
#include "bindings/core/dart/DartFileReader.h"
#include "bindings/core/dart/DartHistory.h"
#include "bindings/core/dart/DartLocation.h"
#include "bindings/core/dart/DartScheduledAction.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/DartWebKitCSSMatrix.h"
#include "bindings/core/dart/DartWebKitPoint.h"
#include "bindings/core/dart/DartXMLHttpRequest.h"
#include "core/css/CSSMatrix.h"
#include "core/dom/Document.h"
#include "core/dom/ExecutionContext.h"
#include "core/dom/MessagePort.h"
#include "core/fileapi/FileReader.h"
#include "core/frame/DOMTimer.h"
#include "core/frame/History.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/Location.h"
#include "core/xml/XMLHttpRequest.h"

#include "wtf/OwnPtr.h"

namespace blink {

namespace DartWindowInternal {

void eventGetter(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void eventSetter(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void historyCrossFrameGetter(Dart_NativeArguments args)
{
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));

        Dart_WeakPersistentHandle existingWrapper = DartDOMWrapper::lookupWrapper<DartHistory>(domData, &receiver->history());
        if (existingWrapper) {
            Dart_SetWeakHandleReturnValue(args, existingWrapper);
            return;
        }

        Dart_Handle result = DartDOMWrapper::createWrapper<DartHistory>(
            domData, &receiver->history(), _HistoryCrossFrameClassId);
        if (result)
            Dart_SetReturnValue(args, result);
    }
}

void locationCrossFrameGetter(Dart_NativeArguments args)
{
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));

        Dart_WeakPersistentHandle existingWrapper = DartDOMWrapper::lookupWrapper<DartLocation>(domData, &receiver->location());
        if (existingWrapper) {
            Dart_SetWeakHandleReturnValue(args, existingWrapper);
            return;
        }

        Dart_Handle result = DartDOMWrapper::createWrapper<DartLocation>(
            domData, &receiver->location(), _LocationCrossFrameClassId);
        if (result)
            Dart_SetReturnValue(args, result);
    }
}

void locationSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        ASSERT(receiver == DartUtilities::domWindowForCurrentIsolate());

        DartStringAdapter location =
            DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        receiver->setLocation(location, receiver, receiver);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void openCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        ASSERT(receiver == DartUtilities::domWindowForCurrentIsolate());

        DartStringAdapter url = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;
        DartStringAdapter name = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;
        DartStringAdapter options = DartUtilities::dartToStringWithNullCheck(args, 3, exception);
        if (exception)
            goto fail;

        RefPtr<LocalDOMWindow> openedWindow = receiver->open(url, name, options, receiver, receiver);
        if (openedWindow)
            DartWindow::returnToDart(args, openedWindow.release(), true);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void frameElementGetter(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void openerSetter(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void showModalDialogCallback(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

void handlePostMessageCallback(Dart_NativeArguments args, bool extendedTransfer)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);

        LocalDOMWindow* source = DartUtilities::domWindowForCurrentIsolate();
        ASSERT(source);
        ASSERT(source->frame());

        MessagePortArray portArray;
        ArrayBufferArray bufferArray;
        if (!Dart_IsNull(Dart_GetNativeArgument(args, 3))) {
            DartUtilities::toMessagePortArray(Dart_GetNativeArgument(args, 3), portArray, bufferArray, exception);
            if (exception)
                goto fail;
        }

        RefPtr<SerializedScriptValue> message = DartUtilities::toSerializedScriptValue(
            Dart_GetNativeArgument(args, 1),
            &portArray,
            extendedTransfer ? &bufferArray : 0,
            exception);
        if (exception)
            goto fail;

        DartStringAdapter targetOrigin = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        receiver->postMessage(message.release(), &portArray, targetOrigin, source, es);
        if (es.hadException()) {
            exception = es.toDart(args);
            goto fail;
        }

        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void postMessageCallback(Dart_NativeArguments args)
{
    handlePostMessageCallback(args, false);
}

void webkitPostMessageCallback(Dart_NativeArguments args)
{
    handlePostMessageCallback(args, true);
}

// NOTE: if throws exception, doesn't unwind the stack, should be called with caution!
static void windowSetTimeoutImpl(Dart_NativeArguments args, bool singleShot)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        ASSERT(receiver == DartUtilities::domWindowForCurrentIsolate());

        Dart_Handle callback = Dart_GetNativeArgument(args, 1);
        if (!Dart_IsClosure(callback)) {
            exception = Dart_NewStringFromCString("Not a Dart closure passed");
            goto fail;
        }

        int timeout = DartUtilities::dartToInt(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;

        ExecutionContext* context = receiver->document();
        ASSERT(context);
        OwnPtr<DartScheduledAction> action = adoptPtr(new DartScheduledAction(Dart_CurrentIsolate(), callback));
        int id = DOMTimer::install(context, action.release(), timeout, singleShot);
        Dart_SetReturnValue(args, DartUtilities::intToDart(id));
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void setTimeoutCallback(Dart_NativeArguments args)
{
    windowSetTimeoutImpl(args, true /* singleShot */);
}

void setIntervalCallback(Dart_NativeArguments args)
{
    windowSetTimeoutImpl(args, false /* singleShot */);
}

void addEventListenerCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        ASSERT(receiver == DartUtilities::domWindowForCurrentIsolate());

        DartStringAdapter type = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;
        EventListener* listener = DartEventListener::toNative(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;
        bool useCapture = DartUtilities::dartToBool(Dart_GetNativeArgument(args, 3), exception);
        if (exception)
            goto fail;

        receiver->addEventListener(type, listener, useCapture);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void removeEventListenerCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        LocalDOMWindow* receiver = DartDOMWrapper::receiver<LocalDOMWindow>(args);
        ASSERT(receiver == DartUtilities::domWindowForCurrentIsolate());

        DartStringAdapter type = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;
        EventListener* listener = DartEventListener::toNative(Dart_GetNativeArgument(args, 2), exception);
        if (exception)
            goto fail;
        bool useCapture = DartUtilities::dartToBool(Dart_GetNativeArgument(args, 3), exception);
        if (exception)
            goto fail;

        receiver->removeEventListener(type, listener, useCapture);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void toStringCallback(Dart_NativeArguments args)
{
    // FIXME: proper implementation.
    Dart_SetReturnValue(args, Dart_NewStringFromCString("<window>"));
}

void ___getter___2Callback(Dart_NativeArguments)
{
    // FIXME: proper implementation.
    DART_UNIMPLEMENTED();
}

}

Dart_Handle DartWindow::createWrapper(DartDOMData* domData, LocalDOMWindow* window)
{
    LocalDOMWindow* primaryWindow = DartUtilities::domWindowForCurrentIsolate();
    if (window == primaryWindow) {
        return DartDOMWrapper::createWrapper<DartWindow>(
            domData, window, WindowClassId);
    } else {
        return DartDOMWrapper::createWrapper<DartWindow>(
            domData, window, _DOMWindowCrossFrameClassId);
    }
}

}
