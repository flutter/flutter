; Copyright (c) 2011, Google Inc.
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:
; 
;     * Redistributions of source code must retain the above copyright
; notice, this list of conditions and the following disclaimer.
;     * Redistributions in binary form must reproduce the above
; copyright notice, this list of conditions and the following disclaimer
; in the documentation and/or other materials provided with the
; distribution.
;     * Neither the name of Google Inc. nor the names of its
; contributors may be used to endorse or promote products derived from
; this software without specific prior written permission.
; 
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; ---
; Author: Scott Francis
;
; Unit tests for PreamblePatcher
 
.MODEL small
 
.CODE

TooShortFunction PROC
	ret
TooShortFunction ENDP

JumpShortCondFunction PROC
	test cl, 1
	jnz jumpspot
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
	int 3
jumpspot:
	nop
	nop
	nop
	nop
	mov rax, 1
	ret
JumpShortCondFunction ENDP

JumpNearCondFunction PROC
	test cl, 1
	jnz jumpspot
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
jumpspot:
	nop
	nop
	mov rax, 1
	ret
JumpNearCondFunction ENDP

JumpAbsoluteFunction PROC
	test cl, 1
	jmp jumpspot
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
jumpspot:
	nop
	nop
	mov rax, 1
	ret
JumpAbsoluteFunction ENDP

CallNearRelativeFunction PROC
	test cl, 1
	call TooShortFunction
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	mov rdx, 0ffff1111H
	nop
	nop
	nop
	ret
CallNearRelativeFunction ENDP

END
