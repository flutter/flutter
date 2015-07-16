/*
These functions provide integer arithmetic with integer checking.  They do not
actually raise an exception when an overflow is detected, but rather set a bit
in the overflow parameter.  (This parameter may be re-used accross several
arithmetic operations, so should be or-ed rather than assigned to.)

The implementation is divided into two parts, the signed and unsigned basecases,
which is where the magic happens, and a generic template matching a specific
type to an implementation based on its (c-compile-time) size and signedness.

When possible, branching is avoided, and preference is given to speed over
accuracy (a low rate of falsely "detected" overflows are acceptable,
undetected overflows are not).


TODO: Hook up checking.
TODO: Conditionally support 128-bit with intmax_t?
*/

/////////////// Common.proto ///////////////

static int __Pyx_check_twos_complement(void) {
    if (-1 != ~0) {
        PyErr_SetString(PyExc_RuntimeError, "Two's complement required for overflow checks.");
        return 1;
    } else if (sizeof(short) == sizeof(int)) {
        PyErr_SetString(PyExc_RuntimeError, "sizeof(short) < sizeof(int) required for overflow checks.");
        return 1;
    } else {
        return 0;
    }
}

#define __PYX_IS_UNSIGNED(type) (((type) -1) > 0)
#define __PYX_SIGN_BIT(type)    (((unsigned type) 1) << (sizeof(type) * 8 - 1))
#define __PYX_HALF_MAX(type)    (((type) 1) << (sizeof(type) * 8 - 2))
#define __PYX_MIN(type)         (__PYX_IS_UNSIGNED(type) ? (type) 0 : 0 - __PYX_HALF_MAX(type) - __PYX_HALF_MAX(type))
#define __PYX_MAX(type)         (~__PYX_MIN(type))

#define __Pyx_add_no_overflow(a, b, overflow) ((a) + (b))
#define __Pyx_add_const_no_overflow(a, b, overflow) ((a) + (b))
#define __Pyx_sub_no_overflow(a, b, overflow) ((a) - (b))
#define __Pyx_sub_const_no_overflow(a, b, overflow) ((a) - (b))
#define __Pyx_mul_no_overflow(a, b, overflow) ((a) * (b))
#define __Pyx_mul_const_no_overflow(a, b, overflow) ((a) * (b))
#define __Pyx_div_no_overflow(a, b, overflow) ((a) / (b))
#define __Pyx_div_const_no_overflow(a, b, overflow) ((a) / (b))

/////////////// Common.init ///////////////

__Pyx_check_twos_complement();

/////////////// BaseCaseUnsigned.proto ///////////////

static CYTHON_INLINE {{UINT}} __Pyx_add_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow);
static CYTHON_INLINE {{UINT}} __Pyx_sub_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow);
static CYTHON_INLINE {{UINT}} __Pyx_mul_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow);
static CYTHON_INLINE {{UINT}} __Pyx_div_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow);

// Use these when b is known at compile time.
#define __Pyx_add_const_{{NAME}}_checking_overflow __Pyx_add_{{NAME}}_checking_overflow
#define __Pyx_sub_const_{{NAME}}_checking_overflow __Pyx_sub_{{NAME}}_checking_overflow
static CYTHON_INLINE {{UINT}} __Pyx_mul_const_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} constant, int *overflow);
#define __Pyx_div_const_{{NAME}}_checking_overflow __Pyx_div_{{NAME}}_checking_overflow

/////////////// BaseCaseUnsigned ///////////////

static CYTHON_INLINE {{UINT}} __Pyx_add_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow) {
    {{UINT}} r = a + b;
    *overflow |= r < a;
    return r;
}

static CYTHON_INLINE {{UINT}} __Pyx_sub_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow) {
    {{UINT}} r = a - b;
    *overflow |= r > a;
    return r;
}

static CYTHON_INLINE {{UINT}} __Pyx_mul_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow) {
    if (sizeof({{UINT}}) < sizeof(unsigned long)) {
        unsigned long big_r = ((unsigned long) a) * ((unsigned long) b);
        {{UINT}} r = ({{UINT}}) big_r;
        *overflow |= big_r != r;
        return r;
    } else if (sizeof({{UINT}}) < sizeof(unsigned long long)) {
        unsigned long long big_r = ((unsigned long long) a) * ((unsigned long long) b);
        {{UINT}} r = ({{UINT}}) big_r;
        *overflow |= big_r != r;
        return r;
    } else {
        {{UINT}} prod = a * b;
        double dprod = ((double) a) * ((double) b);
        // Overflow results in an error of at least 2^sizeof(UINT),
        // whereas rounding represents an error on the order of 2^(sizeof(UINT)-53).
        *overflow |= fabs(dprod - prod) > (__PYX_MAX({{UINT}}) / 2);
        return prod;
    }
}

static CYTHON_INLINE {{UINT}} __Pyx_mul_const_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow) {
    if (b > 1) {
        *overflow |= a > __PYX_MAX({{UINT}}) / b;
    }
    return a * b;
}


static CYTHON_INLINE {{UINT}} __Pyx_div_{{NAME}}_checking_overflow({{UINT}} a, {{UINT}} b, int *overflow) {
    if (b == 0) {
        *overflow |= 1;
        return 0;
    }
    return a / b;
}


/////////////// BaseCaseSigned.proto ///////////////

static CYTHON_INLINE {{INT}} __Pyx_add_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);
static CYTHON_INLINE {{INT}} __Pyx_sub_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);
static CYTHON_INLINE {{INT}} __Pyx_mul_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);
static CYTHON_INLINE {{INT}} __Pyx_div_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);


// Use when b is known at compile time.
static CYTHON_INLINE {{INT}} __Pyx_add_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);
static CYTHON_INLINE {{INT}} __Pyx_sub_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow);
static CYTHON_INLINE {{INT}} __Pyx_mul_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} constant, int *overflow);
#define __Pyx_div_const_{{NAME}}_checking_overflow __Pyx_div_{{NAME}}_checking_overflow

/////////////// BaseCaseSigned ///////////////

static CYTHON_INLINE {{INT}} __Pyx_add_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    if (sizeof({{INT}}) < sizeof(long)) {
        long big_r = ((long) a) + ((long) b);
        {{INT}} r = ({{INT}}) big_r;
        *overflow |= big_r != r;
        return r;
    } else if (sizeof({{INT}}) < sizeof(long long)) {
        long long big_r = ((long long) a) + ((long long) b);
        {{INT}} r = ({{INT}}) big_r;
        *overflow |= big_r != r;
        return r;
    } else {
        // Signed overflow undefined, but unsigned overflow is well defined.
        {{INT}} r = ({{INT}}) ((unsigned {{INT}}) a + (unsigned {{INT}}) b);
        // Overflow happened if the operands have the same sign, but the result
        // has opposite sign.
        // sign(a) == sign(b) != sign(r)
        {{INT}} sign_a = __PYX_SIGN_BIT({{INT}}) & a;
        {{INT}} sign_b = __PYX_SIGN_BIT({{INT}}) & b;
        {{INT}} sign_r = __PYX_SIGN_BIT({{INT}}) & r;
        *overflow |= (sign_a == sign_b) & (sign_a != sign_r);
        return r;
    }
}

static CYTHON_INLINE {{INT}} __Pyx_add_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    if (b > 0) {
        *overflow |= a > __PYX_MAX({{INT}}) - b;
    } else if (b < 0) {
        *overflow |= a < __PYX_MIN({{INT}}) - b;
    }
    return a + b;
}

static CYTHON_INLINE {{INT}} __Pyx_sub_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    *overflow |= b == __PYX_MIN({{INT}});
    return __Pyx_add_{{NAME}}_checking_overflow(a, -b, overflow);
}

static CYTHON_INLINE {{INT}} __Pyx_sub_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    *overflow |= b == __PYX_MIN({{INT}});
    return __Pyx_add_const_{{NAME}}_checking_overflow(a, -b, overflow);
}

static CYTHON_INLINE {{INT}} __Pyx_mul_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    if (sizeof({{INT}}) < sizeof(long)) {
        long big_r = ((long) a) * ((long) b);
        {{INT}} r = ({{INT}}) big_r;
        *overflow |= big_r != r;
        return ({{INT}}) r;
    } else if (sizeof({{INT}}) < sizeof(long long)) {
        long long big_r = ((long long) a) * ((long long) b);
        {{INT}} r = ({{INT}}) big_r;
        *overflow |= big_r != r;
        return ({{INT}}) r;
    } else {
        {{INT}} prod = a * b;
        double dprod = ((double) a) * ((double) b);
        // Overflow results in an error of at least 2^sizeof(INT),
        // whereas rounding represents an error on the order of 2^(sizeof(INT)-53).
        *overflow |= fabs(dprod - prod) > (__PYX_MAX({{INT}}) / 2);
        return prod;
    }
}

static CYTHON_INLINE {{INT}} __Pyx_mul_const_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    if (b > 1) {
        *overflow |= a > __PYX_MAX({{INT}}) / b;
        *overflow |= a < __PYX_MIN({{INT}}) / b;
    } else if (b == -1) {
        *overflow |= a == __PYX_MIN({{INT}});
    } else if (b < -1) {
        *overflow |= a > __PYX_MIN({{INT}}) / b;
        *overflow |= a < __PYX_MAX({{INT}}) / b;
    }
    return a * b;
}

static CYTHON_INLINE {{INT}} __Pyx_div_{{NAME}}_checking_overflow({{INT}} a, {{INT}} b, int *overflow) {
    if (b == 0) {
        *overflow |= 1;
        return 0;
    }
    *overflow |= (a == __PYX_MIN({{INT}})) & (b == -1);
    return a / b;
}


/////////////// SizeCheck.init ///////////////

__Pyx_check_sane_{{NAME}}();

/////////////// SizeCheck.proto ///////////////

static int __Pyx_check_sane_{{NAME}}(void) {
    if (sizeof({{TYPE}}) <= sizeof(int) ||
        sizeof({{TYPE}}) == sizeof(long) ||
        sizeof({{TYPE}}) == sizeof(long long)) {
        return 0;
    } else {
        PyErr_Format(PyExc_RuntimeError, \
            "Bad size for int type %.{{max(60, len(TYPE))}}s: %d", "{{TYPE}}", (int) sizeof({{TYPE}}));
        return 1;
    }
}


/////////////// Binop.proto ///////////////

static CYTHON_INLINE {{TYPE}} __Pyx_{{BINOP}}_{{NAME}}_checking_overflow({{TYPE}} a, {{TYPE}} b, int *overflow);

/////////////// Binop ///////////////

static CYTHON_INLINE {{TYPE}} __Pyx_{{BINOP}}_{{NAME}}_checking_overflow({{TYPE}} a, {{TYPE}} b, int *overflow) {
    if (sizeof({{TYPE}}) < sizeof(int)) {
        return __Pyx_{{BINOP}}_no_overflow(a, b, overflow);
    } else if (__PYX_IS_UNSIGNED({{TYPE}})) {
        if (sizeof({{TYPE}}) == sizeof(unsigned int)) {
            return __Pyx_{{BINOP}}_unsigned_int_checking_overflow(a, b, overflow);
        } else if (sizeof({{TYPE}}) == sizeof(unsigned long)) {
            return __Pyx_{{BINOP}}_unsigned_long_checking_overflow(a, b, overflow);
        } else if (sizeof({{TYPE}}) == sizeof(unsigned long long)) {
            return __Pyx_{{BINOP}}_unsigned_long_long_checking_overflow(a, b, overflow);
        } else {
            abort(); return 0; // handled elsewhere
        }
    } else {
        if (sizeof({{TYPE}}) == sizeof(int)) {
            return __Pyx_{{BINOP}}_int_checking_overflow(a, b, overflow);
        } else if (sizeof({{TYPE}}) == sizeof(long)) {
            return __Pyx_{{BINOP}}_long_checking_overflow(a, b, overflow);
        } else if (sizeof({{TYPE}}) == sizeof(long long)) {
            return __Pyx_{{BINOP}}_long_long_checking_overflow(a, b, overflow);
        } else {
            abort(); return 0; // handled elsewhere
        }
    }
}

/////////////// LeftShift.proto ///////////////

static CYTHON_INLINE {{TYPE}} __Pyx_lshift_{{NAME}}_checking_overflow({{TYPE}} a, {{TYPE}} b, int *overflow) {
    *overflow |=
#if {{SIGNED}}
        (b < 0) |
#endif
        (b > ({{TYPE}}) (8 * sizeof({{TYPE}}))) | (a > (__PYX_MAX({{TYPE}}) >> b));
    return a << b;
}
#define __Pyx_lshift_const_{{NAME}}_checking_overflow __Pyx_lshift_{{NAME}}_checking_overflow

