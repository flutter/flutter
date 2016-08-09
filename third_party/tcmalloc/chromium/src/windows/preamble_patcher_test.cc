/* Copyright (c) 2011, Google Inc.
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
 * Author: Joi Sigurdsson
 * Author: Scott Francis
 *
 * Unit tests for PreamblePatcher
 */

#include "config_for_unittests.h"
#include "preamble_patcher.h"
#include "mini_disassembler.h"
#pragma warning(push)
#pragma warning(disable:4553)
#include "auto_testing_hook.h"
#pragma warning(pop)

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tchar.h>

// Turning off all optimizations for this file, since the official build's
// "Whole program optimization" seems to cause the TestPatchUsingDynamicStub
// test to crash with an access violation.  We debugged this and found
// that the optimized access a register that is changed by a call to the hook
// function.
#pragma optimize("", off)

// A convenience macro to avoid a lot of casting in the tests.
// I tried to make this a templated function, but windows complained:
//     error C2782: 'sidestep::SideStepError `anonymous-namespace'::Unpatch(T,T,T *)' : template parameter 'T' is ambiguous
//        could be 'int (int)'
//        or       'int (__cdecl *)(int)'
// My life isn't long enough to try to figure out how to fix this.
#define UNPATCH(target_function, replacement_function, original_function_stub) \
  sidestep::PreamblePatcher::Unpatch((void*)(target_function),          \
                                     (void*)(replacement_function),     \
                                     (void*)(original_function))

namespace {

// Function for testing - this is what we patch
//
// NOTE:  Because of the way the compiler optimizes this function in
// release builds, we need to use a different input value every time we
// call it within a function, otherwise the compiler will just reuse the
// last calculated incremented value.
int __declspec(noinline) IncrementNumber(int i) {
#ifdef _M_X64
  __int64 i2 = i + 1;
  return (int) i2;
#else
   return i + 1;
#endif
}

extern "C" int TooShortFunction(int);

extern "C" int JumpShortCondFunction(int);

extern "C" int JumpNearCondFunction(int);

extern "C" int JumpAbsoluteFunction(int);

extern "C" int CallNearRelativeFunction(int);

typedef int (*IncrementingFunc)(int);
IncrementingFunc original_function = NULL;

int HookIncrementNumber(int i) {
  SIDESTEP_ASSERT(original_function != NULL);
  int incremented_once = original_function(i);
  return incremented_once + 1;
}

// For the AutoTestingHook test, we can't use original_function, because
// all that is encapsulated.
// This function "increments" by 10, just to set it apart from the other
// functions.
int __declspec(noinline) AutoHookIncrementNumber(int i) {
  return i + 10;
}

};  // namespace

namespace sidestep {

bool TestDisassembler() {
   unsigned int instruction_size = 0;
   sidestep::MiniDisassembler disassembler;
   void * target = reinterpret_cast<unsigned char *>(IncrementNumber);
   void * new_target = PreamblePatcher::ResolveTarget(target);
   if (target != new_target)
      target = new_target;

   while (1) {
      sidestep::InstructionType instructionType = disassembler.Disassemble(
         reinterpret_cast<unsigned char *>(target) + instruction_size,
         instruction_size);
      if (sidestep::IT_RETURN == instructionType) {
         return true;
      }
   }
}

bool TestPatchWithLongJump() {
  original_function = NULL;
  void *p = ::VirtualAlloc(reinterpret_cast<void *>(0x0000020000000000), 4096,
                           MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  SIDESTEP_EXPECT_TRUE(p != NULL);
  memset(p, 0xcc, 4096);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(IncrementNumber,
                                                        (IncrementingFunc) p,
                                                        &original_function));
  SIDESTEP_ASSERT((*original_function)(1) == 2);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(IncrementNumber,
                               (IncrementingFunc)p,
                               original_function));
  ::VirtualFree(p, 0, MEM_RELEASE);
  return true;
}

bool TestPatchWithPreambleShortCondJump() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(JumpShortCondFunction,
                                                        HookIncrementNumber,
                                                        &original_function));
  (*original_function)(1);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(JumpShortCondFunction,
                               (void*)HookIncrementNumber,
                               original_function));
  return true;
}

bool TestPatchWithPreambleNearRelativeCondJump() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(JumpNearCondFunction,
                                                        HookIncrementNumber,
                                                        &original_function));
  (*original_function)(0);
  (*original_function)(1);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(JumpNearCondFunction,
                               HookIncrementNumber,
                               original_function));
  return true;
}

bool TestPatchWithPreambleAbsoluteJump() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(JumpAbsoluteFunction,
                                                        HookIncrementNumber,
                                                        &original_function));
  (*original_function)(0);
  (*original_function)(1);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(JumpAbsoluteFunction,
                               HookIncrementNumber,
                               original_function));
  return true;
}

bool TestPatchWithPreambleNearRelativeCall() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(
                                                    CallNearRelativeFunction,
                                                    HookIncrementNumber,
                                                    &original_function));
  (*original_function)(0);
  (*original_function)(1);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(CallNearRelativeFunction,
                               HookIncrementNumber,
                               original_function));
  return true;
}

bool TestPatchUsingDynamicStub() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(IncrementNumber(1) == 2);
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(IncrementNumber,
                                                        HookIncrementNumber,
                                                        &original_function));
  SIDESTEP_EXPECT_TRUE(original_function);
  SIDESTEP_EXPECT_TRUE(IncrementNumber(2) == 4);
  SIDESTEP_EXPECT_TRUE(original_function(3) == 4);

  // Clearbox test to see that the function has been patched.
  sidestep::MiniDisassembler disassembler;
  unsigned int instruction_size = 0;
  SIDESTEP_EXPECT_TRUE(sidestep::IT_JUMP == disassembler.Disassemble(
                           reinterpret_cast<unsigned char*>(IncrementNumber),
                           instruction_size));

  // Since we patched IncrementNumber, its first statement is a
  // jmp to the hook function.  So verify that we now can not patch
  // IncrementNumber because it starts with a jump.
#if 0
  IncrementingFunc dummy = NULL;
  // TODO(joi@chromium.org): restore this test once flag is added to
  // disable JMP following
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_JUMP_INSTRUCTION ==
                       sidestep::PreamblePatcher::Patch(IncrementNumber,
                                                        HookIncrementNumber,
                                                        &dummy));

  // This test disabled because code in preamble_patcher_with_stub.cc
  // asserts before returning the error code -- so there is no way
  // to get an error code here, in debug build.
  dummy = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_FUNCTION_TOO_SMALL ==
                       sidestep::PreamblePatcher::Patch(TooShortFunction,
                                                        HookIncrementNumber,
                                                        &dummy));
#endif

  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(IncrementNumber,
                               HookIncrementNumber,
                               original_function));
  return true;
}

bool PatchThenUnpatch() {
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       sidestep::PreamblePatcher::Patch(IncrementNumber,
                                                        HookIncrementNumber,
                                                        &original_function));
  SIDESTEP_EXPECT_TRUE(original_function);
  SIDESTEP_EXPECT_TRUE(IncrementNumber(1) == 3);
  SIDESTEP_EXPECT_TRUE(original_function(2) == 3);

  SIDESTEP_EXPECT_TRUE(sidestep::SIDESTEP_SUCCESS ==
                       UNPATCH(IncrementNumber,
                               HookIncrementNumber,
                               original_function));
  original_function = NULL;
  SIDESTEP_EXPECT_TRUE(IncrementNumber(3) == 4);

  return true;
}

bool AutoTestingHookTest() {
  SIDESTEP_EXPECT_TRUE(IncrementNumber(1) == 2);

  // Inner scope, so we can test what happens when the AutoTestingHook
  // goes out of scope
  {
    AutoTestingHook hook = MakeTestingHook(IncrementNumber,
                                           AutoHookIncrementNumber);
    (void) hook;
    SIDESTEP_EXPECT_TRUE(IncrementNumber(2) == 12);
  }
  SIDESTEP_EXPECT_TRUE(IncrementNumber(3) == 4);

  return true;
}

bool AutoTestingHookInContainerTest() {
  SIDESTEP_EXPECT_TRUE(IncrementNumber(1) == 2);

  // Inner scope, so we can test what happens when the AutoTestingHook
  // goes out of scope
  {
    AutoTestingHookHolder hook(MakeTestingHookHolder(IncrementNumber,
                                                     AutoHookIncrementNumber));
    (void) hook;
    SIDESTEP_EXPECT_TRUE(IncrementNumber(2) == 12);
  }
  SIDESTEP_EXPECT_TRUE(IncrementNumber(3) == 4);

  return true;
}

bool TestPreambleAllocation() {
  __int64 diff = 0;
  void* p1 = reinterpret_cast<void*>(0x110000000);
  void* p2 = reinterpret_cast<void*>(0x810000000);
  unsigned char* b1 = PreamblePatcher::AllocPreambleBlockNear(p1);
  SIDESTEP_EXPECT_TRUE(b1 != NULL);
  diff = reinterpret_cast<__int64>(p1) - reinterpret_cast<__int64>(b1);
  // Ensure blocks are within 2GB
  SIDESTEP_EXPECT_TRUE(diff <= INT_MAX && diff >= INT_MIN);
  unsigned char* b2 = PreamblePatcher::AllocPreambleBlockNear(p2);
  SIDESTEP_EXPECT_TRUE(b2 != NULL);
  diff = reinterpret_cast<__int64>(p2) - reinterpret_cast<__int64>(b2);
  SIDESTEP_EXPECT_TRUE(diff <= INT_MAX && diff >= INT_MIN);

  // Ensure we're reusing free blocks
  unsigned char* b3 = b1;
  unsigned char* b4 = b2;
  PreamblePatcher::FreePreambleBlock(b1);
  PreamblePatcher::FreePreambleBlock(b2);
  b1 = PreamblePatcher::AllocPreambleBlockNear(p1);
  SIDESTEP_EXPECT_TRUE(b1 == b3);
  b2 = PreamblePatcher::AllocPreambleBlockNear(p2);
  SIDESTEP_EXPECT_TRUE(b2 == b4);
  PreamblePatcher::FreePreambleBlock(b1);
  PreamblePatcher::FreePreambleBlock(b2);

  return true;
}

bool UnitTests() {
  return TestPatchWithPreambleNearRelativeCall() &&
      TestPatchWithPreambleAbsoluteJump() &&
      TestPatchWithPreambleNearRelativeCondJump() && 
      TestPatchWithPreambleShortCondJump() &&
      TestDisassembler() && TestPatchWithLongJump() &&
      TestPatchUsingDynamicStub() && PatchThenUnpatch() &&
      AutoTestingHookTest() && AutoTestingHookInContainerTest() &&
      TestPreambleAllocation();
}

};  // namespace sidestep

int safe_vsnprintf(char *str, size_t size, const char *format, va_list ap) {
  if (size == 0)        // not even room for a \0?
    return -1;          // not what C99 says to do, but what windows does
  str[size-1] = '\0';
  return _vsnprintf(str, size-1, format, ap);
}

int _tmain(int argc, _TCHAR* argv[])
{
  bool ret = sidestep::UnitTests();
  printf("%s\n", ret ? "PASS" : "FAIL");
  return ret ? 0 : -1;
}

#pragma optimize("", on)
