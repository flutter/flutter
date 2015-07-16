#ifndef __glxext_h_
#define __glxext_h_

#ifdef __cplusplus
extern "C" {
#endif

/*
** Copyright (c) 2007-2012 The Khronos Group Inc.
** 
** Permission is hereby granted, free of charge, to any person obtaining a
** copy of this software and/or associated documentation files (the
** "Materials"), to deal in the Materials without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Materials, and to
** permit persons to whom the Materials are furnished to do so, subject to
** the following conditions:
** 
** The above copyright notice and this permission notice shall be included
** in all copies or substantial portions of the Materials.
** 
** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
*/

/* Function declaration macros - to move into glplatform.h */

#if defined(_WIN32) && !defined(APIENTRY) && !defined(__CYGWIN__) && !defined(__SCITECH_SNAP__)
#define WIN32_LEAN_AND_MEAN 1
#include <windows.h>
#endif

#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef APIENTRYP
#define APIENTRYP APIENTRY *
#endif
#ifndef GLAPI
#define GLAPI extern
#endif

/*************************************************************/

/* Header file version number, required by OpenGL ABI for Linux */
/* glxext.h last updated 2012/02/29 */
/* Current version at http://www.opengl.org/registry/ */
#define GLX_GLXEXT_VERSION 33

#ifndef GLX_VERSION_1_3
#define GLX_WINDOW_BIT                     0x00000001
#define GLX_PIXMAP_BIT                     0x00000002
#define GLX_PBUFFER_BIT                    0x00000004
#define GLX_RGBA_BIT                       0x00000001
#define GLX_COLOR_INDEX_BIT                0x00000002
#define GLX_PBUFFER_CLOBBER_MASK           0x08000000
#define GLX_FRONT_LEFT_BUFFER_BIT          0x00000001
#define GLX_FRONT_RIGHT_BUFFER_BIT         0x00000002
#define GLX_BACK_LEFT_BUFFER_BIT           0x00000004
#define GLX_BACK_RIGHT_BUFFER_BIT          0x00000008
#define GLX_AUX_BUFFERS_BIT                0x00000010
#define GLX_DEPTH_BUFFER_BIT               0x00000020
#define GLX_STENCIL_BUFFER_BIT             0x00000040
#define GLX_ACCUM_BUFFER_BIT               0x00000080
#define GLX_CONFIG_CAVEAT                  0x20
#define GLX_X_VISUAL_TYPE                  0x22
#define GLX_TRANSPARENT_TYPE               0x23
#define GLX_TRANSPARENT_INDEX_VALUE        0x24
#define GLX_TRANSPARENT_RED_VALUE          0x25
#define GLX_TRANSPARENT_GREEN_VALUE        0x26
#define GLX_TRANSPARENT_BLUE_VALUE         0x27
#define GLX_TRANSPARENT_ALPHA_VALUE        0x28
#define GLX_DONT_CARE                      0xFFFFFFFF
#define GLX_NONE                           0x8000
#define GLX_SLOW_CONFIG                    0x8001
#define GLX_TRUE_COLOR                     0x8002
#define GLX_DIRECT_COLOR                   0x8003
#define GLX_PSEUDO_COLOR                   0x8004
#define GLX_STATIC_COLOR                   0x8005
#define GLX_GRAY_SCALE                     0x8006
#define GLX_STATIC_GRAY                    0x8007
#define GLX_TRANSPARENT_RGB                0x8008
#define GLX_TRANSPARENT_INDEX              0x8009
#define GLX_VISUAL_ID                      0x800B
#define GLX_SCREEN                         0x800C
#define GLX_NON_CONFORMANT_CONFIG          0x800D
#define GLX_DRAWABLE_TYPE                  0x8010
#define GLX_RENDER_TYPE                    0x8011
#define GLX_X_RENDERABLE                   0x8012
#define GLX_FBCONFIG_ID                    0x8013
#define GLX_RGBA_TYPE                      0x8014
#define GLX_COLOR_INDEX_TYPE               0x8015
#define GLX_MAX_PBUFFER_WIDTH              0x8016
#define GLX_MAX_PBUFFER_HEIGHT             0x8017
#define GLX_MAX_PBUFFER_PIXELS             0x8018
#define GLX_PRESERVED_CONTENTS             0x801B
#define GLX_LARGEST_PBUFFER                0x801C
#define GLX_WIDTH                          0x801D
#define GLX_HEIGHT                         0x801E
#define GLX_EVENT_MASK                     0x801F
#define GLX_DAMAGED                        0x8020
#define GLX_SAVED                          0x8021
#define GLX_WINDOW                         0x8022
#define GLX_PBUFFER                        0x8023
#define GLX_PBUFFER_HEIGHT                 0x8040
#define GLX_PBUFFER_WIDTH                  0x8041
#endif

#ifndef GLX_VERSION_1_4
#define GLX_SAMPLE_BUFFERS                 100000
#define GLX_SAMPLES                        100001
#endif

#ifndef GLX_ARB_get_proc_address
#endif

#ifndef GLX_ARB_multisample
#define GLX_SAMPLE_BUFFERS_ARB             100000
#define GLX_SAMPLES_ARB                    100001
#endif

#ifndef GLX_ARB_vertex_buffer_object
#define GLX_CONTEXT_ALLOW_BUFFER_BYTE_ORDER_MISMATCH_ARB 0x2095
#endif

#ifndef GLX_ARB_fbconfig_float
#define GLX_RGBA_FLOAT_TYPE_ARB            0x20B9
#define GLX_RGBA_FLOAT_BIT_ARB             0x00000004
#endif

#ifndef GLX_ARB_framebuffer_sRGB
#define GLX_FRAMEBUFFER_SRGB_CAPABLE_ARB   0x20B2
#endif

#ifndef GLX_ARB_create_context
#define GLX_CONTEXT_DEBUG_BIT_ARB          0x00000001
#define GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB 0x00000002
#define GLX_CONTEXT_MAJOR_VERSION_ARB      0x2091
#define GLX_CONTEXT_MINOR_VERSION_ARB      0x2092
#define GLX_CONTEXT_FLAGS_ARB              0x2094
#endif

#ifndef GLX_ARB_create_context_profile
#define GLX_CONTEXT_CORE_PROFILE_BIT_ARB   0x00000001
#define GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB 0x00000002
#define GLX_CONTEXT_PROFILE_MASK_ARB       0x9126
#endif

#ifndef GLX_ARB_create_context_robustness
#define GLX_CONTEXT_ROBUST_ACCESS_BIT_ARB  0x00000004
#define GLX_LOSE_CONTEXT_ON_RESET_ARB      0x8252
#define GLX_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB 0x8256
#define GLX_NO_RESET_NOTIFICATION_ARB      0x8261
#endif

#ifndef GLX_SGIS_multisample
#define GLX_SAMPLE_BUFFERS_SGIS            100000
#define GLX_SAMPLES_SGIS                   100001
#endif

#ifndef GLX_EXT_visual_info
#define GLX_X_VISUAL_TYPE_EXT              0x22
#define GLX_TRANSPARENT_TYPE_EXT           0x23
#define GLX_TRANSPARENT_INDEX_VALUE_EXT    0x24
#define GLX_TRANSPARENT_RED_VALUE_EXT      0x25
#define GLX_TRANSPARENT_GREEN_VALUE_EXT    0x26
#define GLX_TRANSPARENT_BLUE_VALUE_EXT     0x27
#define GLX_TRANSPARENT_ALPHA_VALUE_EXT    0x28
#define GLX_NONE_EXT                       0x8000
#define GLX_TRUE_COLOR_EXT                 0x8002
#define GLX_DIRECT_COLOR_EXT               0x8003
#define GLX_PSEUDO_COLOR_EXT               0x8004
#define GLX_STATIC_COLOR_EXT               0x8005
#define GLX_GRAY_SCALE_EXT                 0x8006
#define GLX_STATIC_GRAY_EXT                0x8007
#define GLX_TRANSPARENT_RGB_EXT            0x8008
#define GLX_TRANSPARENT_INDEX_EXT          0x8009
#endif

#ifndef GLX_SGI_swap_control
#endif

#ifndef GLX_SGI_video_sync
#endif

#ifndef GLX_SGI_make_current_read
#endif

#ifndef GLX_SGIX_video_source
#endif

#ifndef GLX_EXT_visual_rating
#define GLX_VISUAL_CAVEAT_EXT              0x20
#define GLX_SLOW_VISUAL_EXT                0x8001
#define GLX_NON_CONFORMANT_VISUAL_EXT      0x800D
/* reuse GLX_NONE_EXT */
#endif

#ifndef GLX_EXT_import_context
#define GLX_SHARE_CONTEXT_EXT              0x800A
#define GLX_VISUAL_ID_EXT                  0x800B
#define GLX_SCREEN_EXT                     0x800C
#endif

#ifndef GLX_SGIX_fbconfig
#define GLX_WINDOW_BIT_SGIX                0x00000001
#define GLX_PIXMAP_BIT_SGIX                0x00000002
#define GLX_RGBA_BIT_SGIX                  0x00000001
#define GLX_COLOR_INDEX_BIT_SGIX           0x00000002
#define GLX_DRAWABLE_TYPE_SGIX             0x8010
#define GLX_RENDER_TYPE_SGIX               0x8011
#define GLX_X_RENDERABLE_SGIX              0x8012
#define GLX_FBCONFIG_ID_SGIX               0x8013
#define GLX_RGBA_TYPE_SGIX                 0x8014
#define GLX_COLOR_INDEX_TYPE_SGIX          0x8015
/* reuse GLX_SCREEN_EXT */
#endif

#ifndef GLX_SGIX_pbuffer
#define GLX_PBUFFER_BIT_SGIX               0x00000004
#define GLX_BUFFER_CLOBBER_MASK_SGIX       0x08000000
#define GLX_FRONT_LEFT_BUFFER_BIT_SGIX     0x00000001
#define GLX_FRONT_RIGHT_BUFFER_BIT_SGIX    0x00000002
#define GLX_BACK_LEFT_BUFFER_BIT_SGIX      0x00000004
#define GLX_BACK_RIGHT_BUFFER_BIT_SGIX     0x00000008
#define GLX_AUX_BUFFERS_BIT_SGIX           0x00000010
#define GLX_DEPTH_BUFFER_BIT_SGIX          0x00000020
#define GLX_STENCIL_BUFFER_BIT_SGIX        0x00000040
#define GLX_ACCUM_BUFFER_BIT_SGIX          0x00000080
#define GLX_SAMPLE_BUFFERS_BIT_SGIX        0x00000100
#define GLX_MAX_PBUFFER_WIDTH_SGIX         0x8016
#define GLX_MAX_PBUFFER_HEIGHT_SGIX        0x8017
#define GLX_MAX_PBUFFER_PIXELS_SGIX        0x8018
#define GLX_OPTIMAL_PBUFFER_WIDTH_SGIX     0x8019
#define GLX_OPTIMAL_PBUFFER_HEIGHT_SGIX    0x801A
#define GLX_PRESERVED_CONTENTS_SGIX        0x801B
#define GLX_LARGEST_PBUFFER_SGIX           0x801C
#define GLX_WIDTH_SGIX                     0x801D
#define GLX_HEIGHT_SGIX                    0x801E
#define GLX_EVENT_MASK_SGIX                0x801F
#define GLX_DAMAGED_SGIX                   0x8020
#define GLX_SAVED_SGIX                     0x8021
#define GLX_WINDOW_SGIX                    0x8022
#define GLX_PBUFFER_SGIX                   0x8023
#endif

#ifndef GLX_SGI_cushion
#endif

#ifndef GLX_SGIX_video_resize
#define GLX_SYNC_FRAME_SGIX                0x00000000
#define GLX_SYNC_SWAP_SGIX                 0x00000001
#endif

#ifndef GLX_SGIX_dmbuffer
#define GLX_DIGITAL_MEDIA_PBUFFER_SGIX     0x8024
#endif

#ifndef GLX_SGIX_swap_group
#endif

#ifndef GLX_SGIX_swap_barrier
#endif

#ifndef GLX_SGIS_blended_overlay
#define GLX_BLENDED_RGBA_SGIS              0x8025
#endif

#ifndef GLX_SGIS_shared_multisample
#define GLX_MULTISAMPLE_SUB_RECT_WIDTH_SGIS 0x8026
#define GLX_MULTISAMPLE_SUB_RECT_HEIGHT_SGIS 0x8027
#endif

#ifndef GLX_SUN_get_transparent_index
#endif

#ifndef GLX_3DFX_multisample
#define GLX_SAMPLE_BUFFERS_3DFX            0x8050
#define GLX_SAMPLES_3DFX                   0x8051
#endif

#ifndef GLX_MESA_copy_sub_buffer
#endif

#ifndef GLX_MESA_pixmap_colormap
#endif

#ifndef GLX_MESA_release_buffers
#endif

#ifndef GLX_MESA_set_3dfx_mode
#define GLX_3DFX_WINDOW_MODE_MESA          0x1
#define GLX_3DFX_FULLSCREEN_MODE_MESA      0x2
#endif

#ifndef GLX_SGIX_visual_select_group
#define GLX_VISUAL_SELECT_GROUP_SGIX       0x8028
#endif

#ifndef GLX_OML_swap_method
#define GLX_SWAP_METHOD_OML                0x8060
#define GLX_SWAP_EXCHANGE_OML              0x8061
#define GLX_SWAP_COPY_OML                  0x8062
#define GLX_SWAP_UNDEFINED_OML             0x8063
#endif

#ifndef GLX_OML_sync_control
#endif

#ifndef GLX_NV_float_buffer
#define GLX_FLOAT_COMPONENTS_NV            0x20B0
#endif

#ifndef GLX_SGIX_hyperpipe
#define GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX 80
#define GLX_BAD_HYPERPIPE_CONFIG_SGIX      91
#define GLX_BAD_HYPERPIPE_SGIX             92
#define GLX_HYPERPIPE_DISPLAY_PIPE_SGIX    0x00000001
#define GLX_HYPERPIPE_RENDER_PIPE_SGIX     0x00000002
#define GLX_PIPE_RECT_SGIX                 0x00000001
#define GLX_PIPE_RECT_LIMITS_SGIX          0x00000002
#define GLX_HYPERPIPE_STEREO_SGIX          0x00000003
#define GLX_HYPERPIPE_PIXEL_AVERAGE_SGIX   0x00000004
#define GLX_HYPERPIPE_ID_SGIX              0x8030
#endif

#ifndef GLX_MESA_agp_offset
#endif

#ifndef GLX_EXT_fbconfig_packed_float
#define GLX_RGBA_UNSIGNED_FLOAT_TYPE_EXT   0x20B1
#define GLX_RGBA_UNSIGNED_FLOAT_BIT_EXT    0x00000008
#endif

#ifndef GLX_EXT_framebuffer_sRGB
#define GLX_FRAMEBUFFER_SRGB_CAPABLE_EXT   0x20B2
#endif

#ifndef GLX_EXT_texture_from_pixmap
#define GLX_TEXTURE_1D_BIT_EXT             0x00000001
#define GLX_TEXTURE_2D_BIT_EXT             0x00000002
#define GLX_TEXTURE_RECTANGLE_BIT_EXT      0x00000004
#define GLX_BIND_TO_TEXTURE_RGB_EXT        0x20D0
#define GLX_BIND_TO_TEXTURE_RGBA_EXT       0x20D1
#define GLX_BIND_TO_MIPMAP_TEXTURE_EXT     0x20D2
#define GLX_BIND_TO_TEXTURE_TARGETS_EXT    0x20D3
#define GLX_Y_INVERTED_EXT                 0x20D4
#define GLX_TEXTURE_FORMAT_EXT             0x20D5
#define GLX_TEXTURE_TARGET_EXT             0x20D6
#define GLX_MIPMAP_TEXTURE_EXT             0x20D7
#define GLX_TEXTURE_FORMAT_NONE_EXT        0x20D8
#define GLX_TEXTURE_FORMAT_RGB_EXT         0x20D9
#define GLX_TEXTURE_FORMAT_RGBA_EXT        0x20DA
#define GLX_TEXTURE_1D_EXT                 0x20DB
#define GLX_TEXTURE_2D_EXT                 0x20DC
#define GLX_TEXTURE_RECTANGLE_EXT          0x20DD
#define GLX_FRONT_LEFT_EXT                 0x20DE
#define GLX_FRONT_RIGHT_EXT                0x20DF
#define GLX_BACK_LEFT_EXT                  0x20E0
#define GLX_BACK_RIGHT_EXT                 0x20E1
#define GLX_FRONT_EXT                      GLX_FRONT_LEFT_EXT
#define GLX_BACK_EXT                       GLX_BACK_LEFT_EXT
#define GLX_AUX0_EXT                       0x20E2
#define GLX_AUX1_EXT                       0x20E3
#define GLX_AUX2_EXT                       0x20E4
#define GLX_AUX3_EXT                       0x20E5
#define GLX_AUX4_EXT                       0x20E6
#define GLX_AUX5_EXT                       0x20E7
#define GLX_AUX6_EXT                       0x20E8
#define GLX_AUX7_EXT                       0x20E9
#define GLX_AUX8_EXT                       0x20EA
#define GLX_AUX9_EXT                       0x20EB
#endif

#ifndef GLX_NV_present_video
#define GLX_NUM_VIDEO_SLOTS_NV             0x20F0
#endif

#ifndef GLX_NV_video_out
#define GLX_VIDEO_OUT_COLOR_NV             0x20C3
#define GLX_VIDEO_OUT_ALPHA_NV             0x20C4
#define GLX_VIDEO_OUT_DEPTH_NV             0x20C5
#define GLX_VIDEO_OUT_COLOR_AND_ALPHA_NV   0x20C6
#define GLX_VIDEO_OUT_COLOR_AND_DEPTH_NV   0x20C7
#define GLX_VIDEO_OUT_FRAME_NV             0x20C8
#define GLX_VIDEO_OUT_FIELD_1_NV           0x20C9
#define GLX_VIDEO_OUT_FIELD_2_NV           0x20CA
#define GLX_VIDEO_OUT_STACKED_FIELDS_1_2_NV 0x20CB
#define GLX_VIDEO_OUT_STACKED_FIELDS_2_1_NV 0x20CC
#endif

#ifndef GLX_NV_swap_group
#endif

#ifndef GLX_NV_video_capture
#define GLX_DEVICE_ID_NV                   0x20CD
#define GLX_UNIQUE_ID_NV                   0x20CE
#define GLX_NUM_VIDEO_CAPTURE_SLOTS_NV     0x20CF
#endif

#ifndef GLX_EXT_swap_control
#define GLX_SWAP_INTERVAL_EXT              0x20F1
#define GLX_MAX_SWAP_INTERVAL_EXT          0x20F2
#endif

#ifndef GLX_NV_copy_image
#endif

#ifndef GLX_INTEL_swap_event
#define GLX_BUFFER_SWAP_COMPLETE_INTEL_MASK 0x04000000
#define GLX_EXCHANGE_COMPLETE_INTEL        0x8180
#define GLX_COPY_COMPLETE_INTEL            0x8181
#define GLX_FLIP_COMPLETE_INTEL            0x8182
#endif

#ifndef GLX_NV_multisample_coverage
#define GLX_COVERAGE_SAMPLES_NV            100001
#define GLX_COLOR_SAMPLES_NV               0x20B3
#endif

#ifndef GLX_AMD_gpu_association
#define GLX_GPU_VENDOR_AMD                 0x1F00
#define GLX_GPU_RENDERER_STRING_AMD        0x1F01
#define GLX_GPU_OPENGL_VERSION_STRING_AMD  0x1F02
#define GLX_GPU_FASTEST_TARGET_GPUS_AMD    0x21A2
#define GLX_GPU_RAM_AMD                    0x21A3
#define GLX_GPU_CLOCK_AMD                  0x21A4
#define GLX_GPU_NUM_PIPES_AMD              0x21A5
#define GLX_GPU_NUM_SIMD_AMD               0x21A6
#define GLX_GPU_NUM_RB_AMD                 0x21A7
#define GLX_GPU_NUM_SPI_AMD                0x21A8
#endif

#ifndef GLX_EXT_create_context_es2_profile
#define GLX_CONTEXT_ES2_PROFILE_BIT_EXT    0x00000004
#endif

#ifndef GLX_EXT_swap_control_tear
#define GLX_LATE_SWAPS_TEAR_EXT            0x20F3
#endif


/*************************************************************/

#ifndef GLX_ARB_get_proc_address
typedef void (*__GLXextFuncPtr)(void);
#endif

#ifndef GLX_SGIX_video_source
typedef XID GLXVideoSourceSGIX;
#endif

#ifndef GLX_SGIX_fbconfig
typedef XID GLXFBConfigIDSGIX;
typedef struct __GLXFBConfigRec *GLXFBConfigSGIX;
#endif

#ifndef GLX_SGIX_pbuffer
typedef XID GLXPbufferSGIX;
typedef struct {
    int type;
    unsigned long serial;	  /* # of last request processed by server */
    Bool send_event;		  /* true if this came for SendEvent request */
    Display *display;		  /* display the event was read from */
    GLXDrawable drawable;	  /* i.d. of Drawable */
    int event_type;		  /* GLX_DAMAGED_SGIX or GLX_SAVED_SGIX */
    int draw_type;		  /* GLX_WINDOW_SGIX or GLX_PBUFFER_SGIX */
    unsigned int mask;	  /* mask indicating which buffers are affected*/
    int x, y;
    int width, height;
    int count;		  /* if nonzero, at least this many more */
} GLXBufferClobberEventSGIX;
#endif

#ifndef GLX_NV_video_output
typedef unsigned int GLXVideoDeviceNV;
#endif

#ifndef GLX_NV_video_capture
typedef XID GLXVideoCaptureDeviceNV;
#endif

#ifndef GLEXT_64_TYPES_DEFINED
/* This code block is duplicated in glext.h, so must be protected */
#define GLEXT_64_TYPES_DEFINED
/* Define int32_t, int64_t, and uint64_t types for UST/MSC */
/* (as used in the GLX_OML_sync_control extension). */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#include <inttypes.h>
#elif defined(__sun__) || defined(__digital__)
#include <inttypes.h>
#if defined(__STDC__)
#if defined(__arch64__) || defined(_LP64)
typedef long int int64_t;
typedef unsigned long int uint64_t;
#else
typedef long long int int64_t;
typedef unsigned long long int uint64_t;
#endif /* __arch64__ */
#endif /* __STDC__ */
#elif defined( __VMS ) || defined(__sgi)
#include <inttypes.h>
#elif defined(__SCO__) || defined(__USLC__)
#include <stdint.h>
#elif defined(__UNIXOS2__) || defined(__SOL64__)
typedef long int int32_t;
typedef long long int int64_t;
typedef unsigned long long int uint64_t;
#elif defined(_WIN32) && defined(__GNUC__)
#include <stdint.h>
#elif defined(_WIN32)
typedef __int32 int32_t;
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#else
#include <inttypes.h>     /* Fallback option */
#endif
#endif

#ifndef GLX_VERSION_1_3
#define GLX_VERSION_1_3 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXFBConfig * glXGetFBConfigs (Display *dpy, int screen, int *nelements);
extern GLXFBConfig * glXChooseFBConfig (Display *dpy, int screen, const int *attrib_list, int *nelements);
extern int glXGetFBConfigAttrib (Display *dpy, GLXFBConfig config, int attribute, int *value);
extern XVisualInfo * glXGetVisualFromFBConfig (Display *dpy, GLXFBConfig config);
extern GLXWindow glXCreateWindow (Display *dpy, GLXFBConfig config, Window win, const int *attrib_list);
extern void glXDestroyWindow (Display *dpy, GLXWindow win);
extern GLXPixmap glXCreatePixmap (Display *dpy, GLXFBConfig config, Pixmap pixmap, const int *attrib_list);
extern void glXDestroyPixmap (Display *dpy, GLXPixmap pixmap);
extern GLXPbuffer glXCreatePbuffer (Display *dpy, GLXFBConfig config, const int *attrib_list);
extern void glXDestroyPbuffer (Display *dpy, GLXPbuffer pbuf);
extern void glXQueryDrawable (Display *dpy, GLXDrawable draw, int attribute, unsigned int *value);
extern GLXContext glXCreateNewContext (Display *dpy, GLXFBConfig config, int render_type, GLXContext share_list, Bool direct);
extern Bool glXMakeContextCurrent (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
extern GLXDrawable glXGetCurrentReadDrawable (void);
extern Display * glXGetCurrentDisplay (void);
extern int glXQueryContext (Display *dpy, GLXContext ctx, int attribute, int *value);
extern void glXSelectEvent (Display *dpy, GLXDrawable draw, unsigned long event_mask);
extern void glXGetSelectedEvent (Display *dpy, GLXDrawable draw, unsigned long *event_mask);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXFBConfig * ( * PFNGLXGETFBCONFIGSPROC) (Display *dpy, int screen, int *nelements);
typedef GLXFBConfig * ( * PFNGLXCHOOSEFBCONFIGPROC) (Display *dpy, int screen, const int *attrib_list, int *nelements);
typedef int ( * PFNGLXGETFBCONFIGATTRIBPROC) (Display *dpy, GLXFBConfig config, int attribute, int *value);
typedef XVisualInfo * ( * PFNGLXGETVISUALFROMFBCONFIGPROC) (Display *dpy, GLXFBConfig config);
typedef GLXWindow ( * PFNGLXCREATEWINDOWPROC) (Display *dpy, GLXFBConfig config, Window win, const int *attrib_list);
typedef void ( * PFNGLXDESTROYWINDOWPROC) (Display *dpy, GLXWindow win);
typedef GLXPixmap ( * PFNGLXCREATEPIXMAPPROC) (Display *dpy, GLXFBConfig config, Pixmap pixmap, const int *attrib_list);
typedef void ( * PFNGLXDESTROYPIXMAPPROC) (Display *dpy, GLXPixmap pixmap);
typedef GLXPbuffer ( * PFNGLXCREATEPBUFFERPROC) (Display *dpy, GLXFBConfig config, const int *attrib_list);
typedef void ( * PFNGLXDESTROYPBUFFERPROC) (Display *dpy, GLXPbuffer pbuf);
typedef void ( * PFNGLXQUERYDRAWABLEPROC) (Display *dpy, GLXDrawable draw, int attribute, unsigned int *value);
typedef GLXContext ( * PFNGLXCREATENEWCONTEXTPROC) (Display *dpy, GLXFBConfig config, int render_type, GLXContext share_list, Bool direct);
typedef Bool ( * PFNGLXMAKECONTEXTCURRENTPROC) (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
typedef GLXDrawable ( * PFNGLXGETCURRENTREADDRAWABLEPROC) (void);
typedef Display * ( * PFNGLXGETCURRENTDISPLAYPROC) (void);
typedef int ( * PFNGLXQUERYCONTEXTPROC) (Display *dpy, GLXContext ctx, int attribute, int *value);
typedef void ( * PFNGLXSELECTEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long event_mask);
typedef void ( * PFNGLXGETSELECTEDEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long *event_mask);
#endif

#ifndef GLX_VERSION_1_4
#define GLX_VERSION_1_4 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern __GLXextFuncPtr glXGetProcAddress (const GLubyte *procName);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef __GLXextFuncPtr ( * PFNGLXGETPROCADDRESSPROC) (const GLubyte *procName);
#endif

#ifndef GLX_ARB_get_proc_address
#define GLX_ARB_get_proc_address 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern __GLXextFuncPtr glXGetProcAddressARB (const GLubyte *procName);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef __GLXextFuncPtr ( * PFNGLXGETPROCADDRESSARBPROC) (const GLubyte *procName);
#endif

#ifndef GLX_ARB_multisample
#define GLX_ARB_multisample 1
#endif

#ifndef GLX_ARB_fbconfig_float
#define GLX_ARB_fbconfig_float 1
#endif

#ifndef GLX_ARB_framebuffer_sRGB
#define GLX_ARB_framebuffer_sRGB 1
#endif

#ifndef GLX_ARB_create_context
#define GLX_ARB_create_context 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXContext glXCreateContextAttribsARB (Display *dpy, GLXFBConfig config, GLXContext share_context, Bool direct, const int *attrib_list);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXContext ( * PFNGLXCREATECONTEXTATTRIBSARBPROC) (Display *dpy, GLXFBConfig config, GLXContext share_context, Bool direct, const int *attrib_list);
#endif

#ifndef GLX_ARB_create_context_profile
#define GLX_ARB_create_context_profile 1
#endif

#ifndef GLX_ARB_create_context_robustness
#define GLX_ARB_create_context_robustness 1
#endif

#ifndef GLX_SGIS_multisample
#define GLX_SGIS_multisample 1
#endif

#ifndef GLX_EXT_visual_info
#define GLX_EXT_visual_info 1
#endif

#ifndef GLX_SGI_swap_control
#define GLX_SGI_swap_control 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXSwapIntervalSGI (int interval);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXSWAPINTERVALSGIPROC) (int interval);
#endif

#ifndef GLX_SGI_video_sync
#define GLX_SGI_video_sync 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXGetVideoSyncSGI (unsigned int *count);
extern int glXWaitVideoSyncSGI (int divisor, int remainder, unsigned int *count);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXGETVIDEOSYNCSGIPROC) (unsigned int *count);
typedef int ( * PFNGLXWAITVIDEOSYNCSGIPROC) (int divisor, int remainder, unsigned int *count);
#endif

#ifndef GLX_SGI_make_current_read
#define GLX_SGI_make_current_read 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXMakeCurrentReadSGI (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
extern GLXDrawable glXGetCurrentReadDrawableSGI (void);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXMAKECURRENTREADSGIPROC) (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
typedef GLXDrawable ( * PFNGLXGETCURRENTREADDRAWABLESGIPROC) (void);
#endif

#ifndef GLX_SGIX_video_source
#define GLX_SGIX_video_source 1
#ifdef _VL_H
#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXVideoSourceSGIX glXCreateGLXVideoSourceSGIX (Display *display, int screen, VLServer server, VLPath path, int nodeClass, VLNode drainNode);
extern void glXDestroyGLXVideoSourceSGIX (Display *dpy, GLXVideoSourceSGIX glxvideosource);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXVideoSourceSGIX ( * PFNGLXCREATEGLXVIDEOSOURCESGIXPROC) (Display *display, int screen, VLServer server, VLPath path, int nodeClass, VLNode drainNode);
typedef void ( * PFNGLXDESTROYGLXVIDEOSOURCESGIXPROC) (Display *dpy, GLXVideoSourceSGIX glxvideosource);
#endif /* _VL_H */
#endif

#ifndef GLX_EXT_visual_rating
#define GLX_EXT_visual_rating 1
#endif

#ifndef GLX_EXT_import_context
#define GLX_EXT_import_context 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Display * glXGetCurrentDisplayEXT (void);
extern int glXQueryContextInfoEXT (Display *dpy, GLXContext context, int attribute, int *value);
extern GLXContextID glXGetContextIDEXT (const GLXContext context);
extern GLXContext glXImportContextEXT (Display *dpy, GLXContextID contextID);
extern void glXFreeContextEXT (Display *dpy, GLXContext context);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Display * ( * PFNGLXGETCURRENTDISPLAYEXTPROC) (void);
typedef int ( * PFNGLXQUERYCONTEXTINFOEXTPROC) (Display *dpy, GLXContext context, int attribute, int *value);
typedef GLXContextID ( * PFNGLXGETCONTEXTIDEXTPROC) (const GLXContext context);
typedef GLXContext ( * PFNGLXIMPORTCONTEXTEXTPROC) (Display *dpy, GLXContextID contextID);
typedef void ( * PFNGLXFREECONTEXTEXTPROC) (Display *dpy, GLXContext context);
#endif

#ifndef GLX_SGIX_fbconfig
#define GLX_SGIX_fbconfig 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXGetFBConfigAttribSGIX (Display *dpy, GLXFBConfigSGIX config, int attribute, int *value);
extern GLXFBConfigSGIX * glXChooseFBConfigSGIX (Display *dpy, int screen, int *attrib_list, int *nelements);
extern GLXPixmap glXCreateGLXPixmapWithConfigSGIX (Display *dpy, GLXFBConfigSGIX config, Pixmap pixmap);
extern GLXContext glXCreateContextWithConfigSGIX (Display *dpy, GLXFBConfigSGIX config, int render_type, GLXContext share_list, Bool direct);
extern XVisualInfo * glXGetVisualFromFBConfigSGIX (Display *dpy, GLXFBConfigSGIX config);
extern GLXFBConfigSGIX glXGetFBConfigFromVisualSGIX (Display *dpy, XVisualInfo *vis);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXGETFBCONFIGATTRIBSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, int attribute, int *value);
typedef GLXFBConfigSGIX * ( * PFNGLXCHOOSEFBCONFIGSGIXPROC) (Display *dpy, int screen, int *attrib_list, int *nelements);
typedef GLXPixmap ( * PFNGLXCREATEGLXPIXMAPWITHCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, Pixmap pixmap);
typedef GLXContext ( * PFNGLXCREATECONTEXTWITHCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, int render_type, GLXContext share_list, Bool direct);
typedef XVisualInfo * ( * PFNGLXGETVISUALFROMFBCONFIGSGIXPROC) (Display *dpy, GLXFBConfigSGIX config);
typedef GLXFBConfigSGIX ( * PFNGLXGETFBCONFIGFROMVISUALSGIXPROC) (Display *dpy, XVisualInfo *vis);
#endif

#ifndef GLX_SGIX_pbuffer
#define GLX_SGIX_pbuffer 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXPbufferSGIX glXCreateGLXPbufferSGIX (Display *dpy, GLXFBConfigSGIX config, unsigned int width, unsigned int height, int *attrib_list);
extern void glXDestroyGLXPbufferSGIX (Display *dpy, GLXPbufferSGIX pbuf);
extern int glXQueryGLXPbufferSGIX (Display *dpy, GLXPbufferSGIX pbuf, int attribute, unsigned int *value);
extern void glXSelectEventSGIX (Display *dpy, GLXDrawable drawable, unsigned long mask);
extern void glXGetSelectedEventSGIX (Display *dpy, GLXDrawable drawable, unsigned long *mask);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXPbufferSGIX ( * PFNGLXCREATEGLXPBUFFERSGIXPROC) (Display *dpy, GLXFBConfigSGIX config, unsigned int width, unsigned int height, int *attrib_list);
typedef void ( * PFNGLXDESTROYGLXPBUFFERSGIXPROC) (Display *dpy, GLXPbufferSGIX pbuf);
typedef int ( * PFNGLXQUERYGLXPBUFFERSGIXPROC) (Display *dpy, GLXPbufferSGIX pbuf, int attribute, unsigned int *value);
typedef void ( * PFNGLXSELECTEVENTSGIXPROC) (Display *dpy, GLXDrawable drawable, unsigned long mask);
typedef void ( * PFNGLXGETSELECTEDEVENTSGIXPROC) (Display *dpy, GLXDrawable drawable, unsigned long *mask);
#endif

#ifndef GLX_SGI_cushion
#define GLX_SGI_cushion 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXCushionSGI (Display *dpy, Window window, float cushion);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXCUSHIONSGIPROC) (Display *dpy, Window window, float cushion);
#endif

#ifndef GLX_SGIX_video_resize
#define GLX_SGIX_video_resize 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXBindChannelToWindowSGIX (Display *display, int screen, int channel, Window window);
extern int glXChannelRectSGIX (Display *display, int screen, int channel, int x, int y, int w, int h);
extern int glXQueryChannelRectSGIX (Display *display, int screen, int channel, int *dx, int *dy, int *dw, int *dh);
extern int glXQueryChannelDeltasSGIX (Display *display, int screen, int channel, int *x, int *y, int *w, int *h);
extern int glXChannelRectSyncSGIX (Display *display, int screen, int channel, GLenum synctype);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXBINDCHANNELTOWINDOWSGIXPROC) (Display *display, int screen, int channel, Window window);
typedef int ( * PFNGLXCHANNELRECTSGIXPROC) (Display *display, int screen, int channel, int x, int y, int w, int h);
typedef int ( * PFNGLXQUERYCHANNELRECTSGIXPROC) (Display *display, int screen, int channel, int *dx, int *dy, int *dw, int *dh);
typedef int ( * PFNGLXQUERYCHANNELDELTASSGIXPROC) (Display *display, int screen, int channel, int *x, int *y, int *w, int *h);
typedef int ( * PFNGLXCHANNELRECTSYNCSGIXPROC) (Display *display, int screen, int channel, GLenum synctype);
#endif

#ifndef GLX_SGIX_dmbuffer
#define GLX_SGIX_dmbuffer 1
#ifdef _DM_BUFFER_H_
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXAssociateDMPbufferSGIX (Display *dpy, GLXPbufferSGIX pbuffer, DMparams *params, DMbuffer dmbuffer);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXASSOCIATEDMPBUFFERSGIXPROC) (Display *dpy, GLXPbufferSGIX pbuffer, DMparams *params, DMbuffer dmbuffer);
#endif /* _DM_BUFFER_H_ */
#endif

#ifndef GLX_SGIX_swap_group
#define GLX_SGIX_swap_group 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXJoinSwapGroupSGIX (Display *dpy, GLXDrawable drawable, GLXDrawable member);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXJOINSWAPGROUPSGIXPROC) (Display *dpy, GLXDrawable drawable, GLXDrawable member);
#endif

#ifndef GLX_SGIX_swap_barrier
#define GLX_SGIX_swap_barrier 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXBindSwapBarrierSGIX (Display *dpy, GLXDrawable drawable, int barrier);
extern Bool glXQueryMaxSwapBarriersSGIX (Display *dpy, int screen, int *max);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXBINDSWAPBARRIERSGIXPROC) (Display *dpy, GLXDrawable drawable, int barrier);
typedef Bool ( * PFNGLXQUERYMAXSWAPBARRIERSSGIXPROC) (Display *dpy, int screen, int *max);
#endif

#ifndef GLX_SUN_get_transparent_index
#define GLX_SUN_get_transparent_index 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Status glXGetTransparentIndexSUN (Display *dpy, Window overlay, Window underlay, long *pTransparentIndex);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Status ( * PFNGLXGETTRANSPARENTINDEXSUNPROC) (Display *dpy, Window overlay, Window underlay, long *pTransparentIndex);
#endif

#ifndef GLX_MESA_copy_sub_buffer
#define GLX_MESA_copy_sub_buffer 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXCopySubBufferMESA (Display *dpy, GLXDrawable drawable, int x, int y, int width, int height);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXCOPYSUBBUFFERMESAPROC) (Display *dpy, GLXDrawable drawable, int x, int y, int width, int height);
#endif

#ifndef GLX_MESA_pixmap_colormap
#define GLX_MESA_pixmap_colormap 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXPixmap glXCreateGLXPixmapMESA (Display *dpy, XVisualInfo *visual, Pixmap pixmap, Colormap cmap);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXPixmap ( * PFNGLXCREATEGLXPIXMAPMESAPROC) (Display *dpy, XVisualInfo *visual, Pixmap pixmap, Colormap cmap);
#endif

#ifndef GLX_MESA_release_buffers
#define GLX_MESA_release_buffers 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXReleaseBuffersMESA (Display *dpy, GLXDrawable drawable);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXRELEASEBUFFERSMESAPROC) (Display *dpy, GLXDrawable drawable);
#endif

#ifndef GLX_MESA_set_3dfx_mode
#define GLX_MESA_set_3dfx_mode 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXSet3DfxModeMESA (int mode);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXSET3DFXMODEMESAPROC) (int mode);
#endif

#ifndef GLX_SGIX_visual_select_group
#define GLX_SGIX_visual_select_group 1
#endif

#ifndef GLX_OML_swap_method
#define GLX_OML_swap_method 1
#endif

#ifndef GLX_OML_sync_control
#define GLX_OML_sync_control 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXGetSyncValuesOML (Display *dpy, GLXDrawable drawable, int64_t *ust, int64_t *msc, int64_t *sbc);
extern Bool glXGetMscRateOML (Display *dpy, GLXDrawable drawable, int32_t *numerator, int32_t *denominator);
extern int64_t glXSwapBuffersMscOML (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder);
extern Bool glXWaitForMscOML (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder, int64_t *ust, int64_t *msc, int64_t *sbc);
extern Bool glXWaitForSbcOML (Display *dpy, GLXDrawable drawable, int64_t target_sbc, int64_t *ust, int64_t *msc, int64_t *sbc);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXGETSYNCVALUESOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t *ust, int64_t *msc, int64_t *sbc);
typedef Bool ( * PFNGLXGETMSCRATEOMLPROC) (Display *dpy, GLXDrawable drawable, int32_t *numerator, int32_t *denominator);
typedef int64_t ( * PFNGLXSWAPBUFFERSMSCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder);
typedef Bool ( * PFNGLXWAITFORMSCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_msc, int64_t divisor, int64_t remainder, int64_t *ust, int64_t *msc, int64_t *sbc);
typedef Bool ( * PFNGLXWAITFORSBCOMLPROC) (Display *dpy, GLXDrawable drawable, int64_t target_sbc, int64_t *ust, int64_t *msc, int64_t *sbc);
#endif

#ifndef GLX_NV_float_buffer
#define GLX_NV_float_buffer 1
#endif

#ifndef GLX_SGIX_hyperpipe
#define GLX_SGIX_hyperpipe 1

typedef struct {
    char    pipeName[GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX];
    int     networkId;
} GLXHyperpipeNetworkSGIX;

typedef struct {
    char    pipeName[GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX];
    int     channel;
    unsigned int
      participationType;
    int     timeSlice;
} GLXHyperpipeConfigSGIX;

typedef struct {
    char pipeName[GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX];
    int srcXOrigin, srcYOrigin, srcWidth, srcHeight;
    int destXOrigin, destYOrigin, destWidth, destHeight;
} GLXPipeRect;

typedef struct {
    char pipeName[GLX_HYPERPIPE_PIPE_NAME_LENGTH_SGIX];
    int XOrigin, YOrigin, maxHeight, maxWidth;
} GLXPipeRectLimits;

#ifdef GLX_GLXEXT_PROTOTYPES
extern GLXHyperpipeNetworkSGIX * glXQueryHyperpipeNetworkSGIX (Display *dpy, int *npipes);
extern int glXHyperpipeConfigSGIX (Display *dpy, int networkId, int npipes, GLXHyperpipeConfigSGIX *cfg, int *hpId);
extern GLXHyperpipeConfigSGIX * glXQueryHyperpipeConfigSGIX (Display *dpy, int hpId, int *npipes);
extern int glXDestroyHyperpipeConfigSGIX (Display *dpy, int hpId);
extern int glXBindHyperpipeSGIX (Display *dpy, int hpId);
extern int glXQueryHyperpipeBestAttribSGIX (Display *dpy, int timeSlice, int attrib, int size, void *attribList, void *returnAttribList);
extern int glXHyperpipeAttribSGIX (Display *dpy, int timeSlice, int attrib, int size, void *attribList);
extern int glXQueryHyperpipeAttribSGIX (Display *dpy, int timeSlice, int attrib, int size, void *returnAttribList);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef GLXHyperpipeNetworkSGIX * ( * PFNGLXQUERYHYPERPIPENETWORKSGIXPROC) (Display *dpy, int *npipes);
typedef int ( * PFNGLXHYPERPIPECONFIGSGIXPROC) (Display *dpy, int networkId, int npipes, GLXHyperpipeConfigSGIX *cfg, int *hpId);
typedef GLXHyperpipeConfigSGIX * ( * PFNGLXQUERYHYPERPIPECONFIGSGIXPROC) (Display *dpy, int hpId, int *npipes);
typedef int ( * PFNGLXDESTROYHYPERPIPECONFIGSGIXPROC) (Display *dpy, int hpId);
typedef int ( * PFNGLXBINDHYPERPIPESGIXPROC) (Display *dpy, int hpId);
typedef int ( * PFNGLXQUERYHYPERPIPEBESTATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *attribList, void *returnAttribList);
typedef int ( * PFNGLXHYPERPIPEATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *attribList);
typedef int ( * PFNGLXQUERYHYPERPIPEATTRIBSGIXPROC) (Display *dpy, int timeSlice, int attrib, int size, void *returnAttribList);
#endif

#ifndef GLX_MESA_agp_offset
#define GLX_MESA_agp_offset 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern unsigned int glXGetAGPOffsetMESA (const void *pointer);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef unsigned int ( * PFNGLXGETAGPOFFSETMESAPROC) (const void *pointer);
#endif

#ifndef GLX_EXT_fbconfig_packed_float
#define GLX_EXT_fbconfig_packed_float 1
#endif

#ifndef GLX_EXT_framebuffer_sRGB
#define GLX_EXT_framebuffer_sRGB 1
#endif

#ifndef GLX_EXT_texture_from_pixmap
#define GLX_EXT_texture_from_pixmap 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXBindTexImageEXT (Display *dpy, GLXDrawable drawable, int buffer, const int *attrib_list);
extern void glXReleaseTexImageEXT (Display *dpy, GLXDrawable drawable, int buffer);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXBINDTEXIMAGEEXTPROC) (Display *dpy, GLXDrawable drawable, int buffer, const int *attrib_list);
typedef void ( * PFNGLXRELEASETEXIMAGEEXTPROC) (Display *dpy, GLXDrawable drawable, int buffer);
#endif

#ifndef GLX_NV_present_video
#define GLX_NV_present_video 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern unsigned int * glXEnumerateVideoDevicesNV (Display *dpy, int screen, int *nelements);
extern int glXBindVideoDeviceNV (Display *dpy, unsigned int video_slot, unsigned int video_device, const int *attrib_list);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef unsigned int * ( * PFNGLXENUMERATEVIDEODEVICESNVPROC) (Display *dpy, int screen, int *nelements);
typedef int ( * PFNGLXBINDVIDEODEVICENVPROC) (Display *dpy, unsigned int video_slot, unsigned int video_device, const int *attrib_list);
#endif

#ifndef GLX_NV_video_output
#define GLX_NV_video_output 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXGetVideoDeviceNV (Display *dpy, int screen, int numVideoDevices, GLXVideoDeviceNV *pVideoDevice);
extern int glXReleaseVideoDeviceNV (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice);
extern int glXBindVideoImageNV (Display *dpy, GLXVideoDeviceNV VideoDevice, GLXPbuffer pbuf, int iVideoBuffer);
extern int glXReleaseVideoImageNV (Display *dpy, GLXPbuffer pbuf);
extern int glXSendPbufferToVideoNV (Display *dpy, GLXPbuffer pbuf, int iBufferType, unsigned long *pulCounterPbuffer, GLboolean bBlock);
extern int glXGetVideoInfoNV (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice, unsigned long *pulCounterOutputPbuffer, unsigned long *pulCounterOutputVideo);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXGETVIDEODEVICENVPROC) (Display *dpy, int screen, int numVideoDevices, GLXVideoDeviceNV *pVideoDevice);
typedef int ( * PFNGLXRELEASEVIDEODEVICENVPROC) (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice);
typedef int ( * PFNGLXBINDVIDEOIMAGENVPROC) (Display *dpy, GLXVideoDeviceNV VideoDevice, GLXPbuffer pbuf, int iVideoBuffer);
typedef int ( * PFNGLXRELEASEVIDEOIMAGENVPROC) (Display *dpy, GLXPbuffer pbuf);
typedef int ( * PFNGLXSENDPBUFFERTOVIDEONVPROC) (Display *dpy, GLXPbuffer pbuf, int iBufferType, unsigned long *pulCounterPbuffer, GLboolean bBlock);
typedef int ( * PFNGLXGETVIDEOINFONVPROC) (Display *dpy, int screen, GLXVideoDeviceNV VideoDevice, unsigned long *pulCounterOutputPbuffer, unsigned long *pulCounterOutputVideo);
#endif

#ifndef GLX_NV_swap_group
#define GLX_NV_swap_group 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern Bool glXJoinSwapGroupNV (Display *dpy, GLXDrawable drawable, GLuint group);
extern Bool glXBindSwapBarrierNV (Display *dpy, GLuint group, GLuint barrier);
extern Bool glXQuerySwapGroupNV (Display *dpy, GLXDrawable drawable, GLuint *group, GLuint *barrier);
extern Bool glXQueryMaxSwapGroupsNV (Display *dpy, int screen, GLuint *maxGroups, GLuint *maxBarriers);
extern Bool glXQueryFrameCountNV (Display *dpy, int screen, GLuint *count);
extern Bool glXResetFrameCountNV (Display *dpy, int screen);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef Bool ( * PFNGLXJOINSWAPGROUPNVPROC) (Display *dpy, GLXDrawable drawable, GLuint group);
typedef Bool ( * PFNGLXBINDSWAPBARRIERNVPROC) (Display *dpy, GLuint group, GLuint barrier);
typedef Bool ( * PFNGLXQUERYSWAPGROUPNVPROC) (Display *dpy, GLXDrawable drawable, GLuint *group, GLuint *barrier);
typedef Bool ( * PFNGLXQUERYMAXSWAPGROUPSNVPROC) (Display *dpy, int screen, GLuint *maxGroups, GLuint *maxBarriers);
typedef Bool ( * PFNGLXQUERYFRAMECOUNTNVPROC) (Display *dpy, int screen, GLuint *count);
typedef Bool ( * PFNGLXRESETFRAMECOUNTNVPROC) (Display *dpy, int screen);
#endif

#ifndef GLX_NV_video_capture
#define GLX_NV_video_capture 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern int glXBindVideoCaptureDeviceNV (Display *dpy, unsigned int video_capture_slot, GLXVideoCaptureDeviceNV device);
extern GLXVideoCaptureDeviceNV * glXEnumerateVideoCaptureDevicesNV (Display *dpy, int screen, int *nelements);
extern void glXLockVideoCaptureDeviceNV (Display *dpy, GLXVideoCaptureDeviceNV device);
extern int glXQueryVideoCaptureDeviceNV (Display *dpy, GLXVideoCaptureDeviceNV device, int attribute, int *value);
extern void glXReleaseVideoCaptureDeviceNV (Display *dpy, GLXVideoCaptureDeviceNV device);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef int ( * PFNGLXBINDVIDEOCAPTUREDEVICENVPROC) (Display *dpy, unsigned int video_capture_slot, GLXVideoCaptureDeviceNV device);
typedef GLXVideoCaptureDeviceNV * ( * PFNGLXENUMERATEVIDEOCAPTUREDEVICESNVPROC) (Display *dpy, int screen, int *nelements);
typedef void ( * PFNGLXLOCKVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device);
typedef int ( * PFNGLXQUERYVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device, int attribute, int *value);
typedef void ( * PFNGLXRELEASEVIDEOCAPTUREDEVICENVPROC) (Display *dpy, GLXVideoCaptureDeviceNV device);
#endif

#ifndef GLX_EXT_swap_control
#define GLX_EXT_swap_control 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXSwapIntervalEXT (Display *dpy, GLXDrawable drawable, int interval);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXSWAPINTERVALEXTPROC) (Display *dpy, GLXDrawable drawable, int interval);
#endif

#ifndef GLX_NV_copy_image
#define GLX_NV_copy_image 1
#ifdef GLX_GLXEXT_PROTOTYPES
extern void glXCopyImageSubDataNV (Display *dpy, GLXContext srcCtx, GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLXContext dstCtx, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei width, GLsizei height, GLsizei depth);
#endif /* GLX_GLXEXT_PROTOTYPES */
typedef void ( * PFNGLXCOPYIMAGESUBDATANVPROC) (Display *dpy, GLXContext srcCtx, GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLXContext dstCtx, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei width, GLsizei height, GLsizei depth);
#endif

#ifndef GLX_INTEL_swap_event
#define GLX_INTEL_swap_event 1
#endif

#ifndef GLX_NV_multisample_coverage
#define GLX_NV_multisample_coverage 1
#endif

#ifndef GLX_EXT_swap_control_tear
#define GLX_EXT_swap_control_tear 1
#endif


#ifdef __cplusplus
}
#endif

#endif
