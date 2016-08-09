/* vim: set ts=8 sw=8 noexpandtab: */
//  qcms
//  Copyright (C) 2009 Mozilla Foundation
//  Copyright (C) 1998-2007 Marti Maria
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

#ifndef _QCMS_TRANSFORM_UTIL_H
#define _QCMS_TRANSFORM_UTIL_H

#include <stdlib.h>

#define CLU(table,x,y,z) table[(x*len + y*x_len + z*xy_len)*3]

//XXX: could use a bettername
typedef uint16_t uint16_fract_t;

float lut_interp_linear(double input_value, uint16_t *table, size_t length);
float lut_interp_linear_float(float input_value, float *table, size_t length);
uint16_t lut_interp_linear16(uint16_t input_value, uint16_t *table, size_t length);


static inline float lerp(float a, float b, float t)
{
	return a*(1.f-t) + b*t;
}

unsigned char clamp_u8(float v);
float clamp_float(float a);

float u8Fixed8Number_to_float(uint16_t x);


float *build_input_gamma_table(struct curveType *TRC);
struct matrix build_colorant_matrix(qcms_profile *p);
void build_output_lut(struct curveType *trc,
                      uint16_t **output_gamma_lut, size_t *output_gamma_lut_length);

struct matrix matrix_invert(struct matrix mat);
qcms_bool compute_precache(struct curveType *trc, uint8_t *output);

#endif
