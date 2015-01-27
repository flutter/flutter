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
#include "bindings/core/dart/DartLocation.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartUtilities.h"
#include "core/dom/Document.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Location.h"

namespace blink {

namespace DartLocationInternal {

void hrefSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter href = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        receiver->setHref(DartUtilities::domWindowForCurrentIsolate(), receiver->frame()->document()->domWindow(), href);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void protocolSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter protocol = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        DartExceptionState es;
        receiver->setProtocol(window, window, protocol, es);
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

void hostSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter host = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setHost(window, window, host);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void hostnameSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter hostname = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setHostname(window, window, hostname);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void portSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter port = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setPort(window, window, port);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void pathnameSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter pathname = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setPathname(window, window, pathname);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void searchSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);

        DartStringAdapter search = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setSearch(window, window, search);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void hashSetter(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);
        DartStringAdapter hash = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->setHash(window, window, hash);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void assignCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);
        DartStringAdapter url = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->assign(window, window, url);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void replaceCallback(Dart_NativeArguments args)
{
    Dart_Handle exception = 0;
    {
        Location* receiver = DartDOMWrapper::receiver<Location>(args);
        DartStringAdapter url = DartUtilities::dartToString(args, 1, exception);
        if (exception)
            goto fail;

        LocalDOMWindow* window = receiver->frame()->document()->domWindow();
        ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
        receiver->replace(window, window, url);
        return;
    }

fail:
    Dart_ThrowException(exception);
    ASSERT_NOT_REACHED();
}

void reloadCallback(Dart_NativeArguments args)
{
    Location* receiver = DartDOMWrapper::receiver<Location>(args);
    LocalDOMWindow* window = receiver->frame()->document()->domWindow();
    ASSERT(window == DartUtilities::domWindowForCurrentIsolate());
    receiver->reload(window);
}

void toStringCallback(Dart_NativeArguments args)
{
    Location* receiver = DartDOMWrapper::receiver<Location>(args);
    Dart_SetReturnValue(args, DartUtilities::stringToDart(receiver->href()));
}

void valueOfCallback(Dart_NativeArguments args)
{
    DART_UNIMPLEMENTED();
}

}

}
