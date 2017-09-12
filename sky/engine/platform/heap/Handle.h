/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_HEAP_HANDLE_H_
#define SKY_ENGINE_PLATFORM_HEAP_HANDLE_H_

#include "flutter/sky/engine/wtf/StdLibExtras.h"

//
// STACK_ALLOCATED(): Use if the object is only stack allocated.
//
// DISALLOW_ALLOCATION(): Cannot be allocated with new operators but can
// be a part object.
//
// ALLOW_ONLY_INLINE_ALLOCATION(): Allows only placement new operator.
// This disallows general allocation of this object but allows to put
// the object as a value object in collections.
//
#define DISALLOW_ALLOCATION()                             \
 private:                                                 \
  void* operator new(size_t) = delete;                    \
  void* operator new(size_t, NotNullTag, void*) = delete; \
  void* operator new(size_t, void*) = delete;

#define ALLOW_ONLY_INLINE_ALLOCATION()                                        \
 public:                                                                      \
  void* operator new(size_t, NotNullTag, void* location) { return location; } \
  void* operator new(size_t, void* location) { return location; }             \
                                                                              \
 private:                                                                     \
  void* operator new(size_t) = delete;

#define STATIC_ONLY(Type) \
 private:                 \
  Type() = delete;

// These macros insert annotations that the Blink GC plugin for clang uses for
// verification. STACK_ALLOCATED is used to declare that objects of this type
// are always stack allocated. GC_PLUGIN_IGNORE is used to make the plugin
// ignore a particular class or field when checking for proper usage. When using
// GC_PLUGIN_IGNORE a bug-number should be provided as an argument where the
// bug describes what needs to happen to remove the GC_PLUGIN_IGNORE again.
#if COMPILER(CLANG)
#define STACK_ALLOCATED()                                                \
 private:                                                                \
  __attribute__((annotate("blink_stack_allocated"))) void* operator new( \
      size_t) = delete;                                                  \
  void* operator new(size_t, NotNullTag, void*) = delete;                \
  void* operator new(size_t, void*) = delete;

#else
#define STACK_ALLOCATED() DISALLOW_ALLOCATION()
#endif

#define DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) \
 public:                                               \
  ~type();                                             \
                                                       \
 private:
#define DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(type) \
 public:                                                       \
  virtual ~type();                                             \
                                                               \
 private:

#define DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) \
  type::~type() {}

#define DEFINE_STATIC_REF_WILL_BE_PERSISTENT(type, name, arguments) \
  DEFINE_STATIC_REF(type, name, arguments)

#endif  // SKY_ENGINE_PLATFORM_HEAP_HANDLE_H_
