/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is mozilla libpng configuration.
 *
 * The Initial Developer of the Original Code is
 * Tim Rowley.
 * Portions created by the Initial Developer are Copyright (C) 2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): Tim Rowley <tor@cs.brown.edu>, Apple Computer
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

#ifndef CHROME_THIRD_PARTY_LIBPNG_PNGUSR_H__
#define CHROME_THIRD_PARTY_LIBPNG_PNGUSR_H__

#define PNG_NO_GLOBAL_ARRAYS

#undef PNG_NO_INFO_IMAGE
#define PNG_NO_READ_BACKGROUND
#define PNG_NO_READ_DITHER
#define PNG_NO_READ_INVERT
#define PNG_NO_READ_SHIFT
#if defined(CHROME_PNG_READ_PACK_SUPPORT)
#undef PNG_NO_READ_PACK  // Required by freetype to support png glyphs.
#else
#define PNG_NO_READ_PACK
#endif
#define PNG_NO_READ_PACKSWAP
#undef PNG_NO_READ_FILLER
#define PNG_NO_READ_SWAP
#define PNG_NO_READ_SWAP_ALPHA
#define PNG_NO_READ_INVERT_ALPHA
#define PNG_NO_READ_RGB_TO_GRAY
#define PNG_NO_READ_bKGD
#undef PNG_NO_READ_cHRM
#undef PNG_NO_READ_gAMA
#define PNG_NO_READ_hIST
#undef PNG_NO_READ_iCCP
#define PNG_NO_READ_oFFs
#define PNG_NO_READ_pCAL
#define PNG_NO_READ_pHYs
#define PNG_NO_READ_sBIT
#define PNG_NO_READ_sCAL
#define PNG_NO_READ_sPLT
#undef PNG_NO_READ_sRGB
#define PNG_NO_READ_TEXT
#define PNG_NO_READ_tIME
#define PNG_NO_READ_UNKNOWN_CHUNKS
#define PNG_NO_READ_USER_CHUNKS
#define PNG_NO_READ_EMPTY_PLTE
#define PNG_NO_READ_OPT_PLTE

#ifdef CHROME_PNG_WRITE_SUPPORT
#define PNG_NO_WRITE_BACKGROUND
#define PNG_NO_WRITE_DITHER
#define PNG_NO_WRITE_INVERT
#define PNG_NO_WRITE_SHIFT
#define PNG_NO_WRITE_PACK
#define PNG_NO_WRITE_PACKSWAP
#undef PNG_NO_WRITE_FILLER
#define PNG_NO_WRITE_SWAP
#define PNG_NO_WRITE_SWAP_ALPHA
#define PNG_NO_WRITE_INVERT_ALPHA
#define PNG_NO_WRITE_RGB_TO_GRAY
#define PNG_NO_WRITE_USER_TRANSFORM
#define PNG_NO_WRITE_bKGD
#define PNG_NO_WRITE_cHRM
#define PNG_NO_WRITE_gAMA
#define PNG_NO_WRITE_hIST
#define PNG_NO_WRITE_iCCP
#define PNG_NO_WRITE_oFFs
#define PNG_NO_WRITE_pCAL
#define PNG_NO_WRITE_pHYs
#define PNG_NO_WRITE_sBIT
#define PNG_NO_WRITE_sCAL
#define PNG_NO_WRITE_sPLT
#define PNG_NO_WRITE_sRGB
#define PNG_NO_WRITE_tIME
#define PNG_NO_WRITE_UNKNOWN_CHUNKS
#define PNG_NO_WRITE_USER_CHUNKS
#define PNG_NO_WRITE_EMPTY_PLTE
#define PNG_NO_WRITE_OPT_PLTE
#else
#define PNG_NO_WRITE_SUPPORTED
#endif

#define PNG_NO_USER_MEM
#define PNG_NO_FIXED_POINT_SUPPORTED
#define PNG_NO_MNG_FEATURES
#define PNG_NO_HANDLE_AS_UNKNOWN
#define PNG_NO_CONSOLE_IO
#define PNG_NO_ZALLOC_ZERO
#define PNG_NO_ERROR_NUMBERS
#undef PNG_NO_EASY_ACCESS
#define PNG_NO_USER_LIMITS
#define PNG_NO_SET_USER_LIMITS
#define PNG_NO_TIME_RFC1123
#undef PNG_NO_INFO_IMAGE
#undef PNG_NO_PROGRESSIVE_READ
#undef PNG_NO_SEQUENTIAL_READ

/* Mangle names of exported libpng functions so different libpng versions
   can coexist. It is recommended that if you do this, you give your
   library a different name such as "libwkpng" instead of "libpng". */

#define png_64bit_product               wk_png_64bit_product
#define png_access_version_number       wk_png_access_version_number
#undef png_benign_error
#define png_build_gamma_table           wk_png_build_gamma_table
#define png_build_grayscale_palette     wk_png_build_grayscale_palette
#define png_calculate_crc               wk_png_calculate_crc
#define png_calloc                      wk_png_calloc
#define png_check_IHDR                  wk_png_check_IHDR
#define png_check_cHRM_fixed            wk_png_check_cHRM_fixed
#define png_check_chunk_name            wk_png_check_chunk_name
#define png_check_keyword               wk_png_check_keyword
#define png_check_sig                   wk_png_check_sig
#undef png_chunk_benign_error
#define png_chunk_error                 wk_png_chunk_error
#define png_chunk_warning               wk_png_chunk_warning
#define png_combine_row                 wk_png_combine_row
#define png_convert_from_struct_tm      wk_png_convert_from_struct_tm
#define png_convert_from_time_t         wk_png_convert_from_time_t
#define png_convert_size                wk_png_convert_size
#define png_convert_to_rfc1123          wk_png_convert_to_rfc1123
#define png_correct_palette             wk_png_correct_palette
#define png_crc_error                   wk_png_crc_error
#define png_crc_finish                  wk_png_crc_finish
#define png_crc_read                    wk_png_crc_read
#define png_create_info_struct          wk_png_create_info_struct
#define png_create_read_struct          wk_png_create_read_struct
#define png_create_read_struct_2        wk_png_create_read_struct_2
#define png_create_struct               wk_png_create_struct
#define png_create_struct_2             wk_png_create_struct_2
#define png_create_write_struct         wk_png_create_write_struct
#define png_create_write_struct_2       wk_png_create_write_struct_2
#define png_data_freer                  wk_png_data_freer
#define png_decompress_chunk            wk_png_decompress_chunk
#define png_default_error               wk_png_default_error
#define png_default_flush               wk_png_default_flush
#define png_default_read_data           wk_png_default_read_data
#define png_default_warning             wk_png_default_warning
#define png_default_write_data          wk_png_default_write_data
#define png_destroy_info_struct         wk_png_destroy_info_struct
#define png_destroy_read_struct         wk_png_destroy_read_struct
#define png_destroy_struct              wk_png_destroy_struct
#define png_destroy_struct_2            wk_png_destroy_struct_2
#define png_destroy_write_struct        wk_png_destroy_write_struct
#define png_do_background               wk_png_do_background
#define png_do_bgr                      wk_png_do_bgr
#define png_do_chop                     wk_png_do_chop
#define png_do_dither                   wk_png_do_dither
#define png_do_expand                   wk_png_do_expand
#define png_do_expand_palette           wk_png_do_expand_palette
#define png_do_gamma                    wk_png_do_gamma
#define png_do_gray_to_rgb              wk_png_do_gray_to_rgb
#define png_do_invert                   wk_png_do_invert
#define png_do_pack                     wk_png_do_pack
#define png_do_packswap                 wk_png_do_packswap
#define png_do_read_filler              wk_png_do_read_filler
#define png_do_read_interlace           wk_png_do_read_interlace
#define png_do_read_intrapixel          wk_png_do_read_intrapixel
#define png_do_read_invert_alpha        wk_png_do_read_invert_alpha
#define png_do_read_swap_alpha          wk_png_do_read_swap_alpha
#define png_do_read_transformations     wk_png_do_read_transformations
#define png_do_rgb_to_gray              wk_png_do_rgb_to_gray
#define png_do_shift                    wk_png_do_shift
#define png_do_strip_filler             wk_png_do_strip_filler
#define png_do_swap                     wk_png_do_swap
#define png_do_unpack                   wk_png_do_unpack
#define png_do_unshift                  wk_png_do_unshift
#define png_do_write_interlace          wk_png_do_write_interlace
#define png_do_write_intrapixel         wk_png_do_write_intrapixel
#define png_do_write_invert_alpha       wk_png_do_write_invert_alpha
#define png_do_write_swap_alpha         wk_png_do_write_swap_alpha
#define png_do_write_transformations    wk_png_do_write_transformations
#define png_dummy_mmx_support           wk_png_dummy_mmx_support
#define png_err                         wk_png_err
#define png_error                       wk_png_error
#define png_flush                       wk_png_flush
#define png_format_buffer               wk_png_format_buffer
#define png_free                        wk_png_free
#define png_free_data                   wk_png_free_data
#define png_free_default                wk_png_free_default
#define png_get_IHDR                    wk_png_get_IHDR
#define png_get_PLTE                    wk_png_get_PLTE
#define png_get_asm_flagmask            wk_png_get_asm_flagmask
#define png_get_asm_flags               wk_png_get_asm_flags
#define png_get_bKGD                    wk_png_get_bKGD
#define png_get_bit_depth               wk_png_get_bit_depth
#define png_get_cHRM                    wk_png_get_cHRM
#define png_get_cHRM_fixed              wk_png_get_cHRM_fixed
#define png_get_channels                wk_png_get_channels
#define png_get_color_type              wk_png_get_color_type
#define png_get_compression_buffer_size wk_png_get_compression_buffer_size
#define png_get_compression_type        wk_png_get_compression_type
#define png_get_copyright               wk_png_get_copyright
#define png_get_error_ptr               wk_png_get_error_ptr
#define png_get_filter_type             wk_png_get_filter_type
#define png_get_gAMA                    wk_png_get_gAMA
#define png_get_gAMA_fixed              wk_png_get_gAMA_fixed
#define png_get_hIST                    wk_png_get_hIST
#define png_get_header_ver              wk_png_get_header_ver
#define png_get_header_version          wk_png_get_header_version
#define png_get_iCCP                    wk_png_get_iCCP
#define png_get_image_height            wk_png_get_image_height
#define png_get_image_width             wk_png_get_image_width
#undef png_get_int_32
#define png_get_interlace_type          wk_png_get_interlace_type
#define png_get_io_ptr                  wk_png_get_io_ptr
#define png_get_libpng_ver              wk_png_get_libpng_ver
#define png_get_mem_ptr                 wk_png_get_mem_ptr
#define png_get_mmx_bitdepth_threshold  wk_png_get_mmx_bitdepth_threshold
#define png_get_mmx_flagmask            wk_png_get_mmx_flagmask
#define png_get_mmx_rowbytes_threshold  wk_png_get_mmx_rowbytes_threshold
#define png_get_oFFs                    wk_png_get_oFFs
#define png_get_pCAL                    wk_png_get_pCAL
#define png_get_pHYs                    wk_png_get_pHYs
#define png_get_pHYs_dpi                wk_png_get_pHYs_dpi
#define png_get_pixel_aspect_ratio      wk_png_get_pixel_aspect_ratio
#define png_get_pixels_per_inch         wk_png_get_pixels_per_inch
#define png_get_pixels_per_meter        wk_png_get_pixels_per_meter
#define png_get_progressive_ptr         wk_png_get_progressive_ptr
#define png_get_rgb_to_gray_status      wk_png_get_rgb_to_gray_status
#define png_get_rowbytes                wk_png_get_rowbytes
#define png_get_rows                    wk_png_get_rows
#define png_get_sBIT                    wk_png_get_sBIT
#define png_get_sCAL                    wk_png_get_sCAL
#define png_get_sCAL_s                  wk_png_get_sCAL_s
#define png_get_sPLT                    wk_png_get_sPLT
#define png_get_sRGB                    wk_png_get_sRGB
#define png_get_signature               wk_png_get_signature
#define png_get_tIME                    wk_png_get_tIME
#define png_get_tRNS                    wk_png_get_tRNS
#define png_get_text                    wk_png_get_text
#undef png_get_uint_16
#define png_get_uint_31                 wk_png_get_uint_31
#undef png_get_uint_32
#define png_get_unknown_chunks          wk_png_get_unknown_chunks
#define png_get_user_chunk_ptr          wk_png_get_user_chunk_ptr
#define png_get_user_height_max         wk_png_get_user_height_max
#define png_get_user_transform_ptr      wk_png_get_user_transform_ptr
#define png_get_user_width_max          wk_png_get_user_width_max
#define png_get_valid                   wk_png_get_valid
#define png_get_x_offset_inches         wk_png_get_x_offset_inches
#define png_get_x_offset_microns        wk_png_get_x_offset_microns
#define png_get_x_offset_pixels         wk_png_get_x_offset_pixels
#define png_get_x_pixels_per_inch       wk_png_get_x_pixels_per_inch
#define png_get_x_pixels_per_meter      wk_png_get_x_pixels_per_meter
#define png_get_y_offset_inches         wk_png_get_y_offset_inches
#define png_get_y_offset_microns        wk_png_get_y_offset_microns
#define png_get_y_offset_pixels         wk_png_get_y_offset_pixels
#define png_get_y_pixels_per_inch       wk_png_get_y_pixels_per_inch
#define png_get_y_pixels_per_meter      wk_png_get_y_pixels_per_meter
#define png_handle_IEND                 wk_png_handle_IEND
#define png_handle_IHDR                 wk_png_handle_IHDR
#define png_handle_PLTE                 wk_png_handle_PLTE
#define png_handle_as_unknown           wk_png_handle_as_unknown
#define png_handle_bKGD                 wk_png_handle_bKGD
#define png_handle_cHRM                 wk_png_handle_cHRM
#define png_handle_gAMA                 wk_png_handle_gAMA
#define png_handle_hIST                 wk_png_handle_hIST
#define png_handle_iCCP                 wk_png_handle_iCCP
#define png_handle_iTXt                 wk_png_handle_iTXt
#define png_handle_oFFs                 wk_png_handle_oFFs
#define png_handle_pCAL                 wk_png_handle_pCAL
#define png_handle_pHYs                 wk_png_handle_pHYs
#define png_handle_sBIT                 wk_png_handle_sBIT
#define png_handle_sCAL                 wk_png_handle_sCAL
#define png_handle_sPLT                 wk_png_handle_sPLT
#define png_handle_sRGB                 wk_png_handle_sRGB
#define png_handle_tEXt                 wk_png_handle_tEXt
#define png_handle_tIME                 wk_png_handle_tIME
#define png_handle_tRNS                 wk_png_handle_tRNS
#define png_handle_unknown              wk_png_handle_unknown
#define png_handle_zTXt                 wk_png_handle_zTXt
#define png_inflate                     wk_png_inflate
#define png_info_destroy                wk_png_info_destroy
#undef png_info_init
#define png_info_init_3                 wk_png_info_init_3
#define png_init_io                     wk_png_init_io
#define png_init_read_transformations   wk_png_init_read_transformations
#define png_malloc                      wk_png_malloc
#define png_malloc_default              wk_png_malloc_default
#define png_malloc_warn                 wk_png_malloc_warn
#define png_memcpy_check                wk_png_memcpy_check
#define png_memset_check                wk_png_memset_check
#define png_mmx_support                 wk_png_mmx_support
#define png_permit_empty_plte           wk_png_permit_empty_plte
#define png_permit_mng_features         wk_png_permit_mng_features
#define png_process_IDAT_data           wk_png_process_IDAT_data
#define png_process_data                wk_png_process_data
#define png_process_some_data           wk_png_process_some_data
#define png_progressive_combine_row     wk_png_progressive_combine_row
#define png_push_crc_finish             wk_png_push_crc_finish
#define png_push_crc_skip               wk_png_push_crc_skip
#define png_push_fill_buffer            wk_png_push_fill_buffer
#define png_push_handle_iTXt            wk_png_push_handle_iTXt
#define png_push_handle_tEXt            wk_png_push_handle_tEXt
#define png_push_handle_unknown         wk_png_push_handle_unknown
#define png_push_handle_zTXt            wk_png_push_handle_zTXt
#define png_push_have_end               wk_png_push_have_end
#define png_push_have_info              wk_png_push_have_info
#define png_push_have_row               wk_png_push_have_row
#define png_push_process_row            wk_png_push_process_row
#define png_push_read_IDAT              wk_png_push_read_IDAT
#define png_push_read_chunk             wk_png_push_read_chunk
#define png_push_read_iTXt              wk_png_push_read_iTXt
#define png_push_read_sig               wk_png_push_read_sig
#define png_push_read_tEXt              wk_png_push_read_tEXt
#define png_push_read_zTXt              wk_png_push_read_zTXt
#define png_push_restore_buffer         wk_png_push_restore_buffer
#define png_push_save_buffer            wk_png_push_save_buffer
#define png_read_chunk_header           wk_png_read_chunk_header
#define png_read_data                   wk_png_read_data
#define png_read_destroy                wk_png_read_destroy
#define png_read_end                    wk_png_read_end
#define png_read_filter_row             wk_png_read_filter_row
#define png_read_finish_row             wk_png_read_finish_row
#define png_read_image                  wk_png_read_image
#define png_read_info                   wk_png_read_info
#undef png_read_init
#define png_read_init_2                 wk_png_read_init_2
#define png_read_init_3                 wk_png_read_init_3
#define png_read_png                    wk_png_read_png
#define png_read_push_finish_row        wk_png_read_push_finish_row
#define png_read_row                    wk_png_read_row
#define png_read_rows                   wk_png_read_rows
#define png_read_start_row              wk_png_read_start_row
#define png_read_transform_info         wk_png_read_transform_info
#define png_read_update_info            wk_png_read_update_info
#define png_reset_crc                   wk_png_reset_crc
#define png_reset_zstream               wk_png_reset_zstream
#define png_save_int_32                 wk_png_save_int_32
#define png_save_uint_16                wk_png_save_uint_16
#define png_save_uint_32                wk_png_save_uint_32
#define png_set_IHDR                    wk_png_set_IHDR
#define png_set_PLTE                    wk_png_set_PLTE
#define png_set_add_alpha               wk_png_set_add_alpha
#define png_set_asm_flags               wk_png_set_asm_flags
#define png_set_bKGD                    wk_png_set_bKGD
#define png_set_background              wk_png_set_background
#define png_set_benign_errors           wk_png_set_benign_errors
#define png_set_bgr                     wk_png_set_bgr
#define png_set_cHRM                    wk_png_set_cHRM
#define png_set_cHRM_fixed              wk_png_set_cHRM_fixed
#define png_set_compression_buffer_size wk_png_set_compression_buffer_size
#define png_set_compression_level       wk_png_set_compression_level
#define png_set_compression_mem_level   wk_png_set_compression_mem_level
#define png_set_compression_method      wk_png_set_compression_method
#define png_set_compression_strategy    wk_png_set_compression_strategy
#define png_set_compression_window_bits wk_png_set_compression_window_bits
#define png_set_crc_action              wk_png_set_crc_action
#define png_set_dither                  wk_png_set_dither
#define png_set_error_fn                wk_png_set_error_fn
#define png_set_expand                  wk_png_set_expand
#define png_set_expand_gray_1_2_4_to_8  wk_png_set_expand_gray_1_2_4_to_8
#define png_set_filler                  wk_png_set_filler
#define png_set_filter                  wk_png_set_filter
#define png_set_filter_heuristics       wk_png_set_filter_heuristics
#define png_set_flush                   wk_png_set_flush
#define png_set_gAMA                    wk_png_set_gAMA
#define png_set_gAMA_fixed              wk_png_set_gAMA_fixed
#define png_set_gamma                   wk_png_set_gamma
#define png_set_gray_1_2_4_to_8         wk_png_set_gray_1_2_4_to_8
#define png_set_gray_to_rgb             wk_png_set_gray_to_rgb
#define png_set_hIST                    wk_png_set_hIST
#define png_set_iCCP                    wk_png_set_iCCP
#define png_set_interlace_handling      wk_png_set_interlace_handling
#define png_set_invalid                 wk_png_set_invalid
#define png_set_invert_alpha            wk_png_set_invert_alpha
#define png_set_invert_mono             wk_png_set_invert_mono
#define png_set_keep_unknown_chunks     wk_png_set_keep_unknown_chunks
#define png_set_mem_fn                  wk_png_set_mem_fn
#define png_set_mmx_thresholds          wk_png_set_mmx_thresholds
#define png_set_oFFs                    wk_png_set_oFFs
#define png_set_pCAL                    wk_png_set_pCAL
#define png_set_pHYs                    wk_png_set_pHYs
#define png_set_packing                 wk_png_set_packing
#define png_set_packswap                wk_png_set_packswap
#define png_set_palette_to_rgb          wk_png_set_palette_to_rgb
#define png_set_progressive_read_fn     wk_png_set_progressive_read_fn
#define png_set_read_fn                 wk_png_set_read_fn
#define png_set_read_status_fn          wk_png_set_read_status_fn
#define png_set_read_user_chunk_fn      wk_png_set_read_user_chunk_fn
#define png_set_read_user_transform_fn  wk_png_set_read_user_transform_fn
#define png_set_rgb_to_gray             wk_png_set_rgb_to_gray
#define png_set_rgb_to_gray_fixed       wk_png_set_rgb_to_gray_fixed
#define png_set_rows                    wk_png_set_rows
#define png_set_sBIT                    wk_png_set_sBIT
#define png_set_sCAL                    wk_png_set_sCAL
#define png_set_sCAL_s                  wk_png_set_sCAL_s
#define png_set_sPLT                    wk_png_set_sPLT
#define png_set_sRGB                    wk_png_set_sRGB
#define png_set_sRGB_gAMA_and_cHRM      wk_png_set_sRGB_gAMA_and_cHRM
#define png_set_shift                   wk_png_set_shift
#define png_set_sig_bytes               wk_png_set_sig_bytes
#define png_set_strip_16                wk_png_set_strip_16
#define png_set_strip_alpha             wk_png_set_strip_alpha
#define png_set_strip_error_numbers     wk_png_set_strip_error_numbers
#define png_set_swap                    wk_png_set_swap
#define png_set_swap_alpha              wk_png_set_swap_alpha
#define png_set_tIME                    wk_png_set_tIME
#define png_set_tRNS                    wk_png_set_tRNS
#define png_set_tRNS_to_alpha           wk_png_set_tRNS_to_alpha
#define png_set_text                    wk_png_set_text
#define png_set_text_2                  wk_png_set_text_2
#define png_set_unknown_chunk_location  wk_png_set_unknown_chunk_location
#define png_set_unknown_chunks          wk_png_set_unknown_chunks
#define png_set_user_limits             wk_png_set_user_limits
#define png_set_user_transform_info     wk_png_set_user_transform_info
#define png_set_write_fn                wk_png_set_write_fn
#define png_set_write_status_fn         wk_png_set_write_status_fn
#define png_set_write_user_transform_fn wk_png_set_write_user_transform_fn
#define png_sig_cmp                     wk_png_sig_cmp
#define png_start_read_image            wk_png_start_read_image
#define png_text_compress               wk_png_text_compress
#define png_warning                     wk_png_warning
#define png_write_IDAT                  wk_png_write_IDAT
#define png_write_IEND                  wk_png_write_IEND
#define png_write_IHDR                  wk_png_write_IHDR
#define png_write_PLTE                  wk_png_write_PLTE
#define png_write_bKGD                  wk_png_write_bKGD
#define png_write_cHRM                  wk_png_write_cHRM
#define png_write_cHRM_fixed            wk_png_write_cHRM_fixed
#define png_write_chunk                 wk_png_write_chunk
#define png_write_chunk_data            wk_png_write_chunk_data
#define png_write_chunk_end             wk_png_write_chunk_end
#define png_write_chunk_start           wk_png_write_chunk_start
#define png_write_compressed_data_out   wk_png_write_compressed_data_out
#define png_write_data                  wk_png_write_data
#define png_write_destroy               wk_png_write_destroy
#define png_write_end                   wk_png_write_end
#define png_write_filtered_row          wk_png_write_filtered_row
#define png_write_find_filter           wk_png_write_find_filter
#define png_write_finish_row            wk_png_write_finish_row
#define png_write_flush                 wk_png_write_flush
#define png_write_gAMA                  wk_png_write_gAMA
#define png_write_gAMA_fixed            wk_png_write_gAMA_fixed
#define png_write_hIST                  wk_png_write_hIST
#define png_write_iCCP                  wk_png_write_iCCP
#define png_write_iTXt                  wk_png_write_iTXt
#define png_write_image                 wk_png_write_image
#define png_write_info                  wk_png_write_info
#define png_write_info_before_PLTE      wk_png_write_info_before_PLTE
#undef png_write_init
#define png_write_init_2                wk_png_write_init_2
#define png_write_init_3                wk_png_write_init_3
#define png_write_oFFs                  wk_png_write_oFFs
#define png_write_pCAL                  wk_png_write_pCAL
#define png_write_pHYs                  wk_png_write_pHYs
#define png_write_png                   wk_png_write_png
#define png_write_row                   wk_png_write_row
#define png_write_rows                  wk_png_write_rows
#define png_write_sBIT                  wk_png_write_sBIT
#define png_write_sCAL                  wk_png_write_sCAL
#define png_write_sCAL_s                wk_png_write_sCAL_s
#define png_write_sPLT                  wk_png_write_sPLT
#define png_write_sRGB                  wk_png_write_sRGB
#define png_write_sig                   wk_png_write_sig
#define png_write_start_row             wk_png_write_start_row
#define png_write_tEXt                  wk_png_write_tEXt
#define png_write_tIME                  wk_png_write_tIME
#define png_write_tRNS                  wk_png_write_tRNS
#define png_write_zTXt                  wk_png_write_zTXt
#define png_zalloc                      wk_png_zalloc
#define png_zfree                       wk_png_zfree

#endif  // CHROME_THIRD_PARTY_LIBPNG_PNGUSR_H__
