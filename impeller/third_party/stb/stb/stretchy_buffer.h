// stretchy_buffer.h - v1.02 - public domain - nothings.org/stb
// a vector<>-like dynamic array for C
//
// version history:
//      1.02 -  tweaks to syntax for no good reason
//      1.01 -  added a "common uses" documentation section
//      1.0  -  fixed bug in the version I posted prematurely
//      0.9  -  rewrite to try to avoid strict-aliasing optimization
//              issues, but won't compile as C++
//
// Will probably not work correctly with strict-aliasing optimizations.
//
// The idea:
//
//    This implements an approximation to C++ vector<> for C, in that it
//    provides a generic definition for dynamic arrays which you can
//    still access in a typesafe way using arr[i] or *(arr+i). However,
//    it is simply a convenience wrapper around the common idiom of
//    of keeping a set of variables (in a struct or globals) which store
//        - pointer to array
//        - the length of the "in-use" part of the array
//        - the current size of the allocated array
//
//    I find it to be single most useful non-built-in-structure when
//    programming in C (hash tables a close second), but to be clear
//    it lacks many of the capabilities of C++ vector<>: there is no
//    range checking, the object address isn't stable (see next section
//    for details), the set of methods available is small (although
//    the file stb.h has another implementation of stretchy buffers
//    called 'stb_arr' which provides more methods, e.g. for insertion
//    and deletion).
//
// How to use:
//
//    Unlike other stb header file libraries, there is no need to
//    define an _IMPLEMENTATION symbol. Every #include creates as
//    much implementation is needed.
//
//    stretchy_buffer.h does not define any types, so you do not
//    need to #include it to before defining data types that are
//    stretchy buffers, only in files that *manipulate* stretchy
//    buffers.
//
//    If you want a stretchy buffer aka dynamic array containing
//    objects of TYPE, declare such an array as:
//
//       TYPE *myarray = NULL;
//
//    (There is no typesafe way to distinguish between stretchy
//    buffers and regular arrays/pointers; this is necessary to
//    make ordinary array indexing work on these objects.)
//
//    Unlike C++ vector<>, the stretchy_buffer has the same
//    semantics as an object that you manually malloc and realloc.
//    The pointer may relocate every time you add a new object
//    to it, so you:
//
//         1. can't take long-term pointers to elements of the array
//         2. have to return the pointer from functions which might expand it
//            (either as a return value or by passing it back)
//
//    Now you can do the following things with this array:
//
//         sb_free(TYPE *a)           free the array
//         sb_count(TYPE *a)          the number of elements in the array
//         sb_push(TYPE *a, TYPE v)   adds v on the end of the array, a la push_back
//         sb_add(TYPE *a, int n)     adds n uninitialized elements at end of array & returns pointer to first added
//         sb_last(TYPE *a)           returns an lvalue of the last item in the array
//         a[n]                       access the nth (counting from 0) element of the array
//
//     #define STRETCHY_BUFFER_NO_SHORT_NAMES to only export
//     names of the form 'stb_sb_' if you have a name that would
//     otherwise collide.
//
//     Note that these are all macros and many of them evaluate
//     their arguments more than once, so the arguments should
//     be side-effect-free.
//
//     Note that 'TYPE *a' in sb_push and sb_add must be lvalues
//     so that the library can overwrite the existing pointer if
//     the object has to be reallocated.
//
//     In an out-of-memory condition, the code will try to
//     set up a null-pointer or otherwise-invalid-pointer
//     exception to happen later. It's possible optimizing
//     compilers could detect this write-to-null statically
//     and optimize away some of the code, but it should only
//     be along the failure path. Nevertheless, for more security
//     in the face of such compilers, #define STRETCHY_BUFFER_OUT_OF_MEMORY
//     to a statement such as assert(0) or exit(1) or something
//     to force a failure when out-of-memory occurs.
//
// Common use:
//
//    The main application for this is when building a list of
//    things with an unknown quantity, either due to loading from
//    a file or through a process which produces an unpredictable
//    number.
//
//    My most common idiom is something like:
//
//       SomeStruct *arr = NULL;
//       while (something)
//       {
//          SomeStruct new_one;
//          new_one.whatever = whatever;
//          new_one.whatup   = whatup;
//          new_one.foobar   = barfoo;
//          sb_push(arr, new_one);
//       }
//
//    and various closely-related factorings of that. For example,
//    you might have several functions to create/init new SomeStructs,
//    and if you use the above idiom, you might prefer to make them
//    return structs rather than take non-const-pointers-to-structs,
//    so you can do things like:
//
//       SomeStruct *arr = NULL;
//       while (something)
//       {
//          if (case_A) {
//             sb_push(arr, some_func1());
//          } else if (case_B) {
//             sb_push(arr, some_func2());
//          } else {
//             sb_push(arr, some_func3());
//          }
//       }
//
//    Note that the above relies on the fact that sb_push doesn't
//    evaluate its second argument more than once. The macros do
//    evaluate the *array* argument multiple times, and numeric
//    arguments may be evaluated multiple times, but you can rely
//    on the second argument of sb_push being evaluated only once.
//
//    Of course, you don't have to store bare objects in the array;
//    if you need the objects to have stable pointers, store an array
//    of pointers instead:
//
//       SomeStruct **arr = NULL;
//       while (something)
//       {
//          SomeStruct *new_one = malloc(sizeof(*new_one));
//          new_one->whatever = whatever;
//          new_one->whatup   = whatup;
//          new_one->foobar   = barfoo;
//          sb_push(arr, new_one);
//       }
//
// How it works:
//
//    A long-standing tradition in things like malloc implementations
//    is to store extra data before the beginning of the block returned
//    to the user. The stretchy buffer implementation here uses the
//    same trick; the current-count and current-allocation-size are
//    stored before the beginning of the array returned to the user.
//    (This means you can't directly free() the pointer, because the
//    allocated pointer is different from the type-safe pointer provided
//    to the user.)
//
//    The details are trivial and implementation is straightforward;
//    the main trick is in realizing in the first place that it's
//    possible to do this in a generic, type-safe way in C.
//
// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.

#ifndef STB_STRETCHY_BUFFER_H_INCLUDED
#define STB_STRETCHY_BUFFER_H_INCLUDED

#ifndef NO_STRETCHY_BUFFER_SHORT_NAMES
#define sb_free   stb_sb_free
#define sb_push   stb_sb_push
#define sb_count  stb_sb_count
#define sb_add    stb_sb_add
#define sb_last   stb_sb_last
#endif

#define stb_sb_free(a)         ((a) ? free(stb__sbraw(a)),0 : 0)
#define stb_sb_push(a,v)       (stb__sbmaybegrow(a,1), (a)[stb__sbn(a)++] = (v))
#define stb_sb_count(a)        ((a) ? stb__sbn(a) : 0)
#define stb_sb_add(a,n)        (stb__sbmaybegrow(a,n), stb__sbn(a)+=(n), &(a)[stb__sbn(a)-(n)])
#define stb_sb_last(a)         ((a)[stb__sbn(a)-1])

#define stb__sbraw(a) ((int *) (a) - 2)
#define stb__sbm(a)   stb__sbraw(a)[0]
#define stb__sbn(a)   stb__sbraw(a)[1]

#define stb__sbneedgrow(a,n)  ((a)==0 || stb__sbn(a)+(n) >= stb__sbm(a))
#define stb__sbmaybegrow(a,n) (stb__sbneedgrow(a,(n)) ? stb__sbgrow(a,n) : 0)
#define stb__sbgrow(a,n)      ((a) = stb__sbgrowf((a), (n), sizeof(*(a))))

#include <stdlib.h>

static void * stb__sbgrowf(void *arr, int increment, int itemsize)
{
   int dbl_cur = arr ? 2*stb__sbm(arr) : 0;
   int min_needed = stb_sb_count(arr) + increment;
   int m = dbl_cur > min_needed ? dbl_cur : min_needed;
   int *p = (int *) realloc(arr ? stb__sbraw(arr) : 0, itemsize * m + sizeof(int)*2);
   if (p) {
      if (!arr)
         p[1] = 0;
      p[0] = m;
      return p+2;
   } else {
      #ifdef STRETCHY_BUFFER_OUT_OF_MEMORY
      STRETCHY_BUFFER_OUT_OF_MEMORY ;
      #endif
      return (void *) (2*sizeof(int)); // try to force a NULL pointer exception later
   }
}
#endif // STB_STRETCHY_BUFFER_H_INCLUDED
