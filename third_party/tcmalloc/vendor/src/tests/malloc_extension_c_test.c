/* Copyright (c) 2009, Google Inc.
 * All rights reserved.
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
 *
 * ---
 * Author: Craig Silverstein
 *
 * This tests the c shims: malloc_extension_c.h and malloc_hook_c.h.
 * Mostly, we'll just care that these shims compile under gcc
 * (*not* g++!)
 *
 * NOTE: this is C code, not C++ code!
 */

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>   /* for size_t */
#include <gperftools/malloc_extension_c.h>
#include <gperftools/malloc_hook_c.h>

#define FAIL(msg) do {                          \
  fprintf(stderr, "FATAL ERROR: %s\n", msg);    \
  exit(1);                                      \
} while (0)

static int g_new_hook_calls = 0;
static int g_delete_hook_calls = 0;

void TestNewHook(const void* ptr, size_t size) {
  g_new_hook_calls++;
}

void TestDeleteHook(const void* ptr) {
  g_delete_hook_calls++;
}

void TestMallocHook(void) {
  /* TODO(csilvers): figure out why we get:
   * E0100 00:00:00.000000  7383 malloc_hook.cc:244] RAW: google_malloc section is missing, thus InHookCaller is broken!
   */
#if 0
  void* result[5];

  if (MallocHook_GetCallerStackTrace(result, sizeof(result)/sizeof(*result),
                                     0) < 2) {  /* should have this and main */
    FAIL("GetCallerStackTrace failed");
  }
#endif

  if (!MallocHook_AddNewHook(&TestNewHook)) {
    FAIL("Failed to add new hook");
  }
  if (!MallocHook_AddDeleteHook(&TestDeleteHook)) {
    FAIL("Failed to add delete hook");
  }
  free(malloc(10));
  free(malloc(20));
  if (g_new_hook_calls != 2) {
    FAIL("Wrong number of calls to the new hook");
  }
  if (g_delete_hook_calls != 2) {
    FAIL("Wrong number of calls to the delete hook");
  }
  if (!MallocHook_RemoveNewHook(&TestNewHook)) {
    FAIL("Failed to remove new hook");
  }
  if (!MallocHook_RemoveDeleteHook(&TestDeleteHook)) {
    FAIL("Failed to remove delete hook");
  }
}

void TestMallocExtension(void) {
  int blocks;
  size_t total;
  int hist[64];
  char buffer[200];
  char* x = (char*)malloc(10);

  MallocExtension_VerifyAllMemory();
  MallocExtension_VerifyMallocMemory(x);
  MallocExtension_MallocMemoryStats(&blocks, &total, hist);
  MallocExtension_GetStats(buffer, sizeof(buffer));
  if (!MallocExtension_GetNumericProperty("generic.current_allocated_bytes",
                                          &total)) {
    FAIL("GetNumericProperty failed for generic.current_allocated_bytes");
  }
  if (total < 10) {
    FAIL("GetNumericProperty had bad return for generic.current_allocated_bytes");
  }
  if (!MallocExtension_GetNumericProperty("generic.current_allocated_bytes",
                                          &total)) {
    FAIL("GetNumericProperty failed for generic.current_allocated_bytes");
  }
  MallocExtension_MarkThreadIdle();
  MallocExtension_MarkThreadBusy();
  MallocExtension_ReleaseToSystem(1);
  MallocExtension_ReleaseFreeMemory();
  if (MallocExtension_GetEstimatedAllocatedSize(10) < 10) {
    FAIL("GetEstimatedAllocatedSize returned a bad value (too small)");
  }
  if (MallocExtension_GetAllocatedSize(x) < 10) {
    FAIL("GetEstimatedAllocatedSize returned a bad value (too small)");
  }
  if (MallocExtension_GetOwnership(x) != MallocExtension_kOwned) {
    FAIL("DidAllocatePtr returned a bad value (kNotOwned)");
  }
  /* TODO(csilvers): this relies on undocumented behavior that
     GetOwnership works on stack-allocated variables.  Use a better test. */
  if (MallocExtension_GetOwnership(hist) != MallocExtension_kNotOwned) {
    FAIL("DidAllocatePtr returned a bad value (kOwned)");
  }

  free(x);
}

int main(int argc, char** argv) {
  TestMallocHook();
  TestMallocExtension();

  printf("PASS\n");
  return 0;
}
