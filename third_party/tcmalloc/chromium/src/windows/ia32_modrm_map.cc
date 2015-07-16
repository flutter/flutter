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
 * Table of relevant information about how to decode the ModR/M byte.
 * Based on information in the IA-32 Intel® Architecture
 * Software Developer's Manual Volume 2: Instruction Set Reference.
 */

#include "mini_disassembler.h"
#include "mini_disassembler_types.h"

namespace sidestep {

const ModrmEntry MiniDisassembler::s_ia16_modrm_map_[] = {
// mod == 00
  /* r/m == 000 */ { false, false, OS_ZERO },
  /* r/m == 001 */ { false, false, OS_ZERO },
  /* r/m == 010 */ { false, false, OS_ZERO },
  /* r/m == 011 */ { false, false, OS_ZERO },
  /* r/m == 100 */ { false, false, OS_ZERO },
  /* r/m == 101 */ { false, false, OS_ZERO },
  /* r/m == 110 */ { true, false, OS_WORD },
  /* r/m == 111 */ { false, false, OS_ZERO }, 
// mod == 01
  /* r/m == 000 */ { true, false, OS_BYTE },
  /* r/m == 001 */ { true, false, OS_BYTE },
  /* r/m == 010 */ { true, false, OS_BYTE },
  /* r/m == 011 */ { true, false, OS_BYTE },
  /* r/m == 100 */ { true, false, OS_BYTE },
  /* r/m == 101 */ { true, false, OS_BYTE },
  /* r/m == 110 */ { true, false, OS_BYTE },
  /* r/m == 111 */ { true, false, OS_BYTE }, 
// mod == 10
  /* r/m == 000 */ { true, false, OS_WORD },
  /* r/m == 001 */ { true, false, OS_WORD },
  /* r/m == 010 */ { true, false, OS_WORD },
  /* r/m == 011 */ { true, false, OS_WORD },
  /* r/m == 100 */ { true, false, OS_WORD },
  /* r/m == 101 */ { true, false, OS_WORD },
  /* r/m == 110 */ { true, false, OS_WORD },
  /* r/m == 111 */ { true, false, OS_WORD }, 
// mod == 11
  /* r/m == 000 */ { false, false, OS_ZERO },
  /* r/m == 001 */ { false, false, OS_ZERO },
  /* r/m == 010 */ { false, false, OS_ZERO },
  /* r/m == 011 */ { false, false, OS_ZERO },
  /* r/m == 100 */ { false, false, OS_ZERO },
  /* r/m == 101 */ { false, false, OS_ZERO },
  /* r/m == 110 */ { false, false, OS_ZERO },
  /* r/m == 111 */ { false, false, OS_ZERO }
};

const ModrmEntry MiniDisassembler::s_ia32_modrm_map_[] = {
// mod == 00
  /* r/m == 000 */ { false, false, OS_ZERO },
  /* r/m == 001 */ { false, false, OS_ZERO },
  /* r/m == 010 */ { false, false, OS_ZERO },
  /* r/m == 011 */ { false, false, OS_ZERO },
  /* r/m == 100 */ { false, true, OS_ZERO },
  /* r/m == 101 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 110 */ { false, false, OS_ZERO },
  /* r/m == 111 */ { false, false, OS_ZERO }, 
// mod == 01
  /* r/m == 000 */ { true, false, OS_BYTE },
  /* r/m == 001 */ { true, false, OS_BYTE },
  /* r/m == 010 */ { true, false, OS_BYTE },
  /* r/m == 011 */ { true, false, OS_BYTE },
  /* r/m == 100 */ { true, true, OS_BYTE },
  /* r/m == 101 */ { true, false, OS_BYTE },
  /* r/m == 110 */ { true, false, OS_BYTE },
  /* r/m == 111 */ { true, false, OS_BYTE }, 
// mod == 10
  /* r/m == 000 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 001 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 010 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 011 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 100 */ { true, true, OS_DOUBLE_WORD },
  /* r/m == 101 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 110 */ { true, false, OS_DOUBLE_WORD },
  /* r/m == 111 */ { true, false, OS_DOUBLE_WORD }, 
// mod == 11
  /* r/m == 000 */ { false, false, OS_ZERO },
  /* r/m == 001 */ { false, false, OS_ZERO },
  /* r/m == 010 */ { false, false, OS_ZERO },
  /* r/m == 011 */ { false, false, OS_ZERO },
  /* r/m == 100 */ { false, false, OS_ZERO },
  /* r/m == 101 */ { false, false, OS_ZERO },
  /* r/m == 110 */ { false, false, OS_ZERO },
  /* r/m == 111 */ { false, false, OS_ZERO },
};

};  // namespace sidestep
