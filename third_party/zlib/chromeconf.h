/* Copyright 2017 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. */

#ifndef THIRD_PARTY_ZLIB_CHROMECONF_H_
#define THIRD_PARTY_ZLIB_CHROMECONF_H_

#if defined(COMPONENT_BUILD)
#if defined(WIN32)
#if defined(ZLIB_IMPLEMENTATION)
#define ZEXTERN __declspec(dllexport)
#else
#define ZEXTERN __declspec(dllimport)
#endif
#elif defined(ZLIB_IMPLEMENTATION)
#define ZEXTERN __attribute__((visibility("default")))
#endif
#endif

/* Rename all zlib names with a Cr_z_ prefix. This is based on the Z_PREFIX
 * option from zconf.h, but with a custom prefix. Where zconf.h would rename
 * both a macro and its underscore-suffixed internal implementation (such as
 * deflateInit2 and deflateInit2_), only the implementation is renamed here.
 * The Byte type is also omitted.
 *
 * To generate this list, run
 * sed -rn -e 's/^# *define +([^ ]+) +(z_[^ ]+)$/#define \1 Cr_\2/p' zconf.h
 * (use -E instead of -r on macOS).
 *
 * gzread is also addressed by modifications in gzread.c and zlib.h. */

#define Z_CR_PREFIX_SET

#define _dist_code Cr_z__dist_code
#define _length_code Cr_z__length_code
#define _tr_align Cr_z__tr_align
#define _tr_flush_bits Cr_z__tr_flush_bits
#define _tr_flush_block Cr_z__tr_flush_block
#define _tr_init Cr_z__tr_init
#define _tr_stored_block Cr_z__tr_stored_block
#define _tr_tally Cr_z__tr_tally
#define adler32 Cr_z_adler32
#define adler32_combine Cr_z_adler32_combine
#define adler32_combine64 Cr_z_adler32_combine64
#define adler32_z Cr_z_adler32_z
#define compress Cr_z_compress
#define compress2 Cr_z_compress2
#define compressBound Cr_z_compressBound
#define crc32 Cr_z_crc32
#define crc32_combine Cr_z_crc32_combine
#define crc32_combine64 Cr_z_crc32_combine64
#define crc32_z Cr_z_crc32_z
#define deflate Cr_z_deflate
#define deflateBound Cr_z_deflateBound
#define deflateCopy Cr_z_deflateCopy
#define deflateEnd Cr_z_deflateEnd
#define deflateGetDictionary Cr_z_deflateGetDictionary
/* #undef deflateInit */
/* #undef deflateInit2 */
#define deflateInit2_ Cr_z_deflateInit2_
#define deflateInit_ Cr_z_deflateInit_
#define deflateParams Cr_z_deflateParams
#define deflatePending Cr_z_deflatePending
#define deflatePrime Cr_z_deflatePrime
#define deflateReset Cr_z_deflateReset
#define deflateResetKeep Cr_z_deflateResetKeep
#define deflateSetDictionary Cr_z_deflateSetDictionary
#define deflateSetHeader Cr_z_deflateSetHeader
#define deflateTune Cr_z_deflateTune
#define deflate_copyright Cr_z_deflate_copyright
#define get_crc_table Cr_z_get_crc_table
#define gz_error Cr_z_gz_error
#define gz_intmax Cr_z_gz_intmax
#define gz_strwinerror Cr_z_gz_strwinerror
#define gzbuffer Cr_z_gzbuffer
#define gzclearerr Cr_z_gzclearerr
#define gzclose Cr_z_gzclose
#define gzclose_r Cr_z_gzclose_r
#define gzclose_w Cr_z_gzclose_w
#define gzdirect Cr_z_gzdirect
#define gzdopen Cr_z_gzdopen
#define gzeof Cr_z_gzeof
#define gzerror Cr_z_gzerror
#define gzflush Cr_z_gzflush
#define gzfread Cr_z_gzfread
#define gzfwrite Cr_z_gzfwrite
#define gzgetc Cr_z_gzgetc
#define gzgetc_ Cr_z_gzgetc_
#define gzgets Cr_z_gzgets
#define gzoffset Cr_z_gzoffset
#define gzoffset64 Cr_z_gzoffset64
#define gzopen Cr_z_gzopen
#define gzopen64 Cr_z_gzopen64
#define gzopen_w Cr_z_gzopen_w
#define gzprintf Cr_z_gzprintf
#define gzputc Cr_z_gzputc
#define gzputs Cr_z_gzputs
#define gzread Cr_z_gzread
#define gzrewind Cr_z_gzrewind
#define gzseek Cr_z_gzseek
#define gzseek64 Cr_z_gzseek64
#define gzsetparams Cr_z_gzsetparams
#define gztell Cr_z_gztell
#define gztell64 Cr_z_gztell64
#define gzungetc Cr_z_gzungetc
#define gzvprintf Cr_z_gzvprintf
#define gzwrite Cr_z_gzwrite
#define inflate Cr_z_inflate
#define inflateBack Cr_z_inflateBack
#define inflateBackEnd Cr_z_inflateBackEnd
/* #undef inflateBackInit */
#define inflateBackInit_ Cr_z_inflateBackInit_
#define inflateCodesUsed Cr_z_inflateCodesUsed
#define inflateCopy Cr_z_inflateCopy
#define inflateEnd Cr_z_inflateEnd
#define inflateGetDictionary Cr_z_inflateGetDictionary
#define inflateGetHeader Cr_z_inflateGetHeader
/* #undef inflateInit */
/* #undef inflateInit2 */
#define inflateInit2_ Cr_z_inflateInit2_
#define inflateInit_ Cr_z_inflateInit_
#define inflateMark Cr_z_inflateMark
#define inflatePrime Cr_z_inflatePrime
#define inflateReset Cr_z_inflateReset
#define inflateReset2 Cr_z_inflateReset2
#define inflateResetKeep Cr_z_inflateResetKeep
#define inflateSetDictionary Cr_z_inflateSetDictionary
#define inflateSync Cr_z_inflateSync
#define inflateSyncPoint Cr_z_inflateSyncPoint
#define inflateUndermine Cr_z_inflateUndermine
#define inflateValidate Cr_z_inflateValidate
#define inflate_copyright Cr_z_inflate_copyright
#define inflate_fast Cr_z_inflate_fast
#define inflate_table Cr_z_inflate_table
#define uncompress Cr_z_uncompress
#define uncompress2 Cr_z_uncompress2
#define zError Cr_z_zError
#define zcalloc Cr_z_zcalloc
#define zcfree Cr_z_zcfree
#define zlibCompileFlags Cr_z_zlibCompileFlags
#define zlibVersion Cr_z_zlibVersion
/* #undef Byte */
#define Bytef Cr_z_Bytef
#define alloc_func Cr_z_alloc_func
#define charf Cr_z_charf
#define free_func Cr_z_free_func
#define gzFile Cr_z_gzFile
#define gz_header Cr_z_gz_header
#define gz_headerp Cr_z_gz_headerp
#define in_func Cr_z_in_func
#define intf Cr_z_intf
#define out_func Cr_z_out_func
#define uInt Cr_z_uInt
#define uIntf Cr_z_uIntf
#define uLong Cr_z_uLong
#define uLongf Cr_z_uLongf
#define voidp Cr_z_voidp
#define voidpc Cr_z_voidpc
#define voidpf Cr_z_voidpf
#define gz_header_s Cr_z_gz_header_s
/* #undef internal_state */
/* #undef z_off64_t */

/* An exported symbol that isn't handled by Z_PREFIX in zconf.h */
#define z_errmsg Cr_z_z_errmsg

/* Symbols added in simd.patch */
#define copy_with_crc Cr_z_copy_with_crc
#define crc_finalize Cr_z_crc_finalize
#define crc_fold_512to32 Cr_z_crc_fold_512to32
#define crc_fold_copy Cr_z_crc_fold_copy
#define crc_fold_init Cr_z_crc_fold_init
#define crc_reset Cr_z_crc_reset
#define fill_window_sse Cr_z_fill_window_sse
#define deflate_read_buf Cr_z_deflate_read_buf
#define x86_check_features Cr_z_x86_check_features
#define x86_cpu_enable_simd Cr_z_x86_cpu_enable_simd

/* Symbols added by adler_simd.c */
#define adler32_simd_ Cr_z_adler32_simd_
#define x86_cpu_enable_ssse3 Cr_z_x86_cpu_enable_ssse3

/* Symbols added by contrib/optimizations/inffast_chunk */
#define inflate_fast_chunk_ Cr_z_inflate_fast_chunk_

/* Symbols added by crc32_simd.c */
#define crc32_sse42_simd_ Cr_z_crc32_sse42_simd_

/* Symbols added by armv8_crc32 */
#define arm_cpu_enable_crc32 Cr_z_arm_cpu_enable_crc32
#define arm_cpu_enable_pmull Cr_z_arm_cpu_enable_pmull
#define arm_check_features Cr_z_arm_check_features
#define armv8_crc32_little Cr_z_armv8_crc32_little

/* Symbols added by cpu_features.c */
#define cpu_check_features Cr_z_cpu_check_features
#define x86_cpu_enable_sse2 Cr_z_x86_cpu_enable_sse2

#endif /* THIRD_PARTY_ZLIB_CHROMECONF_H_ */
