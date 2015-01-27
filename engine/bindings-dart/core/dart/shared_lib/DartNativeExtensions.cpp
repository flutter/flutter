/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "bindings/core/dart/shared_lib/DartNativeExtensions.h"

#include "bindings/core/dart/DartUtilities.h"

namespace blink {

#if defined(ENABLE_DART_NATIVE_EXTENSIONS)
Dart_Handle DartNativeExtensions::loadExtension(const String& url, Dart_Handle parentLibrary)
{
    String userUri = url.substring(String("dart-ext:").length());

    String name;
    String path;
    size_t index = userUri.reverseFind('/');
    if (index == kNotFound) {
        name = userUri;
        path = "./";
    } else if (index == userUri.length() - 1) {
        return Dart_NewApiError("Extension name missing.");
    } else {
        name = userUri.substring(index + 1);
        path = userUri.substring(0, index + 1);
    }

    void* libraryHandle = 0;
    Dart_Handle result = loadExtensionLibrary(path, name, &libraryHandle);
    if (Dart_IsError(result)) {
        return result;
    }

    String initFunctionName = name + "_Init";

    typedef Dart_Handle (*InitFunctionType)(Dart_Handle library);
    InitFunctionType fn;
    result = resolveSymbol(libraryHandle, initFunctionName, reinterpret_cast<void**>(&fn));
    if (Dart_IsError(result)) {
        return result;
    }

    return (*fn)(parentLibrary);
}
#else
Dart_Handle DartNativeExtensions::loadExtension(const String& url, Dart_Handle parentLibrary)
{
    return Dart_NewApiError("Native extensions are not enabled.");
}
#endif // defined(ENABLE_DART_NATIVE_EXTENSIONS)

}


