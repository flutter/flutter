/*
 * jdmarker.c
 *
 * Copyright (C) 1991-1998, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains routines to decode JPEG datastream markers.
 * Most of the complexity arises from our desire to support input
 * suspension: if not all of the data for a marker is available,
 * we must exit back to the application.  On resumption, we reprocess
 * the marker.
 */

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"


typedef enum {			/* JPEG marker codes */
  M_SOF0  = 0xc0,
  M_SOF1  = 0xc1,
  M_SOF2  = 0xc2,
  M_SOF3  = 0xc3,
  
  M_SOF5  = 0xc5,
  M_SOF6  = 0xc6,
  M_SOF7  = 0xc7,
  
  M_JPG   = 0xc8,
  M_SOF9  = 0xc9,
  M_SOF10 = 0xca,
  M_SOF11 = 0xcb,
  
  M_SOF13 = 0xcd,
  M_SOF14 = 0xce,
  M_SOF15 = 0xcf,
  
  M_DHT   = 0xc4,
  
  M_DAC   = 0xcc,
  
  M_RST0  = 0xd0,
  M_RST1  = 0xd1,
  M_RST2  = 0xd2,
  M_RST3  = 0xd3,
  M_RST4  = 0xd4,
  M_RST5  = 0xd5,
  M_RST6  = 0xd6,
  M_RST7  = 0xd7,
  
  M_SOI   = 0xd8,
  M_EOI   = 0xd9,
  M_SOS   = 0xda,
  M_DQT   = 0xdb,
  M_DNL   = 0xdc,
  M_DRI   = 0xdd,
  M_DHP   = 0xde,
  M_EXP   = 0xdf,
  
  M_APP0  = 0xe0,
  M_APP1  = 0xe1,
  M_APP2  = 0xe2,
  M_APP3  = 0xe3,
  M_APP4  = 0xe4,
  M_APP5  = 0xe5,
  M_APP6  = 0xe6,
  M_APP7  = 0xe7,
  M_APP8  = 0xe8,
  M_APP9  = 0xe9,
  M_APP10 = 0xea,
  M_APP11 = 0xeb,
  M_APP12 = 0xec,
  M_APP13 = 0xed,
  M_APP14 = 0xee,
  M_APP15 = 0xef,
  
  M_JPG0  = 0xf0,
  M_JPG13 = 0xfd,
  M_COM   = 0xfe,
  
  M_TEM   = 0x01,
  
  M_ERROR = 0x100
} JPEG_MARKER;


/* Private state */

typedef struct {
  struct jpeg_marker_reader pub; /* public fields */

  /* Application-overridable marker processing methods */
  jpeg_marker_parser_method process_COM;
  jpeg_marker_parser_method process_APPn[16];

  /* Limit on marker data length to save for each marker type */
  unsigned int length_limit_COM;
  unsigned int length_limit_APPn[16];

  /* Status of COM/APPn marker saving */
  jpeg_saved_marker_ptr cur_marker;	/* NULL if not processing a marker */
  unsigned int bytes_read;		/* data bytes read so far in marker */
  /* Note: cur_marker is not linked into marker_list until it's all read. */
} my_marker_reader;

typedef my_marker_reader * my_marker_ptr;


/*
 * Macros for fetching data from the data source module.
 *
 * At all times, cinfo->src->next_input_byte and ->bytes_in_buffer reflect
 * the current restart point; we update them only when we have reached a
 * suitable place to restart if a suspension occurs.
 */

/* Declare and initialize local copies of input pointer/count */
#define INPUT_VARS(cinfo)  \
	struct jpeg_source_mgr * datasrc = (cinfo)->src;  \
	const JOCTET * next_input_byte = datasrc->next_input_byte;  \
	size_t bytes_in_buffer = datasrc->bytes_in_buffer

/* Unload the local copies --- do this only at a restart boundary */
#define INPUT_SYNC(cinfo)  \
	( datasrc->next_input_byte = next_input_byte,  \
	  datasrc->bytes_in_buffer = bytes_in_buffer )

/* Reload the local copies --- used only in MAKE_BYTE_AVAIL */
#define INPUT_RELOAD(cinfo)  \
	( next_input_byte = datasrc->next_input_byte,  \
	  bytes_in_buffer = datasrc->bytes_in_buffer )

/* Internal macro for INPUT_BYTE and INPUT_2BYTES: make a byte available.
 * Note we do *not* do INPUT_SYNC before calling fill_input_buffer,
 * but we must reload the local copies after a successful fill.
 */
#define MAKE_BYTE_AVAIL(cinfo,action)  \
	if (bytes_in_buffer == 0) {  \
	  if (! (*datasrc->fill_input_buffer) (cinfo))  \
	    { action; }  \
	  INPUT_RELOAD(cinfo);  \
	}

/* Read a byte into variable V.
 * If must suspend, take the specified action (typically "return FALSE").
 */
#define INPUT_BYTE(cinfo,V,action)  \
	MAKESTMT( MAKE_BYTE_AVAIL(cinfo,action); \
		  bytes_in_buffer--; \
		  V = GETJOCTET(*next_input_byte++); )

/* As above, but read two bytes interpreted as an unsigned 16-bit integer.
 * V should be declared unsigned int or perhaps INT32.
 */
#define INPUT_2BYTES(cinfo,V,action)  \
	MAKESTMT( MAKE_BYTE_AVAIL(cinfo,action); \
		  bytes_in_buffer--; \
		  V = ((unsigned int) GETJOCTET(*next_input_byte++)) << 8; \
		  MAKE_BYTE_AVAIL(cinfo,action); \
		  bytes_in_buffer--; \
		  V += GETJOCTET(*next_input_byte++); )


/*
 * Routines to process JPEG markers.
 *
 * Entry condition: JPEG marker itself has been read and its code saved
 *   in cinfo->unread_marker; input restart point is just after the marker.
 *
 * Exit: if return TRUE, have read and processed any parameters, and have
 *   updated the restart point to point after the parameters.
 *   If return FALSE, was forced to suspend before reaching end of
 *   marker parameters; restart point has not been moved.  Same routine
 *   will be called again after application supplies more input data.
 *
 * This approach to suspension assumes that all of a marker's parameters
 * can fit into a single input bufferload.  This should hold for "normal"
 * markers.  Some COM/APPn markers might have large parameter segments
 * that might not fit.  If we are simply dropping such a marker, we use
 * skip_input_data to get past it, and thereby put the problem on the
 * source manager's shoulders.  If we are saving the marker's contents
 * into memory, we use a slightly different convention: when forced to
 * suspend, the marker processor updates the restart point to the end of
 * what it's consumed (ie, the end of the buffer) before returning FALSE.
 * On resumption, cinfo->unread_marker still contains the marker code,
 * but the data source will point to the next chunk of marker data.
 * The marker processor must retain internal state to deal with this.
 *
 * Note that we don't bother to avoid duplicate trace messages if a
 * suspension occurs within marker parameters.  Other side effects
 * require more care.
 */


LOCAL(boolean)
get_soi (j_decompress_ptr cinfo)
/* Process an SOI marker */
{
  int i;
  
  TRACEMS(cinfo, 1, JTRC_SOI);

  if (cinfo->marker->saw_SOI)
    ERREXIT(cinfo, JERR_SOI_DUPLICATE);

  /* Reset all parameters that are defined to be reset by SOI */

  for (i = 0; i < NUM_ARITH_TBLS; i++) {
    cinfo->arith_dc_L[i] = 0;
    cinfo->arith_dc_U[i] = 1;
    cinfo->arith_ac_K[i] = 5;
  }
  cinfo->restart_interval = 0;

  /* Set initial assumptions for colorspace etc */

  cinfo->jpeg_color_space = JCS_UNKNOWN;
  cinfo->CCIR601_sampling = FALSE; /* Assume non-CCIR sampling??? */

  cinfo->saw_JFIF_marker = FALSE;
  cinfo->JFIF_major_version = 1; /* set default JFIF APP0 values */
  cinfo->JFIF_minor_version = 1;
  cinfo->density_unit = 0;
  cinfo->X_density = 1;
  cinfo->Y_density = 1;
  cinfo->saw_Adobe_marker = FALSE;
  cinfo->Adobe_transform = 0;

  cinfo->marker->saw_SOI = TRUE;

  return TRUE;
}


LOCAL(boolean)
get_sof (j_decompress_ptr cinfo, boolean is_prog, boolean is_arith)
/* Process a SOFn marker */
{
  INT32 length;
  int c, ci;
  jpeg_component_info * compptr;
  INPUT_VARS(cinfo);

  cinfo->progressive_mode = is_prog;
  cinfo->arith_code = is_arith;

  INPUT_2BYTES(cinfo, length, return FALSE);

  INPUT_BYTE(cinfo, cinfo->data_precision, return FALSE);
  INPUT_2BYTES(cinfo, cinfo->image_height, return FALSE);
  INPUT_2BYTES(cinfo, cinfo->image_width, return FALSE);
  INPUT_BYTE(cinfo, cinfo->num_components, return FALSE);

  length -= 8;

  TRACEMS4(cinfo, 1, JTRC_SOF, cinfo->unread_marker,
	   (int) cinfo->image_width, (int) cinfo->image_height,
	   cinfo->num_components);

  if (cinfo->marker->saw_SOF)
    ERREXIT(cinfo, JERR_SOF_DUPLICATE);

  /* We don't support files in which the image height is initially specified */
  /* as 0 and is later redefined by DNL.  As long as we have to check that,  */
  /* might as well have a general sanity check. */
  if (cinfo->image_height <= 0 || cinfo->image_width <= 0
      || cinfo->num_components <= 0)
    ERREXIT(cinfo, JERR_EMPTY_IMAGE);

  if (length != (cinfo->num_components * 3))
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  if (cinfo->comp_info == NULL)	/* do only once, even if suspend */
    cinfo->comp_info = (jpeg_component_info *) (*cinfo->mem->alloc_small)
			((j_common_ptr) cinfo, JPOOL_IMAGE,
			 cinfo->num_components * SIZEOF(jpeg_component_info));
  
  for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
       ci++, compptr++) {
    compptr->component_index = ci;
    INPUT_BYTE(cinfo, compptr->component_id, return FALSE);
    INPUT_BYTE(cinfo, c, return FALSE);
    compptr->h_samp_factor = (c >> 4) & 15;
    compptr->v_samp_factor = (c     ) & 15;
    INPUT_BYTE(cinfo, compptr->quant_tbl_no, return FALSE);

    TRACEMS4(cinfo, 1, JTRC_SOF_COMPONENT,
	     compptr->component_id, compptr->h_samp_factor,
	     compptr->v_samp_factor, compptr->quant_tbl_no);
  }

  cinfo->marker->saw_SOF = TRUE;

  INPUT_SYNC(cinfo);
  return TRUE;
}


LOCAL(boolean)
get_sos (j_decompress_ptr cinfo)
/* Process a SOS marker */
{
  INT32 length;
  int i, ci, n, c, cc;
  jpeg_component_info * compptr;
  INPUT_VARS(cinfo);

  if (! cinfo->marker->saw_SOF)
    ERREXIT(cinfo, JERR_SOS_NO_SOF);

  INPUT_2BYTES(cinfo, length, return FALSE);

  INPUT_BYTE(cinfo, n, return FALSE); /* Number of components */

  TRACEMS1(cinfo, 1, JTRC_SOS, n);

  if (length != (n * 2 + 6) || n < 1 || n > MAX_COMPS_IN_SCAN)
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  cinfo->comps_in_scan = n;

  /* Collect the component-spec parameters */

  for (i = 0; i < n; i++) {
    INPUT_BYTE(cinfo, cc, return FALSE);
    INPUT_BYTE(cinfo, c, return FALSE);
    
    for (ci = 0, compptr = cinfo->comp_info; ci < cinfo->num_components;
	 ci++, compptr++) {
      if (cc == compptr->component_id)
	goto id_found;
    }

    ERREXIT1(cinfo, JERR_BAD_COMPONENT_ID, cc);

  id_found:

    cinfo->cur_comp_info[i] = compptr;
    compptr->dc_tbl_no = (c >> 4) & 15;
    compptr->ac_tbl_no = (c     ) & 15;
    
    TRACEMS3(cinfo, 1, JTRC_SOS_COMPONENT, cc,
	     compptr->dc_tbl_no, compptr->ac_tbl_no);

    /* This CSi (cc) should differ from the previous CSi */
    for (ci = 0; ci < i; ci++) {
      if (cinfo->cur_comp_info[ci] == compptr)
        ERREXIT1(cinfo, JERR_BAD_COMPONENT_ID, cc);
    }
  }

  /* Collect the additional scan parameters Ss, Se, Ah/Al. */
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Ss = c;
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Se = c;
  INPUT_BYTE(cinfo, c, return FALSE);
  cinfo->Ah = (c >> 4) & 15;
  cinfo->Al = (c     ) & 15;

  TRACEMS4(cinfo, 1, JTRC_SOS_PARAMS, cinfo->Ss, cinfo->Se,
	   cinfo->Ah, cinfo->Al);

  /* Prepare to scan data & restart markers */
  cinfo->marker->next_restart_num = 0;

  /* Count another SOS marker */
  cinfo->input_scan_number++;

  INPUT_SYNC(cinfo);
  return TRUE;
}


#ifdef D_ARITH_CODING_SUPPORTED

LOCAL(boolean)
get_dac (j_decompress_ptr cinfo)
/* Process a DAC marker */
{
  INT32 length;
  int index, val;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;
  
  while (length > 0) {
    INPUT_BYTE(cinfo, index, return FALSE);
    INPUT_BYTE(cinfo, val, return FALSE);

    length -= 2;

    TRACEMS2(cinfo, 1, JTRC_DAC, index, val);

    if (index < 0 || index >= (2*NUM_ARITH_TBLS))
      ERREXIT1(cinfo, JERR_DAC_INDEX, index);

    if (index >= NUM_ARITH_TBLS) { /* define AC table */
      cinfo->arith_ac_K[index-NUM_ARITH_TBLS] = (UINT8) val;
    } else {			/* define DC table */
      cinfo->arith_dc_L[index] = (UINT8) (val & 0x0F);
      cinfo->arith_dc_U[index] = (UINT8) (val >> 4);
      if (cinfo->arith_dc_L[index] > cinfo->arith_dc_U[index])
	ERREXIT1(cinfo, JERR_DAC_VALUE, val);
    }
  }

  if (length != 0)
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  INPUT_SYNC(cinfo);
  return TRUE;
}

#else /* ! D_ARITH_CODING_SUPPORTED */

#define get_dac(cinfo)  skip_variable(cinfo)

#endif /* D_ARITH_CODING_SUPPORTED */


LOCAL(boolean)
get_dht (j_decompress_ptr cinfo)
/* Process a DHT marker */
{
  INT32 length;
  UINT8 bits[17];
  UINT8 huffval[256];
  int i, index, count;
  JHUFF_TBL **htblptr;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;
  
  while (length > 16) {
    INPUT_BYTE(cinfo, index, return FALSE);

    TRACEMS1(cinfo, 1, JTRC_DHT, index);
      
    bits[0] = 0;
    count = 0;
    for (i = 1; i <= 16; i++) {
      INPUT_BYTE(cinfo, bits[i], return FALSE);
      count += bits[i];
    }

    length -= 1 + 16;

    TRACEMS8(cinfo, 2, JTRC_HUFFBITS,
	     bits[1], bits[2], bits[3], bits[4],
	     bits[5], bits[6], bits[7], bits[8]);
    TRACEMS8(cinfo, 2, JTRC_HUFFBITS,
	     bits[9], bits[10], bits[11], bits[12],
	     bits[13], bits[14], bits[15], bits[16]);

    /* Here we just do minimal validation of the counts to avoid walking
     * off the end of our table space.  jdhuff.c will check more carefully.
     */
    if (count > 256 || ((INT32) count) > length)
      ERREXIT(cinfo, JERR_BAD_HUFF_TABLE);

    for (i = 0; i < count; i++)
      INPUT_BYTE(cinfo, huffval[i], return FALSE);

    length -= count;

    if (index & 0x10) {		/* AC table definition */
      index -= 0x10;
      htblptr = &cinfo->ac_huff_tbl_ptrs[index];
    } else {			/* DC table definition */
      htblptr = &cinfo->dc_huff_tbl_ptrs[index];
    }

    if (index < 0 || index >= NUM_HUFF_TBLS)
      ERREXIT1(cinfo, JERR_DHT_INDEX, index);

    if (*htblptr == NULL)
      *htblptr = jpeg_alloc_huff_table((j_common_ptr) cinfo);
  
    MEMCOPY((*htblptr)->bits, bits, SIZEOF((*htblptr)->bits));
    MEMCOPY((*htblptr)->huffval, huffval, SIZEOF((*htblptr)->huffval));
  }

  if (length != 0)
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  INPUT_SYNC(cinfo);
  return TRUE;
}


LOCAL(boolean)
get_dqt (j_decompress_ptr cinfo)
/* Process a DQT marker */
{
  INT32 length;
  int n, i, prec;
  unsigned int tmp;
  JQUANT_TBL *quant_ptr;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  while (length > 0) {
    INPUT_BYTE(cinfo, n, return FALSE);
    prec = n >> 4;
    n &= 0x0F;

    TRACEMS2(cinfo, 1, JTRC_DQT, n, prec);

    if (n >= NUM_QUANT_TBLS)
      ERREXIT1(cinfo, JERR_DQT_INDEX, n);
      
    if (cinfo->quant_tbl_ptrs[n] == NULL)
      cinfo->quant_tbl_ptrs[n] = jpeg_alloc_quant_table((j_common_ptr) cinfo);
    quant_ptr = cinfo->quant_tbl_ptrs[n];

    for (i = 0; i < DCTSIZE2; i++) {
      if (prec)
	INPUT_2BYTES(cinfo, tmp, return FALSE);
      else
	INPUT_BYTE(cinfo, tmp, return FALSE);
      /* We convert the zigzag-order table to natural array order. */
      quant_ptr->quantval[jpeg_natural_order[i]] = (UINT16) tmp;
    }

    if (cinfo->err->trace_level >= 2) {
      for (i = 0; i < DCTSIZE2; i += 8) {
	TRACEMS8(cinfo, 2, JTRC_QUANTVALS,
		 quant_ptr->quantval[i],   quant_ptr->quantval[i+1],
		 quant_ptr->quantval[i+2], quant_ptr->quantval[i+3],
		 quant_ptr->quantval[i+4], quant_ptr->quantval[i+5],
		 quant_ptr->quantval[i+6], quant_ptr->quantval[i+7]);
      }
    }

    length -= DCTSIZE2+1;
    if (prec) length -= DCTSIZE2;
  }

  if (length != 0)
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  INPUT_SYNC(cinfo);
  return TRUE;
}


LOCAL(boolean)
get_dri (j_decompress_ptr cinfo)
/* Process a DRI marker */
{
  INT32 length;
  unsigned int tmp;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  
  if (length != 4)
    ERREXIT(cinfo, JERR_BAD_LENGTH);

  INPUT_2BYTES(cinfo, tmp, return FALSE);

  TRACEMS1(cinfo, 1, JTRC_DRI, tmp);

  cinfo->restart_interval = tmp;

  INPUT_SYNC(cinfo);
  return TRUE;
}


/*
 * Routines for processing APPn and COM markers.
 * These are either saved in memory or discarded, per application request.
 * APP0 and APP14 are specially checked to see if they are
 * JFIF and Adobe markers, respectively.
 */

#define APP0_DATA_LEN	14	/* Length of interesting data in APP0 */
#define APP14_DATA_LEN	12	/* Length of interesting data in APP14 */
#define APPN_DATA_LEN	14	/* Must be the largest of the above!! */


LOCAL(void)
examine_app0 (j_decompress_ptr cinfo, JOCTET FAR * data,
	      unsigned int datalen, INT32 remaining)
/* Examine first few bytes from an APP0.
 * Take appropriate action if it is a JFIF marker.
 * datalen is # of bytes at data[], remaining is length of rest of marker data.
 */
{
  INT32 totallen = (INT32) datalen + remaining;

  if (datalen >= APP0_DATA_LEN &&
      GETJOCTET(data[0]) == 0x4A &&
      GETJOCTET(data[1]) == 0x46 &&
      GETJOCTET(data[2]) == 0x49 &&
      GETJOCTET(data[3]) == 0x46 &&
      GETJOCTET(data[4]) == 0) {
    /* Found JFIF APP0 marker: save info */
    cinfo->saw_JFIF_marker = TRUE;
    cinfo->JFIF_major_version = GETJOCTET(data[5]);
    cinfo->JFIF_minor_version = GETJOCTET(data[6]);
    cinfo->density_unit = GETJOCTET(data[7]);
    cinfo->X_density = (GETJOCTET(data[8]) << 8) + GETJOCTET(data[9]);
    cinfo->Y_density = (GETJOCTET(data[10]) << 8) + GETJOCTET(data[11]);
    /* Check version.
     * Major version must be 1, anything else signals an incompatible change.
     * (We used to treat this as an error, but now it's a nonfatal warning,
     * because some bozo at Hijaak couldn't read the spec.)
     * Minor version should be 0..2, but process anyway if newer.
     */
    if (cinfo->JFIF_major_version != 1)
      WARNMS2(cinfo, JWRN_JFIF_MAJOR,
	      cinfo->JFIF_major_version, cinfo->JFIF_minor_version);
    /* Generate trace messages */
    TRACEMS5(cinfo, 1, JTRC_JFIF,
	     cinfo->JFIF_major_version, cinfo->JFIF_minor_version,
	     cinfo->X_density, cinfo->Y_density, cinfo->density_unit);
    /* Validate thumbnail dimensions and issue appropriate messages */
    if (GETJOCTET(data[12]) | GETJOCTET(data[13]))
      TRACEMS2(cinfo, 1, JTRC_JFIF_THUMBNAIL,
	       GETJOCTET(data[12]), GETJOCTET(data[13]));
    totallen -= APP0_DATA_LEN;
    if (totallen !=
	((INT32)GETJOCTET(data[12]) * (INT32)GETJOCTET(data[13]) * (INT32) 3))
      TRACEMS1(cinfo, 1, JTRC_JFIF_BADTHUMBNAILSIZE, (int) totallen);
  } else if (datalen >= 6 &&
      GETJOCTET(data[0]) == 0x4A &&
      GETJOCTET(data[1]) == 0x46 &&
      GETJOCTET(data[2]) == 0x58 &&
      GETJOCTET(data[3]) == 0x58 &&
      GETJOCTET(data[4]) == 0) {
    /* Found JFIF "JFXX" extension APP0 marker */
    /* The library doesn't actually do anything with these,
     * but we try to produce a helpful trace message.
     */
    switch (GETJOCTET(data[5])) {
    case 0x10:
      TRACEMS1(cinfo, 1, JTRC_THUMB_JPEG, (int) totallen);
      break;
    case 0x11:
      TRACEMS1(cinfo, 1, JTRC_THUMB_PALETTE, (int) totallen);
      break;
    case 0x13:
      TRACEMS1(cinfo, 1, JTRC_THUMB_RGB, (int) totallen);
      break;
    default:
      TRACEMS2(cinfo, 1, JTRC_JFIF_EXTENSION,
	       GETJOCTET(data[5]), (int) totallen);
      break;
    }
  } else {
    /* Start of APP0 does not match "JFIF" or "JFXX", or too short */
    TRACEMS1(cinfo, 1, JTRC_APP0, (int) totallen);
  }
}


LOCAL(void)
examine_app14 (j_decompress_ptr cinfo, JOCTET FAR * data,
	       unsigned int datalen, INT32 remaining)
/* Examine first few bytes from an APP14.
 * Take appropriate action if it is an Adobe marker.
 * datalen is # of bytes at data[], remaining is length of rest of marker data.
 */
{
  unsigned int version, flags0, flags1, transform;

  if (datalen >= APP14_DATA_LEN &&
      GETJOCTET(data[0]) == 0x41 &&
      GETJOCTET(data[1]) == 0x64 &&
      GETJOCTET(data[2]) == 0x6F &&
      GETJOCTET(data[3]) == 0x62 &&
      GETJOCTET(data[4]) == 0x65) {
    /* Found Adobe APP14 marker */
    version = (GETJOCTET(data[5]) << 8) + GETJOCTET(data[6]);
    flags0 = (GETJOCTET(data[7]) << 8) + GETJOCTET(data[8]);
    flags1 = (GETJOCTET(data[9]) << 8) + GETJOCTET(data[10]);
    transform = GETJOCTET(data[11]);
    TRACEMS4(cinfo, 1, JTRC_ADOBE, version, flags0, flags1, transform);
    cinfo->saw_Adobe_marker = TRUE;
    cinfo->Adobe_transform = (UINT8) transform;
  } else {
    /* Start of APP14 does not match "Adobe", or too short */
    TRACEMS1(cinfo, 1, JTRC_APP14, (int) (datalen + remaining));
  }
}


METHODDEF(boolean)
get_interesting_appn (j_decompress_ptr cinfo)
/* Process an APP0 or APP14 marker without saving it */
{
  INT32 length;
  JOCTET b[APPN_DATA_LEN];
  unsigned int i, numtoread;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;

  /* get the interesting part of the marker data */
  if (length >= APPN_DATA_LEN)
    numtoread = APPN_DATA_LEN;
  else if (length > 0)
    numtoread = (unsigned int) length;
  else
    numtoread = 0;
  for (i = 0; i < numtoread; i++)
    INPUT_BYTE(cinfo, b[i], return FALSE);
  length -= numtoread;

  /* process it */
  switch (cinfo->unread_marker) {
  case M_APP0:
    examine_app0(cinfo, (JOCTET FAR *) b, numtoread, length);
    break;
  case M_APP14:
    examine_app14(cinfo, (JOCTET FAR *) b, numtoread, length);
    break;
  default:
    /* can't get here unless jpeg_save_markers chooses wrong processor */
    ERREXIT1(cinfo, JERR_UNKNOWN_MARKER, cinfo->unread_marker);
    break;
  }

  /* skip any remaining data -- could be lots */
  INPUT_SYNC(cinfo);
  if (length > 0)
    (*cinfo->src->skip_input_data) (cinfo, (long) length);

  return TRUE;
}


#ifdef SAVE_MARKERS_SUPPORTED

METHODDEF(boolean)
save_marker (j_decompress_ptr cinfo)
/* Save an APPn or COM marker into the marker list */
{
  my_marker_ptr marker = (my_marker_ptr) cinfo->marker;
  jpeg_saved_marker_ptr cur_marker = marker->cur_marker;
  unsigned int bytes_read, data_length;
  JOCTET FAR * data;
  INT32 length = 0;
  INPUT_VARS(cinfo);

  if (cur_marker == NULL) {
    /* begin reading a marker */
    INPUT_2BYTES(cinfo, length, return FALSE);
    length -= 2;
    if (length >= 0) {		/* watch out for bogus length word */
      /* figure out how much we want to save */
      unsigned int limit;
      if (cinfo->unread_marker == (int) M_COM)
	limit = marker->length_limit_COM;
      else
	limit = marker->length_limit_APPn[cinfo->unread_marker - (int) M_APP0];
      if ((unsigned int) length < limit)
	limit = (unsigned int) length;
      /* allocate and initialize the marker item */
      cur_marker = (jpeg_saved_marker_ptr)
	(*cinfo->mem->alloc_large) ((j_common_ptr) cinfo, JPOOL_IMAGE,
				    SIZEOF(struct jpeg_marker_struct) + limit);
      cur_marker->next = NULL;
      cur_marker->marker = (UINT8) cinfo->unread_marker;
      cur_marker->original_length = (unsigned int) length;
      cur_marker->data_length = limit;
      /* data area is just beyond the jpeg_marker_struct */
      data = cur_marker->data = (JOCTET FAR *) (cur_marker + 1);
      marker->cur_marker = cur_marker;
      marker->bytes_read = 0;
      bytes_read = 0;
      data_length = limit;
    } else {
      /* deal with bogus length word */
      bytes_read = data_length = 0;
      data = NULL;
    }
  } else {
    /* resume reading a marker */
    bytes_read = marker->bytes_read;
    data_length = cur_marker->data_length;
    data = cur_marker->data + bytes_read;
  }

  while (bytes_read < data_length) {
    INPUT_SYNC(cinfo);		/* move the restart point to here */
    marker->bytes_read = bytes_read;
    /* If there's not at least one byte in buffer, suspend */
    MAKE_BYTE_AVAIL(cinfo, return FALSE);
    /* Copy bytes with reasonable rapidity */
    while (bytes_read < data_length && bytes_in_buffer > 0) {
      *data++ = *next_input_byte++;
      bytes_in_buffer--;
      bytes_read++;
    }
  }

  /* Done reading what we want to read */
  if (cur_marker != NULL) {	/* will be NULL if bogus length word */
    /* Add new marker to end of list */
    if (cinfo->marker_list == NULL) {
      cinfo->marker_list = cur_marker;
    } else {
      jpeg_saved_marker_ptr prev = cinfo->marker_list;
      while (prev->next != NULL)
	prev = prev->next;
      prev->next = cur_marker;
    }
    /* Reset pointer & calc remaining data length */
    data = cur_marker->data;
    length = cur_marker->original_length - data_length;
  }
  /* Reset to initial state for next marker */
  marker->cur_marker = NULL;

  /* Process the marker if interesting; else just make a generic trace msg */
  switch (cinfo->unread_marker) {
  case M_APP0:
    examine_app0(cinfo, data, data_length, length);
    break;
  case M_APP14:
    examine_app14(cinfo, data, data_length, length);
    break;
  default:
    TRACEMS2(cinfo, 1, JTRC_MISC_MARKER, cinfo->unread_marker,
	     (int) (data_length + length));
    break;
  }

  /* skip any remaining data -- could be lots */
  INPUT_SYNC(cinfo);		/* do before skip_input_data */
  if (length > 0)
    (*cinfo->src->skip_input_data) (cinfo, (long) length);

  return TRUE;
}

#endif /* SAVE_MARKERS_SUPPORTED */


METHODDEF(boolean)
skip_variable (j_decompress_ptr cinfo)
/* Skip over an unknown or uninteresting variable-length marker */
{
  INT32 length;
  INPUT_VARS(cinfo);

  INPUT_2BYTES(cinfo, length, return FALSE);
  length -= 2;
  
  TRACEMS2(cinfo, 1, JTRC_MISC_MARKER, cinfo->unread_marker, (int) length);

  INPUT_SYNC(cinfo);		/* do before skip_input_data */
  if (length > 0)
    (*cinfo->src->skip_input_data) (cinfo, (long) length);

  return TRUE;
}


/*
 * Find the next JPEG marker, save it in cinfo->unread_marker.
 * Returns FALSE if had to suspend before reaching a marker;
 * in that case cinfo->unread_marker is unchanged.
 *
 * Note that the result might not be a valid marker code,
 * but it will never be 0 or FF.
 */

LOCAL(boolean)
next_marker (j_decompress_ptr cinfo)
{
  int c;
  INPUT_VARS(cinfo);

  for (;;) {
    INPUT_BYTE(cinfo, c, return FALSE);
    /* Skip any non-FF bytes.
     * This may look a bit inefficient, but it will not occur in a valid file.
     * We sync after each discarded byte so that a suspending data source
     * can discard the byte from its buffer.
     */
    while (c != 0xFF) {
      cinfo->marker->discarded_bytes++;
      INPUT_SYNC(cinfo);
      INPUT_BYTE(cinfo, c, return FALSE);
    }
    /* This loop swallows any duplicate FF bytes.  Extra FFs are legal as
     * pad bytes, so don't count them in discarded_bytes.  We assume there
     * will not be so many consecutive FF bytes as to overflow a suspending
     * data source's input buffer.
     */
    do {
      INPUT_BYTE(cinfo, c, return FALSE);
    } while (c == 0xFF);
    if (c != 0)
      break;			/* found a valid marker, exit loop */
    /* Reach here if we found a stuffed-zero data sequence (FF/00).
     * Discard it and loop back to try again.
     */
    cinfo->marker->discarded_bytes += 2;
    INPUT_SYNC(cinfo);
  }

  if (cinfo->marker->discarded_bytes != 0) {
    WARNMS2(cinfo, JWRN_EXTRANEOUS_DATA, cinfo->marker->discarded_bytes, c);
    cinfo->marker->discarded_bytes = 0;
  }

  cinfo->unread_marker = c;

  INPUT_SYNC(cinfo);
  return TRUE;
}


LOCAL(boolean)
first_marker (j_decompress_ptr cinfo)
/* Like next_marker, but used to obtain the initial SOI marker. */
/* For this marker, we do not allow preceding garbage or fill; otherwise,
 * we might well scan an entire input file before realizing it ain't JPEG.
 * If an application wants to process non-JFIF files, it must seek to the
 * SOI before calling the JPEG library.
 */
{
  int c, c2;
  INPUT_VARS(cinfo);

  INPUT_BYTE(cinfo, c, return FALSE);
  INPUT_BYTE(cinfo, c2, return FALSE);
  if (c != 0xFF || c2 != (int) M_SOI)
    ERREXIT2(cinfo, JERR_NO_SOI, c, c2);

  cinfo->unread_marker = c2;

  INPUT_SYNC(cinfo);
  return TRUE;
}


/*
 * Read markers until SOS or EOI.
 *
 * Returns same codes as are defined for jpeg_consume_input:
 * JPEG_SUSPENDED, JPEG_REACHED_SOS, or JPEG_REACHED_EOI.
 */

METHODDEF(int)
read_markers (j_decompress_ptr cinfo)
{
  /* Outer loop repeats once for each marker. */
  for (;;) {
    /* Collect the marker proper, unless we already did. */
    /* NB: first_marker() enforces the requirement that SOI appear first. */
    if (cinfo->unread_marker == 0) {
      if (! cinfo->marker->saw_SOI) {
	if (! first_marker(cinfo))
	  return JPEG_SUSPENDED;
      } else {
	if (! next_marker(cinfo))
	  return JPEG_SUSPENDED;
      }
    }
    /* At this point cinfo->unread_marker contains the marker code and the
     * input point is just past the marker proper, but before any parameters.
     * A suspension will cause us to return with this state still true.
     */
    switch (cinfo->unread_marker) {
    case M_SOI:
      if (! get_soi(cinfo))
	return JPEG_SUSPENDED;
      break;

    case M_SOF0:		/* Baseline */
    case M_SOF1:		/* Extended sequential, Huffman */
      if (! get_sof(cinfo, FALSE, FALSE))
	return JPEG_SUSPENDED;
      break;

    case M_SOF2:		/* Progressive, Huffman */
      if (! get_sof(cinfo, TRUE, FALSE))
	return JPEG_SUSPENDED;
      break;

    case M_SOF9:		/* Extended sequential, arithmetic */
      if (! get_sof(cinfo, FALSE, TRUE))
	return JPEG_SUSPENDED;
      break;

    case M_SOF10:		/* Progressive, arithmetic */
      if (! get_sof(cinfo, TRUE, TRUE))
	return JPEG_SUSPENDED;
      break;

    /* Currently unsupported SOFn types */
    case M_SOF3:		/* Lossless, Huffman */
    case M_SOF5:		/* Differential sequential, Huffman */
    case M_SOF6:		/* Differential progressive, Huffman */
    case M_SOF7:		/* Differential lossless, Huffman */
    case M_JPG:			/* Reserved for JPEG extensions */
    case M_SOF11:		/* Lossless, arithmetic */
    case M_SOF13:		/* Differential sequential, arithmetic */
    case M_SOF14:		/* Differential progressive, arithmetic */
    case M_SOF15:		/* Differential lossless, arithmetic */
      ERREXIT1(cinfo, JERR_SOF_UNSUPPORTED, cinfo->unread_marker);
      break;

    case M_SOS:
      if (! get_sos(cinfo))
	return JPEG_SUSPENDED;
      cinfo->unread_marker = 0;	/* processed the marker */
      return JPEG_REACHED_SOS;
    
    case M_EOI:
      TRACEMS(cinfo, 1, JTRC_EOI);
      cinfo->unread_marker = 0;	/* processed the marker */
      return JPEG_REACHED_EOI;
      
    case M_DAC:
      if (! get_dac(cinfo))
	return JPEG_SUSPENDED;
      break;
      
    case M_DHT:
      if (! get_dht(cinfo))
	return JPEG_SUSPENDED;
      break;
      
    case M_DQT:
      if (! get_dqt(cinfo))
	return JPEG_SUSPENDED;
      break;
      
    case M_DRI:
      if (! get_dri(cinfo))
	return JPEG_SUSPENDED;
      break;
      
    case M_APP0:
    case M_APP1:
    case M_APP2:
    case M_APP3:
    case M_APP4:
    case M_APP5:
    case M_APP6:
    case M_APP7:
    case M_APP8:
    case M_APP9:
    case M_APP10:
    case M_APP11:
    case M_APP12:
    case M_APP13:
    case M_APP14:
    case M_APP15:
      if (! (*((my_marker_ptr) cinfo->marker)->process_APPn[
		cinfo->unread_marker - (int) M_APP0]) (cinfo))
	return JPEG_SUSPENDED;
      break;
      
    case M_COM:
      if (! (*((my_marker_ptr) cinfo->marker)->process_COM) (cinfo))
	return JPEG_SUSPENDED;
      break;

    case M_RST0:		/* these are all parameterless */
    case M_RST1:
    case M_RST2:
    case M_RST3:
    case M_RST4:
    case M_RST5:
    case M_RST6:
    case M_RST7:
    case M_TEM:
      TRACEMS1(cinfo, 1, JTRC_PARMLESS_MARKER, cinfo->unread_marker);
      break;

    case M_DNL:			/* Ignore DNL ... perhaps the wrong thing */
      if (! skip_variable(cinfo))
	return JPEG_SUSPENDED;
      break;

    default:			/* must be DHP, EXP, JPGn, or RESn */
      /* For now, we treat the reserved markers as fatal errors since they are
       * likely to be used to signal incompatible JPEG Part 3 extensions.
       * Once the JPEG 3 version-number marker is well defined, this code
       * ought to change!
       */
      ERREXIT1(cinfo, JERR_UNKNOWN_MARKER, cinfo->unread_marker);
      break;
    }
    /* Successfully processed marker, so reset state variable */
    cinfo->unread_marker = 0;
  } /* end loop */
}


/*
 * Read a restart marker, which is expected to appear next in the datastream;
 * if the marker is not there, take appropriate recovery action.
 * Returns FALSE if suspension is required.
 *
 * This is called by the entropy decoder after it has read an appropriate
 * number of MCUs.  cinfo->unread_marker may be nonzero if the entropy decoder
 * has already read a marker from the data source.  Under normal conditions
 * cinfo->unread_marker will be reset to 0 before returning; if not reset,
 * it holds a marker which the decoder will be unable to read past.
 */

METHODDEF(boolean)
read_restart_marker (j_decompress_ptr cinfo)
{
  /* Obtain a marker unless we already did. */
  /* Note that next_marker will complain if it skips any data. */
  if (cinfo->unread_marker == 0) {
    if (! next_marker(cinfo))
      return FALSE;
  }

  if (cinfo->unread_marker ==
      ((int) M_RST0 + cinfo->marker->next_restart_num)) {
    /* Normal case --- swallow the marker and let entropy decoder continue */
    TRACEMS1(cinfo, 3, JTRC_RST, cinfo->marker->next_restart_num);
    cinfo->unread_marker = 0;
  } else {
    /* Uh-oh, the restart markers have been messed up. */
    /* Let the data source manager determine how to resync. */
    if (! (*cinfo->src->resync_to_restart) (cinfo,
					    cinfo->marker->next_restart_num))
      return FALSE;
  }

  /* Update next-restart state */
  cinfo->marker->next_restart_num = (cinfo->marker->next_restart_num + 1) & 7;

  return TRUE;
}


/*
 * This is the default resync_to_restart method for data source managers
 * to use if they don't have any better approach.  Some data source managers
 * may be able to back up, or may have additional knowledge about the data
 * which permits a more intelligent recovery strategy; such managers would
 * presumably supply their own resync method.
 *
 * read_restart_marker calls resync_to_restart if it finds a marker other than
 * the restart marker it was expecting.  (This code is *not* used unless
 * a nonzero restart interval has been declared.)  cinfo->unread_marker is
 * the marker code actually found (might be anything, except 0 or FF).
 * The desired restart marker number (0..7) is passed as a parameter.
 * This routine is supposed to apply whatever error recovery strategy seems
 * appropriate in order to position the input stream to the next data segment.
 * Note that cinfo->unread_marker is treated as a marker appearing before
 * the current data-source input point; usually it should be reset to zero
 * before returning.
 * Returns FALSE if suspension is required.
 *
 * This implementation is substantially constrained by wanting to treat the
 * input as a data stream; this means we can't back up.  Therefore, we have
 * only the following actions to work with:
 *   1. Simply discard the marker and let the entropy decoder resume at next
 *      byte of file.
 *   2. Read forward until we find another marker, discarding intervening
 *      data.  (In theory we could look ahead within the current bufferload,
 *      without having to discard data if we don't find the desired marker.
 *      This idea is not implemented here, in part because it makes behavior
 *      dependent on buffer size and chance buffer-boundary positions.)
 *   3. Leave the marker unread (by failing to zero cinfo->unread_marker).
 *      This will cause the entropy decoder to process an empty data segment,
 *      inserting dummy zeroes, and then we will reprocess the marker.
 *
 * #2 is appropriate if we think the desired marker lies ahead, while #3 is
 * appropriate if the found marker is a future restart marker (indicating
 * that we have missed the desired restart marker, probably because it got
 * corrupted).
 * We apply #2 or #3 if the found marker is a restart marker no more than
 * two counts behind or ahead of the expected one.  We also apply #2 if the
 * found marker is not a legal JPEG marker code (it's certainly bogus data).
 * If the found marker is a restart marker more than 2 counts away, we do #1
 * (too much risk that the marker is erroneous; with luck we will be able to
 * resync at some future point).
 * For any valid non-restart JPEG marker, we apply #3.  This keeps us from
 * overrunning the end of a scan.  An implementation limited to single-scan
 * files might find it better to apply #2 for markers other than EOI, since
 * any other marker would have to be bogus data in that case.
 */

GLOBAL(boolean)
jpeg_resync_to_restart (j_decompress_ptr cinfo, int desired)
{
  int marker = cinfo->unread_marker;
  int action = 1;
  
  /* Always put up a warning. */
  WARNMS2(cinfo, JWRN_MUST_RESYNC, marker, desired);
  
  /* Outer loop handles repeated decision after scanning forward. */
  for (;;) {
    if (marker < (int) M_SOF0)
      action = 2;		/* invalid marker */
    else if (marker < (int) M_RST0 || marker > (int) M_RST7)
      action = 3;		/* valid non-restart marker */
    else {
      if (marker == ((int) M_RST0 + ((desired+1) & 7)) ||
	  marker == ((int) M_RST0 + ((desired+2) & 7)))
	action = 3;		/* one of the next two expected restarts */
      else if (marker == ((int) M_RST0 + ((desired-1) & 7)) ||
	       marker == ((int) M_RST0 + ((desired-2) & 7)))
	action = 2;		/* a prior restart, so advance */
      else
	action = 1;		/* desired restart or too far away */
    }
    TRACEMS2(cinfo, 4, JTRC_RECOVERY_ACTION, marker, action);
    switch (action) {
    case 1:
      /* Discard marker and let entropy decoder resume processing. */
      cinfo->unread_marker = 0;
      return TRUE;
    case 2:
      /* Scan to the next marker, and repeat the decision loop. */
      if (! next_marker(cinfo))
	return FALSE;
      marker = cinfo->unread_marker;
      break;
    case 3:
      /* Return without advancing past this marker. */
      /* Entropy decoder will be forced to process an empty segment. */
      return TRUE;
    }
  } /* end loop */
}


/*
 * Reset marker processing state to begin a fresh datastream.
 */

METHODDEF(void)
reset_marker_reader (j_decompress_ptr cinfo)
{
  my_marker_ptr marker = (my_marker_ptr) cinfo->marker;

  cinfo->comp_info = NULL;		/* until allocated by get_sof */
  cinfo->input_scan_number = 0;		/* no SOS seen yet */
  cinfo->unread_marker = 0;		/* no pending marker */
  marker->pub.saw_SOI = FALSE;		/* set internal state too */
  marker->pub.saw_SOF = FALSE;
  marker->pub.discarded_bytes = 0;
  marker->cur_marker = NULL;
}


/*
 * Initialize the marker reader module.
 * This is called only once, when the decompression object is created.
 */

GLOBAL(void)
jinit_marker_reader (j_decompress_ptr cinfo)
{
  my_marker_ptr marker;
  int i;

  /* Create subobject in permanent pool */
  marker = (my_marker_ptr)
    (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
				SIZEOF(my_marker_reader));
  cinfo->marker = (struct jpeg_marker_reader *) marker;
  /* Initialize public method pointers */
  marker->pub.reset_marker_reader = reset_marker_reader;
  marker->pub.read_markers = read_markers;
  marker->pub.read_restart_marker = read_restart_marker;
  /* Initialize COM/APPn processing.
   * By default, we examine and then discard APP0 and APP14,
   * but simply discard COM and all other APPn.
   */
  marker->process_COM = skip_variable;
  marker->length_limit_COM = 0;
  for (i = 0; i < 16; i++) {
    marker->process_APPn[i] = skip_variable;
    marker->length_limit_APPn[i] = 0;
  }
  marker->process_APPn[0] = get_interesting_appn;
  marker->process_APPn[14] = get_interesting_appn;
  /* Reset marker processing state */
  reset_marker_reader(cinfo);
}


/*
 * Control saving of COM and APPn markers into marker_list.
 */

#ifdef SAVE_MARKERS_SUPPORTED

GLOBAL(void)
jpeg_save_markers (j_decompress_ptr cinfo, int marker_code,
		   unsigned int length_limit)
{
  my_marker_ptr marker = (my_marker_ptr) cinfo->marker;
  long maxlength;
  jpeg_marker_parser_method processor;

  /* Length limit mustn't be larger than what we can allocate
   * (should only be a concern in a 16-bit environment).
   */
  maxlength = cinfo->mem->max_alloc_chunk - SIZEOF(struct jpeg_marker_struct);
  if (((long) length_limit) > maxlength)
    length_limit = (unsigned int) maxlength;

  /* Choose processor routine to use.
   * APP0/APP14 have special requirements.
   */
  if (length_limit) {
    processor = save_marker;
    /* If saving APP0/APP14, save at least enough for our internal use. */
    if (marker_code == (int) M_APP0 && length_limit < APP0_DATA_LEN)
      length_limit = APP0_DATA_LEN;
    else if (marker_code == (int) M_APP14 && length_limit < APP14_DATA_LEN)
      length_limit = APP14_DATA_LEN;
  } else {
    processor = skip_variable;
    /* If discarding APP0/APP14, use our regular on-the-fly processor. */
    if (marker_code == (int) M_APP0 || marker_code == (int) M_APP14)
      processor = get_interesting_appn;
  }

  if (marker_code == (int) M_COM) {
    marker->process_COM = processor;
    marker->length_limit_COM = length_limit;
  } else if (marker_code >= (int) M_APP0 && marker_code <= (int) M_APP15) {
    marker->process_APPn[marker_code - (int) M_APP0] = processor;
    marker->length_limit_APPn[marker_code - (int) M_APP0] = length_limit;
  } else
    ERREXIT1(cinfo, JERR_UNKNOWN_MARKER, marker_code);
}

#endif /* SAVE_MARKERS_SUPPORTED */


/*
 * Install a special processing method for COM or APPn markers.
 */

GLOBAL(void)
jpeg_set_marker_processor (j_decompress_ptr cinfo, int marker_code,
			   jpeg_marker_parser_method routine)
{
  my_marker_ptr marker = (my_marker_ptr) cinfo->marker;

  if (marker_code == (int) M_COM)
    marker->process_COM = routine;
  else if (marker_code >= (int) M_APP0 && marker_code <= (int) M_APP15)
    marker->process_APPn[marker_code - (int) M_APP0] = routine;
  else
    ERREXIT1(cinfo, JERR_UNKNOWN_MARKER, marker_code);
}
