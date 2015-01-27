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
#include "bindings/core/dart/DartImageData.h"

#include "bindings/core/dart/DartDOMWrapper.h"

namespace blink {

Dart_Handle DartImageData::createWrapper(
    DartDOMData* domData, ImageData* imageData)
{
    if (!imageData)
        return Dart_Null();

    // FIMXE: In JavaScript bindings "data" property of the ImageData wrapper is
    // set to imageData->data to eliminate the C++ callback when accessing the
    // "data" property.
    return DartDOMWrapper::createWrapper<DartImageData>(domData, imageData);
}

namespace DartImageDataInternal {

// Another approach would be to set a field while constructing an object
// like v8 does, however, I hope eventually to move this call into
// field initialisation step.
void dataGetter(Dart_NativeArguments args)
{
    {
        ImageData* receiver = DartDOMWrapper::receiver<ImageData>(args);

        Dart_Handle wrapper = DartUtilities::arrayBufferViewToDart(receiver->data());
        ASSERT(!Dart_IsError(wrapper));

        Dart_SetReturnValue(args, wrapper);
        return;
    }
}

}

}
