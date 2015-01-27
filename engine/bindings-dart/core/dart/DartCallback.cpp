/*
 * Copyright (C) 2006-2011 Google Inc. All rights reserved.
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
#include "bindings/core/dart/DartCallback.h"

#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartUtilities.h"

namespace blink {

DartCallback::DartCallback(Dart_Handle object, Dart_Handle& exception)
{
    if (!Dart_IsClosure(object)) {
        exception = Dart_NewStringFromCString("Callback must be a function");
        m_callback = 0;
        return;
    }
    m_callback = Dart_NewPersistentHandle(object);
}

DartCallback::~DartCallback()
{
    if (!m_callback || !isIsolateAlive())
        return;

    DartIsolateScope scope(isolate());
    Dart_DeletePersistentHandle(m_callback);
}

bool DartCallback::handleEvent(int argc, Dart_Handle* argv)
{
    ASSERT(isolate() == Dart_CurrentIsolate());
    ASSERT(m_callback);

    ExecutionContext* context = DartDOMData::current()->scriptExecutionContext();
    DartController* dartController = DartController::retrieve(context);

    Dart_Handle result = dartController->callFunction(Dart_HandleFromPersistent(m_callback), argc, argv);
    if (Dart_IsError(result)) {
        DartUtilities::reportProblem(context, result);
        return false;
    }

    return true;
}

}
