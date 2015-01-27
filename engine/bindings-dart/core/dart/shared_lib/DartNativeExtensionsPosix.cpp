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

#if defined(ENABLE_DART_NATIVE_EXTENSIONS)
#if OS(POSIX)
#include "wtf/text/StringUTF8Adaptor.h"
#include <dlfcn.h>
#include <string>


namespace blink {

Dart_Handle DartNativeExtensions::loadExtensionLibrary(const String& libraryPath, const String& libraryName, void** libraryHandle)
{
    String libraryFile = libraryPath;
#if OS(MACOSX)
    libraryFile.append("lib");
    libraryFile.append(libraryName);
    libraryFile.append(".dylib");
#else
    libraryFile.append("lib");
    libraryFile.append(libraryName);
    libraryFile.append(".so");
#endif
    StringUTF8Adaptor utf8LibraryFile(libraryFile);
    std::string utf8LibraryFileStr(utf8LibraryFile.data(), utf8LibraryFile.length());
    *libraryHandle = dlopen(utf8LibraryFileStr.c_str(), RTLD_LAZY);
    if (!*libraryHandle) {
        return Dart_NewApiError(dlerror());
    }
    return Dart_Null();
}

Dart_Handle DartNativeExtensions::resolveSymbol(void* libHandle, const String& symbolName, void** symbol)
{
    StringUTF8Adaptor utf8Symbol(symbolName);
    std::string utf8SymbolStr(utf8Symbol.data(), utf8Symbol.length());
    dlerror();
    *symbol = dlsym(libHandle, utf8SymbolStr.c_str());
    const char* error = dlerror();
    if (error) {
        return Dart_NewApiError(error);
    }
    return Dart_Null();
}

}

#endif // OS(POSIX)
#endif // defined(ENABLE_DART_NATIVE_EXTENSIONS)
