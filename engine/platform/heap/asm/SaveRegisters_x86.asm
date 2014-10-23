;; Copyright (C) 2013 Google Inc. All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;     * Redistributions of source code must retain the above copyright
;; notice, this list of conditions and the following disclaimer.
;;     * Redistributions in binary form must reproduce the above
;; copyright notice, this list of conditions and the following disclaimer
;; in the documentation and/or other materials provided with the
;; distribution.
;;     * Neither the name of Google Inc. nor the names of its
;; contributors may be used to endorse or promote products derived from
;; this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;

%ifndef X64POSIX
%define X64POSIX 0
%endif

%ifndef X64WIN
%define X64WIN 0
%endif

%ifndef IA32
%define IA32 0
%endif

%ifndef ARM
%define ARM 0
%endif

;; Prefix symbols by '_' if PREFIX is defined.
%ifdef PREFIX
%define mangle(x) _ %+ x
%else
%define mangle(x) x
%endif


; PRIVATE makes a symbol private.
%ifidn   __OUTPUT_FORMAT__,elf32
  %define PRIVATE :hidden
%elifidn __OUTPUT_FORMAT__,elf64
  %define PRIVATE :hidden
%elifidn __OUTPUT_FORMAT__,elfx32
  %define PRIVATE :hidden
%elif X64WIN
  %define PRIVATE
%else
  %define PRIVATE :private_extern
%endif

;; typedef void (*PushAllRegistersCallback)(SafePointBarrier*, ThreadState*, intptr_t*);
;; extern "C" void pushAllRegisters(SafePointBarrier*, ThreadState*, PushAllRegistersCallback)

        global mangle(pushAllRegisters) PRIVATE

%if X64POSIX

mangle(pushAllRegisters):
        ;; Push all callee-saves registers to get them
        ;; on the stack for conservative stack scanning.
        ;; We maintain 16-byte alignment at calls (required on Mac).
        ;; There is an 8-byte return address on the stack and we push
        ;; 56 bytes which maintains 16-byte stack alignment
        ;; at the call.
        push 0
        push rbx
        push rbp
        push r12
        push r13
        push r14
        push r15
        ;; Pass the two first arguments unchanged (rdi, rsi)
        ;; and the stack pointer after pushing callee-saved
        ;; registers to the callback.
        mov r8, rdx
        mov rdx, rsp
        call r8
        ;; Pop the callee-saved registers. None of them were
        ;; modified so no restoring is needed.
        add rsp, 56
        ret

%elif X64WIN

mangle(pushAllRegisters):
        ;; Push all callee-saves registers to get them
        ;; on the stack for conservative stack scanning.
        push rsi
        push rdi
        push rbx
        push rbp
        push r12
        push r13
        push r14
        push r15
        ;; Pass the two first arguments unchanged (rcx, rdx)
        ;; and the stack pointer after pushing callee-saved
        ;; registers to the callback.
        mov r9, r8
        mov r8, rsp
        call r9
        ;; Pop the callee-saved registers. None of them were
        ;; modified so no restoring is needed.
        add rsp, 64
        ret

%elif IA32

mangle(pushAllRegisters):
        ;; Push all callee-saves registers to get them
        ;; on the stack for conservative stack scanning.
        ;; We maintain 16-byte alignment at calls (required on
        ;; Mac). There is a 4-byte return address on the stack
        ;; and we push 28 bytes which maintains 16-byte alignment
        ;; at the call.
        push ebx
        push ebp
        push esi
        push edi
        ;; Pass the two first arguments unchanged and the
        ;; stack pointer after pushing callee-save registers
        ;; to the callback.
        mov ecx, [esp + 28]
        push esp
        push dword [esp + 28]
        push dword [esp + 28]
        call ecx
        ;; Pop arguments and the callee-saved registers.
        ;; None of the callee-saved registers were modified
        ;; so we do not need to restore them.
        add esp, 28
        ret


%elif ARM
%error "Yasm does not support arm. Use SaveRegisters_arm.S on arm."
%else
%error "Unsupported platform."
%endif
