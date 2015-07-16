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

#include <stdlib.h>
#include "qcmsint.h"
#include "matrix.h"

struct vector matrix_eval(struct matrix mat, struct vector v)
{
	struct vector result;
	result.v[0] = mat.m[0][0]*v.v[0] + mat.m[0][1]*v.v[1] + mat.m[0][2]*v.v[2];
	result.v[1] = mat.m[1][0]*v.v[0] + mat.m[1][1]*v.v[1] + mat.m[1][2]*v.v[2];
	result.v[2] = mat.m[2][0]*v.v[0] + mat.m[2][1]*v.v[1] + mat.m[2][2]*v.v[2];
	return result;
}

//XXX: should probably pass by reference and we could
//probably reuse this computation in matrix_invert
float matrix_det(struct matrix mat)
{
	float det;
	det = mat.m[0][0]*mat.m[1][1]*mat.m[2][2] +
		mat.m[0][1]*mat.m[1][2]*mat.m[2][0] +
		mat.m[0][2]*mat.m[1][0]*mat.m[2][1] -
		mat.m[0][0]*mat.m[1][2]*mat.m[2][1] -
		mat.m[0][1]*mat.m[1][0]*mat.m[2][2] -
		mat.m[0][2]*mat.m[1][1]*mat.m[2][0];
	return det;
}

/* from pixman and cairo and Mathematics for Game Programmers */
/* lcms uses gauss-jordan elimination with partial pivoting which is
 * less efficient and not as numerically stable. See Mathematics for
 * Game Programmers. */
struct matrix matrix_invert(struct matrix mat)
{
	struct matrix dest_mat;
	int i,j;
	static int a[3] = { 2, 2, 1 };
	static int b[3] = { 1, 0, 0 };

	/* inv  (A) = 1/det (A) * adj (A) */
	float det = matrix_det(mat);

	if (det == 0) {
		dest_mat.invalid = true;
	} else {
		dest_mat.invalid = false;
	}

	det = 1/det;

	for (j = 0; j < 3; j++) {
		for (i = 0; i < 3; i++) {
			double p;
			int ai = a[i];
			int aj = a[j];
			int bi = b[i];
			int bj = b[j];

			p = mat.m[ai][aj] * mat.m[bi][bj] -
				mat.m[ai][bj] * mat.m[bi][aj];
			if (((i + j) & 1) != 0)
				p = -p;

			dest_mat.m[j][i] = det * p;
		}
	}
	return dest_mat;
}

struct matrix matrix_identity(void)
{
	struct matrix i;
	i.m[0][0] = 1;
	i.m[0][1] = 0;
	i.m[0][2] = 0;
	i.m[1][0] = 0;
	i.m[1][1] = 1;
	i.m[1][2] = 0;
	i.m[2][0] = 0;
	i.m[2][1] = 0;
	i.m[2][2] = 1;
	i.invalid = false;
	return i;
}

struct matrix matrix_invalid(void)
{
	struct matrix inv = matrix_identity();
	inv.invalid = true;
	return inv;
}


/* from pixman */
/* MAT3per... */
struct matrix matrix_multiply(struct matrix a, struct matrix b)
{
	struct matrix result;
	int dx, dy;
	int o;
	for (dy = 0; dy < 3; dy++) {
		for (dx = 0; dx < 3; dx++) {
			double v = 0;
			for (o = 0; o < 3; o++) {
				v += a.m[dy][o] * b.m[o][dx];
			}
			result.m[dy][dx] = v;
		}
	}
	result.invalid = a.invalid || b.invalid;
	return result;
}


