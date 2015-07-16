/*
 * jidctred.c
 *
 * Copyright (C) 1994-1998, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains inverse-DCT routines that produce reduced-size output:
 * either 4x4, 2x2, or 1x1 pixels from an 8x8 DCT block.
 *
 * The implementation is based on the Loeffler, Ligtenberg and Moschytz (LL&M)
 * algorithm used in jidctint.c.  We simply replace each 8-to-8 1-D IDCT step
 * with an 8-to-4 step that produces the four averages of two adjacent outputs
 * (or an 8-to-2 step producing two averages of four outputs, for 2x2 output).
 * These steps were derived by computing the corresponding values at the end
 * of the normal LL&M code, then simplifying as much as possible.
 *
 * 1x1 is trivial: just take the DC coefficient divided by 8.
 *
 * See jidctint.c for additional comments.
 */

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"
#include "jdct.h"		/* Private declarations for DCT subsystem */

#ifdef IDCT_SCALING_SUPPORTED


/*
 * This module is specialized to the case DCTSIZE = 8.
 */

#if DCTSIZE != 8
  Sorry, this code only copes with 8x8 DCTs. /* deliberate syntax err */
#endif


/* Scaling is the same as in jidctint.c. */

#if BITS_IN_JSAMPLE == 8
#define CONST_BITS  13
#define PASS1_BITS  2
#else
#define CONST_BITS  13
#define PASS1_BITS  1		/* lose a little precision to avoid overflow */
#endif

/* Some C compilers fail to reduce "FIX(constant)" at compile time, thus
 * causing a lot of useless floating-point operations at run time.
 * To get around this we use the following pre-calculated constants.
 * If you change CONST_BITS you may want to add appropriate values.
 * (With a reasonable C compiler, you can just rely on the FIX() macro...)
 */

#if CONST_BITS == 13
#define FIX_0_211164243  ((INT32)  1730)	/* FIX(0.211164243) */
#define FIX_0_509795579  ((INT32)  4176)	/* FIX(0.509795579) */
#define FIX_0_601344887  ((INT32)  4926)	/* FIX(0.601344887) */
#define FIX_0_720959822  ((INT32)  5906)	/* FIX(0.720959822) */
#define FIX_0_765366865  ((INT32)  6270)	/* FIX(0.765366865) */
#define FIX_0_850430095  ((INT32)  6967)	/* FIX(0.850430095) */
#define FIX_0_899976223  ((INT32)  7373)	/* FIX(0.899976223) */
#define FIX_1_061594337  ((INT32)  8697)	/* FIX(1.061594337) */
#define FIX_1_272758580  ((INT32)  10426)	/* FIX(1.272758580) */
#define FIX_1_451774981  ((INT32)  11893)	/* FIX(1.451774981) */
#define FIX_1_847759065  ((INT32)  15137)	/* FIX(1.847759065) */
#define FIX_2_172734803  ((INT32)  17799)	/* FIX(2.172734803) */
#define FIX_2_562915447  ((INT32)  20995)	/* FIX(2.562915447) */
#define FIX_3_624509785  ((INT32)  29692)	/* FIX(3.624509785) */
#else
#define FIX_0_211164243  FIX(0.211164243)
#define FIX_0_509795579  FIX(0.509795579)
#define FIX_0_601344887  FIX(0.601344887)
#define FIX_0_720959822  FIX(0.720959822)
#define FIX_0_765366865  FIX(0.765366865)
#define FIX_0_850430095  FIX(0.850430095)
#define FIX_0_899976223  FIX(0.899976223)
#define FIX_1_061594337  FIX(1.061594337)
#define FIX_1_272758580  FIX(1.272758580)
#define FIX_1_451774981  FIX(1.451774981)
#define FIX_1_847759065  FIX(1.847759065)
#define FIX_2_172734803  FIX(2.172734803)
#define FIX_2_562915447  FIX(2.562915447)
#define FIX_3_624509785  FIX(3.624509785)
#endif


/* Multiply an INT32 variable by an INT32 constant to yield an INT32 result.
 * For 8-bit samples with the recommended scaling, all the variable
 * and constant values involved are no more than 16 bits wide, so a
 * 16x16->32 bit multiply can be used instead of a full 32x32 multiply.
 * For 12-bit samples, a full 32-bit multiplication will be needed.
 */

#if BITS_IN_JSAMPLE == 8
#define MULTIPLY(var,const)  MULTIPLY16C16(var,const)
#else
#define MULTIPLY(var,const)  ((var) * (const))
#endif


/* Dequantize a coefficient by multiplying it by the multiplier-table
 * entry; produce an int result.  In this module, both inputs and result
 * are 16 bits or less, so either int or short multiply will work.
 */

#define DEQUANTIZE(coef,quantval)  (((ISLOW_MULT_TYPE) (coef)) * (quantval))


/*
 * Perform dequantization and inverse DCT on one block of coefficients,
 * producing a reduced-size 4x4 output block.
 */

GLOBAL(void)
jpeg_idct_4x4 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
	       JCOEFPTR coef_block,
	       JSAMPARRAY output_buf, JDIMENSION output_col)
{
  INT32 tmp0, tmp2, tmp10, tmp12;
  INT32 z1, z2, z3, z4;
  JCOEFPTR inptr;
  ISLOW_MULT_TYPE * quantptr;
  int * wsptr;
  JSAMPROW outptr;
  JSAMPLE *range_limit = IDCT_range_limit(cinfo);
  int ctr;
  int workspace[DCTSIZE*4];	/* buffers data between passes */
  SHIFT_TEMPS

  /* Pass 1: process columns from input, store into work array. */

  inptr = coef_block;
  quantptr = (ISLOW_MULT_TYPE *) compptr->dct_table;
  wsptr = workspace;
  for (ctr = DCTSIZE; ctr > 0; inptr++, quantptr++, wsptr++, ctr--) {
    /* Don't bother to process column 4, because second pass won't use it */
    if (ctr == DCTSIZE-4)
      continue;
    if (inptr[DCTSIZE*1] == 0 && inptr[DCTSIZE*2] == 0 &&
	inptr[DCTSIZE*3] == 0 && inptr[DCTSIZE*5] == 0 &&
	inptr[DCTSIZE*6] == 0 && inptr[DCTSIZE*7] == 0) {
      /* AC terms all zero; we need not examine term 4 for 4x4 output */
      int dcval = DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]) << PASS1_BITS;
      
      wsptr[DCTSIZE*0] = dcval;
      wsptr[DCTSIZE*1] = dcval;
      wsptr[DCTSIZE*2] = dcval;
      wsptr[DCTSIZE*3] = dcval;
      
      continue;
    }
    
    /* Even part */
    
    tmp0 = DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]);
    tmp0 <<= (CONST_BITS+1);
    
    z2 = DEQUANTIZE(inptr[DCTSIZE*2], quantptr[DCTSIZE*2]);
    z3 = DEQUANTIZE(inptr[DCTSIZE*6], quantptr[DCTSIZE*6]);

    tmp2 = MULTIPLY(z2, FIX_1_847759065) + MULTIPLY(z3, - FIX_0_765366865);
    
    tmp10 = tmp0 + tmp2;
    tmp12 = tmp0 - tmp2;
    
    /* Odd part */
    
    z1 = DEQUANTIZE(inptr[DCTSIZE*7], quantptr[DCTSIZE*7]);
    z2 = DEQUANTIZE(inptr[DCTSIZE*5], quantptr[DCTSIZE*5]);
    z3 = DEQUANTIZE(inptr[DCTSIZE*3], quantptr[DCTSIZE*3]);
    z4 = DEQUANTIZE(inptr[DCTSIZE*1], quantptr[DCTSIZE*1]);
    
    tmp0 = MULTIPLY(z1, - FIX_0_211164243) /* sqrt(2) * (c3-c1) */
	 + MULTIPLY(z2, FIX_1_451774981) /* sqrt(2) * (c3+c7) */
	 + MULTIPLY(z3, - FIX_2_172734803) /* sqrt(2) * (-c1-c5) */
	 + MULTIPLY(z4, FIX_1_061594337); /* sqrt(2) * (c5+c7) */
    
    tmp2 = MULTIPLY(z1, - FIX_0_509795579) /* sqrt(2) * (c7-c5) */
	 + MULTIPLY(z2, - FIX_0_601344887) /* sqrt(2) * (c5-c1) */
	 + MULTIPLY(z3, FIX_0_899976223) /* sqrt(2) * (c3-c7) */
	 + MULTIPLY(z4, FIX_2_562915447); /* sqrt(2) * (c1+c3) */

    /* Final output stage */
    
    wsptr[DCTSIZE*0] = (int) DESCALE(tmp10 + tmp2, CONST_BITS-PASS1_BITS+1);
    wsptr[DCTSIZE*3] = (int) DESCALE(tmp10 - tmp2, CONST_BITS-PASS1_BITS+1);
    wsptr[DCTSIZE*1] = (int) DESCALE(tmp12 + tmp0, CONST_BITS-PASS1_BITS+1);
    wsptr[DCTSIZE*2] = (int) DESCALE(tmp12 - tmp0, CONST_BITS-PASS1_BITS+1);
  }
  
  /* Pass 2: process 4 rows from work array, store into output array. */

  wsptr = workspace;
  for (ctr = 0; ctr < 4; ctr++) {
    outptr = output_buf[ctr] + output_col;
    /* It's not clear whether a zero row test is worthwhile here ... */

#ifndef NO_ZERO_ROW_TEST
    if (wsptr[1] == 0 && wsptr[2] == 0 && wsptr[3] == 0 &&
	wsptr[5] == 0 && wsptr[6] == 0 && wsptr[7] == 0) {
      /* AC terms all zero */
      JSAMPLE dcval = range_limit[(int) DESCALE((INT32) wsptr[0], PASS1_BITS+3)
				  & RANGE_MASK];
      
      outptr[0] = dcval;
      outptr[1] = dcval;
      outptr[2] = dcval;
      outptr[3] = dcval;
      
      wsptr += DCTSIZE;		/* advance pointer to next row */
      continue;
    }
#endif
    
    /* Even part */
    
    tmp0 = ((INT32) wsptr[0]) << (CONST_BITS+1);
    
    tmp2 = MULTIPLY((INT32) wsptr[2], FIX_1_847759065)
	 + MULTIPLY((INT32) wsptr[6], - FIX_0_765366865);
    
    tmp10 = tmp0 + tmp2;
    tmp12 = tmp0 - tmp2;
    
    /* Odd part */
    
    z1 = (INT32) wsptr[7];
    z2 = (INT32) wsptr[5];
    z3 = (INT32) wsptr[3];
    z4 = (INT32) wsptr[1];
    
    tmp0 = MULTIPLY(z1, - FIX_0_211164243) /* sqrt(2) * (c3-c1) */
	 + MULTIPLY(z2, FIX_1_451774981) /* sqrt(2) * (c3+c7) */
	 + MULTIPLY(z3, - FIX_2_172734803) /* sqrt(2) * (-c1-c5) */
	 + MULTIPLY(z4, FIX_1_061594337); /* sqrt(2) * (c5+c7) */
    
    tmp2 = MULTIPLY(z1, - FIX_0_509795579) /* sqrt(2) * (c7-c5) */
	 + MULTIPLY(z2, - FIX_0_601344887) /* sqrt(2) * (c5-c1) */
	 + MULTIPLY(z3, FIX_0_899976223) /* sqrt(2) * (c3-c7) */
	 + MULTIPLY(z4, FIX_2_562915447); /* sqrt(2) * (c1+c3) */

    /* Final output stage */
    
    outptr[0] = range_limit[(int) DESCALE(tmp10 + tmp2,
					  CONST_BITS+PASS1_BITS+3+1)
			    & RANGE_MASK];
    outptr[3] = range_limit[(int) DESCALE(tmp10 - tmp2,
					  CONST_BITS+PASS1_BITS+3+1)
			    & RANGE_MASK];
    outptr[1] = range_limit[(int) DESCALE(tmp12 + tmp0,
					  CONST_BITS+PASS1_BITS+3+1)
			    & RANGE_MASK];
    outptr[2] = range_limit[(int) DESCALE(tmp12 - tmp0,
					  CONST_BITS+PASS1_BITS+3+1)
			    & RANGE_MASK];
    
    wsptr += DCTSIZE;		/* advance pointer to next row */
  }
}


/*
 * Perform dequantization and inverse DCT on one block of coefficients,
 * producing a reduced-size 2x2 output block.
 */

GLOBAL(void)
jpeg_idct_2x2 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
	       JCOEFPTR coef_block,
	       JSAMPARRAY output_buf, JDIMENSION output_col)
{
  INT32 tmp0, tmp10, z1;
  JCOEFPTR inptr;
  ISLOW_MULT_TYPE * quantptr;
  int * wsptr;
  JSAMPROW outptr;
  JSAMPLE *range_limit = IDCT_range_limit(cinfo);
  int ctr;
  int workspace[DCTSIZE*2];	/* buffers data between passes */
  SHIFT_TEMPS

  /* Pass 1: process columns from input, store into work array. */

  inptr = coef_block;
  quantptr = (ISLOW_MULT_TYPE *) compptr->dct_table;
  wsptr = workspace;
  for (ctr = DCTSIZE; ctr > 0; inptr++, quantptr++, wsptr++, ctr--) {
    /* Don't bother to process columns 2,4,6 */
    if (ctr == DCTSIZE-2 || ctr == DCTSIZE-4 || ctr == DCTSIZE-6)
      continue;
    if (inptr[DCTSIZE*1] == 0 && inptr[DCTSIZE*3] == 0 &&
	inptr[DCTSIZE*5] == 0 && inptr[DCTSIZE*7] == 0) {
      /* AC terms all zero; we need not examine terms 2,4,6 for 2x2 output */
      int dcval = DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]) << PASS1_BITS;
      
      wsptr[DCTSIZE*0] = dcval;
      wsptr[DCTSIZE*1] = dcval;
      
      continue;
    }
    
    /* Even part */
    
    z1 = DEQUANTIZE(inptr[DCTSIZE*0], quantptr[DCTSIZE*0]);
    tmp10 = z1 << (CONST_BITS+2);
    
    /* Odd part */

    z1 = DEQUANTIZE(inptr[DCTSIZE*7], quantptr[DCTSIZE*7]);
    tmp0 = MULTIPLY(z1, - FIX_0_720959822); /* sqrt(2) * (c7-c5+c3-c1) */
    z1 = DEQUANTIZE(inptr[DCTSIZE*5], quantptr[DCTSIZE*5]);
    tmp0 += MULTIPLY(z1, FIX_0_850430095); /* sqrt(2) * (-c1+c3+c5+c7) */
    z1 = DEQUANTIZE(inptr[DCTSIZE*3], quantptr[DCTSIZE*3]);
    tmp0 += MULTIPLY(z1, - FIX_1_272758580); /* sqrt(2) * (-c1+c3-c5-c7) */
    z1 = DEQUANTIZE(inptr[DCTSIZE*1], quantptr[DCTSIZE*1]);
    tmp0 += MULTIPLY(z1, FIX_3_624509785); /* sqrt(2) * (c1+c3+c5+c7) */

    /* Final output stage */
    
    wsptr[DCTSIZE*0] = (int) DESCALE(tmp10 + tmp0, CONST_BITS-PASS1_BITS+2);
    wsptr[DCTSIZE*1] = (int) DESCALE(tmp10 - tmp0, CONST_BITS-PASS1_BITS+2);
  }
  
  /* Pass 2: process 2 rows from work array, store into output array. */

  wsptr = workspace;
  for (ctr = 0; ctr < 2; ctr++) {
    outptr = output_buf[ctr] + output_col;
    /* It's not clear whether a zero row test is worthwhile here ... */

#ifndef NO_ZERO_ROW_TEST
    if (wsptr[1] == 0 && wsptr[3] == 0 && wsptr[5] == 0 && wsptr[7] == 0) {
      /* AC terms all zero */
      JSAMPLE dcval = range_limit[(int) DESCALE((INT32) wsptr[0], PASS1_BITS+3)
				  & RANGE_MASK];
      
      outptr[0] = dcval;
      outptr[1] = dcval;
      
      wsptr += DCTSIZE;		/* advance pointer to next row */
      continue;
    }
#endif
    
    /* Even part */
    
    tmp10 = ((INT32) wsptr[0]) << (CONST_BITS+2);
    
    /* Odd part */

    tmp0 = MULTIPLY((INT32) wsptr[7], - FIX_0_720959822) /* sqrt(2) * (c7-c5+c3-c1) */
	 + MULTIPLY((INT32) wsptr[5], FIX_0_850430095) /* sqrt(2) * (-c1+c3+c5+c7) */
	 + MULTIPLY((INT32) wsptr[3], - FIX_1_272758580) /* sqrt(2) * (-c1+c3-c5-c7) */
	 + MULTIPLY((INT32) wsptr[1], FIX_3_624509785); /* sqrt(2) * (c1+c3+c5+c7) */

    /* Final output stage */
    
    outptr[0] = range_limit[(int) DESCALE(tmp10 + tmp0,
					  CONST_BITS+PASS1_BITS+3+2)
			    & RANGE_MASK];
    outptr[1] = range_limit[(int) DESCALE(tmp10 - tmp0,
					  CONST_BITS+PASS1_BITS+3+2)
			    & RANGE_MASK];
    
    wsptr += DCTSIZE;		/* advance pointer to next row */
  }
}


/*
 * Perform dequantization and inverse DCT on one block of coefficients,
 * producing a reduced-size 1x1 output block.
 */

GLOBAL(void)
jpeg_idct_1x1 (j_decompress_ptr cinfo, jpeg_component_info * compptr,
	       JCOEFPTR coef_block,
	       JSAMPARRAY output_buf, JDIMENSION output_col)
{
  int dcval;
  ISLOW_MULT_TYPE * quantptr;
  JSAMPLE *range_limit = IDCT_range_limit(cinfo);
  SHIFT_TEMPS

  /* We hardly need an inverse DCT routine for this: just take the
   * average pixel value, which is one-eighth of the DC coefficient.
   */
  quantptr = (ISLOW_MULT_TYPE *) compptr->dct_table;
  dcval = DEQUANTIZE(coef_block[0], quantptr[0]);
  dcval = (int) DESCALE((INT32) dcval, 3);

  output_buf[0][output_col] = range_limit[dcval & RANGE_MASK];
}

#endif /* IDCT_SCALING_SUPPORTED */
