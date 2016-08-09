
/* filter_neon.S - NEON optimised filter functions
 *
 * Copyright (c) 2014 Glenn Randers-Pehrson
 * Written by Mans Rullgard, 2011.
 * Last changed in libpng 1.6.16 [December 22, 2014]
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

/* This is required to get the symbol renames, which are #defines, and the
 * definitions (or not) of PNG_ARM_NEON_OPT and PNG_ARM_NEON_IMPLEMENTATION.
 */
#define PNG_VERSION_INFO_ONLY
#include "../pngpriv.h"

#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",%progbits /* mark stack as non-executable */
#endif

#ifdef PNG_READ_SUPPORTED

/* Assembler NEON support - only works for 32-bit ARM (i.e. it does not work for
 * ARM64).  The code in arm/filter_neon_intrinsics.c supports ARM64, however it
 * only works if -mfpu=neon is specified on the GCC command line.  See pngpriv.h
 * for the logic which sets PNG_USE_ARM_NEON_ASM:
 */
#if PNG_ARM_NEON_IMPLEMENTATION == 2 /* hand-coded assembler */

#if PNG_ARM_NEON_OPT > 0

#ifdef __ELF__
#   define ELF
#else
#   define ELF @
#endif

        .arch armv7-a
        .fpu  neon

.macro  func    name, export=0
    .macro endfunc
ELF     .size   \name, . - \name
        .endfunc
        .purgem endfunc
    .endm
        .text

        /* Explicitly specifying alignment here because some versions of
         * GAS don't align code correctly.  This is harmless in correctly
         * written versions of GAS.
         */
        .align 2

    .if \export
        .global \name
    .endif
ELF     .type   \name, STT_FUNC
        .func   \name
\name:
.endm

func    png_read_filter_row_sub4_neon, export=1
        ldr             r3,  [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
1:
        vld4.32         {d4[],d5[],d6[],d7[]},    [r1,:128]
        vadd.u8         d0,  d3,  d4
        vadd.u8         d1,  d0,  d5
        vadd.u8         d2,  d1,  d6
        vadd.u8         d3,  d2,  d7
        vst4.32         {d0[0],d1[0],d2[0],d3[0]},[r1,:128]!
        subs            r3,  r3,  #16
        bgt             1b

        bx              lr
endfunc

func    png_read_filter_row_sub3_neon, export=1
        ldr             r3,  [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
        mov             r0,  r1
        mov             r2,  #3
        mov             r12, #12
        vld1.8          {q11},    [r0], r12
1:
        vext.8          d5,  d22, d23, #3
        vadd.u8         d0,  d3,  d22
        vext.8          d6,  d22, d23, #6
        vadd.u8         d1,  d0,  d5
        vext.8          d7,  d23, d23, #1
        vld1.8          {q11},    [r0], r12
        vst1.32         {d0[0]},  [r1,:32], r2
        vadd.u8         d2,  d1,  d6
        vst1.32         {d1[0]},  [r1], r2
        vadd.u8         d3,  d2,  d7
        vst1.32         {d2[0]},  [r1], r2
        vst1.32         {d3[0]},  [r1], r2
        subs            r3,  r3,  #12
        bgt             1b

        bx              lr
endfunc

func    png_read_filter_row_up_neon, export=1
        ldr             r3,  [r0, #4]           @ rowbytes
1:
        vld1.8          {q0}, [r1,:128]
        vld1.8          {q1}, [r2,:128]!
        vadd.u8         q0,  q0,  q1
        vst1.8          {q0}, [r1,:128]!
        subs            r3,  r3,  #16
        bgt             1b

        bx              lr
endfunc

func    png_read_filter_row_avg4_neon, export=1
        ldr             r12, [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
1:
        vld4.32         {d4[],d5[],d6[],d7[]},    [r1,:128]
        vld4.32         {d16[],d17[],d18[],d19[]},[r2,:128]!
        vhadd.u8        d0,  d3,  d16
        vadd.u8         d0,  d0,  d4
        vhadd.u8        d1,  d0,  d17
        vadd.u8         d1,  d1,  d5
        vhadd.u8        d2,  d1,  d18
        vadd.u8         d2,  d2,  d6
        vhadd.u8        d3,  d2,  d19
        vadd.u8         d3,  d3,  d7
        vst4.32         {d0[0],d1[0],d2[0],d3[0]},[r1,:128]!
        subs            r12, r12, #16
        bgt             1b

        bx              lr
endfunc

func    png_read_filter_row_avg3_neon, export=1
        push            {r4,lr}
        ldr             r12, [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
        mov             r0,  r1
        mov             r4,  #3
        mov             lr,  #12
        vld1.8          {q11},    [r0], lr
1:
        vld1.8          {q10},    [r2], lr
        vext.8          d5,  d22, d23, #3
        vhadd.u8        d0,  d3,  d20
        vext.8          d17, d20, d21, #3
        vadd.u8         d0,  d0,  d22
        vext.8          d6,  d22, d23, #6
        vhadd.u8        d1,  d0,  d17
        vext.8          d18, d20, d21, #6
        vadd.u8         d1,  d1,  d5
        vext.8          d7,  d23, d23, #1
        vld1.8          {q11},    [r0], lr
        vst1.32         {d0[0]},  [r1,:32], r4
        vhadd.u8        d2,  d1,  d18
        vst1.32         {d1[0]},  [r1], r4
        vext.8          d19, d21, d21, #1
        vadd.u8         d2,  d2,  d6
        vhadd.u8        d3,  d2,  d19
        vst1.32         {d2[0]},  [r1], r4
        vadd.u8         d3,  d3,  d7
        vst1.32         {d3[0]},  [r1], r4
        subs            r12, r12, #12
        bgt             1b

        pop             {r4,pc}
endfunc

.macro  paeth           rx,  ra,  rb,  rc
        vaddl.u8        q12, \ra, \rb           @ a + b
        vaddl.u8        q15, \rc, \rc           @ 2*c
        vabdl.u8        q13, \rb, \rc           @ pa
        vabdl.u8        q14, \ra, \rc           @ pb
        vabd.u16        q15, q12, q15           @ pc
        vcle.u16        q12, q13, q14           @ pa <= pb
        vcle.u16        q13, q13, q15           @ pa <= pc
        vcle.u16        q14, q14, q15           @ pb <= pc
        vand            q12, q12, q13           @ pa <= pb && pa <= pc
        vmovn.u16       d28, q14
        vmovn.u16       \rx, q12
        vbsl            d28, \rb, \rc
        vbsl            \rx, \ra, d28
.endm

func    png_read_filter_row_paeth4_neon, export=1
        ldr             r12, [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
        vmov.i8         d20, #0
1:
        vld4.32         {d4[],d5[],d6[],d7[]},    [r1,:128]
        vld4.32         {d16[],d17[],d18[],d19[]},[r2,:128]!
        paeth           d0,  d3,  d16, d20
        vadd.u8         d0,  d0,  d4
        paeth           d1,  d0,  d17, d16
        vadd.u8         d1,  d1,  d5
        paeth           d2,  d1,  d18, d17
        vadd.u8         d2,  d2,  d6
        paeth           d3,  d2,  d19, d18
        vmov            d20, d19
        vadd.u8         d3,  d3,  d7
        vst4.32         {d0[0],d1[0],d2[0],d3[0]},[r1,:128]!
        subs            r12, r12, #16
        bgt             1b

        bx              lr
endfunc

func    png_read_filter_row_paeth3_neon, export=1
        push            {r4,lr}
        ldr             r12, [r0, #4]           @ rowbytes
        vmov.i8         d3,  #0
        vmov.i8         d4,  #0
        mov             r0,  r1
        mov             r4,  #3
        mov             lr,  #12
        vld1.8          {q11},    [r0], lr
1:
        vld1.8          {q10},    [r2], lr
        paeth           d0,  d3,  d20, d4
        vext.8          d5,  d22, d23, #3
        vadd.u8         d0,  d0,  d22
        vext.8          d17, d20, d21, #3
        paeth           d1,  d0,  d17, d20
        vst1.32         {d0[0]},  [r1,:32], r4
        vext.8          d6,  d22, d23, #6
        vadd.u8         d1,  d1,  d5
        vext.8          d18, d20, d21, #6
        paeth           d2,  d1,  d18, d17
        vext.8          d7,  d23, d23, #1
        vld1.8          {q11},    [r0], lr
        vst1.32         {d1[0]},  [r1], r4
        vadd.u8         d2,  d2,  d6
        vext.8          d19, d21, d21, #1
        paeth           d3,  d2,  d19, d18
        vst1.32         {d2[0]},  [r1], r4
        vmov            d4,  d19
        vadd.u8         d3,  d3,  d7
        vst1.32         {d3[0]},  [r1], r4
        subs            r12, r12, #12
        bgt             1b

        pop             {r4,pc}
endfunc
#endif /* PNG_ARM_NEON_OPT > 0 */
#endif /* PNG_ARM_NEON_IMPLEMENTATION == 2 (assembler) */
#endif /* READ */
