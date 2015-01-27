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
#include "bindings/core/dart/DartDOMWrapper.h"

#include "bindings/core/dart/DartCSSStyleDeclaration.h"
#include "bindings/core/dart/DartDOMException.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartNode.h"
#include "bindings/core/dart/DartUtilities.h"
#include "core/html/HTMLFormControlElement.h"
#include "core/html/LabelableElement.h"
#include "wtf/StringExtras.h"
#include "wtf/text/WTFString.h"

#include <stdio.h>

namespace blink {

Dart_PersistentHandle DartDOMWrapper::dartClass(
    DartDOMData* domData, intptr_t cid)
{
    ASSERT(cid < NumWebkitClassIds);

    ClassTable* table = domData->classHandleCache();

    Dart_PersistentHandle persistentType = (*table)[cid];

    if (persistentType)
        return persistentType;

    // Slow path: we have not encountered this type yet. Look up the registered wrapper.
    Dart_Handle htmlLibrary = domData->htmlLibrary();
    Dart_Handle type = Dart_Null();
    Dart_Handle getType = Dart_NewStringFromCString("_getType");
    intptr_t searchid = cid;
    while (searchid > 0 && Dart_IsNull(type)) {
        const char* keyName = DartWebkitClassInfo[searchid].jsName;
        Dart_Handle key = Dart_NewStringFromCString(keyName);
        type = Dart_Invoke(htmlLibrary, getType, 1, &key);
        if (Dart_IsError(type)) {
            DartUtilities::reportProblem(domData->scriptExecutionContext(), type);
            break;
        }

        if (Dart_IsNull(type)) {
            searchid = DartWebkitClassInfo[searchid].base_class_id;
        }
    }
    if ((searchid <= 0) || Dart_IsError(type) || !Dart_IsType(type) || Dart_IsNull(type)) {
        Dart_Handle error;
        if (Dart_IsError(type)) {
            error = type;
        } else {
            char message[256];
            snprintf(message, 256, "Unsupported native browser type: %s", DartWebkitClassInfo[cid].jsName);
            error = Dart_NewApiError(message);
        }
        DartUtilities::reportProblem(domData->scriptExecutionContext(), error);
        type = Dart_GetType(htmlLibrary, Dart_NewStringFromCString("_UnsupportedBrowserObject"), 0, 0);
    }

    persistentType = Dart_NewPersistentHandle(type);
    (*table)[cid] = persistentType;

    return persistentType;
}

}
