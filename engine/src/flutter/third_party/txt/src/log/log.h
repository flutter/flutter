/*
 * Copyright 2017 Google, Inc.
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

#pragma once

#include <stdint.h>

#include "flutter/fml/logging.h"

#if defined(_WIN32)
// Conflicts with macro on Windows.
#undef ERROR
#endif

#ifndef LOG_ALWAYS_FATAL_IF
#define LOG_ALWAYS_FATAL_IF(cond, ...) \
  ((cond) ? (FML_LOG(FATAL) << #cond) : (void)0)
#endif

#ifndef LOG_ALWAYS_FATAL
#define LOG_ALWAYS_FATAL(...) FML_LOG(FATAL)
#endif

#ifndef LOG_ASSERT
#define LOG_ASSERT(cond, ...) FML_CHECK(cond)
#define ALOG_ASSERT LOG_ASSERT
#endif

#ifndef ALOGD
#define ALOGD(message, ...) FML_DLOG(INFO) << (message)
#endif

#ifndef ALOGW
#define ALOGW(message, ...) FML_LOG(WARNING) << (message)
#endif

#ifndef ALOGE
#define ALOGE(message, ...) FML_LOG(ERROR) << (message)
#endif

#define android_errorWriteLog(tag, subTag) \
  __android_log_error_write(tag, subTag, -1, NULL, 0)
#define android_errorWriteWithInfoLog(tag, subTag, uid, data, dataLen) \
  __android_log_error_write(tag, subTag, uid, data, dataLen)
int __android_log_error_write(int tag,
                              const char* subTag,
                              int32_t uid,
                              const char* data,
                              uint32_t dataLen);
