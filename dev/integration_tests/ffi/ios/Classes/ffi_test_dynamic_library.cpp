// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdlib.h>
#include <string.h>
#include <iostream>

#if defined(_WIN32)
#define DART_EXPORT extern "C" __declspec(dllexport)
#else
#define DART_EXPORT                                                            \
  extern "C" __attribute__((visibility("default"))) __attribute((used))
#endif

DART_EXPORT intptr_t return42() {
  return 42;
}

DART_EXPORT double timesFour(double d) {
  return d * 4.0;
}

// Wrap memmove so we can easily find it on all platforms.
//
// We use this in our samples to illustrate resource lifetime management.
DART_EXPORT void MemMove(void* destination, void* source, intptr_t num_bytes) {
  memmove(destination, source, num_bytes);
}

// Some opaque struct.
typedef struct {
} some_resource;

DART_EXPORT some_resource* AllocateResource() {
  void* pointer = malloc(sizeof(int64_t));

  // Dummy initialize.
  static_cast<int64_t*>(pointer)[0] = 10;

  return static_cast<some_resource*>(pointer);
}

DART_EXPORT void UseResource(some_resource* resource) {
  // Dummy change.
  reinterpret_cast<int64_t*>(resource)[0] += 10;
}

DART_EXPORT void ReleaseResource(some_resource* resource) {
  free(resource);
}
