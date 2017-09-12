/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_MATHEXTRAS_H_
#define SKY_ENGINE_WTF_MATHEXTRAS_H_

#include <cmath>
#include <cstddef>
#include <limits>

#include "flutter/sky/engine/wtf/CPU.h"
#include "flutter/sky/engine/wtf/OperatingSystem.h"

const double piDouble = M_PI;
const float piFloat = static_cast<float>(M_PI);

const double piOverTwoDouble = M_PI_2;
const float piOverTwoFloat = static_cast<float>(M_PI_2);

const double piOverFourDouble = M_PI_4;
const float piOverFourFloat = static_cast<float>(M_PI_4);

const double twoPiDouble = piDouble * 2.0;
const float twoPiFloat = piFloat * 2.0f;

#if OS(ANDROID)
// ANDROID and MSVC's math.h does not currently supply log2 or log2f.
inline double log2(double num) {
  // This constant is roughly M_LN2, which is not provided by default on Windows
  // and Android.
  return log(num) / 0.693147180559945309417232121458176568;
}

inline float log2f(float num) {
  // This constant is roughly M_LN2, which is not provided by default on Windows
  // and Android.
  return logf(num) / 0.693147180559945309417232121458176568f;
}
#endif

inline double deg2rad(double d) {
  return d * piDouble / 180.0;
}
inline double rad2deg(double r) {
  return r * 180.0 / piDouble;
}
inline double deg2grad(double d) {
  return d * 400.0 / 360.0;
}
inline double grad2deg(double g) {
  return g * 360.0 / 400.0;
}
inline double turn2deg(double t) {
  return t * 360.0;
}
inline double deg2turn(double d) {
  return d / 360.0;
}
inline double rad2grad(double r) {
  return r * 200.0 / piDouble;
}
inline double grad2rad(double g) {
  return g * piDouble / 200.0;
}
inline double turn2grad(double t) {
  return t * 400;
}
inline double grad2turn(double g) {
  return g / 400;
}

inline float deg2rad(float d) {
  return d * piFloat / 180.0f;
}
inline float rad2deg(float r) {
  return r * 180.0f / piFloat;
}
inline float deg2grad(float d) {
  return d * 400.0f / 360.0f;
}
inline float grad2deg(float g) {
  return g * 360.0f / 400.0f;
}
inline float turn2deg(float t) {
  return t * 360.0f;
}
inline float deg2turn(float d) {
  return d / 360.0f;
}
inline float rad2grad(float r) {
  return r * 200.0f / piFloat;
}
inline float grad2rad(float g) {
  return g * piFloat / 200.0f;
}
inline float turn2grad(float t) {
  return t * 400;
}
inline float grad2turn(float g) {
  return g / 400;
}

// std::numeric_limits<T>::min() returns the smallest positive value for
// floating point types
template <typename T>
inline T defaultMinimumForClamp() {
  return std::numeric_limits<T>::min();
}
template <>
inline float defaultMinimumForClamp() {
  return -std::numeric_limits<float>::max();
}
template <>
inline double defaultMinimumForClamp() {
  return -std::numeric_limits<double>::max();
}
template <typename T>
inline T defaultMaximumForClamp() {
  return std::numeric_limits<T>::max();
}

template <typename T>
inline T clampTo(double value,
                 T min = defaultMinimumForClamp<T>(),
                 T max = defaultMaximumForClamp<T>()) {
  if (value >= static_cast<double>(max))
    return max;
  if (value <= static_cast<double>(min))
    return min;
  return static_cast<T>(value);
}
template <>
inline long long int clampTo(
    double,
    long long int,
    long long int);  // clampTo does not support long long ints.

inline int clampToInteger(double value) {
  return clampTo<int>(value);
}

inline unsigned clampToUnsigned(double value) {
  return clampTo<unsigned>(value);
}

inline float clampToFloat(double value) {
  return clampTo<float>(value);
}

inline int clampToPositiveInteger(double value) {
  return clampTo<int>(value, 0);
}

inline int clampToInteger(float value) {
  return clampTo<int>(value);
}

inline int clampToInteger(unsigned x) {
  const unsigned intMax =
      static_cast<unsigned>(std::numeric_limits<int>::max());

  if (x >= intMax)
    return std::numeric_limits<int>::max();
  return static_cast<int>(x);
}

inline bool isWithinIntRange(float x) {
  return x > static_cast<float>(std::numeric_limits<int>::min()) &&
         x < static_cast<float>(std::numeric_limits<int>::max());
}

static size_t greatestCommonDivisor(size_t a, size_t b) {
  return b ? greatestCommonDivisor(b, a % b) : a;
}

inline size_t lowestCommonMultiple(size_t a, size_t b) {
  return a && b ? a / greatestCommonDivisor(a, b) * b : 0;
}

#ifndef UINT64_C
#define UINT64_C(c) c##ull
#endif

// Calculate d % 2^{64}.
inline void doubleToInteger(double d, unsigned long long& value) {
  if (std::isnan(d) || std::isinf(d))
    value = 0;
  else {
    // -2^{64} < fmodValue < 2^{64}.
    double fmodValue =
        fmod(trunc(d), std::numeric_limits<unsigned long long>::max() + 1.0);
    if (fmodValue >= 0) {
      // 0 <= fmodValue < 2^{64}.
      // 0 <= value < 2^{64}. This cast causes no loss.
      value = static_cast<unsigned long long>(fmodValue);
    } else {
      // -2^{64} < fmodValue < 0.
      // 0 < fmodValueInUnsignedLongLong < 2^{64}. This cast causes no loss.
      unsigned long long fmodValueInUnsignedLongLong =
          static_cast<unsigned long long>(-fmodValue);
      // -1 < (std::numeric_limits<unsigned long long>::max() -
      // fmodValueInUnsignedLongLong) < 2^{64} - 1. 0 < value < 2^{64}.
      value = std::numeric_limits<unsigned long long>::max() -
              fmodValueInUnsignedLongLong + 1;
    }
  }
}

namespace WTF {

inline unsigned fastLog2(unsigned i) {
  unsigned log2 = 0;
  if (i & (i - 1))
    log2 += 1;
  if (i >> 16)
    log2 += 16, i >>= 16;
  if (i >> 8)
    log2 += 8, i >>= 8;
  if (i >> 4)
    log2 += 4, i >>= 4;
  if (i >> 2)
    log2 += 2, i >>= 2;
  if (i >> 1)
    log2 += 1;
  return log2;
}

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_MATHEXTRAS_H_
