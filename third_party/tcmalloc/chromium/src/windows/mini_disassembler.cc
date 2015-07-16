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
 * Implementation of MiniDisassembler.
 */

#include "mini_disassembler.h"

namespace sidestep {

MiniDisassembler::MiniDisassembler(bool operand_default_is_32_bits,
                                   bool address_default_is_32_bits)
    : operand_default_is_32_bits_(operand_default_is_32_bits),
      address_default_is_32_bits_(address_default_is_32_bits) {
  Initialize();
}

MiniDisassembler::MiniDisassembler()
    : operand_default_is_32_bits_(true),
      address_default_is_32_bits_(true) {
  Initialize();
}

InstructionType MiniDisassembler::Disassemble(
    unsigned char* start_byte,
    unsigned int& instruction_bytes) {
  // Clean up any state from previous invocations.
  Initialize();

  // Start by processing any prefixes.
  unsigned char* current_byte = start_byte;
  unsigned int size = 0;
  InstructionType instruction_type = ProcessPrefixes(current_byte, size);

  if (IT_UNKNOWN == instruction_type)
    return instruction_type;

  current_byte += size;
  size = 0;

  // Invariant: We have stripped all prefixes, and the operand_is_32_bits_
  // and address_is_32_bits_ flags are correctly set.

  instruction_type = ProcessOpcode(current_byte, 0, size);

  // Check for error processing instruction
  if ((IT_UNKNOWN == instruction_type_) || (IT_UNUSED == instruction_type_)) {
    return IT_UNKNOWN;
  }

  current_byte += size;

  // Invariant: operand_bytes_ indicates the total size of operands
  // specified by the opcode and/or ModR/M byte and/or SIB byte.
  // pCurrentByte points to the first byte after the ModR/M byte, or after
  // the SIB byte if it is present (i.e. the first byte of any operands
  // encoded in the instruction).

  // We get the total length of any prefixes, the opcode, and the ModR/M and
  // SIB bytes if present, by taking the difference of the original starting
  // address and the current byte (which points to the first byte of the
  // operands if present, or to the first byte of the next instruction if
  // they are not).  Adding the count of bytes in the operands encoded in
  // the instruction gives us the full length of the instruction in bytes.
  instruction_bytes += operand_bytes_ + (current_byte - start_byte);

  // Return the instruction type, which was set by ProcessOpcode().
  return instruction_type_;
}

void MiniDisassembler::Initialize() {
  operand_is_32_bits_ = operand_default_is_32_bits_;
  address_is_32_bits_ = address_default_is_32_bits_;
#ifdef _M_X64
  operand_default_support_64_bits_ = true;
#else
  operand_default_support_64_bits_ = false;
#endif
  operand_is_64_bits_ = false;
  operand_bytes_ = 0;
  have_modrm_ = false;
  should_decode_modrm_ = false;
  instruction_type_ = IT_UNKNOWN;
  got_f2_prefix_ = false;
  got_f3_prefix_ = false;
  got_66_prefix_ = false;
}

InstructionType MiniDisassembler::ProcessPrefixes(unsigned char* start_byte,
                                                  unsigned int& size) {
  InstructionType instruction_type = IT_GENERIC;
  const Opcode& opcode = s_ia32_opcode_map_[0].table_[*start_byte];

  switch (opcode.type_) {
    case IT_PREFIX_ADDRESS:
      address_is_32_bits_ = !address_default_is_32_bits_;
      goto nochangeoperand;
    case IT_PREFIX_OPERAND:
      operand_is_32_bits_ = !operand_default_is_32_bits_;
      nochangeoperand:
    case IT_PREFIX:

      if (0xF2 == (*start_byte))
        got_f2_prefix_ = true;
      else if (0xF3 == (*start_byte))
        got_f3_prefix_ = true;
      else if (0x66 == (*start_byte))
        got_66_prefix_ = true;
      else if (operand_default_support_64_bits_ && (*start_byte) & 0x48)
        operand_is_64_bits_ = true;

      instruction_type = opcode.type_;
      size ++;
      // we got a prefix, so add one and check next byte
      ProcessPrefixes(start_byte + 1, size);
    default:
      break;   // not a prefix byte
  }

  return instruction_type;
}

InstructionType MiniDisassembler::ProcessOpcode(unsigned char* start_byte,
                                                unsigned int table_index,
                                                unsigned int& size) {
  const OpcodeTable& table = s_ia32_opcode_map_[table_index];   // Get our table
  unsigned char current_byte = (*start_byte) >> table.shift_;
  current_byte = current_byte & table.mask_;  // Mask out the bits we will use

  // Check whether the byte we have is inside the table we have.
  if (current_byte < table.min_lim_ || current_byte > table.max_lim_) {
    instruction_type_ = IT_UNKNOWN;
    return instruction_type_;
  }

  const Opcode& opcode = table.table_[current_byte];
  if (IT_UNUSED == opcode.type_) {
    // This instruction is not used by the IA-32 ISA, so we indicate
    // this to the user.  Probably means that we were pointed to
    // a byte in memory that was not the start of an instruction.
    instruction_type_ = IT_UNUSED;
    return instruction_type_;
  } else if (IT_REFERENCE == opcode.type_) {
    // We are looking at an opcode that has more bytes (or is continued
    // in the ModR/M byte).  Recursively find the opcode definition in
    // the table for the opcode's next byte.
    size++;
    ProcessOpcode(start_byte + 1, opcode.table_index_, size);
    return instruction_type_;
  }

  const SpecificOpcode* specific_opcode = (SpecificOpcode*)&opcode;
  if (opcode.is_prefix_dependent_) {
    if (got_f2_prefix_ && opcode.opcode_if_f2_prefix_.mnemonic_ != 0) {
      specific_opcode = &opcode.opcode_if_f2_prefix_;
    } else if (got_f3_prefix_ && opcode.opcode_if_f3_prefix_.mnemonic_ != 0) {
      specific_opcode = &opcode.opcode_if_f3_prefix_;
    } else if (got_66_prefix_ && opcode.opcode_if_66_prefix_.mnemonic_ != 0) {
      specific_opcode = &opcode.opcode_if_66_prefix_;
    }
  }

  // Inv: The opcode type is known.
  instruction_type_ = specific_opcode->type_;

  // Let's process the operand types to see if we have any immediate
  // operands, and/or a ModR/M byte.

  ProcessOperand(specific_opcode->flag_dest_);
  ProcessOperand(specific_opcode->flag_source_);
  ProcessOperand(specific_opcode->flag_aux_);

  // Inv: We have processed the opcode and incremented operand_bytes_
  // by the number of bytes of any operands specified by the opcode
  // that are stored in the instruction (not registers etc.).  Now
  // we need to return the total number of bytes for the opcode and
  // for the ModR/M or SIB bytes if they are present.

  if (table.mask_ != 0xff) {
    if (have_modrm_) {
      // we're looking at a ModR/M byte so we're not going to
      // count that into the opcode size
      ProcessModrm(start_byte, size);
      return IT_GENERIC;
    } else {
      // need to count the ModR/M byte even if it's just being
      // used for opcode extension
      size++;
      return IT_GENERIC;
    }
  } else {
    if (have_modrm_) {
      // The ModR/M byte is the next byte.
      size++;
      ProcessModrm(start_byte + 1, size);
      return IT_GENERIC;
    } else {
      size++;
      return IT_GENERIC;
    }
  }
}

bool MiniDisassembler::ProcessOperand(int flag_operand) {
  bool succeeded = true;
  if (AM_NOT_USED == flag_operand)
    return succeeded;

  // Decide what to do based on the addressing mode.
  switch (flag_operand & AM_MASK) {
    // No ModR/M byte indicated by these addressing modes, and no
    // additional (e.g. immediate) parameters.
    case AM_A: // Direct address
    case AM_F: // EFLAGS register
    case AM_X: // Memory addressed by the DS:SI register pair
    case AM_Y: // Memory addressed by the ES:DI register pair
    case AM_IMPLICIT: // Parameter is implicit, occupies no space in
                       // instruction
      break;

    // There is a ModR/M byte but it does not necessarily need
    // to be decoded.
    case AM_C: // reg field of ModR/M selects a control register
    case AM_D: // reg field of ModR/M selects a debug register
    case AM_G: // reg field of ModR/M selects a general register
    case AM_P: // reg field of ModR/M selects an MMX register
    case AM_R: // mod field of ModR/M may refer only to a general register
    case AM_S: // reg field of ModR/M selects a segment register
    case AM_T: // reg field of ModR/M selects a test register
    case AM_V: // reg field of ModR/M selects a 128-bit XMM register
      have_modrm_ = true;
      break;

    // In these addressing modes, there is a ModR/M byte and it needs to be
    // decoded. No other (e.g. immediate) params than indicated in ModR/M.
    case AM_E: // Operand is either a general-purpose register or memory,
                 // specified by ModR/M byte
    case AM_M: // ModR/M byte will refer only to memory
    case AM_Q: // Operand is either an MMX register or memory (complex
                 // evaluation), specified by ModR/M byte
    case AM_W: // Operand is either a 128-bit XMM register or memory (complex
                 // eval), specified by ModR/M byte
      have_modrm_ = true;
      should_decode_modrm_ = true;
      break;

    // These addressing modes specify an immediate or an offset value
    // directly, so we need to look at the operand type to see how many
    // bytes.
    case AM_I: // Immediate data.
    case AM_J: // Jump to offset.
    case AM_O: // Operand is at offset.
      switch (flag_operand & OT_MASK) {
        case OT_B: // Byte regardless of operand-size attribute.
          operand_bytes_ += OS_BYTE;
          break;
        case OT_C: // Byte or word, depending on operand-size attribute.
          if (operand_is_32_bits_)
            operand_bytes_ += OS_WORD;
          else
            operand_bytes_ += OS_BYTE;
          break;
        case OT_D: // Doubleword, regardless of operand-size attribute.
          operand_bytes_ += OS_DOUBLE_WORD;
          break;
        case OT_DQ: // Double-quadword, regardless of operand-size attribute.
          operand_bytes_ += OS_DOUBLE_QUAD_WORD;
          break;
        case OT_P: // 32-bit or 48-bit pointer, depending on operand-size
                     // attribute.
          if (operand_is_32_bits_)
            operand_bytes_ += OS_48_BIT_POINTER;
          else
            operand_bytes_ += OS_32_BIT_POINTER;
          break;
        case OT_PS: // 128-bit packed single-precision floating-point data.
          operand_bytes_ += OS_128_BIT_PACKED_SINGLE_PRECISION_FLOATING;
          break;
        case OT_Q: // Quadword, regardless of operand-size attribute.
          operand_bytes_ += OS_QUAD_WORD;
          break;
        case OT_S: // 6-byte pseudo-descriptor.
          operand_bytes_ += OS_PSEUDO_DESCRIPTOR;
          break;
        case OT_SD: // Scalar Double-Precision Floating-Point Value
        case OT_PD: // Unaligned packed double-precision floating point value
          operand_bytes_ += OS_DOUBLE_PRECISION_FLOATING;
          break;
        case OT_SS:
          // Scalar element of a 128-bit packed single-precision
          // floating data.
          // We simply return enItUnknown since we don't have to support
          // floating point
          succeeded = false;
          break;
        case OT_V: // Word, doubleword or quadword, depending on operand-size 
                   // attribute.
          if (operand_is_64_bits_ && flag_operand & AM_I &&
              flag_operand & IOS_64)
            operand_bytes_ += OS_QUAD_WORD;
          else if (operand_is_32_bits_)
            operand_bytes_ += OS_DOUBLE_WORD;
          else
            operand_bytes_ += OS_WORD;
          break;
        case OT_W: // Word, regardless of operand-size attribute.
          operand_bytes_ += OS_WORD;
          break;

        // Can safely ignore these.
        case OT_A: // Two one-word operands in memory or two double-word
                     // operands in memory
        case OT_PI: // Quadword MMX technology register (e.g. mm0)
        case OT_SI: // Doubleword integer register (e.g., eax)
          break;

        default:
          break;
      }
      break;

    default:
      break;
  }

  return succeeded;
}

bool MiniDisassembler::ProcessModrm(unsigned char* start_byte,
                                    unsigned int& size) {
  // If we don't need to decode, we just return the size of the ModR/M
  // byte (there is never a SIB byte in this case).
  if (!should_decode_modrm_) {
    size++;
    return true;
  }

  // We never care about the reg field, only the combination of the mod
  // and r/m fields, so let's start by packing those fields together into
  // 5 bits.
  unsigned char modrm = (*start_byte);
  unsigned char mod = modrm & 0xC0; // mask out top two bits to get mod field
  modrm = modrm & 0x07; // mask out bottom 3 bits to get r/m field
  mod = mod >> 3; // shift the mod field to the right place
  modrm = mod | modrm; // combine the r/m and mod fields as discussed
  mod = mod >> 3; // shift the mod field to bits 2..0

  // Invariant: modrm contains the mod field in bits 4..3 and the r/m field
  // in bits 2..0, and mod contains the mod field in bits 2..0

  const ModrmEntry* modrm_entry = 0;
  if (address_is_32_bits_)
    modrm_entry = &s_ia32_modrm_map_[modrm];
  else
    modrm_entry = &s_ia16_modrm_map_[modrm];

  // Invariant: modrm_entry points to information that we need to decode
  // the ModR/M byte.

  // Add to the count of operand bytes, if the ModR/M byte indicates
  // that some operands are encoded in the instruction.
  if (modrm_entry->is_encoded_in_instruction_)
    operand_bytes_ += modrm_entry->operand_size_;

  // Process the SIB byte if necessary, and return the count
  // of ModR/M and SIB bytes.
  if (modrm_entry->use_sib_byte_) {
    size++;
    return ProcessSib(start_byte + 1, mod, size);
  } else {
    size++;
    return true;
  }
}

bool MiniDisassembler::ProcessSib(unsigned char* start_byte,
                                  unsigned char mod,
                                  unsigned int& size) {
  // get the mod field from the 2..0 bits of the SIB byte
  unsigned char sib_base = (*start_byte) & 0x07;
  if (0x05 == sib_base) {
    switch (mod) {
    case 0x00: // mod == 00
    case 0x02: // mod == 10
      operand_bytes_ += OS_DOUBLE_WORD;
      break;
    case 0x01: // mod == 01
      operand_bytes_ += OS_BYTE;
      break;
    case 0x03: // mod == 11
      // According to the IA-32 docs, there does not seem to be a disp
      // value for this value of mod
    default:
      break;
    }
  }

  size++;
  return true;
}

};  // namespace sidestep
