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
#include "bindings/core/dart/DartHistory.h"

#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartUtilities.h"
#include "core/frame/History.h"

namespace blink {

namespace DartHistoryInternal {

void stateGetter(Dart_NativeArguments args)
{
    DART_UNIMPLEMENTED();
}

static void addStateObjectHelper(Dart_NativeArguments args, FrameLoadType loadType)
{
    Dart_Handle exception = 0;
    {
        History* receiver = DartDOMWrapper::receiver<History>(args);

        RefPtr<SerializedScriptValue> data = DartUtilities::dartToSerializedScriptValue(Dart_GetNativeArgument(args, 1), exception);
        if (exception)
            goto fail;

        DartStringAdapter title = DartUtilities::dartToString(args, 2, exception);
        if (exception)
            goto fail;

        // FIXME: url argument should be optional.
        DartStringAdapter url = DartUtilities::dartToString(args, 3, exception);
        if (exception)
            goto fail;

        DartExceptionState es;
        receiver->stateObjectAdded(data.release(), title, url, loadType, es);
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

void pushStateCallback(Dart_NativeArguments args)
{
    addStateObjectHelper(args, FrameLoadTypeStandard);
}

void replaceStateCallback(Dart_NativeArguments args)
{
    addStateObjectHelper(args, FrameLoadTypeRedirectWithLockedBackForwardList);
}

}

}
