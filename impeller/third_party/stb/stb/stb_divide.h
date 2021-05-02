// stb_divide.h - v0.91 - public domain - Sean Barrett, Feb 2010
// Three kinds of divide/modulus of signed integers.
//
// HISTORY
//
//   v0.91  2010-02-27  Fix euclidean division by INT_MIN for non-truncating C
//                      Check result with 64-bit math to catch such cases
//   v0.90  2010-02-24  First public release
//
// USAGE
//
// In *ONE* source file, put:
//
//    #define STB_DIVIDE_IMPLEMENTATION
//    // #define C_INTEGER_DIVISION_TRUNCATES  // see Note 1
//    // #define C_INTEGER_DIVISION_FLOORS     // see Note 2
//    #include "stb_divide.h"
//
// Other source files should just include stb_divide.h
//
// Note 1: On platforms/compilers that you know signed C division
// truncates, you can #define C_INTEGER_DIVISION_TRUNCATES.
//
// Note 2: On platforms/compilers that you know signed C division
// floors (rounds to negative infinity), you can #define
// C_INTEGER_DIVISION_FLOORS.
//
// You can #define STB_DIVIDE_TEST in which case the implementation
// will generate a main() and compiling the result will create a
// program that tests the implementation. Run it with no arguments
// and any output indicates an error; run it with any argument and
// it will also print the test results. Define STB_DIVIDE_TEST_64
// to a 64-bit integer type to avoid overflows in the result-checking
// which give false negatives.
//
// ABOUT
//
// This file provides three different consistent divide/mod pairs
// implemented on top of arbitrary C/C++ division, including correct
// handling of overflow of intermediate calculations:
//
//     trunc:   a/b truncates to 0,           a%b has same sign as a
//     floor:   a/b truncates to -inf,        a%b has same sign as b
//     eucl:    a/b truncates to sign(b)*inf, a%b is non-negative
//
// Not necessarily optimal; I tried to keep it generally efficient,
// but there may be better ways.
//
// Briefly, for those who are not familiar with the problem, we note
// the reason these divides exist and are interesting:
//
//     'trunc' is easy to implement in hardware (strip the signs,
//          compute, reapply the signs), thus is commonly defined
//          by many languages (including C99)
//
//     'floor' is simple to define and better behaved than trunc;
//          for example it divides integers into fixed-size buckets
//          without an extra-wide bucket at 0, and for a fixed
//          divisor N there are only |N| possible moduli.
//
//     'eucl' guarantees fixed-sized buckets *and* a non-negative
//          modulus and defines division to be whatever is needed
//          to achieve that result.
//
// See "The Euclidean definition of the functions div and mod"
// by Raymond Boute (1992), or "Division and Modulus for Computer
// Scientists" by Daan Leijen (2001)
//
// We assume of the built-in C division:
//     (a) modulus is the remainder for the corresponding division
//     (b) a/b truncates if a and b are the same sign
//
// Property (a) requires (a/b)*b + (a%b)==a, and is required by C.
// Property (b) seems to be true of all hardware but is *not* satisfied
// by the euclidean division operator we define, so it's possibly not
// always true. If any such platform turns up, we can add more cases.
// (Possibly only stb_div_trunc currently relies on property (b).)
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.


#ifndef INCLUDE_STB_DIVIDE_H
#define INCLUDE_STB_DIVIDE_H

#ifdef __cplusplus
extern "C" {
#endif

extern int stb_div_trunc(int value_to_be_divided, int value_to_divide_by);
extern int stb_div_floor(int value_to_be_divided, int value_to_divide_by);
extern int stb_div_eucl (int value_to_be_divided, int value_to_divide_by);
extern int stb_mod_trunc(int value_to_be_divided, int value_to_divide_by);
extern int stb_mod_floor(int value_to_be_divided, int value_to_divide_by);
extern int stb_mod_eucl (int value_to_be_divided, int value_to_divide_by);

#ifdef __cplusplus
}
#endif

#ifdef STB_DIVIDE_IMPLEMENTATION

#if defined(__STDC_VERSION) && __STDC_VERSION__ >= 19901
   #ifndef C_INTEGER_DIVISION_TRUNCATES
      #define C_INTEGER_DIVISION_TRUNCATES
   #endif
#endif

#ifndef INT_MIN
#include <limits.h> // if you have no limits.h, #define INT_MIN yourself
#endif

// the following macros are designed to allow testing
// other platforms by simulating them
#ifndef STB_DIVIDE_TEST_FLOOR
   #define stb__div(a,b)  ((a)/(b))
   #define stb__mod(a,b)  ((a)%(b))
#else
   // implement floor-style divide on trunc platform
   #ifndef C_INTEGER_DIVISION_TRUNCATES
   #error "floor test requires truncating division"
   #endif
   #undef C_INTEGER_DIVISION_TRUNCATES
   int stb__div(int v1, int v2)
   {
      int q = v1/v2, r = v1%v2;
      if ((r > 0 && v2 < 0) || (r < 0 && v2 > 0))
         return q-1;
      else
         return q;
   }

   int stb__mod(int v1, int v2)
   {
      int r = v1%v2;
      if ((r > 0 && v2 < 0) || (r < 0 && v2 > 0))
         return r+v2;
      else
         return r;
   }
#endif

int stb_div_trunc(int v1, int v2)
{
   #ifdef C_INTEGER_DIVISION_TRUNCATES
   return v1/v2;
   #else
   if (v1 >= 0 && v2 <= 0)
      return -stb__div(-v1,v2);  // both negative to avoid overflow
   if (v1 <= 0 && v2 >= 0)
      if (v1 != INT_MIN)
         return -stb__div(v1,-v2);    // both negative to avoid overflow
      else
         return -stb__div(v1+v2,-v2)-1; // push v1 away from wrap point
   else
      return v1/v2;            // same sign, so expect truncation
   #endif
}

int stb_div_floor(int v1, int v2)
{
   #ifdef C_INTEGER_DIVISION_FLOORS
   return v1/v2;
   #else
   if (v1 >= 0 && v2 < 0)
      if ((-v1)+v2+1 < 0) // check if increasing v1's magnitude overflows
         return -stb__div(-v1+v2+1,v2); // nope, so just compute it
      else
         return -stb__div(-v1,v2) + ((-v1)%v2 ? -1 : 0);
   if (v1 < 0 && v2 >= 0)
      if (v1 != INT_MIN)
         if (v1-v2+1 < 0) // check if increasing v1's magnitude overflows
            return -stb__div(v1-v2+1,-v2); // nope, so just compute it
         else
            return -stb__div(-v1,v2) + (stb__mod(v1,-v2) ? -1 : 0);
      else // it must be possible to compute -(v1+v2) without overflowing
         return -stb__div(-(v1+v2),v2) + (stb__mod(-(v1+v2),v2) ? -2 : -1);
   else
      return v1/v2;           // same sign, so expect truncation
   #endif
}

int stb_div_eucl(int v1, int v2)
{
   int q,r;
   #ifdef C_INTEGER_DIVISION_TRUNCATES
   q = v1/v2;
   r = v1%v2;
   #else
   // handle every quadrant separately, since we can't rely on q and r flor
   if (v1 >= 0)
      if (v2 >= 0)
         return stb__div(v1,v2);
      else if (v2 != INT_MIN)
         q = -stb__div(v1,-v2), r = stb__mod(v1,-v2);
      else
         q = 0, r = v1;
   else if (v1 != INT_MIN)
      if (v2 >= 0)
         q = -stb__div(-v1,v2), r = -stb__mod(-v1,v2);
      else if (v2 != INT_MIN)
         q = stb__div(-v1,-v2), r = -stb__mod(-v1,-v2);
      else // if v2 is INT_MIN, then we can't use -v2, but we can't divide by v2
         q = 1, r = v1-q*v2;
   else // if v1 is INT_MIN, we have to move away from overflow place
      if (v2 >= 0)
         q = -stb__div(-(v1+v2),v2)-1, r = -stb__mod(-(v1+v2),v2);
      else
         q = stb__div(-(v1-v2),-v2)+1, r = -stb__mod(-(v1-v2),-v2);
   #endif
   if (r >= 0)
      return q;
   else
      return q + (v2 > 0 ? -1 : 1);
}

int stb_mod_trunc(int v1, int v2)
{
   #ifdef C_INTEGER_DIVISION_TRUNCATES
   return v1%v2;
   #else
   if (v1 >= 0) { // modulus result should always be positive
      int r = stb__mod(v1,v2);
      if (r >= 0)
         return r;
      else
         return r + (v2 > 0 ? v2 : -v2);
   } else {    // modulus result should always be negative
      int r = stb__mod(v1,v2);
      if (r <= 0)
         return r;
      else
         return r - (v2 > 0 ? v2 : -v2);
   }
   #endif
}

int stb_mod_floor(int v1, int v2)
{
   #ifdef C_INTEGER_DIVISION_FLOORS
   return v1%v2;
   #else
   if (v2 >= 0) { // result should always be positive
      int r = stb__mod(v1,v2);
      if (r >= 0)
         return r;
      else
         return r + v2;
   } else { // result should always be negative
      int r = stb__mod(v1,v2);
      if (r <= 0)
         return r;
      else
         return r + v2;
   }
   #endif
}

int stb_mod_eucl(int v1, int v2)
{
   int r = stb__mod(v1,v2);

   if (r >= 0)
      return r;
   else
      return r + (v2 > 0 ? v2 : -v2); // abs()
}

#ifdef STB_DIVIDE_TEST
#include <stdio.h>
#include <math.h>
#include <limits.h>

int show=0;

void stbdiv_check(int q, int r, int a, int b, char *type, int dir)
{
   if ((dir > 0 && r < 0) || (dir < 0 && r > 0))
      fprintf(stderr, "FAILED: %s(%d,%d) remainder %d in wrong direction\n", type,a,b,r);
   else
      if (b != INT_MIN) // can't compute abs(), but if b==INT_MIN all remainders are valid
         if (r <= -abs(b) || r >= abs(b))
            fprintf(stderr, "FAILED: %s(%d,%d) remainder %d out of range\n", type,a,b,r);
   #ifdef STB_DIVIDE_TEST_64
   {
      STB_DIVIDE_TEST_64 q64 = q, r64=r, a64=a, b64=b;
      if (q64*b64+r64 != a64)
         fprintf(stderr, "FAILED: %s(%d,%d) remainder %d doesn't match quotient %d\n", type,a,b,r,q);
   }
   #else
   if (q*b+r != a)
      fprintf(stderr, "FAILED: %s(%d,%d) remainder %d doesn't match quotient %d\n", type,a,b,r,q);
   #endif
}

void test(int a, int b)
{
   int q,r;
   if (show) printf("(%+11d,%+d) |  ", a,b);
   q = stb_div_trunc(a,b), r = stb_mod_trunc(a,b);
   if (show) printf("(%+11d,%+2d)  ", q,r); stbdiv_check(q,r,a,b, "trunc",a);
   q = stb_div_floor(a,b), r = stb_mod_floor(a,b); 
   if (show) printf("(%+11d,%+2d)  ", q,r); stbdiv_check(q,r,a,b, "floor",b);
   q = stb_div_eucl (a,b), r = stb_mod_eucl (a,b);
   if (show) printf("(%+11d,%+2d)\n", q,r); stbdiv_check(q,r,a,b, "euclidean",1);
}

void testh(int a, int b)
{
   int q,r;
   if (show) printf("(%08x,%08x) |\n", a,b);
   q = stb_div_trunc(a,b), r = stb_mod_trunc(a,b); stbdiv_check(q,r,a,b, "trunc",a);
   if (show) printf("             (%08x,%08x)", q,r);
   q = stb_div_floor(a,b), r = stb_mod_floor(a,b); stbdiv_check(q,r,a,b, "floor",b);
   if (show) printf("   (%08x,%08x)", q,r);
   q = stb_div_eucl (a,b), r = stb_mod_eucl (a,b); stbdiv_check(q,r,a,b, "euclidean",1);
   if (show) printf("   (%08x,%08x)\n ", q,r);
}

int main(int argc, char **argv)
{
   if (argc > 1) show=1;

   test(8,3);
   test(8,-3);
   test(-8,3);
   test(-8,-3);
   test(1,2);
   test(1,-2);
   test(-1,2);
   test(-1,-2);
   test(8,4);
   test(8,-4);
   test(-8,4);
   test(-8,-4);

   test(INT_MAX,1);
   test(INT_MIN,1);
   test(INT_MIN+1,1);
   test(INT_MAX,-1);
   //test(INT_MIN,-1); // this traps in MSVC, so we leave it untested
   test(INT_MIN+1,-1);
   test(INT_MIN,-2);
   test(INT_MIN+1,2);
   test(INT_MIN+1,-2);
   test(INT_MAX,2);
   test(INT_MAX,-2);
   test(INT_MIN+1,2);
   test(INT_MIN+1,-2);
   test(INT_MIN,2);
   test(INT_MIN,-2);
   test(INT_MIN,7);
   test(INT_MIN,-7);
   test(INT_MIN+1,4);
   test(INT_MIN+1,-4);

   testh(-7, INT_MIN);
   testh(-1, INT_MIN);
   testh(1, INT_MIN);
   testh(7, INT_MIN);

   testh(INT_MAX-1, INT_MIN);
   testh(INT_MAX,   INT_MIN);
   testh(INT_MIN,   INT_MIN);
   testh(INT_MIN+1, INT_MIN);

   testh(INT_MAX-1, INT_MAX);
   testh(INT_MAX  , INT_MAX);
   testh(INT_MIN  , INT_MAX);
   testh(INT_MIN+1, INT_MAX);

   return 0;
}
#endif // STB_DIVIDE_TEST
#endif // STB_DIVIDE_IMPLEMENTATION
#endif // INCLUDE_STB_DIVIDE_H
