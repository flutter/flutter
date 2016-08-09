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

// Definitions of assembly statements we need
#define ASM_JMP32REL 0xE9
#define ASM_INT3 0xCC
#define ASM_NOP 0x90
// X64 opcodes
#define ASM_MOVRAX_IMM 0xB8
#define ASM_REXW 0x48
#define ASM_JMP 0xFF
#define ASM_JMP_RAX 0xE0
#define ASM_PUSH 0x68
#define ASM_RET 0xC3

namespace sidestep {

SideStepError PreamblePatcher::RawPatchWithStub(
    void* target_function,
    void* replacement_function,
    unsigned char* preamble_stub,
    unsigned long stub_size,
    unsigned long* bytes_needed) {
  if ((NULL == target_function) ||
      (NULL == replacement_function) ||
      (NULL == preamble_stub)) {
    SIDESTEP_ASSERT(false &&
                    "Invalid parameters - either pTargetFunction or "
                    "pReplacementFunction or pPreambleStub were NULL.");
    return SIDESTEP_INVALID_PARAMETER;
  }

  // TODO(V7:joi) Siggi and I just had a discussion and decided that both
  // patching and unpatching are actually unsafe.  We also discussed a
  // method of making it safe, which is to freeze all other threads in the
  // process, check their thread context to see if their eip is currently
  // inside the block of instructions we need to copy to the stub, and if so
  // wait a bit and try again, then unfreeze all threads once we've patched.
  // Not implementing this for now since we're only using SideStep for unit
  // testing, but if we ever use it for production code this is what we
  // should do.
  //
  // NOTE: Stoyan suggests we can write 8 or even 10 bytes atomically using
  // FPU instructions, and on newer processors we could use cmpxchg8b or
  // cmpxchg16b. So it might be possible to do the patching/unpatching
  // atomically and avoid having to freeze other threads.  Note though, that
  // doing it atomically does not help if one of the other threads happens
  // to have its eip in the middle of the bytes you change while you change
  // them.
  unsigned char* target = reinterpret_cast<unsigned char*>(target_function);
  unsigned int required_trampoline_bytes = 0;
  const unsigned int kRequiredStubJumpBytes = 5;
  const unsigned int kRequiredTargetPatchBytes = 5;

  // Initialize the stub with INT3's just in case.
  if (stub_size) {
    memset(preamble_stub, 0xcc, stub_size);
  }
  if (kIs64BitBinary) {
    // In 64-bit mode JMP instructions are always relative to RIP.  If the
    // replacement - target offset is > 2GB, we can't JMP to the replacement
    // function.  In this case, we're going to use a trampoline - that is,
    // we're going to do a relative jump to a small chunk of code in the stub
    // that will then do the absolute jump to the replacement function.  By
    // doing this, we only need to patch 5 bytes in the target function, as
    // opposed to patching 12 bytes if we were to do an absolute jump.
    //
    // Note that the first byte of the trampoline is a NOP instruction.  This
    // is used as a trampoline signature that will be detected when unpatching
    // the function.
    //
    // jmp <trampoline>
    //
    // trampoline:
    //    nop
    //    mov rax, <replacement_function>
    //    jmp rax
    //
    __int64 replacement_target_offset = reinterpret_cast<__int64>(
        replacement_function) - reinterpret_cast<__int64>(target) - 5;
    if (replacement_target_offset > INT_MAX
        || replacement_target_offset < INT_MIN) {
      // The stub needs to be within 2GB of the target for the trampoline to
      // work!
      __int64 trampoline_offset = reinterpret_cast<__int64>(preamble_stub)
          - reinterpret_cast<__int64>(target) - 5;
      if (trampoline_offset > INT_MAX || trampoline_offset < INT_MIN) {
        // We're screwed.
        SIDESTEP_ASSERT(false 
                       && "Preamble stub is too far from target to patch.");
        return SIDESTEP_UNEXPECTED;
      }
      required_trampoline_bytes = 13;
    }
  }

  // Let's disassemble the preamble of the target function to see if we can
  // patch, and to see how much of the preamble we need to take.  We need 5
  // bytes for our jmp instruction, so let's find the minimum number of
  // instructions to get 5 bytes.
  MiniDisassembler disassembler;
  unsigned int preamble_bytes = 0;
  unsigned int stub_bytes = 0;
  while (preamble_bytes < kRequiredTargetPatchBytes) {
    unsigned int cur_bytes = 0;
    InstructionType instruction_type =
        disassembler.Disassemble(target + preamble_bytes, cur_bytes);
    if (IT_JUMP == instruction_type) {
      unsigned int jump_bytes = 0;
      SideStepError jump_ret = SIDESTEP_JUMP_INSTRUCTION;
      if (IsShortConditionalJump(target + preamble_bytes, cur_bytes)) {
        jump_ret = PatchShortConditionalJump(target + preamble_bytes, cur_bytes,
                                             preamble_stub + stub_bytes,
                                             &jump_bytes,
                                             stub_size - stub_bytes);
      } else if (IsNearConditionalJump(target + preamble_bytes, cur_bytes) ||
                 IsNearRelativeJump(target + preamble_bytes, cur_bytes) ||
                 IsNearAbsoluteCall(target + preamble_bytes, cur_bytes) ||
                 IsNearRelativeCall(target + preamble_bytes, cur_bytes)) {
         jump_ret = PatchNearJumpOrCall(target + preamble_bytes, cur_bytes,
                                        preamble_stub + stub_bytes, &jump_bytes,
                                        stub_size - stub_bytes);
      }
      if (jump_ret != SIDESTEP_SUCCESS) {
        SIDESTEP_ASSERT(false &&
                        "Unable to patch because there is an unhandled branch "
                        "instruction in the initial preamble bytes.");
        return SIDESTEP_JUMP_INSTRUCTION;
      }
      stub_bytes += jump_bytes;
    } else if (IT_RETURN == instruction_type) {
      SIDESTEP_ASSERT(false &&
                      "Unable to patch because function is too short");
      return SIDESTEP_FUNCTION_TOO_SMALL;
    } else if (IT_GENERIC == instruction_type) {
      if (IsMovWithDisplacement(target + preamble_bytes, cur_bytes)) {
        unsigned int mov_bytes = 0;
        if (PatchMovWithDisplacement(target + preamble_bytes, cur_bytes,
                                     preamble_stub + stub_bytes, &mov_bytes,
                                     stub_size - stub_bytes)
            != SIDESTEP_SUCCESS) {
          return SIDESTEP_UNSUPPORTED_INSTRUCTION;
        }
        stub_bytes += mov_bytes;
      } else {
        memcpy(reinterpret_cast<void*>(preamble_stub + stub_bytes),
               reinterpret_cast<void*>(target + preamble_bytes), cur_bytes);
        stub_bytes += cur_bytes;
      }
    } else {
      SIDESTEP_ASSERT(false &&
                      "Disassembler encountered unsupported instruction "
                      "(either unused or unknown");
      return SIDESTEP_UNSUPPORTED_INSTRUCTION;
    }
    preamble_bytes += cur_bytes;
  }

  if (NULL != bytes_needed)
    *bytes_needed = stub_bytes + kRequiredStubJumpBytes
        + required_trampoline_bytes;

  // Inv: cbPreamble is the number of bytes (at least 5) that we need to take
  // from the preamble to have whole instructions that are 5 bytes or more
  // in size total. The size of the stub required is cbPreamble +
  // kRequiredStubJumpBytes (5) + required_trampoline_bytes (0 or 13)
  if (stub_bytes + kRequiredStubJumpBytes + required_trampoline_bytes
      > stub_size) {
    SIDESTEP_ASSERT(false);
    return SIDESTEP_INSUFFICIENT_BUFFER;
  }

  // Now, make a jmp instruction to the rest of the target function (minus the
  // preamble bytes we moved into the stub) and copy it into our preamble-stub.
  // find address to jump to, relative to next address after jmp instruction
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4244)
#endif
  int relative_offset_to_target_rest
      = ((reinterpret_cast<unsigned char*>(target) + preamble_bytes) -
         (preamble_stub + stub_bytes + kRequiredStubJumpBytes));
#ifdef _MSC_VER
#pragma warning(pop)
#endif
  // jmp (Jump near, relative, displacement relative to next instruction)
  preamble_stub[stub_bytes] = ASM_JMP32REL;
  // copy the address
  memcpy(reinterpret_cast<void*>(preamble_stub + stub_bytes + 1),
         reinterpret_cast<void*>(&relative_offset_to_target_rest), 4);

  if (kIs64BitBinary && required_trampoline_bytes != 0) {
    // Construct the trampoline
    unsigned int trampoline_pos = stub_bytes + kRequiredStubJumpBytes;
    preamble_stub[trampoline_pos] = ASM_NOP;
    preamble_stub[trampoline_pos + 1] = ASM_REXW;
    preamble_stub[trampoline_pos + 2] = ASM_MOVRAX_IMM;
    memcpy(reinterpret_cast<void*>(preamble_stub + trampoline_pos + 3),
           reinterpret_cast<void*>(&replacement_function),
           sizeof(void *));
    preamble_stub[trampoline_pos + 11] = ASM_JMP;
    preamble_stub[trampoline_pos + 12] = ASM_JMP_RAX;

    // Now update replacement_function to point to the trampoline
    replacement_function = preamble_stub + trampoline_pos;
  }

  // Inv: preamble_stub points to assembly code that will execute the
  // original function by first executing the first cbPreamble bytes of the
  // preamble, then jumping to the rest of the function.

  // Overwrite the first 5 bytes of the target function with a jump to our
  // replacement function.
  // (Jump near, relative, displacement relative to next instruction)
  target[0] = ASM_JMP32REL;

  // Find offset from instruction after jmp, to the replacement function.
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4244)
#endif
  int offset_to_replacement_function =
      reinterpret_cast<unsigned char*>(replacement_function) -
      reinterpret_cast<unsigned char*>(target) - 5;
#ifdef _MSC_VER
#pragma warning(pop)
#endif
  // complete the jmp instruction
  memcpy(reinterpret_cast<void*>(target + 1),
         reinterpret_cast<void*>(&offset_to_replacement_function), 4);

  // Set any remaining bytes that were moved to the preamble-stub to INT3 so
  // as not to cause confusion (otherwise you might see some strange
  // instructions if you look at the disassembly, or even invalid
  // instructions). Also, by doing this, we will break into the debugger if
  // some code calls into this portion of the code.  If this happens, it
  // means that this function cannot be patched using this patcher without
  // further thought.
  if (preamble_bytes > kRequiredTargetPatchBytes) {
    memset(reinterpret_cast<void*>(target + kRequiredTargetPatchBytes),
           ASM_INT3, preamble_bytes - kRequiredTargetPatchBytes);
  }

  // Inv: The memory pointed to by target_function now points to a relative
  // jump instruction that jumps over to the preamble_stub.  The preamble
  // stub contains the first stub_size bytes of the original target
  // function's preamble code, followed by a relative jump back to the next
  // instruction after the first cbPreamble bytes.
  //
  // In 64-bit mode the memory pointed to by target_function *may* point to a
  // relative jump instruction that jumps to a trampoline which will then
  // perform an absolute jump to the replacement function.  The preamble stub
  // still contains the original target function's preamble code, followed by a
  // jump back to the instructions after the first preamble bytes.
  //
  return SIDESTEP_SUCCESS;
}

};  // namespace sidestep
