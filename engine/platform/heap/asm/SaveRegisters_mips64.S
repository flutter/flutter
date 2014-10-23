// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 * typedef void (*PushAllRegistersCallback)(SafePointBarrier*, ThreadState*, intptr_t*);
 * extern "C" void pushAllRegisters(SafePointBarrier*, ThreadState*, PushAllRegistersCallback)
 */

.type pushAllRegisters, %function
.global pushAllRegisters
.hidden pushAllRegisters
pushAllRegisters:
        // Push all callee-saves registers to get them
        // on the stack for conservative stack scanning.
        // Reserve space for callee-saved registers and return address.
        daddiu $sp,$sp,-80
        // Save the callee-saved registers and the return address.
        sd $s0,0($sp)
        sd $s1,8($sp)
        sd $s2,16($sp)
        sd $s3,24($sp)
        sd $s4,32($sp)
        sd $s5,40($sp)
        sd $s6,48($sp)
        sd $s7,56($sp)
        sd $ra,64($sp)
        // Note: the callee-saved floating point registers do not need to be
        // copied to the stack, because fp registers never hold heap pointers
        // and so do not need to be kept visible to the garbage collector.
        // Pass the two first arguments untouched in a0 and a1 and the
        // stack pointer to the callback.
        move $t9,$a2
        move $a2,$sp
        jal $t9
        // Restore return address, adjust stack and return.
        // Note: the copied registers do not need to be reloaded here,
        // because they were preserved by the called routine.
        ld $ra,64($sp)
        daddiu $sp,$sp,80
        jr $ra
