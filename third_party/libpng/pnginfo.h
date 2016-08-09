
/* pnginfo.h - header file for PNG reference library
 *
 * Last changed in libpng 1.6.1 [March 28, 2013]
 * Copyright (c) 1998-2002,2004,2006-2013 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

 /* png_info is a structure that holds the information in a PNG file so
 * that the application can find out the characteristics of the image.
 * If you are reading the file, this structure will tell you what is
 * in the PNG file.  If you are writing the file, fill in the information
 * you want to put into the PNG file, using png_set_*() functions, then
 * call png_write_info().
 *
 * The names chosen should be very close to the PNG specification, so
 * consult that document for information about the meaning of each field.
 *
 * With libpng < 0.95, it was only possible to directly set and read the
 * the values in the png_info_struct, which meant that the contents and
 * order of the values had to remain fixed.  With libpng 0.95 and later,
 * however, there are now functions that abstract the contents of
 * png_info_struct from the application, so this makes it easier to use
 * libpng with dynamic libraries, and even makes it possible to use
 * libraries that don't have all of the libpng ancillary chunk-handing
 * functionality.  In libpng-1.5.0 this was moved into a separate private
 * file that is not visible to applications.
 *
 * The following members may have allocated storage attached that should be
 * cleaned up before the structure is discarded: palette, trans, text,
 * pcal_purpose, pcal_units, pcal_params, hist, iccp_name, iccp_profile,
 * splt_palettes, scal_unit, row_pointers, and unknowns.   By default, these
 * are automatically freed when the info structure is deallocated, if they were
 * allocated internally by libpng.  This behavior can be changed by means
 * of the png_data_freer() function.
 *
 * More allocation details: all the chunk-reading functions that
 * change these members go through the corresponding png_set_*
 * functions.  A function to clear these members is available: see
 * png_free_data().  The png_set_* functions do not depend on being
 * able to point info structure members to any of the storage they are
 * passed (they make their own copies), EXCEPT that the png_set_text
 * functions use the same storage passed to them in the text_ptr or
 * itxt_ptr structure argument, and the png_set_rows and png_set_unknowns
 * functions do not make their own copies.
 */
#ifndef PNGINFO_H
#define PNGINFO_H

struct png_info_def
{
   /* The following are necessary for every PNG file */
   png_uint_32 width;  /* width of image in pixels (from IHDR) */
   png_uint_32 height; /* height of image in pixels (from IHDR) */
   png_uint_32 valid;  /* valid chunk data (see PNG_INFO_ below) */
   png_size_t rowbytes; /* bytes needed to hold an untransformed row */
   png_colorp palette;      /* array of color values (valid & PNG_INFO_PLTE) */
   png_uint_16 num_palette; /* number of color entries in "palette" (PLTE) */
   png_uint_16 num_trans;   /* number of transparent palette color (tRNS) */
   png_byte bit_depth;      /* 1, 2, 4, 8, or 16 bits/channel (from IHDR) */
   png_byte color_type;     /* see PNG_COLOR_TYPE_ below (from IHDR) */
   /* The following three should have been named *_method not *_type */
   png_byte compression_type; /* must be PNG_COMPRESSION_TYPE_BASE (IHDR) */
   png_byte filter_type;    /* must be PNG_FILTER_TYPE_BASE (from IHDR) */
   png_byte interlace_type; /* One of PNG_INTERLACE_NONE, PNG_INTERLACE_ADAM7 */

   /* The following are set by png_set_IHDR, called from the application on
    * write, but the are never actually used by the write code.
    */
   png_byte channels;       /* number of data channels per pixel (1, 2, 3, 4) */
   png_byte pixel_depth;    /* number of bits per pixel */
   png_byte spare_byte;     /* to align the data, and for future use */

#ifdef PNG_READ_SUPPORTED
   /* This is never set during write */
   png_byte signature[8];   /* magic bytes read by libpng from start of file */
#endif

   /* The rest of the data is optional.  If you are reading, check the
    * valid field to see if the information in these are valid.  If you
    * are writing, set the valid field to those chunks you want written,
    * and initialize the appropriate fields below.
    */

#if defined(PNG_COLORSPACE_SUPPORTED) || defined(PNG_GAMMA_SUPPORTED)
   /* png_colorspace only contains 'flags' if neither GAMMA or COLORSPACE are
    * defined.  When COLORSPACE is switched on all the colorspace-defining
    * chunks should be enabled, when GAMMA is switched on all the gamma-defining
    * chunks should be enabled.  If this is not done it becomes possible to read
    * inconsistent PNG files and assign a probably incorrect interpretation to
    * the information.  (In other words, by carefully choosing which chunks to
    * recognize the system configuration can select an interpretation for PNG
    * files containing ambiguous data and this will result in inconsistent
    * behavior between different libpng builds!)
    */
   png_colorspace colorspace;
#endif

#ifdef PNG_iCCP_SUPPORTED
   /* iCCP chunk data. */
   png_charp iccp_name;     /* profile name */
   png_bytep iccp_profile;  /* International Color Consortium profile data */
   png_uint_32 iccp_proflen;  /* ICC profile data length */
#endif

#ifdef PNG_TEXT_SUPPORTED
   /* The tEXt, and zTXt chunks contain human-readable textual data in
    * uncompressed, compressed, and optionally compressed forms, respectively.
    * The data in "text" is an array of pointers to uncompressed,
    * null-terminated C strings. Each chunk has a keyword that describes the
    * textual data contained in that chunk.  Keywords are not required to be
    * unique, and the text string may be empty.  Any number of text chunks may
    * be in an image.
    */
   int num_text; /* number of comments read or comments to write */
   int max_text; /* current size of text array */
   png_textp text; /* array of comments read or comments to write */
#endif /* TEXT */

#ifdef PNG_tIME_SUPPORTED
   /* The tIME chunk holds the last time the displayed image data was
    * modified.  See the png_time struct for the contents of this struct.
    */
   png_time mod_time;
#endif

#ifdef PNG_sBIT_SUPPORTED
   /* The sBIT chunk specifies the number of significant high-order bits
    * in the pixel data.  Values are in the range [1, bit_depth], and are
    * only specified for the channels in the pixel data.  The contents of
    * the low-order bits is not specified.  Data is valid if
    * (valid & PNG_INFO_sBIT) is non-zero.
    */
   png_color_8 sig_bit; /* significant bits in color channels */
#endif

#if defined(PNG_tRNS_SUPPORTED) || defined(PNG_READ_EXPAND_SUPPORTED) || \
defined(PNG_READ_BACKGROUND_SUPPORTED)
   /* The tRNS chunk supplies transparency data for paletted images and
    * other image types that don't need a full alpha channel.  There are
    * "num_trans" transparency values for a paletted image, stored in the
    * same order as the palette colors, starting from index 0.  Values
    * for the data are in the range [0, 255], ranging from fully transparent
    * to fully opaque, respectively.  For non-paletted images, there is a
    * single color specified that should be treated as fully transparent.
    * Data is valid if (valid & PNG_INFO_tRNS) is non-zero.
    */
   png_bytep trans_alpha;    /* alpha values for paletted image */
   png_color_16 trans_color; /* transparent color for non-palette image */
#endif

#if defined(PNG_bKGD_SUPPORTED) || defined(PNG_READ_BACKGROUND_SUPPORTED)
   /* The bKGD chunk gives the suggested image background color if the
    * display program does not have its own background color and the image
    * is needs to composited onto a background before display.  The colors
    * in "background" are normally in the same color space/depth as the
    * pixel data.  Data is valid if (valid & PNG_INFO_bKGD) is non-zero.
    */
   png_color_16 background;
#endif

#ifdef PNG_oFFs_SUPPORTED
   /* The oFFs chunk gives the offset in "offset_unit_type" units rightwards
    * and downwards from the top-left corner of the display, page, or other
    * application-specific co-ordinate space.  See the PNG_OFFSET_ defines
    * below for the unit types.  Valid if (valid & PNG_INFO_oFFs) non-zero.
    */
   png_int_32 x_offset; /* x offset on page */
   png_int_32 y_offset; /* y offset on page */
   png_byte offset_unit_type; /* offset units type */
#endif

#ifdef PNG_pHYs_SUPPORTED
   /* The pHYs chunk gives the physical pixel density of the image for
    * display or printing in "phys_unit_type" units (see PNG_RESOLUTION_
    * defines below).  Data is valid if (valid & PNG_INFO_pHYs) is non-zero.
    */
   png_uint_32 x_pixels_per_unit; /* horizontal pixel density */
   png_uint_32 y_pixels_per_unit; /* vertical pixel density */
   png_byte phys_unit_type; /* resolution type (see PNG_RESOLUTION_ below) */
#endif

#ifdef PNG_hIST_SUPPORTED
   /* The hIST chunk contains the relative frequency or importance of the
    * various palette entries, so that a viewer can intelligently select a
    * reduced-color palette, if required.  Data is an array of "num_palette"
    * values in the range [0,65535]. Data valid if (valid & PNG_INFO_hIST)
    * is non-zero.
    */
   png_uint_16p hist;
#endif

#ifdef PNG_pCAL_SUPPORTED
   /* The pCAL chunk describes a transformation between the stored pixel
    * values and original physical data values used to create the image.
    * The integer range [0, 2^bit_depth - 1] maps to the floating-point
    * range given by [pcal_X0, pcal_X1], and are further transformed by a
    * (possibly non-linear) transformation function given by "pcal_type"
    * and "pcal_params" into "pcal_units".  Please see the PNG_EQUATION_
    * defines below, and the PNG-Group's PNG extensions document for a
    * complete description of the transformations and how they should be
    * implemented, and for a description of the ASCII parameter strings.
    * Data values are valid if (valid & PNG_INFO_pCAL) non-zero.
    */
   png_charp pcal_purpose;  /* pCAL chunk description string */
   png_int_32 pcal_X0;      /* minimum value */
   png_int_32 pcal_X1;      /* maximum value */
   png_charp pcal_units;    /* Latin-1 string giving physical units */
   png_charpp pcal_params;  /* ASCII strings containing parameter values */
   png_byte pcal_type;      /* equation type (see PNG_EQUATION_ below) */
   png_byte pcal_nparams;   /* number of parameters given in pcal_params */
#endif

/* New members added in libpng-1.0.6 */
   png_uint_32 free_me;     /* flags items libpng is responsible for freeing */

#ifdef PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED
   /* Storage for unknown chunks that the library doesn't recognize. */
   png_unknown_chunkp unknown_chunks;

   /* The type of this field is limited by the type of
    * png_struct::user_chunk_cache_max, else overflow can occur.
    */
   int                unknown_chunks_num;
#endif

#ifdef PNG_sPLT_SUPPORTED
   /* Data on sPLT chunks (there may be more than one). */
   png_sPLT_tp splt_palettes;
   int         splt_palettes_num; /* Match type returned by png_get API */
#endif

#ifdef PNG_sCAL_SUPPORTED
   /* The sCAL chunk describes the actual physical dimensions of the
    * subject matter of the graphic.  The chunk contains a unit specification
    * a byte value, and two ASCII strings representing floating-point
    * values.  The values are width and height corresponsing to one pixel
    * in the image.  Data values are valid if (valid & PNG_INFO_sCAL) is
    * non-zero.
    */
   png_byte scal_unit;         /* unit of physical scale */
   png_charp scal_s_width;     /* string containing height */
   png_charp scal_s_height;    /* string containing width */
#endif

#ifdef PNG_INFO_IMAGE_SUPPORTED
   /* Memory has been allocated if (valid & PNG_ALLOCATED_INFO_ROWS)
      non-zero */
   /* Data valid if (valid & PNG_INFO_IDAT) non-zero */
   png_bytepp row_pointers;        /* the image bits */
#endif

};
#endif /* PNGINFO_H */
