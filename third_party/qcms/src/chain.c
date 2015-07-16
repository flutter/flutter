/* vim: set ts=8 sw=8 noexpandtab: */
//  qcms
//  Copyright (C) 2009 Mozilla Corporation
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

#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <string.h> //memcpy
#include "qcmsint.h"
#include "transform_util.h"
#include "matrix.h"

static struct matrix build_lut_matrix(struct lutType *lut)
{
	struct matrix result;
	if (lut) {
		result.m[0][0] = s15Fixed16Number_to_float(lut->e00);
		result.m[0][1] = s15Fixed16Number_to_float(lut->e01);
		result.m[0][2] = s15Fixed16Number_to_float(lut->e02);
		result.m[1][0] = s15Fixed16Number_to_float(lut->e10);
		result.m[1][1] = s15Fixed16Number_to_float(lut->e11);
		result.m[1][2] = s15Fixed16Number_to_float(lut->e12);
		result.m[2][0] = s15Fixed16Number_to_float(lut->e20);
		result.m[2][1] = s15Fixed16Number_to_float(lut->e21);
		result.m[2][2] = s15Fixed16Number_to_float(lut->e22);
		result.invalid = false;
	} else {
		memset(&result, 0, sizeof(struct matrix));
		result.invalid = true;
	}
	return result;
}

static struct matrix build_mAB_matrix(struct lutmABType *lut)
{
	struct matrix result;
	if (lut) {
		result.m[0][0] = s15Fixed16Number_to_float(lut->e00);
		result.m[0][1] = s15Fixed16Number_to_float(lut->e01);
		result.m[0][2] = s15Fixed16Number_to_float(lut->e02);
		result.m[1][0] = s15Fixed16Number_to_float(lut->e10);
		result.m[1][1] = s15Fixed16Number_to_float(lut->e11);
		result.m[1][2] = s15Fixed16Number_to_float(lut->e12);
		result.m[2][0] = s15Fixed16Number_to_float(lut->e20);
		result.m[2][1] = s15Fixed16Number_to_float(lut->e21);
		result.m[2][2] = s15Fixed16Number_to_float(lut->e22);
		result.invalid = false;
	} else {
		memset(&result, 0, sizeof(struct matrix));
		result.invalid = true;
	}
	return result;
}

//Based on lcms cmsLab2XYZ
#define f(t) (t <= (24.0f/116.0f)*(24.0f/116.0f)*(24.0f/116.0f)) ? ((841.0/108.0) * t + (16.0/116.0)) : pow(t,1.0/3.0)
#define f_1(t) (t <= (24.0f/116.0f)) ? ((108.0/841.0) * (t - (16.0/116.0))) : (t * t * t)
static void qcms_transform_module_LAB_to_XYZ(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	// lcms: D50 XYZ values
	float WhitePointX = 0.9642f;
	float WhitePointY = 1.0f;
	float WhitePointZ = 0.8249f;
	for (i = 0; i < length; i++) {
		float device_L = *src++ * 100.0f;
		float device_a = *src++ * 255.0f - 128.0f;
		float device_b = *src++ * 255.0f - 128.0f;
		float y = (device_L + 16.0f) / 116.0f;

		float X = f_1((y + 0.002f * device_a)) * WhitePointX;
		float Y = f_1(y) * WhitePointY;
		float Z = f_1((y - 0.005f * device_b)) * WhitePointZ;
		*dest++ = X / (1.0 + 32767.0/32768.0);
		*dest++ = Y / (1.0 + 32767.0/32768.0);
		*dest++ = Z / (1.0 + 32767.0/32768.0);
	}
}

//Based on lcms cmsXYZ2Lab
static void qcms_transform_module_XYZ_to_LAB(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
        // lcms: D50 XYZ values
        float WhitePointX = 0.9642f;
        float WhitePointY = 1.0f;
        float WhitePointZ = 0.8249f;
        for (i = 0; i < length; i++) {
                float device_x = *src++ * (1.0 + 32767.0/32768.0) / WhitePointX;
                float device_y = *src++ * (1.0 + 32767.0/32768.0) / WhitePointY;
                float device_z = *src++ * (1.0 + 32767.0/32768.0) / WhitePointZ;

		float fx = f(device_x);
		float fy = f(device_y);
		float fz = f(device_z);

                float L = 116.0f*fy - 16.0f;
                float a = 500.0f*(fx - fy);
                float b = 200.0f*(fy - fz);
                *dest++ = L / 100.0f;
                *dest++ = (a+128.0f) / 255.0f;
                *dest++ = (b+128.0f) / 255.0f;
        }

}

static void qcms_transform_module_clut_only(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	int xy_len = 1;
	int x_len = transform->grid_size;
	int len = x_len * x_len;
	float* r_table = transform->r_clut;
	float* g_table = transform->g_clut;
	float* b_table = transform->b_clut;

	for (i = 0; i < length; i++) {
		float linear_r = *src++;
		float linear_g = *src++;
		float linear_b = *src++;

		int x = floor(linear_r * (transform->grid_size-1));
		int y = floor(linear_g * (transform->grid_size-1));
		int z = floor(linear_b * (transform->grid_size-1));
		int x_n = ceil(linear_r * (transform->grid_size-1));
		int y_n = ceil(linear_g * (transform->grid_size-1));
		int z_n = ceil(linear_b * (transform->grid_size-1));
		float x_d = linear_r * (transform->grid_size-1) - x;
		float y_d = linear_g * (transform->grid_size-1) - y;
		float z_d = linear_b * (transform->grid_size-1) - z;

		float r_x1 = lerp(CLU(r_table,x,y,z), CLU(r_table,x_n,y,z), x_d);
		float r_x2 = lerp(CLU(r_table,x,y_n,z), CLU(r_table,x_n,y_n,z), x_d);
		float r_y1 = lerp(r_x1, r_x2, y_d);
		float r_x3 = lerp(CLU(r_table,x,y,z_n), CLU(r_table,x_n,y,z_n), x_d);
		float r_x4 = lerp(CLU(r_table,x,y_n,z_n), CLU(r_table,x_n,y_n,z_n), x_d);
		float r_y2 = lerp(r_x3, r_x4, y_d);
		float clut_r = lerp(r_y1, r_y2, z_d);

		float g_x1 = lerp(CLU(g_table,x,y,z), CLU(g_table,x_n,y,z), x_d);
		float g_x2 = lerp(CLU(g_table,x,y_n,z), CLU(g_table,x_n,y_n,z), x_d);
		float g_y1 = lerp(g_x1, g_x2, y_d);
		float g_x3 = lerp(CLU(g_table,x,y,z_n), CLU(g_table,x_n,y,z_n), x_d);
		float g_x4 = lerp(CLU(g_table,x,y_n,z_n), CLU(g_table,x_n,y_n,z_n), x_d);
		float g_y2 = lerp(g_x3, g_x4, y_d);
		float clut_g = lerp(g_y1, g_y2, z_d);

		float b_x1 = lerp(CLU(b_table,x,y,z), CLU(b_table,x_n,y,z), x_d);
		float b_x2 = lerp(CLU(b_table,x,y_n,z), CLU(b_table,x_n,y_n,z), x_d);
		float b_y1 = lerp(b_x1, b_x2, y_d);
		float b_x3 = lerp(CLU(b_table,x,y,z_n), CLU(b_table,x_n,y,z_n), x_d);
		float b_x4 = lerp(CLU(b_table,x,y_n,z_n), CLU(b_table,x_n,y_n,z_n), x_d);
		float b_y2 = lerp(b_x3, b_x4, y_d);
		float clut_b = lerp(b_y1, b_y2, z_d);

		*dest++ = clamp_float(clut_r);
		*dest++ = clamp_float(clut_g);
		*dest++ = clamp_float(clut_b);
	}
}

static void qcms_transform_module_clut(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	int xy_len = 1;
	int x_len = transform->grid_size;
	int len = x_len * x_len;
	float* r_table = transform->r_clut;
	float* g_table = transform->g_clut;
	float* b_table = transform->b_clut;
	for (i = 0; i < length; i++) {
		float device_r = *src++;
		float device_g = *src++;
		float device_b = *src++;
		float linear_r = lut_interp_linear_float(device_r,
				transform->input_clut_table_r, transform->input_clut_table_length);
		float linear_g = lut_interp_linear_float(device_g,
				transform->input_clut_table_g, transform->input_clut_table_length);
		float linear_b = lut_interp_linear_float(device_b,
				transform->input_clut_table_b, transform->input_clut_table_length);

		int x = floor(linear_r * (transform->grid_size-1));
		int y = floor(linear_g * (transform->grid_size-1));
		int z = floor(linear_b * (transform->grid_size-1));
		int x_n = ceil(linear_r * (transform->grid_size-1));
		int y_n = ceil(linear_g * (transform->grid_size-1));
		int z_n = ceil(linear_b * (transform->grid_size-1));
		float x_d = linear_r * (transform->grid_size-1) - x;
		float y_d = linear_g * (transform->grid_size-1) - y;
		float z_d = linear_b * (transform->grid_size-1) - z;

		float r_x1 = lerp(CLU(r_table,x,y,z), CLU(r_table,x_n,y,z), x_d);
		float r_x2 = lerp(CLU(r_table,x,y_n,z), CLU(r_table,x_n,y_n,z), x_d);
		float r_y1 = lerp(r_x1, r_x2, y_d);
		float r_x3 = lerp(CLU(r_table,x,y,z_n), CLU(r_table,x_n,y,z_n), x_d);
		float r_x4 = lerp(CLU(r_table,x,y_n,z_n), CLU(r_table,x_n,y_n,z_n), x_d);
		float r_y2 = lerp(r_x3, r_x4, y_d);
		float clut_r = lerp(r_y1, r_y2, z_d);

		float g_x1 = lerp(CLU(g_table,x,y,z), CLU(g_table,x_n,y,z), x_d);
		float g_x2 = lerp(CLU(g_table,x,y_n,z), CLU(g_table,x_n,y_n,z), x_d);
		float g_y1 = lerp(g_x1, g_x2, y_d);
		float g_x3 = lerp(CLU(g_table,x,y,z_n), CLU(g_table,x_n,y,z_n), x_d);
		float g_x4 = lerp(CLU(g_table,x,y_n,z_n), CLU(g_table,x_n,y_n,z_n), x_d);
		float g_y2 = lerp(g_x3, g_x4, y_d);
		float clut_g = lerp(g_y1, g_y2, z_d);

		float b_x1 = lerp(CLU(b_table,x,y,z), CLU(b_table,x_n,y,z), x_d);
		float b_x2 = lerp(CLU(b_table,x,y_n,z), CLU(b_table,x_n,y_n,z), x_d);
		float b_y1 = lerp(b_x1, b_x2, y_d);
		float b_x3 = lerp(CLU(b_table,x,y,z_n), CLU(b_table,x_n,y,z_n), x_d);
		float b_x4 = lerp(CLU(b_table,x,y_n,z_n), CLU(b_table,x_n,y_n,z_n), x_d);
		float b_y2 = lerp(b_x3, b_x4, y_d);
		float clut_b = lerp(b_y1, b_y2, z_d);

		float pcs_r = lut_interp_linear_float(clut_r,
				transform->output_clut_table_r, transform->output_clut_table_length);
		float pcs_g = lut_interp_linear_float(clut_g,
				transform->output_clut_table_g, transform->output_clut_table_length);
		float pcs_b = lut_interp_linear_float(clut_b,
				transform->output_clut_table_b, transform->output_clut_table_length);

		*dest++ = clamp_float(pcs_r);
		*dest++ = clamp_float(pcs_g);
		*dest++ = clamp_float(pcs_b);
	}
}

/* NOT USED
static void qcms_transform_module_tetra_clut(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	int xy_len = 1;
	int x_len = transform->grid_size;
	int len = x_len * x_len;
	float* r_table = transform->r_clut;
	float* g_table = transform->g_clut;
	float* b_table = transform->b_clut;
	float c0_r, c1_r, c2_r, c3_r;
	float c0_g, c1_g, c2_g, c3_g;
	float c0_b, c1_b, c2_b, c3_b;
	float clut_r, clut_g, clut_b;
	float pcs_r, pcs_g, pcs_b;
	for (i = 0; i < length; i++) {
		float device_r = *src++;
		float device_g = *src++;
		float device_b = *src++;
		float linear_r = lut_interp_linear_float(device_r,
				transform->input_clut_table_r, transform->input_clut_table_length);
		float linear_g = lut_interp_linear_float(device_g,
				transform->input_clut_table_g, transform->input_clut_table_length);
		float linear_b = lut_interp_linear_float(device_b,
				transform->input_clut_table_b, transform->input_clut_table_length);

		int x = floor(linear_r * (transform->grid_size-1));
		int y = floor(linear_g * (transform->grid_size-1));
		int z = floor(linear_b * (transform->grid_size-1));
		int x_n = ceil(linear_r * (transform->grid_size-1));
		int y_n = ceil(linear_g * (transform->grid_size-1));
		int z_n = ceil(linear_b * (transform->grid_size-1));
		float rx = linear_r * (transform->grid_size-1) - x;
		float ry = linear_g * (transform->grid_size-1) - y;
		float rz = linear_b * (transform->grid_size-1) - z;

		c0_r = CLU(r_table, x, y, z);
		c0_g = CLU(g_table, x, y, z);
		c0_b = CLU(b_table, x, y, z);
		if( rx >= ry ) {
			if (ry >= rz) { //rx >= ry && ry >= rz
				c1_r = CLU(r_table, x_n, y, z) - c0_r;
				c2_r = CLU(r_table, x_n, y_n, z) - CLU(r_table, x_n, y, z);
				c3_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x_n, y_n, z);
				c1_g = CLU(g_table, x_n, y, z) - c0_g;
				c2_g = CLU(g_table, x_n, y_n, z) - CLU(g_table, x_n, y, z);
				c3_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x_n, y_n, z);
				c1_b = CLU(b_table, x_n, y, z) - c0_b;
				c2_b = CLU(b_table, x_n, y_n, z) - CLU(b_table, x_n, y, z);
				c3_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x_n, y_n, z);
			} else {
				if (rx >= rz) { //rx >= rz && rz >= ry
					c1_r = CLU(r_table, x_n, y, z) - c0_r;
					c2_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x_n, y, z_n);
					c3_r = CLU(r_table, x_n, y, z_n) - CLU(r_table, x_n, y, z);
					c1_g = CLU(g_table, x_n, y, z) - c0_g;
					c2_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x_n, y, z_n);
					c3_g = CLU(g_table, x_n, y, z_n) - CLU(g_table, x_n, y, z);
					c1_b = CLU(b_table, x_n, y, z) - c0_b;
					c2_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x_n, y, z_n);
					c3_b = CLU(b_table, x_n, y, z_n) - CLU(b_table, x_n, y, z);
				} else { //rz > rx && rx >= ry
					c1_r = CLU(r_table, x_n, y, z_n) - CLU(r_table, x, y, z_n);
					c2_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x_n, y, z_n);
					c3_r = CLU(r_table, x, y, z_n) - c0_r;
					c1_g = CLU(g_table, x_n, y, z_n) - CLU(g_table, x, y, z_n);
					c2_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x_n, y, z_n);
					c3_g = CLU(g_table, x, y, z_n) - c0_g;
					c1_b = CLU(b_table, x_n, y, z_n) - CLU(b_table, x, y, z_n);
					c2_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x_n, y, z_n);
					c3_b = CLU(b_table, x, y, z_n) - c0_b;
				}
			}
		} else {
			if (rx >= rz) { //ry > rx && rx >= rz
				c1_r = CLU(r_table, x_n, y_n, z) - CLU(r_table, x, y_n, z);
				c2_r = CLU(r_table, x_n, y_n, z) - c0_r;
				c3_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x_n, y_n, z);
				c1_g = CLU(g_table, x_n, y_n, z) - CLU(g_table, x, y_n, z);
				c2_g = CLU(g_table, x_n, y_n, z) - c0_g;
				c3_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x_n, y_n, z);
				c1_b = CLU(b_table, x_n, y_n, z) - CLU(b_table, x, y_n, z);
				c2_b = CLU(b_table, x_n, y_n, z) - c0_b;
				c3_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x_n, y_n, z);
			} else {
				if (ry >= rz) { //ry >= rz && rz > rx 
					c1_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x, y_n, z_n);
					c2_r = CLU(r_table, x, y_n, z) - c0_r;
					c3_r = CLU(r_table, x, y_n, z_n) - CLU(r_table, x, y_n, z);
					c1_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x, y_n, z_n);
					c2_g = CLU(g_table, x, y_n, z) - c0_g;
					c3_g = CLU(g_table, x, y_n, z_n) - CLU(g_table, x, y_n, z);
					c1_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x, y_n, z_n);
					c2_b = CLU(b_table, x, y_n, z) - c0_b;
					c3_b = CLU(b_table, x, y_n, z_n) - CLU(b_table, x, y_n, z);
				} else { //rz > ry && ry > rx
					c1_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x, y_n, z_n);
					c2_r = CLU(r_table, x, y_n, z) - c0_r;
					c3_r = CLU(r_table, x_n, y_n, z_n) - CLU(r_table, x_n, y_n, z);
					c1_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x, y_n, z_n);
					c2_g = CLU(g_table, x, y_n, z) - c0_g;
					c3_g = CLU(g_table, x_n, y_n, z_n) - CLU(g_table, x_n, y_n, z);
					c1_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x, y_n, z_n);
					c2_b = CLU(b_table, x, y_n, z) - c0_b;
					c3_b = CLU(b_table, x_n, y_n, z_n) - CLU(b_table, x_n, y_n, z);
				}
			}
		}

		clut_r = c0_r + c1_r*rx + c2_r*ry + c3_r*rz;
		clut_g = c0_g + c1_g*rx + c2_g*ry + c3_g*rz;
		clut_b = c0_b + c1_b*rx + c2_b*ry + c3_b*rz;

		pcs_r = lut_interp_linear_float(clut_r,
				transform->output_clut_table_r, transform->output_clut_table_length);
		pcs_g = lut_interp_linear_float(clut_g,
				transform->output_clut_table_g, transform->output_clut_table_length);
		pcs_b = lut_interp_linear_float(clut_b,
				transform->output_clut_table_b, transform->output_clut_table_length);
		*dest++ = clamp_float(pcs_r);
		*dest++ = clamp_float(pcs_g);
		*dest++ = clamp_float(pcs_b);
	}
}
*/

static void qcms_transform_module_gamma_table(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	float out_r, out_g, out_b;
	for (i = 0; i < length; i++) {
		float in_r = *src++;
		float in_g = *src++;
		float in_b = *src++;

		out_r = lut_interp_linear_float(in_r, transform->input_clut_table_r, 256);
		out_g = lut_interp_linear_float(in_g, transform->input_clut_table_g, 256);
		out_b = lut_interp_linear_float(in_b, transform->input_clut_table_b, 256);

		*dest++ = clamp_float(out_r);
		*dest++ = clamp_float(out_g);
		*dest++ = clamp_float(out_b);
	}
}

static void qcms_transform_module_gamma_lut(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	float out_r, out_g, out_b;
	for (i = 0; i < length; i++) {
		float in_r = *src++;
		float in_g = *src++;
		float in_b = *src++;

		out_r = lut_interp_linear(in_r,
				transform->output_gamma_lut_r, transform->output_gamma_lut_r_length);
		out_g = lut_interp_linear(in_g,
				transform->output_gamma_lut_g, transform->output_gamma_lut_g_length);
		out_b = lut_interp_linear(in_b,
				transform->output_gamma_lut_b, transform->output_gamma_lut_b_length);

		*dest++ = clamp_float(out_r);
		*dest++ = clamp_float(out_g);
		*dest++ = clamp_float(out_b);
	}
}

static void qcms_transform_module_matrix_translate(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	struct matrix mat;

	/* store the results in column major mode
	 * this makes doing the multiplication with sse easier */
	mat.m[0][0] = transform->matrix.m[0][0];
	mat.m[1][0] = transform->matrix.m[0][1];
	mat.m[2][0] = transform->matrix.m[0][2];
	mat.m[0][1] = transform->matrix.m[1][0];
	mat.m[1][1] = transform->matrix.m[1][1];
	mat.m[2][1] = transform->matrix.m[1][2];
	mat.m[0][2] = transform->matrix.m[2][0];
	mat.m[1][2] = transform->matrix.m[2][1];
	mat.m[2][2] = transform->matrix.m[2][2];

	for (i = 0; i < length; i++) {
		float in_r = *src++;
		float in_g = *src++;
		float in_b = *src++;

		float out_r = mat.m[0][0]*in_r + mat.m[1][0]*in_g + mat.m[2][0]*in_b + transform->tx;
		float out_g = mat.m[0][1]*in_r + mat.m[1][1]*in_g + mat.m[2][1]*in_b + transform->ty;
		float out_b = mat.m[0][2]*in_r + mat.m[1][2]*in_g + mat.m[2][2]*in_b + transform->tz;

		*dest++ = clamp_float(out_r);
		*dest++ = clamp_float(out_g);
		*dest++ = clamp_float(out_b);
	}
}

static void qcms_transform_module_matrix(struct qcms_modular_transform *transform, float *src, float *dest, size_t length)
{
	size_t i;
	struct matrix mat;

	/* store the results in column major mode
	 * this makes doing the multiplication with sse easier */
	mat.m[0][0] = transform->matrix.m[0][0];
	mat.m[1][0] = transform->matrix.m[0][1];
	mat.m[2][0] = transform->matrix.m[0][2];
	mat.m[0][1] = transform->matrix.m[1][0];
	mat.m[1][1] = transform->matrix.m[1][1];
	mat.m[2][1] = transform->matrix.m[1][2];
	mat.m[0][2] = transform->matrix.m[2][0];
	mat.m[1][2] = transform->matrix.m[2][1];
	mat.m[2][2] = transform->matrix.m[2][2];

	for (i = 0; i < length; i++) {
		float in_r = *src++;
		float in_g = *src++;
		float in_b = *src++;

		float out_r = mat.m[0][0]*in_r + mat.m[1][0]*in_g + mat.m[2][0]*in_b;
		float out_g = mat.m[0][1]*in_r + mat.m[1][1]*in_g + mat.m[2][1]*in_b;
		float out_b = mat.m[0][2]*in_r + mat.m[1][2]*in_g + mat.m[2][2]*in_b;

		*dest++ = clamp_float(out_r);
		*dest++ = clamp_float(out_g);
		*dest++ = clamp_float(out_b);
	}
}

static struct qcms_modular_transform* qcms_modular_transform_alloc() {
	return calloc(1, sizeof(struct qcms_modular_transform));
}

static void qcms_modular_transform_release(struct qcms_modular_transform *transform)
{
	struct qcms_modular_transform *next_transform;
	while (transform != NULL) {
		next_transform = transform->next_transform;
		// clut may use a single block of memory.
		// Perhaps we should remove this to simply the code.
		if (transform->input_clut_table_r + transform->input_clut_table_length == transform->input_clut_table_g && transform->input_clut_table_g + transform->input_clut_table_length == transform->input_clut_table_b) {
			if (transform->input_clut_table_r) free(transform->input_clut_table_r);
		} else {
			if (transform->input_clut_table_r) free(transform->input_clut_table_r);
			if (transform->input_clut_table_g) free(transform->input_clut_table_g);
			if (transform->input_clut_table_b) free(transform->input_clut_table_b);
		}
		if (transform->r_clut + 1 == transform->g_clut && transform->g_clut + 1 == transform->b_clut) {
			if (transform->r_clut) free(transform->r_clut);
		} else {
			if (transform->r_clut) free(transform->r_clut);
			if (transform->g_clut) free(transform->g_clut);
			if (transform->b_clut) free(transform->b_clut);
		}
		if (transform->output_clut_table_r + transform->output_clut_table_length == transform->output_clut_table_g && transform->output_clut_table_g+ transform->output_clut_table_length == transform->output_clut_table_b) {
			if (transform->output_clut_table_r) free(transform->output_clut_table_r);
		} else {
			if (transform->output_clut_table_r) free(transform->output_clut_table_r);
			if (transform->output_clut_table_g) free(transform->output_clut_table_g);
			if (transform->output_clut_table_b) free(transform->output_clut_table_b);
		}
		if (transform->output_gamma_lut_r) free(transform->output_gamma_lut_r);
		if (transform->output_gamma_lut_g) free(transform->output_gamma_lut_g);
		if (transform->output_gamma_lut_b) free(transform->output_gamma_lut_b);
		free(transform);
		transform = next_transform;
	}
}

/* Set transform to be the next element in the linked list. */
static void append_transform(struct qcms_modular_transform *transform, struct qcms_modular_transform ***next_transform)
{
	**next_transform = transform;
	while (transform) {
		*next_transform = &(transform->next_transform);
		transform = transform->next_transform;
	}
}

/* reverse the transformation list (used by mBA) */
static struct qcms_modular_transform* reverse_transform(struct qcms_modular_transform *transform) 
{
	struct qcms_modular_transform *prev_transform = NULL;
	while (transform != NULL) {
		struct qcms_modular_transform *next_transform = transform->next_transform;
		transform->next_transform = prev_transform;
		prev_transform = transform;
		transform = next_transform;
	}
	
	return prev_transform;
}

#define EMPTY_TRANSFORM_LIST NULL
static struct qcms_modular_transform* qcms_modular_transform_create_mAB(struct lutmABType *lut)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform **next_transform = &first_transform;
	struct qcms_modular_transform *transform = NULL;

	if (lut->a_curves[0] != NULL) {
		size_t clut_length;
		float *clut;

		// If the A curve is present this also implies the 
		// presence of a CLUT.
		if (!lut->clut_table) 
			goto fail;

		// Prepare A curve.
		transform = qcms_modular_transform_alloc();
		if (!transform)
			goto fail;
		append_transform(transform, &next_transform);
		transform->input_clut_table_r = build_input_gamma_table(lut->a_curves[0]);
		transform->input_clut_table_g = build_input_gamma_table(lut->a_curves[1]);
		transform->input_clut_table_b = build_input_gamma_table(lut->a_curves[2]);
		transform->transform_module_fn = qcms_transform_module_gamma_table;
		if (lut->num_grid_points[0] != lut->num_grid_points[1] ||
			lut->num_grid_points[1] != lut->num_grid_points[2] ) {
			//XXX: We don't currently support clut that are not squared!
			goto fail;
		}

		// Prepare CLUT
		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		clut_length = sizeof(float)*pow(lut->num_grid_points[0], 3)*3;
		clut = malloc(clut_length);
		if (!clut)
			goto fail;
		memcpy(clut, lut->clut_table, clut_length);
		transform->r_clut = clut + 0;
		transform->g_clut = clut + 1;
		transform->b_clut = clut + 2;
		transform->grid_size = lut->num_grid_points[0];
		transform->transform_module_fn = qcms_transform_module_clut_only;
	}
	if (lut->m_curves[0] != NULL) {
		// M curve imples the presence of a Matrix

		// Prepare M curve
		transform = qcms_modular_transform_alloc();
		if (!transform)
			goto fail;
		append_transform(transform, &next_transform);
		transform->input_clut_table_r = build_input_gamma_table(lut->m_curves[0]);
		transform->input_clut_table_g = build_input_gamma_table(lut->m_curves[1]);
		transform->input_clut_table_b = build_input_gamma_table(lut->m_curves[2]);
		transform->transform_module_fn = qcms_transform_module_gamma_table;

		// Prepare Matrix
		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->matrix = build_mAB_matrix(lut);
		if (transform->matrix.invalid)
			goto fail;
		transform->tx = s15Fixed16Number_to_float(lut->e03);
		transform->ty = s15Fixed16Number_to_float(lut->e13);
		transform->tz = s15Fixed16Number_to_float(lut->e23);
		transform->transform_module_fn = qcms_transform_module_matrix_translate;
	}
	if (lut->b_curves[0] != NULL) {
		// Prepare B curve
		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->input_clut_table_r = build_input_gamma_table(lut->b_curves[0]);
		transform->input_clut_table_g = build_input_gamma_table(lut->b_curves[1]);
		transform->input_clut_table_b = build_input_gamma_table(lut->b_curves[2]);
		transform->transform_module_fn = qcms_transform_module_gamma_table;
	} else {
		// B curve is mandatory
		goto fail;
	}

	if (lut->reversed) {
		// mBA are identical to mAB except that the transformation order
		// is reversed
		first_transform = reverse_transform(first_transform);
	}

	return first_transform;
fail:
	qcms_modular_transform_release(first_transform);
	return NULL;
}

static struct qcms_modular_transform* qcms_modular_transform_create_lut(struct lutType *lut)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform **next_transform = &first_transform;
	struct qcms_modular_transform *transform = NULL;

	size_t in_curve_len, clut_length, out_curve_len;
	float *in_curves, *clut, *out_curves;

	// Prepare Matrix
	transform = qcms_modular_transform_alloc();
	if (!transform) 
		goto fail;
	append_transform(transform, &next_transform);
	transform->matrix = build_lut_matrix(lut);
	if (transform->matrix.invalid)
		goto fail;
	transform->transform_module_fn = qcms_transform_module_matrix;

	// Prepare input curves
	transform = qcms_modular_transform_alloc();
	if (!transform) 
		goto fail;
	append_transform(transform, &next_transform);
	in_curve_len = sizeof(float)*lut->num_input_table_entries * 3;
	in_curves = malloc(in_curve_len);
	if (!in_curves) 
		goto fail;
	memcpy(in_curves, lut->input_table, in_curve_len);
	transform->input_clut_table_r = in_curves + lut->num_input_table_entries * 0;
	transform->input_clut_table_g = in_curves + lut->num_input_table_entries * 1;
	transform->input_clut_table_b = in_curves + lut->num_input_table_entries * 2;
	transform->input_clut_table_length = lut->num_input_table_entries;

	// Prepare table
	clut_length = sizeof(float)*pow(lut->num_clut_grid_points, 3)*3;
	clut = malloc(clut_length);
	if (!clut) 
		goto fail;
	memcpy(clut, lut->clut_table, clut_length);
	transform->r_clut = clut + 0;
	transform->g_clut = clut + 1;
	transform->b_clut = clut + 2;
	transform->grid_size = lut->num_clut_grid_points;

	// Prepare output curves
	out_curve_len = sizeof(float) * lut->num_output_table_entries * 3;
	out_curves = malloc(out_curve_len);
	if (!out_curves) 
		goto fail;
	memcpy(out_curves, lut->output_table, out_curve_len);
	transform->output_clut_table_r = out_curves + lut->num_output_table_entries * 0;
	transform->output_clut_table_g = out_curves + lut->num_output_table_entries * 1;
	transform->output_clut_table_b = out_curves + lut->num_output_table_entries * 2;
	transform->output_clut_table_length = lut->num_output_table_entries;
	transform->transform_module_fn = qcms_transform_module_clut;

	return first_transform;
fail:
	qcms_modular_transform_release(first_transform);
	return NULL;
}

struct qcms_modular_transform* qcms_modular_transform_create_input(qcms_profile *in)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform **next_transform = &first_transform;

	if (in->A2B0) {
		struct qcms_modular_transform *lut_transform;
		lut_transform = qcms_modular_transform_create_lut(in->A2B0);
		if (!lut_transform)
			goto fail;
		append_transform(lut_transform, &next_transform);
	} else if (in->mAB && in->mAB->num_in_channels == 3 && in->mAB->num_out_channels == 3) {
		struct qcms_modular_transform *mAB_transform;
		mAB_transform = qcms_modular_transform_create_mAB(in->mAB);
		if (!mAB_transform)
			goto fail;
		append_transform(mAB_transform, &next_transform);

	} else {
		struct qcms_modular_transform *transform;

		transform = qcms_modular_transform_alloc();
		if (!transform)
			goto fail;
		append_transform(transform, &next_transform);
		transform->input_clut_table_r = build_input_gamma_table(in->redTRC);
		transform->input_clut_table_g = build_input_gamma_table(in->greenTRC);
		transform->input_clut_table_b = build_input_gamma_table(in->blueTRC);
		transform->transform_module_fn = qcms_transform_module_gamma_table;
		if (!transform->input_clut_table_r || !transform->input_clut_table_g ||
				!transform->input_clut_table_b) {
			goto fail;
		}

		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->matrix.m[0][0] = 1/1.999969482421875f;
		transform->matrix.m[0][1] = 0.f;
		transform->matrix.m[0][2] = 0.f;
		transform->matrix.m[1][0] = 0.f;
		transform->matrix.m[1][1] = 1/1.999969482421875f;
		transform->matrix.m[1][2] = 0.f;
		transform->matrix.m[2][0] = 0.f;
		transform->matrix.m[2][1] = 0.f;
		transform->matrix.m[2][2] = 1/1.999969482421875f;
		transform->matrix.invalid = false;
		transform->transform_module_fn = qcms_transform_module_matrix;

		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->matrix = build_colorant_matrix(in);
		transform->transform_module_fn = qcms_transform_module_matrix;
	}

	return first_transform;
fail:
	qcms_modular_transform_release(first_transform);
	return EMPTY_TRANSFORM_LIST;
}
static struct qcms_modular_transform* qcms_modular_transform_create_output(qcms_profile *out)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform **next_transform = &first_transform;

	if (out->B2A0) {
		struct qcms_modular_transform *lut_transform;
		lut_transform = qcms_modular_transform_create_lut(out->B2A0);
		if (!lut_transform) 
			goto fail;
		append_transform(lut_transform, &next_transform);
	} else if (out->mBA && out->mBA->num_in_channels == 3 && out->mBA->num_out_channels == 3) {
		struct qcms_modular_transform *lut_transform;
		lut_transform = qcms_modular_transform_create_mAB(out->mBA);
		if (!lut_transform) 
			goto fail;
		append_transform(lut_transform, &next_transform);
	} else if (out->redTRC && out->greenTRC && out->blueTRC) {
		struct qcms_modular_transform *transform;

		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->matrix = matrix_invert(build_colorant_matrix(out));
		transform->transform_module_fn = qcms_transform_module_matrix;

		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		transform->matrix.m[0][0] = 1.999969482421875f;
		transform->matrix.m[0][1] = 0.f;
		transform->matrix.m[0][2] = 0.f;
		transform->matrix.m[1][0] = 0.f;
		transform->matrix.m[1][1] = 1.999969482421875f;
		transform->matrix.m[1][2] = 0.f;
		transform->matrix.m[2][0] = 0.f;
		transform->matrix.m[2][1] = 0.f;
		transform->matrix.m[2][2] = 1.999969482421875f;
		transform->matrix.invalid = false;
		transform->transform_module_fn = qcms_transform_module_matrix;

		transform = qcms_modular_transform_alloc();
		if (!transform) 
			goto fail;
		append_transform(transform, &next_transform);
		build_output_lut(out->redTRC, &transform->output_gamma_lut_r,
			&transform->output_gamma_lut_r_length);
		build_output_lut(out->greenTRC, &transform->output_gamma_lut_g,
			&transform->output_gamma_lut_g_length);
		build_output_lut(out->blueTRC, &transform->output_gamma_lut_b,
			&transform->output_gamma_lut_b_length);
		transform->transform_module_fn = qcms_transform_module_gamma_lut;

		if (!transform->output_gamma_lut_r || !transform->output_gamma_lut_g ||
				!transform->output_gamma_lut_b) {
			goto fail;
		}
	} else {
		assert(0 && "Unsupported output profile workflow.");
		return NULL;
	}

	return first_transform;
fail:
	qcms_modular_transform_release(first_transform);
	return EMPTY_TRANSFORM_LIST;
}

/* Not Completed
// Simplify the transformation chain to an equivalent transformation chain
static struct qcms_modular_transform* qcms_modular_transform_reduce(struct qcms_modular_transform *transform)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform *curr_trans = transform;
	struct qcms_modular_transform *prev_trans = NULL;
	while (curr_trans) {
		struct qcms_modular_transform *next_trans = curr_trans->next_transform;
		if (curr_trans->transform_module_fn == qcms_transform_module_matrix) {
			if (next_trans && next_trans->transform_module_fn == qcms_transform_module_matrix) {
				curr_trans->matrix = matrix_multiply(curr_trans->matrix, next_trans->matrix);
				goto remove_next;	
			}
		}
		if (curr_trans->transform_module_fn == qcms_transform_module_gamma_table) {
			bool isLinear = true;
			uint16_t i;
			for (i = 0; isLinear && i < 256; i++) {
				isLinear &= (int)(curr_trans->input_clut_table_r[i] * 255) == i;
				isLinear &= (int)(curr_trans->input_clut_table_g[i] * 255) == i;
				isLinear &= (int)(curr_trans->input_clut_table_b[i] * 255) == i;
			}
			goto remove_current;
		}
		
next_transform:
		if (!next_trans) break;
		prev_trans = curr_trans;
		curr_trans = next_trans;
		continue;
remove_current:
		if (curr_trans == transform) {
			//Update head
			transform = next_trans;
		} else {
			prev_trans->next_transform = next_trans;
		}
		curr_trans->next_transform = NULL;
		qcms_modular_transform_release(curr_trans);
		//return transform;
		return qcms_modular_transform_reduce(transform);
remove_next:
		curr_trans->next_transform = next_trans->next_transform;
		next_trans->next_transform = NULL;
		qcms_modular_transform_release(next_trans);
		continue;
	}
	return transform;
}
*/

static struct qcms_modular_transform* qcms_modular_transform_create(qcms_profile *in, qcms_profile *out)
{
	struct qcms_modular_transform *first_transform = NULL;
	struct qcms_modular_transform **next_transform = &first_transform;

	if (in->color_space == RGB_SIGNATURE) {
		struct qcms_modular_transform* rgb_to_pcs;
		rgb_to_pcs = qcms_modular_transform_create_input(in);
		if (!rgb_to_pcs) 
			goto fail;
		append_transform(rgb_to_pcs, &next_transform);
	} else {
		assert(0 && "input color space not supported");
		goto fail;
	}

	if (in->pcs == LAB_SIGNATURE && out->pcs == XYZ_SIGNATURE) {
		struct qcms_modular_transform* lab_to_pcs;
		lab_to_pcs = qcms_modular_transform_alloc();
		if (!lab_to_pcs) 
			goto fail;
		append_transform(lab_to_pcs, &next_transform);
		lab_to_pcs->transform_module_fn = qcms_transform_module_LAB_to_XYZ;
	}

	// This does not improve accuracy in practice, something is wrong here.
	//if (in->chromaticAdaption.invalid == false) {
	//	struct qcms_modular_transform* chromaticAdaption;
	//	chromaticAdaption = qcms_modular_transform_alloc();
	//	if (!chromaticAdaption) 
	//		goto fail;
	//	append_transform(chromaticAdaption, &next_transform);
	//	chromaticAdaption->matrix = matrix_invert(in->chromaticAdaption);
	//	chromaticAdaption->transform_module_fn = qcms_transform_module_matrix;
	//}

        if (in->pcs == XYZ_SIGNATURE && out->pcs == LAB_SIGNATURE) {
		struct qcms_modular_transform* pcs_to_lab;
		pcs_to_lab = qcms_modular_transform_alloc();
		if (!pcs_to_lab) 
			goto fail;
		append_transform(pcs_to_lab, &next_transform);
		pcs_to_lab->transform_module_fn = qcms_transform_module_XYZ_to_LAB;
	}

	if (out->color_space == RGB_SIGNATURE) {
		struct qcms_modular_transform* pcs_to_rgb;
		pcs_to_rgb = qcms_modular_transform_create_output(out);
		if (!pcs_to_rgb) 
			goto fail;
		append_transform(pcs_to_rgb, &next_transform);
	} else {
		assert(0 && "output color space not supported");
		goto fail;
	}
	// Not Completed
	//return qcms_modular_transform_reduce(first_transform);
	return first_transform;
fail:
	qcms_modular_transform_release(first_transform);
	return EMPTY_TRANSFORM_LIST;
}

static float* qcms_modular_transform_data(struct qcms_modular_transform *transform, float *src, float *dest, size_t len)
{
        while (transform != NULL) {
                // Keep swaping src/dest when performing a transform to use less memory.
                float *new_src = dest;
		const transform_module_fn_t transform_fn = transform->transform_module_fn;
		if (transform_fn != qcms_transform_module_gamma_table &&
		    transform_fn != qcms_transform_module_gamma_lut &&
		    transform_fn != qcms_transform_module_clut &&
		    transform_fn != qcms_transform_module_clut_only &&
		    transform_fn != qcms_transform_module_matrix &&
		    transform_fn != qcms_transform_module_matrix_translate &&
		    transform_fn != qcms_transform_module_LAB_to_XYZ &&
		    transform_fn != qcms_transform_module_XYZ_to_LAB) {
			assert(0 && "Unsupported transform module");
			return NULL;
		}
                transform->transform_module_fn(transform,src,dest,len);
                dest = src;
                src = new_src;
                transform = transform->next_transform;
        }
        // The results end up in the src buffer because of the switching
        return src;
}

float* qcms_chain_transform(qcms_profile *in, qcms_profile *out, float *src, float *dest, size_t lutSize)
{
	struct qcms_modular_transform *transform_list = qcms_modular_transform_create(in, out);
	if (transform_list != NULL) {
		float *lut = qcms_modular_transform_data(transform_list, src, dest, lutSize/3);
		qcms_modular_transform_release(transform_list);
		return lut;
	}
	return NULL;
}
