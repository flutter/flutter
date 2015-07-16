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
 *
 * Definition of MiniDisassembler.
 */

#ifndef GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_H_
#define GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_H_

#include "config.h"
#include <windows.h>
#include "mini_disassembler_types.h"

// compatibility shim
#include "base/logging.h"
#define SIDESTEP_ASSERT(cond)  RAW_DCHECK(cond, #cond)
#define SIDESTEP_LOG(msg)      RAW_VLOG(1, msg)

namespace sidestep {

// This small disassembler is very limited
// in its functionality, and in fact does only the bare minimum required by the
// preamble patching utility.  It may be useful for other purposes, however.
//
// The limitations include at least the following:
//  -# No support for coprocessor opcodes, MMX, etc.
//  -# No machine-readable identification of opcodes or decoding of
//     assembly parameters. The name of the opcode (as a string) is given,
//     however, to aid debugging.
//
// You may ask what this little disassembler actually does, then?  The answer is
// that it does the following, which is exactly what the patching utility needs:
//  -# Indicates if opcode is a jump (any kind) or a return (any kind)
//     because this is important for the patching utility to determine if
//     a function is too short or there are jumps too early in it for it
//     to be preamble patched.
//  -# The opcode length is always calculated, so that the patching utility
//     can figure out where the next instruction starts, and whether it
//     already has enough instructions to replace with the absolute jump
//     to the patching code.
//
// The usage is quite simple; just create a MiniDisassembler and use its
// Disassemble() method.
//
// If you would like to extend this disassembler, please refer to the
// IA-32 Intel® Architecture Software Developer's Manual Volume 2:
// Instruction Set Reference for information about operand decoding
// etc.
class PERFTOOLS_DLL_DECL MiniDisassembler {
 public:

  // Creates a new instance and sets defaults.
  //
  // @param operand_default_32_bits If true, the default operand size is
  // set to 32 bits, which is the default under Win32. Otherwise it is 16 bits.
  // @param address_default_32_bits If true, the default address size is
  // set to 32 bits, which is the default under Win32. Otherwise it is 16 bits.
  MiniDisassembler(bool operand_default_32_bits,
                   bool address_default_32_bits);

  // Equivalent to MiniDisassembler(true, true);
  MiniDisassembler();

  // Attempts to disassemble a single instruction starting from the
  // address in memory it is pointed to.
  //
  // @param start Address where disassembly should start.
  // @param instruction_bytes Variable that will be <b>incremented</b> by
  // the length in bytes of the instruction.
  // @return enItJump, enItReturn or enItGeneric on success.  enItUnknown
  // if unable to disassemble, enItUnused if this seems to be an unused
  // opcode. In the last two (error) cases, cbInstruction will be set
  // to 0xffffffff.
  //
  // @post This instance of the disassembler is ready to be used again,
  // with unchanged defaults from creation time.
  InstructionType Disassemble(unsigned char* start, unsigned int& instruction_bytes);

 private:

  // Makes the disassembler ready for reuse.
  void Initialize();

  // Sets the flags for address and operand sizes.
  // @return Number of prefix bytes.
  InstructionType ProcessPrefixes(unsigned char* start, unsigned int& size);

  // Sets the flag for whether we have ModR/M, and increments
  // operand_bytes_ if any are specifies by the opcode directly.
  // @return Number of opcode bytes.
  InstructionType ProcessOpcode(unsigned char* start,
                                unsigned int table,
                                unsigned int& size);

  // Checks the type of the supplied operand.  Increments
  // operand_bytes_ if it directly indicates an immediate etc.
  // operand.  Asserts have_modrm_ if the operand specifies
  // a ModR/M byte.
  bool ProcessOperand(int flag_operand);

  // Increments operand_bytes_ by size specified by ModR/M and
  // by SIB if present.
  // @return 0 in case of error, 1 if there is just a ModR/M byte,
  // 2 if there is a ModR/M byte and a SIB byte.
  bool ProcessModrm(unsigned char* start, unsigned int& size);

  // Processes the SIB byte that it is pointed to.
  // @param start Pointer to the SIB byte.
  // @param mod The mod field from the ModR/M byte.
  // @return 1 to indicate success (indicates 1 SIB byte)
  bool ProcessSib(unsigned char* start, unsigned char mod, unsigned int& size);

  // The instruction type we have decoded from the opcode.
  InstructionType instruction_type_;

  // Counts the number of bytes that is occupied by operands in
  // the current instruction (note: we don't care about how large
  // operands stored in registers etc. are).
  unsigned int operand_bytes_;

  // True iff there is a ModR/M byte in this instruction.
  bool have_modrm_;

  // True iff we need to decode the ModR/M byte (sometimes it just
  // points to a register, we can tell by the addressing mode).
  bool should_decode_modrm_;

  // Current operand size is 32 bits if true, 16 bits if false.
  bool operand_is_32_bits_;

  // Default operand size is 32 bits if true, 16 bits if false.
  bool operand_default_is_32_bits_;

  // Current address size is 32 bits if true, 16 bits if false.
  bool address_is_32_bits_;

  // Default address size is 32 bits if true, 16 bits if false.
  bool address_default_is_32_bits_;

  // Determines if 64 bit operands are supported (x64).
  bool operand_default_support_64_bits_;

  // Current operand size is 64 bits if true, 32 bits if false.
  bool operand_is_64_bits_;

  // Huge big opcode table based on the IA-32 manual, defined
  // in Ia32OpcodeMap.cc
  static const OpcodeTable s_ia32_opcode_map_[];

  // Somewhat smaller table to help with decoding ModR/M bytes
  // when 16-bit addressing mode is being used.  Defined in
  // Ia32ModrmMap.cc
  static const ModrmEntry s_ia16_modrm_map_[];

  // Somewhat smaller table to help with decoding ModR/M bytes
  // when 32-bit addressing mode is being used.  Defined in
  // Ia32ModrmMap.cc
  static const ModrmEntry s_ia32_modrm_map_[];

  // Indicators of whether we got certain prefixes that certain
  // silly Intel instructions depend on in nonstandard ways for
  // their behaviors.
  bool got_f2_prefix_, got_f3_prefix_, got_66_prefix_;
};

};  // namespace sidestep

#endif  // GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_H_
