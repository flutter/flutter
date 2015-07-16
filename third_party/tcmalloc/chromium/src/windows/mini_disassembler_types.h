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
 * Several simple types used by the disassembler and some of the patching
 * mechanisms.
 */

#ifndef GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_TYPES_H_
#define GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_TYPES_H_

namespace sidestep {

// Categories of instructions that we care about
enum InstructionType {
  // This opcode is not used
  IT_UNUSED,
  // This disassembler does not recognize this opcode (error)
  IT_UNKNOWN,
  // This is not an instruction but a reference to another table
  IT_REFERENCE,
  // This byte is a prefix byte that we can ignore
  IT_PREFIX,
  // This is a prefix byte that switches to the nondefault address size
  IT_PREFIX_ADDRESS,
  // This is a prefix byte that switches to the nondefault operand size
  IT_PREFIX_OPERAND,
  // A jump or call instruction
  IT_JUMP,
  // A return instruction
  IT_RETURN,
  // Any other type of instruction (in this case we don't care what it is)
  IT_GENERIC,
};

// Lists IA-32 operand sizes in multiples of 8 bits
enum OperandSize {
  OS_ZERO = 0,
  OS_BYTE = 1,
  OS_WORD = 2,
  OS_DOUBLE_WORD = 4,
  OS_QUAD_WORD = 8,
  OS_DOUBLE_QUAD_WORD = 16,
  OS_32_BIT_POINTER = 32/8,
  OS_48_BIT_POINTER = 48/8,
  OS_SINGLE_PRECISION_FLOATING = 32/8,
  OS_DOUBLE_PRECISION_FLOATING = 64/8,
  OS_DOUBLE_EXTENDED_PRECISION_FLOATING = 80/8,
  OS_128_BIT_PACKED_SINGLE_PRECISION_FLOATING = 128/8,
  OS_PSEUDO_DESCRIPTOR = 6
};

// Operand addressing methods from the IA-32 manual.  The enAmMask value
// is a mask for the rest.  The other enumeration values are named for the
// names given to the addressing methods in the manual, e.g. enAm_D is for
// the D addressing method.
//
// The reason we use a full 4 bytes and a mask, is that we need to combine
// these flags with the enOperandType to store the details
// on the operand in a single integer.
enum AddressingMethod {
  AM_NOT_USED = 0,        // This operand is not used for this instruction
  AM_MASK = 0x00FF0000,  // Mask for the rest of the values in this enumeration
  AM_A = 0x00010000,    // A addressing type
  AM_C = 0x00020000,    // C addressing type
  AM_D = 0x00030000,    // D addressing type
  AM_E = 0x00040000,    // E addressing type
  AM_F = 0x00050000,    // F addressing type
  AM_G = 0x00060000,    // G addressing type
  AM_I = 0x00070000,    // I addressing type
  AM_J = 0x00080000,    // J addressing type
  AM_M = 0x00090000,    // M addressing type
  AM_O = 0x000A0000,    // O addressing type
  AM_P = 0x000B0000,    // P addressing type
  AM_Q = 0x000C0000,    // Q addressing type
  AM_R = 0x000D0000,    // R addressing type
  AM_S = 0x000E0000,    // S addressing type
  AM_T = 0x000F0000,    // T addressing type
  AM_V = 0x00100000,    // V addressing type
  AM_W = 0x00110000,    // W addressing type
  AM_X = 0x00120000,    // X addressing type
  AM_Y = 0x00130000,    // Y addressing type
  AM_REGISTER = 0x00140000,  // Specific register is always used as this op
  AM_IMPLICIT = 0x00150000,  // An implicit, fixed value is used
};

// Operand types from the IA-32 manual. The enOtMask value is
// a mask for the rest. The rest of the values are named for the
// names given to these operand types in the manual, e.g. enOt_ps
// is for the ps operand type in the manual.
//
// The reason we use a full 4 bytes and a mask, is that we need
// to combine these flags with the enAddressingMethod to store the details
// on the operand in a single integer.
enum OperandType {
  OT_MASK = 0xFF000000,
  OT_A = 0x01000000,
  OT_B = 0x02000000,
  OT_C = 0x03000000,
  OT_D = 0x04000000,
  OT_DQ = 0x05000000,
  OT_P = 0x06000000,
  OT_PI = 0x07000000,
  OT_PS = 0x08000000,  // actually unsupported for (we don't know its size)
  OT_Q = 0x09000000,
  OT_S = 0x0A000000,
  OT_SS = 0x0B000000,
  OT_SI = 0x0C000000,
  OT_V = 0x0D000000,
  OT_W = 0x0E000000,
  OT_SD = 0x0F000000,  // scalar double-precision floating-point value
  OT_PD = 0x10000000,  // double-precision floating point
  // dummy "operand type" for address mode M - which doesn't specify
  // operand type
  OT_ADDRESS_MODE_M = 0x80000000
};

// Flag that indicates if an immediate operand is 64-bits.
//
// The Intel 64 and IA-32 Architecture Software Developer's Manual currently
// defines MOV as the only instruction supporting a 64-bit immediate operand.
enum ImmediateOperandSize {
  IOS_MASK = 0x0000F000,
  IOS_DEFAULT = 0x0,
  IOS_64 = 0x00001000
};

// Everything that's in an Opcode (see below) except the three
// alternative opcode structs for different prefixes.
struct SpecificOpcode {
  // Index to continuation table, or 0 if this is the last
  // byte in the opcode.
  int table_index_;

  // The opcode type
  InstructionType type_;

  // Description of the type of the dest, src and aux operands,
  // put together from enOperandType, enAddressingMethod and 
  // enImmediateOperandSize flags.
  int flag_dest_;
  int flag_source_;
  int flag_aux_;

  // We indicate the mnemonic for debugging purposes
  const char* mnemonic_;
};

// The information we keep in our tables about each of the different
// valid instructions recognized by the IA-32 architecture.
struct Opcode {
  // Index to continuation table, or 0 if this is the last
  // byte in the opcode.
  int table_index_;

  // The opcode type
  InstructionType type_;

  // Description of the type of the dest, src and aux operands,
  // put together from an enOperandType flag and an enAddressingMethod
  // flag.
  int flag_dest_;
  int flag_source_;
  int flag_aux_;

  // We indicate the mnemonic for debugging purposes
  const char* mnemonic_;

  // Alternative opcode info if certain prefixes are specified.
  // In most cases, all of these are zeroed-out.  Only used if
  // bPrefixDependent is true.
  bool is_prefix_dependent_;
  SpecificOpcode opcode_if_f2_prefix_;
  SpecificOpcode opcode_if_f3_prefix_;
  SpecificOpcode opcode_if_66_prefix_;
};

// Information about each table entry.
struct OpcodeTable {
  // Table of instruction entries
  const Opcode* table_;
  // How many bytes left to shift ModR/M byte <b>before</b> applying mask
  unsigned char shift_;
  // Mask to apply to byte being looked at before comparing to table
  unsigned char mask_;
  // Minimum/maximum indexes in table.
  unsigned char min_lim_;
  unsigned char max_lim_;
};

// Information about each entry in table used to decode ModR/M byte.
struct ModrmEntry {
  // Is the operand encoded as bytes in the instruction (rather than
  // if it's e.g. a register in which case it's just encoded in the
  // ModR/M byte)
  bool is_encoded_in_instruction_;

  // Is there a SIB byte?  In this case we always need to decode it.
  bool use_sib_byte_;

  // What is the size of the operand (only important if it's encoded
  // in the instruction)?
  OperandSize operand_size_;
};

};  // namespace sidestep

#endif  // GOOGLE_PERFTOOLS_MINI_DISASSEMBLER_TYPES_H_
