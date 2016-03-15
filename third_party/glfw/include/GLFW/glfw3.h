/*************************************************************************
 * GLFW 3.1 - www.glfw.org
 * A library for OpenGL, window and input
 *------------------------------------------------------------------------
 * Copyright (c) 2002-2006 Marcus Geelnard
 * Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would
 *    be appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not
 *    be misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source
 *    distribution.
 *
 *************************************************************************/

#ifndef _glfw3_h_
#define _glfw3_h_

#ifdef __cplusplus
extern "C" {
#endif


/*************************************************************************
 * Doxygen documentation
 *************************************************************************/

/*! @defgroup context Context handling
 *
 *  This is the reference documentation for context related functions.  For more
 *  information, see the @ref context.
 */
/*! @defgroup init Initialization, version and errors
 *
 *  This is the reference documentation for initialization and termination of
 *  the library, version management and error handling.  For more information,
 *  see the @ref intro.
 */
/*! @defgroup input Input handling
 *
 *  This is the reference documentation for input related functions and types.
 *  For more information, see the @ref input.
 */
/*! @defgroup monitor Monitor handling
 *
 *  This is the reference documentation for monitor related functions and types.
 *  For more information, see the @ref monitor.
 */
/*! @defgroup window Window handling
 *
 *  This is the reference documentation for window related functions and types,
 *  including creation, deletion and event polling.  For more information, see
 *  the @ref window.
 */


/*************************************************************************
 * Compiler- and platform-specific preprocessor work
 *************************************************************************/

/* If we are we on Windows, we want a single define for it.
 */
#if !defined(_WIN32) && (defined(__WIN32__) || defined(WIN32) || defined(__MINGW32__))
 #define _WIN32
#endif /* _WIN32 */

/* It is customary to use APIENTRY for OpenGL function pointer declarations on
 * all platforms.  Additionally, the Windows OpenGL header needs APIENTRY.
 */
#ifndef APIENTRY
 #ifdef _WIN32
  #define APIENTRY __stdcall
 #else
  #define APIENTRY
 #endif
#endif /* APIENTRY */

/* Some Windows OpenGL headers need this.
 */
#if !defined(WINGDIAPI) && defined(_WIN32)
 #define WINGDIAPI __declspec(dllimport)
 #define GLFW_WINGDIAPI_DEFINED
#endif /* WINGDIAPI */

/* Some Windows GLU headers need this.
 */
#if !defined(CALLBACK) && defined(_WIN32)
 #define CALLBACK __stdcall
 #define GLFW_CALLBACK_DEFINED
#endif /* CALLBACK */

/* Most Windows GLU headers need wchar_t.
 * The OS X OpenGL header blocks the definition of ptrdiff_t by glext.h.
 */
#if !defined(GLFW_INCLUDE_NONE)
 #include <stddef.h>
#endif

/* Include the chosen client API headers.
 */
#if defined(__APPLE_CC__)
 #if defined(GLFW_INCLUDE_GLCOREARB)
  #include <OpenGL/gl3.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <OpenGL/gl3ext.h>
  #endif
 #elif !defined(GLFW_INCLUDE_NONE)
  #if !defined(GLFW_INCLUDE_GLEXT)
   #define GL_GLEXT_LEGACY
  #endif
  #include <OpenGL/gl.h>
 #endif
 #if defined(GLFW_INCLUDE_GLU)
  #include <OpenGL/glu.h>
 #endif
#else
 #if defined(GLFW_INCLUDE_GLCOREARB)
  #include <GL/glcorearb.h>
 #elif defined(GLFW_INCLUDE_ES1)
  #include <GLES/gl.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <GLES/glext.h>
  #endif
 #elif defined(GLFW_INCLUDE_ES2)
  #include <GLES2/gl2.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <GLES2/gl2ext.h>
  #endif
 #elif defined(GLFW_INCLUDE_ES3)
  #include <GLES3/gl3.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <GLES3/gl2ext.h>
  #endif
 #elif defined(GLFW_INCLUDE_ES31)
  #include <GLES3/gl31.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <GLES3/gl2ext.h>
  #endif
 #elif !defined(GLFW_INCLUDE_NONE)
  #include <GL/gl.h>
  #if defined(GLFW_INCLUDE_GLEXT)
   #include <GL/glext.h>
  #endif
 #endif
 #if defined(GLFW_INCLUDE_GLU)
  #include <GL/glu.h>
 #endif
#endif

#if defined(GLFW_DLL) && defined(_GLFW_BUILD_DLL)
 /* GLFW_DLL must be defined by applications that are linking against the DLL
  * version of the GLFW library.  _GLFW_BUILD_DLL is defined by the GLFW
  * configuration header when compiling the DLL version of the library.
  */
 #error "You may not have both GLFW_DLL and _GLFW_BUILD_DLL defined"
#endif

/* GLFWAPI is used to declare public API functions for export
 * from the DLL / shared library / dynamic library.
 */
#if defined(_WIN32) && defined(_GLFW_BUILD_DLL)
 /* We are building GLFW as a Win32 DLL */
 #define GLFWAPI __declspec(dllexport)
#elif defined(_WIN32) && defined(GLFW_DLL)
 /* We are calling GLFW as a Win32 DLL */
 #define GLFWAPI __declspec(dllimport)
#elif defined(__GNUC__) && defined(_GLFW_BUILD_DLL)
 /* We are building GLFW as a shared / dynamic library */
 #define GLFWAPI __attribute__((visibility("default")))
#else
 /* We are building or calling GLFW as a static library */
 #define GLFWAPI
#endif


/*************************************************************************
 * GLFW API tokens
 *************************************************************************/

/*! @name GLFW version macros
 *  @{ */
/*! @brief The major version number of the GLFW library.
 *
 *  This is incremented when the API is changed in non-compatible ways.
 *  @ingroup init
 */
#define GLFW_VERSION_MAJOR          3
/*! @brief The minor version number of the GLFW library.
 *
 *  This is incremented when features are added to the API but it remains
 *  backward-compatible.
 *  @ingroup init
 */
#define GLFW_VERSION_MINOR          1
/*! @brief The revision number of the GLFW library.
 *
 *  This is incremented when a bug fix release is made that does not contain any
 *  API changes.
 *  @ingroup init
 */
#define GLFW_VERSION_REVISION       2
/*! @} */

/*! @name Key and button actions
 *  @{ */
/*! @brief The key or mouse button was released.
 *
 *  The key or mouse button was released.
 *
 *  @ingroup input
 */
#define GLFW_RELEASE                0
/*! @brief The key or mouse button was pressed.
 *
 *  The key or mouse button was pressed.
 *
 *  @ingroup input
 */
#define GLFW_PRESS                  1
/*! @brief The key was held down until it repeated.
 *
 *  The key was held down until it repeated.
 *
 *  @ingroup input
 */
#define GLFW_REPEAT                 2
/*! @} */

/*! @defgroup keys Keyboard keys
 *
 *  See [key input](@ref input_key) for how these are used.
 *
 *  These key codes are inspired by the _USB HID Usage Tables v1.12_ (p. 53-60),
 *  but re-arranged to map to 7-bit ASCII for printable keys (function keys are
 *  put in the 256+ range).
 *
 *  The naming of the key codes follow these rules:
 *   - The US keyboard layout is used
 *   - Names of printable alpha-numeric characters are used (e.g. "A", "R",
 *     "3", etc.)
 *   - For non-alphanumeric characters, Unicode:ish names are used (e.g.
 *     "COMMA", "LEFT_SQUARE_BRACKET", etc.). Note that some names do not
 *     correspond to the Unicode standard (usually for brevity)
 *   - Keys that lack a clear US mapping are named "WORLD_x"
 *   - For non-printable keys, custom names are used (e.g. "F4",
 *     "BACKSPACE", etc.)
 *
 *  @ingroup input
 *  @{
 */

/* The unknown key */
#define GLFW_KEY_UNKNOWN            -1

/* Printable keys */
#define GLFW_KEY_SPACE              32
#define GLFW_KEY_APOSTROPHE         39  /* ' */
#define GLFW_KEY_COMMA              44  /* , */
#define GLFW_KEY_MINUS              45  /* - */
#define GLFW_KEY_PERIOD             46  /* . */
#define GLFW_KEY_SLASH              47  /* / */
#define GLFW_KEY_0                  48
#define GLFW_KEY_1                  49
#define GLFW_KEY_2                  50
#define GLFW_KEY_3                  51
#define GLFW_KEY_4                  52
#define GLFW_KEY_5                  53
#define GLFW_KEY_6                  54
#define GLFW_KEY_7                  55
#define GLFW_KEY_8                  56
#define GLFW_KEY_9                  57
#define GLFW_KEY_SEMICOLON          59  /* ; */
#define GLFW_KEY_EQUAL              61  /* = */
#define GLFW_KEY_A                  65
#define GLFW_KEY_B                  66
#define GLFW_KEY_C                  67
#define GLFW_KEY_D                  68
#define GLFW_KEY_E                  69
#define GLFW_KEY_F                  70
#define GLFW_KEY_G                  71
#define GLFW_KEY_H                  72
#define GLFW_KEY_I                  73
#define GLFW_KEY_J                  74
#define GLFW_KEY_K                  75
#define GLFW_KEY_L                  76
#define GLFW_KEY_M                  77
#define GLFW_KEY_N                  78
#define GLFW_KEY_O                  79
#define GLFW_KEY_P                  80
#define GLFW_KEY_Q                  81
#define GLFW_KEY_R                  82
#define GLFW_KEY_S                  83
#define GLFW_KEY_T                  84
#define GLFW_KEY_U                  85
#define GLFW_KEY_V                  86
#define GLFW_KEY_W                  87
#define GLFW_KEY_X                  88
#define GLFW_KEY_Y                  89
#define GLFW_KEY_Z                  90
#define GLFW_KEY_LEFT_BRACKET       91  /* [ */
#define GLFW_KEY_BACKSLASH          92  /* \ */
#define GLFW_KEY_RIGHT_BRACKET      93  /* ] */
#define GLFW_KEY_GRAVE_ACCENT       96  /* ` */
#define GLFW_KEY_WORLD_1            161 /* non-US #1 */
#define GLFW_KEY_WORLD_2            162 /* non-US #2 */

/* Function keys */
#define GLFW_KEY_ESCAPE             256
#define GLFW_KEY_ENTER              257
#define GLFW_KEY_TAB                258
#define GLFW_KEY_BACKSPACE          259
#define GLFW_KEY_INSERT             260
#define GLFW_KEY_DELETE             261
#define GLFW_KEY_RIGHT              262
#define GLFW_KEY_LEFT               263
#define GLFW_KEY_DOWN               264
#define GLFW_KEY_UP                 265
#define GLFW_KEY_PAGE_UP            266
#define GLFW_KEY_PAGE_DOWN          267
#define GLFW_KEY_HOME               268
#define GLFW_KEY_END                269
#define GLFW_KEY_CAPS_LOCK          280
#define GLFW_KEY_SCROLL_LOCK        281
#define GLFW_KEY_NUM_LOCK           282
#define GLFW_KEY_PRINT_SCREEN       283
#define GLFW_KEY_PAUSE              284
#define GLFW_KEY_F1                 290
#define GLFW_KEY_F2                 291
#define GLFW_KEY_F3                 292
#define GLFW_KEY_F4                 293
#define GLFW_KEY_F5                 294
#define GLFW_KEY_F6                 295
#define GLFW_KEY_F7                 296
#define GLFW_KEY_F8                 297
#define GLFW_KEY_F9                 298
#define GLFW_KEY_F10                299
#define GLFW_KEY_F11                300
#define GLFW_KEY_F12                301
#define GLFW_KEY_F13                302
#define GLFW_KEY_F14                303
#define GLFW_KEY_F15                304
#define GLFW_KEY_F16                305
#define GLFW_KEY_F17                306
#define GLFW_KEY_F18                307
#define GLFW_KEY_F19                308
#define GLFW_KEY_F20                309
#define GLFW_KEY_F21                310
#define GLFW_KEY_F22                311
#define GLFW_KEY_F23                312
#define GLFW_KEY_F24                313
#define GLFW_KEY_F25                314
#define GLFW_KEY_KP_0               320
#define GLFW_KEY_KP_1               321
#define GLFW_KEY_KP_2               322
#define GLFW_KEY_KP_3               323
#define GLFW_KEY_KP_4               324
#define GLFW_KEY_KP_5               325
#define GLFW_KEY_KP_6               326
#define GLFW_KEY_KP_7               327
#define GLFW_KEY_KP_8               328
#define GLFW_KEY_KP_9               329
#define GLFW_KEY_KP_DECIMAL         330
#define GLFW_KEY_KP_DIVIDE          331
#define GLFW_KEY_KP_MULTIPLY        332
#define GLFW_KEY_KP_SUBTRACT        333
#define GLFW_KEY_KP_ADD             334
#define GLFW_KEY_KP_ENTER           335
#define GLFW_KEY_KP_EQUAL           336
#define GLFW_KEY_LEFT_SHIFT         340
#define GLFW_KEY_LEFT_CONTROL       341
#define GLFW_KEY_LEFT_ALT           342
#define GLFW_KEY_LEFT_SUPER         343
#define GLFW_KEY_RIGHT_SHIFT        344
#define GLFW_KEY_RIGHT_CONTROL      345
#define GLFW_KEY_RIGHT_ALT          346
#define GLFW_KEY_RIGHT_SUPER        347
#define GLFW_KEY_MENU               348
#define GLFW_KEY_LAST               GLFW_KEY_MENU

/*! @} */

/*! @defgroup mods Modifier key flags
 *
 *  See [key input](@ref input_key) for how these are used.
 *
 *  @ingroup input
 *  @{ */

/*! @brief If this bit is set one or more Shift keys were held down.
 */
#define GLFW_MOD_SHIFT           0x0001
/*! @brief If this bit is set one or more Control keys were held down.
 */
#define GLFW_MOD_CONTROL         0x0002
/*! @brief If this bit is set one or more Alt keys were held down.
 */
#define GLFW_MOD_ALT             0x0004
/*! @brief If this bit is set one or more Super keys were held down.
 */
#define GLFW_MOD_SUPER           0x0008

/*! @} */

/*! @defgroup buttons Mouse buttons
 *
 *  See [mouse button input](@ref input_mouse_button) for how these are used.
 *
 *  @ingroup input
 *  @{ */
#define GLFW_MOUSE_BUTTON_1         0
#define GLFW_MOUSE_BUTTON_2         1
#define GLFW_MOUSE_BUTTON_3         2
#define GLFW_MOUSE_BUTTON_4         3
#define GLFW_MOUSE_BUTTON_5         4
#define GLFW_MOUSE_BUTTON_6         5
#define GLFW_MOUSE_BUTTON_7         6
#define GLFW_MOUSE_BUTTON_8         7
#define GLFW_MOUSE_BUTTON_LAST      GLFW_MOUSE_BUTTON_8
#define GLFW_MOUSE_BUTTON_LEFT      GLFW_MOUSE_BUTTON_1
#define GLFW_MOUSE_BUTTON_RIGHT     GLFW_MOUSE_BUTTON_2
#define GLFW_MOUSE_BUTTON_MIDDLE    GLFW_MOUSE_BUTTON_3
/*! @} */

/*! @defgroup joysticks Joysticks
 *
 *  See [joystick input](@ref joystick) for how these are used.
 *
 *  @ingroup input
 *  @{ */
#define GLFW_JOYSTICK_1             0
#define GLFW_JOYSTICK_2             1
#define GLFW_JOYSTICK_3             2
#define GLFW_JOYSTICK_4             3
#define GLFW_JOYSTICK_5             4
#define GLFW_JOYSTICK_6             5
#define GLFW_JOYSTICK_7             6
#define GLFW_JOYSTICK_8             7
#define GLFW_JOYSTICK_9             8
#define GLFW_JOYSTICK_10            9
#define GLFW_JOYSTICK_11            10
#define GLFW_JOYSTICK_12            11
#define GLFW_JOYSTICK_13            12
#define GLFW_JOYSTICK_14            13
#define GLFW_JOYSTICK_15            14
#define GLFW_JOYSTICK_16            15
#define GLFW_JOYSTICK_LAST          GLFW_JOYSTICK_16
/*! @} */

/*! @defgroup errors Error codes
 *
 *  See [error handling](@ref error_handling) for how these are used.
 *
 *  @ingroup init
 *  @{ */
/*! @brief GLFW has not been initialized.
 *
 *  This occurs if a GLFW function was called that may not be called unless the
 *  library is [initialized](@ref intro_init).
 *
 *  @par Analysis
 *  Application programmer error.  Initialize GLFW before calling any function
 *  that requires initialization.
 */
#define GLFW_NOT_INITIALIZED        0x00010001
/*! @brief No context is current for this thread.
 *
 *  This occurs if a GLFW function was called that needs and operates on the
 *  current OpenGL or OpenGL ES context but no context is current on the calling
 *  thread.  One such function is @ref glfwSwapInterval.
 *
 *  @par Analysis
 *  Application programmer error.  Ensure a context is current before calling
 *  functions that require a current context.
 */
#define GLFW_NO_CURRENT_CONTEXT     0x00010002
/*! @brief One of the arguments to the function was an invalid enum value.
 *
 *  One of the arguments to the function was an invalid enum value, for example
 *  requesting [GLFW_RED_BITS](@ref window_hints_fb) with @ref
 *  glfwGetWindowAttrib.
 *
 *  @par Analysis
 *  Application programmer error.  Fix the offending call.
 */
#define GLFW_INVALID_ENUM           0x00010003
/*! @brief One of the arguments to the function was an invalid value.
 *
 *  One of the arguments to the function was an invalid value, for example
 *  requesting a non-existent OpenGL or OpenGL ES version like 2.7.
 *
 *  Requesting a valid but unavailable OpenGL or OpenGL ES version will instead
 *  result in a @ref GLFW_VERSION_UNAVAILABLE error.
 *
 *  @par Analysis
 *  Application programmer error.  Fix the offending call.
 */
#define GLFW_INVALID_VALUE          0x00010004
/*! @brief A memory allocation failed.
 *
 *  A memory allocation failed.
 *
 *  @par Analysis
 *  A bug in GLFW or the underlying operating system.  Report the bug to our
 *  [issue tracker](https://github.com/glfw/glfw/issues).
 */
#define GLFW_OUT_OF_MEMORY          0x00010005
/*! @brief GLFW could not find support for the requested client API on the
 *  system.
 *
 *  GLFW could not find support for the requested client API on the system.  If
 *  emitted by functions other than @ref glfwCreateWindow, no supported client
 *  API was found.
 *
 *  @par Analysis
 *  The installed graphics driver does not support the requested client API, or
 *  does not support it via the chosen context creation backend.  Below are
 *  a few examples.
 *
 *  @par
 *  Some pre-installed Windows graphics drivers do not support OpenGL.  AMD only
 *  supports OpenGL ES via EGL, while Nvidia and Intel only support it via
 *  a WGL or GLX extension.  OS X does not provide OpenGL ES at all.  The Mesa
 *  EGL, OpenGL and OpenGL ES libraries do not interface with the Nvidia binary
 *  driver.
 */
#define GLFW_API_UNAVAILABLE        0x00010006
/*! @brief The requested OpenGL or OpenGL ES version is not available.
 *
 *  The requested OpenGL or OpenGL ES version (including any requested context
 *  or framebuffer hints) is not available on this machine.
 *
 *  @par Analysis
 *  The machine does not support your requirements.  If your application is
 *  sufficiently flexible, downgrade your requirements and try again.
 *  Otherwise, inform the user that their machine does not match your
 *  requirements.
 *
 *  @par
 *  Future invalid OpenGL and OpenGL ES versions, for example OpenGL 4.8 if 5.0
 *  comes out before the 4.x series gets that far, also fail with this error and
 *  not @ref GLFW_INVALID_VALUE, because GLFW cannot know what future versions
 *  will exist.
 */
#define GLFW_VERSION_UNAVAILABLE    0x00010007
/*! @brief A platform-specific error occurred that does not match any of the
 *  more specific categories.
 *
 *  A platform-specific error occurred that does not match any of the more
 *  specific categories.
 *
 *  @par Analysis
 *  A bug or configuration error in GLFW, the underlying operating system or
 *  its drivers, or a lack of required resources.  Report the issue to our
 *  [issue tracker](https://github.com/glfw/glfw/issues).
 */
#define GLFW_PLATFORM_ERROR         0x00010008
/*! @brief The requested format is not supported or available.
 *
 *  If emitted during window creation, the requested pixel format is not
 *  supported.
 *
 *  If emitted when querying the clipboard, the contents of the clipboard could
 *  not be converted to the requested format.
 *
 *  @par Analysis
 *  If emitted during window creation, one or more
 *  [hard constraints](@ref window_hints_hard) did not match any of the
 *  available pixel formats.  If your application is sufficiently flexible,
 *  downgrade your requirements and try again.  Otherwise, inform the user that
 *  their machine does not match your requirements.
 *
 *  @par
 *  If emitted when querying the clipboard, ignore the error or report it to
 *  the user, as appropriate.
 */
#define GLFW_FORMAT_UNAVAILABLE     0x00010009
/*! @} */

#define GLFW_FOCUSED                0x00020001
#define GLFW_ICONIFIED              0x00020002
#define GLFW_RESIZABLE              0x00020003
#define GLFW_VISIBLE                0x00020004
#define GLFW_DECORATED              0x00020005
#define GLFW_AUTO_ICONIFY           0x00020006
#define GLFW_FLOATING               0x00020007

#define GLFW_RED_BITS               0x00021001
#define GLFW_GREEN_BITS             0x00021002
#define GLFW_BLUE_BITS              0x00021003
#define GLFW_ALPHA_BITS             0x00021004
#define GLFW_DEPTH_BITS             0x00021005
#define GLFW_STENCIL_BITS           0x00021006
#define GLFW_ACCUM_RED_BITS         0x00021007
#define GLFW_ACCUM_GREEN_BITS       0x00021008
#define GLFW_ACCUM_BLUE_BITS        0x00021009
#define GLFW_ACCUM_ALPHA_BITS       0x0002100A
#define GLFW_AUX_BUFFERS            0x0002100B
#define GLFW_STEREO                 0x0002100C
#define GLFW_SAMPLES                0x0002100D
#define GLFW_SRGB_CAPABLE           0x0002100E
#define GLFW_REFRESH_RATE           0x0002100F
#define GLFW_DOUBLEBUFFER           0x00021010

#define GLFW_CLIENT_API             0x00022001
#define GLFW_CONTEXT_VERSION_MAJOR  0x00022002
#define GLFW_CONTEXT_VERSION_MINOR  0x00022003
#define GLFW_CONTEXT_REVISION       0x00022004
#define GLFW_CONTEXT_ROBUSTNESS     0x00022005
#define GLFW_OPENGL_FORWARD_COMPAT  0x00022006
#define GLFW_OPENGL_DEBUG_CONTEXT   0x00022007
#define GLFW_OPENGL_PROFILE         0x00022008
#define GLFW_CONTEXT_RELEASE_BEHAVIOR 0x00022009

#define GLFW_OPENGL_API             0x00030001
#define GLFW_OPENGL_ES_API          0x00030002

#define GLFW_NO_ROBUSTNESS                   0
#define GLFW_NO_RESET_NOTIFICATION  0x00031001
#define GLFW_LOSE_CONTEXT_ON_RESET  0x00031002

#define GLFW_OPENGL_ANY_PROFILE              0
#define GLFW_OPENGL_CORE_PROFILE    0x00032001
#define GLFW_OPENGL_COMPAT_PROFILE  0x00032002

#define GLFW_CURSOR                 0x00033001
#define GLFW_STICKY_KEYS            0x00033002
#define GLFW_STICKY_MOUSE_BUTTONS   0x00033003

#define GLFW_CURSOR_NORMAL          0x00034001
#define GLFW_CURSOR_HIDDEN          0x00034002
#define GLFW_CURSOR_DISABLED        0x00034003

#define GLFW_ANY_RELEASE_BEHAVIOR            0
#define GLFW_RELEASE_BEHAVIOR_FLUSH 0x00035001
#define GLFW_RELEASE_BEHAVIOR_NONE  0x00035002

/*! @defgroup shapes Standard cursor shapes
 *
 *  See [standard cursor creation](@ref cursor_standard) for how these are used.
 *
 *  @ingroup input
 *  @{ */

/*! @brief The regular arrow cursor shape.
 *
 *  The regular arrow cursor.
 */
#define GLFW_ARROW_CURSOR           0x00036001
/*! @brief The text input I-beam cursor shape.
 *
 *  The text input I-beam cursor shape.
 */
#define GLFW_IBEAM_CURSOR           0x00036002
/*! @brief The crosshair shape.
 *
 *  The crosshair shape.
 */
#define GLFW_CROSSHAIR_CURSOR       0x00036003
/*! @brief The hand shape.
 *
 *  The hand shape.
 */
#define GLFW_HAND_CURSOR            0x00036004
/*! @brief The horizontal resize arrow shape.
 *
 *  The horizontal resize arrow shape.
 */
#define GLFW_HRESIZE_CURSOR         0x00036005
/*! @brief The vertical resize arrow shape.
 *
 *  The vertical resize arrow shape.
 */
#define GLFW_VRESIZE_CURSOR         0x00036006
/*! @} */

#define GLFW_CONNECTED              0x00040001
#define GLFW_DISCONNECTED           0x00040002

#define GLFW_DONT_CARE              -1


/*************************************************************************
 * GLFW API types
 *************************************************************************/

/*! @brief Client API function pointer type.
 *
 *  Generic function pointer used for returning client API function pointers
 *  without forcing a cast from a regular pointer.
 *
 *  @ingroup context
 */
typedef void (*GLFWglproc)(void);

/*! @brief Opaque monitor object.
 *
 *  Opaque monitor object.
 *
 *  @ingroup monitor
 */
typedef struct GLFWmonitor GLFWmonitor;

/*! @brief Opaque window object.
 *
 *  Opaque window object.
 *
 *  @ingroup window
 */
typedef struct GLFWwindow GLFWwindow;

/*! @brief Opaque cursor object.
 *
 *  Opaque cursor object.
 *
 *  @ingroup cursor
 */
typedef struct GLFWcursor GLFWcursor;

/*! @brief The function signature for error callbacks.
 *
 *  This is the function signature for error callback functions.
 *
 *  @param[in] error An [error code](@ref errors).
 *  @param[in] description A UTF-8 encoded string describing the error.
 *
 *  @sa glfwSetErrorCallback
 *
 *  @ingroup init
 */
typedef void (* GLFWerrorfun)(int,const char*);

/*! @brief The function signature for window position callbacks.
 *
 *  This is the function signature for window position callback functions.
 *
 *  @param[in] window The window that was moved.
 *  @param[in] xpos The new x-coordinate, in screen coordinates, of the
 *  upper-left corner of the client area of the window.
 *  @param[in] ypos The new y-coordinate, in screen coordinates, of the
 *  upper-left corner of the client area of the window.
 *
 *  @sa glfwSetWindowPosCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowposfun)(GLFWwindow*,int,int);

/*! @brief The function signature for window resize callbacks.
 *
 *  This is the function signature for window size callback functions.
 *
 *  @param[in] window The window that was resized.
 *  @param[in] width The new width, in screen coordinates, of the window.
 *  @param[in] height The new height, in screen coordinates, of the window.
 *
 *  @sa glfwSetWindowSizeCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowsizefun)(GLFWwindow*,int,int);

/*! @brief The function signature for window close callbacks.
 *
 *  This is the function signature for window close callback functions.
 *
 *  @param[in] window The window that the user attempted to close.
 *
 *  @sa glfwSetWindowCloseCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowclosefun)(GLFWwindow*);

/*! @brief The function signature for window content refresh callbacks.
 *
 *  This is the function signature for window refresh callback functions.
 *
 *  @param[in] window The window whose content needs to be refreshed.
 *
 *  @sa glfwSetWindowRefreshCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowrefreshfun)(GLFWwindow*);

/*! @brief The function signature for window focus/defocus callbacks.
 *
 *  This is the function signature for window focus callback functions.
 *
 *  @param[in] window The window that gained or lost input focus.
 *  @param[in] focused `GL_TRUE` if the window was given input focus, or
 *  `GL_FALSE` if it lost it.
 *
 *  @sa glfwSetWindowFocusCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowfocusfun)(GLFWwindow*,int);

/*! @brief The function signature for window iconify/restore callbacks.
 *
 *  This is the function signature for window iconify/restore callback
 *  functions.
 *
 *  @param[in] window The window that was iconified or restored.
 *  @param[in] iconified `GL_TRUE` if the window was iconified, or `GL_FALSE`
 *  if it was restored.
 *
 *  @sa glfwSetWindowIconifyCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWwindowiconifyfun)(GLFWwindow*,int);

/*! @brief The function signature for framebuffer resize callbacks.
 *
 *  This is the function signature for framebuffer resize callback
 *  functions.
 *
 *  @param[in] window The window whose framebuffer was resized.
 *  @param[in] width The new width, in pixels, of the framebuffer.
 *  @param[in] height The new height, in pixels, of the framebuffer.
 *
 *  @sa glfwSetFramebufferSizeCallback
 *
 *  @ingroup window
 */
typedef void (* GLFWframebuffersizefun)(GLFWwindow*,int,int);

/*! @brief The function signature for mouse button callbacks.
 *
 *  This is the function signature for mouse button callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] button The [mouse button](@ref buttons) that was pressed or
 *  released.
 *  @param[in] action One of `GLFW_PRESS` or `GLFW_RELEASE`.
 *  @param[in] mods Bit field describing which [modifier keys](@ref mods) were
 *  held down.
 *
 *  @sa glfwSetMouseButtonCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWmousebuttonfun)(GLFWwindow*,int,int,int);

/*! @brief The function signature for cursor position callbacks.
 *
 *  This is the function signature for cursor position callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] xpos The new x-coordinate, in screen coordinates, of the cursor.
 *  @param[in] ypos The new y-coordinate, in screen coordinates, of the cursor.
 *
 *  @sa glfwSetCursorPosCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWcursorposfun)(GLFWwindow*,double,double);

/*! @brief The function signature for cursor enter/leave callbacks.
 *
 *  This is the function signature for cursor enter/leave callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] entered `GL_TRUE` if the cursor entered the window's client
 *  area, or `GL_FALSE` if it left it.
 *
 *  @sa glfwSetCursorEnterCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWcursorenterfun)(GLFWwindow*,int);

/*! @brief The function signature for scroll callbacks.
 *
 *  This is the function signature for scroll callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] xoffset The scroll offset along the x-axis.
 *  @param[in] yoffset The scroll offset along the y-axis.
 *
 *  @sa glfwSetScrollCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWscrollfun)(GLFWwindow*,double,double);

/*! @brief The function signature for keyboard key callbacks.
 *
 *  This is the function signature for keyboard key callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] key The [keyboard key](@ref keys) that was pressed or released.
 *  @param[in] scancode The system-specific scancode of the key.
 *  @param[in] action `GLFW_PRESS`, `GLFW_RELEASE` or `GLFW_REPEAT`.
 *  @param[in] mods Bit field describing which [modifier keys](@ref mods) were
 *  held down.
 *
 *  @sa glfwSetKeyCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWkeyfun)(GLFWwindow*,int,int,int,int);

/*! @brief The function signature for Unicode character callbacks.
 *
 *  This is the function signature for Unicode character callback functions.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] codepoint The Unicode code point of the character.
 *
 *  @sa glfwSetCharCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWcharfun)(GLFWwindow*,unsigned int);

/*! @brief The function signature for Unicode character with modifiers
 *  callbacks.
 *
 *  This is the function signature for Unicode character with modifiers callback
 *  functions.  It is called for each input character, regardless of what
 *  modifier keys are held down.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] codepoint The Unicode code point of the character.
 *  @param[in] mods Bit field describing which [modifier keys](@ref mods) were
 *  held down.
 *
 *  @sa glfwSetCharModsCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWcharmodsfun)(GLFWwindow*,unsigned int,int);

/*! @brief The function signature for file drop callbacks.
 *
 *  This is the function signature for file drop callbacks.
 *
 *  @param[in] window The window that received the event.
 *  @param[in] count The number of dropped files.
 *  @param[in] paths The UTF-8 encoded file and/or directory path names.
 *
 *  @sa glfwSetDropCallback
 *
 *  @ingroup input
 */
typedef void (* GLFWdropfun)(GLFWwindow*,int,const char**);

/*! @brief The function signature for monitor configuration callbacks.
 *
 *  This is the function signature for monitor configuration callback functions.
 *
 *  @param[in] monitor The monitor that was connected or disconnected.
 *  @param[in] event One of `GLFW_CONNECTED` or `GLFW_DISCONNECTED`.
 *
 *  @sa glfwSetMonitorCallback
 *
 *  @ingroup monitor
 */
typedef void (* GLFWmonitorfun)(GLFWmonitor*,int);

/*! @brief Video mode type.
 *
 *  This describes a single video mode.
 *
 *  @ingroup monitor
 */
typedef struct GLFWvidmode
{
    /*! The width, in screen coordinates, of the video mode.
     */
    int width;
    /*! The height, in screen coordinates, of the video mode.
     */
    int height;
    /*! The bit depth of the red channel of the video mode.
     */
    int redBits;
    /*! The bit depth of the green channel of the video mode.
     */
    int greenBits;
    /*! The bit depth of the blue channel of the video mode.
     */
    int blueBits;
    /*! The refresh rate, in Hz, of the video mode.
     */
    int refreshRate;
} GLFWvidmode;

/*! @brief Gamma ramp.
 *
 *  This describes the gamma ramp for a monitor.
 *
 *  @sa glfwGetGammaRamp glfwSetGammaRamp
 *
 *  @ingroup monitor
 */
typedef struct GLFWgammaramp
{
    /*! An array of value describing the response of the red channel.
     */
    unsigned short* red;
    /*! An array of value describing the response of the green channel.
     */
    unsigned short* green;
    /*! An array of value describing the response of the blue channel.
     */
    unsigned short* blue;
    /*! The number of elements in each array.
     */
    unsigned int size;
} GLFWgammaramp;

/*! @brief Image data.
 */
typedef struct GLFWimage
{
    /*! The width, in pixels, of this image.
     */
    int width;
    /*! The height, in pixels, of this image.
     */
    int height;
    /*! The pixel data of this image, arranged left-to-right, top-to-bottom.
     */
    unsigned char* pixels;
} GLFWimage;


/*************************************************************************
 * GLFW API functions
 *************************************************************************/

/*! @brief Initializes the GLFW library.
 *
 *  This function initializes the GLFW library.  Before most GLFW functions can
 *  be used, GLFW must be initialized, and before an application terminates GLFW
 *  should be terminated in order to free any resources allocated during or
 *  after initialization.
 *
 *  If this function fails, it calls @ref glfwTerminate before returning.  If it
 *  succeeds, you should call @ref glfwTerminate before the application exits.
 *
 *  Additional calls to this function after successful initialization but before
 *  termination will return `GL_TRUE` immediately.
 *
 *  @return `GL_TRUE` if successful, or `GL_FALSE` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @remarks __OS X:__ This function will change the current directory of the
 *  application to the `Contents/Resources` subdirectory of the application's
 *  bundle, if present.  This can be disabled with a
 *  [compile-time option](@ref compile_options_osx).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref intro_init
 *  @sa glfwTerminate
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup init
 */
GLFWAPI int glfwInit(void);

/*! @brief Terminates the GLFW library.
 *
 *  This function destroys all remaining windows and cursors, restores any
 *  modified gamma ramps and frees any other allocated resources.  Once this
 *  function is called, you must again call @ref glfwInit successfully before
 *  you will be able to use most GLFW functions.
 *
 *  If GLFW has been successfully initialized, this function should be called
 *  before the application exits.  If initialization fails, there is no need to
 *  call this function, as it is called by @ref glfwInit before it returns
 *  failure.
 *
 *  @remarks This function may be called before @ref glfwInit.
 *
 *  @warning No window's context may be current on another thread when this
 *  function is called.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref intro_init
 *  @sa glfwInit
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup init
 */
GLFWAPI void glfwTerminate(void);

/*! @brief Retrieves the version of the GLFW library.
 *
 *  This function retrieves the major, minor and revision numbers of the GLFW
 *  library.  It is intended for when you are using GLFW as a shared library and
 *  want to ensure that you are using the minimum required version.
 *
 *  Any or all of the version arguments may be `NULL`.  This function always
 *  succeeds.
 *
 *  @param[out] major Where to store the major version number, or `NULL`.
 *  @param[out] minor Where to store the minor version number, or `NULL`.
 *  @param[out] rev Where to store the revision number, or `NULL`.
 *
 *  @remarks This function may be called before @ref glfwInit.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref intro_version
 *  @sa glfwGetVersionString
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup init
 */
GLFWAPI void glfwGetVersion(int* major, int* minor, int* rev);

/*! @brief Returns a string describing the compile-time configuration.
 *
 *  This function returns the compile-time generated
 *  [version string](@ref intro_version_string) of the GLFW library binary.  It
 *  describes the version, platform, compiler and any platform-specific
 *  compile-time options.
 *
 *  __Do not use the version string__ to parse the GLFW library version.  The
 *  @ref glfwGetVersion function already provides the version of the running
 *  library binary.
 *
 *  This function always succeeds.
 *
 *  @return The GLFW version string.
 *
 *  @remarks This function may be called before @ref glfwInit.
 *
 *  @par Pointer Lifetime
 *  The returned string is static and compile-time generated.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref intro_version
 *  @sa glfwGetVersion
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup init
 */
GLFWAPI const char* glfwGetVersionString(void);

/*! @brief Sets the error callback.
 *
 *  This function sets the error callback, which is called with an error code
 *  and a human-readable description each time a GLFW error occurs.
 *
 *  The error callback is called on the thread where the error occurred.  If you
 *  are using GLFW from multiple threads, your error callback needs to be
 *  written accordingly.
 *
 *  Because the description string may have been generated specifically for that
 *  error, it is not guaranteed to be valid after the callback has returned.  If
 *  you wish to use it after the callback returns, you need to make a copy.
 *
 *  Once set, the error callback remains set even after the library has been
 *  terminated.
 *
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set.
 *
 *  @remarks This function may be called before @ref glfwInit.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref error_handling
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup init
 */
GLFWAPI GLFWerrorfun glfwSetErrorCallback(GLFWerrorfun cbfun);

/*! @brief Returns the currently connected monitors.
 *
 *  This function returns an array of handles for all currently connected
 *  monitors.  The primary monitor is always first in the returned array.  If no
 *  monitors were found, this function returns `NULL`.
 *
 *  @param[out] count Where to store the number of monitors in the returned
 *  array.  This is set to zero if an error occurred.
 *  @return An array of monitor handles, or `NULL` if no monitors were found or
 *  if an [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned array is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is guaranteed to be valid only until the monitor configuration
 *  changes or the library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_monitors
 *  @sa @ref monitor_event
 *  @sa glfwGetPrimaryMonitor
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI GLFWmonitor** glfwGetMonitors(int* count);

/*! @brief Returns the primary monitor.
 *
 *  This function returns the primary monitor.  This is usually the monitor
 *  where elements like the task bar or global menu bar are located.
 *
 *  @return The primary monitor, or `NULL` if no monitors were found or if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @remarks The primary monitor is always first in the array returned by @ref
 *  glfwGetMonitors.
 *
 *  @sa @ref monitor_monitors
 *  @sa glfwGetMonitors
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI GLFWmonitor* glfwGetPrimaryMonitor(void);

/*! @brief Returns the position of the monitor's viewport on the virtual screen.
 *
 *  This function returns the position, in screen coordinates, of the upper-left
 *  corner of the specified monitor.
 *
 *  Any or all of the position arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` position arguments will be set to zero.
 *
 *  @param[in] monitor The monitor to query.
 *  @param[out] xpos Where to store the monitor x-coordinate, or `NULL`.
 *  @param[out] ypos Where to store the monitor y-coordinate, or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_properties
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI void glfwGetMonitorPos(GLFWmonitor* monitor, int* xpos, int* ypos);

/*! @brief Returns the physical size of the monitor.
 *
 *  This function returns the size, in millimetres, of the display area of the
 *  specified monitor.
 *
 *  Some systems do not provide accurate monitor size information, either
 *  because the monitor
 *  [EDID](https://en.wikipedia.org/wiki/Extended_display_identification_data)
 *  data is incorrect or because the driver does not report it accurately.
 *
 *  Any or all of the size arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` size arguments will be set to zero.
 *
 *  @param[in] monitor The monitor to query.
 *  @param[out] widthMM Where to store the width, in millimetres, of the
 *  monitor's display area, or `NULL`.
 *  @param[out] heightMM Where to store the height, in millimetres, of the
 *  monitor's display area, or `NULL`.
 *
 *  @remarks __Windows:__ The OS calculates the returned physical size from the
 *  current resolution and system DPI instead of querying the monitor EDID data.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_properties
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI void glfwGetMonitorPhysicalSize(GLFWmonitor* monitor, int* widthMM, int* heightMM);

/*! @brief Returns the name of the specified monitor.
 *
 *  This function returns a human-readable name, encoded as UTF-8, of the
 *  specified monitor.  The name typically reflects the make and model of the
 *  monitor and is not guaranteed to be unique among the connected monitors.
 *
 *  @param[in] monitor The monitor to query.
 *  @return The UTF-8 encoded name of the monitor, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned string is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified monitor is disconnected or the
 *  library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_properties
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI const char* glfwGetMonitorName(GLFWmonitor* monitor);

/*! @brief Sets the monitor configuration callback.
 *
 *  This function sets the monitor configuration callback, or removes the
 *  currently set callback.  This is called when a monitor is connected to or
 *  disconnected from the system.
 *
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @bug __X11:__ This callback is not yet called on monitor configuration
 *  changes.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_event
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI GLFWmonitorfun glfwSetMonitorCallback(GLFWmonitorfun cbfun);

/*! @brief Returns the available video modes for the specified monitor.
 *
 *  This function returns an array of all video modes supported by the specified
 *  monitor.  The returned array is sorted in ascending order, first by color
 *  bit depth (the sum of all channel depths) and then by resolution area (the
 *  product of width and height).
 *
 *  @param[in] monitor The monitor to query.
 *  @param[out] count Where to store the number of video modes in the returned
 *  array.  This is set to zero if an error occurred.
 *  @return An array of video modes, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned array is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified monitor is disconnected, this
 *  function is called again for that monitor or the library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_modes
 *  @sa glfwGetVideoMode
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Changed to return an array of modes for a specific monitor.
 *
 *  @ingroup monitor
 */
GLFWAPI const GLFWvidmode* glfwGetVideoModes(GLFWmonitor* monitor, int* count);

/*! @brief Returns the current mode of the specified monitor.
 *
 *  This function returns the current video mode of the specified monitor.  If
 *  you have created a full screen window for that monitor, the return value
 *  will depend on whether that window is iconified.
 *
 *  @param[in] monitor The monitor to query.
 *  @return The current mode of the monitor, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned array is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified monitor is disconnected or the
 *  library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_modes
 *  @sa glfwGetVideoModes
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwGetDesktopMode`.
 *
 *  @ingroup monitor
 */
GLFWAPI const GLFWvidmode* glfwGetVideoMode(GLFWmonitor* monitor);

/*! @brief Generates a gamma ramp and sets it for the specified monitor.
 *
 *  This function generates a 256-element gamma ramp from the specified exponent
 *  and then calls @ref glfwSetGammaRamp with it.  The value must be a finite
 *  number greater than zero.
 *
 *  @param[in] monitor The monitor whose gamma ramp to set.
 *  @param[in] gamma The desired exponent.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_gamma
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI void glfwSetGamma(GLFWmonitor* monitor, float gamma);

/*! @brief Returns the current gamma ramp for the specified monitor.
 *
 *  This function returns the current gamma ramp of the specified monitor.
 *
 *  @param[in] monitor The monitor to query.
 *  @return The current gamma ramp, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned structure and its arrays are allocated and freed by GLFW.  You
 *  should not free them yourself.  They are valid until the specified monitor
 *  is disconnected, this function is called again for that monitor or the
 *  library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_gamma
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI const GLFWgammaramp* glfwGetGammaRamp(GLFWmonitor* monitor);

/*! @brief Sets the current gamma ramp for the specified monitor.
 *
 *  This function sets the current gamma ramp for the specified monitor.  The
 *  original gamma ramp for that monitor is saved by GLFW the first time this
 *  function is called and is restored by @ref glfwTerminate.
 *
 *  @param[in] monitor The monitor whose gamma ramp to set.
 *  @param[in] ramp The gamma ramp to use.
 *
 *  @remarks Gamma ramp sizes other than 256 are not supported by all platforms
 *  or graphics hardware.
 *
 *  @remarks __Windows:__ The gamma ramp size must be 256.
 *
 *  @par Pointer Lifetime
 *  The specified gamma ramp is copied before this function returns.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref monitor_gamma
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup monitor
 */
GLFWAPI void glfwSetGammaRamp(GLFWmonitor* monitor, const GLFWgammaramp* ramp);

/*! @brief Resets all window hints to their default values.
 *
 *  This function resets all window hints to their
 *  [default values](@ref window_hints_values).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_hints
 *  @sa glfwWindowHint
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwDefaultWindowHints(void);

/*! @brief Sets the specified window hint to the desired value.
 *
 *  This function sets hints for the next call to @ref glfwCreateWindow.  The
 *  hints, once set, retain their values until changed by a call to @ref
 *  glfwWindowHint or @ref glfwDefaultWindowHints, or until the library is
 *  terminated.
 *
 *  @param[in] target The [window hint](@ref window_hints) to set.
 *  @param[in] hint The new value of the window hint.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_hints
 *  @sa glfwDefaultWindowHints
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwOpenWindowHint`.
 *
 *  @ingroup window
 */
GLFWAPI void glfwWindowHint(int target, int hint);

/*! @brief Creates a window and its associated context.
 *
 *  This function creates a window and its associated OpenGL or OpenGL ES
 *  context.  Most of the options controlling how the window and its context
 *  should be created are specified with [window hints](@ref window_hints).
 *
 *  Successful creation does not change which context is current.  Before you
 *  can use the newly created context, you need to
 *  [make it current](@ref context_current).  For information about the `share`
 *  parameter, see @ref context_sharing.
 *
 *  The created window, framebuffer and context may differ from what you
 *  requested, as not all parameters and hints are
 *  [hard constraints](@ref window_hints_hard).  This includes the size of the
 *  window, especially for full screen windows.  To query the actual attributes
 *  of the created window, framebuffer and context, see @ref
 *  glfwGetWindowAttrib, @ref glfwGetWindowSize and @ref glfwGetFramebufferSize.
 *
 *  To create a full screen window, you need to specify the monitor the window
 *  will cover.  If no monitor is specified, windowed mode will be used.  Unless
 *  you have a way for the user to choose a specific monitor, it is recommended
 *  that you pick the primary monitor.  For more information on how to query
 *  connected monitors, see @ref monitor_monitors.
 *
 *  For full screen windows, the specified size becomes the resolution of the
 *  window's _desired video mode_.  As long as a full screen window has input
 *  focus, the supported video mode most closely matching the desired video mode
 *  is set for the specified monitor.  For more information about full screen
 *  windows, including the creation of so called _windowed full screen_ or
 *  _borderless full screen_ windows, see @ref window_windowed_full_screen.
 *
 *  By default, newly created windows use the placement recommended by the
 *  window system.  To create the window at a specific position, make it
 *  initially invisible using the [GLFW_VISIBLE](@ref window_hints_wnd) window
 *  hint, set its [position](@ref window_pos) and then [show](@ref window_hide)
 *  it.
 *
 *  If a full screen window has input focus, the screensaver is prohibited from
 *  starting.
 *
 *  Window systems put limits on window sizes.  Very large or very small window
 *  dimensions may be overridden by the window system on creation.  Check the
 *  actual [size](@ref window_size) after creation.
 *
 *  The [swap interval](@ref buffer_swap) is not set during window creation and
 *  the initial value may vary depending on driver settings and defaults.
 *
 *  @param[in] width The desired width, in screen coordinates, of the window.
 *  This must be greater than zero.
 *  @param[in] height The desired height, in screen coordinates, of the window.
 *  This must be greater than zero.
 *  @param[in] title The initial, UTF-8 encoded window title.
 *  @param[in] monitor The monitor to use for full screen mode, or `NULL` to use
 *  windowed mode.
 *  @param[in] share The window whose context to share resources with, or `NULL`
 *  to not share resources.
 *  @return The handle of the created window, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @remarks __Windows:__ Window creation will fail if the Microsoft GDI
 *  software OpenGL implementation is the only one available.
 *
 *  @remarks __Windows:__ If the executable has an icon resource named
 *  `GLFW_ICON,` it will be set as the icon for the window.  If no such icon is
 *  present, the `IDI_WINLOGO` icon will be used instead.
 *
 *  @remarks __Windows:__ The context to share resources with may not be current
 *  on any other thread.
 *
 *  @remarks __OS X:__ The GLFW window has no icon, as it is not a document
 *  window, but the dock icon will be the same as the application bundle's icon.
 *  For more information on bundles, see the
 *  [Bundle Programming Guide](https://developer.apple.com/library/mac/documentation/CoreFoundation/Conceptual/CFBundles/)
 *  in the Mac Developer Library.
 *
 *  @remarks __OS X:__ The first time a window is created the menu bar is
 *  populated with common commands like Hide, Quit and About.  The About entry
 *  opens a minimal about dialog with information from the application's bundle.
 *  The menu bar can be disabled with a
 *  [compile-time option](@ref compile_options_osx).
 *
 *  @remarks __OS X:__ On OS X 10.10 and later the window frame will not be
 *  rendered at full resolution on Retina displays unless the
 *  `NSHighResolutionCapable` key is enabled in the application bundle's
 *  `Info.plist`.  For more information, see
 *  [High Resolution Guidelines for OS X](https://developer.apple.com/library/mac/documentation/GraphicsAnimation/Conceptual/HighResolutionOSX/Explained/Explained.html)
 *  in the Mac Developer Library.  The GLFW test and example programs use
 *  a custom `Info.plist` template for this, which can be found as
 *  `CMake/MacOSXBundleInfo.plist.in` in the source tree.
 *
 *  @remarks __X11:__ There is no mechanism for setting the window icon yet.
 *
 *  @remarks __X11:__ Some window managers will not respect the placement of
 *  initially hidden windows.
 *
 *  @remarks __X11:__ Due to the asynchronous nature of X11, it may take
 *  a moment for a window to reach its requested state.  This means you may not
 *  be able to query the final size, position or other attributes directly after
 *  window creation.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_creation
 *  @sa glfwDestroyWindow
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwOpenWindow`.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);

/*! @brief Destroys the specified window and its context.
 *
 *  This function destroys the specified window and its context.  On calling
 *  this function, no further callbacks will be called for that window.
 *
 *  If the context of the specified window is current on the main thread, it is
 *  detached before being destroyed.
 *
 *  @param[in] window The window to destroy.
 *
 *  @note The context of the specified window must not be current on any other
 *  thread when this function is called.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_creation
 *  @sa glfwCreateWindow
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwCloseWindow`.
 *
 *  @ingroup window
 */
GLFWAPI void glfwDestroyWindow(GLFWwindow* window);

/*! @brief Checks the close flag of the specified window.
 *
 *  This function returns the value of the close flag of the specified window.
 *
 *  @param[in] window The window to query.
 *  @return The value of the close flag.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.  Access is not synchronized.
 *
 *  @sa @ref window_close
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI int glfwWindowShouldClose(GLFWwindow* window);

/*! @brief Sets the close flag of the specified window.
 *
 *  This function sets the value of the close flag of the specified window.
 *  This can be used to override the user's attempt to close the window, or
 *  to signal that it should be closed.
 *
 *  @param[in] window The window whose flag to change.
 *  @param[in] value The new value.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.  Access is not synchronized.
 *
 *  @sa @ref window_close
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSetWindowShouldClose(GLFWwindow* window, int value);

/*! @brief Sets the title of the specified window.
 *
 *  This function sets the window title, encoded as UTF-8, of the specified
 *  window.
 *
 *  @param[in] window The window whose title to change.
 *  @param[in] title The UTF-8 encoded window title.
 *
 *  @remarks __OS X:__ The window title will not be updated until the next time
 *  you process events.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_title
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSetWindowTitle(GLFWwindow* window, const char* title);

/*! @brief Retrieves the position of the client area of the specified window.
 *
 *  This function retrieves the position, in screen coordinates, of the
 *  upper-left corner of the client area of the specified window.
 *
 *  Any or all of the position arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` position arguments will be set to zero.
 *
 *  @param[in] window The window to query.
 *  @param[out] xpos Where to store the x-coordinate of the upper-left corner of
 *  the client area, or `NULL`.
 *  @param[out] ypos Where to store the y-coordinate of the upper-left corner of
 *  the client area, or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_pos
 *  @sa glfwSetWindowPos
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwGetWindowPos(GLFWwindow* window, int* xpos, int* ypos);

/*! @brief Sets the position of the client area of the specified window.
 *
 *  This function sets the position, in screen coordinates, of the upper-left
 *  corner of the client area of the specified windowed mode window.  If the
 *  window is a full screen window, this function does nothing.
 *
 *  __Do not use this function__ to move an already visible window unless you
 *  have very good reasons for doing so, as it will confuse and annoy the user.
 *
 *  The window manager may put limits on what positions are allowed.  GLFW
 *  cannot and should not override these limits.
 *
 *  @param[in] window The window to query.
 *  @param[in] xpos The x-coordinate of the upper-left corner of the client area.
 *  @param[in] ypos The y-coordinate of the upper-left corner of the client area.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_pos
 *  @sa glfwGetWindowPos
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSetWindowPos(GLFWwindow* window, int xpos, int ypos);

/*! @brief Retrieves the size of the client area of the specified window.
 *
 *  This function retrieves the size, in screen coordinates, of the client area
 *  of the specified window.  If you wish to retrieve the size of the
 *  framebuffer of the window in pixels, see @ref glfwGetFramebufferSize.
 *
 *  Any or all of the size arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` size arguments will be set to zero.
 *
 *  @param[in] window The window whose size to retrieve.
 *  @param[out] width Where to store the width, in screen coordinates, of the
 *  client area, or `NULL`.
 *  @param[out] height Where to store the height, in screen coordinates, of the
 *  client area, or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_size
 *  @sa glfwSetWindowSize
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwGetWindowSize(GLFWwindow* window, int* width, int* height);

/*! @brief Sets the size of the client area of the specified window.
 *
 *  This function sets the size, in screen coordinates, of the client area of
 *  the specified window.
 *
 *  For full screen windows, this function selects and switches to the resolution
 *  closest to the specified size, without affecting the window's context.  As
 *  the context is unaffected, the bit depths of the framebuffer remain
 *  unchanged.
 *
 *  The window manager may put limits on what sizes are allowed.  GLFW cannot
 *  and should not override these limits.
 *
 *  @param[in] window The window to resize.
 *  @param[in] width The desired width of the specified window.
 *  @param[in] height The desired height of the specified window.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_size
 *  @sa glfwGetWindowSize
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSetWindowSize(GLFWwindow* window, int width, int height);

/*! @brief Retrieves the size of the framebuffer of the specified window.
 *
 *  This function retrieves the size, in pixels, of the framebuffer of the
 *  specified window.  If you wish to retrieve the size of the window in screen
 *  coordinates, see @ref glfwGetWindowSize.
 *
 *  Any or all of the size arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` size arguments will be set to zero.
 *
 *  @param[in] window The window whose framebuffer to query.
 *  @param[out] width Where to store the width, in pixels, of the framebuffer,
 *  or `NULL`.
 *  @param[out] height Where to store the height, in pixels, of the framebuffer,
 *  or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_fbsize
 *  @sa glfwSetFramebufferSizeCallback
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwGetFramebufferSize(GLFWwindow* window, int* width, int* height);

/*! @brief Retrieves the size of the frame of the window.
 *
 *  This function retrieves the size, in screen coordinates, of each edge of the
 *  frame of the specified window.  This size includes the title bar, if the
 *  window has one.  The size of the frame may vary depending on the
 *  [window-related hints](@ref window_hints_wnd) used to create it.
 *
 *  Because this function retrieves the size of each window frame edge and not
 *  the offset along a particular coordinate axis, the retrieved values will
 *  always be zero or positive.
 *
 *  Any or all of the size arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` size arguments will be set to zero.
 *
 *  @param[in] window The window whose frame size to query.
 *  @param[out] left Where to store the size, in screen coordinates, of the left
 *  edge of the window frame, or `NULL`.
 *  @param[out] top Where to store the size, in screen coordinates, of the top
 *  edge of the window frame, or `NULL`.
 *  @param[out] right Where to store the size, in screen coordinates, of the
 *  right edge of the window frame, or `NULL`.
 *  @param[out] bottom Where to store the size, in screen coordinates, of the
 *  bottom edge of the window frame, or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_size
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup window
 */
GLFWAPI void glfwGetWindowFrameSize(GLFWwindow* window, int* left, int* top, int* right, int* bottom);

/*! @brief Iconifies the specified window.
 *
 *  This function iconifies (minimizes) the specified window if it was
 *  previously restored.  If the window is already iconified, this function does
 *  nothing.
 *
 *  If the specified window is a full screen window, the original monitor
 *  resolution is restored until the window is restored.
 *
 *  @param[in] window The window to iconify.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_iconify
 *  @sa glfwRestoreWindow
 *
 *  @since Added in GLFW 2.1.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwIconifyWindow(GLFWwindow* window);

/*! @brief Restores the specified window.
 *
 *  This function restores the specified window if it was previously iconified
 *  (minimized).  If the window is already restored, this function does nothing.
 *
 *  If the specified window is a full screen window, the resolution chosen for
 *  the window is restored on the selected monitor.
 *
 *  @param[in] window The window to restore.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_iconify
 *  @sa glfwIconifyWindow
 *
 *  @since Added in GLFW 2.1.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwRestoreWindow(GLFWwindow* window);

/*! @brief Makes the specified window visible.
 *
 *  This function makes the specified window visible if it was previously
 *  hidden.  If the window is already visible or is in full screen mode, this
 *  function does nothing.
 *
 *  @param[in] window The window to make visible.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_hide
 *  @sa glfwHideWindow
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwShowWindow(GLFWwindow* window);

/*! @brief Hides the specified window.
 *
 *  This function hides the specified window if it was previously visible.  If
 *  the window is already hidden or is in full screen mode, this function does
 *  nothing.
 *
 *  @param[in] window The window to hide.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_hide
 *  @sa glfwShowWindow
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwHideWindow(GLFWwindow* window);

/*! @brief Returns the monitor that the window uses for full screen mode.
 *
 *  This function returns the handle of the monitor that the specified window is
 *  in full screen on.
 *
 *  @param[in] window The window to query.
 *  @return The monitor, or `NULL` if the window is in windowed mode or an error
 *  occurred.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_monitor
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI GLFWmonitor* glfwGetWindowMonitor(GLFWwindow* window);

/*! @brief Returns an attribute of the specified window.
 *
 *  This function returns the value of an attribute of the specified window or
 *  its OpenGL or OpenGL ES context.
 *
 *  @param[in] window The window to query.
 *  @param[in] attrib The [window attribute](@ref window_attribs) whose value to
 *  return.
 *  @return The value of the attribute, or zero if an
 *  [error](@ref error_handling) occurred.
 *
 *  @remarks Framebuffer related hints are not window attributes.  See @ref
 *  window_attribs_fb for more information.
 *
 *  @remarks Zero is a valid value for many window and context related
 *  attributes so you cannot use a return value of zero as an indication of
 *  errors.  However, this function should not fail as long as it is passed
 *  valid arguments and the library has been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_attribs
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwGetWindowParam` and
 *  `glfwGetGLVersion`.
 *
 *  @ingroup window
 */
GLFWAPI int glfwGetWindowAttrib(GLFWwindow* window, int attrib);

/*! @brief Sets the user pointer of the specified window.
 *
 *  This function sets the user-defined pointer of the specified window.  The
 *  current value is retained until the window is destroyed.  The initial value
 *  is `NULL`.
 *
 *  @param[in] window The window whose pointer to set.
 *  @param[in] pointer The new value.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.  Access is not synchronized.
 *
 *  @sa @ref window_userptr
 *  @sa glfwGetWindowUserPointer
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSetWindowUserPointer(GLFWwindow* window, void* pointer);

/*! @brief Returns the user pointer of the specified window.
 *
 *  This function returns the current value of the user-defined pointer of the
 *  specified window.  The initial value is `NULL`.
 *
 *  @param[in] window The window whose pointer to return.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.  Access is not synchronized.
 *
 *  @sa @ref window_userptr
 *  @sa glfwSetWindowUserPointer
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI void* glfwGetWindowUserPointer(GLFWwindow* window);

/*! @brief Sets the position callback for the specified window.
 *
 *  This function sets the position callback of the specified window, which is
 *  called when the window is moved.  The callback is provided with the screen
 *  position of the upper-left corner of the client area of the window.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_pos
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* window, GLFWwindowposfun cbfun);

/*! @brief Sets the size callback for the specified window.
 *
 *  This function sets the size callback of the specified window, which is
 *  called when the window is resized.  The callback is provided with the size,
 *  in screen coordinates, of the client area of the window.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_size
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, GLFWwindowsizefun cbfun);

/*! @brief Sets the close callback for the specified window.
 *
 *  This function sets the close callback of the specified window, which is
 *  called when the user attempts to close the window, for example by clicking
 *  the close widget in the title bar.
 *
 *  The close flag is set before this callback is called, but you can modify it
 *  at any time with @ref glfwSetWindowShouldClose.
 *
 *  The close callback is not triggered by @ref glfwDestroyWindow.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @remarks __OS X:__ Selecting Quit from the application menu will
 *  trigger the close callback for all windows.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_close
 *
 *  @since Added in GLFW 2.5.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* window, GLFWwindowclosefun cbfun);

/*! @brief Sets the refresh callback for the specified window.
 *
 *  This function sets the refresh callback of the specified window, which is
 *  called when the client area of the window needs to be redrawn, for example
 *  if the window has been exposed after having been covered by another window.
 *
 *  On compositing window systems such as Aero, Compiz or Aqua, where the window
 *  contents are saved off-screen, this callback may be called only very
 *  infrequently or never at all.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_refresh
 *
 *  @since Added in GLFW 2.5.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* window, GLFWwindowrefreshfun cbfun);

/*! @brief Sets the focus callback for the specified window.
 *
 *  This function sets the focus callback of the specified window, which is
 *  called when the window gains or loses input focus.
 *
 *  After the focus callback is called for a window that lost input focus,
 *  synthetic key and mouse button release events will be generated for all such
 *  that had been pressed.  For more information, see @ref glfwSetKeyCallback
 *  and @ref glfwSetMouseButtonCallback.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_focus
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowfocusfun glfwSetWindowFocusCallback(GLFWwindow* window, GLFWwindowfocusfun cbfun);

/*! @brief Sets the iconify callback for the specified window.
 *
 *  This function sets the iconification callback of the specified window, which
 *  is called when the window is iconified or restored.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_iconify
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI GLFWwindowiconifyfun glfwSetWindowIconifyCallback(GLFWwindow* window, GLFWwindowiconifyfun cbfun);

/*! @brief Sets the framebuffer resize callback for the specified window.
 *
 *  This function sets the framebuffer resize callback of the specified window,
 *  which is called when the framebuffer of the specified window is resized.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref window_fbsize
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup window
 */
GLFWAPI GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* window, GLFWframebuffersizefun cbfun);

/*! @brief Processes all pending events.
 *
 *  This function processes only those events that are already in the event
 *  queue and then returns immediately.  Processing events will cause the window
 *  and input callbacks associated with those events to be called.
 *
 *  On some platforms, a window move, resize or menu operation will cause event
 *  processing to block.  This is due to how event processing is designed on
 *  those platforms.  You can use the
 *  [window refresh callback](@ref window_refresh) to redraw the contents of
 *  your window when necessary during such operations.
 *
 *  On some platforms, certain events are sent directly to the application
 *  without going through the event queue, causing callbacks to be called
 *  outside of a call to one of the event processing functions.
 *
 *  Event processing is not required for joystick input to work.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref events
 *  @sa glfwWaitEvents
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup window
 */
GLFWAPI void glfwPollEvents(void);

/*! @brief Waits until events are queued and processes them.
 *
 *  This function puts the calling thread to sleep until at least one event is
 *  available in the event queue.  Once one or more events are available,
 *  it behaves exactly like @ref glfwPollEvents, i.e. the events in the queue
 *  are processed and the function then returns immediately.  Processing events
 *  will cause the window and input callbacks associated with those events to be
 *  called.
 *
 *  Since not all events are associated with callbacks, this function may return
 *  without a callback having been called even if you are monitoring all
 *  callbacks.
 *
 *  On some platforms, a window move, resize or menu operation will cause event
 *  processing to block.  This is due to how event processing is designed on
 *  those platforms.  You can use the
 *  [window refresh callback](@ref window_refresh) to redraw the contents of
 *  your window when necessary during such operations.
 *
 *  On some platforms, certain callbacks may be called outside of a call to one
 *  of the event processing functions.
 *
 *  If no windows exist, this function returns immediately.  For synchronization
 *  of threads in applications that do not create windows, use your threading
 *  library of choice.
 *
 *  Event processing is not required for joystick input to work.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref events
 *  @sa glfwPollEvents
 *
 *  @since Added in GLFW 2.5.
 *
 *  @ingroup window
 */
GLFWAPI void glfwWaitEvents(void);

/*! @brief Posts an empty event to the event queue.
 *
 *  This function posts an empty event from the current thread to the event
 *  queue, causing @ref glfwWaitEvents to return.
 *
 *  If no windows exist, this function returns immediately.  For synchronization
 *  of threads in applications that do not create windows, use your threading
 *  library of choice.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref events
 *  @sa glfwWaitEvents
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup window
 */
GLFWAPI void glfwPostEmptyEvent(void);

/*! @brief Returns the value of an input option for the specified window.
 *
 *  This function returns the value of an input option for the specified window.
 *  The mode must be one of `GLFW_CURSOR`, `GLFW_STICKY_KEYS` or
 *  `GLFW_STICKY_MOUSE_BUTTONS`.
 *
 *  @param[in] window The window to query.
 *  @param[in] mode One of `GLFW_CURSOR`, `GLFW_STICKY_KEYS` or
 *  `GLFW_STICKY_MOUSE_BUTTONS`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa glfwSetInputMode
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup input
 */
GLFWAPI int glfwGetInputMode(GLFWwindow* window, int mode);

/*! @brief Sets an input option for the specified window.
 *
 *  This function sets an input mode option for the specified window.  The mode
 *  must be one of `GLFW_CURSOR`, `GLFW_STICKY_KEYS` or
 *  `GLFW_STICKY_MOUSE_BUTTONS`.
 *
 *  If the mode is `GLFW_CURSOR`, the value must be one of the following cursor
 *  modes:
 *  - `GLFW_CURSOR_NORMAL` makes the cursor visible and behaving normally.
 *  - `GLFW_CURSOR_HIDDEN` makes the cursor invisible when it is over the client
 *    area of the window but does not restrict the cursor from leaving.
 *  - `GLFW_CURSOR_DISABLED` hides and grabs the cursor, providing virtual
 *    and unlimited cursor movement.  This is useful for implementing for
 *    example 3D camera controls.
 *
 *  If the mode is `GLFW_STICKY_KEYS`, the value must be either `GL_TRUE` to
 *  enable sticky keys, or `GL_FALSE` to disable it.  If sticky keys are
 *  enabled, a key press will ensure that @ref glfwGetKey returns `GLFW_PRESS`
 *  the next time it is called even if the key had been released before the
 *  call.  This is useful when you are only interested in whether keys have been
 *  pressed but not when or in which order.
 *
 *  If the mode is `GLFW_STICKY_MOUSE_BUTTONS`, the value must be either
 *  `GL_TRUE` to enable sticky mouse buttons, or `GL_FALSE` to disable it.  If
 *  sticky mouse buttons are enabled, a mouse button press will ensure that @ref
 *  glfwGetMouseButton returns `GLFW_PRESS` the next time it is called even if
 *  the mouse button had been released before the call.  This is useful when you
 *  are only interested in whether mouse buttons have been pressed but not when
 *  or in which order.
 *
 *  @param[in] window The window whose input mode to set.
 *  @param[in] mode One of `GLFW_CURSOR`, `GLFW_STICKY_KEYS` or
 *  `GLFW_STICKY_MOUSE_BUTTONS`.
 *  @param[in] value The new value of the specified input mode.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa glfwGetInputMode
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwEnable` and `glfwDisable`.
 *
 *  @ingroup input
 */
GLFWAPI void glfwSetInputMode(GLFWwindow* window, int mode, int value);

/*! @brief Returns the last reported state of a keyboard key for the specified
 *  window.
 *
 *  This function returns the last state reported for the specified key to the
 *  specified window.  The returned state is one of `GLFW_PRESS` or
 *  `GLFW_RELEASE`.  The higher-level action `GLFW_REPEAT` is only reported to
 *  the key callback.
 *
 *  If the `GLFW_STICKY_KEYS` input mode is enabled, this function returns
 *  `GLFW_PRESS` the first time you call it for a key that was pressed, even if
 *  that key has already been released.
 *
 *  The key functions deal with physical keys, with [key tokens](@ref keys)
 *  named after their use on the standard US keyboard layout.  If you want to
 *  input text, use the Unicode character callback instead.
 *
 *  The [modifier key bit masks](@ref mods) are not key tokens and cannot be
 *  used with this function.
 *
 *  @param[in] window The desired window.
 *  @param[in] key The desired [keyboard key](@ref keys).  `GLFW_KEY_UNKNOWN` is
 *  not a valid key for this function.
 *  @return One of `GLFW_PRESS` or `GLFW_RELEASE`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_key
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup input
 */
GLFWAPI int glfwGetKey(GLFWwindow* window, int key);

/*! @brief Returns the last reported state of a mouse button for the specified
 *  window.
 *
 *  This function returns the last state reported for the specified mouse button
 *  to the specified window.  The returned state is one of `GLFW_PRESS` or
 *  `GLFW_RELEASE`.
 *
 *  If the `GLFW_STICKY_MOUSE_BUTTONS` input mode is enabled, this function
 *  `GLFW_PRESS` the first time you call it for a mouse button that was pressed,
 *  even if that mouse button has already been released.
 *
 *  @param[in] window The desired window.
 *  @param[in] button The desired [mouse button](@ref buttons).
 *  @return One of `GLFW_PRESS` or `GLFW_RELEASE`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_mouse_button
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup input
 */
GLFWAPI int glfwGetMouseButton(GLFWwindow* window, int button);

/*! @brief Retrieves the position of the cursor relative to the client area of
 *  the window.
 *
 *  This function returns the position of the cursor, in screen coordinates,
 *  relative to the upper-left corner of the client area of the specified
 *  window.
 *
 *  If the cursor is disabled (with `GLFW_CURSOR_DISABLED`) then the cursor
 *  position is unbounded and limited only by the minimum and maximum values of
 *  a `double`.
 *
 *  The coordinate can be converted to their integer equivalents with the
 *  `floor` function.  Casting directly to an integer type works for positive
 *  coordinates, but fails for negative ones.
 *
 *  Any or all of the position arguments may be `NULL`.  If an error occurs, all
 *  non-`NULL` position arguments will be set to zero.
 *
 *  @param[in] window The desired window.
 *  @param[out] xpos Where to store the cursor x-coordinate, relative to the
 *  left edge of the client area, or `NULL`.
 *  @param[out] ypos Where to store the cursor y-coordinate, relative to the to
 *  top edge of the client area, or `NULL`.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_pos
 *  @sa glfwSetCursorPos
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwGetMousePos`.
 *
 *  @ingroup input
 */
GLFWAPI void glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);

/*! @brief Sets the position of the cursor, relative to the client area of the
 *  window.
 *
 *  This function sets the position, in screen coordinates, of the cursor
 *  relative to the upper-left corner of the client area of the specified
 *  window.  The window must have input focus.  If the window does not have
 *  input focus when this function is called, it fails silently.
 *
 *  __Do not use this function__ to implement things like camera controls.  GLFW
 *  already provides the `GLFW_CURSOR_DISABLED` cursor mode that hides the
 *  cursor, transparently re-centers it and provides unconstrained cursor
 *  motion.  See @ref glfwSetInputMode for more information.
 *
 *  If the cursor mode is `GLFW_CURSOR_DISABLED` then the cursor position is
 *  unconstrained and limited only by the minimum and maximum values of
 *  a `double`.
 *
 *  @param[in] window The desired window.
 *  @param[in] xpos The desired x-coordinate, relative to the left edge of the
 *  client area.
 *  @param[in] ypos The desired y-coordinate, relative to the top edge of the
 *  client area.
 *
 *  @remarks __X11:__ Due to the asynchronous nature of X11, it may take
 *  a moment for the window focus event to arrive.  This means you may not be
 *  able to set the cursor position directly after window creation.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_pos
 *  @sa glfwGetCursorPos
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwSetMousePos`.
 *
 *  @ingroup input
 */
GLFWAPI void glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);

/*! @brief Creates a custom cursor.
 *
 *  Creates a new custom cursor image that can be set for a window with @ref
 *  glfwSetCursor.  The cursor can be destroyed with @ref glfwDestroyCursor.
 *  Any remaining cursors are destroyed by @ref glfwTerminate.
 *
 *  The pixels are 32-bit, little-endian, non-premultiplied RGBA, i.e. eight
 *  bits per channel.  They are arranged canonically as packed sequential rows,
 *  starting from the top-left corner.
 *
 *  The cursor hotspot is specified in pixels, relative to the upper-left corner
 *  of the cursor image.  Like all other coordinate systems in GLFW, the X-axis
 *  points to the right and the Y-axis points down.
 *
 *  @param[in] image The desired cursor image.
 *  @param[in] xhot The desired x-coordinate, in pixels, of the cursor hotspot.
 *  @param[in] yhot The desired y-coordinate, in pixels, of the cursor hotspot.
 *
 *  @return The handle of the created cursor, or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The specified image data is copied before this function returns.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_object
 *  @sa glfwDestroyCursor
 *  @sa glfwCreateStandardCursor
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcursor* glfwCreateCursor(const GLFWimage* image, int xhot, int yhot);

/*! @brief Creates a cursor with a standard shape.
 *
 *  Returns a cursor with a [standard shape](@ref shapes), that can be set for
 *  a window with @ref glfwSetCursor.
 *
 *  @param[in] shape One of the [standard shapes](@ref shapes).
 *
 *  @return A new cursor ready to use or `NULL` if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_object
 *  @sa glfwCreateCursor
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcursor* glfwCreateStandardCursor(int shape);

/*! @brief Destroys a cursor.
 *
 *  This function destroys a cursor previously created with @ref
 *  glfwCreateCursor.  Any remaining cursors will be destroyed by @ref
 *  glfwTerminate.
 *
 *  @param[in] cursor The cursor object to destroy.
 *
 *  @par Reentrancy
 *  This function may not be called from a callback.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_object
 *  @sa glfwCreateCursor
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI void glfwDestroyCursor(GLFWcursor* cursor);

/*! @brief Sets the cursor for the window.
 *
 *  This function sets the cursor image to be used when the cursor is over the
 *  client area of the specified window.  The set cursor will only be visible
 *  when the [cursor mode](@ref cursor_mode) of the window is
 *  `GLFW_CURSOR_NORMAL`.
 *
 *  On some platforms, the set cursor may not be visible unless the window also
 *  has input focus.
 *
 *  @param[in] window The window to set the cursor for.
 *  @param[in] cursor The cursor to set, or `NULL` to switch back to the default
 *  arrow cursor.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_object
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI void glfwSetCursor(GLFWwindow* window, GLFWcursor* cursor);

/*! @brief Sets the key callback.
 *
 *  This function sets the key callback of the specified window, which is called
 *  when a key is pressed, repeated or released.
 *
 *  The key functions deal with physical keys, with layout independent
 *  [key tokens](@ref keys) named after their values in the standard US keyboard
 *  layout.  If you want to input text, use the
 *  [character callback](@ref glfwSetCharCallback) instead.
 *
 *  When a window loses input focus, it will generate synthetic key release
 *  events for all pressed keys.  You can tell these events from user-generated
 *  events by the fact that the synthetic ones are generated after the focus
 *  loss event has been processed, i.e. after the
 *  [window focus callback](@ref glfwSetWindowFocusCallback) has been called.
 *
 *  The scancode of a key is specific to that platform or sometimes even to that
 *  machine.  Scancodes are intended to allow users to bind keys that don't have
 *  a GLFW key token.  Such keys have `key` set to `GLFW_KEY_UNKNOWN`, their
 *  state is not saved and so it cannot be queried with @ref glfwGetKey.
 *
 *  Sometimes GLFW needs to generate synthetic key events, in which case the
 *  scancode may be zero.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new key callback, or `NULL` to remove the currently
 *  set callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_key
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup input
 */
GLFWAPI GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun cbfun);

/*! @brief Sets the Unicode character callback.
 *
 *  This function sets the character callback of the specified window, which is
 *  called when a Unicode character is input.
 *
 *  The character callback is intended for Unicode text input.  As it deals with
 *  characters, it is keyboard layout dependent, whereas the
 *  [key callback](@ref glfwSetKeyCallback) is not.  Characters do not map 1:1
 *  to physical keys, as a key may produce zero, one or more characters.  If you
 *  want to know whether a specific physical key was pressed or released, see
 *  the key callback instead.
 *
 *  The character callback behaves as system text input normally does and will
 *  not be called if modifier keys are held down that would prevent normal text
 *  input on that platform, for example a Super (Command) key on OS X or Alt key
 *  on Windows.  There is a
 *  [character with modifiers callback](@ref glfwSetCharModsCallback) that
 *  receives these events.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_char
 *
 *  @since Added in GLFW 2.4.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun cbfun);

/*! @brief Sets the Unicode character with modifiers callback.
 *
 *  This function sets the character with modifiers callback of the specified
 *  window, which is called when a Unicode character is input regardless of what
 *  modifier keys are used.
 *
 *  The character with modifiers callback is intended for implementing custom
 *  Unicode character input.  For regular Unicode text input, see the
 *  [character callback](@ref glfwSetCharCallback).  Like the character
 *  callback, the character with modifiers callback deals with characters and is
 *  keyboard layout dependent.  Characters do not map 1:1 to physical keys, as
 *  a key may produce zero, one or more characters.  If you want to know whether
 *  a specific physical key was pressed or released, see the
 *  [key callback](@ref glfwSetKeyCallback) instead.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or an
 *  error occurred.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_char
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcharmodsfun glfwSetCharModsCallback(GLFWwindow* window, GLFWcharmodsfun cbfun);

/*! @brief Sets the mouse button callback.
 *
 *  This function sets the mouse button callback of the specified window, which
 *  is called when a mouse button is pressed or released.
 *
 *  When a window loses input focus, it will generate synthetic mouse button
 *  release events for all pressed mouse buttons.  You can tell these events
 *  from user-generated events by the fact that the synthetic ones are generated
 *  after the focus loss event has been processed, i.e. after the
 *  [window focus callback](@ref glfwSetWindowFocusCallback) has been called.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref input_mouse_button
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.  Updated callback signature.
 *
 *  @ingroup input
 */
GLFWAPI GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun cbfun);

/*! @brief Sets the cursor position callback.
 *
 *  This function sets the cursor position callback of the specified window,
 *  which is called when the cursor is moved.  The callback is provided with the
 *  position, in screen coordinates, relative to the upper-left corner of the
 *  client area of the window.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_pos
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwSetMousePosCallback`.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun cbfun);

/*! @brief Sets the cursor enter/exit callback.
 *
 *  This function sets the cursor boundary crossing callback of the specified
 *  window, which is called when the cursor enters or leaves the client area of
 *  the window.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new callback, or `NULL` to remove the currently set
 *  callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref cursor_enter
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup input
 */
GLFWAPI GLFWcursorenterfun glfwSetCursorEnterCallback(GLFWwindow* window, GLFWcursorenterfun cbfun);

/*! @brief Sets the scroll callback.
 *
 *  This function sets the scroll callback of the specified window, which is
 *  called when a scrolling device is used, such as a mouse wheel or scrolling
 *  area of a touchpad.
 *
 *  The scroll callback receives all scrolling input, like that from a mouse
 *  wheel or a touchpad scrolling area.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new scroll callback, or `NULL` to remove the currently
 *  set callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref scrolling
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwSetMouseWheelCallback`.
 *
 *  @ingroup input
 */
GLFWAPI GLFWscrollfun glfwSetScrollCallback(GLFWwindow* window, GLFWscrollfun cbfun);

/*! @brief Sets the file drop callback.
 *
 *  This function sets the file drop callback of the specified window, which is
 *  called when one or more dragged files are dropped on the window.
 *
 *  Because the path array and its strings may have been generated specifically
 *  for that event, they are not guaranteed to be valid after the callback has
 *  returned.  If you wish to use them after the callback returns, you need to
 *  make a deep copy.
 *
 *  @param[in] window The window whose callback to set.
 *  @param[in] cbfun The new file drop callback, or `NULL` to remove the
 *  currently set callback.
 *  @return The previously set callback, or `NULL` if no callback was set or the
 *  library had not been [initialized](@ref intro_init).
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref path_drop
 *
 *  @since Added in GLFW 3.1.
 *
 *  @ingroup input
 */
GLFWAPI GLFWdropfun glfwSetDropCallback(GLFWwindow* window, GLFWdropfun cbfun);

/*! @brief Returns whether the specified joystick is present.
 *
 *  This function returns whether the specified joystick is present.
 *
 *  @param[in] joy The [joystick](@ref joysticks) to query.
 *  @return `GL_TRUE` if the joystick is present, or `GL_FALSE` otherwise.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref joystick
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwGetJoystickParam`.
 *
 *  @ingroup input
 */
GLFWAPI int glfwJoystickPresent(int joy);

/*! @brief Returns the values of all axes of the specified joystick.
 *
 *  This function returns the values of all axes of the specified joystick.
 *  Each element in the array is a value between -1.0 and 1.0.
 *
 *  @param[in] joy The [joystick](@ref joysticks) to query.
 *  @param[out] count Where to store the number of axis values in the returned
 *  array.  This is set to zero if an error occurred.
 *  @return An array of axis values, or `NULL` if the joystick is not present.
 *
 *  @par Pointer Lifetime
 *  The returned array is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified joystick is disconnected, this
 *  function is called again for that joystick or the library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref joystick_axis
 *
 *  @since Added in GLFW 3.0.  Replaces `glfwGetJoystickPos`.
 *
 *  @ingroup input
 */
GLFWAPI const float* glfwGetJoystickAxes(int joy, int* count);

/*! @brief Returns the state of all buttons of the specified joystick.
 *
 *  This function returns the state of all buttons of the specified joystick.
 *  Each element in the array is either `GLFW_PRESS` or `GLFW_RELEASE`.
 *
 *  @param[in] joy The [joystick](@ref joysticks) to query.
 *  @param[out] count Where to store the number of button states in the returned
 *  array.  This is set to zero if an error occurred.
 *  @return An array of button states, or `NULL` if the joystick is not present.
 *
 *  @par Pointer Lifetime
 *  The returned array is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified joystick is disconnected, this
 *  function is called again for that joystick or the library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref joystick_button
 *
 *  @since Added in GLFW 2.2.
 *
 *  @par
 *  __GLFW 3:__ Changed to return a dynamic array.
 *
 *  @ingroup input
 */
GLFWAPI const unsigned char* glfwGetJoystickButtons(int joy, int* count);

/*! @brief Returns the name of the specified joystick.
 *
 *  This function returns the name, encoded as UTF-8, of the specified joystick.
 *  The returned string is allocated and freed by GLFW.  You should not free it
 *  yourself.
 *
 *  @param[in] joy The [joystick](@ref joysticks) to query.
 *  @return The UTF-8 encoded name of the joystick, or `NULL` if the joystick
 *  is not present.
 *
 *  @par Pointer Lifetime
 *  The returned string is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the specified joystick is disconnected, this
 *  function is called again for that joystick or the library is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref joystick_name
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup input
 */
GLFWAPI const char* glfwGetJoystickName(int joy);

/*! @brief Sets the clipboard to the specified string.
 *
 *  This function sets the system clipboard to the specified, UTF-8 encoded
 *  string.
 *
 *  @param[in] window The window that will own the clipboard contents.
 *  @param[in] string A UTF-8 encoded string.
 *
 *  @par Pointer Lifetime
 *  The specified string is copied before this function returns.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref clipboard
 *  @sa glfwGetClipboardString
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup input
 */
GLFWAPI void glfwSetClipboardString(GLFWwindow* window, const char* string);

/*! @brief Returns the contents of the clipboard as a string.
 *
 *  This function returns the contents of the system clipboard, if it contains
 *  or is convertible to a UTF-8 encoded string.  If the clipboard is empty or
 *  if its contents cannot be converted, `NULL` is returned and a @ref
 *  GLFW_FORMAT_UNAVAILABLE error is generated.
 *
 *  @param[in] window The window that will request the clipboard contents.
 *  @return The contents of the clipboard as a UTF-8 encoded string, or `NULL`
 *  if an [error](@ref error_handling) occurred.
 *
 *  @par Pointer Lifetime
 *  The returned string is allocated and freed by GLFW.  You should not free it
 *  yourself.  It is valid until the next call to @ref
 *  glfwGetClipboardString or @ref glfwSetClipboardString, or until the library
 *  is terminated.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref clipboard
 *  @sa glfwSetClipboardString
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup input
 */
GLFWAPI const char* glfwGetClipboardString(GLFWwindow* window);

/*! @brief Returns the value of the GLFW timer.
 *
 *  This function returns the value of the GLFW timer.  Unless the timer has
 *  been set using @ref glfwSetTime, the timer measures time elapsed since GLFW
 *  was initialized.
 *
 *  The resolution of the timer is system dependent, but is usually on the order
 *  of a few micro- or nanoseconds.  It uses the highest-resolution monotonic
 *  time source on each supported platform.
 *
 *  @return The current value, in seconds, or zero if an
 *  [error](@ref error_handling) occurred.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.  Access is not synchronized.
 *
 *  @sa @ref time
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup input
 */
GLFWAPI double glfwGetTime(void);

/*! @brief Sets the GLFW timer.
 *
 *  This function sets the value of the GLFW timer.  It then continues to count
 *  up from that value.  The value must be a positive finite number less than
 *  or equal to 18446744073.0, which is approximately 584.5 years.
 *
 *  @param[in] time The new value, in seconds.
 *
 *  @remarks The upper limit of the timer is calculated as
 *  floor((2<sup>64</sup> - 1) / 10<sup>9</sup>) and is due to implementations
 *  storing nanoseconds in 64 bits.  The limit may be increased in the future.
 *
 *  @par Thread Safety
 *  This function may only be called from the main thread.
 *
 *  @sa @ref time
 *
 *  @since Added in GLFW 2.2.
 *
 *  @ingroup input
 */
GLFWAPI void glfwSetTime(double time);

/*! @brief Makes the context of the specified window current for the calling
 *  thread.
 *
 *  This function makes the OpenGL or OpenGL ES context of the specified window
 *  current on the calling thread.  A context can only be made current on
 *  a single thread at a time and each thread can have only a single current
 *  context at a time.
 *
 *  By default, making a context non-current implicitly forces a pipeline flush.
 *  On machines that support `GL_KHR_context_flush_control`, you can control
 *  whether a context performs this flush by setting the
 *  [GLFW_CONTEXT_RELEASE_BEHAVIOR](@ref window_hints_ctx) window hint.
 *
 *  @param[in] window The window whose context to make current, or `NULL` to
 *  detach the current context.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref context_current
 *  @sa glfwGetCurrentContext
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup context
 */
GLFWAPI void glfwMakeContextCurrent(GLFWwindow* window);

/*! @brief Returns the window whose context is current on the calling thread.
 *
 *  This function returns the window whose OpenGL or OpenGL ES context is
 *  current on the calling thread.
 *
 *  @return The window whose context is current, or `NULL` if no window's
 *  context is current.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref context_current
 *  @sa glfwMakeContextCurrent
 *
 *  @since Added in GLFW 3.0.
 *
 *  @ingroup context
 */
GLFWAPI GLFWwindow* glfwGetCurrentContext(void);

/*! @brief Swaps the front and back buffers of the specified window.
 *
 *  This function swaps the front and back buffers of the specified window.  If
 *  the swap interval is greater than zero, the GPU driver waits the specified
 *  number of screen updates before swapping the buffers.
 *
 *  @param[in] window The window whose buffers to swap.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref buffer_swap
 *  @sa glfwSwapInterval
 *
 *  @since Added in GLFW 1.0.
 *
 *  @par
 *  __GLFW 3:__ Added window handle parameter.
 *
 *  @ingroup window
 */
GLFWAPI void glfwSwapBuffers(GLFWwindow* window);

/*! @brief Sets the swap interval for the current context.
 *
 *  This function sets the swap interval for the current context, i.e. the
 *  number of screen updates to wait from the time @ref glfwSwapBuffers was
 *  called before swapping the buffers and returning.  This is sometimes called
 *  _vertical synchronization_, _vertical retrace synchronization_ or just
 *  _vsync_.
 *
 *  Contexts that support either of the `WGL_EXT_swap_control_tear` and
 *  `GLX_EXT_swap_control_tear` extensions also accept negative swap intervals,
 *  which allow the driver to swap even if a frame arrives a little bit late.
 *  You can check for the presence of these extensions using @ref
 *  glfwExtensionSupported.  For more information about swap tearing, see the
 *  extension specifications.
 *
 *  A context must be current on the calling thread.  Calling this function
 *  without a current context will cause a @ref GLFW_NO_CURRENT_CONTEXT error.
 *
 *  @param[in] interval The minimum number of screen updates to wait for
 *  until the buffers are swapped by @ref glfwSwapBuffers.
 *
 *  @remarks This function is not called during context creation, leaving the
 *  swap interval set to whatever is the default on that platform.  This is done
 *  because some swap interval extensions used by GLFW do not allow the swap
 *  interval to be reset to zero once it has been set to a non-zero value.
 *
 *  @remarks Some GPU drivers do not honor the requested swap interval, either
 *  because of a user setting that overrides the application's request or due to
 *  bugs in the driver.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref buffer_swap
 *  @sa glfwSwapBuffers
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup context
 */
GLFWAPI void glfwSwapInterval(int interval);

/*! @brief Returns whether the specified extension is available.
 *
 *  This function returns whether the specified
 *  [client API extension](@ref context_glext) is supported by the current
 *  OpenGL or OpenGL ES context.  It searches both for OpenGL and OpenGL ES
 *  extension and platform-specific context creation API extensions.
 *
 *  A context must be current on the calling thread.  Calling this function
 *  without a current context will cause a @ref GLFW_NO_CURRENT_CONTEXT error.
 *
 *  As this functions retrieves and searches one or more extension strings each
 *  call, it is recommended that you cache its results if it is going to be used
 *  frequently.  The extension strings will not change during the lifetime of
 *  a context, so there is no danger in doing this.
 *
 *  @param[in] extension The ASCII encoded name of the extension.
 *  @return `GL_TRUE` if the extension is available, or `GL_FALSE` otherwise.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref context_glext
 *  @sa glfwGetProcAddress
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup context
 */
GLFWAPI int glfwExtensionSupported(const char* extension);

/*! @brief Returns the address of the specified function for the current
 *  context.
 *
 *  This function returns the address of the specified
 *  [core or extension function](@ref context_glext), if it is supported
 *  by the current context.
 *
 *  A context must be current on the calling thread.  Calling this function
 *  without a current context will cause a @ref GLFW_NO_CURRENT_CONTEXT error.
 *
 *  @param[in] procname The ASCII encoded name of the function.
 *  @return The address of the function, or `NULL` if an [error](@ref
 *  error_handling) occurred.
 *
 *  @remarks The address of a given function is not guaranteed to be the same
 *  between contexts.
 *
 *  @remarks This function may return a non-`NULL` address despite the
 *  associated version or extension not being available.  Always check the
 *  context version or extension string first.
 *
 *  @par Pointer Lifetime
 *  The returned function pointer is valid until the context is destroyed or the
 *  library is terminated.
 *
 *  @par Thread Safety
 *  This function may be called from any thread.
 *
 *  @sa @ref context_glext
 *  @sa glfwExtensionSupported
 *
 *  @since Added in GLFW 1.0.
 *
 *  @ingroup context
 */
GLFWAPI GLFWglproc glfwGetProcAddress(const char* procname);


/*************************************************************************
 * Global definition cleanup
 *************************************************************************/

/* ------------------- BEGIN SYSTEM/COMPILER SPECIFIC -------------------- */

#ifdef GLFW_WINGDIAPI_DEFINED
 #undef WINGDIAPI
 #undef GLFW_WINGDIAPI_DEFINED
#endif

#ifdef GLFW_CALLBACK_DEFINED
 #undef CALLBACK
 #undef GLFW_CALLBACK_DEFINED
#endif

/* -------------------- END SYSTEM/COMPILER SPECIFIC --------------------- */


#ifdef __cplusplus
}
#endif

#endif /* _glfw3_h_ */

