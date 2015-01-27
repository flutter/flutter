// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "bindings/core/dart/DartScriptPromise.h"

#include "bindings/common/ExceptionMessages.h"
#include "bindings/common/ExceptionState.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8ThrowException.h"
#include "core/dom/DOMException.h"
#include <v8.h>

namespace blink {

DartScriptPromise::DartScriptPromise(DartScriptState* scriptState, Dart_Handle future)
    : m_scriptState(scriptState)
    , m_value(future)
{
    if (!future)
        return;

    if (!Dart_IsFuture(future)) {
        m_value.clear();
        // FIXMEDART: How do we do a sticky error?
        Dart_Handle coreLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:core"));
        Dart_Handle errorClass = Dart_GetType(coreLib, DartUtilities::stringToDart((String)"ArgumentError"), 0, 0);
        Dart_Handle dartMessage = DartUtilities::stringToDart((String)"the given value is not a Future");
        Dart_Handle error = Dart_New(errorClass, Dart_NewStringFromCString(""), 1, &dartMessage);
        Dart_ThrowException(error);
        ASSERT_NOT_REACHED();
        return;
    }
}

PassRefPtr<AbstractScriptPromise> DartScriptPromise::then(PassOwnPtr<ScriptFunction> onFulfilled, PassOwnPtr<ScriptFunction> onRejected)
{
    // FIXMEDART: Implement.
    RELEASE_ASSERT_NOT_REACHED();
    return nullptr;
}

} // namespace blink
