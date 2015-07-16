#ifndef QCMS_H
#define QCMS_H

#ifdef  __cplusplus
extern "C" {
#endif

/* if we've already got an ICC_H header we can ignore the following */
#ifndef ICC_H
/* icc34 defines */

/***************************************************************** 
 Copyright (c) 1994-1996 SunSoft, Inc.

                    Rights Reserved

Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restrict- 
ion, including without limitation the rights to use, copy, modify, 
merge, publish distribute, sublicense, and/or sell copies of the 
Software, and to permit persons to whom the Software is furnished 
to do so, subject to the following conditions: 
 
The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software. 
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-
INFRINGEMENT.  IN NO EVENT SHALL SUNSOFT, INC. OR ITS PARENT 
COMPANY BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
OTHER DEALINGS IN THE SOFTWARE. 
 
Except as contained in this notice, the name of SunSoft, Inc. 
shall not be used in advertising or otherwise to promote the 
sale, use or other dealings in this Software without written 
authorization from SunSoft Inc. 
******************************************************************/

/*
 * QCMS, in general, is not threadsafe. However, it should be safe to create
 * profile and transformation objects on different threads, so long as you
 * don't use the same objects on different threads at the same time.
 */

/* 
 * Color Space Signatures
 * Note that only icSigXYZData and icSigLabData are valid
 * Profile Connection Spaces (PCSs)
 */ 
typedef enum {
    icSigXYZData                        = 0x58595A20L,  /* 'XYZ ' */
    icSigLabData                        = 0x4C616220L,  /* 'Lab ' */
    icSigLuvData                        = 0x4C757620L,  /* 'Luv ' */
    icSigYCbCrData                      = 0x59436272L,  /* 'YCbr' */
    icSigYxyData                        = 0x59787920L,  /* 'Yxy ' */
    icSigRgbData                        = 0x52474220L,  /* 'RGB ' */
    icSigGrayData                       = 0x47524159L,  /* 'GRAY' */
    icSigHsvData                        = 0x48535620L,  /* 'HSV ' */
    icSigHlsData                        = 0x484C5320L,  /* 'HLS ' */
    icSigCmykData                       = 0x434D594BL,  /* 'CMYK' */
    icSigCmyData                        = 0x434D5920L,  /* 'CMY ' */
    icSig2colorData                     = 0x32434C52L,  /* '2CLR' */
    icSig3colorData                     = 0x33434C52L,  /* '3CLR' */
    icSig4colorData                     = 0x34434C52L,  /* '4CLR' */
    icSig5colorData                     = 0x35434C52L,  /* '5CLR' */
    icSig6colorData                     = 0x36434C52L,  /* '6CLR' */
    icSig7colorData                     = 0x37434C52L,  /* '7CLR' */
    icSig8colorData                     = 0x38434C52L,  /* '8CLR' */
    icSig9colorData                     = 0x39434C52L,  /* '9CLR' */
    icSig10colorData                    = 0x41434C52L,  /* 'ACLR' */
    icSig11colorData                    = 0x42434C52L,  /* 'BCLR' */
    icSig12colorData                    = 0x43434C52L,  /* 'CCLR' */
    icSig13colorData                    = 0x44434C52L,  /* 'DCLR' */
    icSig14colorData                    = 0x45434C52L,  /* 'ECLR' */
    icSig15colorData                    = 0x46434C52L,  /* 'FCLR' */
    icMaxEnumData                       = 0xFFFFFFFFL   
} icColorSpaceSignature;
#endif

#include <stdio.h>

typedef int qcms_bool;

struct _qcms_transform;
typedef struct _qcms_transform qcms_transform;

struct _qcms_profile;
typedef struct _qcms_profile qcms_profile;

/* these values match the Rendering Intent values from the ICC spec */
typedef enum {
	QCMS_INTENT_DEFAULT = 0,
	QCMS_INTENT_PERCEPTUAL = 0,
	QCMS_INTENT_RELATIVE_COLORIMETRIC = 1,
	QCMS_INTENT_SATURATION = 2,
	QCMS_INTENT_ABSOLUTE_COLORIMETRIC = 3
} qcms_intent;

//XXX: I don't really like the _DATA_ prefix
typedef enum {
	QCMS_DATA_RGB_8,
	QCMS_DATA_RGBA_8,
	QCMS_DATA_GRAY_8,
	QCMS_DATA_GRAYA_8
} qcms_data_type;

/* Format of the output data for qcms_transform_data_type() */
typedef enum {
	QCMS_OUTPUT_RGBX,
	QCMS_OUTPUT_BGRX
} qcms_output_type;

/* the names for the following two types are sort of ugly */
typedef struct
{
	double x;
	double y;
	double Y;
} qcms_CIE_xyY;

typedef struct
{
	qcms_CIE_xyY red;
	qcms_CIE_xyY green;
	qcms_CIE_xyY blue;
} qcms_CIE_xyYTRIPLE;

qcms_profile* qcms_profile_create_rgb_with_gamma(
		qcms_CIE_xyY white_point,
		qcms_CIE_xyYTRIPLE primaries,
		float gamma);

qcms_profile* qcms_profile_from_memory(const void *mem, size_t size);

qcms_profile* qcms_profile_from_file(FILE *file);
qcms_profile* qcms_profile_from_path(const char *path);
#ifdef _WIN32
qcms_profile* qcms_profile_from_unicode_path(const wchar_t *path);
#endif
qcms_profile* qcms_profile_sRGB(void);
void qcms_profile_release(qcms_profile *profile);

qcms_bool qcms_profile_is_bogus(qcms_profile *profile);
qcms_intent qcms_profile_get_rendering_intent(qcms_profile *profile);
icColorSpaceSignature qcms_profile_get_color_space(qcms_profile *profile);

qcms_bool qcms_profile_match(qcms_profile *p1, qcms_profile *p2);
const char* qcms_profile_get_description(qcms_profile *profile);

void qcms_profile_precache_output_transform(qcms_profile *profile);

qcms_transform* qcms_transform_create(
		qcms_profile *in, qcms_data_type in_type,
		qcms_profile* out, qcms_data_type out_type,
		qcms_intent intent);

qcms_bool qcms_transform_create_LUT_zyx_bgra(
		qcms_profile *in, qcms_profile* out, qcms_intent intent,
		int samples, unsigned char* lut);

void qcms_transform_data(qcms_transform *transform, void *src, void *dest, size_t length);
void qcms_transform_data_type(qcms_transform *transform, void *src, void *dest, size_t length, qcms_output_type type);

void qcms_transform_release(qcms_transform *);

void qcms_enable_iccv4();

#ifdef  __cplusplus
}
#endif

#endif
