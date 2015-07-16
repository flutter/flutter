// Copyright (c) 2006-2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "linux_shadow_stacks.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const int kMaxShadowIndex = 2048;
static const char kOverflowMessage[] = "Shadow stack overflow\n";

// Thread-local vars.
__thread
int shadow_index = -1;
__thread
void *shadow_ip_stack[kMaxShadowIndex];
__thread
void *shadow_sp_stack[kMaxShadowIndex];

enum Status {UNINITIALIZED = -1, DISABLED, ENABLED};
Status status = UNINITIALIZED;

void init() {
  if (!getenv("KEEP_SHADOW_STACKS")) {
    status = DISABLED;
    return;
  }
  status = ENABLED;
}

void __cyg_profile_func_enter(void *this_fn, void *call_site) {
  if (status == DISABLED) return;
  if (status == UNINITIALIZED) {
    init();
    if (status == DISABLED) return;
  }
  shadow_index++;
  if (shadow_index > kMaxShadowIndex) {
    // Avoid memory allocation when reporting an error.
    write(2, kOverflowMessage, sizeof(kOverflowMessage));
    int a = 0;
    a = a / a;
  }
  // Update the shadow IP stack
  shadow_ip_stack[shadow_index] = this_fn;
  // Update the shadow SP stack. The code for obtaining the frame address was
  // borrowed from Google Perftools, http://code.google.com/p/google-perftools/
  //
  // Copyright (c) 2005, Google Inc.
  // All rights reserved.
  //
  // Redistribution and use in source and binary forms, with or without
  // modification, are permitted provided that the following conditions are
  // met:
  //
  //     * Redistributions of source code must retain the above copyright
  // notice, this list of conditions and the following disclaimer.
  //     * Redistributions in binary form must reproduce the above
  // copyright notice, this list of conditions and the following disclaimer
  // in the documentation and/or other materials provided with the
  // distribution.
  //     * Neither the name of Google Inc. nor the names of its
  // contributors may be used to endorse or promote products derived from
  // this software without specific prior written permission.
  //
  // THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  // "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  // LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  // A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  // OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  // SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  // LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  // DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  // THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  // (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  // OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  void **sp;
#if (__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 2) || __llvm__
  // __builtin_frame_address(0) can return the wrong address on gcc-4.1.0-k8.
  // It's always correct on llvm, and the techniques below aren't (in
  // particular, llvm-gcc will make a copy of this_fn, so it's not in sp[2]),
  // so we also prefer __builtin_frame_address when running under llvm.
  sp = reinterpret_cast<void**>(__builtin_frame_address(0));
#elif defined(__i386__)
  // Stack frame format:
  //    sp[0]   pointer to previous frame
  //    sp[1]   caller address
  //    sp[2]   first argument
  //    ...
  // NOTE: This will break under llvm, since result is a copy and not in sp[2]
  sp = (void **)&this_fn - 2;
#elif defined(__x86_64__)
  unsigned long rbp;
  // Move the value of the register %rbp into the local variable rbp.
  // We need 'volatile' to prevent this instruction from getting moved
  // around during optimization to before function prologue is done.
  // An alternative way to achieve this
  // would be (before this __asm__ instruction) to call Noop() defined as
  //   static void Noop() __attribute__ ((noinline));  // prevent inlining
  //   static void Noop() { asm(""); }  // prevent optimizing-away
  __asm__ volatile ("mov %%rbp, %0" : "=r" (rbp));
  // Arguments are passed in registers on x86-64, so we can't just
  // offset from &result
  sp = (void **) rbp;
#else
# error Cannot obtain SP (possibly compiling on a non x86 architecture)
#endif
  shadow_sp_stack[shadow_index] = (void*)sp;
  return;
}

void __cyg_profile_func_exit(void *this_fn, void *call_site) {
  if (status == DISABLED) return;
  shadow_index--;
}

void *get_shadow_ip_stack(int *index /*OUT*/) {
  *index = shadow_index;
  return shadow_ip_stack;
}

void *get_shadow_sp_stack(int *index /*OUT*/) {
  *index = shadow_index;
  return shadow_sp_stack;
}
