// Copyright 2012, Google Inc.
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

#include "bindings/core/dart/DartFile.h"

namespace blink {

namespace DartFileInternal {

void constructorCallback(Dart_NativeArguments args)
{
    // FIXME: Implement this.
    DART_UNIMPLEMENTED();
}

void lastModifiedGetter(Dart_NativeArguments args)
{
    // The auto-generated getters return null when the method in the underlying
    // implementation returns NaN. The File API says we should return the
    // current time when the last modification time is unknown.
    // Section 7.2 of the File API spec. http://dev.w3.org/2006/webapi/FileAPI/

    File* file = DartDOMWrapper::receiver<File>(args);
    double lastModified = file->lastModifiedDate();
    if (!isValidFileTime(lastModified))
        lastModified = currentTimeMS();

    // lastModified returns a number, not a Date instance.
    // http://dev.w3.org/2006/webapi/FileAPI/#file-attrs
    int64_t returnValue = static_cast<int64_t>(floor(lastModified));
    Dart_SetIntegerReturnValue(args, returnValue);
}

void lastModifiedDateGetter(Dart_NativeArguments args)
{
    File* file = DartDOMWrapper::receiver<File>(args);
    double lastModified = file->lastModifiedDate();
    if (!isValidFileTime(lastModified))
        lastModified = currentTimeMS();

    // lastModifiedDate returns a Date instance.
    // http://www.w3.org/TR/FileAPI/#file-attrs
    Dart_SetReturnValue(args, DartUtilities::dateToDart(lastModified));
}

}

}
