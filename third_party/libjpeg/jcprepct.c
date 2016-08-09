/*
 * jcprepct.c
 *
 * Copyright (C) 1994-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains the compression preprocessing controller.
 * This controller manages the color conversion, downsampling,
 * and edge expansion steps.
 *
 * Most of the complexity here is associated with buffering input rows
 * as required by the downsampler.  See the comments at the head of
 * jcsample.c for the downsampler's needs.
 */

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"


/* At present, jcsample.c can request context rows only for smoothing.
 * In the future, we might also need context rows for CCIR601 sampling
 * or other more-complex downsampling procedures.  The code to support
 * context rows should be compiled only if needed.
 */
#ifdef INPUT_SMOOTHING_SUPPORTED
#define CONTEXT_ROWS_SUPPORTED
#endif


/*
 * For the simple (no-context-row) case, we just need to buffer one
 * row group's worth of pixels for the downsampling step.  At the bottom of
 * the image, we pad to a full row group by replicating the last pixel row.
 * The downsampler's last output row is then replicated if needed to pad
 * out to a full iMCU row.
 *
 * When providing context rows, we must buffer three row groups' worth of
 * pixels.  Three row groups are physically allocated, but the row pointer
 * arrays are made five row groups high, with the extra pointers above and
 * below "wrapping around" to point to the last and first real row groups.
 * This allows the downsampler to access the proper context rows.
 * At the top and bottom of the image, we create dummy context rows by
 * copying the first or last real pixel row.  This copying could be avoided
 * by pointer hacking as is done in jdmainct.c, but it doesn't seem worth the
 * trouble on the compression side.
 */


/* Private buffer controller object */

typedef struct {
  struct jpeg_c_prep_controller pub; /* public fields */

  /* Downsampling input buffer.  This buffer holds color-converted data
   * until we have enough to do a downsample step.
   */
  JSAMPARRAY color_buf[MAX_COMPONENTS];

  JDIMENSION rows_to_go;	/* counts rows remaining in source image */
  int next_buf_row;		/* index of next row to store in color_buf */

#ifdef CONTEXT_ROWS_SUPPORTED	/* only needed for context case */
  int this_row_group;		/* starting row index of group to process */
  int next_buf_stop;		/* downsample when we reach this index */
#endif
} my_prep_controller;

typedef my_prep_controller * my_prep_ptr;


/*
 * Initialize for a processing pass.
 */

METHODDEF(void)
start_pass_prep (j_compress_ptr cinfo, J_BUF_MODE pass_mode)
{
  my_prep_ptr prep = (my_prep_ptr) cinfo->prep;

  if (pass_mode != JBUF_PASS_THRU)
    ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);

  /* Initialize total-height counter for detecting bottom of image */
  prep->rows_to_go = cinfo->image_height;
  /* Mark the conversion buffer empty */
  prep->next_buf_row = 0;
#ifdef CONTEXT_ROWS_SUPPORTED
  /* Preset additional state variables for context mode.
   * These aren't used in non-context mode, so we needn't test which mode.
   */
  prep->this_row_group = 0;
  /* Set next_buf_stop to stop after two row groups have been read in. */
  prep->next_buf_stop = 2 * cinfo->max_v_samp_factor;
#endif
}


/*
 * Expand an image vertically from height input_rows to height output_rows,
 * by duplicating the bottom row.
 */

LOCAL(void)
expand_bottom_edge (JSAMPARRAY image_data, JDIMENSION num_cols,
		    int input_rows, int output_rows)
{
  register int row;

  for (row = input_rows; row < output_rows; row++) {
    jcopy_sample_rows(image_data, input_rows-1, image_data, row,
		      1, num_cols);
  }
}


/*
 * Process some data in the simple no-context case.
 *
 * Preprocessor output data is counted in "row groups".  A row group
 * is defined to be v_samp_factor sample rows of each component.
 * Downsampling will produce this much data from each max_v_samp_factor
 * input rows.
 */

METHODDEF(void)
pre_process_data (j_compress_ptr cinfo,
		  JSAMPARRAY input_buf, JDIMENSION *in_row_ctr,
		  JDIMENSION in_rows_avail,
		  JSAMPIMAGE output_buf, JDIMENSION *out_row_group_ctr,
		  JDIMENSION out_row_groups_avail)
{
  my_prep_ptr prep = (my_prep_ptr) cinfo->prep;
  int numrows, ci;
  JDIMENSION inrows;
  jpeg_component_info * compptr;

  while (*in_row_ctr < in_rows_avail &&
	 *out_row_group_ctr < out_row_groups_avail) {
    /* Do color conversion to fill the conversion buffer. */
    inrows = in_rows_avail - *in_row_ctr;
    numrows = cinfo->max_v_samp_factor - prep->next_buf_row;
    numrows = (int) MIN((JDIMENSION) numrows, inrows);
    (*cinfo->cconvert->color_convert) (cinfo, input_buf + *in_row_ctr,
				       prep->color_buf,
				       (JDIMENSION) prep->next_buf_row,
				       numrows);
    *in_row_ctr += numrows;
    prep->next_buf_row += numrows;
    prep->rows_to_go -= numrows;
    /* If at bottom of image, pad to fill the conversion buffer. */
    if (prep->rows_to_go == 0 &&
	prep->next_buf_row < cinfo->max_v_samp_factor) {
      for (ci = 0; ci < cinfo->num_components; ci++) {
	expand_bottom_edge(prep->color_buf[ci], cinfo->image_width,
			   prep->next_buf_row, cinfo->max_v_samp_factor);
      }
      prep->next_buf_row = cinfo->max_v_samp_factor;
    }
    /* If we've filled the conversion buffer, empty it. */
    if (prep->next_buf_row == cinfo->max_v_samp_factor) {
      (*cinfo->downsample->downsample) (cinfo,
					prep->color_buf, (JDIMENSION) 0,
					output_buf, *out_row_group_ctr);
      prep->next_buf_row = 0;
      (*out_row_group_ctr)++;
    }
    /* If at bottom of image, pad the output to a full iMCU height.
     * Note we assume the caller is providing a one-iMCU-height output buffer!
     */
    if (prep->rows_to_go == 0 &&
	*out_row_group_ctr < out_row_groups_avail) {
      for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	   ci++, compptr++) {
	expand_bottom_edge(output_buf[ci],
			   compptr->width_in_blocks * DCTSIZE,
			   (int) (*out_row_group_ctr * compptr->v_samp_factor),
			   (int) (out_row_groups_avail * compptr->v_samp_factor));
      }
      *out_row_group_ctr = out_row_groups_avail;
      break;			/* can exit outer loop without test */
    }
  }
}


#ifdef CONTEXT_ROWS_SUPPORTED

/*
 * Process some data in the context case.
 */

METHODDEF(void)
pre_process_context (j_compress_ptr cinfo,
		     JSAMPARRAY input_buf, JDIMENSION *in_row_ctr,
		     JDIMENSION in_rows_avail,
		     JSAMPIMAGE output_buf, JDIMENSION *out_row_group_ctr,
		     JDIMENSION out_row_groups_avail)
{
  my_prep_ptr prep = (my_prep_ptr) cinfo->prep;
  int numrows, ci;
  int buf_height = cinfo->max_v_samp_factor * 3;
  JDIMENSION inrows;

  while (*out_row_group_ctr < out_row_groups_avail) {
    if (*in_row_ctr < in_rows_avail) {
      /* Do color conversion to fill the conversion buffer. */
      inrows = in_rows_avail - *in_row_ctr;
      numrows = prep->next_buf_stop - prep->next_buf_row;
      numrows = (int) MIN((JDIMENSION) numrows, inrows);
      (*cinfo->cconvert->color_convert) (cinfo, input_buf + *in_row_ctr,
					 prep->color_buf,
					 (JDIMENSION) prep->next_buf_row,
					 numrows);
      /* Pad at top of image, if first time through */
      if (prep->rows_to_go == cinfo->image_height) {
	for (ci = 0; ci < cinfo->num_components; ci++) {
	  int row;
	  for (row = 1; row <= cinfo->max_v_samp_factor; row++) {
	    jcopy_sample_rows(prep->color_buf[ci], 0,
			      prep->color_buf[ci], -row,
			      1, cinfo->image_width);
	  }
	}
      }
      *in_row_ctr += numrows;
      prep->next_buf_row += numrows;
      prep->rows_to_go -= numrows;
    } else {
      /* Return for more data, unless we are at the bottom of the image. */
      if (prep->rows_to_go != 0)
	break;
      /* When at bottom of image, pad to fill the conversion buffer. */
      if (prep->next_buf_row < prep->next_buf_stop) {
	for (ci = 0; ci < cinfo->num_components; ci++) {
	  expand_bottom_edge(prep->color_buf[ci], cinfo->image_width,
			     prep->next_buf_row, prep->next_buf_stop);
	}
	prep->next_buf_row = prep->next_buf_stop;
      }
    }
    /* If we've gotten enough data, downsample a row group. */
    if (prep->next_buf_row == prep->next_buf_stop) {
      (*cinfo->downsample->downsample) (cinfo,
					prep->color_buf,
					(JDIMENSION) prep->this_row_group,
					output_buf, *out_row_group_ctr);
      (*out_row_group_ctr)++;
      /* Advance pointers with wraparound as necessary. */
      prep->this_row_group += cinfo->max_v_samp_factor;
      if (prep->this_row_group >= buf_height)
	prep->this_row_group = 0;
      if (prep->next_buf_row >= buf_height)
	prep->next_buf_row = 0;
      prep->next_buf_stop = prep->next_buf_row + cinfo->max_v_samp_factor;
    }
  }
}


/*
 * Create the wrapped-around downsampling input buffer needed for context mode.
 */

LOCAL(void)
create_context_buffer (j_compress_ptr cinfo)
{
  my_prep_ptr prep = (my_prep_ptr) cinfo->prep;
  int rgroup_height = cinfo->max_v_samp_factor;
  int ci, i;
  jpeg_component_info * compptr;
  JSAMPARRAY true_buffer, fake_buffer;

  /* Grab enough space for fake row pointers for all the components;
   * we need five row groups' worth of pointers for each component.
   */
  fake_buffer = (JSAMPARRAY)
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				(cinfo->num_components * 5 * rgroup_height) *
				SIZEOF(JSAMPROW));

  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    /* Allocate the actual buffer space (3 row groups) for this component.
     * We make the buffer wide enough to allow the downsampler to edge-expand
     * horizontally within the buffer, if it so chooses.
     */
    true_buffer = (*cinfo->mem->alloc_sarray)
      ((j_common_ptr) cinfo, JPOOL_IMAGE,
       (JDIMENSION) (((long) compptr->width_in_blocks * DCTSIZE *
		      cinfo->max_h_samp_factor) / compptr->h_samp_factor),
       (JDIMENSION) (3 * rgroup_height));
    /* Copy true buffer row pointers into the middle of the fake row array */
    MEMCOPY(fake_buffer + rgroup_height, true_buffer,
	    3 * rgroup_height * SIZEOF(JSAMPROW));
    /* Fill in the above and below wraparound pointers */
    for (i = 0; i < rgroup_height; i++) {
      fake_buffer[i] = true_buffer[2 * rgroup_height + i];
      fake_buffer[4 * rgroup_height + i] = true_buffer[i];
    }
    prep->color_buf[ci] = fake_buffer + rgroup_height;
    fake_buffer += 5 * rgroup_height; /* point to space for next component */
  }
}

#endif /* CONTEXT_ROWS_SUPPORTED */


/*
 * Initialize preprocessing controller.
 */

GLOBAL(void)
jinit_c_prep_controller (j_compress_ptr cinfo, boolean need_full_buffer)
{
  my_prep_ptr prep;
  int ci;
  jpeg_component_info * compptr;

  if (need_full_buffer)		/* safety check */
    ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);

  prep = (my_prep_ptr)
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				SIZEOF(my_prep_controller));
  cinfo->prep = (struct jpeg_c_prep_controller *) prep;
  prep->pub.start_pass = start_pass_prep;

  /* Allocate the color conversion buffer.
   * We make the buffer wide enough to allow the downsampler to edge-expand
   * horizontally within the buffer, if it so chooses.
   */
  if (cinfo->downsample->need_context_rows) {
    /* Set up to provide context rows */
#ifdef CONTEXT_ROWS_SUPPORTED
    prep->pub.pre_process_data = pre_process_context;
    create_context_buffer(cinfo);
#else
    ERREXIT(cinfo, JERR_NOT_COMPILED);
#endif
  } else {
    /* No context, just make it tall enough for one row group */
    prep->pub.pre_process_data = pre_process_data;
    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      prep->color_buf[ci] = (*cinfo->mem->alloc_sarray)
	((j_common_ptr) cinfo, JPOOL_IMAGE,
	 (JDIMENSION) (((long) compptr->width_in_blocks * DCTSIZE *
			cinfo->max_h_samp_factor) / compptr->h_samp_factor),
	 (JDIMENSION) cinfo->max_v_samp_factor);
    }
  }
}
