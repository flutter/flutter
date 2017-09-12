/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_DATALOG_H_
#define SKY_ENGINE_WTF_DATALOG_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/FilePrintStream.h"

#include <stdarg.h>
#include <stdio.h>

namespace WTF {

FilePrintStream& dataFile();

void dataLogFV(const char* format, va_list) WTF_ATTRIBUTE_PRINTF(1, 0);
void dataLogF(const char* format, ...) WTF_ATTRIBUTE_PRINTF(1, 2);
void dataLogFString(const char*);

template <typename T>
void dataLog(const T& value) {
  dataFile().print(value);
}

template <typename T1, typename T2>
void dataLog(const T1& value1, const T2& value2) {
  dataFile().print(value1, value2);
}

template <typename T1, typename T2, typename T3>
void dataLog(const T1& value1, const T2& value2, const T3& value3) {
  dataFile().print(value1, value2, value3);
}

template <typename T1, typename T2, typename T3, typename T4>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4) {
  dataFile().print(value1, value2, value3, value4);
}

template <typename T1, typename T2, typename T3, typename T4, typename T5>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5) {
  dataFile().print(value1, value2, value3, value4, value5);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6) {
  dataFile().print(value1, value2, value3, value4, value5, value6);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8,
          typename T9>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8,
             const T9& value9) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8, value9);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8,
          typename T9,
          typename T10>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8,
             const T9& value9,
             const T10& value10) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8, value9, value10);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8,
          typename T9,
          typename T10,
          typename T11>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8,
             const T9& value9,
             const T10& value10,
             const T11& value11) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8, value9, value10, value11);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8,
          typename T9,
          typename T10,
          typename T11,
          typename T12>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8,
             const T9& value9,
             const T10& value10,
             const T11& value11,
             const T12& value12) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8, value9, value10, value11, value12);
}

template <typename T1,
          typename T2,
          typename T3,
          typename T4,
          typename T5,
          typename T6,
          typename T7,
          typename T8,
          typename T9,
          typename T10,
          typename T11,
          typename T12,
          typename T13>
void dataLog(const T1& value1,
             const T2& value2,
             const T3& value3,
             const T4& value4,
             const T5& value5,
             const T6& value6,
             const T7& value7,
             const T8& value8,
             const T9& value9,
             const T10& value10,
             const T11& value11,
             const T12& value12,
             const T13& value13) {
  dataFile().print(value1, value2, value3, value4, value5, value6, value7,
                   value8, value9, value10, value11, value12, value13);
}

}  // namespace WTF

using WTF::dataLog;
using WTF::dataLogF;
using WTF::dataLogFString;

#endif  // SKY_ENGINE_WTF_DATALOG_H_
