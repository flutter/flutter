# NumPy math library
#
# This exports the functionality of the NumPy core math library, aka npymath,
# which provides implementations of C99 math functions and macros for system
# with a C89 library (such as MSVC). npymath is available with NumPy >=1.3,
# although some functions will require later versions. The spacing function is
# not in C99, but comes from Fortran.
#
# On the Cython side, the npymath functions are available without the "npy_"
# prefix that they have in C, to make this is a drop-in replacement for
# libc.math. The same is true for the constants, where possible.
#
# See the NumPy documentation for linking instructions.
#
# Complex number support and NumPy 2.0 half-precision functions are currently
# not exported.
#
# Author: Lars Buitinck

cdef extern from "numpy/npy_math.h" nogil:
    # Floating-point classification
    long double NAN "NPY_NAN"
    long double INFINITY "NPY_INFINITY"
    long double PZERO "NPY_PZERO"        # positive zero
    long double NZERO "NPY_NZERO"        # negative zero

    # These four are actually macros and work on any floating-point type.
    bint isfinite "npy_isfinite"(long double)
    bint isinf "npy_isinf"(long double)
    bint isnan "npy_isnan"(long double)
    bint signbit "npy_signbit"(long double)

    # Math constants
    long double E "NPY_E"
    long double LOG2E "NPY_LOG2E"       # ln(e) / ln(2)
    long double LOG10E "NPY_LOG10E"     # ln(e) / ln(10)
    long double LOGE2 "NPY_LOGE2"       # ln(2)
    long double LOGE10 "NPY_LOGE10"     # ln(10)
    long double PI "NPY_PI"
    long double PI_2 "NPY_PI_2"         # pi / 2
    long double PI_4 "NPY_PI_4"         # pi / 4
    long double NPY_1_PI                # 1 / pi; NPY_ because of ident syntax
    long double NPY_2_PI                # 2 / pi
    long double EULER "NPY_EULER"       # Euler constant (gamma, 0.57721)

    # Low-level floating point manipulation (NumPy >=1.4)
    float copysignf "npy_copysignf"(float, float)
    float nextafterf "npy_nextafterf"(float x, float y)
    float spacingf "npy_spacingf"(float x)
    double copysign "npy_copysign"(double, double)
    double nextafter "npy_nextafter"(double x, double y)
    double spacing "npy_spacing"(double x)
    long double copysignl "npy_copysignl"(long double, long double)
    long double nextafterl "npy_nextafterl"(long double x, long double y)
    long double spacingl "npy_spacingl"(long double x)

    # Float C99 functions
    float sinf "npy_sinf"(float x)
    float cosf "npy_cosf"(float x)
    float tanf "npy_tanf"(float x)
    float sinhf "npy_sinhf"(float x)
    float coshf "npy_coshf"(float x)
    float tanhf "npy_tanhf"(float x)
    float fabsf "npy_fabsf"(float x)
    float floorf "npy_floorf"(float x)
    float ceilf "npy_ceilf"(float x)
    float rintf "npy_rintf"(float x)
    float sqrtf "npy_sqrtf"(float x)
    float log10f "npy_log10f"(float x)
    float logf "npy_logf"(float x)
    float expf "npy_expf"(float x)
    float expm1f "npy_expm1f"(float x)
    float asinf "npy_asinf"(float x)
    float acosf "npy_acosf"(float x)
    float atanf "npy_atanf"(float x)
    float asinhf "npy_asinhf"(float x)
    float acoshf "npy_acoshf"(float x)
    float atanhf "npy_atanhf"(float x)
    float log1pf "npy_log1pf"(float x)
    float exp2f "npy_exp2f"(float x)
    float log2f "npy_log2f"(float x)
    float atan2f "npy_atan2f"(float x)
    float hypotf "npy_hypotf"(float x)
    float powf "npy_powf"(float x)
    float fmodf "npy_fmodf"(float x)
    float modff "npy_modff"(float x)

    # Long double C99 functions
    long double sinl "npy_sinl"(long double x)
    long double cosl "npy_cosl"(long double x)
    long double tanl "npy_tanl"(long double x)
    long double sinhl "npy_sinhl"(long double x)
    long double coshl "npy_coshl"(long double x)
    long double tanhl "npy_tanhl"(long double x)
    long double fabsl "npy_fabsl"(long double x)
    long double floorl "npy_floorl"(long double x)
    long double ceill "npy_ceill"(long double x)
    long double rintl "npy_rintl"(long double x)
    long double sqrtl "npy_sqrtl"(long double x)
    long double log10l "npy_log10l"(long double x)
    long double logl "npy_logl"(long double x)
    long double expl "npy_expl"(long double x)
    long double expm1l "npy_expm1l"(long double x)
    long double asinl "npy_asinl"(long double x)
    long double acosl "npy_acosl"(long double x)
    long double atanl "npy_atanl"(long double x)
    long double asinhl "npy_asinhl"(long double x)
    long double acoshl "npy_acoshl"(long double x)
    long double atanhl "npy_atanhl"(long double x)
    long double log1pl "npy_log1pl"(long double x)
    long double exp2l "npy_exp2l"(long double x)
    long double log2l "npy_log2l"(long double x)
    long double atan2l "npy_atan2l"(long double x)
    long double hypotl "npy_hypotl"(long double x)
    long double powl "npy_powl"(long double x)
    long double fmodl "npy_fmodl"(long double x)
    long double modfl "npy_modfl"(long double x)

    # NumPy extensions
    float deg2radf "npy_deg2radf"(float x)
    float rad2degf "npy_rad2degf"(float x)
    float logaddexpf "npy_logaddexpf"(float x)
    float logaddexp2f "npy_logaddexp2f"(float x)

    double deg2rad "npy_deg2rad"(double x)
    double rad2deg "npy_rad2deg"(double x)
    double logaddexp "npy_logaddexp"(double x)
    double logaddexp2 "npy_logaddexp2"(double x)

    long double deg2radl "npy_deg2radl"(long double x)
    long double rad2degl "npy_rad2degl"(long double x)
    long double logaddexpl "npy_logaddexpl"(long double x)
    long double logaddexp2l "npy_logaddexp2l"(long double x)
