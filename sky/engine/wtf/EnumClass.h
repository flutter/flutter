/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_ENUMCLASS_H_
#define SKY_ENGINE_WTF_ENUMCLASS_H_

#include "flutter/sky/engine/wtf/Compiler.h"

namespace WTF {

// How to define a type safe enum list using the ENUM_CLASS macros?
// ===============================================================
// To get an enum list like this:
//
//     enum class MyEnums {
//         Value1,
//         Value2,
//         ...
//         ValueN
//     };
//
// ... write this:
//
//     ENUM_CLASS(MyEnums) {
//         Value1,
//         Value2,
//         ...
//         ValueN
//     } ENUM_CLASS_END(MyEnums);
//
// The ENUM_CLASS macros will use C++11's enum class if the compiler supports
// it. Otherwise, it will use the EnumClass template below.

#define ENUM_CLASS(__enumName) enum class __enumName

#define ENUM_CLASS_END(__enumName)

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_ENUMCLASS_H_
