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
#include "bindings/core/dart/DartEvent.h"

#include "bindings/core/dart/DartDataTransfer.h"
#include "core/DartEventHeaders.h"
#include "core/EventInterfaces.h"
#include "core/clipboard/DataTransfer.h"
#include "core/events/ClipboardEvent.h"
#include "core/events/Event.h"
#include "modules/DartEventModulesHeaders.h"
#include "modules/EventModulesInterfaces.h"

#include <dart_api.h>

namespace blink {

// FIXMEDART: we shouldn't have to define this bogus toDart method
// for an event we don't support as we do not support service workers.
Dart_Handle InstallEvent_toDart(void*) {
    ASSERT_NOT_REACHED();
    return Dart_Null();
}

// FIXMEDART: we shouldn't have to define this bogus toDart method
// for an event we don't support as we do not support service workers.
Dart_Handle InstallPhaseEvent_toDart(void*) {
    ASSERT_NOT_REACHED();
    return Dart_Null();
}

#define TRY_TO_WRAP_WITH_INTERFACE(interfaceName) \
    if (EventNames::interfaceName == desiredInterface) \
        return toDartNoInline(static_cast<interfaceName*>(event), 0);

Dart_Handle DartEvent::createWrapper(DartDOMData* domData, Event* event)
{
    if (!event)
        return Dart_Null();

    String desiredInterface = event->interfaceName();

    // We need to check Event first to avoid infinite recursion.
    if (EventNames::Event == desiredInterface)
        return DartDOMWrapper::createWrapper<DartEvent>(domData, event);

    EVENT_INTERFACES_FOR_EACH(TRY_TO_WRAP_WITH_INTERFACE)
    EVENT_MODULES_INTERFACES_FOR_EACH(TRY_TO_WRAP_WITH_INTERFACE)

    return DartDOMWrapper::createWrapper<DartEvent>(domData, event);
}

namespace DartEventInternal {

void clipboardDataGetter(Dart_NativeArguments args)
{
    Event* event = DartDOMWrapper::receiver<Event>(args);

    if (event->isClipboardEvent())
    {
        DartDOMWrapper::returnToDart<DartDataTransfer>(args, static_cast<ClipboardEvent*>(event)->clipboardData());
    }
}

}

}
