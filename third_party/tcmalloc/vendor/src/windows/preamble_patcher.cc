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
 * Implementation of PreamblePatcher
 */

#include "preamble_patcher.h"

#include "mini_disassembler.h"

// compatibility shims
#include "base/logging.h"

// Definitions of assembly statements we need
#define ASM_JMP32REL 0xE9
#define ASM_INT3 0xCC
#define ASM_JMP32ABS_0 0xFF
#define ASM_JMP32ABS_1 0x25
#define ASM_JMP8REL 0xEB
#define ASM_JCC32REL_0 0x0F
#define ASM_JCC32REL_1_MASK 0x80
#define ASM_NOP 0x90
// X64 opcodes
#define ASM_REXW 0x48
#define ASM_MOVRAX_IMM 0xB8
#define ASM_JMP 0xFF
#define ASM_JMP_RAX 0xE0

namespace sidestep {

PreamblePatcher::PreamblePage* PreamblePatcher::preamble_pages_ = NULL;
long PreamblePatcher::granularity_ = 0;
long PreamblePatcher::pagesize_ = 0;
bool PreamblePatcher::initialized_ = false;

static const unsigned int kPreamblePageMagic = 0x4347414D; // "MAGC"

// Handle a special case that we see with functions that point into an
// IAT table (including functions linked statically into the
// application): these function already starts with ASM_JMP32*.  For
// instance, malloc() might be implemented as a JMP to __malloc().
// This function follows the initial JMPs for us, until we get to the
// place where the actual code is defined.  If we get to STOP_BEFORE,
// we return the address before stop_before.  The stop_before_trampoline
// flag is used in 64-bit mode.  If true, we will return the address
// before a trampoline is detected.  Trampolines are defined as:
//
//    nop
//    mov rax, <replacement_function>
//    jmp rax
//
// See PreamblePatcher::RawPatchWithStub for more information.
void* PreamblePatcher::ResolveTargetImpl(unsigned char* target,
                                         unsigned char* stop_before,
                                         bool stop_before_trampoline) {
  if (target == NULL)
    return NULL;
  while (1) {
    unsigned char* new_target;
    if (target[0] == ASM_JMP32REL) {
      // target[1-4] holds the place the jmp goes to, but it's
      // relative to the next instruction.
      int relative_offset;   // Windows guarantees int is 4 bytes
      SIDESTEP_ASSERT(sizeof(relative_offset) == 4);
      memcpy(reinterpret_cast<void*>(&relative_offset),
             reinterpret_cast<void*>(target + 1), 4);
      new_target = target + 5 + relative_offset;
    } else if (target[0] == ASM_JMP8REL) {
      // Visual Studio 7.1 implements new[] as an 8 bit jump to new
      signed char relative_offset;
      memcpy(reinterpret_cast<void*>(&relative_offset),
             reinterpret_cast<void*>(target + 1), 1);
      new_target = target + 2 + relative_offset;
    } else if (target[0] == ASM_JMP32ABS_0 &&
               target[1] == ASM_JMP32ABS_1) {
      // Visual studio seems to sometimes do it this way instead of the
      // previous way.  Not sure what the rules are, but it was happening
      // with operator new in some binaries.
      void** new_target_v;
      if (kIs64BitBinary) {
        // In 64-bit mode JMPs are RIP-relative, not absolute
        int target_offset;
        memcpy(reinterpret_cast<void*>(&target_offset),
               reinterpret_cast<void*>(target + 2), 4);
        new_target_v = reinterpret_cast<void**>(target + target_offset + 6);
      } else {
        SIDESTEP_ASSERT(sizeof(new_target) == 4);
        memcpy(&new_target_v, reinterpret_cast<void*>(target + 2), 4);
      }
      new_target = reinterpret_cast<unsigned char*>(*new_target_v);
    } else {
      break;
    }
    if (new_target == stop_before)
      break;
    if (stop_before_trampoline && *new_target == ASM_NOP
        && new_target[1] == ASM_REXW && new_target[2] == ASM_MOVRAX_IMM)
      break;
    target = new_target;
  }
  return target;
}

// Special case scoped_ptr to avoid dependency on scoped_ptr below.
class DeleteUnsignedCharArray {
 public:
  DeleteUnsignedCharArray(unsigned char* array) : array_(array) {
  }

  ~DeleteUnsignedCharArray() {
    if (array_) {
      PreamblePatcher::FreePreambleBlock(array_);
    }
  }

  unsigned char* Release() {
    unsigned char* temp = array_;
    array_ = NULL;
    return temp;
  }

 private:
  unsigned char* array_;
};

SideStepError PreamblePatcher::RawPatchWithStubAndProtections(
    void* target_function, void *replacement_function,
    unsigned char* preamble_stub, unsigned long stub_size,
    unsigned long* bytes_needed) {
  // We need to be able to write to a process-local copy of the first
  // MAX_PREAMBLE_STUB_SIZE bytes of target_function
  DWORD old_target_function_protect = 0;
  BOOL succeeded = ::VirtualProtect(reinterpret_cast<void*>(target_function),
                                    MAX_PREAMBLE_STUB_SIZE,
                                    PAGE_EXECUTE_READWRITE,
                                    &old_target_function_protect);
  if (!succeeded) {
    SIDESTEP_ASSERT(false && "Failed to make page containing target function "
                    "copy-on-write.");
    return SIDESTEP_ACCESS_DENIED;
  }

  SideStepError error_code = RawPatchWithStub(target_function,
                                              replacement_function,
                                              preamble_stub,
                                              stub_size,
                                              bytes_needed);

  // Restore the protection of the first MAX_PREAMBLE_STUB_SIZE bytes of
  // pTargetFunction to what they were before we started goofing around.
  // We do this regardless of whether the patch succeeded or not.
  succeeded = ::VirtualProtect(reinterpret_cast<void*>(target_function),
                               MAX_PREAMBLE_STUB_SIZE,
                               old_target_function_protect,
                               &old_target_function_protect);
  if (!succeeded) {
    SIDESTEP_ASSERT(false &&
                    "Failed to restore protection to target function.");
    // We must not return an error here because the function has
    // likely actually been patched, and returning an error might
    // cause our client code not to unpatch it.  So we just keep
    // going.
  }

  if (SIDESTEP_SUCCESS != error_code) {  // Testing RawPatchWithStub, above
    SIDESTEP_ASSERT(false);
    return error_code;
  }

  // Flush the instruction cache to make sure the processor doesn't execute the
  // old version of the instructions (before our patch).
  //
  // FlushInstructionCache is actually a no-op at least on
  // single-processor XP machines.  I'm not sure why this is so, but
  // it is, yet I want to keep the call to the API here for
  // correctness in case there is a difference in some variants of
  // Windows/hardware.
  succeeded = ::FlushInstructionCache(::GetCurrentProcess(),
                                      target_function,
                                      MAX_PREAMBLE_STUB_SIZE);
  if (!succeeded) {
    SIDESTEP_ASSERT(false && "Failed to flush instruction cache.");
    // We must not return an error here because the function has actually
    // been patched, and returning an error would likely cause our client
    // code not to unpatch it.  So we just keep going.
  }

  return SIDESTEP_SUCCESS;
}

SideStepError PreamblePatcher::RawPatch(void* target_function,
                                        void* replacement_function,
                                        void** original_function_stub) {
  if (!target_function || !replacement_function || !original_function_stub ||
      (*original_function_stub) || target_function == replacement_function) {
    SIDESTEP_ASSERT(false && "Preconditions not met");
    return SIDESTEP_INVALID_PARAMETER;
  }

  BOOL succeeded = FALSE;

  // First, deal with a special case that we see with functions that
  // point into an IAT table (including functions linked statically
  // into the application): these function already starts with
  // ASM_JMP32REL.  For instance, malloc() might be implemented as a
  // JMP to __malloc().  In that case, we replace the destination of
  // the JMP (__malloc), rather than the JMP itself (malloc).  This
  // way we get the correct behavior no matter how malloc gets called.
  void* new_target = ResolveTarget(target_function);
  if (new_target != target_function) {
    target_function = new_target;
  }

  // In 64-bit mode, preamble_stub must be within 2GB of target function
  // so that if target contains a jump, we can translate it.
  unsigned char* preamble_stub = AllocPreambleBlockNear(target_function);
  if (!preamble_stub) {
    SIDESTEP_ASSERT(false && "Unable to allocate preamble-stub.");
    return SIDESTEP_INSUFFICIENT_BUFFER;
  }

  // Frees the array at end of scope.
  DeleteUnsignedCharArray guard_preamble_stub(preamble_stub);

  SideStepError error_code = RawPatchWithStubAndProtections(
      target_function, replacement_function, preamble_stub,
      MAX_PREAMBLE_STUB_SIZE, NULL);

  if (SIDESTEP_SUCCESS != error_code) {
    SIDESTEP_ASSERT(false);
    return error_code;
  }

  // Flush the instruction cache to make sure the processor doesn't execute the
  // old version of the instructions (before our patch).
  //
  // FlushInstructionCache is actually a no-op at least on
  // single-processor XP machines.  I'm not sure why this is so, but
  // it is, yet I want to keep the call to the API here for
  // correctness in case there is a difference in some variants of
  // Windows/hardware.
  succeeded = ::FlushInstructionCache(::GetCurrentProcess(),
                                      target_function,
                                      MAX_PREAMBLE_STUB_SIZE);
  if (!succeeded) {
    SIDESTEP_ASSERT(false && "Failed to flush instruction cache.");
    // We must not return an error here because the function has actually
    // been patched, and returning an error would likely cause our client
    // code not to unpatch it.  So we just keep going.
  }

  SIDESTEP_LOG("PreamblePatcher::RawPatch successfully patched.");

  // detach the scoped pointer so the memory is not freed
  *original_function_stub =
      reinterpret_cast<void*>(guard_preamble_stub.Release());
  return SIDESTEP_SUCCESS;
}

SideStepError PreamblePatcher::Unpatch(void* target_function,
                                       void* replacement_function,
                                       void* original_function_stub) {
  SIDESTEP_ASSERT(target_function && replacement_function &&
                  original_function_stub);
  if (!target_function || !replacement_function ||
      !original_function_stub) {
    return SIDESTEP_INVALID_PARAMETER;
  }

  // Before unpatching, target_function should be a JMP to
  // replacement_function.  If it's not, then either it's an error, or
  // we're falling into the case where the original instruction was a
  // JMP, and we patched the jumped_to address rather than the JMP
  // itself.  (For instance, if malloc() is just a JMP to __malloc(),
  // we patched __malloc() and not malloc().)
  unsigned char* target = reinterpret_cast<unsigned char*>(target_function);
  target = reinterpret_cast<unsigned char*>(
      ResolveTargetImpl(
          target, reinterpret_cast<unsigned char*>(replacement_function),
          true));
  // We should end at the function we patched.  When we patch, we insert
  // a ASM_JMP32REL instruction, so look for that as a sanity check.
  if (target[0] != ASM_JMP32REL) {
    SIDESTEP_ASSERT(false &&
                    "target_function does not look like it was patched.");
    return SIDESTEP_INVALID_PARAMETER;
  }

  const unsigned int kRequiredTargetPatchBytes = 5;

  // We need to be able to write to a process-local copy of the first
  // kRequiredTargetPatchBytes bytes of target_function
  DWORD old_target_function_protect = 0;
  BOOL succeeded = ::VirtualProtect(reinterpret_cast<void*>(target),
                                    kRequiredTargetPatchBytes,
                                    PAGE_EXECUTE_READWRITE,
                                    &old_target_function_protect);
  if (!succeeded) {
    SIDESTEP_ASSERT(false && "Failed to make page containing target function "
                    "copy-on-write.");
    return SIDESTEP_ACCESS_DENIED;
  }

  unsigned char* preamble_stub = reinterpret_cast<unsigned char*>(
                                   original_function_stub);

  // Disassemble the preamble of stub and copy the bytes back to target.
  // If we've done any conditional jumps in the preamble we need to convert
  // them back to the orignal REL8 jumps in the target.
  MiniDisassembler disassembler;
  unsigned int preamble_bytes = 0;
  unsigned int target_bytes = 0;
  while (target_bytes < kRequiredTargetPatchBytes) {
    unsigned int cur_bytes = 0;
    InstructionType instruction_type =
        disassembler.Disassemble(preamble_stub + preamble_bytes, cur_bytes);
    if (IT_JUMP == instruction_type) {
      unsigned int jump_bytes = 0;
      SideStepError jump_ret = SIDESTEP_JUMP_INSTRUCTION;
      if (IsNearConditionalJump(preamble_stub + preamble_bytes, cur_bytes) ||
          IsNearRelativeJump(preamble_stub + preamble_bytes, cur_bytes) ||
          IsNearAbsoluteCall(preamble_stub + preamble_bytes, cur_bytes) ||
          IsNearRelativeCall(preamble_stub + preamble_bytes, cur_bytes)) {
        jump_ret = PatchNearJumpOrCall(preamble_stub + preamble_bytes, 
                                       cur_bytes, target + target_bytes, 
                                       &jump_bytes, MAX_PREAMBLE_STUB_SIZE);
      }
      if (jump_ret == SIDESTEP_JUMP_INSTRUCTION) {
        SIDESTEP_ASSERT(false &&
                        "Found unsupported jump instruction in stub!!");
        return SIDESTEP_UNSUPPORTED_INSTRUCTION;
      }
      target_bytes += jump_bytes;
    } else if (IT_GENERIC == instruction_type) {
      if (IsMovWithDisplacement(preamble_stub + preamble_bytes, cur_bytes)) {
        unsigned int mov_bytes = 0;
        if (PatchMovWithDisplacement(preamble_stub + preamble_bytes, cur_bytes,
                                     target + target_bytes, &mov_bytes,
                                     MAX_PREAMBLE_STUB_SIZE)
                                     != SIDESTEP_SUCCESS) {
          SIDESTEP_ASSERT(false &&
                          "Found unsupported generic instruction in stub!!");
          return SIDESTEP_UNSUPPORTED_INSTRUCTION;
        }
      } else {
        memcpy(reinterpret_cast<void*>(target + target_bytes),
               reinterpret_cast<void*>(reinterpret_cast<unsigned char*>(
                   original_function_stub) + preamble_bytes), cur_bytes);
        target_bytes += cur_bytes;
      }
    } else {
      SIDESTEP_ASSERT(false &&
                      "Found unsupported instruction in stub!!");
      return SIDESTEP_UNSUPPORTED_INSTRUCTION;
    }
    preamble_bytes += cur_bytes;
  }

  FreePreambleBlock(reinterpret_cast<unsigned char*>(original_function_stub));

  // Restore the protection of the first kRequiredTargetPatchBytes bytes of
  // target to what they were before we started goofing around.
  succeeded = ::VirtualProtect(reinterpret_cast<void*>(target),
                               kRequiredTargetPatchBytes,
                               old_target_function_protect,
                               &old_target_function_protect);

  // Flush the instruction cache to make sure the processor doesn't execute the
  // old version of the instructions (before our patch).
  //
  // See comment on FlushInstructionCache elsewhere in this file.
  succeeded = ::FlushInstructionCache(::GetCurrentProcess(),
                                      target,
                                      MAX_PREAMBLE_STUB_SIZE);
  if (!succeeded) {
    SIDESTEP_ASSERT(false && "Failed to flush instruction cache.");
    return SIDESTEP_UNEXPECTED;
  }

  SIDESTEP_LOG("PreamblePatcher::Unpatch successfully unpatched.");
  return SIDESTEP_SUCCESS;
}

void PreamblePatcher::Initialize() {
  if (!initialized_) {
    SYSTEM_INFO si = { 0 };
    ::GetSystemInfo(&si);
    granularity_ = si.dwAllocationGranularity;
    pagesize_ = si.dwPageSize;
    initialized_ = true;
  }
}

unsigned char* PreamblePatcher::AllocPreambleBlockNear(void* target) {
  PreamblePage* preamble_page = preamble_pages_;
  while (preamble_page != NULL) {
    if (preamble_page->free_ != NULL) {
      __int64 val = reinterpret_cast<__int64>(preamble_page) -
          reinterpret_cast<__int64>(target);
      if ((val > 0 && val + pagesize_ <= INT_MAX) ||
          (val < 0 && val >= INT_MIN)) {
        break;
      }
    }
    preamble_page = preamble_page->next_;
  }

  // The free_ member of the page is used to store the next available block
  // of memory to use or NULL if there are no chunks available, in which case
  // we'll allocate a new page.
  if (preamble_page == NULL || preamble_page->free_ == NULL) {
    // Create a new preamble page and initialize the free list
    preamble_page = reinterpret_cast<PreamblePage*>(AllocPageNear(target));
    SIDESTEP_ASSERT(preamble_page != NULL && "Could not allocate page!");
    void** pp = &preamble_page->free_;
    unsigned char* ptr = reinterpret_cast<unsigned char*>(preamble_page) +
        MAX_PREAMBLE_STUB_SIZE;
    unsigned char* limit = reinterpret_cast<unsigned char*>(preamble_page) +
        pagesize_;
    while (ptr < limit) {
      *pp = ptr;
      pp = reinterpret_cast<void**>(ptr);
      ptr += MAX_PREAMBLE_STUB_SIZE;
    }
    *pp = NULL;
    // Insert the new page into the list
    preamble_page->magic_ = kPreamblePageMagic;
    preamble_page->next_ = preamble_pages_;
    preamble_pages_ = preamble_page;
  }
  unsigned char* ret = reinterpret_cast<unsigned char*>(preamble_page->free_);
  preamble_page->free_ = *(reinterpret_cast<void**>(preamble_page->free_));
  return ret;
}

void PreamblePatcher::FreePreambleBlock(unsigned char* block) {
  SIDESTEP_ASSERT(block != NULL);
  SIDESTEP_ASSERT(granularity_ != 0);
  uintptr_t ptr = reinterpret_cast<uintptr_t>(block);
  ptr -= ptr & (granularity_ - 1);
  PreamblePage* preamble_page = reinterpret_cast<PreamblePage*>(ptr);
  SIDESTEP_ASSERT(preamble_page->magic_ == kPreamblePageMagic);
  *(reinterpret_cast<void**>(block)) = preamble_page->free_;
  preamble_page->free_ = block;
}

void* PreamblePatcher::AllocPageNear(void* target) {
  MEMORY_BASIC_INFORMATION mbi = { 0 };
  if (!::VirtualQuery(target, &mbi, sizeof(mbi))) {
    SIDESTEP_ASSERT(false && "VirtualQuery failed on target address");
    return 0;
  }
  if (initialized_ == false) {
    PreamblePatcher::Initialize();
    SIDESTEP_ASSERT(initialized_);
  }
  void* pv = NULL;
  unsigned char* allocation_base = reinterpret_cast<unsigned char*>(
      mbi.AllocationBase);
  __int64 i = 1;
  bool high_target = reinterpret_cast<__int64>(target) > UINT_MAX;
  while (pv == NULL) {
    __int64 val = reinterpret_cast<__int64>(allocation_base) -
        (i * granularity_);
    if (high_target &&
        reinterpret_cast<__int64>(target) - val > INT_MAX) {
        // We're further than 2GB from the target
      break;
    } else if (val <= NULL) {
      // Less than 0
      break;
    }
    pv = ::VirtualAlloc(reinterpret_cast<void*>(allocation_base -
                            (i++ * granularity_)),
                        pagesize_, MEM_COMMIT | MEM_RESERVE,
                        PAGE_EXECUTE_READWRITE);
  }

  // We couldn't allocate low, try to allocate high
  if (pv == NULL) {
    i = 1;
    // Round up to the next multiple of page granularity
    allocation_base = reinterpret_cast<unsigned char*>(
        (reinterpret_cast<__int64>(target) &
        (~(granularity_ - 1))) + granularity_);
    while (pv == NULL) {
      __int64 val = reinterpret_cast<__int64>(allocation_base) +
          (i * granularity_) - reinterpret_cast<__int64>(target);
      if (val > INT_MAX || val < 0) {
        // We're too far or we overflowed
        break;
      }
      pv = ::VirtualAlloc(reinterpret_cast<void*>(allocation_base +
                              (i++ * granularity_)),
                          pagesize_, MEM_COMMIT | MEM_RESERVE,
                          PAGE_EXECUTE_READWRITE);
    }
  }
  return pv;
}

bool PreamblePatcher::IsShortConditionalJump(
    unsigned char* target,
    unsigned int instruction_size) {
  return (*(target) & 0x70) == 0x70 && instruction_size == 2;
}

bool PreamblePatcher::IsNearConditionalJump(
    unsigned char* target,
    unsigned int instruction_size) {
  return *(target) == 0xf && (*(target + 1) & 0x80) == 0x80 &&
      instruction_size == 6;
}

bool PreamblePatcher::IsNearRelativeJump(
    unsigned char* target,
    unsigned int instruction_size) {
  return *(target) == 0xe9 && instruction_size == 5;
}

bool PreamblePatcher::IsNearAbsoluteCall(
    unsigned char* target,
    unsigned int instruction_size) {
  return *(target) == 0xff && (*(target + 1) & 0x10) == 0x10 &&
      instruction_size == 6;
}

bool PreamblePatcher::IsNearRelativeCall(
    unsigned char* target,
    unsigned int instruction_size) {
  return *(target) == 0xe8 && instruction_size == 5;
}

bool PreamblePatcher::IsMovWithDisplacement(
    unsigned char* target,
    unsigned int instruction_size) {
  // In this case, the ModRM byte's mod field will be 0 and r/m will be 101b (5)
  return instruction_size == 7 && *target == 0x48 && *(target + 1) == 0x8b &&
      (*(target + 2) >> 6) == 0 && (*(target + 2) & 0x7) == 5;
}

SideStepError PreamblePatcher::PatchShortConditionalJump(
    unsigned char* source,
    unsigned int instruction_size,
    unsigned char* target,
    unsigned int* target_bytes,
    unsigned int target_size) {
  unsigned char* original_jump_dest = (source + 2) + source[1];
  unsigned char* stub_jump_from = target + 6;
  __int64 fixup_jump_offset = original_jump_dest - stub_jump_from;
  if (fixup_jump_offset > INT_MAX || fixup_jump_offset < INT_MIN) {
    SIDESTEP_ASSERT(false &&
                    "Unable to fix up short jump because target"
                    " is too far away.");
    return SIDESTEP_JUMP_INSTRUCTION;
  }

  *target_bytes = 6;
  if (target_size > *target_bytes) {
    // Convert the short jump to a near jump.
    //
    // 0f 8x xx xx xx xx = Jcc rel32off
    unsigned short jmpcode = ((0x80 | (source[0] & 0xf)) << 8) | 0x0f;
    memcpy(reinterpret_cast<void*>(target),
           reinterpret_cast<void*>(&jmpcode), 2);
    memcpy(reinterpret_cast<void*>(target + 2),
           reinterpret_cast<void*>(&fixup_jump_offset), 4);
  }

  return SIDESTEP_SUCCESS;
}

SideStepError PreamblePatcher::PatchNearJumpOrCall(
    unsigned char* source,
    unsigned int instruction_size,
    unsigned char* target,
    unsigned int* target_bytes,
    unsigned int target_size) {
  SIDESTEP_ASSERT(instruction_size == 5 || instruction_size == 6);
  unsigned int jmp_offset_in_instruction = instruction_size == 5 ? 1 : 2;
  unsigned char* original_jump_dest = reinterpret_cast<unsigned char *>(
      reinterpret_cast<__int64>(source + instruction_size) +
      *(reinterpret_cast<int*>(source + jmp_offset_in_instruction)));
  unsigned char* stub_jump_from = target + instruction_size;
  __int64 fixup_jump_offset = original_jump_dest - stub_jump_from;
  if (fixup_jump_offset > INT_MAX || fixup_jump_offset < INT_MIN) {
    SIDESTEP_ASSERT(false &&
                    "Unable to fix up near jump because target"
                    " is too far away.");
    return SIDESTEP_JUMP_INSTRUCTION;
  }

  if ((fixup_jump_offset < SCHAR_MAX && fixup_jump_offset > SCHAR_MIN)) {
    *target_bytes = 2;
    if (target_size > *target_bytes) {
      // If the new offset is in range, use a short jump instead of a near jump.
      if (source[0] == ASM_JCC32REL_0 &&
          (source[1] & ASM_JCC32REL_1_MASK) == ASM_JCC32REL_1_MASK) {
        unsigned short jmpcode = (static_cast<unsigned char>(
            fixup_jump_offset) << 8) | (0x70 | (source[1] & 0xf));
        memcpy(reinterpret_cast<void*>(target),
               reinterpret_cast<void*>(&jmpcode),
               2);
      } else {
        target[0] = ASM_JMP8REL;
        target[1] = static_cast<unsigned char>(fixup_jump_offset);
      }
    }
  } else {
    *target_bytes = instruction_size;
    if (target_size > *target_bytes) {
      memcpy(reinterpret_cast<void*>(target),
             reinterpret_cast<void*>(source),
             jmp_offset_in_instruction);
      memcpy(reinterpret_cast<void*>(target + jmp_offset_in_instruction),
             reinterpret_cast<void*>(&fixup_jump_offset),
             4);
    }
  }

  return SIDESTEP_SUCCESS;
}

SideStepError PreamblePatcher::PatchMovWithDisplacement(
     unsigned char* source,
     unsigned int instruction_size,
     unsigned char* target,
     unsigned int* target_bytes,
     unsigned int target_size) {
  SIDESTEP_ASSERT(instruction_size == 7);
  const int mov_offset_in_instruction = 3; // 0x48 0x8b 0x0d <offset>
  unsigned char* original_mov_dest = reinterpret_cast<unsigned char*>(
      reinterpret_cast<__int64>(source + instruction_size) +
      *(reinterpret_cast<int*>(source + mov_offset_in_instruction)));
  unsigned char* stub_mov_from = target + instruction_size;
  __int64 fixup_mov_offset = original_mov_dest - stub_mov_from;
  if (fixup_mov_offset > INT_MAX || fixup_mov_offset < INT_MIN) {
    SIDESTEP_ASSERT(false &&
        "Unable to fix up near MOV because target is too far away.");
    return SIDESTEP_UNEXPECTED;
  }
  *target_bytes = instruction_size;
  if (target_size > *target_bytes) {
    memcpy(reinterpret_cast<void*>(target),
           reinterpret_cast<void*>(source),
           mov_offset_in_instruction);
    memcpy(reinterpret_cast<void*>(target + mov_offset_in_instruction),
           reinterpret_cast<void*>(&fixup_mov_offset),
           4);
  }
  return SIDESTEP_SUCCESS;
}

};  // namespace sidestep
