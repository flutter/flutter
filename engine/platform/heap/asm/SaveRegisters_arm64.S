/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
        /* Save return address. */
        sub sp, sp, #96
        stp x19, x20, [sp, #80]
        stp x21, x22, [sp, #64]
        stp x23, x24, [sp, #48]
        stp x25, x26, [sp, #32]
        stp x27, x28, [sp, #16]
        stp x30, x29, [sp, #0]  // x30 is lr.

        /* Pass the two first arguments unchanged (x0, x1)
         * and pass the stack pointer as third argument to the
         * callback function.
         */
        mov x3, x2
        mov x2, sp
        blr x3

        /* We don't restore all registers since they are callee saved (so
         * the callback didn't clobber them) and we didn't modify them either.
         */
        ldr x30, [sp], #96
        ret
