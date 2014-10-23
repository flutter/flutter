/*

Copyright (C) 2010 Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#ifndef NullPtr_h
#define NullPtr_h

// For compilers and standard libraries that do not yet include it, this adds the
// nullptr_t type and nullptr object. They are defined in the same namespaces they
// would be in compiler and library that had the support.

#if COMPILER_SUPPORTS(CXX_NULLPTR) || defined(_LIBCPP_VERSION)

// libstdc++ supports nullptr_t starting with gcc 4.6. STLport doesn't define it.
#if (defined(__GLIBCXX__) && __GLIBCXX__ < 20110325) || defined(_STLPORT_VERSION)
namespace std {
typedef decltype(nullptr) nullptr_t;
}
#endif

#else

#include "wtf/WTFExport.h"

namespace std {
class nullptr_t {
public:
    // Required in order to create const nullptr_t objects without an
    // explicit initializer in GCC 4.5, a la:
    //
    // const std::nullptr_t nullptr;
    nullptr_t() { }

    // Make nullptr convertible to any pointer type.
    template<typename T> operator T*() const { return 0; }
    // Make nullptr convertible to any member pointer type.
    template<typename C, typename T> operator T C::*() { return 0; }
private:
    // Do not allow taking the address of nullptr.
    void operator&();
};
}
WTF_EXPORT extern const std::nullptr_t nullptr;

#endif

#if COMPILER_SUPPORTS(CXX_DELETED_FUNCTIONS)
#define WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(ClassName) \
    private: \
        ClassName(int) = delete
#define WTF_DISALLOW_ZERO_ASSIGNMENT(ClassName) \
    private: \
        ClassName& operator=(int) = delete
#else
#define WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(ClassName) \
    private: \
        ClassName(int)
#define WTF_DISALLOW_ZERO_ASSIGNMENT(ClassName) \
    private: \
        ClassName& operator=(int)
#endif

#endif
