/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef WINDOWS_UTILS_H
#define WINDOWS_UTILS_H

#if defined(_WIN32)
#define DISABLE_TEST_WINDOWS(TEST_NAME) DISABLED_##TEST_NAME
#define FRIEND_TEST_WINDOWS_DISABLED_EXPANDED(SUITE, TEST_NAME) \
  FRIEND_TEST(SUITE, TEST_NAME)
#define FRIEND_TEST_WINDOWS_DISABLED(SUITE, TEST_NAME) \
  FRIEND_TEST_WINDOWS_DISABLED_EXPANDED(SUITE, DISABLE_TEST_WINDOWS(TEST_NAME))

#define FRIEND_TEST_WINDOWS_ONLY(SUITE, TEST_NAME) FRIEND_TEST(SUITE, TEST_NAME)
#define WINDOWS_ONLY(TEST_NAME) TEST_NAME

#define NOMINMAX
#include <BaseTsd.h>
#include <intrin.h>
#include <windows.h>

#undef ERROR

inline unsigned int clz_win(unsigned int num) {
  unsigned long r = 0;
  _BitScanReverse(&r, num);
  return r;
}

inline unsigned int clzl_win(unsigned long num) {
  unsigned long r = 0;
  _BitScanReverse64(&r, num);
  return r;
}

inline unsigned int ctz_win(unsigned int num) {
  unsigned long r = 0;
  _BitScanForward(&r, num);
  return r;
}

typedef SSIZE_T ssize_t;

#else
#define DISABLE_TEST_WINDOWS(TEST_NAME) TEST_NAME
#define FRIEND_TEST_WINDOWS_DISABLED(SUITE, TEST_NAME) \
  FRIEND_TEST(SUITE, TEST_NAME)

#define WINDOWS_ONLY(TEST_NAME) DISABLED_##TEST_NAME
#define FRIEND_TEST_WINDOWS_ONLY_EXPANDED(SUITE, TEST_NAME) \
  FRIEND_TEST(SUITE, TEST_NAME)
#define FRIEND_TEST_WINDOWS_ONLY(SUITE, TEST_NAME) \
  FRIEND_TEST_WINDOWS_ONLY_EXPANDED(SUITE, DISABLE_TEST_WINDOWS(TEST_NAME))
#endif  // defined(_WIN32)
#endif  // WINDOWS_UTILS_H
