/* vim: set ts=8 sw=8 noexpandtab: */
//  qcms
//  Copyright (C) 2009 Mozilla Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include "qcms.h"
#include "qcmstypes.h"

/* used as a lookup table for the output transformation.
 * we refcount them so we only need to have one around per output
 * profile, instead of duplicating them per transform */
struct precache_output
{
	int ref_count;
	/* We previously used a count of 65536 here but that seems like more
	 * precision than we actually need.  By reducing the size we can
	 * improve startup performance and reduce memory usage. ColorSync on
	 * 10.5 uses 4097 which is perhaps because they use a fixed point
	 * representation where 1. is represented by 0x1000. */
#define PRECACHE_OUTPUT_SIZE 8192
#define PRECACHE_OUTPUT_MAX (PRECACHE_OUTPUT_SIZE-1)
	uint8_t data[PRECACHE_OUTPUT_SIZE];
};

#ifdef _MSC_VER
#define ALIGN __declspec(align(16))
#else
#define ALIGN __attribute__(( aligned (16) ))
#endif

typedef struct _qcms_format_type {
	int r;
	int b;
} qcms_format_type;

struct _qcms_transform {
	float ALIGN matrix[3][4];
	float *input_gamma_table_r;
	float *input_gamma_table_g;
	float *input_gamma_table_b;

	float *input_clut_table_r;
	float *input_clut_table_g;
	float *input_clut_table_b;
	uint16_t input_clut_table_length;
	float *r_clut;
	float *g_clut;
	float *b_clut;
	uint16_t grid_size;
	float *output_clut_table_r;
	float *output_clut_table_g;
	float *output_clut_table_b;
	uint16_t output_clut_table_length;
 
	float *input_gamma_table_gray;

	float out_gamma_r;
	float out_gamma_g;
	float out_gamma_b;

	float out_gamma_gray;

	uint16_t *output_gamma_lut_r;
	uint16_t *output_gamma_lut_g;
	uint16_t *output_gamma_lut_b;

	uint16_t *output_gamma_lut_gray;

	size_t output_gamma_lut_r_length;
	size_t output_gamma_lut_g_length;
	size_t output_gamma_lut_b_length;

	size_t output_gamma_lut_gray_length;

	struct precache_output *output_table_r;
	struct precache_output *output_table_g;
	struct precache_output *output_table_b;

	void (*transform_fn)(struct _qcms_transform *transform, unsigned char *src, unsigned char *dest, size_t length, struct _qcms_format_type output_format);
};

struct matrix {
	float m[3][3];
	bool invalid;
};

struct qcms_modular_transform;

typedef void (*transform_module_fn_t)(struct qcms_modular_transform *transform, float *src, float *dest, size_t length);

struct qcms_modular_transform {
	struct matrix matrix;
	float tx, ty, tz;

	float *input_clut_table_r;
	float *input_clut_table_g;
	float *input_clut_table_b;
	uint16_t input_clut_table_length;
	float *r_clut;
	float *g_clut;
	float *b_clut;
	uint16_t grid_size;
	float *output_clut_table_r;
	float *output_clut_table_g;
	float *output_clut_table_b;
	uint16_t output_clut_table_length;
 
	uint16_t *output_gamma_lut_r;
	uint16_t *output_gamma_lut_g;
	uint16_t *output_gamma_lut_b;

	size_t output_gamma_lut_r_length;
	size_t output_gamma_lut_g_length;
	size_t output_gamma_lut_b_length;

	transform_module_fn_t transform_module_fn;
	struct qcms_modular_transform *next_transform;
};

typedef int32_t s15Fixed16Number;
typedef uint16_t uInt16Number;
typedef uint8_t uInt8Number;

struct XYZNumber {
	s15Fixed16Number X;
	s15Fixed16Number Y;
	s15Fixed16Number Z;
};

struct curveType {
	uint32_t type;
	uint32_t count;
	float parameter[7];
	uInt16Number data[];
};

struct lutmABType {
	uint8_t num_in_channels;
	uint8_t num_out_channels;
	// 16 is the upperbound, actual is 0..num_in_channels.
	uint8_t num_grid_points[16];

	s15Fixed16Number e00;
	s15Fixed16Number e01;
	s15Fixed16Number e02;
	s15Fixed16Number e03;
	s15Fixed16Number e10;
	s15Fixed16Number e11;
	s15Fixed16Number e12;
	s15Fixed16Number e13;
	s15Fixed16Number e20;
	s15Fixed16Number e21;
	s15Fixed16Number e22;
	s15Fixed16Number e23;

	// reversed elements (for mBA)
	bool reversed;

	float *clut_table;
	struct curveType *a_curves[10];
	struct curveType *b_curves[10];
	struct curveType *m_curves[10];
	float clut_table_data[];
};

/* should lut8Type and lut16Type be different types? */
struct lutType { // used by lut8Type/lut16Type (mft2) only
	uint8_t num_input_channels;
	uint8_t num_output_channels;
	uint8_t num_clut_grid_points;

	s15Fixed16Number e00;
	s15Fixed16Number e01;
	s15Fixed16Number e02;
	s15Fixed16Number e10;
	s15Fixed16Number e11;
	s15Fixed16Number e12;
	s15Fixed16Number e20;
	s15Fixed16Number e21;
	s15Fixed16Number e22;

	uint16_t num_input_table_entries;
	uint16_t num_output_table_entries;

	float *input_table;
	float *clut_table;
	float *output_table;

	float table_data[];
};
#if 0
/* this is from an intial idea of having the struct correspond to the data in
 * the file. I decided that it wasn't a good idea.
 */
struct tag_value {
	uint32_t type;
	union {
		struct {
			uint32_t reserved;
			struct {
				s15Fixed16Number X;
				s15Fixed16Number Y;
				s15Fixed16Number Z;
			} XYZNumber;
		} XYZType;
	};
}; // I guess we need to pack this?
#endif

#define RGB_SIGNATURE  0x52474220
#define GRAY_SIGNATURE 0x47524159
#define XYZ_SIGNATURE  0x58595A20
#define LAB_SIGNATURE  0x4C616220

struct _qcms_profile {
	char description[64];
	uint32_t class;
	uint32_t color_space;
	uint32_t pcs;
	qcms_intent rendering_intent;
	struct XYZNumber redColorant;
	struct XYZNumber blueColorant;
	struct XYZNumber greenColorant;
	struct curveType *redTRC;
	struct curveType *blueTRC;
	struct curveType *greenTRC;
	struct curveType *grayTRC;
	struct lutType *A2B0;
	struct lutType *B2A0;
	struct lutmABType *mAB;
	struct lutmABType *mBA;
	struct matrix chromaticAdaption;

	struct precache_output *output_table_r;
	struct precache_output *output_table_g;
	struct precache_output *output_table_b;
};

#ifdef _MSC_VER
#define inline _inline
#endif

/* produces the nearest float to 'a' with a maximum error
 * of 1/1024 which happens for large values like 0x40000040 */
static inline float s15Fixed16Number_to_float(s15Fixed16Number a)
{
	return ((int32_t)a)/65536.f;
}

static inline s15Fixed16Number double_to_s15Fixed16Number(double v)
{
	return (int32_t)(v*65536);
}

static inline float uInt8Number_to_float(uInt8Number a)
{
	return ((int32_t)a)/255.f;
}

static inline float uInt16Number_to_float(uInt16Number a)
{
	return ((int32_t)a)/65535.f;
}


void precache_release(struct precache_output *p);
qcms_bool set_rgb_colorants(qcms_profile *profile, qcms_CIE_xyY white_point, qcms_CIE_xyYTRIPLE primaries);

void qcms_transform_data_rgb_out_lut_sse2(qcms_transform *transform,
                                          unsigned char *src,
                                          unsigned char *dest,
                                          size_t length,
                                          qcms_format_type output_format);
void qcms_transform_data_rgba_out_lut_sse2(qcms_transform *transform,
                                          unsigned char *src,
                                          unsigned char *dest,
                                          size_t length,
                                          qcms_format_type output_format);
void qcms_transform_data_rgb_out_lut_sse1(qcms_transform *transform,
                                          unsigned char *src,
                                          unsigned char *dest,
                                          size_t length,
                                          qcms_format_type output_format);
void qcms_transform_data_rgba_out_lut_sse1(qcms_transform *transform,
                                          unsigned char *src,
                                          unsigned char *dest,
                                          size_t length,
                                          qcms_format_type output_format);

extern qcms_bool qcms_supports_iccv4;


#ifdef _MSC_VER

long __cdecl _InterlockedIncrement(long volatile *);
long __cdecl _InterlockedDecrement(long volatile *);
#pragma intrinsic(_InterlockedIncrement)
#pragma intrinsic(_InterlockedDecrement)

#define qcms_atomic_increment(x) _InterlockedIncrement((long volatile *)&x)
#define qcms_atomic_decrement(x) _InterlockedDecrement((long volatile*)&x)

#else

#define qcms_atomic_increment(x) __sync_add_and_fetch(&x, 1)
#define qcms_atomic_decrement(x) __sync_sub_and_fetch(&x, 1)

#endif
