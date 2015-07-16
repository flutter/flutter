/*
 * jdphuff.c
 *
 * Copyright (C) 1995-1997, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains Huffman entropy decoding routines for progressive JPEG.
 *
 * Much of the complexity here has to do with supporting input suspension.
 * If the data source module demands suspension, we want to be able to back
 * up to the start of the current MCU.  To do this, we copy state variables
 * into local working storage, and update them back to the permanent
 * storage only upon successful completion of an MCU.
 */

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"
#include "jdhuff.h"		/* Declarations shared with jdhuff.c */


#ifdef D_PROGRESSIVE_SUPPORTED

/*
 * Expanded entropy decoder object for progressive Huffman decoding.
 *
 * The savable_state subrecord contains fields that change within an MCU,
 * but must not be updated permanently until we complete the MCU.
 */

typedef struct {
  unsigned int EOBRUN;			/* remaining EOBs in EOBRUN */
  int last_dc_val[MAX_COMPS_IN_SCAN];	/* last DC coef for each component */
} savable_state;

/* This macro is to work around compilers with missing or broken
 * structure assignment.  You'll need to fix this code if you have
 * such a compiler and you change MAX_COMPS_IN_SCAN.
 */

#ifndef NO_STRUCT_ASSIGN
#define ASSIGN_STATE(dest,src)  ((dest) = (src))
#else
#if MAX_COMPS_IN_SCAN == 4
#define ASSIGN_STATE(dest,src)  \
	((dest).EOBRUN = (src).EOBRUN, \
	 (dest).last_dc_val[0] = (src).last_dc_val[0], \
	 (dest).last_dc_val[1] = (src).last_dc_val[1], \
	 (dest).last_dc_val[2] = (src).last_dc_val[2], \
	 (dest).last_dc_val[3] = (src).last_dc_val[3])
#endif
#endif


typedef struct {
  struct jpeg_entropy_decoder pub; /* public fields */

  /* These fields are loaded into local variables at start of each MCU.
   * In case of suspension, we exit WITHOUT updating them.
   */
  bitread_perm_state bitstate;	/* Bit buffer at start of MCU */
  savable_state saved;		/* Other state at start of MCU */

  /* These fields are NOT loaded into local working state. */
  unsigned int restarts_to_go;	/* MCUs left in this restart interval */

  /* Pointers to derived tables (these workspaces have image lifespan) */
  d_derived_tbl * derived_tbls[NUM_HUFF_TBLS];

  d_derived_tbl * ac_derived_tbl; /* active table during an AC scan */
} phuff_entropy_decoder;

typedef phuff_entropy_decoder * phuff_entropy_ptr;

/* Forward declarations */
METHODDEF(boolean) decode_mcu_DC_first JPP((j_decompress_ptr cinfo,
					    JBLOCKROW *MCU_data));
METHODDEF(boolean) decode_mcu_AC_first JPP((j_decompress_ptr cinfo,
					    JBLOCKROW *MCU_data));
METHODDEF(boolean) decode_mcu_DC_refine JPP((j_decompress_ptr cinfo,
					     JBLOCKROW *MCU_data));
METHODDEF(boolean) decode_mcu_AC_refine JPP((j_decompress_ptr cinfo,
					     JBLOCKROW *MCU_data));


/*
 * Initialize for a Huffman-compressed scan.
 */

METHODDEF(void)
start_pass_phuff_decoder (j_decompress_ptr cinfo)
{
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  boolean is_DC_band, bad;
  int ci, coefi, tbl;
  int *coef_bit_ptr;
  jpeg_component_info * compptr;

  is_DC_band = (cinfo->Ss == 0);

  /* Validate scan parameters */
  bad = FALSE;
  if (is_DC_band) {
    if (cinfo->Se != 0)
      bad = TRUE;
  } else {
    /* need not check Ss/Se < 0 since they came from unsigned bytes */
    if (cinfo->Ss > cinfo->Se || cinfo->Se >= DCTSIZE2)
      bad = TRUE;
    /* AC scans may have only one component */
    if (cinfo->comps_in_scan != 1)
      bad = TRUE;
  }
  if (cinfo->Ah != 0) {
    /* Successive approximation refinement scan: must have Al = Ah-1. */
    if (cinfo->Al != cinfo->Ah-1)
      bad = TRUE;
  }
  if (cinfo->Al > 13)		/* need not check for < 0 */
    bad = TRUE;
  /* Arguably the maximum Al value should be less than 13 for 8-bit precision,
   * but the spec doesn't say so, and we try to be liberal about what we
   * accept.  Note: large Al values could result in out-of-range DC
   * coefficients during early scans, leading to bizarre displays due to
   * overflows in the IDCT math.  But we won't crash.
   */
  if (bad)
    ERREXIT4(cinfo, JERR_BAD_PROGRESSION,
	     cinfo->Ss, cinfo->Se, cinfo->Ah, cinfo->Al);
  /* Update progression status, and verify that scan order is legal.
   * Note that inter-scan inconsistencies are treated as warnings
   * not fatal errors ... not clear if this is right way to behave.
   */
  for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
    int cindex = cinfo->cur_comp_info[ci]->component_index;
    coef_bit_ptr = & cinfo->coef_bits[cindex][0];
    if (!is_DC_band && coef_bit_ptr[0] < 0) /* AC without prior DC scan */
      WARNMS2(cinfo, JWRN_BOGUS_PROGRESSION, cindex, 0);
    for (coefi = cinfo->Ss; coefi <= cinfo->Se; coefi++) {
      int expected = (coef_bit_ptr[coefi] < 0) ? 0 : coef_bit_ptr[coefi];
      if (cinfo->Ah != expected)
	WARNMS2(cinfo, JWRN_BOGUS_PROGRESSION, cindex, coefi);
      coef_bit_ptr[coefi] = cinfo->Al;
    }
  }

  /* Select MCU decoding routine */
  if (cinfo->Ah == 0) {
    if (is_DC_band)
      entropy->pub.decode_mcu = decode_mcu_DC_first;
    else
      entropy->pub.decode_mcu = decode_mcu_AC_first;
  } else {
    if (is_DC_band)
      entropy->pub.decode_mcu = decode_mcu_DC_refine;
    else
      entropy->pub.decode_mcu = decode_mcu_AC_refine;
  }

  for (ci = 0; ci < cinfo->comps_in_scan; ci++) {
    compptr = cinfo->cur_comp_info[ci];
    /* Make sure requested tables are present, and compute derived tables.
     * We may build same derived table more than once, but it's not expensive.
     */
    if (is_DC_band) {
      if (cinfo->Ah == 0) {	/* DC refinement needs no table */
	tbl = compptr->dc_tbl_no;
	jpeg_make_d_derived_tbl(cinfo, TRUE, tbl,
				& entropy->derived_tbls[tbl]);
      }
    } else {
      tbl = compptr->ac_tbl_no;
      jpeg_make_d_derived_tbl(cinfo, FALSE, tbl,
			      & entropy->derived_tbls[tbl]);
      /* remember the single active table */
      entropy->ac_derived_tbl = entropy->derived_tbls[tbl];
    }
    /* Initialize DC predictions to 0 */
    entropy->saved.last_dc_val[ci] = 0;
  }

  /* Initialize bitread state variables */
  entropy->bitstate.bits_left = 0;
  entropy->bitstate.get_buffer = 0; /* unnecessary, but keeps Purify quiet */
  entropy->pub.insufficient_data = FALSE;

  /* Initialize private state variables */
  entropy->saved.EOBRUN = 0;

  /* Initialize restart counter */
  entropy->restarts_to_go = cinfo->restart_interval;
}


/*
 * Figure F.12: extend sign bit.
 * On some machines, a shift and add will be faster than a table lookup.
 */

#ifdef AVOID_TABLES

#define HUFF_EXTEND(x,s)  ((x) < (1<<((s)-1)) ? (x) + (((-1)<<(s)) + 1) : (x))

#else

#define HUFF_EXTEND(x,s)  ((x) < extend_test[s] ? (x) + extend_offset[s] : (x))

static const int extend_test[16] =   /* entry n is 2**(n-1) */
  { 0, 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040, 0x0080,
    0x0100, 0x0200, 0x0400, 0x0800, 0x1000, 0x2000, 0x4000 };

static const int extend_offset[16] = /* entry n is (-1 << n) + 1 */
  { 0, ((-1)<<1) + 1, ((-1)<<2) + 1, ((-1)<<3) + 1, ((-1)<<4) + 1,
    ((-1)<<5) + 1, ((-1)<<6) + 1, ((-1)<<7) + 1, ((-1)<<8) + 1,
    ((-1)<<9) + 1, ((-1)<<10) + 1, ((-1)<<11) + 1, ((-1)<<12) + 1,
    ((-1)<<13) + 1, ((-1)<<14) + 1, ((-1)<<15) + 1 };

#endif /* AVOID_TABLES */


/*
 * Check for a restart marker & resynchronize decoder.
 * Returns FALSE if must suspend.
 */

LOCAL(boolean)
process_restart (j_decompress_ptr cinfo)
{
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  int ci;

  /* Throw away any unused bits remaining in bit buffer; */
  /* include any full bytes in next_marker's count of discarded bytes */
  cinfo->marker->discarded_bytes += entropy->bitstate.bits_left / 8;
  entropy->bitstate.bits_left = 0;

  /* Advance past the RSTn marker */
  if (! (*cinfo->marker->read_restart_marker) (cinfo))
    return FALSE;

  /* Re-initialize DC predictions to 0 */
  for (ci = 0; ci < cinfo->comps_in_scan; ci++)
    entropy->saved.last_dc_val[ci] = 0;
  /* Re-init EOB run count, too */
  entropy->saved.EOBRUN = 0;

  /* Reset restart counter */
  entropy->restarts_to_go = cinfo->restart_interval;

  /* Reset out-of-data flag, unless read_restart_marker left us smack up
   * against a marker.  In that case we will end up treating the next data
   * segment as empty, and we can avoid producing bogus output pixels by
   * leaving the flag set.
   */
  if (cinfo->unread_marker == 0)
    entropy->pub.insufficient_data = FALSE;

  return TRUE;
}


/*
 * Huffman MCU decoding.
 * Each of these routines decodes and returns one MCU's worth of
 * Huffman-compressed coefficients. 
 * The coefficients are reordered from zigzag order into natural array order,
 * but are not dequantized.
 *
 * The i'th block of the MCU is stored into the block pointed to by
 * MCU_data[i].  WE ASSUME THIS AREA IS INITIALLY ZEROED BY THE CALLER.
 *
 * We return FALSE if data source requested suspension.  In that case no
 * changes have been made to permanent state.  (Exception: some output
 * coefficients may already have been assigned.  This is harmless for
 * spectral selection, since we'll just re-assign them on the next call.
 * Successive approximation AC refinement has to be more careful, however.)
 */

/*
 * MCU decoding for DC initial scan (either spectral selection,
 * or first pass of successive approximation).
 */

METHODDEF(boolean)
decode_mcu_DC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{   
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  int Al = cinfo->Al;
  register int s, r;
  int blkn, ci;
  JBLOCKROW block;
  BITREAD_STATE_VARS;
  savable_state state;
  d_derived_tbl * tbl;
  jpeg_component_info * compptr;

  /* Process restart marker if needed; may have to suspend */
  if (cinfo->restart_interval) {
    if (entropy->restarts_to_go == 0)
      if (! process_restart(cinfo))
	return FALSE;
  }

  /* If we've run out of data, just leave the MCU set to zeroes.
   * This way, we return uniform gray for the remainder of the segment.
   */
  if (! entropy->pub.insufficient_data) {

    /* Load up working state */
    BITREAD_LOAD_STATE(cinfo,entropy->bitstate);
    ASSIGN_STATE(state, entropy->saved);

    /* Outer loop handles each block in the MCU */

    for (blkn = 0; blkn < cinfo->blocks_in_MCU; blkn++) {
      block = MCU_data[blkn];
      ci = cinfo->MCU_membership[blkn];
      compptr = cinfo->cur_comp_info[ci];
      tbl = entropy->derived_tbls[compptr->dc_tbl_no];

      /* Decode a single block's worth of coefficients */

      /* Section F.2.2.1: decode the DC coefficient difference */
      HUFF_DECODE(s, br_state, tbl, return FALSE, label1);
      if (s) {
	CHECK_BIT_BUFFER(br_state, s, return FALSE);
	r = GET_BITS(s);
	s = HUFF_EXTEND(r, s);
      }

      /* Convert DC difference to actual value, update last_dc_val */
      s += state.last_dc_val[ci];
      state.last_dc_val[ci] = s;
      /* Scale and output the coefficient (assumes jpeg_natural_order[0]=0) */
      (*block)[0] = (JCOEF) (s << Al);
    }

    /* Completed MCU, so update state */
    BITREAD_SAVE_STATE(cinfo,entropy->bitstate);
    ASSIGN_STATE(entropy->saved, state);
  }

  /* Account for restart interval (no-op if not using restarts) */
  entropy->restarts_to_go--;

  return TRUE;
}


/*
 * MCU decoding for AC initial scan (either spectral selection,
 * or first pass of successive approximation).
 */

METHODDEF(boolean)
decode_mcu_AC_first (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{   
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  int Se = cinfo->Se;
  int Al = cinfo->Al;
  register int s, k, r;
  unsigned int EOBRUN;
  JBLOCKROW block;
  BITREAD_STATE_VARS;
  d_derived_tbl * tbl;

  /* Process restart marker if needed; may have to suspend */
  if (cinfo->restart_interval) {
    if (entropy->restarts_to_go == 0)
      if (! process_restart(cinfo))
	return FALSE;
  }

  /* If we've run out of data, just leave the MCU set to zeroes.
   * This way, we return uniform gray for the remainder of the segment.
   */
  if (! entropy->pub.insufficient_data) {

    /* Load up working state.
     * We can avoid loading/saving bitread state if in an EOB run.
     */
    EOBRUN = entropy->saved.EOBRUN;	/* only part of saved state we need */

    /* There is always only one block per MCU */

    if (EOBRUN > 0)		/* if it's a band of zeroes... */
      EOBRUN--;			/* ...process it now (we do nothing) */
    else {
      BITREAD_LOAD_STATE(cinfo,entropy->bitstate);
      block = MCU_data[0];
      tbl = entropy->ac_derived_tbl;

      for (k = cinfo->Ss; k <= Se; k++) {
	HUFF_DECODE(s, br_state, tbl, return FALSE, label2);
	r = s >> 4;
	s &= 15;
	if (s) {
	  k += r;
	  CHECK_BIT_BUFFER(br_state, s, return FALSE);
	  r = GET_BITS(s);
	  s = HUFF_EXTEND(r, s);
	  /* Scale and output coefficient in natural (dezigzagged) order */
	  (*block)[jpeg_natural_order[k]] = (JCOEF) (s << Al);
	} else {
	  if (r == 15) {	/* ZRL */
	    k += 15;		/* skip 15 zeroes in band */
	  } else {		/* EOBr, run length is 2^r + appended bits */
	    EOBRUN = 1 << r;
	    if (r) {		/* EOBr, r > 0 */
	      CHECK_BIT_BUFFER(br_state, r, return FALSE);
	      r = GET_BITS(r);
	      EOBRUN += r;
	    }
	    EOBRUN--;		/* this band is processed at this moment */
	    break;		/* force end-of-band */
	  }
	}
      }

      BITREAD_SAVE_STATE(cinfo,entropy->bitstate);
    }

    /* Completed MCU, so update state */
    entropy->saved.EOBRUN = EOBRUN;	/* only part of saved state we need */
  }

  /* Account for restart interval (no-op if not using restarts) */
  entropy->restarts_to_go--;

  return TRUE;
}


/*
 * MCU decoding for DC successive approximation refinement scan.
 * Note: we assume such scans can be multi-component, although the spec
 * is not very clear on the point.
 */

METHODDEF(boolean)
decode_mcu_DC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{   
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  int p1 = 1 << cinfo->Al;	/* 1 in the bit position being coded */
  int blkn;
  JBLOCKROW block;
  BITREAD_STATE_VARS;

  /* Process restart marker if needed; may have to suspend */
  if (cinfo->restart_interval) {
    if (entropy->restarts_to_go == 0)
      if (! process_restart(cinfo))
	return FALSE;
  }

  /* Not worth the cycles to check insufficient_data here,
   * since we will not change the data anyway if we read zeroes.
   */

  /* Load up working state */
  BITREAD_LOAD_STATE(cinfo,entropy->bitstate);

  /* Outer loop handles each block in the MCU */

  for (blkn = 0; blkn < cinfo->blocks_in_MCU; blkn++) {
    block = MCU_data[blkn];

    /* Encoded data is simply the next bit of the two's-complement DC value */
    CHECK_BIT_BUFFER(br_state, 1, return FALSE);
    if (GET_BITS(1))
      (*block)[0] |= p1;
    /* Note: since we use |=, repeating the assignment later is safe */
  }

  /* Completed MCU, so update state */
  BITREAD_SAVE_STATE(cinfo,entropy->bitstate);

  /* Account for restart interval (no-op if not using restarts) */
  entropy->restarts_to_go--;

  return TRUE;
}


/*
 * MCU decoding for AC successive approximation refinement scan.
 */

METHODDEF(boolean)
decode_mcu_AC_refine (j_decompress_ptr cinfo, JBLOCKROW *MCU_data)
{   
  phuff_entropy_ptr entropy = (phuff_entropy_ptr) cinfo->entropy;
  int Se = cinfo->Se;
  int p1 = 1 << cinfo->Al;	/* 1 in the bit position being coded */
  int m1 = (-1) << cinfo->Al;	/* -1 in the bit position being coded */
  register int s, k, r;
  unsigned int EOBRUN;
  JBLOCKROW block;
  JCOEFPTR thiscoef;
  BITREAD_STATE_VARS;
  d_derived_tbl * tbl;
  int num_newnz;
  int newnz_pos[DCTSIZE2];

  /* Process restart marker if needed; may have to suspend */
  if (cinfo->restart_interval) {
    if (entropy->restarts_to_go == 0)
      if (! process_restart(cinfo))
	return FALSE;
  }

  /* If we've run out of data, don't modify the MCU.
   */
  if (! entropy->pub.insufficient_data) {

    /* Load up working state */
    BITREAD_LOAD_STATE(cinfo,entropy->bitstate);
    EOBRUN = entropy->saved.EOBRUN; /* only part of saved state we need */

    /* There is always only one block per MCU */
    block = MCU_data[0];
    tbl = entropy->ac_derived_tbl;

    /* If we are forced to suspend, we must undo the assignments to any newly
     * nonzero coefficients in the block, because otherwise we'd get confused
     * next time about which coefficients were already nonzero.
     * But we need not undo addition of bits to already-nonzero coefficients;
     * instead, we can test the current bit to see if we already did it.
     */
    num_newnz = 0;

    /* initialize coefficient loop counter to start of band */
    k = cinfo->Ss;

    if (EOBRUN == 0) {
      for (; k <= Se; k++) {
	HUFF_DECODE(s, br_state, tbl, goto undoit, label3);
	r = s >> 4;
	s &= 15;
	if (s) {
	  if (s != 1)		/* size of new coef should always be 1 */
	    WARNMS(cinfo, JWRN_HUFF_BAD_CODE);
	  CHECK_BIT_BUFFER(br_state, 1, goto undoit);
	  if (GET_BITS(1))
	    s = p1;		/* newly nonzero coef is positive */
	  else
	    s = m1;		/* newly nonzero coef is negative */
	} else {
	  if (r != 15) {
	    EOBRUN = 1 << r;	/* EOBr, run length is 2^r + appended bits */
	    if (r) {
	      CHECK_BIT_BUFFER(br_state, r, goto undoit);
	      r = GET_BITS(r);
	      EOBRUN += r;
	    }
	    break;		/* rest of block is handled by EOB logic */
	  }
	  /* note s = 0 for processing ZRL */
	}
	/* Advance over already-nonzero coefs and r still-zero coefs,
	 * appending correction bits to the nonzeroes.  A correction bit is 1
	 * if the absolute value of the coefficient must be increased.
	 */
	do {
	  thiscoef = *block + jpeg_natural_order[k];
	  if (*thiscoef != 0) {
	    CHECK_BIT_BUFFER(br_state, 1, goto undoit);
	    if (GET_BITS(1)) {
	      if ((*thiscoef & p1) == 0) { /* do nothing if already set it */
		if (*thiscoef >= 0)
		  *thiscoef += p1;
		else
		  *thiscoef += m1;
	      }
	    }
	  } else {
	    if (--r < 0)
	      break;		/* reached target zero coefficient */
	  }
	  k++;
	} while (k <= Se);
	if (s) {
	  int pos = jpeg_natural_order[k];
	  /* Output newly nonzero coefficient */
	  (*block)[pos] = (JCOEF) s;
	  /* Remember its position in case we have to suspend */
	  newnz_pos[num_newnz++] = pos;
	}
      }
    }

    if (EOBRUN > 0) {
      /* Scan any remaining coefficient positions after the end-of-band
       * (the last newly nonzero coefficient, if any).  Append a correction
       * bit to each already-nonzero coefficient.  A correction bit is 1
       * if the absolute value of the coefficient must be increased.
       */
      for (; k <= Se; k++) {
	thiscoef = *block + jpeg_natural_order[k];
	if (*thiscoef != 0) {
	  CHECK_BIT_BUFFER(br_state, 1, goto undoit);
	  if (GET_BITS(1)) {
	    if ((*thiscoef & p1) == 0) { /* do nothing if already changed it */
	      if (*thiscoef >= 0)
		*thiscoef += p1;
	      else
		*thiscoef += m1;
	    }
	  }
	}
      }
      /* Count one block completed in EOB run */
      EOBRUN--;
    }

    /* Completed MCU, so update state */
    BITREAD_SAVE_STATE(cinfo,entropy->bitstate);
    entropy->saved.EOBRUN = EOBRUN; /* only part of saved state we need */
  }

  /* Account for restart interval (no-op if not using restarts) */
  entropy->restarts_to_go--;

  return TRUE;

undoit:
  /* Re-zero any output coefficients that we made newly nonzero */
  while (num_newnz > 0)
    (*block)[newnz_pos[--num_newnz]] = 0;

  return FALSE;
}


/*
 * Module initialization routine for progressive Huffman entropy decoding.
 */

GLOBAL(void)
jinit_phuff_decoder (j_decompress_ptr cinfo)
{
  phuff_entropy_ptr entropy;
  int *coef_bit_ptr;
  int ci, i;

  entropy = (phuff_entropy_ptr)
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				SIZEOF(phuff_entropy_decoder));
  cinfo->entropy = (struct jpeg_entropy_decoder *) entropy;
  entropy->pub.start_pass = start_pass_phuff_decoder;

  /* Mark derived tables unallocated */
  for (i = 0; i < NUM_HUFF_TBLS; i++) {
    entropy->derived_tbls[i] = NULL;
  }

  /* Create progression status table */
  cinfo->coef_bits = (int (*)[DCTSIZE2])
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				cinfo->num_components*DCTSIZE2*SIZEOF(int));
  coef_bit_ptr = & cinfo->coef_bits[0][0];
  for (ci = 0; ci < cinfo->num_components; ci++) 
    for (i = 0; i < DCTSIZE2; i++)
      *coef_bit_ptr++ = -1;
}

#endif /* D_PROGRESSIVE_SUPPORTED */
