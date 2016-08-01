
/* filter_neon_intrinsics.c - NEON optimised filter functions
 *
 * Copyright (c) 2014,2016 Glenn Randers-Pehrson
 * Written by James Yu <james.yu at linaro.org>, October 2013.
 * Based on filter_neon.S, written by Mans Rullgard, 2011.
 *
 * Last changed in libpng 1.6.22 [(PENDING RELEASE)]
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

#include "../pngpriv.h"

#ifdef PNG_READ_SUPPORTED

/* This code requires -mfpu=neon on the command line: */
#if PNG_ARM_NEON_IMPLEMENTATION == 1 /* intrinsics code from pngpriv.h */

#include <arm_neon.h>

/* libpng row pointers are not necessarily aligned to any particular boundary,
 * however this code will only work with appropriate alignment.  arm/arm_init.c
 * checks for this (and will not compile unless it is done). This code uses
 * variants of png_aligncast to avoid compiler warnings.
 */
#define png_ptr(type,pointer) png_aligncast(type *,pointer)
#define png_ptrc(type,pointer) png_aligncastconst(const type *,pointer)

/* The following relies on a variable 'temp_pointer' being declared with type
 * 'type'.  This is written this way just to hide the GCC strict aliasing
 * warning; note that the code is safe because there never is an alias between
 * the input and output pointers.
 */
#define png_ldr(type,pointer)\
   (temp_pointer = png_ptr(type,pointer), *temp_pointer)

#if PNG_ARM_NEON_OPT > 0

void
png_read_filter_row_up_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_bytep rp_stop = row + row_info->rowbytes;
   png_const_bytep pp = prev_row;

   png_debug(1, "in png_read_filter_row_up_neon");

   for (; rp < rp_stop; rp += 16, pp += 16)
   {
      uint8x16_t qrp, qpp;

      qrp = vld1q_u8(rp);
      qpp = vld1q_u8(pp);
      qrp = vaddq_u8(qrp, qpp);
      vst1q_u8(rp, qrp);
   }
}

void
png_read_filter_row_sub3_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_bytep rp_stop = row + row_info->rowbytes;

   uint8x16_t vtmp = vld1q_u8(rp);
   uint8x8x2_t *vrpt = png_ptr(uint8x8x2_t, &vtmp);
   uint8x8x2_t vrp = *vrpt;

   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   png_debug(1, "in png_read_filter_row_sub3_neon");

   for (; rp < rp_stop;)
   {
      uint8x8_t vtmp1, vtmp2;
      uint32x2_t *temp_pointer;

      vtmp1 = vext_u8(vrp.val[0], vrp.val[1], 3);
      vdest.val[0] = vadd_u8(vdest.val[3], vrp.val[0]);
      vtmp2 = vext_u8(vrp.val[0], vrp.val[1], 6);
      vdest.val[1] = vadd_u8(vdest.val[0], vtmp1);

      vtmp1 = vext_u8(vrp.val[1], vrp.val[1], 1);
      vdest.val[2] = vadd_u8(vdest.val[1], vtmp2);
      vdest.val[3] = vadd_u8(vdest.val[2], vtmp1);

      vtmp = vld1q_u8(rp + 12);
      vrpt = png_ptr(uint8x8x2_t, &vtmp);
      vrp = *vrpt;

      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[0]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[1]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[2]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[3]), 0);
      rp += 3;
   }

   PNG_UNUSED(prev_row)
}

void
png_read_filter_row_sub4_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_bytep rp_stop = row + row_info->rowbytes;

   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   png_debug(1, "in png_read_filter_row_sub4_neon");

   for (; rp < rp_stop; rp += 16)
   {
      uint32x2x4_t vtmp = vld4_u32(png_ptr(uint32_t,rp));
      uint8x8x4_t *vrpt = png_ptr(uint8x8x4_t,&vtmp);
      uint8x8x4_t vrp = *vrpt;
      uint32x2x4_t *temp_pointer;

      vdest.val[0] = vadd_u8(vdest.val[3], vrp.val[0]);
      vdest.val[1] = vadd_u8(vdest.val[0], vrp.val[1]);
      vdest.val[2] = vadd_u8(vdest.val[1], vrp.val[2]);
      vdest.val[3] = vadd_u8(vdest.val[2], vrp.val[3]);
      vst4_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2x4_t,&vdest), 0);
   }

   PNG_UNUSED(prev_row)
}

void
png_read_filter_row_avg3_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_const_bytep pp = prev_row;
   png_bytep rp_stop = row + row_info->rowbytes;

   uint8x16_t vtmp;
   uint8x8x2_t *vrpt;
   uint8x8x2_t vrp;
   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   vtmp = vld1q_u8(rp);
   vrpt = png_ptr(uint8x8x2_t,&vtmp);
   vrp = *vrpt;

   png_debug(1, "in png_read_filter_row_avg3_neon");

   for (; rp < rp_stop; pp += 12)
   {
      uint8x8_t vtmp1, vtmp2, vtmp3;

      uint8x8x2_t *vppt;
      uint8x8x2_t vpp;

      uint32x2_t *temp_pointer;

      vtmp = vld1q_u8(pp);
      vppt = png_ptr(uint8x8x2_t,&vtmp);
      vpp = *vppt;

      vtmp1 = vext_u8(vrp.val[0], vrp.val[1], 3);
      vdest.val[0] = vhadd_u8(vdest.val[3], vpp.val[0]);
      vdest.val[0] = vadd_u8(vdest.val[0], vrp.val[0]);

      vtmp2 = vext_u8(vpp.val[0], vpp.val[1], 3);
      vtmp3 = vext_u8(vrp.val[0], vrp.val[1], 6);
      vdest.val[1] = vhadd_u8(vdest.val[0], vtmp2);
      vdest.val[1] = vadd_u8(vdest.val[1], vtmp1);

      vtmp2 = vext_u8(vpp.val[0], vpp.val[1], 6);
      vtmp1 = vext_u8(vrp.val[1], vrp.val[1], 1);

      vtmp = vld1q_u8(rp + 12);
      vrpt = png_ptr(uint8x8x2_t,&vtmp);
      vrp = *vrpt;

      vdest.val[2] = vhadd_u8(vdest.val[1], vtmp2);
      vdest.val[2] = vadd_u8(vdest.val[2], vtmp3);

      vtmp2 = vext_u8(vpp.val[1], vpp.val[1], 1);

      vdest.val[3] = vhadd_u8(vdest.val[2], vtmp2);
      vdest.val[3] = vadd_u8(vdest.val[3], vtmp1);

      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[0]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[1]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[2]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[3]), 0);
      rp += 3;
   }
}

void
png_read_filter_row_avg4_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_bytep rp_stop = row + row_info->rowbytes;
   png_const_bytep pp = prev_row;

   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   png_debug(1, "in png_read_filter_row_avg4_neon");

   for (; rp < rp_stop; rp += 16, pp += 16)
   {
      uint32x2x4_t vtmp;
      uint8x8x4_t *vrpt, *vppt;
      uint8x8x4_t vrp, vpp;
      uint32x2x4_t *temp_pointer;

      vtmp = vld4_u32(png_ptr(uint32_t,rp));
      vrpt = png_ptr(uint8x8x4_t,&vtmp);
      vrp = *vrpt;
      vtmp = vld4_u32(png_ptrc(uint32_t,pp));
      vppt = png_ptr(uint8x8x4_t,&vtmp);
      vpp = *vppt;

      vdest.val[0] = vhadd_u8(vdest.val[3], vpp.val[0]);
      vdest.val[0] = vadd_u8(vdest.val[0], vrp.val[0]);
      vdest.val[1] = vhadd_u8(vdest.val[0], vpp.val[1]);
      vdest.val[1] = vadd_u8(vdest.val[1], vrp.val[1]);
      vdest.val[2] = vhadd_u8(vdest.val[1], vpp.val[2]);
      vdest.val[2] = vadd_u8(vdest.val[2], vrp.val[2]);
      vdest.val[3] = vhadd_u8(vdest.val[2], vpp.val[3]);
      vdest.val[3] = vadd_u8(vdest.val[3], vrp.val[3]);

      vst4_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2x4_t,&vdest), 0);
   }
}

static uint8x8_t
paeth(uint8x8_t a, uint8x8_t b, uint8x8_t c)
{
   uint8x8_t d, e;
   uint16x8_t p1, pa, pb, pc;

   p1 = vaddl_u8(a, b); /* a + b */
   pc = vaddl_u8(c, c); /* c * 2 */
   pa = vabdl_u8(b, c); /* pa */
   pb = vabdl_u8(a, c); /* pb */
   pc = vabdq_u16(p1, pc); /* pc */

   p1 = vcleq_u16(pa, pb); /* pa <= pb */
   pa = vcleq_u16(pa, pc); /* pa <= pc */
   pb = vcleq_u16(pb, pc); /* pb <= pc */

   p1 = vandq_u16(p1, pa); /* pa <= pb && pa <= pc */

   d = vmovn_u16(pb);
   e = vmovn_u16(p1);

   d = vbsl_u8(d, b, c);
   e = vbsl_u8(e, a, d);

   return e;
}

void
png_read_filter_row_paeth3_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_const_bytep pp = prev_row;
   png_bytep rp_stop = row + row_info->rowbytes;

   uint8x16_t vtmp;
   uint8x8x2_t *vrpt;
   uint8x8x2_t vrp;
   uint8x8_t vlast = vdup_n_u8(0);
   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   vtmp = vld1q_u8(rp);
   vrpt = png_ptr(uint8x8x2_t,&vtmp);
   vrp = *vrpt;

   png_debug(1, "in png_read_filter_row_paeth3_neon");

   for (; rp < rp_stop; pp += 12)
   {
      uint8x8x2_t *vppt;
      uint8x8x2_t vpp;
      uint8x8_t vtmp1, vtmp2, vtmp3;
      uint32x2_t *temp_pointer;

      vtmp = vld1q_u8(pp);
      vppt = png_ptr(uint8x8x2_t,&vtmp);
      vpp = *vppt;

      vdest.val[0] = paeth(vdest.val[3], vpp.val[0], vlast);
      vdest.val[0] = vadd_u8(vdest.val[0], vrp.val[0]);

      vtmp1 = vext_u8(vrp.val[0], vrp.val[1], 3);
      vtmp2 = vext_u8(vpp.val[0], vpp.val[1], 3);
      vdest.val[1] = paeth(vdest.val[0], vtmp2, vpp.val[0]);
      vdest.val[1] = vadd_u8(vdest.val[1], vtmp1);

      vtmp1 = vext_u8(vrp.val[0], vrp.val[1], 6);
      vtmp3 = vext_u8(vpp.val[0], vpp.val[1], 6);
      vdest.val[2] = paeth(vdest.val[1], vtmp3, vtmp2);
      vdest.val[2] = vadd_u8(vdest.val[2], vtmp1);

      vtmp1 = vext_u8(vrp.val[1], vrp.val[1], 1);
      vtmp2 = vext_u8(vpp.val[1], vpp.val[1], 1);

      vtmp = vld1q_u8(rp + 12);
      vrpt = png_ptr(uint8x8x2_t,&vtmp);
      vrp = *vrpt;

      vdest.val[3] = paeth(vdest.val[2], vtmp2, vtmp3);
      vdest.val[3] = vadd_u8(vdest.val[3], vtmp1);

      vlast = vtmp2;

      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[0]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[1]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[2]), 0);
      rp += 3;
      vst1_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2_t,&vdest.val[3]), 0);
      rp += 3;
   }
}

void
png_read_filter_row_paeth4_neon(png_row_infop row_info, png_bytep row,
   png_const_bytep prev_row)
{
   png_bytep rp = row;
   png_bytep rp_stop = row + row_info->rowbytes;
   png_const_bytep pp = prev_row;

   uint8x8_t vlast = vdup_n_u8(0);
   uint8x8x4_t vdest;
   vdest.val[3] = vdup_n_u8(0);

   png_debug(1, "in png_read_filter_row_paeth4_neon");

   for (; rp < rp_stop; rp += 16, pp += 16)
   {
      uint32x2x4_t vtmp;
      uint8x8x4_t *vrpt, *vppt;
      uint8x8x4_t vrp, vpp;
      uint32x2x4_t *temp_pointer;

      vtmp = vld4_u32(png_ptr(uint32_t,rp));
      vrpt = png_ptr(uint8x8x4_t,&vtmp);
      vrp = *vrpt;
      vtmp = vld4_u32(png_ptrc(uint32_t,pp));
      vppt = png_ptr(uint8x8x4_t,&vtmp);
      vpp = *vppt;

      vdest.val[0] = paeth(vdest.val[3], vpp.val[0], vlast);
      vdest.val[0] = vadd_u8(vdest.val[0], vrp.val[0]);
      vdest.val[1] = paeth(vdest.val[0], vpp.val[1], vpp.val[0]);
      vdest.val[1] = vadd_u8(vdest.val[1], vrp.val[1]);
      vdest.val[2] = paeth(vdest.val[1], vpp.val[2], vpp.val[1]);
      vdest.val[2] = vadd_u8(vdest.val[2], vrp.val[2]);
      vdest.val[3] = paeth(vdest.val[2], vpp.val[3], vpp.val[2]);
      vdest.val[3] = vadd_u8(vdest.val[3], vrp.val[3]);

      vlast = vpp.val[3];

      vst4_lane_u32(png_ptr(uint32_t,rp), png_ldr(uint32x2x4_t,&vdest), 0);
   }
}

#endif /* PNG_ARM_NEON_OPT > 0 */
#endif /* PNG_ARM_NEON_IMPLEMENTATION == 1 (intrinsics) */
#endif /* READ */
