// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include "skia/ext/convolver.h"
#include "skia/ext/convolver_mips_dspr2.h"
#include "third_party/skia/include/core/SkTypes.h"

namespace skia {
// Convolves horizontally along a single row. The row data is given in
// |src_data| and continues for the num_values() of the filter.
void ConvolveHorizontally_mips_dspr2(const unsigned char* src_data,
                                     const ConvolutionFilter1D& filter,
                                     unsigned char* out_row,
                                     bool has_alpha) {
#if SIMD_MIPS_DSPR2
  int row_to_filter = 0;
  int num_values = filter.num_values();
  if (has_alpha) {
    for (int out_x = 0; out_x < num_values; out_x++) {
      // Get the filter that determines the current output pixel.
      int filter_offset, filter_length;
      const ConvolutionFilter1D::Fixed* filter_values =
        filter.FilterForValue(out_x, &filter_offset, &filter_length);
      int filter_x = 0;

      __asm__ __volatile__ (
        ".set push                                  \n"
        ".set noreorder                             \n"

        "beqz            %[filter_len], 3f          \n"
        " sll            $t0, %[filter_offset], 2   \n"
        "addu            %[rtf], %[src_data], $t0   \n"
        "mtlo            $0, $ac0                   \n"
        "mtlo            $0, $ac1                   \n"
        "mtlo            $0, $ac2                   \n"
        "mtlo            $0, $ac3                   \n"
        "srl             $t7, %[filter_len], 2      \n"
        "beqz            $t7, 2f                    \n"
        " li             %[fx], 0                   \n"

        "11:                                        \n"
        "addu            $t4, %[filter_val], %[fx]  \n"
        "sll             $t5, %[fx], 1              \n"
        "ulw             $t6, 0($t4)                \n" // t6 = |cur[1]|cur[0]|
        "ulw             $t8, 4($t4)                \n" // t8 = |cur[3]|cur[2]|
        "addu            $t0, %[rtf], $t5           \n"
        "lw              $t1, 0($t0)                \n" // t1 = |a0|b0|g0|r0|
        "lw              $t2, 4($t0)                \n" // t2 = |a1|b1|g1|r1|
        "lw              $t3, 8($t0)                \n" // t3 = |a2|b2|g2|r2|
        "lw              $t4, 12($t0)               \n" // t4 = |a3|b3|g3|r3|
        "precrq.qb.ph    $t0, $t2, $t1              \n" // t0 = |a1|g1|a0|g0|
        "precr.qb.ph     $t5, $t2, $t1              \n" // t5 = |b1|r1|b0|r0|
        "preceu.ph.qbla  $t1, $t0                   \n" // t1 = |0|a1|0|a0|
        "preceu.ph.qbra  $t2, $t0                   \n" // t2 = |0|g1|0|g0|
        "preceu.ph.qbla  $t0, $t5                   \n" // t0 = |0|b1|0|b0|
        "preceu.ph.qbra  $t5, $t5                   \n" // t5 = |0|r1|0|r0|
        "dpa.w.ph        $ac0, $t1, $t6             \n" // ac0+(cur*a1)+(cur*a0)
        "dpa.w.ph        $ac1, $t0, $t6             \n" // ac1+(cur*b1)+(cur*b0)
        "dpa.w.ph        $ac2, $t2, $t6             \n" // ac2+(cur*g1)+(cur*g0)
        "dpa.w.ph        $ac3, $t5, $t6             \n" // ac3+(cur*r1)+(cur*r0)
        "precrq.qb.ph    $t0, $t4, $t3              \n" // t0 = |a3|g3|a2|g2|
        "precr.qb.ph     $t5, $t4, $t3              \n" // t5 = |b3|r3|b2|r2|
        "preceu.ph.qbla  $t1, $t0                   \n" // t1 = |0|a3|0|a2|
        "preceu.ph.qbra  $t2, $t0                   \n" // t2 = |0|g3|0|g2|
        "preceu.ph.qbla  $t0, $t5                   \n" // t0 = |0|b3|0|b2|
        "preceu.ph.qbra  $t5, $t5                   \n" // t5 = |0|r3|0|r2|
        "dpa.w.ph        $ac0, $t1, $t8             \n" // ac0+(cur*a3)+(cur*a2)
        "dpa.w.ph        $ac1, $t0, $t8             \n" // ac1+(cur*b3)+(cur*b2)
        "dpa.w.ph        $ac2, $t2, $t8             \n" // ac2+(cur*g3)+(cur*g2)
        "dpa.w.ph        $ac3, $t5, $t8             \n" // ac3+(cur*r3)+(cur*r2)
        "addiu           $t7, $t7, -1               \n"
        "bgtz            $t7, 11b                   \n"
        " addiu          %[fx], %[fx], 8            \n"

        "2:                                         \n"
        "andi            $t7, %[filter_len], 0x3    \n" // residual
        "beqz            $t7, 3f                    \n"
        " nop                                       \n"

        "21:                                        \n"
        "sll             $t1, %[fx], 1              \n"
        "addu            $t2, %[filter_val], %[fx]  \n"
        "addu            $t0, %[rtf], $t1           \n"
        "lh              $t6, 0($t2)                \n" // t6 = filter_val[fx]
        "lbu             $t1, 0($t0)                \n" // t1 = row[fx * 4 + 0]
        "lbu             $t2, 1($t0)                \n" // t2 = row[fx * 4 + 1]
        "lbu             $t3, 2($t0)                \n" // t3 = row[fx * 4 + 2]
        "lbu             $t4, 3($t0)                \n" // t4 = row[fx * 4 + 2]
        "maddu           $ac3, $t6, $t1             \n"
        "maddu           $ac2, $t6, $t2             \n"
        "maddu           $ac1, $t6, $t3             \n"
        "maddu           $ac0, $t6, $t4             \n"
        "addiu           $t7, $t7, -1               \n"
        "bgtz            $t7, 21b                   \n"
        " addiu          %[fx], %[fx], 2            \n"

        "3:                                         \n"
        "extrv.w         $t0, $ac0, %[kShiftBits]   \n" // a >> kShiftBits
        "extrv.w         $t1, $ac1, %[kShiftBits]   \n" // b >> kShiftBits
        "extrv.w         $t2, $ac2, %[kShiftBits]   \n" // g >> kShiftBits
        "extrv.w         $t3, $ac3, %[kShiftBits]   \n" // r >> kShiftBits
        "sll             $t5, %[out_x], 2           \n"
        "repl.ph         $t6, 128                   \n" // t6 = | 128 | 128 |
        "addu            $t5, %[out_row], $t5       \n"
        "append          $t2, $t3, 16               \n"
        "append          $t0, $t1, 16               \n"
        "subu.ph         $t1, $t0, $t6              \n"
        "shll_s.ph       $t1, $t1, 8                \n"
        "shra.ph         $t1, $t1, 8                \n"
        "addu.ph         $t1, $t1, $t6              \n"
        "subu.ph         $t3, $t2, $t6              \n"
        "shll_s.ph       $t3, $t3, 8                \n"
        "shra.ph         $t3, $t3, 8                \n"
        "addu.ph         $t3, $t3, $t6              \n"
        "precr.qb.ph     $t0, $t1, $t3              \n"
        "usw             $t0, 0($t5)                \n"

        ".set pop                                   \n"
      : [fx] "+r" (filter_x), [out_x] "+r" (out_x), [out_row] "+r" (out_row),
        [rtf] "+r" (row_to_filter)
      : [filter_val] "r" (filter_values), [filter_len] "r" (filter_length),
        [kShiftBits] "r" (ConvolutionFilter1D::kShiftBits),
        [filter_offset] "r" (filter_offset), [src_data] "r" (src_data)
      : "lo", "hi", "$ac1lo", "$ac1hi", "$ac2lo", "$ac2hi", "$ac3lo", "$ac3hi",
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8"
      );
    }
  } else {
    for (int out_x = 0; out_x < num_values; out_x++) {
      // Get the filter that determines the current output pixel.
      int filter_offset, filter_length;
      const ConvolutionFilter1D::Fixed* filter_values =
        filter.FilterForValue(out_x, &filter_offset, &filter_length);
      int filter_x = 0;
      __asm__ __volatile__ (
        ".set push                                  \n"
        ".set noreorder                             \n"

        "beqz            %[filter_len], 3f          \n"
        " sll            $t0, %[filter_offset], 2   \n"
        "addu            %[rtf], %[src_data], $t0   \n"
        "mtlo            $0, $ac1                   \n"
        "mtlo            $0, $ac2                   \n"
        "mtlo            $0, $ac3                   \n"
        "srl             $t7, %[filter_len], 2      \n"
        "beqz            $t7, 2f                    \n"
        " li             %[fx], 0                   \n"

        "11:                                        \n"
        "addu            $t4, %[filter_val], %[fx]  \n"
        "sll             $t5, %[fx], 1              \n"
        "ulw             $t6, 0($t4)                \n" // t6 = |cur[1]|cur[0]|
        "ulw             $t8, 4($t4)                \n" // t8 = |cur[3]|cur[2]|
        "addu            $t0, %[rtf], $t5           \n"
        "lw              $t1, 0($t0)                \n" // t1 = |a0|b0|g0|r0|
        "lw              $t2, 4($t0)                \n" // t2 = |a1|b1|g1|r1|
        "lw              $t3, 8($t0)                \n" // t3 = |a2|b2|g2|r2|
        "lw              $t4, 12($t0)               \n" // t4 = |a3|b3|g3|r3|
        "precrq.qb.ph    $t0, $t2, $t1              \n" // t0 = |a1|g1|a0|g0|
        "precr.qb.ph     $t5, $t2, $t1              \n" // t5 = |b1|r1|b0|r0|
        "preceu.ph.qbra  $t2, $t0                   \n" // t2 = |0|g1|0|g0|
        "preceu.ph.qbla  $t0, $t5                   \n" // t0 = |0|b1|0|b0|
        "preceu.ph.qbra  $t5, $t5                   \n" // t5 = |0|r1|0|r0|
        "dpa.w.ph        $ac1, $t0, $t6             \n" // ac1+(cur*b1)+(cur*b0)
        "dpa.w.ph        $ac2, $t2, $t6             \n" // ac2+(cur*g1)+(cur*g0)
        "dpa.w.ph        $ac3, $t5, $t6             \n" // ac3+(cur*r1)+(cur*r0)
        "precrq.qb.ph    $t0, $t4, $t3              \n" // t0 = |a3|g3|a2|g2|
        "precr.qb.ph     $t5, $t4, $t3              \n" // t5 = |b3|r3|b2|r2|
        "preceu.ph.qbra  $t2, $t0                   \n" // t2 = |0|g3|0|g2|
        "preceu.ph.qbla  $t0, $t5                   \n" // t0 = |0|b3|0|b2|
        "preceu.ph.qbra  $t5, $t5                   \n" // t5 = |0|r3|0|r2|
        "dpa.w.ph        $ac1, $t0, $t8             \n" // ac1+(cur*b3)+(cur*b2)
        "dpa.w.ph        $ac2, $t2, $t8             \n" // ac2+(cur*g3)+(cur*g2)
        "dpa.w.ph        $ac3, $t5, $t8             \n" // ac3+(cur*r3)+(cur*r2)
        "addiu           $t7, $t7, -1               \n"
        "bgtz            $t7, 11b                   \n"
        " addiu          %[fx], %[fx], 8            \n"

        "2:                                         \n"
        "andi            $t7, %[filter_len], 0x3    \n" // residual
        "beqz            $t7, 3f                    \n"
        " nop                                       \n"

        "21:                                        \n"
        "sll             $t1, %[fx], 1              \n"
        "addu            $t2, %[filter_val], %[fx]  \n"
        "addu            $t0, %[rtf], $t1           \n"
        "lh              $t6, 0($t2)                \n" // t6 = filter_val[fx]
        "lbu             $t1, 0($t0)                \n" // t1 = row[fx * 4 + 0]
        "lbu             $t2, 1($t0)                \n" // t2 = row[fx * 4 + 1]
        "lbu             $t3, 2($t0)                \n" // t3 = row[fx * 4 + 2]
        "maddu           $ac3, $t6, $t1             \n"
        "maddu           $ac2, $t6, $t2             \n"
        "maddu           $ac1, $t6, $t3             \n"
        "addiu           $t7, $t7, -1               \n"
        "bgtz            $t7, 21b                   \n"
        " addiu          %[fx], %[fx], 2            \n"

        "3:                                         \n"
        "extrv.w         $t1, $ac1, %[kShiftBits]   \n" // b >> kShiftBits
        "extrv.w         $t2, $ac2, %[kShiftBits]   \n" // g >> kShiftBits
        "extrv.w         $t3, $ac3, %[kShiftBits]   \n" // r >> kShiftBits
        "repl.ph         $t6, 128                   \n" // t6 = | 128 | 128 |
        "sll             $t8, %[out_x], 2           \n"
        "addu            $t8, %[out_row], $t8       \n"
        "append          $t2, $t3, 16               \n"
        "andi            $t1, 0xFFFF                \n"
        "subu.ph         $t5, $t1, $t6              \n"
        "shll_s.ph       $t5, $t5, 8                \n"
        "shra.ph         $t5, $t5, 8                \n"
        "addu.ph         $t5, $t5, $t6              \n"
        "subu.ph         $t4, $t2, $t6              \n"
        "shll_s.ph       $t4, $t4, 8                \n"
        "shra.ph         $t4, $t4, 8                \n"
        "addu.ph         $t4, $t4, $t6              \n"
        "precr.qb.ph     $t0, $t5, $t4              \n"
        "usw             $t0, 0($t8)                \n"

        ".set pop                                   \n"
      : [fx] "+r" (filter_x), [out_x] "+r" (out_x), [out_row] "+r" (out_row),
        [rtf] "+r" (row_to_filter)
      : [filter_val] "r" (filter_values), [filter_len] "r" (filter_length),
        [kShiftBits] "r" (ConvolutionFilter1D::kShiftBits),
        [filter_offset] "r" (filter_offset), [src_data] "r" (src_data)
      : "lo", "hi", "$ac1lo", "$ac1hi", "$ac2lo", "$ac2hi", "$ac3lo", "$ac3hi",
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "t8"
      );
    }
  }
#endif
}
void ConvolveVertically_mips_dspr2(const ConvolutionFilter1D::Fixed* filter_val,
                                   int filter_length,
                                   unsigned char* const* source_data_rows,
                                   int pixel_width,
                                   unsigned char* out_row,
                                   bool has_alpha) {
#if SIMD_MIPS_DSPR2
  // We go through each column in the output and do a vertical convolution,
  // generating one output pixel each time.
  int byte_offset;
  int cnt;
  int filter_y;
  if (has_alpha) {
    for (int out_x = 0; out_x < pixel_width; out_x++) {
      __asm__ __volatile__ (
        ".set push                                   \n"
        ".set noreorder                              \n"

        "beqz            %[filter_len], 3f           \n"
        " sll            %[offset], %[out_x], 2      \n"
        "mtlo            $0, $ac0                    \n"
        "mtlo            $0, $ac1                    \n"
        "mtlo            $0, $ac2                    \n"
        "mtlo            $0, $ac3                    \n"
        "srl             %[cnt], %[filter_len], 2    \n"
        "beqz            %[cnt], 2f                  \n"
        " li             %[fy], 0                    \n"

        "11:                                         \n"
        "sll             $t1, %[fy], 1               \n"
        "addu            $t0, %[src_data_rows], $t1  \n"
        "lw              $t1, 0($t0)                 \n"
        "lw              $t2, 4($t0)                 \n"
        "lw              $t3, 8($t0)                 \n"
        "lw              $t4, 12($t0)                \n"
        "addu            $t1, $t1, %[offset]         \n"
        "addu            $t2, $t2, %[offset]         \n"
        "addu            $t3, $t3, %[offset]         \n"
        "addu            $t4, $t4, %[offset]         \n"
        "lw              $t1, 0($t1)                 \n" // t1 = |a0|b0|g0|r0|
        "lw              $t2, 0($t2)                 \n" // t2 = |a1|b1|g1|r1|
        "lw              $t3, 0($t3)                 \n" // t3 = |a0|b0|g0|r0|
        "lw              $t4, 0($t4)                 \n" // t4 = |a1|b1|g1|r1|
        "precrq.qb.ph    $t5, $t2, $t1               \n" // t5 = |a1|g1|a0|g0|
        "precr.qb.ph     $t6, $t2, $t1               \n" // t6 = |b1|r1|b0|r0|
        "preceu.ph.qbla  $t0, $t5                    \n" // t0 = |0|a1|0|a0|
        "preceu.ph.qbra  $t1, $t5                    \n" // t1 = |0|g1|0|g0|
        "preceu.ph.qbla  $t2, $t6                    \n" // t2 = |0|b1|0|b0|
        "preceu.ph.qbra  $t5, $t6                    \n" // t5 = |0|r1|0|r0|
        "addu            $t6, %[filter_val], %[fy]   \n"
        "ulw             $t7, 0($t6)                 \n" // t7 = |cur_1|cur_0|
        "ulw             $t6, 4($t6)                 \n" // t6 = |cur_3|cur_2|
        "dpa.w.ph        $ac0, $t5, $t7              \n" // (cur*r1)+(cur*r0)
        "dpa.w.ph        $ac1, $t1, $t7              \n" // (cur*g1)+(cur*g0)
        "dpa.w.ph        $ac2, $t2, $t7              \n" // (cur*b1)+(cur*b0)
        "dpa.w.ph        $ac3, $t0, $t7              \n" // (cur*a1)+(cur*a0)
        "precrq.qb.ph    $t5, $t4, $t3               \n" // t5 = |a3|g3|a2|g2|
        "precr.qb.ph     $t7, $t4, $t3               \n" // t7 = |b3|r3|b2|r2|
        "preceu.ph.qbla  $t0, $t5                    \n" // t0 = |0|a3|0|a2|
        "preceu.ph.qbra  $t1, $t5                    \n" // t1 = |0|g3|0|g2|
        "preceu.ph.qbla  $t2, $t7                    \n" // t2 = |0|b3|0|b2|
        "preceu.ph.qbra  $t5, $t7                    \n" // t5 = |0|r3|0|r2|
        "dpa.w.ph        $ac0, $t5, $t6              \n" // (cur*r3)+(cur*r2)
        "dpa.w.ph        $ac1, $t1, $t6              \n" // (cur*g3)+(cur*g2)
        "dpa.w.ph        $ac2, $t2, $t6              \n" // (cur*b3)+(cur*b2)
        "dpa.w.ph        $ac3, $t0, $t6              \n" // (cur*a3)+(cur*a2)
        "addiu           %[cnt], %[cnt], -1          \n"
        "bgtz            %[cnt], 11b                 \n"
        " addiu          %[fy], %[fy], 8             \n"

        "2:                                          \n"
        "andi            %[cnt], %[filter_len], 0x3  \n" // residual
        "beqz            %[cnt], 3f                  \n"
        " nop                                        \n"

        "21:                                         \n"
        "addu            $t0, %[filter_val], %[fy]   \n"
        "lh              $t4, 0($t0)                 \n" // t4=filter_val[fx]
        "sll             $t1, %[fy], 1               \n"
        "addu            $t0, %[src_data_rows], $t1  \n"
        "lw              $t1, 0($t0)                 \n"
        "addu            $t0, $t1, %[offset]         \n"
        "lbu             $t1, 0($t0)                 \n" // t1 = row[fx*4 + 0]
        "lbu             $t2, 1($t0)                 \n" // t2 = row[fx*4 + 1]
        "lbu             $t3, 2($t0)                 \n" // t3 = row[fx*4 + 2]
        "lbu             $t0, 3($t0)                 \n" // t4 = row[fx*4 + 2]
        "maddu           $ac0, $t4, $t1              \n"
        "maddu           $ac1, $t4, $t2              \n"
        "maddu           $ac2, $t4, $t3              \n"
        "maddu           $ac3, $t4, $t0              \n"
        "addiu           %[cnt], %[cnt], -1          \n"
        "bgtz            %[cnt], 21b                 \n"
        " addiu          %[fy], %[fy], 2             \n"

        "3:                                          \n"
        "extrv.w         $t3, $ac0, %[kShiftBits]    \n" // a >> kShiftBits
        "extrv.w         $t2, $ac1, %[kShiftBits]    \n" // b >> kShiftBits
        "extrv.w         $t1, $ac2, %[kShiftBits]    \n" // g >> kShiftBits
        "extrv.w         $t0, $ac3, %[kShiftBits]    \n" // r >> kShiftBits
        "repl.ph         $t4, 128                    \n" // t4 = | 128 | 128 |
        "addu            $t5, %[out_row], %[offset]  \n"
        "append          $t2, $t3, 16                \n" // t2 = |0|g|0|r|
        "append          $t0, $t1, 16                \n" // t0 = |0|a|0|b|
        "subu.ph         $t1, $t0, $t4               \n"
        "shll_s.ph       $t1, $t1, 8                 \n"
        "shra.ph         $t1, $t1, 8                 \n"
        "addu.ph         $t1, $t1, $t4               \n" // Clamp(a)|Clamp(b)
        "subu.ph         $t2, $t2, $t4               \n"
        "shll_s.ph       $t2, $t2, 8                 \n"
        "shra.ph         $t2, $t2, 8                 \n"
        "addu.ph         $t2, $t2, $t4               \n" // Clamp(g)|Clamp(r)
        "andi            $t3, $t1, 0xFF              \n" // t3 = ClampTo8(b)
        "cmp.lt.ph       $t3, $t2                    \n" // cmp b, g, r
        "pick.ph         $t0, $t2, $t3               \n"
        "andi            $t3, $t0, 0xFF              \n"
        "srl             $t4, $t0, 16                \n"
        "cmp.lt.ph       $t3, $t4                    \n"
        "pick.ph         $t0, $t4, $t3               \n" // t0 = max_color_ch
        "srl             $t3, $t1, 16                \n" // t1 = ClampTo8(a)
        "cmp.lt.ph       $t3, $t0                    \n"
        "pick.ph         $t0, $t0, $t3               \n"
        "ins             $t1, $t0, 16, 8             \n"
        "precr.qb.ph     $t0, $t1, $t2               \n" // t0 = |a|b|g|r|
        "usw             $t0, 0($t5)                 \n"

        ".set pop                                    \n"
      : [filter_val] "+r" (filter_val), [filter_len] "+r" (filter_length),
        [offset] "+r" (byte_offset), [fy] "+r" (filter_y), [cnt] "+r" (cnt),
        [out_x] "+r" (out_x), [pixel_width] "+r" (pixel_width)
      : [src_data_rows] "r" (source_data_rows), [out_row] "r" (out_row),
        [kShiftBits] "r" (ConvolutionFilter1D::kShiftBits)
      : "lo", "hi", "$ac1lo", "$ac1hi", "$ac2lo", "$ac2hi", "$ac3lo", "$ac3hi",
        "t0", "t1", "t2", "t3", "t4", "t5", "t6","t7", "memory"
      );
    }
  } else {
    for (int out_x = 0; out_x < pixel_width; out_x++) {
      __asm__ __volatile__ (
        ".set push                                   \n"
        ".set noreorder                              \n"

        "beqz            %[filter_len], 3f           \n"
        " sll            %[offset], %[out_x], 2      \n"
        "mtlo            $0, $ac0                    \n"
        "mtlo            $0, $ac1                    \n"
        "mtlo            $0, $ac2                    \n"
        "srl             %[cnt], %[filter_len], 2    \n"
        "beqz            %[cnt], 2f                  \n"
        " li             %[fy], 0                    \n"

        "11:                                         \n"
        "sll             $t1, %[fy], 1               \n"
        "addu            $t0, %[src_data_rows], $t1  \n"
        "lw              $t1, 0($t0)                 \n"
        "lw              $t2, 4($t0)                 \n"
        "lw              $t3, 8($t0)                 \n"
        "lw              $t4, 12($t0)                \n"
        "addu            $t1, $t1, %[offset]         \n"
        "addu            $t2, $t2, %[offset]         \n"
        "addu            $t3, $t3, %[offset]         \n"
        "addu            $t4, $t4, %[offset]         \n"
        "lw              $t1, 0($t1)                 \n" // t1 = |a0|b0|g0|r0|
        "lw              $t2, 0($t2)                 \n" // t2 = |a1|b1|g1|r1|
        "lw              $t3, 0($t3)                 \n" // t3 = |a0|b0|g0|r0|
        "lw              $t4, 0($t4)                 \n" // t4 = |a1|b1|g1|r1|
        "precrq.qb.ph    $t5, $t2, $t1               \n" // t5 = |a1|g1|a0|g0|
        "precr.qb.ph     $t6, $t2, $t1               \n" // t6 = |b1|r1|b0|r0|
        "preceu.ph.qbra  $t1, $t5                    \n" // t1 = |0|g1|0|g0|
        "preceu.ph.qbla  $t2, $t6                    \n" // t2 = |0|b1|0|b0|
        "preceu.ph.qbra  $t5, $t6                    \n" // t5 = |0|r1|0|r0|
        "addu            $t6, %[filter_val], %[fy]   \n"
        "ulw             $t0, 0($t6)                 \n" // t0 = |cur_1|cur_0|
        "ulw             $t6, 4($t6)                 \n" // t6 = |cur_1|cur_0|
        "dpa.w.ph        $ac0, $t5, $t0              \n" // (cur*r1)+(cur*r0)
        "dpa.w.ph        $ac1, $t1, $t0              \n" // (cur*g1)+(cur*g0)
        "dpa.w.ph        $ac2, $t2, $t0              \n" // (cur*b1)+(cur*b0)
        "precrq.qb.ph    $t5, $t4, $t3               \n" // t5 = |a3|g3|a2|g2|
        "precr.qb.ph     $t0, $t4, $t3               \n" // t0 = |b3|r3|b2|r2|
        "preceu.ph.qbra  $t1, $t5                    \n" // t1 = |0|g3|0|g2|
        "preceu.ph.qbla  $t2, $t0                    \n" // t2 = |0|b3|0|b2|
        "preceu.ph.qbra  $t5, $t0                    \n" // t5 = |0|r3|0|r2|
        "dpa.w.ph        $ac0, $t5, $t6              \n" // (cur*r1)+(cur*r0)
        "dpa.w.ph        $ac1, $t1, $t6              \n" // (cur*g1)+(cur*g0)
        "dpa.w.ph        $ac2, $t2, $t6              \n" // (cur*b1)+(cur*b0)
        "addiu           %[cnt], %[cnt], -1          \n"
        "bgtz            %[cnt], 11b                 \n"
        " addiu          %[fy], %[fy], 8             \n"

        "2:                                          \n"
        "andi            %[cnt], %[filter_len], 0x3  \n" // residual
        "beqz            %[cnt], 3f                  \n"
        " nop                                        \n"

        "21:                                         \n"
        "addu            $t0, %[filter_val], %[fy]   \n"
        "lh              $t4, 0($t0)                 \n" // filter_val[fx]
        "sll             $t1, %[fy], 1               \n"
        "addu            $t0, %[src_data_rows], $t1  \n"
        "lw              $t1, 0($t0)                 \n"
        "addu            $t0, $t1, %[offset]         \n"
        "lbu             $t1, 0($t0)                 \n" // t1 = row[fx*4 + 0]
        "lbu             $t2, 1($t0)                 \n" // t2 = row[fx*4 + 1]
        "lbu             $t3, 2($t0)                 \n" // t3 = row[fx*4 + 2]
        "maddu           $ac0, $t4, $t1              \n"
        "maddu           $ac1, $t4, $t2              \n"
        "maddu           $ac2, $t4, $t3              \n"
        "addiu           %[cnt], %[cnt], -1          \n"
        "bgtz            %[cnt], 21b                 \n"
        " addiu          %[fy], %[fy], 2             \n"

        "3:                                          \n"
        "extrv.w         $t3, $ac0, %[kShiftBits]    \n" // r >> kShiftBits
        "extrv.w         $t2, $ac1, %[kShiftBits]    \n" // g >> kShiftBits
        "extrv.w         $t1, $ac2, %[kShiftBits]    \n" // b >> kShiftBits
        "repl.ph         $t6, 128                    \n" // t6 = | 128 | 128 |
        "addu            $t5, %[out_row], %[offset]  \n"
        "append          $t2, $t3, 16                \n" // t2 = |0|g|0|r|
        "andi            $t1, $t1, 0xFFFF            \n"
        "subu.ph         $t1, $t1, $t6               \n"
        "shll_s.ph       $t1, $t1, 8                 \n"
        "shra.ph         $t1, $t1, 8                 \n"
        "addu.ph         $t1, $t1, $t6               \n" // Clamp(a)|Clamp(b)
        "subu.ph         $t2, $t2, $t6               \n"
        "shll_s.ph       $t2, $t2, 8                 \n"
        "shra.ph         $t2, $t2, 8                 \n"
        "addu.ph         $t2, $t2, $t6               \n" // Clamp(g)|Clamp(r)
        "li              $t0, 0xFF                   \n"
        "ins             $t1, $t0, 16, 8             \n"
        "precr.qb.ph     $t0, $t1, $t2               \n" // t0 = |a|b|g|r|
        "usw             $t0, 0($t5)                 \n"

        ".set pop                                    \n"
      : [filter_val] "+r" (filter_val), [filter_len] "+r" (filter_length),
        [offset] "+r" (byte_offset), [fy] "+r" (filter_y), [cnt] "+r" (cnt),
        [out_x] "+r" (out_x), [pixel_width] "+r" (pixel_width)
      : [src_data_rows] "r" (source_data_rows), [out_row] "r" (out_row),
        [kShiftBits] "r" (ConvolutionFilter1D::kShiftBits)
      : "lo", "hi", "$ac1lo", "$ac1hi", "$ac2lo", "$ac2hi", "$ac3lo", "$ac3hi",
        "t0", "t1", "t2", "t3", "t4", "t5", "t6", "memory"
      );
    }
  }
#endif
}
} // namespace skia
