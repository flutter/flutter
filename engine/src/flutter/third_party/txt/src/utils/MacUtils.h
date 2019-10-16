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

#ifndef MAC_UTILS_H
#define MAC_UTILS_H

#if defined(__APPLE__)
#define DISABLE_TEST_MAC(TEST_NAME) DISABLED_##TEST_NAME
#define FRIEND_TEST_MAC_DISABLED_EXPANDED(SUITE, TEST_NAME) \
  FRIEND_TEST(SUITE, TEST_NAME)
#define FRIEND_TEST_MAC_DISABLED(SUITE, TEST_NAME) \
  FRIEND_TEST_MAC_DISABLED_EXPANDED(SUITE, DISABLE_TEST_MAC(TEST_NAME))

#define FRIEND_TEST_MAC_ONLY(SUITE, TEST_NAME) FRIEND_TEST(SUITE, TEST_NAME)
#define MAC_ONLY(TEST_NAME) TEST_NAME

#else
#define DISABLE_TEST_MAC(TEST_NAME) TEST_NAME
#define FRIEND_TEST_MAC_DISABLED(SUITE, TEST_NAME) FRIEND_TEST(SUITE, TEST_NAME)

#define MAC_ONLY(TEST_NAME) DISABLED_##TEST_NAME
#define FRIEND_TEST_MAC_ONLY_EXPANDED(SUITE, TEST_NAME) \
  FRIEND_TEST(SUITE, TEST_NAME)
#define FRIEND_TEST_MAC_ONLY(SUITE, TEST_NAME) \
  FRIEND_TEST_MAC_ONLY_EXPANDED(SUITE, DISABLE_TEST_MAC(TEST_NAME))
#endif  // defined(__APPLE__)
#endif  // MAC_UTILS_H
