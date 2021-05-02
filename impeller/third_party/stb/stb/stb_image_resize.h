/* stb_image_resize - v0.91 - public domain image resizing
   by Jorge L Rodriguez (@VinoBS) - 2014
   http://github.com/nothings/stb

   Written with emphasis on usability, portability, and efficiency. (No
   SIMD or threads, so it be easily outperformed by libs that use those.)
   Only scaling and translation is supported, no rotations or shears.
   Easy API downsamples w/Mitchell filter, upsamples w/cubic interpolation.

   COMPILING & LINKING
      In one C/C++ file that #includes this file, do this:
         #define STB_IMAGE_RESIZE_IMPLEMENTATION
      before the #include. That will create the implementation in that file.

   QUICKSTART
      stbir_resize_uint8(      input_pixels , in_w , in_h , 0,
                               output_pixels, out_w, out_h, 0, num_channels)
      stbir_resize_float(...)
      stbir_resize_uint8_srgb( input_pixels , in_w , in_h , 0,
                               output_pixels, out_w, out_h, 0,
                               num_channels , alpha_chan  , 0)
      stbir_resize_uint8_srgb_edgemode(
                               input_pixels , in_w , in_h , 0, 
                               output_pixels, out_w, out_h, 0, 
                               num_channels , alpha_chan  , 0, STBIR_EDGE_CLAMP)
                                                            // WRAP/REFLECT/ZERO

   FULL API
      See the "header file" section of the source for API documentation.

   ADDITIONAL DOCUMENTATION

      SRGB & FLOATING POINT REPRESENTATION
         The sRGB functions presume IEEE floating point. If you do not have
         IEEE floating point, define STBIR_NON_IEEE_FLOAT. This will use
         a slower implementation.

      MEMORY ALLOCATION
         The resize functions here perform a single memory allocation using
         malloc. To control the memory allocation, before the #include that
         triggers the implementation, do:

            #define STBIR_MALLOC(size,context) ...
            #define STBIR_FREE(ptr,context)   ...

         Each resize function makes exactly one call to malloc/free, so to use
         temp memory, store the temp memory in the context and return that.

      ASSERT
         Define STBIR_ASSERT(boolval) to override assert() and not use assert.h

      OPTIMIZATION
         Define STBIR_SATURATE_INT to compute clamp values in-range using
         integer operations instead of float operations. This may be faster
         on some platforms.

      DEFAULT FILTERS
         For functions which don't provide explicit control over what filters
         to use, you can change the compile-time defaults with

            #define STBIR_DEFAULT_FILTER_UPSAMPLE     STBIR_FILTER_something
            #define STBIR_DEFAULT_FILTER_DOWNSAMPLE   STBIR_FILTER_something

         See stbir_filter in the header-file section for the list of filters.

      NEW FILTERS
         A number of 1D filter kernels are used. For a list of
         supported filters see the stbir_filter enum. To add a new filter,
         write a filter function and add it to stbir__filter_info_table.

      PROGRESS
         For interactive use with slow resize operations, you can install
         a progress-report callback:

            #define STBIR_PROGRESS_REPORT(val)   some_func(val)

         The parameter val is a float which goes from 0 to 1 as progress is made.

         For example:

            static void my_progress_report(float progress);
            #define STBIR_PROGRESS_REPORT(val) my_progress_report(val)

            #define STB_IMAGE_RESIZE_IMPLEMENTATION
            #include "stb_image_resize.h"

            static void my_progress_report(float progress)
            {
               printf("Progress: %f%%\n", progress*100);
            }

      MAX CHANNELS
         If your image has more than 64 channels, define STBIR_MAX_CHANNELS
         to the max you'll have.

      ALPHA CHANNEL
         Most of the resizing functions provide the ability to control how
         the alpha channel of an image is processed. The important things
         to know about this:

         1. The best mathematically-behaved version of alpha to use is
         called "premultiplied alpha", in which the other color channels
         have had the alpha value multiplied in. If you use premultiplied
         alpha, linear filtering (such as image resampling done by this
         library, or performed in texture units on GPUs) does the "right
         thing". While premultiplied alpha is standard in the movie CGI
         industry, it is still uncommon in the videogame/real-time world.

         If you linearly filter non-premultiplied alpha, strange effects
         occur. (For example, the average of 1% opaque bright green
         and 99% opaque black produces 50% transparent dark green when
         non-premultiplied, whereas premultiplied it produces 50%
         transparent near-black. The former introduces green energy
         that doesn't exist in the source image.)

         2. Artists should not edit premultiplied-alpha images; artists
         want non-premultiplied alpha images. Thus, art tools generally output
         non-premultiplied alpha images.

         3. You will get best results in most cases by converting images
         to premultiplied alpha before processing them mathematically.

         4. If you pass the flag STBIR_FLAG_ALPHA_PREMULTIPLIED, the
         resizer does not do anything special for the alpha channel;
         it is resampled identically to other channels. This produces
         the correct results for premultiplied-alpha images, but produces
         less-than-ideal results for non-premultiplied-alpha images.

         5. If you do not pass the flag STBIR_FLAG_ALPHA_PREMULTIPLIED,
         then the resizer weights the contribution of input pixels
         based on their alpha values, or, equivalently, it multiplies
         the alpha value into the color channels, resamples, then divides
         by the resultant alpha value. Input pixels which have alpha=0 do
         not contribute at all to output pixels unless _all_ of the input
         pixels affecting that output pixel have alpha=0, in which case
         the result for that pixel is the same as it would be without
         STBIR_FLAG_ALPHA_PREMULTIPLIED. However, this is only true for
         input images in integer formats. For input images in float format,
         input pixels with alpha=0 have no effect, and output pixels
         which have alpha=0 will be 0 in all channels. (For float images,
         you can manually achieve the same result by adding a tiny epsilon
         value to the alpha channel of every image, and then subtracting
         or clamping it at the end.)

         6. You can suppress the behavior described in #5 and make
         all-0-alpha pixels have 0 in all channels by #defining
         STBIR_NO_ALPHA_EPSILON.

         7. You can separately control whether the alpha channel is
         interpreted as linear or affected by the colorspace. By default
         it is linear; you almost never want to apply the colorspace.
         (For example, graphics hardware does not apply sRGB conversion
         to the alpha channel.)

   ADDITIONAL CONTRIBUTORS
      Sean Barrett: API design, optimizations
         
   REVISIONS
      0.91 (2016-04-02) fix warnings; fix handling of subpixel regions
      0.90 (2014-09-17) first released version

   LICENSE

     This software is dual-licensed to the public domain and under the following
     license: you are granted a perpetual, irrevocable license to copy, modify,
     publish, and distribute this file as you see fit.

   TODO
      Don't decode all of the image data when only processing a partial tile
      Don't use full-width decode buffers when only processing a partial tile
      When processing wide images, break processing into tiles so data fits in L1 cache
      Installable filters?
      Resize that respects alpha test coverage
         (Reference code: FloatImage::alphaTestCoverage and FloatImage::scaleAlphaToCoverage:
         https://code.google.com/p/nvidia-texture-tools/source/browse/trunk/src/nvimage/FloatImage.cpp )
*/

#ifndef STBIR_INCLUDE_STB_IMAGE_RESIZE_H
#define STBIR_INCLUDE_STB_IMAGE_RESIZE_H

#ifdef _MSC_VER
typedef unsigned char  stbir_uint8;
typedef unsigned short stbir_uint16;
typedef unsigned int   stbir_uint32;
#else
#include <stdint.h>
typedef uint8_t  stbir_uint8;
typedef uint16_t stbir_uint16;
typedef uint32_t stbir_uint32;
#endif

#ifdef STB_IMAGE_RESIZE_STATIC
#define STBIRDEF static
#else
#ifdef __cplusplus
#define STBIRDEF extern "C"
#else
#define STBIRDEF extern
#endif
#endif


//////////////////////////////////////////////////////////////////////////////
//
// Easy-to-use API:
//
//     * "input pixels" points to an array of image data with 'num_channels' channels (e.g. RGB=3, RGBA=4)
//     * input_w is input image width (x-axis), input_h is input image height (y-axis)
//     * stride is the offset between successive rows of image data in memory, in bytes. you can
//       specify 0 to mean packed continuously in memory
//     * alpha channel is treated identically to other channels.
//     * colorspace is linear or sRGB as specified by function name
//     * returned result is 1 for success or 0 in case of an error.
//       #define STBIR_ASSERT() to trigger an assert on parameter validation errors.
//     * Memory required grows approximately linearly with input and output size, but with
//       discontinuities at input_w == output_w and input_h == output_h.
//     * These functions use a "default" resampling filter defined at compile time. To change the filter,
//       you can change the compile-time defaults by #defining STBIR_DEFAULT_FILTER_UPSAMPLE
//       and STBIR_DEFAULT_FILTER_DOWNSAMPLE, or you can use the medium-complexity API.

STBIRDEF int stbir_resize_uint8(     const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels);

STBIRDEF int stbir_resize_float(     const float *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           float *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels);


// The following functions interpret image data as gamma-corrected sRGB. 
// Specify STBIR_ALPHA_CHANNEL_NONE if you have no alpha channel,
// or otherwise provide the index of the alpha channel. Flags value
// of 0 will probably do the right thing if you're not sure what
// the flags mean.

#define STBIR_ALPHA_CHANNEL_NONE       -1

// Set this flag if your texture has premultiplied alpha. Otherwise, stbir will
// use alpha-weighted resampling (effectively premultiplying, resampling,
// then unpremultiplying).
#define STBIR_FLAG_ALPHA_PREMULTIPLIED    (1 << 0)
// The specified alpha channel should be handled as gamma-corrected value even
// when doing sRGB operations.
#define STBIR_FLAG_ALPHA_USES_COLORSPACE  (1 << 1)

STBIRDEF int stbir_resize_uint8_srgb(const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels, int alpha_channel, int flags);


typedef enum
{
    STBIR_EDGE_CLAMP   = 1,
    STBIR_EDGE_REFLECT = 2,
    STBIR_EDGE_WRAP    = 3,
    STBIR_EDGE_ZERO    = 4,
} stbir_edge;

// This function adds the ability to specify how requests to sample off the edge of the image are handled.
STBIRDEF int stbir_resize_uint8_srgb_edgemode(const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                                    unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                              int num_channels, int alpha_channel, int flags,
                                              stbir_edge edge_wrap_mode);

//////////////////////////////////////////////////////////////////////////////
//
// Medium-complexity API
//
// This extends the easy-to-use API as follows:
//
//     * Alpha-channel can be processed separately
//       * If alpha_channel is not STBIR_ALPHA_CHANNEL_NONE
//         * Alpha channel will not be gamma corrected (unless flags&STBIR_FLAG_GAMMA_CORRECT)
//         * Filters will be weighted by alpha channel (unless flags&STBIR_FLAG_ALPHA_PREMULTIPLIED)
//     * Filter can be selected explicitly
//     * uint16 image type
//     * sRGB colorspace available for all types
//     * context parameter for passing to STBIR_MALLOC

typedef enum
{
    STBIR_FILTER_DEFAULT      = 0,  // use same filter type that easy-to-use API chooses
    STBIR_FILTER_BOX          = 1,  // A trapezoid w/1-pixel wide ramps, same result as box for integer scale ratios
    STBIR_FILTER_TRIANGLE     = 2,  // On upsampling, produces same results as bilinear texture filtering
    STBIR_FILTER_CUBICBSPLINE = 3,  // The cubic b-spline (aka Mitchell-Netrevalli with B=1,C=0), gaussian-esque
    STBIR_FILTER_CATMULLROM   = 4,  // An interpolating cubic spline
    STBIR_FILTER_MITCHELL     = 5,  // Mitchell-Netrevalli filter with B=1/3, C=1/3
} stbir_filter;

typedef enum
{
    STBIR_COLORSPACE_LINEAR,
    STBIR_COLORSPACE_SRGB,

    STBIR_MAX_COLORSPACES,
} stbir_colorspace;

// The following functions are all identical except for the type of the image data

STBIRDEF int stbir_resize_uint8_generic( const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                               unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context);

STBIRDEF int stbir_resize_uint16_generic(const stbir_uint16 *input_pixels  , int input_w , int input_h , int input_stride_in_bytes,
                                               stbir_uint16 *output_pixels , int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context);

STBIRDEF int stbir_resize_float_generic( const float *input_pixels         , int input_w , int input_h , int input_stride_in_bytes,
                                               float *output_pixels        , int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context);



//////////////////////////////////////////////////////////////////////////////
//
// Full-complexity API
//
// This extends the medium API as follows:
//
//       * uint32 image type
//     * not typesafe
//     * separate filter types for each axis
//     * separate edge modes for each axis
//     * can specify scale explicitly for subpixel correctness
//     * can specify image source tile using texture coordinates

typedef enum
{
    STBIR_TYPE_UINT8 ,
    STBIR_TYPE_UINT16,
    STBIR_TYPE_UINT32,
    STBIR_TYPE_FLOAT ,

    STBIR_MAX_TYPES
} stbir_datatype;

STBIRDEF int stbir_resize(         const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context);

STBIRDEF int stbir_resize_subpixel(const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context,
                                   float x_scale, float y_scale,
                                   float x_offset, float y_offset);

STBIRDEF int stbir_resize_region(  const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context,
                                   float s0, float t0, float s1, float t1);
// (s0, t0) & (s1, t1) are the top-left and bottom right corner (uv addressing style: [0, 1]x[0, 1]) of a region of the input image to use.

//
//
////   end header file   /////////////////////////////////////////////////////
#endif // STBIR_INCLUDE_STB_IMAGE_RESIZE_H





#ifdef STB_IMAGE_RESIZE_IMPLEMENTATION

#ifndef STBIR_ASSERT
#include <assert.h>
#define STBIR_ASSERT(x) assert(x)
#endif

// For memset
#include <string.h>

#include <math.h>

#ifndef STBIR_MALLOC
#include <stdlib.h>
#define STBIR_MALLOC(size,c) malloc(size)
#define STBIR_FREE(ptr,c)    free(ptr)
#endif

#ifndef _MSC_VER
#ifdef __cplusplus
#define stbir__inline inline
#else
#define stbir__inline
#endif
#else
#define stbir__inline __forceinline
#endif


// should produce compiler error if size is wrong
typedef unsigned char stbir__validate_uint32[sizeof(stbir_uint32) == 4 ? 1 : -1];

#ifdef _MSC_VER
#define STBIR__NOTUSED(v)  (void)(v)
#else
#define STBIR__NOTUSED(v)  (void)sizeof(v)
#endif

#define STBIR__ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))

#ifndef STBIR_DEFAULT_FILTER_UPSAMPLE
#define STBIR_DEFAULT_FILTER_UPSAMPLE    STBIR_FILTER_CATMULLROM
#endif

#ifndef STBIR_DEFAULT_FILTER_DOWNSAMPLE
#define STBIR_DEFAULT_FILTER_DOWNSAMPLE  STBIR_FILTER_MITCHELL
#endif

#ifndef STBIR_PROGRESS_REPORT
#define STBIR_PROGRESS_REPORT(float_0_to_1)
#endif

#ifndef STBIR_MAX_CHANNELS
#define STBIR_MAX_CHANNELS 64
#endif

#if STBIR_MAX_CHANNELS > 65536
#error "Too many channels; STBIR_MAX_CHANNELS must be no more than 65536."
// because we store the indices in 16-bit variables
#endif

// This value is added to alpha just before premultiplication to avoid
// zeroing out color values. It is equivalent to 2^-80. If you don't want
// that behavior (it may interfere if you have floating point images with
// very small alpha values) then you can define STBIR_NO_ALPHA_EPSILON to
// disable it.
#ifndef STBIR_ALPHA_EPSILON
#define STBIR_ALPHA_EPSILON ((float)1 / (1 << 20) / (1 << 20) / (1 << 20) / (1 << 20))
#endif



#ifdef _MSC_VER
#define STBIR__UNUSED_PARAM(v)  (void)(v)
#else
#define STBIR__UNUSED_PARAM(v)  (void)sizeof(v)
#endif

// must match stbir_datatype
static unsigned char stbir__type_size[] = {
    1, // STBIR_TYPE_UINT8
    2, // STBIR_TYPE_UINT16
    4, // STBIR_TYPE_UINT32
    4, // STBIR_TYPE_FLOAT
};

// Kernel function centered at 0
typedef float (stbir__kernel_fn)(float x, float scale);
typedef float (stbir__support_fn)(float scale);

typedef struct
{
    stbir__kernel_fn* kernel;
    stbir__support_fn* support;
} stbir__filter_info;

// When upsampling, the contributors are which source pixels contribute.
// When downsampling, the contributors are which destination pixels are contributed to.
typedef struct
{
    int n0; // First contributing pixel
    int n1; // Last contributing pixel
} stbir__contributors;

typedef struct
{
    const void* input_data;
    int input_w;
    int input_h;
    int input_stride_bytes;

    void* output_data;
    int output_w;
    int output_h;
    int output_stride_bytes;

    float s0, t0, s1, t1;

    float horizontal_shift; // Units: output pixels
    float vertical_shift;   // Units: output pixels
    float horizontal_scale;
    float vertical_scale;

    int channels;
    int alpha_channel;
    stbir_uint32 flags;
    stbir_datatype type;
    stbir_filter horizontal_filter;
    stbir_filter vertical_filter;
    stbir_edge edge_horizontal;
    stbir_edge edge_vertical;
    stbir_colorspace colorspace;

    stbir__contributors* horizontal_contributors;
    float* horizontal_coefficients;

    stbir__contributors* vertical_contributors;
    float* vertical_coefficients;

    int decode_buffer_pixels;
    float* decode_buffer;

    float* horizontal_buffer;

    // cache these because ceil/floor are inexplicably showing up in profile
    int horizontal_coefficient_width;
    int vertical_coefficient_width;
    int horizontal_filter_pixel_width;
    int vertical_filter_pixel_width;
    int horizontal_filter_pixel_margin;
    int vertical_filter_pixel_margin;
    int horizontal_num_contributors;
    int vertical_num_contributors;

    int ring_buffer_length_bytes; // The length of an individual entry in the ring buffer. The total number of ring buffers is stbir__get_filter_pixel_width(filter)
    int ring_buffer_first_scanline;
    int ring_buffer_last_scanline;
    int ring_buffer_begin_index;
    float* ring_buffer;

    float* encode_buffer; // A temporary buffer to store floats so we don't lose precision while we do multiply-adds.

    int horizontal_contributors_size;
    int horizontal_coefficients_size;
    int vertical_contributors_size;
    int vertical_coefficients_size;
    int decode_buffer_size;
    int horizontal_buffer_size;
    int ring_buffer_size;
    int encode_buffer_size;
} stbir__info;

static stbir__inline int stbir__min(int a, int b)
{
    return a < b ? a : b;
}

static stbir__inline int stbir__max(int a, int b)
{
    return a > b ? a : b;
}

static stbir__inline float stbir__saturate(float x)
{
    if (x < 0)
        return 0;

    if (x > 1)
        return 1;

    return x;
}

#ifdef STBIR_SATURATE_INT
static stbir__inline stbir_uint8 stbir__saturate8(int x)
{
    if ((unsigned int) x <= 255)
        return x;

    if (x < 0)
        return 0;

    return 255;
}

static stbir__inline stbir_uint16 stbir__saturate16(int x)
{
    if ((unsigned int) x <= 65535)
        return x;

    if (x < 0)
        return 0;

    return 65535;
}
#endif

static float stbir__srgb_uchar_to_linear_float[256] = {
    0.000000f, 0.000304f, 0.000607f, 0.000911f, 0.001214f, 0.001518f, 0.001821f, 0.002125f, 0.002428f, 0.002732f, 0.003035f,
    0.003347f, 0.003677f, 0.004025f, 0.004391f, 0.004777f, 0.005182f, 0.005605f, 0.006049f, 0.006512f, 0.006995f, 0.007499f,
    0.008023f, 0.008568f, 0.009134f, 0.009721f, 0.010330f, 0.010960f, 0.011612f, 0.012286f, 0.012983f, 0.013702f, 0.014444f,
    0.015209f, 0.015996f, 0.016807f, 0.017642f, 0.018500f, 0.019382f, 0.020289f, 0.021219f, 0.022174f, 0.023153f, 0.024158f,
    0.025187f, 0.026241f, 0.027321f, 0.028426f, 0.029557f, 0.030713f, 0.031896f, 0.033105f, 0.034340f, 0.035601f, 0.036889f,
    0.038204f, 0.039546f, 0.040915f, 0.042311f, 0.043735f, 0.045186f, 0.046665f, 0.048172f, 0.049707f, 0.051269f, 0.052861f,
    0.054480f, 0.056128f, 0.057805f, 0.059511f, 0.061246f, 0.063010f, 0.064803f, 0.066626f, 0.068478f, 0.070360f, 0.072272f,
    0.074214f, 0.076185f, 0.078187f, 0.080220f, 0.082283f, 0.084376f, 0.086500f, 0.088656f, 0.090842f, 0.093059f, 0.095307f,
    0.097587f, 0.099899f, 0.102242f, 0.104616f, 0.107023f, 0.109462f, 0.111932f, 0.114435f, 0.116971f, 0.119538f, 0.122139f,
    0.124772f, 0.127438f, 0.130136f, 0.132868f, 0.135633f, 0.138432f, 0.141263f, 0.144128f, 0.147027f, 0.149960f, 0.152926f,
    0.155926f, 0.158961f, 0.162029f, 0.165132f, 0.168269f, 0.171441f, 0.174647f, 0.177888f, 0.181164f, 0.184475f, 0.187821f,
    0.191202f, 0.194618f, 0.198069f, 0.201556f, 0.205079f, 0.208637f, 0.212231f, 0.215861f, 0.219526f, 0.223228f, 0.226966f,
    0.230740f, 0.234551f, 0.238398f, 0.242281f, 0.246201f, 0.250158f, 0.254152f, 0.258183f, 0.262251f, 0.266356f, 0.270498f,
    0.274677f, 0.278894f, 0.283149f, 0.287441f, 0.291771f, 0.296138f, 0.300544f, 0.304987f, 0.309469f, 0.313989f, 0.318547f,
    0.323143f, 0.327778f, 0.332452f, 0.337164f, 0.341914f, 0.346704f, 0.351533f, 0.356400f, 0.361307f, 0.366253f, 0.371238f,
    0.376262f, 0.381326f, 0.386430f, 0.391573f, 0.396755f, 0.401978f, 0.407240f, 0.412543f, 0.417885f, 0.423268f, 0.428691f,
    0.434154f, 0.439657f, 0.445201f, 0.450786f, 0.456411f, 0.462077f, 0.467784f, 0.473532f, 0.479320f, 0.485150f, 0.491021f,
    0.496933f, 0.502887f, 0.508881f, 0.514918f, 0.520996f, 0.527115f, 0.533276f, 0.539480f, 0.545725f, 0.552011f, 0.558340f,
    0.564712f, 0.571125f, 0.577581f, 0.584078f, 0.590619f, 0.597202f, 0.603827f, 0.610496f, 0.617207f, 0.623960f, 0.630757f,
    0.637597f, 0.644480f, 0.651406f, 0.658375f, 0.665387f, 0.672443f, 0.679543f, 0.686685f, 0.693872f, 0.701102f, 0.708376f,
    0.715694f, 0.723055f, 0.730461f, 0.737911f, 0.745404f, 0.752942f, 0.760525f, 0.768151f, 0.775822f, 0.783538f, 0.791298f,
    0.799103f, 0.806952f, 0.814847f, 0.822786f, 0.830770f, 0.838799f, 0.846873f, 0.854993f, 0.863157f, 0.871367f, 0.879622f,
    0.887923f, 0.896269f, 0.904661f, 0.913099f, 0.921582f, 0.930111f, 0.938686f, 0.947307f, 0.955974f, 0.964686f, 0.973445f,
    0.982251f, 0.991102f, 1.0f
};

static float stbir__srgb_to_linear(float f)
{
    if (f <= 0.04045f)
        return f / 12.92f;
    else
        return (float)pow((f + 0.055f) / 1.055f, 2.4f);
}

static float stbir__linear_to_srgb(float f)
{
    if (f <= 0.0031308f)
        return f * 12.92f;
    else
        return 1.055f * (float)pow(f, 1 / 2.4f) - 0.055f;
}

#ifndef STBIR_NON_IEEE_FLOAT
// From https://gist.github.com/rygorous/2203834

typedef union
{
    stbir_uint32 u;
    float f;
} stbir__FP32;

static const stbir_uint32 fp32_to_srgb8_tab4[104] = {
    0x0073000d, 0x007a000d, 0x0080000d, 0x0087000d, 0x008d000d, 0x0094000d, 0x009a000d, 0x00a1000d,
    0x00a7001a, 0x00b4001a, 0x00c1001a, 0x00ce001a, 0x00da001a, 0x00e7001a, 0x00f4001a, 0x0101001a,
    0x010e0033, 0x01280033, 0x01410033, 0x015b0033, 0x01750033, 0x018f0033, 0x01a80033, 0x01c20033,
    0x01dc0067, 0x020f0067, 0x02430067, 0x02760067, 0x02aa0067, 0x02dd0067, 0x03110067, 0x03440067,
    0x037800ce, 0x03df00ce, 0x044600ce, 0x04ad00ce, 0x051400ce, 0x057b00c5, 0x05dd00bc, 0x063b00b5,
    0x06970158, 0x07420142, 0x07e30130, 0x087b0120, 0x090b0112, 0x09940106, 0x0a1700fc, 0x0a9500f2,
    0x0b0f01cb, 0x0bf401ae, 0x0ccb0195, 0x0d950180, 0x0e56016e, 0x0f0d015e, 0x0fbc0150, 0x10630143,
    0x11070264, 0x1238023e, 0x1357021d, 0x14660201, 0x156601e9, 0x165a01d3, 0x174401c0, 0x182401af,
    0x18fe0331, 0x1a9602fe, 0x1c1502d2, 0x1d7e02ad, 0x1ed4028d, 0x201a0270, 0x21520256, 0x227d0240,
    0x239f0443, 0x25c003fe, 0x27bf03c4, 0x29a10392, 0x2b6a0367, 0x2d1d0341, 0x2ebe031f, 0x304d0300,
    0x31d105b0, 0x34a80555, 0x37520507, 0x39d504c5, 0x3c37048b, 0x3e7c0458, 0x40a8042a, 0x42bd0401,
    0x44c20798, 0x488e071e, 0x4c1c06b6, 0x4f76065d, 0x52a50610, 0x55ac05cc, 0x5892058f, 0x5b590559,
    0x5e0c0a23, 0x631c0980, 0x67db08f6, 0x6c55087f, 0x70940818, 0x74a007bd, 0x787d076c, 0x7c330723,
};
 
static stbir_uint8 stbir__linear_to_srgb_uchar(float in)
{
    static const stbir__FP32 almostone = { 0x3f7fffff }; // 1-eps
    static const stbir__FP32 minval = { (127-13) << 23 };
    stbir_uint32 tab,bias,scale,t;
    stbir__FP32 f;
 
    // Clamp to [2^(-13), 1-eps]; these two values map to 0 and 1, respectively.
    // The tests are carefully written so that NaNs map to 0, same as in the reference
    // implementation.
    if (!(in > minval.f)) // written this way to catch NaNs
        in = minval.f;
    if (in > almostone.f)
        in = almostone.f;
 
    // Do the table lookup and unpack bias, scale
    f.f = in;
    tab = fp32_to_srgb8_tab4[(f.u - minval.u) >> 20];
    bias = (tab >> 16) << 9;
    scale = tab & 0xffff;
 
    // Grab next-highest mantissa bits and perform linear interpolation
    t = (f.u >> 12) & 0xff;
    return (unsigned char) ((bias + scale*t) >> 16);
}

#else
// sRGB transition values, scaled by 1<<28
static int stbir__srgb_offset_to_linear_scaled[256] =
{
            0,     40738,    122216,    203693,    285170,    366648,    448125,    529603,
       611080,    692557,    774035,    855852,    942009,   1033024,   1128971,   1229926,
      1335959,   1447142,   1563542,   1685229,   1812268,   1944725,   2082664,   2226148,
      2375238,   2529996,   2690481,   2856753,   3028870,   3206888,   3390865,   3580856,
      3776916,   3979100,   4187460,   4402049,   4622919,   4850123,   5083710,   5323731,
      5570236,   5823273,   6082892,   6349140,   6622065,   6901714,   7188133,   7481369,
      7781466,   8088471,   8402427,   8723380,   9051372,   9386448,   9728650,  10078021,
     10434603,  10798439,  11169569,  11548036,  11933879,  12327139,  12727857,  13136073,
     13551826,  13975156,  14406100,  14844697,  15290987,  15745007,  16206795,  16676389,
     17153826,  17639142,  18132374,  18633560,  19142734,  19659934,  20185196,  20718552,
     21260042,  21809696,  22367554,  22933648,  23508010,  24090680,  24681686,  25281066,
     25888850,  26505076,  27129772,  27762974,  28404716,  29055026,  29713942,  30381490,
     31057708,  31742624,  32436272,  33138682,  33849884,  34569912,  35298800,  36036568,
     36783260,  37538896,  38303512,  39077136,  39859796,  40651528,  41452360,  42262316,
     43081432,  43909732,  44747252,  45594016,  46450052,  47315392,  48190064,  49074096,
     49967516,  50870356,  51782636,  52704392,  53635648,  54576432,  55526772,  56486700,
     57456236,  58435408,  59424248,  60422780,  61431036,  62449032,  63476804,  64514376,
     65561776,  66619028,  67686160,  68763192,  69850160,  70947088,  72053992,  73170912,
     74297864,  75434880,  76581976,  77739184,  78906536,  80084040,  81271736,  82469648,
     83677792,  84896192,  86124888,  87363888,  88613232,  89872928,  91143016,  92423512,
     93714432,  95015816,  96327688,  97650056,  98982952, 100326408, 101680440, 103045072,
    104420320, 105806224, 107202800, 108610064, 110028048, 111456776, 112896264, 114346544,
    115807632, 117279552, 118762328, 120255976, 121760536, 123276016, 124802440, 126339832,
    127888216, 129447616, 131018048, 132599544, 134192112, 135795792, 137410592, 139036528,
    140673648, 142321952, 143981456, 145652208, 147334208, 149027488, 150732064, 152447968,
    154175200, 155913792, 157663776, 159425168, 161197984, 162982240, 164777968, 166585184,
    168403904, 170234160, 172075968, 173929344, 175794320, 177670896, 179559120, 181458992,
    183370528, 185293776, 187228736, 189175424, 191133888, 193104112, 195086128, 197079968,
    199085648, 201103184, 203132592, 205173888, 207227120, 209292272, 211369392, 213458480,
    215559568, 217672656, 219797792, 221934976, 224084240, 226245600, 228419056, 230604656,
    232802400, 235012320, 237234432, 239468736, 241715280, 243974080, 246245120, 248528464,
    250824112, 253132064, 255452368, 257785040, 260130080, 262487520, 264857376, 267239664,
};

static stbir_uint8 stbir__linear_to_srgb_uchar(float f)
{
    int x = (int) (f * (1 << 28)); // has headroom so you don't need to clamp
    int v = 0;
    int i;

    // Refine the guess with a short binary search.
    i = v + 128; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +  64; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +  32; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +  16; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +   8; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +   4; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +   2; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;
    i = v +   1; if (x >= stbir__srgb_offset_to_linear_scaled[i]) v = i;

    return (stbir_uint8) v;
}
#endif

static float stbir__filter_trapezoid(float x, float scale)
{
    float halfscale = scale / 2;
    float t = 0.5f + halfscale;
    STBIR_ASSERT(scale <= 1);

    x = (float)fabs(x);

    if (x >= t)
        return 0;
    else
    {
        float r = 0.5f - halfscale;
        if (x <= r)
            return 1;
        else
            return (t - x) / scale;
    }
}

static float stbir__support_trapezoid(float scale)
{
    STBIR_ASSERT(scale <= 1);
    return 0.5f + scale / 2;
}

static float stbir__filter_triangle(float x, float s)
{
    STBIR__UNUSED_PARAM(s);

    x = (float)fabs(x);

    if (x <= 1.0f)
        return 1 - x;
    else
        return 0;
}

static float stbir__filter_cubic(float x, float s)
{
    STBIR__UNUSED_PARAM(s);

    x = (float)fabs(x);

    if (x < 1.0f)
        return (4 + x*x*(3*x - 6))/6;
    else if (x < 2.0f)
        return (8 + x*(-12 + x*(6 - x)))/6;

    return (0.0f);
}

static float stbir__filter_catmullrom(float x, float s)
{
    STBIR__UNUSED_PARAM(s);

    x = (float)fabs(x);

    if (x < 1.0f)
        return 1 - x*x*(2.5f - 1.5f*x);
    else if (x < 2.0f)
        return 2 - x*(4 + x*(0.5f*x - 2.5f));

    return (0.0f);
}

static float stbir__filter_mitchell(float x, float s)
{
    STBIR__UNUSED_PARAM(s);

    x = (float)fabs(x);

    if (x < 1.0f)
        return (16 + x*x*(21 * x - 36))/18;
    else if (x < 2.0f)
        return (32 + x*(-60 + x*(36 - 7*x)))/18;

    return (0.0f);
}

static float stbir__support_zero(float s)
{
    STBIR__UNUSED_PARAM(s);
    return 0;
}

static float stbir__support_one(float s)
{
    STBIR__UNUSED_PARAM(s);
    return 1;
}

static float stbir__support_two(float s)
{
    STBIR__UNUSED_PARAM(s);
    return 2;
}

static stbir__filter_info stbir__filter_info_table[] = {
        { NULL,                     stbir__support_zero },
        { stbir__filter_trapezoid,  stbir__support_trapezoid },
        { stbir__filter_triangle,   stbir__support_one },
        { stbir__filter_cubic,      stbir__support_two },
        { stbir__filter_catmullrom, stbir__support_two },
        { stbir__filter_mitchell,   stbir__support_two },
};

stbir__inline static int stbir__use_upsampling(float ratio)
{
    return ratio > 1;
}

stbir__inline static int stbir__use_width_upsampling(stbir__info* stbir_info)
{
    return stbir__use_upsampling(stbir_info->horizontal_scale);
}

stbir__inline static int stbir__use_height_upsampling(stbir__info* stbir_info)
{
    return stbir__use_upsampling(stbir_info->vertical_scale);
}

// This is the maximum number of input samples that can affect an output sample
// with the given filter
static int stbir__get_filter_pixel_width(stbir_filter filter, float scale)
{
    STBIR_ASSERT(filter != 0);
    STBIR_ASSERT(filter < STBIR__ARRAY_SIZE(stbir__filter_info_table));

    if (stbir__use_upsampling(scale))
        return (int)ceil(stbir__filter_info_table[filter].support(1/scale) * 2);
    else
        return (int)ceil(stbir__filter_info_table[filter].support(scale) * 2 / scale);
}

// This is how much to expand buffers to account for filters seeking outside
// the image boundaries.
static int stbir__get_filter_pixel_margin(stbir_filter filter, float scale)
{
    return stbir__get_filter_pixel_width(filter, scale) / 2;
}

static int stbir__get_coefficient_width(stbir_filter filter, float scale)
{
    if (stbir__use_upsampling(scale))
        return (int)ceil(stbir__filter_info_table[filter].support(1 / scale) * 2);
    else
        return (int)ceil(stbir__filter_info_table[filter].support(scale) * 2);
}

static int stbir__get_contributors(float scale, stbir_filter filter, int input_size, int output_size)
{
    if (stbir__use_upsampling(scale))
        return output_size;
    else
        return (input_size + stbir__get_filter_pixel_margin(filter, scale) * 2);
}

static int stbir__get_total_horizontal_coefficients(stbir__info* info)
{
    return info->horizontal_num_contributors
         * stbir__get_coefficient_width      (info->horizontal_filter, info->horizontal_scale);
}

static int stbir__get_total_vertical_coefficients(stbir__info* info)
{
    return info->vertical_num_contributors
         * stbir__get_coefficient_width      (info->vertical_filter, info->vertical_scale);
}

static stbir__contributors* stbir__get_contributor(stbir__contributors* contributors, int n)
{
    return &contributors[n];
}

// For perf reasons this code is duplicated in stbir__resample_horizontal_upsample/downsample,
// if you change it here change it there too.
static float* stbir__get_coefficient(float* coefficients, stbir_filter filter, float scale, int n, int c)
{
    int width = stbir__get_coefficient_width(filter, scale);
    return &coefficients[width*n + c];
}

static int stbir__edge_wrap_slow(stbir_edge edge, int n, int max)
{
    switch (edge)
    {
    case STBIR_EDGE_ZERO:
        return 0; // we'll decode the wrong pixel here, and then overwrite with 0s later

    case STBIR_EDGE_CLAMP:
        if (n < 0)
            return 0;

        if (n >= max)
            return max - 1;

        return n; // NOTREACHED

    case STBIR_EDGE_REFLECT:
    {
        if (n < 0)
        {
            if (n < max)
                return -n;
            else
                return max - 1;
        }

        if (n >= max)
        {
            int max2 = max * 2;
            if (n >= max2)
                return 0;
            else
                return max2 - n - 1;
        }

        return n; // NOTREACHED
    }

    case STBIR_EDGE_WRAP:
        if (n >= 0)
            return (n % max);
        else
        {
            int m = (-n) % max;

            if (m != 0)
                m = max - m;

            return (m);
        }
        return n;  // NOTREACHED

    default:
        STBIR_ASSERT(!"Unimplemented edge type");
        return 0;
    }
}

stbir__inline static int stbir__edge_wrap(stbir_edge edge, int n, int max)
{
    // avoid per-pixel switch
    if (n >= 0 && n < max)
        return n;
    return stbir__edge_wrap_slow(edge, n, max);
}

// What input pixels contribute to this output pixel?
static void stbir__calculate_sample_range_upsample(int n, float out_filter_radius, float scale_ratio, float out_shift, int* in_first_pixel, int* in_last_pixel, float* in_center_of_out)
{
    float out_pixel_center = (float)n + 0.5f;
    float out_pixel_influence_lowerbound = out_pixel_center - out_filter_radius;
    float out_pixel_influence_upperbound = out_pixel_center + out_filter_radius;

    float in_pixel_influence_lowerbound = (out_pixel_influence_lowerbound + out_shift) / scale_ratio;
    float in_pixel_influence_upperbound = (out_pixel_influence_upperbound + out_shift) / scale_ratio;

    *in_center_of_out = (out_pixel_center + out_shift) / scale_ratio;
    *in_first_pixel = (int)(floor(in_pixel_influence_lowerbound + 0.5));
    *in_last_pixel = (int)(floor(in_pixel_influence_upperbound - 0.5));
}

// What output pixels does this input pixel contribute to?
static void stbir__calculate_sample_range_downsample(int n, float in_pixels_radius, float scale_ratio, float out_shift, int* out_first_pixel, int* out_last_pixel, float* out_center_of_in)
{
    float in_pixel_center = (float)n + 0.5f;
    float in_pixel_influence_lowerbound = in_pixel_center - in_pixels_radius;
    float in_pixel_influence_upperbound = in_pixel_center + in_pixels_radius;

    float out_pixel_influence_lowerbound = in_pixel_influence_lowerbound * scale_ratio - out_shift;
    float out_pixel_influence_upperbound = in_pixel_influence_upperbound * scale_ratio - out_shift;

    *out_center_of_in = in_pixel_center * scale_ratio - out_shift;
    *out_first_pixel = (int)(floor(out_pixel_influence_lowerbound + 0.5));
    *out_last_pixel = (int)(floor(out_pixel_influence_upperbound - 0.5));
}

static void stbir__calculate_coefficients_upsample(stbir__info* stbir_info, stbir_filter filter, float scale, int in_first_pixel, int in_last_pixel, float in_center_of_out, stbir__contributors* contributor, float* coefficient_group)
{
    int i;
    float total_filter = 0;
    float filter_scale;

    STBIR_ASSERT(in_last_pixel - in_first_pixel <= (int)ceil(stbir__filter_info_table[filter].support(1/scale) * 2)); // Taken directly from stbir__get_coefficient_width() which we can't call because we don't know if we're horizontal or vertical.

    contributor->n0 = in_first_pixel;
    contributor->n1 = in_last_pixel;

    STBIR_ASSERT(contributor->n1 >= contributor->n0);

    for (i = 0; i <= in_last_pixel - in_first_pixel; i++)
    {
        float in_pixel_center = (float)(i + in_first_pixel) + 0.5f;
        coefficient_group[i] = stbir__filter_info_table[filter].kernel(in_center_of_out - in_pixel_center, 1 / scale);

        // If the coefficient is zero, skip it. (Don't do the <0 check here, we want the influence of those outside pixels.)
        if (i == 0 && !coefficient_group[i])
        {
            contributor->n0 = ++in_first_pixel;
            i--;
            continue;
        }

        total_filter += coefficient_group[i];
    }

    STBIR_ASSERT(stbir__filter_info_table[filter].kernel((float)(in_last_pixel + 1) + 0.5f - in_center_of_out, 1/scale) == 0);

    STBIR_ASSERT(total_filter > 0.9);
    STBIR_ASSERT(total_filter < 1.1f); // Make sure it's not way off.

    // Make sure the sum of all coefficients is 1.
    filter_scale = 1 / total_filter;

    for (i = 0; i <= in_last_pixel - in_first_pixel; i++)
        coefficient_group[i] *= filter_scale;

    for (i = in_last_pixel - in_first_pixel; i >= 0; i--)
    {
        if (coefficient_group[i])
            break;

        // This line has no weight. We can skip it.
        contributor->n1 = contributor->n0 + i - 1;
    }
}

static void stbir__calculate_coefficients_downsample(stbir__info* stbir_info, stbir_filter filter, float scale_ratio, int out_first_pixel, int out_last_pixel, float out_center_of_in, stbir__contributors* contributor, float* coefficient_group)
{
    int i;

     STBIR_ASSERT(out_last_pixel - out_first_pixel <= (int)ceil(stbir__filter_info_table[filter].support(scale_ratio) * 2)); // Taken directly from stbir__get_coefficient_width() which we can't call because we don't know if we're horizontal or vertical.

    contributor->n0 = out_first_pixel;
    contributor->n1 = out_last_pixel;

    STBIR_ASSERT(contributor->n1 >= contributor->n0);

    for (i = 0; i <= out_last_pixel - out_first_pixel; i++)
    {
        float out_pixel_center = (float)(i + out_first_pixel) + 0.5f;
        float x = out_pixel_center - out_center_of_in;
        coefficient_group[i] = stbir__filter_info_table[filter].kernel(x, scale_ratio) * scale_ratio;
    }

    STBIR_ASSERT(stbir__filter_info_table[filter].kernel((float)(out_last_pixel + 1) + 0.5f - out_center_of_in, scale_ratio) == 0);

    for (i = out_last_pixel - out_first_pixel; i >= 0; i--)
    {
        if (coefficient_group[i])
            break;

        // This line has no weight. We can skip it.
        contributor->n1 = contributor->n0 + i - 1;
    }
}

static void stbir__normalize_downsample_coefficients(stbir__info* stbir_info, stbir__contributors* contributors, float* coefficients, stbir_filter filter, float scale_ratio, float shift, int input_size, int output_size)
{
    int num_contributors = stbir__get_contributors(scale_ratio, filter, input_size, output_size);
    int num_coefficients = stbir__get_coefficient_width(filter, scale_ratio);
    int i, j;
    int skip;

    for (i = 0; i < output_size; i++)
    {
        float scale;
        float total = 0;

        for (j = 0; j < num_contributors; j++)
        {
            if (i >= contributors[j].n0 && i <= contributors[j].n1)
            {
                float coefficient = *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i - contributors[j].n0);
                total += coefficient;
            }
            else if (i < contributors[j].n0)
                break;
        }

        STBIR_ASSERT(total > 0.9f);
        STBIR_ASSERT(total < 1.1f);

        scale = 1 / total;

        for (j = 0; j < num_contributors; j++)
        {
            if (i >= contributors[j].n0 && i <= contributors[j].n1)
                *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i - contributors[j].n0) *= scale;
            else if (i < contributors[j].n0)
                break;
        }
    }

    // Optimize: Skip zero coefficients and contributions outside of image bounds.
    // Do this after normalizing because normalization depends on the n0/n1 values.
    for (j = 0; j < num_contributors; j++)
    {
        int range, max, width;

        skip = 0;
        while (*stbir__get_coefficient(coefficients, filter, scale_ratio, j, skip) == 0)
            skip++;

        contributors[j].n0 += skip;

        while (contributors[j].n0 < 0)
        {
            contributors[j].n0++;
            skip++;
        }

        range = contributors[j].n1 - contributors[j].n0 + 1;
        max = stbir__min(num_coefficients, range);

        width = stbir__get_coefficient_width(filter, scale_ratio);
        for (i = 0; i < max; i++)
        {
            if (i + skip >= width)
                break;

            *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i) = *stbir__get_coefficient(coefficients, filter, scale_ratio, j, i + skip);
        }

        continue;
    }

    // Using min to avoid writing into invalid pixels.
    for (i = 0; i < num_contributors; i++)
        contributors[i].n1 = stbir__min(contributors[i].n1, output_size - 1);
}

// Each scan line uses the same kernel values so we should calculate the kernel
// values once and then we can use them for every scan line.
static void stbir__calculate_filters(stbir__info* stbir_info, stbir__contributors* contributors, float* coefficients, stbir_filter filter, float scale_ratio, float shift, int input_size, int output_size)
{
    int n;
    int total_contributors = stbir__get_contributors(scale_ratio, filter, input_size, output_size);

    if (stbir__use_upsampling(scale_ratio))
    {
        float out_pixels_radius = stbir__filter_info_table[filter].support(1 / scale_ratio) * scale_ratio;

        // Looping through out pixels
        for (n = 0; n < total_contributors; n++)
        {
            float in_center_of_out; // Center of the current out pixel in the in pixel space
            int in_first_pixel, in_last_pixel;

            stbir__calculate_sample_range_upsample(n, out_pixels_radius, scale_ratio, shift, &in_first_pixel, &in_last_pixel, &in_center_of_out);

            stbir__calculate_coefficients_upsample(stbir_info, filter, scale_ratio, in_first_pixel, in_last_pixel, in_center_of_out, stbir__get_contributor(contributors, n), stbir__get_coefficient(coefficients, filter, scale_ratio, n, 0));
        }
    }
    else
    {
        float in_pixels_radius = stbir__filter_info_table[filter].support(scale_ratio) / scale_ratio;

        // Looping through in pixels
        for (n = 0; n < total_contributors; n++)
        {
            float out_center_of_in; // Center of the current out pixel in the in pixel space
            int out_first_pixel, out_last_pixel;
            int n_adjusted = n - stbir__get_filter_pixel_margin(filter, scale_ratio);

            stbir__calculate_sample_range_downsample(n_adjusted, in_pixels_radius, scale_ratio, shift, &out_first_pixel, &out_last_pixel, &out_center_of_in);

            stbir__calculate_coefficients_downsample(stbir_info, filter, scale_ratio, out_first_pixel, out_last_pixel, out_center_of_in, stbir__get_contributor(contributors, n), stbir__get_coefficient(coefficients, filter, scale_ratio, n, 0));
        }

        stbir__normalize_downsample_coefficients(stbir_info, contributors, coefficients, filter, scale_ratio, shift, input_size, output_size);
    }
}

static float* stbir__get_decode_buffer(stbir__info* stbir_info)
{
    // The 0 index of the decode buffer starts after the margin. This makes
    // it okay to use negative indexes on the decode buffer.
    return &stbir_info->decode_buffer[stbir_info->horizontal_filter_pixel_margin * stbir_info->channels];
}

#define STBIR__DECODE(type, colorspace) ((type) * (STBIR_MAX_COLORSPACES) + (colorspace))

static void stbir__decode_scanline(stbir__info* stbir_info, int n)
{
    int c;
    int channels = stbir_info->channels;
    int alpha_channel = stbir_info->alpha_channel;
    int type = stbir_info->type;
    int colorspace = stbir_info->colorspace;
    int input_w = stbir_info->input_w;
    int input_stride_bytes = stbir_info->input_stride_bytes;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir_edge edge_horizontal = stbir_info->edge_horizontal;
    stbir_edge edge_vertical = stbir_info->edge_vertical;
    int in_buffer_row_offset = stbir__edge_wrap(edge_vertical, n, stbir_info->input_h) * input_stride_bytes;
    const void* input_data = (char *) stbir_info->input_data + in_buffer_row_offset;
    int max_x = input_w + stbir_info->horizontal_filter_pixel_margin;
    int decode = STBIR__DECODE(type, colorspace);

    int x = -stbir_info->horizontal_filter_pixel_margin;

    // special handling for STBIR_EDGE_ZERO because it needs to return an item that doesn't appear in the input,
    // and we want to avoid paying overhead on every pixel if not STBIR_EDGE_ZERO
    if (edge_vertical == STBIR_EDGE_ZERO && (n < 0 || n >= stbir_info->input_h))
    {
        for (; x < max_x; x++)
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        return;
    }

    switch (decode)
    {
    case STBIR__DECODE(STBIR_TYPE_UINT8, STBIR_COLORSPACE_LINEAR):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = ((float)((const unsigned char*)input_data)[input_pixel_index + c]) / 255;
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_UINT8, STBIR_COLORSPACE_SRGB):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_uchar_to_linear_float[((const unsigned char*)input_data)[input_pixel_index + c]];

            if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                decode_buffer[decode_pixel_index + alpha_channel] = ((float)((const unsigned char*)input_data)[input_pixel_index + alpha_channel]) / 255;
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_UINT16, STBIR_COLORSPACE_LINEAR):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = ((float)((const unsigned short*)input_data)[input_pixel_index + c]) / 65535;
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_UINT16, STBIR_COLORSPACE_SRGB):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear(((float)((const unsigned short*)input_data)[input_pixel_index + c]) / 65535);

            if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                decode_buffer[decode_pixel_index + alpha_channel] = ((float)((const unsigned short*)input_data)[input_pixel_index + alpha_channel]) / 65535;
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_UINT32, STBIR_COLORSPACE_LINEAR):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = (float)(((double)((const unsigned int*)input_data)[input_pixel_index + c]) / 4294967295);
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_UINT32, STBIR_COLORSPACE_SRGB):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear((float)(((double)((const unsigned int*)input_data)[input_pixel_index + c]) / 4294967295));

            if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                decode_buffer[decode_pixel_index + alpha_channel] = (float)(((double)((const unsigned int*)input_data)[input_pixel_index + alpha_channel]) / 4294967295);
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_FLOAT, STBIR_COLORSPACE_LINEAR):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = ((const float*)input_data)[input_pixel_index + c];
        }
        break;

    case STBIR__DECODE(STBIR_TYPE_FLOAT, STBIR_COLORSPACE_SRGB):
        for (; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;
            int input_pixel_index = stbir__edge_wrap(edge_horizontal, x, input_w) * channels;
            for (c = 0; c < channels; c++)
                decode_buffer[decode_pixel_index + c] = stbir__srgb_to_linear(((const float*)input_data)[input_pixel_index + c]);

            if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                decode_buffer[decode_pixel_index + alpha_channel] = ((const float*)input_data)[input_pixel_index + alpha_channel];
        }

        break;

    default:
        STBIR_ASSERT(!"Unknown type/colorspace/channels combination.");
        break;
    }

    if (!(stbir_info->flags & STBIR_FLAG_ALPHA_PREMULTIPLIED))
    {
        for (x = -stbir_info->horizontal_filter_pixel_margin; x < max_x; x++)
        {
            int decode_pixel_index = x * channels;

            // If the alpha value is 0 it will clobber the color values. Make sure it's not.
            float alpha = decode_buffer[decode_pixel_index + alpha_channel];
#ifndef STBIR_NO_ALPHA_EPSILON
            if (stbir_info->type != STBIR_TYPE_FLOAT) {
                alpha += STBIR_ALPHA_EPSILON;
                decode_buffer[decode_pixel_index + alpha_channel] = alpha;
            }
#endif
            for (c = 0; c < channels; c++)
            {
                if (c == alpha_channel)
                    continue;

                decode_buffer[decode_pixel_index + c] *= alpha;
            }
        }
    }

    if (edge_horizontal == STBIR_EDGE_ZERO)
    {
        for (x = -stbir_info->horizontal_filter_pixel_margin; x < 0; x++)
        {
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        }
        for (x = input_w; x < max_x; x++)
        {
            for (c = 0; c < channels; c++)
                decode_buffer[x*channels + c] = 0;
        }
    }
}

static float* stbir__get_ring_buffer_entry(float* ring_buffer, int index, int ring_buffer_length)
{
    return &ring_buffer[index * ring_buffer_length];
}

static float* stbir__add_empty_ring_buffer_entry(stbir__info* stbir_info, int n)
{
    int ring_buffer_index;
    float* ring_buffer;

    if (stbir_info->ring_buffer_begin_index < 0)
    {
        ring_buffer_index = stbir_info->ring_buffer_begin_index = 0;
        stbir_info->ring_buffer_first_scanline = n;
    }
    else
    {
        ring_buffer_index = (stbir_info->ring_buffer_begin_index + (stbir_info->ring_buffer_last_scanline - stbir_info->ring_buffer_first_scanline) + 1) % stbir_info->vertical_filter_pixel_width;
        STBIR_ASSERT(ring_buffer_index != stbir_info->ring_buffer_begin_index);
    }

    ring_buffer = stbir__get_ring_buffer_entry(stbir_info->ring_buffer, ring_buffer_index, stbir_info->ring_buffer_length_bytes / sizeof(float));
    memset(ring_buffer, 0, stbir_info->ring_buffer_length_bytes);

    stbir_info->ring_buffer_last_scanline = n;

    return ring_buffer;
}


static void stbir__resample_horizontal_upsample(stbir__info* stbir_info, int n, float* output_buffer)
{
    int x, k;
    int output_w = stbir_info->output_w;
    int kernel_pixel_width = stbir_info->horizontal_filter_pixel_width;
    int channels = stbir_info->channels;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir__contributors* horizontal_contributors = stbir_info->horizontal_contributors;
    float* horizontal_coefficients = stbir_info->horizontal_coefficients;
    int coefficient_width = stbir_info->horizontal_coefficient_width;

    for (x = 0; x < output_w; x++)
    {
        int n0 = horizontal_contributors[x].n0;
        int n1 = horizontal_contributors[x].n1;

        int out_pixel_index = x * channels;
        int coefficient_group = coefficient_width * x;
        int coefficient_counter = 0;

        STBIR_ASSERT(n1 >= n0);
        STBIR_ASSERT(n0 >= -stbir_info->horizontal_filter_pixel_margin);
        STBIR_ASSERT(n1 >= -stbir_info->horizontal_filter_pixel_margin);
        STBIR_ASSERT(n0 < stbir_info->input_w + stbir_info->horizontal_filter_pixel_margin);
        STBIR_ASSERT(n1 < stbir_info->input_w + stbir_info->horizontal_filter_pixel_margin);

        switch (channels) {
            case 1:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 1;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                }
                break;
            case 2:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 2;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                }
                break;
            case 3:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 3;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                }
                break;
            case 4:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * 4;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                    output_buffer[out_pixel_index + 3] += decode_buffer[in_pixel_index + 3] * coefficient;
                }
                break;
            default:
                for (k = n0; k <= n1; k++)
                {
                    int in_pixel_index = k * channels;
                    float coefficient = horizontal_coefficients[coefficient_group + coefficient_counter++];
                    int c;
                    STBIR_ASSERT(coefficient != 0);
                    for (c = 0; c < channels; c++)
                        output_buffer[out_pixel_index + c] += decode_buffer[in_pixel_index + c] * coefficient;
                }
                break;
        }
    }
}

static void stbir__resample_horizontal_downsample(stbir__info* stbir_info, int n, float* output_buffer)
{
    int x, k;
    int input_w = stbir_info->input_w;
    int output_w = stbir_info->output_w;
    int kernel_pixel_width = stbir_info->horizontal_filter_pixel_width;
    int channels = stbir_info->channels;
    float* decode_buffer = stbir__get_decode_buffer(stbir_info);
    stbir__contributors* horizontal_contributors = stbir_info->horizontal_contributors;
    float* horizontal_coefficients = stbir_info->horizontal_coefficients;
    int coefficient_width = stbir_info->horizontal_coefficient_width;
    int filter_pixel_margin = stbir_info->horizontal_filter_pixel_margin;
    int max_x = input_w + filter_pixel_margin * 2;

    STBIR_ASSERT(!stbir__use_width_upsampling(stbir_info));

    switch (channels) {
        case 1:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 1;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 1;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                }
            }
            break;

        case 2:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 2;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 2;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                }
            }
            break;

        case 3:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 3;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 3;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                }
            }
            break;

        case 4:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * 4;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int out_pixel_index = k * 4;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    STBIR_ASSERT(coefficient != 0);
                    output_buffer[out_pixel_index + 0] += decode_buffer[in_pixel_index + 0] * coefficient;
                    output_buffer[out_pixel_index + 1] += decode_buffer[in_pixel_index + 1] * coefficient;
                    output_buffer[out_pixel_index + 2] += decode_buffer[in_pixel_index + 2] * coefficient;
                    output_buffer[out_pixel_index + 3] += decode_buffer[in_pixel_index + 3] * coefficient;
                }
            }
            break;

        default:
            for (x = 0; x < max_x; x++)
            {
                int n0 = horizontal_contributors[x].n0;
                int n1 = horizontal_contributors[x].n1;

                int in_x = x - filter_pixel_margin;
                int in_pixel_index = in_x * channels;
                int max_n = n1;
                int coefficient_group = coefficient_width * x;

                for (k = n0; k <= max_n; k++)
                {
                    int c;
                    int out_pixel_index = k * channels;
                    float coefficient = horizontal_coefficients[coefficient_group + k - n0];
                    STBIR_ASSERT(coefficient != 0);
                    for (c = 0; c < channels; c++)
                        output_buffer[out_pixel_index + c] += decode_buffer[in_pixel_index + c] * coefficient;
                }
            }
            break;
    }
}

static void stbir__decode_and_resample_upsample(stbir__info* stbir_info, int n)
{
    // Decode the nth scanline from the source image into the decode buffer.
    stbir__decode_scanline(stbir_info, n);

    // Now resample it into the ring buffer.
    if (stbir__use_width_upsampling(stbir_info))
        stbir__resample_horizontal_upsample(stbir_info, n, stbir__add_empty_ring_buffer_entry(stbir_info, n));
    else
        stbir__resample_horizontal_downsample(stbir_info, n, stbir__add_empty_ring_buffer_entry(stbir_info, n));

    // Now it's sitting in the ring buffer ready to be used as source for the vertical sampling.
}

static void stbir__decode_and_resample_downsample(stbir__info* stbir_info, int n)
{
    // Decode the nth scanline from the source image into the decode buffer.
    stbir__decode_scanline(stbir_info, n);

    memset(stbir_info->horizontal_buffer, 0, stbir_info->output_w * stbir_info->channels * sizeof(float));

    // Now resample it into the horizontal buffer.
    if (stbir__use_width_upsampling(stbir_info))
        stbir__resample_horizontal_upsample(stbir_info, n, stbir_info->horizontal_buffer);
    else
        stbir__resample_horizontal_downsample(stbir_info, n, stbir_info->horizontal_buffer);

    // Now it's sitting in the horizontal buffer ready to be distributed into the ring buffers.
}

// Get the specified scan line from the ring buffer.
static float* stbir__get_ring_buffer_scanline(int get_scanline, float* ring_buffer, int begin_index, int first_scanline, int ring_buffer_size, int ring_buffer_length)
{
    int ring_buffer_index = (begin_index + (get_scanline - first_scanline)) % ring_buffer_size;
    return stbir__get_ring_buffer_entry(ring_buffer, ring_buffer_index, ring_buffer_length);
}


static void stbir__encode_scanline(stbir__info* stbir_info, int num_pixels, void *output_buffer, float *encode_buffer, int channels, int alpha_channel, int decode)
{
    int x;
    int n;
    int num_nonalpha;
    stbir_uint16 nonalpha[STBIR_MAX_CHANNELS];

    if (!(stbir_info->flags&STBIR_FLAG_ALPHA_PREMULTIPLIED))
    {
        for (x=0; x < num_pixels; ++x)
        {
            int pixel_index = x*channels;

            float alpha = encode_buffer[pixel_index + alpha_channel];
            float reciprocal_alpha = alpha ? 1.0f / alpha : 0;

            // unrolling this produced a 1% slowdown upscaling a large RGBA linear-space image on my machine - stb
            for (n = 0; n < channels; n++)
                if (n != alpha_channel)
                    encode_buffer[pixel_index + n] *= reciprocal_alpha;

            // We added in a small epsilon to prevent the color channel from being deleted with zero alpha.
            // Because we only add it for integer types, it will automatically be discarded on integer
            // conversion, so we don't need to subtract it back out (which would be problematic for
            // numeric precision reasons).
        }
    }

    // build a table of all channels that need colorspace correction, so
    // we don't perform colorspace correction on channels that don't need it.
    for (x=0, num_nonalpha=0; x < channels; ++x)
        if (x != alpha_channel || (stbir_info->flags & STBIR_FLAG_ALPHA_USES_COLORSPACE))
            nonalpha[num_nonalpha++] = x;

    #define STBIR__ROUND_INT(f)    ((int)          ((f)+0.5))
    #define STBIR__ROUND_UINT(f)   ((stbir_uint32) ((f)+0.5))

    #ifdef STBIR__SATURATE_INT
    #define STBIR__ENCODE_LINEAR8(f)   stbir__saturate8 (STBIR__ROUND_INT((f) * 255  ))
    #define STBIR__ENCODE_LINEAR16(f)  stbir__saturate16(STBIR__ROUND_INT((f) * 65535))
    #else
    #define STBIR__ENCODE_LINEAR8(f)   (unsigned char ) STBIR__ROUND_INT(stbir__saturate(f) * 255  )
    #define STBIR__ENCODE_LINEAR16(f)  (unsigned short) STBIR__ROUND_INT(stbir__saturate(f) * 65535)
    #endif

    switch (decode)
    {
        case STBIR__DECODE(STBIR_TYPE_UINT8, STBIR_COLORSPACE_LINEAR):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    ((unsigned char*)output_buffer)[index] = STBIR__ENCODE_LINEAR8(encode_buffer[index]);
                }
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_UINT8, STBIR_COLORSPACE_SRGB):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    ((unsigned char*)output_buffer)[index] = stbir__linear_to_srgb_uchar(encode_buffer[index]);
                }

                if (!(stbir_info->flags & STBIR_FLAG_ALPHA_USES_COLORSPACE))
                    ((unsigned char *)output_buffer)[pixel_index + alpha_channel] = STBIR__ENCODE_LINEAR8(encode_buffer[pixel_index+alpha_channel]);
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_UINT16, STBIR_COLORSPACE_LINEAR):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    ((unsigned short*)output_buffer)[index] = STBIR__ENCODE_LINEAR16(encode_buffer[index]);
                }
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_UINT16, STBIR_COLORSPACE_SRGB):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    ((unsigned short*)output_buffer)[index] = (unsigned short)STBIR__ROUND_INT(stbir__linear_to_srgb(stbir__saturate(encode_buffer[index])) * 65535);
                }

                if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                    ((unsigned short*)output_buffer)[pixel_index + alpha_channel] = STBIR__ENCODE_LINEAR16(encode_buffer[pixel_index + alpha_channel]);
            }

            break;

        case STBIR__DECODE(STBIR_TYPE_UINT32, STBIR_COLORSPACE_LINEAR):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    ((unsigned int*)output_buffer)[index] = (unsigned int)STBIR__ROUND_UINT(((double)stbir__saturate(encode_buffer[index])) * 4294967295);
                }
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_UINT32, STBIR_COLORSPACE_SRGB):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    ((unsigned int*)output_buffer)[index] = (unsigned int)STBIR__ROUND_UINT(((double)stbir__linear_to_srgb(stbir__saturate(encode_buffer[index]))) * 4294967295);
                }

                if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                    ((unsigned int*)output_buffer)[pixel_index + alpha_channel] = (unsigned int)STBIR__ROUND_INT(((double)stbir__saturate(encode_buffer[pixel_index + alpha_channel])) * 4294967295);
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_FLOAT, STBIR_COLORSPACE_LINEAR):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < channels; n++)
                {
                    int index = pixel_index + n;
                    ((float*)output_buffer)[index] = encode_buffer[index];
                }
            }
            break;

        case STBIR__DECODE(STBIR_TYPE_FLOAT, STBIR_COLORSPACE_SRGB):
            for (x=0; x < num_pixels; ++x)
            {
                int pixel_index = x*channels;

                for (n = 0; n < num_nonalpha; n++)
                {
                    int index = pixel_index + nonalpha[n];
                    ((float*)output_buffer)[index] = stbir__linear_to_srgb(encode_buffer[index]);
                }

                if (!(stbir_info->flags&STBIR_FLAG_ALPHA_USES_COLORSPACE))
                    ((float*)output_buffer)[pixel_index + alpha_channel] = encode_buffer[pixel_index + alpha_channel];
            }
            break;

        default:
            STBIR_ASSERT(!"Unknown type/colorspace/channels combination.");
            break;
    }
}

static void stbir__resample_vertical_upsample(stbir__info* stbir_info, int n, int in_first_scanline, int in_last_scanline, float in_center_of_out)
{
    int x, k;
    int output_w = stbir_info->output_w;
    stbir__contributors* vertical_contributors = stbir_info->vertical_contributors;
    float* vertical_coefficients = stbir_info->vertical_coefficients;
    int channels = stbir_info->channels;
    int alpha_channel = stbir_info->alpha_channel;
    int type = stbir_info->type;
    int colorspace = stbir_info->colorspace;
    int kernel_pixel_width = stbir_info->vertical_filter_pixel_width;
    void* output_data = stbir_info->output_data;
    float* encode_buffer = stbir_info->encode_buffer;
    int decode = STBIR__DECODE(type, colorspace);
    int coefficient_width = stbir_info->vertical_coefficient_width;
    int coefficient_counter;
    int contributor = n;

    float* ring_buffer = stbir_info->ring_buffer;
    int ring_buffer_begin_index = stbir_info->ring_buffer_begin_index;
    int ring_buffer_first_scanline = stbir_info->ring_buffer_first_scanline;
    int ring_buffer_last_scanline = stbir_info->ring_buffer_last_scanline;
    int ring_buffer_length = stbir_info->ring_buffer_length_bytes/sizeof(float);

    int n0,n1, output_row_start;
    int coefficient_group = coefficient_width * contributor;

    n0 = vertical_contributors[contributor].n0;
    n1 = vertical_contributors[contributor].n1;

    output_row_start = n * stbir_info->output_stride_bytes;

    STBIR_ASSERT(stbir__use_height_upsampling(stbir_info));

    memset(encode_buffer, 0, output_w * sizeof(float) * channels);

    // I tried reblocking this for better cache usage of encode_buffer
    // (using x_outer, k, x_inner), but it lost speed. -- stb

    coefficient_counter = 0;
    switch (channels) {
        case 1:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 1;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                }
            }
            break;
        case 2:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 2;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                }
            }
            break;
        case 3:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 3;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                    encode_buffer[in_pixel_index + 2] += ring_buffer_entry[in_pixel_index + 2] * coefficient;
                }
            }
            break;
        case 4:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * 4;
                    encode_buffer[in_pixel_index + 0] += ring_buffer_entry[in_pixel_index + 0] * coefficient;
                    encode_buffer[in_pixel_index + 1] += ring_buffer_entry[in_pixel_index + 1] * coefficient;
                    encode_buffer[in_pixel_index + 2] += ring_buffer_entry[in_pixel_index + 2] * coefficient;
                    encode_buffer[in_pixel_index + 3] += ring_buffer_entry[in_pixel_index + 3] * coefficient;
                }
            }
            break;
        default:
            for (k = n0; k <= n1; k++)
            {
                int coefficient_index = coefficient_counter++;
                float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);
                float coefficient = vertical_coefficients[coefficient_group + coefficient_index];
                for (x = 0; x < output_w; ++x)
                {
                    int in_pixel_index = x * channels;
                    int c;
                    for (c = 0; c < channels; c++)
                        encode_buffer[in_pixel_index + c] += ring_buffer_entry[in_pixel_index + c] * coefficient;
                }
            }
            break;
    }
    stbir__encode_scanline(stbir_info, output_w, (char *) output_data + output_row_start, encode_buffer, channels, alpha_channel, decode);
}

static void stbir__resample_vertical_downsample(stbir__info* stbir_info, int n, int in_first_scanline, int in_last_scanline, float in_center_of_out)
{
    int x, k;
    int output_w = stbir_info->output_w;
    int output_h = stbir_info->output_h;
    stbir__contributors* vertical_contributors = stbir_info->vertical_contributors;
    float* vertical_coefficients = stbir_info->vertical_coefficients;
    int channels = stbir_info->channels;
    int kernel_pixel_width = stbir_info->vertical_filter_pixel_width;
    void* output_data = stbir_info->output_data;
    float* horizontal_buffer = stbir_info->horizontal_buffer;
    int coefficient_width = stbir_info->vertical_coefficient_width;
    int contributor = n + stbir_info->vertical_filter_pixel_margin;

    float* ring_buffer = stbir_info->ring_buffer;
    int ring_buffer_begin_index = stbir_info->ring_buffer_begin_index;
    int ring_buffer_first_scanline = stbir_info->ring_buffer_first_scanline;
    int ring_buffer_last_scanline = stbir_info->ring_buffer_last_scanline;
    int ring_buffer_length = stbir_info->ring_buffer_length_bytes/sizeof(float);
    int n0,n1;

    n0 = vertical_contributors[contributor].n0;
    n1 = vertical_contributors[contributor].n1;

    STBIR_ASSERT(!stbir__use_height_upsampling(stbir_info));

    for (k = n0; k <= n1; k++)
    {
        int coefficient_index = k - n0;
        int coefficient_group = coefficient_width * contributor;
        float coefficient = vertical_coefficients[coefficient_group + coefficient_index];

        float* ring_buffer_entry = stbir__get_ring_buffer_scanline(k, ring_buffer, ring_buffer_begin_index, ring_buffer_first_scanline, kernel_pixel_width, ring_buffer_length);

        switch (channels) {
            case 1:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 1;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                }
                break;
            case 2:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 2;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                }
                break;
            case 3:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 3;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                    ring_buffer_entry[in_pixel_index + 2] += horizontal_buffer[in_pixel_index + 2] * coefficient;
                }
                break;
            case 4:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * 4;
                    ring_buffer_entry[in_pixel_index + 0] += horizontal_buffer[in_pixel_index + 0] * coefficient;
                    ring_buffer_entry[in_pixel_index + 1] += horizontal_buffer[in_pixel_index + 1] * coefficient;
                    ring_buffer_entry[in_pixel_index + 2] += horizontal_buffer[in_pixel_index + 2] * coefficient;
                    ring_buffer_entry[in_pixel_index + 3] += horizontal_buffer[in_pixel_index + 3] * coefficient;
                }
                break;
            default:
                for (x = 0; x < output_w; x++)
                {
                    int in_pixel_index = x * channels;

                    int c;
                    for (c = 0; c < channels; c++)
                        ring_buffer_entry[in_pixel_index + c] += horizontal_buffer[in_pixel_index + c] * coefficient;
                }
                break;
        }
    }
}

static void stbir__buffer_loop_upsample(stbir__info* stbir_info)
{
    int y;
    float scale_ratio = stbir_info->vertical_scale;
    float out_scanlines_radius = stbir__filter_info_table[stbir_info->vertical_filter].support(1/scale_ratio) * scale_ratio;

    STBIR_ASSERT(stbir__use_height_upsampling(stbir_info));

    for (y = 0; y < stbir_info->output_h; y++)
    {
        float in_center_of_out = 0; // Center of the current out scanline in the in scanline space
        int in_first_scanline = 0, in_last_scanline = 0;

        stbir__calculate_sample_range_upsample(y, out_scanlines_radius, scale_ratio, stbir_info->vertical_shift, &in_first_scanline, &in_last_scanline, &in_center_of_out);

        STBIR_ASSERT(in_last_scanline - in_first_scanline <= stbir_info->vertical_filter_pixel_width);

        if (stbir_info->ring_buffer_begin_index >= 0)
        {
            // Get rid of whatever we don't need anymore.
            while (in_first_scanline > stbir_info->ring_buffer_first_scanline)
            {
                if (stbir_info->ring_buffer_first_scanline == stbir_info->ring_buffer_last_scanline)
                {
                    // We just popped the last scanline off the ring buffer.
                    // Reset it to the empty state.
                    stbir_info->ring_buffer_begin_index = -1;
                    stbir_info->ring_buffer_first_scanline = 0;
                    stbir_info->ring_buffer_last_scanline = 0;
                    break;
                }
                else
                {
                    stbir_info->ring_buffer_first_scanline++;
                    stbir_info->ring_buffer_begin_index = (stbir_info->ring_buffer_begin_index + 1) % stbir_info->vertical_filter_pixel_width;
                }
            }
        }

        // Load in new ones.
        if (stbir_info->ring_buffer_begin_index < 0)
            stbir__decode_and_resample_upsample(stbir_info, in_first_scanline);

        while (in_last_scanline > stbir_info->ring_buffer_last_scanline)
            stbir__decode_and_resample_upsample(stbir_info, stbir_info->ring_buffer_last_scanline + 1);

        // Now all buffers should be ready to write a row of vertical sampling.
        stbir__resample_vertical_upsample(stbir_info, y, in_first_scanline, in_last_scanline, in_center_of_out);

        STBIR_PROGRESS_REPORT((float)y / stbir_info->output_h);
    }
}

static void stbir__empty_ring_buffer(stbir__info* stbir_info, int first_necessary_scanline)
{
    int output_stride_bytes = stbir_info->output_stride_bytes;
    int channels = stbir_info->channels;
    int alpha_channel = stbir_info->alpha_channel;
    int type = stbir_info->type;
    int colorspace = stbir_info->colorspace;
    int output_w = stbir_info->output_w;
    void* output_data = stbir_info->output_data;
    int decode = STBIR__DECODE(type, colorspace);

    float* ring_buffer = stbir_info->ring_buffer;
    int ring_buffer_length = stbir_info->ring_buffer_length_bytes/sizeof(float);

    if (stbir_info->ring_buffer_begin_index >= 0)
    {
        // Get rid of whatever we don't need anymore.
        while (first_necessary_scanline > stbir_info->ring_buffer_first_scanline)
        {
            if (stbir_info->ring_buffer_first_scanline >= 0 && stbir_info->ring_buffer_first_scanline < stbir_info->output_h)
            {
                int output_row_start = stbir_info->ring_buffer_first_scanline * output_stride_bytes;
                float* ring_buffer_entry = stbir__get_ring_buffer_entry(ring_buffer, stbir_info->ring_buffer_begin_index, ring_buffer_length);
                stbir__encode_scanline(stbir_info, output_w, (char *) output_data + output_row_start, ring_buffer_entry, channels, alpha_channel, decode);
                STBIR_PROGRESS_REPORT((float)stbir_info->ring_buffer_first_scanline / stbir_info->output_h);
            }

            if (stbir_info->ring_buffer_first_scanline == stbir_info->ring_buffer_last_scanline)
            {
                // We just popped the last scanline off the ring buffer.
                // Reset it to the empty state.
                stbir_info->ring_buffer_begin_index = -1;
                stbir_info->ring_buffer_first_scanline = 0;
                stbir_info->ring_buffer_last_scanline = 0;
                break;
            }
            else
            {
                stbir_info->ring_buffer_first_scanline++;
                stbir_info->ring_buffer_begin_index = (stbir_info->ring_buffer_begin_index + 1) % stbir_info->vertical_filter_pixel_width;
            }
        }
    }
}

static void stbir__buffer_loop_downsample(stbir__info* stbir_info)
{
    int y;
    float scale_ratio = stbir_info->vertical_scale;
    int output_h = stbir_info->output_h;
    float in_pixels_radius = stbir__filter_info_table[stbir_info->vertical_filter].support(scale_ratio) / scale_ratio;
    int pixel_margin = stbir_info->vertical_filter_pixel_margin;
    int max_y = stbir_info->input_h + pixel_margin;

    STBIR_ASSERT(!stbir__use_height_upsampling(stbir_info));

    for (y = -pixel_margin; y < max_y; y++)
    {
        float out_center_of_in; // Center of the current out scanline in the in scanline space
        int out_first_scanline, out_last_scanline;

        stbir__calculate_sample_range_downsample(y, in_pixels_radius, scale_ratio, stbir_info->vertical_shift, &out_first_scanline, &out_last_scanline, &out_center_of_in);

        STBIR_ASSERT(out_last_scanline - out_first_scanline <= stbir_info->vertical_filter_pixel_width);

        if (out_last_scanline < 0 || out_first_scanline >= output_h)
            continue;

        stbir__empty_ring_buffer(stbir_info, out_first_scanline);

        stbir__decode_and_resample_downsample(stbir_info, y);

        // Load in new ones.
        if (stbir_info->ring_buffer_begin_index < 0)
            stbir__add_empty_ring_buffer_entry(stbir_info, out_first_scanline);

        while (out_last_scanline > stbir_info->ring_buffer_last_scanline)
            stbir__add_empty_ring_buffer_entry(stbir_info, stbir_info->ring_buffer_last_scanline + 1);

        // Now the horizontal buffer is ready to write to all ring buffer rows.
        stbir__resample_vertical_downsample(stbir_info, y, out_first_scanline, out_last_scanline, out_center_of_in);
    }

    stbir__empty_ring_buffer(stbir_info, stbir_info->output_h);
}

static void stbir__setup(stbir__info *info, int input_w, int input_h, int output_w, int output_h, int channels)
{
    info->input_w = input_w;
    info->input_h = input_h;
    info->output_w = output_w;
    info->output_h = output_h;
    info->channels = channels;
}

static void stbir__calculate_transform(stbir__info *info, float s0, float t0, float s1, float t1, float *transform)
{
    info->s0 = s0;
    info->t0 = t0;
    info->s1 = s1;
    info->t1 = t1;

    if (transform)
    {
        info->horizontal_scale = transform[0];
        info->vertical_scale   = transform[1];
        info->horizontal_shift = transform[2];
        info->vertical_shift   = transform[3];
    }
    else
    {
        info->horizontal_scale = ((float)info->output_w / info->input_w) / (s1 - s0);
        info->vertical_scale = ((float)info->output_h / info->input_h) / (t1 - t0);

        info->horizontal_shift = s0 * info->output_w / (s1 - s0);
        info->vertical_shift = t0 * info->output_h / (t1 - t0);
    }
}

static void stbir__choose_filter(stbir__info *info, stbir_filter h_filter, stbir_filter v_filter)
{
    if (h_filter == 0)
        h_filter = stbir__use_upsampling(info->horizontal_scale) ? STBIR_DEFAULT_FILTER_UPSAMPLE : STBIR_DEFAULT_FILTER_DOWNSAMPLE;
    if (v_filter == 0)
        v_filter = stbir__use_upsampling(info->vertical_scale)   ? STBIR_DEFAULT_FILTER_UPSAMPLE : STBIR_DEFAULT_FILTER_DOWNSAMPLE;
    info->horizontal_filter = h_filter;
    info->vertical_filter = v_filter;
}

static stbir_uint32 stbir__calculate_memory(stbir__info *info)
{
    int pixel_margin = stbir__get_filter_pixel_margin(info->horizontal_filter, info->horizontal_scale);
    int filter_height = stbir__get_filter_pixel_width(info->vertical_filter, info->vertical_scale);

    info->horizontal_num_contributors = stbir__get_contributors(info->horizontal_scale, info->horizontal_filter, info->input_w, info->output_w);
    info->vertical_num_contributors   = stbir__get_contributors(info->vertical_scale  , info->vertical_filter  , info->input_h, info->output_h);

    info->horizontal_contributors_size = info->horizontal_num_contributors * sizeof(stbir__contributors);
    info->horizontal_coefficients_size = stbir__get_total_horizontal_coefficients(info) * sizeof(float);
    info->vertical_contributors_size = info->vertical_num_contributors * sizeof(stbir__contributors);
    info->vertical_coefficients_size = stbir__get_total_vertical_coefficients(info) * sizeof(float);
    info->decode_buffer_size = (info->input_w + pixel_margin * 2) * info->channels * sizeof(float);
    info->horizontal_buffer_size = info->output_w * info->channels * sizeof(float);
    info->ring_buffer_size = info->output_w * info->channels * filter_height * sizeof(float);
    info->encode_buffer_size = info->output_w * info->channels * sizeof(float);

    STBIR_ASSERT(info->horizontal_filter != 0);
    STBIR_ASSERT(info->horizontal_filter < STBIR__ARRAY_SIZE(stbir__filter_info_table)); // this now happens too late
    STBIR_ASSERT(info->vertical_filter != 0);
    STBIR_ASSERT(info->vertical_filter < STBIR__ARRAY_SIZE(stbir__filter_info_table)); // this now happens too late

    if (stbir__use_height_upsampling(info))
        // The horizontal buffer is for when we're downsampling the height and we
        // can't output the result of sampling the decode buffer directly into the
        // ring buffers.
        info->horizontal_buffer_size = 0;
    else
        // The encode buffer is to retain precision in the height upsampling method
        // and isn't used when height downsampling.
        info->encode_buffer_size = 0;

    return info->horizontal_contributors_size + info->horizontal_coefficients_size
        + info->vertical_contributors_size + info->vertical_coefficients_size
        + info->decode_buffer_size + info->horizontal_buffer_size
        + info->ring_buffer_size + info->encode_buffer_size;
}

static int stbir__resize_allocated(stbir__info *info,
    const void* input_data, int input_stride_in_bytes,
    void* output_data, int output_stride_in_bytes,
    int alpha_channel, stbir_uint32 flags, stbir_datatype type,
    stbir_edge edge_horizontal, stbir_edge edge_vertical, stbir_colorspace colorspace,
    void* tempmem, size_t tempmem_size_in_bytes)
{
    size_t memory_required = stbir__calculate_memory(info);

    int width_stride_input = input_stride_in_bytes ? input_stride_in_bytes : info->channels * info->input_w * stbir__type_size[type];
    int width_stride_output = output_stride_in_bytes ? output_stride_in_bytes : info->channels * info->output_w * stbir__type_size[type];

#ifdef STBIR_DEBUG_OVERWRITE_TEST
#define OVERWRITE_ARRAY_SIZE 8
    unsigned char overwrite_output_before_pre[OVERWRITE_ARRAY_SIZE];
    unsigned char overwrite_tempmem_before_pre[OVERWRITE_ARRAY_SIZE];
    unsigned char overwrite_output_after_pre[OVERWRITE_ARRAY_SIZE];
    unsigned char overwrite_tempmem_after_pre[OVERWRITE_ARRAY_SIZE];

    size_t begin_forbidden = width_stride_output * (info->output_h - 1) + info->output_w * info->channels * stbir__type_size[type];
    memcpy(overwrite_output_before_pre, &((unsigned char*)output_data)[-OVERWRITE_ARRAY_SIZE], OVERWRITE_ARRAY_SIZE);
    memcpy(overwrite_output_after_pre, &((unsigned char*)output_data)[begin_forbidden], OVERWRITE_ARRAY_SIZE);
    memcpy(overwrite_tempmem_before_pre, &((unsigned char*)tempmem)[-OVERWRITE_ARRAY_SIZE], OVERWRITE_ARRAY_SIZE);
    memcpy(overwrite_tempmem_after_pre, &((unsigned char*)tempmem)[tempmem_size_in_bytes], OVERWRITE_ARRAY_SIZE);
#endif

    STBIR_ASSERT(info->channels >= 0);
    STBIR_ASSERT(info->channels <= STBIR_MAX_CHANNELS);

    if (info->channels < 0 || info->channels > STBIR_MAX_CHANNELS)
        return 0;

    STBIR_ASSERT(info->horizontal_filter < STBIR__ARRAY_SIZE(stbir__filter_info_table));
    STBIR_ASSERT(info->vertical_filter < STBIR__ARRAY_SIZE(stbir__filter_info_table));

    if (info->horizontal_filter >= STBIR__ARRAY_SIZE(stbir__filter_info_table))
        return 0;
    if (info->vertical_filter >= STBIR__ARRAY_SIZE(stbir__filter_info_table))
        return 0;

    if (alpha_channel < 0)
        flags |= STBIR_FLAG_ALPHA_USES_COLORSPACE | STBIR_FLAG_ALPHA_PREMULTIPLIED;

    if (!(flags&STBIR_FLAG_ALPHA_USES_COLORSPACE) || !(flags&STBIR_FLAG_ALPHA_PREMULTIPLIED))
        STBIR_ASSERT(alpha_channel >= 0 && alpha_channel < info->channels);

    if (alpha_channel >= info->channels)
        return 0;

    STBIR_ASSERT(tempmem);

    if (!tempmem)
        return 0;

    STBIR_ASSERT(tempmem_size_in_bytes >= memory_required);

    if (tempmem_size_in_bytes < memory_required)
        return 0;

    memset(tempmem, 0, tempmem_size_in_bytes);

    info->input_data = input_data;
    info->input_stride_bytes = width_stride_input;

    info->output_data = output_data;
    info->output_stride_bytes = width_stride_output;

    info->alpha_channel = alpha_channel;
    info->flags = flags;
    info->type = type;
    info->edge_horizontal = edge_horizontal;
    info->edge_vertical = edge_vertical;
    info->colorspace = colorspace;

    info->horizontal_coefficient_width   = stbir__get_coefficient_width  (info->horizontal_filter, info->horizontal_scale);
    info->vertical_coefficient_width     = stbir__get_coefficient_width  (info->vertical_filter  , info->vertical_scale  );
    info->horizontal_filter_pixel_width  = stbir__get_filter_pixel_width (info->horizontal_filter, info->horizontal_scale);
    info->vertical_filter_pixel_width    = stbir__get_filter_pixel_width (info->vertical_filter  , info->vertical_scale  );
    info->horizontal_filter_pixel_margin = stbir__get_filter_pixel_margin(info->horizontal_filter, info->horizontal_scale);
    info->vertical_filter_pixel_margin   = stbir__get_filter_pixel_margin(info->vertical_filter  , info->vertical_scale  );

    info->ring_buffer_length_bytes = info->output_w * info->channels * sizeof(float);
    info->decode_buffer_pixels = info->input_w + info->horizontal_filter_pixel_margin * 2;

#define STBIR__NEXT_MEMPTR(current, newtype) (newtype*)(((unsigned char*)current) + current##_size)

    info->horizontal_contributors = (stbir__contributors *) tempmem;
    info->horizontal_coefficients = STBIR__NEXT_MEMPTR(info->horizontal_contributors, float);
    info->vertical_contributors = STBIR__NEXT_MEMPTR(info->horizontal_coefficients, stbir__contributors);
    info->vertical_coefficients = STBIR__NEXT_MEMPTR(info->vertical_contributors, float);
    info->decode_buffer = STBIR__NEXT_MEMPTR(info->vertical_coefficients, float);

    if (stbir__use_height_upsampling(info))
    {
        info->horizontal_buffer = NULL;
        info->ring_buffer = STBIR__NEXT_MEMPTR(info->decode_buffer, float);
        info->encode_buffer = STBIR__NEXT_MEMPTR(info->ring_buffer, float);

        STBIR_ASSERT((size_t)STBIR__NEXT_MEMPTR(info->encode_buffer, unsigned char) == (size_t)tempmem + tempmem_size_in_bytes);
    }
    else
    {
        info->horizontal_buffer = STBIR__NEXT_MEMPTR(info->decode_buffer, float);
        info->ring_buffer = STBIR__NEXT_MEMPTR(info->horizontal_buffer, float);
        info->encode_buffer = NULL;

        STBIR_ASSERT((size_t)STBIR__NEXT_MEMPTR(info->ring_buffer, unsigned char) == (size_t)tempmem + tempmem_size_in_bytes);
    }

#undef STBIR__NEXT_MEMPTR

    // This signals that the ring buffer is empty
    info->ring_buffer_begin_index = -1;

    stbir__calculate_filters(info, info->horizontal_contributors, info->horizontal_coefficients, info->horizontal_filter, info->horizontal_scale, info->horizontal_shift, info->input_w, info->output_w);
    stbir__calculate_filters(info, info->vertical_contributors, info->vertical_coefficients, info->vertical_filter, info->vertical_scale, info->vertical_shift, info->input_h, info->output_h);

    STBIR_PROGRESS_REPORT(0);

    if (stbir__use_height_upsampling(info))
        stbir__buffer_loop_upsample(info);
    else
        stbir__buffer_loop_downsample(info);

    STBIR_PROGRESS_REPORT(1);

#ifdef STBIR_DEBUG_OVERWRITE_TEST
    STBIR_ASSERT(memcmp(overwrite_output_before_pre, &((unsigned char*)output_data)[-OVERWRITE_ARRAY_SIZE], OVERWRITE_ARRAY_SIZE) == 0);
    STBIR_ASSERT(memcmp(overwrite_output_after_pre, &((unsigned char*)output_data)[begin_forbidden], OVERWRITE_ARRAY_SIZE) == 0);
    STBIR_ASSERT(memcmp(overwrite_tempmem_before_pre, &((unsigned char*)tempmem)[-OVERWRITE_ARRAY_SIZE], OVERWRITE_ARRAY_SIZE) == 0);
    STBIR_ASSERT(memcmp(overwrite_tempmem_after_pre, &((unsigned char*)tempmem)[tempmem_size_in_bytes], OVERWRITE_ARRAY_SIZE) == 0);
#endif

    return 1;
}


static int stbir__resize_arbitrary(
    void *alloc_context,
    const void* input_data, int input_w, int input_h, int input_stride_in_bytes,
    void* output_data, int output_w, int output_h, int output_stride_in_bytes,
    float s0, float t0, float s1, float t1, float *transform,
    int channels, int alpha_channel, stbir_uint32 flags, stbir_datatype type,
    stbir_filter h_filter, stbir_filter v_filter,
    stbir_edge edge_horizontal, stbir_edge edge_vertical, stbir_colorspace colorspace)
{
    stbir__info info;
    int result;
    size_t memory_required;
    void* extra_memory;

    stbir__setup(&info, input_w, input_h, output_w, output_h, channels);
    stbir__calculate_transform(&info, s0,t0,s1,t1,transform);
    stbir__choose_filter(&info, h_filter, v_filter);
    memory_required = stbir__calculate_memory(&info);
    extra_memory = STBIR_MALLOC(memory_required, alloc_context);

    if (!extra_memory)
        return 0;

    result = stbir__resize_allocated(&info, input_data, input_stride_in_bytes,
                                            output_data, output_stride_in_bytes, 
                                            alpha_channel, flags, type,
                                            edge_horizontal, edge_vertical,
                                            colorspace, extra_memory, memory_required);

    STBIR_FREE(extra_memory, alloc_context);

    return result;
}

STBIRDEF int stbir_resize_uint8(     const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels)
{
    return stbir__resize_arbitrary(NULL, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,-1,0, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR);
}

STBIRDEF int stbir_resize_float(     const float *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           float *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels)
{
    return stbir__resize_arbitrary(NULL, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,-1,0, STBIR_TYPE_FLOAT, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_LINEAR);
}

STBIRDEF int stbir_resize_uint8_srgb(const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                           unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                     int num_channels, int alpha_channel, int flags)
{
    return stbir__resize_arbitrary(NULL, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        STBIR_EDGE_CLAMP, STBIR_EDGE_CLAMP, STBIR_COLORSPACE_SRGB);
}

STBIRDEF int stbir_resize_uint8_srgb_edgemode(const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                                    unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                              int num_channels, int alpha_channel, int flags,
                                              stbir_edge edge_wrap_mode)
{
    return stbir__resize_arbitrary(NULL, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, STBIR_FILTER_DEFAULT, STBIR_FILTER_DEFAULT,
        edge_wrap_mode, edge_wrap_mode, STBIR_COLORSPACE_SRGB);
}

STBIRDEF int stbir_resize_uint8_generic( const unsigned char *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                               unsigned char *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, STBIR_TYPE_UINT8, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}

STBIRDEF int stbir_resize_uint16_generic(const stbir_uint16 *input_pixels  , int input_w , int input_h , int input_stride_in_bytes,
                                               stbir_uint16 *output_pixels , int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, STBIR_TYPE_UINT16, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}


STBIRDEF int stbir_resize_float_generic( const float *input_pixels         , int input_w , int input_h , int input_stride_in_bytes,
                                               float *output_pixels        , int output_w, int output_h, int output_stride_in_bytes,
                                         int num_channels, int alpha_channel, int flags,
                                         stbir_edge edge_wrap_mode, stbir_filter filter, stbir_colorspace space, 
                                         void *alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, STBIR_TYPE_FLOAT, filter, filter,
        edge_wrap_mode, edge_wrap_mode, space);
}


STBIRDEF int stbir_resize(         const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,NULL,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}


STBIRDEF int stbir_resize_subpixel(const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context,
                                   float x_scale, float y_scale,
                                   float x_offset, float y_offset)
{
    float transform[4];
    transform[0] = x_scale;
    transform[1] = y_scale;
    transform[2] = x_offset;
    transform[3] = y_offset;
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        0,0,1,1,transform,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}

STBIRDEF int stbir_resize_region(  const void *input_pixels , int input_w , int input_h , int input_stride_in_bytes,
                                         void *output_pixels, int output_w, int output_h, int output_stride_in_bytes,
                                   stbir_datatype datatype,
                                   int num_channels, int alpha_channel, int flags,
                                   stbir_edge edge_mode_horizontal, stbir_edge edge_mode_vertical, 
                                   stbir_filter filter_horizontal,  stbir_filter filter_vertical,
                                   stbir_colorspace space, void *alloc_context,
                                   float s0, float t0, float s1, float t1)
{
    return stbir__resize_arbitrary(alloc_context, input_pixels, input_w, input_h, input_stride_in_bytes,
        output_pixels, output_w, output_h, output_stride_in_bytes,
        s0,t0,s1,t1,NULL,num_channels,alpha_channel,flags, datatype, filter_horizontal, filter_vertical,
        edge_mode_horizontal, edge_mode_vertical, space);
}

#endif // STB_IMAGE_RESIZE_IMPLEMENTATION
