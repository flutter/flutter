// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <android/log.h>
#include <jni.h>
#include <stdio.h>
#include <string.h>

extern "C" {
JNIEXPORT void JNICALL
    Java_org_chromium_memconsumer_ResidentService_nativeUseMemory(JNIEnv* env,
                                                                  jobject clazz,
                                                                  jlong memory);
}

namespace {

uint32_t get_random() {
  static uint32_t m_w = 1;
  static uint32_t m_z = 1;
  m_z = 36969 * (m_z & 65535) + (m_z >> 16);
  m_w = 18000 * (m_w & 65535) + (m_w >> 16);
  return (m_z << 16) + m_w;
}

}  // namespace

JNIEXPORT void JNICALL
    Java_org_chromium_memconsumer_ResidentService_nativeUseMemory(
        JNIEnv* env,
        jobject clazz,
        jlong memory) {
  static uint32_t* g_memory = NULL;
  if (g_memory)
    free(g_memory);
  if (memory == 0) {
    g_memory = NULL;
    return;
  }
  g_memory = static_cast<uint32_t*>(malloc(memory));
  if (!g_memory) {
    __android_log_print(ANDROID_LOG_WARN,
                        "MemConsumer",
                        "Unable to allocate %ld bytes",
                        memory);
  }
  // If memory allocation failed, try to allocate as much as possible.
  while (!g_memory) {
    memory /= 2;
    g_memory = static_cast<uint32_t*>(malloc(memory));
  }
  for (int i = 0; i < memory / sizeof(uint32_t); ++i)
    *(g_memory + i) = get_random();
}
