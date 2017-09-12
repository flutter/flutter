/*
 * Copyright (C) 2006, 2010 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_STRINGEXTRAS_H_
#define SKY_ENGINE_WTF_STRINGEXTRAS_H_

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include "flutter/sky/engine/wtf/OperatingSystem.h"

#if !HAVE(STRNSTR)

inline char* strnstr(const char* buffer,
                     const char* target,
                     size_t bufferLength) {
  size_t targetLength = strlen(target);
  if (targetLength == 0)
    return const_cast<char*>(buffer);
  for (const char* start = buffer;
       *start && start + targetLength <= buffer + bufferLength; start++) {
    if (*start == *target &&
        strncmp(start + 1, target + 1, targetLength - 1) == 0)
      return const_cast<char*>(start);
  }
  return 0;
}

#endif

#endif  // SKY_ENGINE_WTF_STRINGEXTRAS_H_
