// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// base::mac::CallWithEHFrame(void () block_pointer)
#define CALL_WITH_EH_FRAME __ZN4base3mac15CallWithEHFrameEU13block_pointerFvvE

  .section __TEXT,__text,regular,pure_instructions
#if !defined(COMPONENT_BUILD)
  .private_extern CALL_WITH_EH_FRAME
#endif
  .globl CALL_WITH_EH_FRAME
  .align 4
CALL_WITH_EH_FRAME:

  .cfi_startproc

  // Configure the C++ exception handler personality routine. Normally the
  // compiler would emit ___gxx_personality_v0 here. The purpose of this
  // function is to use a custom personality routine.
  .cfi_personality 155, __ZN4base3mac21CxxPersonalityRoutineEi14_Unwind_ActionyP17_Unwind_ExceptionP15_Unwind_Context
  .cfi_lsda 16, CallWithEHFrame_exception_table

Lfunction_start:
  pushq %rbp
  .cfi_def_cfa_offset 16
  .cfi_offset %rbp, -16
  movq %rsp, %rbp
  .cfi_def_cfa_register %rbp

  // Load the function pointer from the block descriptor.
  movq 16(%rdi), %rax

  // Execute the block in the context of a C++ try{}.
Ltry_start:
  callq *%rax
Ltry_end:
  popq %rbp
  ret

  // Landing pad for the exception handler. This should never be called, since
  // the personality routine will stop the search for an exception handler,
  // which will cause the runtime to invoke the default terminate handler.
Lcatch:
  movq %rax, %rdi
  callq ___cxa_begin_catch  // The ABI requires a call to the catch handler.
  ud2  // In the event this is called, make it fatal.

Lfunction_end:
  .cfi_endproc

// The C++ exception table that is used to identify this frame as an
// exception handler. See http://llvm.org/docs/ExceptionHandling.html and
// http://mentorembedded.github.io/cxx-abi/exceptions.pdf.
  .section __TEXT,__gcc_except_tab
  .align 2
CallWithEHFrame_exception_table:
  .byte 255  // DW_EH_PE_omit
  .byte 155  // DW_EH_PE_indirect | DW_EH_PE_pcrel | DW_EH_PE_sdata4
  .asciz "\242\200\200"  // LE int128 for the number of bytes in this table.
  .byte 3  // DW_EH_PE_udata4
  .byte 26  // Callsite table length.

// First callsite.
CS1_begin = Ltry_start - Lfunction_start
  .long CS1_begin
CS1_end = Ltry_end - Ltry_start
  .long CS1_end

// First landing pad.
LP1 = Lcatch - Lfunction_start
  .long LP1
  .byte 1  // Action record.

// Second callsite.
CS2_begin = Ltry_end - Lfunction_start
  .long CS2_begin
CS2_end = Lfunction_end - Ltry_end
  .long CS2_end

// Second landing pad (none).
  .long 0
  .byte 0  // No action.

// Action table.
  .byte 1  // Action record 1.
  .byte 0  // No further action to take.
  .long 0  // No type filter for this catch(){} clause.
  .align 2
