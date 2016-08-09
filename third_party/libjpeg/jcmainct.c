/*
 * jcmainct.c
 *
 * Copyright (C) 1994-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains the main buffer controller for compression.
 * The main buffer lies between the pre-processor and the JPEG
 * compressor proper; it holds downsampled data in the JPEG colorspace.
 */

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"


/* Note: currently, there is no operating mode in which a full-image buffer
 * is needed at this step.  If there were, that mode could not be used with
 * "raw data" input, since this module is bypassed in that case.  However,
 * we've left the code here for possible use in special applications.
 */
#undef FULL_MAIN_BUFFER_SUPPORTED


/* Private buffer controller object */

typedef struct {
  struct jpeg_c_main_controller pub; /* public fields */

  JDIMENSION cur_iMCU_row;	/* number of current iMCU row */
  JDIMENSION rowgroup_ctr;	/* counts row groups received in iMCU row */
  boolean suspended;		/* remember if we suspended output */
  J_BUF_MODE pass_mode;		/* current operating mode */

  /* If using just a strip buffer, this points to the entire set of buffers
   * (we allocate one for each component).  In the full-image case, this
   * points to the currently accessible strips of the virtual arrays.
   */
  JSAMPARRAY buffer[MAX_COMPONENTS];

#ifdef FULL_MAIN_BUFFER_SUPPORTED
  /* If using full-image storage, this array holds pointers to virtual-array
   * control blocks for each component.  Unused if not full-image storage.
   */
  jvirt_sarray_ptr whole_image[MAX_COMPONENTS];
#endif
} my_main_controller;

typedef my_main_controller * my_main_ptr;


/* Forward declarations */
METHODDEF(void) process_data_simple_main
	JPP((j_compress_ptr cinfo, JSAMPARRAY input_buf,
	     JDIMENSION *in_row_ctr, JDIMENSION in_rows_avail));
#ifdef FULL_MAIN_BUFFER_SUPPORTED
METHODDEF(void) process_data_buffer_main
	JPP((j_compress_ptr cinfo, JSAMPARRAY input_buf,
	     JDIMENSION *in_row_ctr, JDIMENSION in_rows_avail));
#endif


/*
 * Initialize for a processing pass.
 */

METHODDEF(void)
start_pass_main (j_compress_ptr cinfo, J_BUF_MODE pass_mode)
{
  my_main_ptr main = (my_main_ptr) cinfo->main;

  /* Do nothing in raw-data mode. */
  if (cinfo->raw_data_in)
    return;

  main->cur_iMCU_row = 0;	/* initialize counters */
  main->rowgroup_ctr = 0;
  main->suspended = FALSE;
  main->pass_mode = pass_mode;	/* save mode for use by process_data */

  switch (pass_mode) {
  case JBUF_PASS_THRU:
#ifdef FULL_MAIN_BUFFER_SUPPORTED
    if (main->whole_image[0] != NULL)
      ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);
#endif
    main->pub.process_data = process_data_simple_main;
    break;
#ifdef FULL_MAIN_BUFFER_SUPPORTED
  case JBUF_SAVE_SOURCE:
  case JBUF_CRANK_DEST:
  case JBUF_SAVE_AND_PASS:
    if (main->whole_image[0] == NULL)
      ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);
    main->pub.process_data = process_data_buffer_main;
    break;
#endif
  default:
    ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);
    break;
  }
}


/*
 * Process some data.
 * This routine handles the simple pass-through mode,
 * where we have only a strip buffer.
 */

METHODDEF(void)
process_data_simple_main (j_compress_ptr cinfo,
			  JSAMPARRAY input_buf, JDIMENSION *in_row_ctr,
			  JDIMENSION in_rows_avail)
{
  my_main_ptr main = (my_main_ptr) cinfo->main;

  while (main->cur_iMCU_row < cinfo->total_iMCU_rows) {
    /* Read input data if we haven't filled the main buffer yet */
    if (main->rowgroup_ctr < DCTSIZE)
      (*cinfo->prep->pre_process_data) (cinfo,
					input_buf, in_row_ctr, in_rows_avail,
					main->buffer, &main->rowgroup_ctr,
					(JDIMENSION) DCTSIZE);

    /* If we don't have a full iMCU row buffered, return to application for
     * more data.  Note that preprocessor will always pad to fill the iMCU row
     * at the bottom of the image.
     */
    if (main->rowgroup_ctr != DCTSIZE)
      return;

    /* Send the completed row to the compressor */
    if (! (*cinfo->coef->compress_data) (cinfo, main->buffer)) {
      /* If compressor did not consume the whole row, then we must need to
       * suspend processing and return to the application.  In this situation
       * we pretend we didn't yet consume the last input row; otherwise, if
       * it happened to be the last row of the image, the application would
       * think we were done.
       */
      if (! main->suspended) {
	(*in_row_ctr)--;
	main->suspended = TRUE;
      }
      return;
    }
    /* We did finish the row.  Undo our little suspension hack if a previous
     * call suspended; then mark the main buffer empty.
     */
    if (main->suspended) {
      (*in_row_ctr)++;
      main->suspended = FALSE;
    }
    main->rowgroup_ctr = 0;
    main->cur_iMCU_row++;
  }
}


#ifdef FULL_MAIN_BUFFER_SUPPORTED

/*
 * Process some data.
 * This routine handles all of the modes that use a full-size buffer.
 */

METHODDEF(void)
process_data_buffer_main (j_compress_ptr cinfo,
			  JSAMPARRAY input_buf, JDIMENSION *in_row_ctr,
			  JDIMENSION in_rows_avail)
{
  my_main_ptr main = (my_main_ptr) cinfo->main;
  int ci;
  jpeg_component_info *compptr;
  boolean writing = (main->pass_mode != JBUF_CRANK_DEST);

  while (main->cur_iMCU_row < cinfo->total_iMCU_rows) {
    /* Realign the virtual buffers if at the start of an iMCU row. */
    if (main->rowgroup_ctr == 0) {
      for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	   ci++, compptr++) {
	main->buffer[ci] = (*cinfo->mem->access_virt_sarray)
	  ((j_common_ptr) cinfo, main->whole_image[ci],
	   main->cur_iMCU_row * (compptr->v_samp_factor * DCTSIZE),
	   (JDIMENSION) (compptr->v_samp_factor * DCTSIZE), writing);
      }
      /* In a read pass, pretend we just read some source data. */
      if (! writing) {
	*in_row_ctr += cinfo->max_v_samp_factor * DCTSIZE;
	main->rowgroup_ctr = DCTSIZE;
      }
    }

    /* If a write pass, read input data until the current iMCU row is full. */
    /* Note: preprocessor will pad if necessary to fill the last iMCU row. */
    if (writing) {
      (*cinfo->prep->pre_process_data) (cinfo,
					input_buf, in_row_ctr, in_rows_avail,
					main->buffer, &main->rowgroup_ctr,
					(JDIMENSION) DCTSIZE);
      /* Return to application if we need more data to fill the iMCU row. */
      if (main->rowgroup_ctr < DCTSIZE)
	return;
    }

    /* Emit data, unless this is a sink-only pass. */
    if (main->pass_mode != JBUF_SAVE_SOURCE) {
      if (! (*cinfo->coef->compress_data) (cinfo, main->buffer)) {
	/* If compressor did not consume the whole row, then we must need to
	 * suspend processing and return to the application.  In this situation
	 * we pretend we didn't yet consume the last input row; otherwise, if
	 * it happened to be the last row of the image, the application would
	 * think we were done.
	 */
	if (! main->suspended) {
	  (*in_row_ctr)--;
	  main->suspended = TRUE;
	}
	return;
      }
      /* We did finish the row.  Undo our little suspension hack if a previous
       * call suspended; then mark the main buffer empty.
       */
      if (main->suspended) {
	(*in_row_ctr)++;
	main->suspended = FALSE;
      }
    }

    /* If get here, we are done with this iMCU row.  Mark buffer empty. */
    main->rowgroup_ctr = 0;
    main->cur_iMCU_row++;
  }
}

#endif /* FULL_MAIN_BUFFER_SUPPORTED */


/*
 * Initialize main buffer controller.
 */

GLOBAL(void)
jinit_c_main_controller (j_compress_ptr cinfo, boolean need_full_buffer)
{
  my_main_ptr main;
  int ci;
  jpeg_component_info *compptr;

  main = (my_main_ptr)
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				SIZEOF(my_main_controller));
  cinfo->main = (struct jpeg_c_main_controller *) main;
  main->pub.start_pass = start_pass_main;

  /* We don't need to create a buffer in raw-data mode. */
  if (cinfo->raw_data_in)
    return;

  /* Create the buffer.  It holds downsampled data, so each component
   * may be of a different size.
   */
  if (need_full_buffer) {
#ifdef FULL_MAIN_BUFFER_SUPPORTED
    /* Allocate a full-image virtual array for each component */
    /* Note we pad the bottom to a multiple of the iMCU height */
    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      main->whole_image[ci] = (*cinfo->mem->request_virt_sarray)
	((j_common_ptr) cinfo, JPOOL_IMAGE, FALSE,
	 compptr->width_in_blocks * DCTSIZE,
	 (JDIMENSION) jround_up((long) compptr->height_in_blocks,
				(long) compptr->v_samp_factor) * DCTSIZE,
	 (JDIMENSION) (compptr->v_samp_factor * DCTSIZE));
    }
#else
    ERREXIT(cinfo, JERR_BAD_BUFFER_MODE);
#endif
  } else {
#ifdef FULL_MAIN_BUFFER_SUPPORTED
    main->whole_image[0] = NULL; /* flag for no virtual arrays */
#endif
    /* Allocate a strip buffer for each component */
    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      main->buffer[ci] = (*cinfo->mem->alloc_sarray)
	((j_common_ptr) cinfo, JPOOL_IMAGE,
	 compptr->width_in_blocks * DCTSIZE,
	 (JDIMENSION) (compptr->v_samp_factor * DCTSIZE));
    }
  }
}
