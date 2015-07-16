cdef extern from "math.h" nogil:
    double M_E
    double M_LOG2E
    double M_LOG10E
    double M_LN2
    double M_LN10
    double M_PI
    double M_PI_2
    double M_PI_4
    double M_1_PI
    double M_2_PI
    double M_2_SQRTPI
    double M_SQRT2
    double M_SQRT1_2

    # C99 constants
    float INFINITY
    float NAN
    double HUGE_VAL
    float HUGE_VALF
    long double HUGE_VALL

    double acos(double x)
    double asin(double x)
    double atan(double x)
    double atan2(double y, double x)
    double cos(double x)
    double sin(double x)
    double tan(double x)

    double cosh(double x)
    double sinh(double x)
    double tanh(double x)
    double acosh(double x)
    double asinh(double x)
    double atanh(double x)

    double hypot(double x, double y)

    double exp(double x)
    double exp2(double x)
    double expm1(double x)
    double log(double x)
    double logb(double x)
    double log2(double x)
    double log10(double x)
    double log1p(double x)
    int ilogb(double x)

    double lgamma(double x)
    double tgamma(double x)

    double frexp(double x, int* exponent)
    double ldexp(double x, int exponent)

    double modf(double x, double* iptr)
    double fmod(double x, double y)
    double remainder(double x, double y)
    double remquo(double x, double y, int *quot)
    double pow(double x, double y)
    double sqrt(double x)
    double cbrt(double x)

    double fabs(double x)
    double ceil(double x)
    double floor(double x)
    double trunc(double x)
    double rint(double x)
    double round(double x)
    double nearbyint(double x)
    double nextafter(double, double)
    double nexttoward(double, long double)

    long long llrint(double)
    long lrint(double)
    long long llround(double)
    long lround(double)

    double copysign(double, double)
    float copysignf(float, float)
    long double copysignl(long double, long double)

    double erf(double)
    float erff(float)
    long double erfl(long double)
    double erfc(double)
    float erfcf(float)
    long double erfcl(long double)

    double fdim(double x, double y)
    double fma(double x, double y)
    double fmax(double x, double y)
    double fmin(double x, double y)
    double scalbln(double x, long n)
    double scalbn(double x, int n)

    double nan(const char*)
    
    bint isfinite(long double)
    bint isnormal(long double)
    bint isnan(long double)
    bint isinf(long double)
