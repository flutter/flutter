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

#define _ISOC99_SOURCE  /* for INFINITY */

#include <math.h>
#include <assert.h>
#include <string.h> //memcpy
#include "qcmsint.h"
#include "transform_util.h"
#include "matrix.h"

#if !defined(INFINITY)
#define INFINITY HUGE_VAL
#endif

#define PARAMETRIC_CURVE_TYPE 0x70617261 //'para'

/* value must be a value between 0 and 1 */
//XXX: is the above a good restriction to have?
// the output range of this function is 0..1
float lut_interp_linear(double input_value, uint16_t *table, size_t length)
{
	int upper, lower;
	float value;
	input_value = input_value * (length - 1); // scale to length of the array
	upper = ceil(input_value);
	lower = floor(input_value);
	//XXX: can we be more performant here?
	value = table[upper]*(1. - (upper - input_value)) + table[lower]*(upper - input_value);
	/* scale the value */
	return value * (1.f/65535.f);
}

/* same as above but takes and returns a uint16_t value representing a range from 0..1 */
uint16_t lut_interp_linear16(uint16_t input_value, uint16_t *table, size_t length)
{
	/* Start scaling input_value to the length of the array: 65535*(length-1).
	 * We'll divide out the 65535 next */
	uintptr_t value = (input_value * (length - 1));
	uint32_t upper = (value + 65534) / 65535; /* equivalent to ceil(value/65535) */
	uint32_t lower = value / 65535;           /* equivalent to floor(value/65535) */
	/* interp is the distance from upper to value scaled to 0..65535 */
	uint32_t interp = value % 65535;

	value = (table[upper]*(interp) + table[lower]*(65535 - interp))/65535; // 0..65535*65535

	return value;
}

/* same as above but takes an input_value from 0..PRECACHE_OUTPUT_MAX
 * and returns a uint8_t value representing a range from 0..1 */
static
uint8_t lut_interp_linear_precache_output(uint32_t input_value, uint16_t *table, size_t length)
{
	/* Start scaling input_value to the length of the array: PRECACHE_OUTPUT_MAX*(length-1).
	 * We'll divide out the PRECACHE_OUTPUT_MAX next */
	uintptr_t value = (input_value * (length - 1));

	/* equivalent to ceil(value/PRECACHE_OUTPUT_MAX) */
	uint32_t upper = (value + PRECACHE_OUTPUT_MAX-1) / PRECACHE_OUTPUT_MAX;
	/* equivalent to floor(value/PRECACHE_OUTPUT_MAX) */
	uint32_t lower = value / PRECACHE_OUTPUT_MAX;
	/* interp is the distance from upper to value scaled to 0..PRECACHE_OUTPUT_MAX */
	uint32_t interp = value % PRECACHE_OUTPUT_MAX;

	/* the table values range from 0..65535 */
	value = (table[upper]*(interp) + table[lower]*(PRECACHE_OUTPUT_MAX - interp)); // 0..(65535*PRECACHE_OUTPUT_MAX)

	/* round and scale */
	value += (PRECACHE_OUTPUT_MAX*65535/255)/2;
        value /= (PRECACHE_OUTPUT_MAX*65535/255); // scale to 0..255
	return value;
}

/* value must be a value between 0 and 1 */
//XXX: is the above a good restriction to have?
float lut_interp_linear_float(float value, float *table, size_t length)
{
        int upper, lower;
        value = value * (length - 1);
        upper = ceil(value);
        lower = floor(value);
        //XXX: can we be more performant here?
        value = table[upper]*(1. - (upper - value)) + table[lower]*(upper - value);
        /* scale the value */
        return value;
}

#if 0
/* if we use a different representation i.e. one that goes from 0 to 0x1000 we can be more efficient
 * because we can avoid the divisions and use a shifting instead */
/* same as above but takes and returns a uint16_t value representing a range from 0..1 */
uint16_t lut_interp_linear16(uint16_t input_value, uint16_t *table, int length)
{
	uint32_t value = (input_value * (length - 1));
	uint32_t upper = (value + 4095) / 4096; /* equivalent to ceil(value/4096) */
	uint32_t lower = value / 4096;           /* equivalent to floor(value/4096) */
	uint32_t interp = value % 4096;

	value = (table[upper]*(interp) + table[lower]*(4096 - interp))/4096; // 0..4096*4096

	return value;
}
#endif

void compute_curve_gamma_table_type1(float gamma_table[256], uint16_t gamma)
{
	unsigned int i;
	float gamma_float = u8Fixed8Number_to_float(gamma);
	for (i = 0; i < 256; i++) {
		// 0..1^(0..255 + 255/256) will always be between 0 and 1
		gamma_table[i] = pow(i/255., gamma_float);
	}
}

void compute_curve_gamma_table_type2(float gamma_table[256], uint16_t *table, size_t length)
{
	unsigned int i;
	for (i = 0; i < 256; i++) {
		gamma_table[i] = lut_interp_linear(i/255., table, length);
	}
}

void compute_curve_gamma_table_type_parametric(float gamma_table[256], float parameter[7], int count)
{
        size_t X;
        float interval;
        float a, b, c, e, f;
        float y = parameter[0];
        if (count == 0) {
                a = 1;
                b = 0;
                c = 0;
                e = 0;
                f = 0;
                interval = -INFINITY;
        } else if(count == 1) {
                a = parameter[1];
                b = parameter[2];
                c = 0;
                e = 0;
                f = 0;
                interval = -1 * parameter[2] / parameter[1];
        } else if(count == 2) {
                a = parameter[1];
                b = parameter[2];
                c = 0;
                e = parameter[3];
                f = parameter[3];
                interval = -1 * parameter[2] / parameter[1];
        } else if(count == 3) {
                a = parameter[1];
                b = parameter[2];
                c = parameter[3];
                e = -c;
                f = 0;
                interval = parameter[4];
        } else if(count == 4) {
                a = parameter[1];
                b = parameter[2];
                c = parameter[3];
                e = parameter[5] - c;
                f = parameter[6];
                interval = parameter[4];
        } else {
                assert(0 && "invalid parametric function type.");
                a = 1;
                b = 0;
                c = 0;
                e = 0;
                f = 0;
                interval = -INFINITY;
        }       
        for (X = 0; X < 256; X++) {
                if (X >= interval) {
                        // XXX The equations are not exactly as definied in the spec but are
                        //     algebraic equivilent.
                        // TODO Should division by 255 be for the whole expression.
                        gamma_table[X] = clamp_float(pow(a * X / 255. + b, y) + c + e);
                } else {
                        gamma_table[X] = clamp_float(c * X / 255. + f);
                }
        }
}

void compute_curve_gamma_table_type0(float gamma_table[256])
{
	unsigned int i;
	for (i = 0; i < 256; i++) {
		gamma_table[i] = i/255.;
	}
}

float clamp_float(float a)
{
	/* One would naturally write this function as the following:
	if (a > 1.)
		return 1.;
	else if (a < 0)
		return 0;
	else
		return a;

	However, that version will let NaNs pass through which is undesirable
	for most consumers.
	*/

	if (a > 1.)
		return 1.;
	else if (a >= 0)
		return a;
	else // a < 0 or a is NaN
		return 0;
}

unsigned char clamp_u8(float v)
{
	if (v > 255.)
		return 255;
	else if (v < 0)
		return 0;
	else
		return floor(v+.5);
}

float u8Fixed8Number_to_float(uint16_t x)
{
	// 0x0000 = 0.
	// 0x0100 = 1.
	// 0xffff = 255  + 255/256
	return x/256.;
}

/* The SSE2 code uses min & max which let NaNs pass through.
   We want to try to prevent that here by ensuring that
   gamma table is within expected values. */
void validate_gamma_table(float gamma_table[256])
{
	int i;
	for (i = 0; i < 256; i++) {
		// Note: we check that the gamma is not in range
		// instead of out of range so that we catch NaNs
		if (!(gamma_table[i] >= 0.f && gamma_table[i] <= 1.f)) {
			gamma_table[i] = 0.f;
		}
	}
}

float *build_input_gamma_table(struct curveType *TRC)
{
	float *gamma_table;

	if (!TRC) return NULL;
	gamma_table = malloc(sizeof(float)*256);
	if (gamma_table) {
		if (TRC->type == PARAMETRIC_CURVE_TYPE) {
			compute_curve_gamma_table_type_parametric(gamma_table, TRC->parameter, TRC->count);
		} else {
			if (TRC->count == 0) {
				compute_curve_gamma_table_type0(gamma_table);
			} else if (TRC->count == 1) {
				compute_curve_gamma_table_type1(gamma_table, TRC->data[0]);
			} else {
				compute_curve_gamma_table_type2(gamma_table, TRC->data, TRC->count);
			}
		}
	}

	validate_gamma_table(gamma_table);

	return gamma_table;
}

struct matrix build_colorant_matrix(qcms_profile *p)
{
	struct matrix result;
	result.m[0][0] = s15Fixed16Number_to_float(p->redColorant.X);
	result.m[0][1] = s15Fixed16Number_to_float(p->greenColorant.X);
	result.m[0][2] = s15Fixed16Number_to_float(p->blueColorant.X);
	result.m[1][0] = s15Fixed16Number_to_float(p->redColorant.Y);
	result.m[1][1] = s15Fixed16Number_to_float(p->greenColorant.Y);
	result.m[1][2] = s15Fixed16Number_to_float(p->blueColorant.Y);
	result.m[2][0] = s15Fixed16Number_to_float(p->redColorant.Z);
	result.m[2][1] = s15Fixed16Number_to_float(p->greenColorant.Z);
	result.m[2][2] = s15Fixed16Number_to_float(p->blueColorant.Z);
	result.invalid = false;
	return result;
}

/* The following code is copied nearly directly from lcms.
 * I think it could be much better. For example, Argyll seems to have better code in
 * icmTable_lookup_bwd and icmTable_setup_bwd. However, for now this is a quick way
 * to a working solution and allows for easy comparing with lcms. */
uint16_fract_t lut_inverse_interp16(uint16_t Value, uint16_t LutTable[], int length)
{
        int l = 1;
        int r = 0x10000;
        int x = 0, res;       // 'int' Give spacing for negative values
        int NumZeroes, NumPoles;
        int cell0, cell1;
        double val2;
        double y0, y1, x0, x1;
        double a, b, f;

        // July/27 2001 - Expanded to handle degenerated curves with an arbitrary
        // number of elements containing 0 at the begining of the table (Zeroes)
        // and another arbitrary number of poles (FFFFh) at the end.
        // First the zero and pole extents are computed, then value is compared.

        NumZeroes = 0;
        while (LutTable[NumZeroes] == 0 && NumZeroes < length-1)
            NumZeroes++;

        // There are no zeros at the beginning and we are trying to find a zero, so
        // return anything. It seems zero would be the less destructive choice
	/* I'm not sure that this makes sense, but oh well... */
        if (NumZeroes == 0 && Value == 0)
            return 0;

        NumPoles = 0;
        while (LutTable[length-1- NumPoles] == 0xFFFF && NumPoles < length-1)
            NumPoles++;

        // Does the curve belong to this case?
        if (NumZeroes > 1 || NumPoles > 1)
        {
                int a, b, sample;

                // Identify if value fall downto 0 or FFFF zone
                if (Value == 0) return 0;
                // if (Value == 0xFFFF) return 0xFFFF;
                sample = (length-1) * ((double) Value * (1./65535.));
                if (LutTable[sample] == 0xffff)
                    return 0xffff;

                // else restrict to valid zone

                a = ((NumZeroes-1) * 0xFFFF) / (length-1);
                b = ((length-1 - NumPoles) * 0xFFFF) / (length-1);

                l = a - 1;
                r = b + 1;

                // Ensure a valid binary search range

                if (l < 1)
                    l = 1;
                if (r > 0x10000)
                    r = 0x10000;

                // If the search range is inverted due to degeneracy,
                // deem LutTable non-invertible in this search range.
                // Refer to https://bugzil.la/1132467

                if (r <= l)
                    return 0;
        }

        // For input 0, return that to maintain black level. Note the binary search
        // does not. For example, it inverts the standard sRGB gamma curve to 7 at
        // the origin, causing a black level error.

        if (Value == 0 && NumZeroes) {
            return 0;
        }

        // Seems not a degenerated case... apply binary search

        while (r > l) {

                x = (l + r) / 2;

                res = (int) lut_interp_linear16((uint16_fract_t) (x-1), LutTable, length);

                if (res == Value) {

                    // Found exact match.

                    return (uint16_fract_t) (x - 1);
                }

                if (res > Value) r = x - 1;
                else l = x + 1;
        }

        // Not found, should we interpolate?

        // Get surrounding nodes

        assert(x >= 1);

        val2 = (length-1) * ((double) (x - 1) / 65535.0);

        cell0 = (int) floor(val2);
        cell1 = (int) ceil(val2);

        assert(cell0 >= 0);
        assert(cell1 >= 0);
        assert(cell0 < length);
        assert(cell1 < length);

        if (cell0 == cell1) return (uint16_fract_t) x;

        y0 = LutTable[cell0] ;
        x0 = (65535.0 * cell0) / (length-1); 

        y1 = LutTable[cell1] ;
        x1 = (65535.0 * cell1) / (length-1);

        a = (y1 - y0) / (x1 - x0);
        b = y0 - a * x0;

        if (fabs(a) < 0.01) return (uint16_fract_t) x;

        f = ((Value - b) / a);

        if (f < 0.0) return (uint16_fract_t) 0;
        if (f >= 65535.0) return (uint16_fract_t) 0xFFFF;

        return (uint16_fract_t) floor(f + 0.5);
}

/*
 The number of entries needed to invert a lookup table should not
 necessarily be the same as the original number of entries.  This is
 especially true of lookup tables that have a small number of entries.

 For example:
 Using a table like:
    {0, 3104, 14263, 34802, 65535}
 invert_lut will produce an inverse of:
    {3, 34459, 47529, 56801, 65535}
 which has an maximum error of about 9855 (pixel difference of ~38.346)

 For now, we punt the decision of output size to the caller. */
static uint16_t *invert_lut(uint16_t *table, int length, size_t out_length)
{
        int i;
        /* for now we invert the lut by creating a lut of size out_length
         * and attempting to lookup a value for each entry using lut_inverse_interp16 */
        uint16_t *output = malloc(sizeof(uint16_t)*out_length);
        if (!output)
                return NULL;

        for (i = 0; i < out_length; i++) {
                double x = ((double) i * 65535.) / (double) (out_length - 1);
                uint16_fract_t input = floor(x + .5);
                output[i] = lut_inverse_interp16(input, table, length);
        }
        return output;
}

static void compute_precache_pow(uint8_t *output, float gamma)
{
	uint32_t v = 0;
	for (v = 0; v < PRECACHE_OUTPUT_SIZE; v++) {
		//XXX: don't do integer/float conversion... and round?
		output[v] = 255. * pow(v/(double)PRECACHE_OUTPUT_MAX, gamma);
	}
}

void compute_precache_lut(uint8_t *output, uint16_t *table, int length)
{
	uint32_t v = 0;
	for (v = 0; v < PRECACHE_OUTPUT_SIZE; v++) {
		output[v] = lut_interp_linear_precache_output(v, table, length);
	}
}

void compute_precache_linear(uint8_t *output)
{
	uint32_t v = 0;
	for (v = 0; v < PRECACHE_OUTPUT_SIZE; v++) {
		//XXX: round?
		output[v] = v / (PRECACHE_OUTPUT_SIZE/256);
	}
}

qcms_bool compute_precache(struct curveType *trc, uint8_t *output)
{
        
        if (trc->type == PARAMETRIC_CURVE_TYPE) {
                        float gamma_table[256];
                        uint16_t gamma_table_uint[256];
                        uint16_t i;
                        uint16_t *inverted;
                        int inverted_size = 256;

                        compute_curve_gamma_table_type_parametric(gamma_table, trc->parameter, trc->count);
                        for(i = 0; i < 256; i++) {
                                gamma_table_uint[i] = (uint16_t)(gamma_table[i] * 65535);
                        }

                        //XXX: the choice of a minimum of 256 here is not backed by any theory, 
                        //     measurement or data, howeve r it is what lcms uses.
                        //     the maximum number we would need is 65535 because that's the 
                        //     accuracy used for computing the pre cache table
                        if (inverted_size < 256)
                                inverted_size = 256;

                        inverted = invert_lut(gamma_table_uint, 256, inverted_size);
                        if (!inverted)
                                return false;
                        compute_precache_lut(output, inverted, inverted_size);
                        free(inverted);
        } else {
                if (trc->count == 0) {
                        compute_precache_linear(output);
                } else if (trc->count == 1) {
                        compute_precache_pow(output, 1./u8Fixed8Number_to_float(trc->data[0]));
                } else {
                        uint16_t *inverted;
                        int inverted_size = trc->count;
                        //XXX: the choice of a minimum of 256 here is not backed by any theory, 
                        //     measurement or data, howeve r it is what lcms uses.
                        //     the maximum number we would need is 65535 because that's the 
                        //     accuracy used for computing the pre cache table
                        if (inverted_size < 256)
                                inverted_size = 256;

                        inverted = invert_lut(trc->data, trc->count, inverted_size);
                        if (!inverted)
                                return false;
                        compute_precache_lut(output, inverted, inverted_size);
                        free(inverted);
                }
        }
        return true;
}


static uint16_t *build_linear_table(int length)
{
        int i;
        uint16_t *output = malloc(sizeof(uint16_t)*length);
        if (!output)
                return NULL;

        for (i = 0; i < length; i++) {
                double x = ((double) i * 65535.) / (double) (length - 1);
                uint16_fract_t input = floor(x + .5);
                output[i] = input;
        }
        return output;
}

static uint16_t *build_pow_table(float gamma, int length)
{
        int i;
        uint16_t *output = malloc(sizeof(uint16_t)*length);
        if (!output)
                return NULL;

        for (i = 0; i < length; i++) {
                uint16_fract_t result;
                double x = ((double) i) / (double) (length - 1);
                x = pow(x, gamma);                //XXX turn this conversion into a function
                result = floor(x*65535. + .5);
                output[i] = result;
        }
        return output;
}

void build_output_lut(struct curveType *trc,
                uint16_t **output_gamma_lut, size_t *output_gamma_lut_length)
{
        if (trc->type == PARAMETRIC_CURVE_TYPE) {
                float gamma_table[256];
                uint16_t i;
                uint16_t *output = malloc(sizeof(uint16_t)*256);

                if (!output) {
                        *output_gamma_lut = NULL;
                        return;
                }

                compute_curve_gamma_table_type_parametric(gamma_table, trc->parameter, trc->count);
                *output_gamma_lut_length = 256;
                for(i = 0; i < 256; i++) {
                        output[i] = (uint16_t)(gamma_table[i] * 65535);
                }
                *output_gamma_lut = output;
        } else {
                if (trc->count == 0) {
                        *output_gamma_lut = build_linear_table(4096);
                        *output_gamma_lut_length = 4096;
                } else if (trc->count == 1) {
                        float gamma = 1./u8Fixed8Number_to_float(trc->data[0]);
                        *output_gamma_lut = build_pow_table(gamma, 4096);
                        *output_gamma_lut_length = 4096;
                } else {
                        //XXX: the choice of a minimum of 256 here is not backed by any theory, 
                        //     measurement or data, however it is what lcms uses.
                        *output_gamma_lut_length = trc->count;
                        if (*output_gamma_lut_length < 256)
                                *output_gamma_lut_length = 256;

                        *output_gamma_lut = invert_lut(trc->data, trc->count, *output_gamma_lut_length);
                }
        }

}
