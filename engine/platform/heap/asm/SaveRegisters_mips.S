/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 */


/*
 * typedef void (*PushAllRegistersCallback)(SafePointBarrier*, ThreadState*, intptr_t*);
 * extern "C" void pushAllRegisters(SafePointBarrier*, ThreadState*, PushAllRegistersCallback)
 */

.type pushAllRegisters, %function
.global pushAllRegisters
.hidden pushAllRegisters
pushAllRegisters:
        // Reserve space for callee-saved registers, return address,
        // as well as for the callee arguments.
        addiu $sp,$sp,-56
        // Save the callee-saved registers and the return address.
        sw $s0,16($sp)
        sw $s1,20($sp)
        sw $s2,24($sp)
        sw $s3,28($sp)
        sw $s4,32($sp)
        sw $s5,36($sp)
        sw $s6,40($sp)
        sw $s7,44($sp)
        sw $ra,48($sp)
        // Pass the two first arguments untouched in a0 and a1 and the
        // stack pointer to the callback.
        move $t9,$a2
        move $a2,$sp
        jal $t9
        // Restore return address, adjust stack and return. No
        // callee-saved register was changed so we do not have to
        // restore callee-saved registers.
        lw $ra,48($sp)
        addiu $sp,$sp,56
        jr $ra
