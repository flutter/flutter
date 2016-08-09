/* Copyright (c) 2007, Google Inc.
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
 * Definition of PreamblePatcher
 */

#ifndef GOOGLE_PERFTOOLS_PREAMBLE_PATCHER_H_
#define GOOGLE_PERFTOOLS_PREAMBLE_PATCHER_H_

#include "config.h"
#include <windows.h>

// compatibility shim
#include "base/logging.h"
#define SIDESTEP_ASSERT(cond)  RAW_DCHECK(cond, #cond)
#define SIDESTEP_LOG(msg)      RAW_VLOG(1, msg)

// Maximum size of the preamble stub. We overwrite at least the first 5
// bytes of the function. Considering the worst case scenario, we need 4
// bytes + the max instruction size + 5 more bytes for our jump back to
// the original code. With that in mind, 32 is a good number :)
#ifdef _M_X64
// In 64-bit mode we may need more room.  In 64-bit mode all jumps must be
// within +/-2GB of RIP.  Because of this limitation we may need to use a
// trampoline to jump to the replacement function if it is further than 2GB
// away from the target. The trampoline is 14 bytes.
//
// So 4 bytes + max instruction size (17 bytes) + 5 bytes to jump back to the
// original code + trampoline size.  64 bytes is a nice number :-)
#define MAX_PREAMBLE_STUB_SIZE    (64)
#else
#define MAX_PREAMBLE_STUB_SIZE    (32)
#endif

// Determines if this is a 64-bit binary.
#ifdef _M_X64
static const bool kIs64BitBinary = true;
#else
static const bool kIs64BitBinary = false;
#endif

namespace sidestep {

// Possible results of patching/unpatching
enum SideStepError {
  SIDESTEP_SUCCESS = 0,
  SIDESTEP_INVALID_PARAMETER,
  SIDESTEP_INSUFFICIENT_BUFFER,
  SIDESTEP_JUMP_INSTRUCTION,
  SIDESTEP_FUNCTION_TOO_SMALL,
  SIDESTEP_UNSUPPORTED_INSTRUCTION,
  SIDESTEP_NO_SUCH_MODULE,
  SIDESTEP_NO_SUCH_FUNCTION,
  SIDESTEP_ACCESS_DENIED,
  SIDESTEP_UNEXPECTED,
};

#define SIDESTEP_TO_HRESULT(error)                      \
  MAKE_HRESULT(SEVERITY_ERROR, FACILITY_NULL, error)

class DeleteUnsignedCharArray;

// Implements a patching mechanism that overwrites the first few bytes of
// a function preamble with a jump to our hook function, which is then
// able to call the original function via a specially-made preamble-stub
// that imitates the action of the original preamble.
//
// NOTE:  This patching mechanism should currently only be used for
// non-production code, e.g. unit tests, because it is not threadsafe.
// See the TODO in preamble_patcher_with_stub.cc for instructions on what
// we need to do before using it in production code; it's fairly simple
// but unnecessary for now since we only intend to use it in unit tests.
//
// To patch a function, use either of the typesafe Patch() methods.  You
// can unpatch a function using Unpatch().
//
// Typical usage goes something like this:
// @code
// typedef int (*MyTypesafeFuncPtr)(int x);
// MyTypesafeFuncPtr original_func_stub;
// int MyTypesafeFunc(int x) { return x + 1; }
// int HookMyTypesafeFunc(int x) { return 1 + original_func_stub(x); }
// 
// void MyPatchInitializingFunction() {
//   original_func_stub = PreamblePatcher::Patch(
//              MyTypesafeFunc, HookMyTypesafeFunc);
//   if (!original_func_stub) {
//     // ... error handling ...
//   }
//
//   // ... continue - you have patched the function successfully ...
// }
// @endcode
//
// Note that there are a number of ways that this method of patching can
// fail.  The most common are:
//    - If there is a jump (jxx) instruction in the first 5 bytes of
//    the function being patched, we cannot patch it because in the
//    current implementation we do not know how to rewrite relative
//    jumps after relocating them to the preamble-stub.  Note that
//    if you really really need to patch a function like this, it
//    would be possible to add this functionality (but at some cost).
//    - If there is a return (ret) instruction in the first 5 bytes
//    we cannot patch the function because it may not be long enough
//    for the jmp instruction we use to inject our patch.
//    - If there is another thread currently executing within the bytes
//    that are copied to the preamble stub, it will crash in an undefined
//    way.
//
// If you get any other error than the above, you're either pointing the
// patcher at an invalid instruction (e.g. into the middle of a multi-
// byte instruction, or not at memory containing executable instructions)
// or, there may be a bug in the disassembler we use to find
// instruction boundaries.
//
// NOTE:  In optimized builds, when you have very trivial functions that
// the compiler can reason do not have side effects, the compiler may
// reuse the result of calling the function with a given parameter, which
// may mean if you patch the function in between your patch will never get
// invoked.  See preamble_patcher_test.cc for an example.
class PERFTOOLS_DLL_DECL PreamblePatcher {
 public:

  // This is a typesafe version of RawPatch(), identical in all other
  // ways than it takes a template parameter indicating the type of the
  // function being patched.
  //
  // @param T The type of the function you are patching. Usually
  // you will establish this type using a typedef, as in the following
  // example:
  // @code
  // typedef BOOL (WINAPI *MessageBoxPtr)(HWND, LPCTSTR, LPCTSTR, UINT);
  // MessageBoxPtr original = NULL;
  // PreamblePatcher::Patch(MessageBox, Hook_MessageBox, &original);
  // @endcode
  template <class T>
  static SideStepError Patch(T target_function,
                             T replacement_function,
                             T* original_function_stub) {
    // NOTE: casting from a function to a pointer is contra the C++
    //       spec.  It's not safe on IA64, but is on i386.  We use
    //       a C-style cast here to emphasize this is not legal C++.
    return RawPatch((void*)(target_function),
                    (void*)(replacement_function),
                    (void**)(original_function_stub));
  }

  // Patches a named function imported from the named module using
  // preamble patching.  Uses RawPatch() to do the actual patching
  // work.
  //
  // @param T The type of the function you are patching.  Must
  // exactly match the function you specify using module_name and
  // function_name.
  //
  // @param module_name The name of the module from which the function
  // is being imported.  Note that the patch will fail if this module
  // has not already been loaded into the current process.
  //
  // @param function_name The name of the function you wish to patch.
  //
  // @param replacement_function Your replacement function which
  // will be called whenever code tries to call the original function.
  //
  // @param original_function_stub Pointer to memory that should receive a
  // pointer that can be used (e.g. in the replacement function) to call the
  // original function, or NULL to indicate failure.
  //
  // @return One of the EnSideStepError error codes; only SIDESTEP_SUCCESS
  // indicates success.
  template <class T>
  static SideStepError Patch(LPCTSTR module_name,
                             LPCSTR function_name,
                             T replacement_function,
                             T* original_function_stub) {
    SIDESTEP_ASSERT(module_name && function_name);
    if (!module_name || !function_name) {
      SIDESTEP_ASSERT(false &&
                      "You must specify a module name and function name.");
      return SIDESTEP_INVALID_PARAMETER;
    }
    HMODULE module = ::GetModuleHandle(module_name);
    SIDESTEP_ASSERT(module != NULL);
    if (!module) {
      SIDESTEP_ASSERT(false && "Invalid module name.");
      return SIDESTEP_NO_SUCH_MODULE;
    }
    FARPROC existing_function = ::GetProcAddress(module, function_name);
    if (!existing_function) {
      SIDESTEP_ASSERT(
          false && "Did not find any function with that name in the module.");
      return SIDESTEP_NO_SUCH_FUNCTION;
    }
    // NOTE: casting from a function to a pointer is contra the C++
    //       spec.  It's not safe on IA64, but is on i386.  We use
    //       a C-style cast here to emphasize this is not legal C++.
    return RawPatch((void*)existing_function, (void*)replacement_function,
                    (void**)(original_function_stub));
  }

  // Patches a function by overwriting its first few bytes with
  // a jump to a different function.  This is the "worker" function
  // for each of the typesafe Patch() functions.  In most cases,
  // it is preferable to use the Patch() functions rather than
  // this one as they do more checking at compile time.
  //
  // @param target_function A pointer to the function that should be
  // patched.
  //
  // @param replacement_function A pointer to the function that should
  // replace the target function.  The replacement function must have
  // exactly the same calling convention and parameters as the original
  // function.
  //
  // @param original_function_stub Pointer to memory that should receive a
  // pointer that can be used (e.g. in the replacement function) to call the
  // original function, or NULL to indicate failure.
  //
  // @param original_function_stub Pointer to memory that should receive a
  // pointer that can be used (e.g. in the replacement function) to call the
  // original function, or NULL to indicate failure.
  //
  // @return One of the EnSideStepError error codes; only SIDESTEP_SUCCESS
  // indicates success.
  //
  // @note The preamble-stub (the memory pointed to by
  // *original_function_stub) is allocated on the heap, and (in
  // production binaries) never destroyed, resulting in a memory leak.  This
  // will be the case until we implement safe unpatching of a method.
  // However, it is quite difficult to unpatch a method (because other
  // threads in the process may be using it) so we are leaving it for now.
  // See however UnsafeUnpatch, which can be used for binaries where you
  // know only one thread is running, e.g. unit tests.
  static SideStepError RawPatch(void* target_function,
                                void* replacement_function,
                                void** original_function_stub);

  // Unpatches target_function and deletes the stub that previously could be
  // used to call the original version of the function.
  //
  // DELETES the stub that is passed to the function.
  //
  // @param target_function Pointer to the target function which was
  // previously patched, i.e. a pointer which value should match the value
  // of the symbol prior to patching it.
  //
  // @param replacement_function Pointer to the function target_function
  // was patched to.
  //
  // @param original_function_stub Pointer to the stub returned when
  // patching, that could be used to call the original version of the
  // patched function.  This function will also delete the stub, which after
  // unpatching is useless.
  //
  // If your original call was
  //    Patch(VirtualAlloc, MyVirtualAlloc, &origptr)
  // then to undo it you would call
  //    Unpatch(VirtualAlloc, MyVirtualAlloc, origptr);
  //
  // @return One of the EnSideStepError error codes; only SIDESTEP_SUCCESS
  // indicates success.
  static SideStepError Unpatch(void* target_function,
                               void* replacement_function,
                               void* original_function_stub);

  // A helper routine when patching, which follows jmp instructions at
  // function addresses, to get to the "actual" function contents.
  // This allows us to identify two functions that are at different
  // addresses but actually resolve to the same code.
  //
  // @param target_function Pointer to a function.
  //
  // @return Either target_function (the input parameter), or if
  // target_function's body consists entirely of a JMP instruction,
  // the address it JMPs to (or more precisely, the address at the end
  // of a chain of JMPs).
  template <class T>
  static T ResolveTarget(T target_function) {
    return (T)ResolveTargetImpl((unsigned char*)target_function, NULL);
  }

  // Allocates a block of memory of size MAX_PREAMBLE_STUB_SIZE that is as
  // close (within 2GB) as possible to target.  This is done to ensure that 
  // we can perform a relative jump from target to a trampoline if the 
  // replacement function is > +-2GB from target.  This means that we only need 
  // to patch 5 bytes in the target function.
  //
  // @param target    Pointer to target function.
  //
  // @return  Returns a block of memory of size MAX_PREAMBLE_STUB_SIZE that can
  //          be used to store a function preamble block.
  static unsigned char* AllocPreambleBlockNear(void* target);

  // Frees a block allocated by AllocPreambleBlockNear.
  //
  // @param block     Block that was returned by AllocPreambleBlockNear.
  static void FreePreambleBlock(unsigned char* block);

 private:
  friend class DeleteUnsignedCharArray;

   // Used to store data allocated for preamble stubs
  struct PreamblePage {
    unsigned int magic_;
    PreamblePage* next_;
    // This member points to a linked list of free blocks within the page
    // or NULL if at the end
    void* free_;
  };

  // In 64-bit mode, the replacement function must be within 2GB of the original
  // target in order to only require 5 bytes for the function patch.  To meet
  // this requirement we're creating an allocator within this class to
  // allocate blocks that are within 2GB of a given target. This member is the
  // head of a linked list of pages used to allocate blocks that are within
  // 2GB of the target.
  static PreamblePage* preamble_pages_;
  
  // Page granularity
  static long granularity_;

  // Page size
  static long pagesize_;

  // Determines if the patcher has been initialized.
  static bool initialized_;

  // Used to initialize static members.
  static void Initialize();

  // Patches a function by overwriting its first few bytes with
  // a jump to a different function.  This is similar to the RawPatch
  // function except that it uses the stub allocated by the caller
  // instead of allocating it.
  //
  // We call VirtualProtect to make the
  // target function writable at least for the duration of the call.
  //
  // @param target_function A pointer to the function that should be
  // patched.
  //
  // @param replacement_function A pointer to the function that should
  // replace the target function.  The replacement function must have
  // exactly the same calling convention and parameters as the original
  // function.
  //
  // @param preamble_stub A pointer to a buffer where the preamble stub
  // should be copied. The size of the buffer should be sufficient to
  // hold the preamble bytes.
  //
  // @param stub_size Size in bytes of the buffer allocated for the
  // preamble_stub
  //
  // @param bytes_needed Pointer to a variable that receives the minimum
  // number of bytes required for the stub.  Can be set to NULL if you're
  // not interested.
  //
  // @return An error code indicating the result of patching.
  static SideStepError RawPatchWithStubAndProtections(
      void* target_function,
      void* replacement_function,
      unsigned char* preamble_stub,
      unsigned long stub_size,
      unsigned long* bytes_needed);

  // A helper function used by RawPatchWithStubAndProtections -- it
  // does everything but the VirtualProtect work.  Defined in
  // preamble_patcher_with_stub.cc.
  //
  // @param target_function A pointer to the function that should be
  // patched.
  //
  // @param replacement_function A pointer to the function that should
  // replace the target function.  The replacement function must have
  // exactly the same calling convention and parameters as the original
  // function.
  //
  // @param preamble_stub A pointer to a buffer where the preamble stub
  // should be copied. The size of the buffer should be sufficient to
  // hold the preamble bytes.
  //
  // @param stub_size Size in bytes of the buffer allocated for the
  // preamble_stub
  //
  // @param bytes_needed Pointer to a variable that receives the minimum
  // number of bytes required for the stub.  Can be set to NULL if you're
  // not interested.
  //
  // @return An error code indicating the result of patching.
  static SideStepError RawPatchWithStub(void* target_function,
                                        void* replacement_function,
                                        unsigned char* preamble_stub,
                                        unsigned long stub_size,
                                        unsigned long* bytes_needed);


  // A helper routine when patching, which follows jmp instructions at
  // function addresses, to get to the "actual" function contents.
  // This allows us to identify two functions that are at different
  // addresses but actually resolve to the same code.
  //
  // @param target_function Pointer to a function.
  //
  // @param stop_before If, when following JMP instructions from
  // target_function, we get to the address stop, we return
  // immediately, the address that jumps to stop_before.
  //
  // @param stop_before_trampoline  When following JMP instructions from 
  // target_function, stop before a trampoline is detected.  See comment in
  // PreamblePatcher::RawPatchWithStub for more information.  This parameter 
  // has no effect in 32-bit mode.
  //
  // @return Either target_function (the input parameter), or if
  // target_function's body consists entirely of a JMP instruction,
  // the address it JMPs to (or more precisely, the address at the end
  // of a chain of JMPs).
  static void* ResolveTargetImpl(unsigned char* target_function,
                                 unsigned char* stop_before,
                                 bool stop_before_trampoline = false);

  // Helper routine that attempts to allocate a page as close (within 2GB)
  // as possible to target.
  //
  // @param target    Pointer to target function.
  //
  // @return   Returns an address that is within 2GB of target.
  static void* AllocPageNear(void* target);

  // Helper routine that determines if a target instruction is a short
  // conditional jump.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a short conditional jump.
  static bool IsShortConditionalJump(unsigned char* target,
                                     unsigned int instruction_size);

  // Helper routine that determines if a target instruction is a near
  // conditional jump.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a near conditional jump.
  static bool IsNearConditionalJump(unsigned char* target,
                                    unsigned int instruction_size);

  // Helper routine that determines if a target instruction is a near
  // relative jump.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a near absolute jump.
  static bool IsNearRelativeJump(unsigned char* target,
                                 unsigned int instruction_size);

  // Helper routine that determines if a target instruction is a near 
  // absolute call.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a near absolute call.
  static bool IsNearAbsoluteCall(unsigned char* target,
                                 unsigned int instruction_size);

  // Helper routine that determines if a target instruction is a near 
  // absolute call.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a near absolute call.
  static bool IsNearRelativeCall(unsigned char* target,
                                 unsigned int instruction_size);

  // Helper routine that determines if a target instruction is a 64-bit MOV
  // that uses a RIP-relative displacement.
  //
  // @param target            Pointer to instruction.
  //
  // @param instruction_size  Size of the instruction in bytes.
  //
  // @return  Returns true if the instruction is a MOV with displacement.
  static bool IsMovWithDisplacement(unsigned char* target,
                                    unsigned int instruction_size);

  // Helper routine that converts a short conditional jump instruction
  // to a near conditional jump in a target buffer.  Note that the target
  // buffer must be within 2GB of the source for the near jump to work.
  //
  // A short conditional jump instruction is in the format:
  // 7x xx = Jcc rel8off
  //
  // @param source              Pointer to instruction.
  //
  // @param instruction_size    Size of the instruction.
  //
  // @param target              Target buffer to write the new instruction.
  //
  // @param target_bytes        Pointer to a buffer that contains the size
  //                            of the target instruction, in bytes.
  //
  // @param target_size         Size of the target buffer.
  //
  // @return  Returns SIDESTEP_SUCCESS if successful, otherwise an error.
  static SideStepError PatchShortConditionalJump(unsigned char* source,
                                                 unsigned int instruction_size,
                                                 unsigned char* target,
                                                 unsigned int* target_bytes,
                                                 unsigned int target_size);

  // Helper routine that converts an instruction that will convert various
  // jump-like instructions to corresponding instructions in the target buffer.
  // What this routine does is fix up the relative offsets contained in jump
  // instructions to point back to the original target routine.  Like with
  // PatchShortConditionalJump, the target buffer must be within 2GB of the
  // source.
  //
  // We currently handle the following instructions:
  //
  // E9 xx xx xx xx     = JMP rel32off
  // 0F 8x xx xx xx xx  = Jcc rel32off
  // FF /2 xx xx xx xx  = CALL reg/mem32/mem64
  // E8 xx xx xx xx     = CALL rel32off
  //
  // It should not be hard to update this function to support other
  // instructions that jump to relative targets.
  //
  // @param source              Pointer to instruction.
  //
  // @param instruction_size    Size of the instruction.
  //
  // @param target              Target buffer to write the new instruction.
  //
  // @param target_bytes        Pointer to a buffer that contains the size
  //                            of the target instruction, in bytes.
  //
  // @param target_size         Size of the target buffer.
  //
  // @return  Returns SIDESTEP_SUCCESS if successful, otherwise an error.
  static SideStepError PatchNearJumpOrCall(unsigned char* source,
                                           unsigned int instruction_size,
                                           unsigned char* target,
                                           unsigned int* target_bytes,
                                           unsigned int target_size);
  
  // Helper routine that patches a 64-bit MOV instruction with a RIP-relative
  // displacement.  The target buffer must be within 2GB of the source.
  //
  // 48 8B 0D XX XX XX XX = MOV rel32off
  //
  // @param source              Pointer to instruction.
  //
  // @param instruction_size    Size of the instruction.
  //
  // @param target              Target buffer to write the new instruction.
  //
  // @param target_bytes        Pointer to a buffer that contains the size
  //                            of the target instruction, in bytes.
  //
  // @param target_size         Size of the target buffer.
  //
  // @return  Returns SIDESTEP_SUCCESS if successful, otherwise an error.
  static SideStepError PatchMovWithDisplacement(unsigned char* source,
                                                unsigned int instruction_size,
                                                unsigned char* target,
                                                unsigned int* target_bytes,
                                                unsigned int target_size);
};

};  // namespace sidestep

#endif  // GOOGLE_PERFTOOLS_PREAMBLE_PATCHER_H_
