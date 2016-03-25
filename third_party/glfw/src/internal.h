//========================================================================
// GLFW 3.2 - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2002-2006 Marcus Geelnard
// Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

#ifndef _glfw3_internal_h_
#define _glfw3_internal_h_


#if defined(_GLFW_USE_CONFIG_H)
 #include "glfw_config.h"
#endif

#if defined(GLFW_INCLUDE_GLCOREARB) || \
    defined(GLFW_INCLUDE_ES1)       || \
    defined(GLFW_INCLUDE_ES2)       || \
    defined(GLFW_INCLUDE_ES3)       || \
    defined(GLFW_INCLUDE_NONE)      || \
    defined(GLFW_INCLUDE_GLEXT)     || \
    defined(GLFW_INCLUDE_GLU)       || \
    defined(GLFW_DLL)
 #error "You must not define any header option macros when compiling GLFW"
#endif

#define GLFW_INCLUDE_NONE
#include "../include/GLFW/glfw3.h"

typedef int GLFWbool;

typedef struct _GLFWwndconfig   _GLFWwndconfig;
typedef struct _GLFWctxconfig   _GLFWctxconfig;
typedef struct _GLFWfbconfig    _GLFWfbconfig;
typedef struct _GLFWcontext     _GLFWcontext;
typedef struct _GLFWwindow      _GLFWwindow;
typedef struct _GLFWlibrary     _GLFWlibrary;
typedef struct _GLFWmonitor     _GLFWmonitor;
typedef struct _GLFWcursor      _GLFWcursor;

#define GL_VERSION 0x1f02
#define GL_NONE	0
#define GL_COLOR_BUFFER_BIT	0x00004000
#define GL_EXTENSIONS 0x1f03
#define GL_NUM_EXTENSIONS 0x821d
#define GL_CONTEXT_FLAGS 0x821e
#define GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT 0x00000001
#define GL_CONTEXT_FLAG_DEBUG_BIT 0x00000002
#define GL_CONTEXT_PROFILE_MASK 0x9126
#define GL_CONTEXT_COMPATIBILITY_PROFILE_BIT 0x00000002
#define GL_CONTEXT_CORE_PROFILE_BIT 0x00000001
#define GL_RESET_NOTIFICATION_STRATEGY_ARB 0x8256
#define GL_LOSE_CONTEXT_ON_RESET_ARB 0x8252
#define GL_NO_RESET_NOTIFICATION_ARB 0x8261
#define GL_CONTEXT_RELEASE_BEHAVIOR 0x82fb
#define GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH 0x82fc
#define GL_CONTEXT_FLAG_NO_ERROR_BIT_KHR 0x00000008

typedef int	GLint;
typedef unsigned int GLuint;
typedef unsigned int GLenum;
typedef unsigned int GLbitfield;
typedef unsigned char GLubyte;

typedef void (APIENTRY * PFNGLCLEARPROC)(GLbitfield);
typedef const GLubyte* (APIENTRY * PFNGLGETSTRINGPROC)(GLenum);
typedef void (APIENTRY * PFNGLGETINTEGERVPROC)(GLenum,GLint*);
typedef const GLubyte* (APIENTRY * PFNGLGETSTRINGIPROC)(GLenum,GLuint);

#define VK_NULL_HANDLE 0

typedef void* VkInstance;
typedef void* VkPhysicalDevice;
typedef GLFWuint64 VkSurfaceKHR;
typedef unsigned int VkFlags;
typedef unsigned int VkBool32;

typedef enum VkStructureType
{
    VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR = 1000004000,
    VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR = 1000005000,
    VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR = 1000006000,
    VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR = 1000007000,
    VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR = 1000009000,
    VK_STRUCTURE_TYPE_MAX_ENUM = 0x7FFFFFFF
} VkStructureType;

typedef enum VkResult
{
    VK_SUCCESS = 0,
    VK_NOT_READY = 1,
    VK_TIMEOUT = 2,
    VK_EVENT_SET = 3,
    VK_EVENT_RESET = 4,
    VK_INCOMPLETE = 5,
    VK_ERROR_OUT_OF_HOST_MEMORY = -1,
    VK_ERROR_OUT_OF_DEVICE_MEMORY = -2,
    VK_ERROR_INITIALIZATION_FAILED = -3,
    VK_ERROR_DEVICE_LOST = -4,
    VK_ERROR_MEMORY_MAP_FAILED = -5,
    VK_ERROR_LAYER_NOT_PRESENT = -6,
    VK_ERROR_EXTENSION_NOT_PRESENT = -7,
    VK_ERROR_FEATURE_NOT_PRESENT = -8,
    VK_ERROR_INCOMPATIBLE_DRIVER = -9,
    VK_ERROR_TOO_MANY_OBJECTS = -10,
    VK_ERROR_FORMAT_NOT_SUPPORTED = -11,
    VK_ERROR_SURFACE_LOST_KHR = -1000000000,
    VK_SUBOPTIMAL_KHR = 1000001003,
    VK_ERROR_OUT_OF_DATE_KHR = -1000001004,
    VK_ERROR_INCOMPATIBLE_DISPLAY_KHR = -1000003001,
    VK_ERROR_NATIVE_WINDOW_IN_USE_KHR = -1000000001,
    VK_ERROR_VALIDATION_FAILED_EXT = -1000011001,
    VK_RESULT_MAX_ENUM = 0x7FFFFFFF
} VkResult;

typedef struct VkAllocationCallbacks VkAllocationCallbacks;

typedef struct VkExtensionProperties
{
    char            extensionName[256];
    unsigned int    specVersion;
} VkExtensionProperties;

typedef void (APIENTRY * PFN_vkVoidFunction)(void);
typedef PFN_vkVoidFunction (APIENTRY * PFN_vkGetInstanceProcAddr)(VkInstance,const char*);
typedef VkResult (APIENTRY * PFN_vkEnumerateInstanceExtensionProperties)(const char*,unsigned int*,VkExtensionProperties*);

#define vkEnumerateInstanceExtensionProperties _glfw.vk.EnumerateInstanceExtensionProperties
#define vkGetInstanceProcAddr _glfw.vk.GetInstanceProcAddr

#if defined(_GLFW_COCOA)
 #include "cocoa_platform.h"
#elif defined(_GLFW_WIN32)
 #include "win32_platform.h"
#elif defined(_GLFW_X11)
 #include "x11_platform.h"
#elif defined(_GLFW_WAYLAND)
 #include "wl_platform.h"
#elif defined(_GLFW_MIR)
 #include "mir_platform.h"
#else
 #error "No supported window creation API selected"
#endif


//========================================================================
// Doxygen group definitions
//========================================================================

/*! @defgroup platform Platform interface
 *  @brief The interface implemented by the platform-specific code.
 *
 *  The platform API is the interface exposed by the platform-specific code for
 *  each platform and is called by the shared code of the public API It mirrors
 *  the public API except it uses objects instead of handles.
 */
/*! @defgroup event Event interface
 *  @brief The interface used by the platform-specific code to report events.
 *
 *  The event API is used by the platform-specific code to notify the shared
 *  code of events that can be translated into state changes and/or callback
 *  calls.
 */
/*! @defgroup utility Utility functions
 *  @brief Various utility functions for internal use.
 *
 *  These functions are shared code and may be used by any part of GLFW
 *  Each platform may add its own utility functions, but those must only be
 *  called by the platform-specific code
 */


//========================================================================
// Helper macros
//========================================================================

// Constructs a version number string from the public header macros
#define _GLFW_CONCAT_VERSION(m, n, r) #m "." #n "." #r
#define _GLFW_MAKE_VERSION(m, n, r) _GLFW_CONCAT_VERSION(m, n, r)
#define _GLFW_VERSION_NUMBER _GLFW_MAKE_VERSION(GLFW_VERSION_MAJOR, \
                                                GLFW_VERSION_MINOR, \
                                                GLFW_VERSION_REVISION)

// Checks for whether the library has been initialized
#define _GLFW_REQUIRE_INIT()                         \
    if (!_glfwInitialized)                           \
    {                                                \
        _glfwInputError(GLFW_NOT_INITIALIZED, NULL); \
        return;                                      \
    }
#define _GLFW_REQUIRE_INIT_OR_RETURN(x)              \
    if (!_glfwInitialized)                           \
    {                                                \
        _glfwInputError(GLFW_NOT_INITIALIZED, NULL); \
        return x;                                    \
    }

// Swaps the provided pointers
#define _GLFW_SWAP_POINTERS(x, y) \
    {                             \
        void* t;                  \
        t = x;                    \
        x = y;                    \
        y = t;                    \
    }


//========================================================================
// Platform-independent structures
//========================================================================

/*! @brief Window configuration.
 *
 *  Parameters relating to the creation of the window but not directly related
 *  to the framebuffer.  This is used to pass window creation parameters from
 *  shared code to the platform API.
 */
struct _GLFWwndconfig
{
    int           width;
    int           height;
    const char*   title;
    GLFWbool      resizable;
    GLFWbool      visible;
    GLFWbool      decorated;
    GLFWbool      focused;
    GLFWbool      autoIconify;
    GLFWbool      floating;
    GLFWbool      maximized;
};


/*! @brief Context configuration.
 *
 *  Parameters relating to the creation of the context but not directly related
 *  to the framebuffer.  This is used to pass context creation parameters from
 *  shared code to the platform API.
 */
struct _GLFWctxconfig
{
    int           api;
    int           major;
    int           minor;
    GLFWbool      forward;
    GLFWbool      debug;
    GLFWbool      noerror;
    int           profile;
    int           robustness;
    int           release;
    _GLFWwindow*  share;
};


/*! @brief Framebuffer configuration.
 *
 *  This describes buffers and their sizes.  It also contains
 *  a platform-specific ID used to map back to the backend API object.
 *
 *  It is used to pass framebuffer parameters from shared code to the platform
 *  API and also to enumerate and select available framebuffer configs.
 */
struct _GLFWfbconfig
{
    int         redBits;
    int         greenBits;
    int         blueBits;
    int         alphaBits;
    int         depthBits;
    int         stencilBits;
    int         accumRedBits;
    int         accumGreenBits;
    int         accumBlueBits;
    int         accumAlphaBits;
    int         auxBuffers;
    GLFWbool    stereo;
    int         samples;
    GLFWbool    sRGB;
    GLFWbool    doublebuffer;

    // This is defined in the context API's context.h
    _GLFW_PLATFORM_FBCONFIG;
};


/*! @brief Context structure.
 */
struct _GLFWcontext
{
    int                 api;
    int                 major, minor, revision;
    GLFWbool            forward, debug, noerror;
    int                 profile;
    int                 robustness;
    int                 release;

    PFNGLGETSTRINGIPROC GetStringi;
    PFNGLGETINTEGERVPROC GetIntegerv;
    PFNGLGETSTRINGPROC  GetString;

    // This is defined in the context API's context.h
    _GLFW_PLATFORM_CONTEXT_STATE;
};


/*! @brief Window and context structure.
 */
struct _GLFWwindow
{
    struct _GLFWwindow* next;

    // Window settings and state
    GLFWbool            resizable;
    GLFWbool            decorated;
    GLFWbool            autoIconify;
    GLFWbool            floating;
    GLFWbool            closed;
    void*               userPointer;
    GLFWvidmode         videoMode;
    _GLFWmonitor*       monitor;
    _GLFWcursor*        cursor;

    int                 minwidth, minheight;
    int                 maxwidth, maxheight;
    int                 numer, denom;

    // Window input state
    GLFWbool            stickyKeys;
    GLFWbool            stickyMouseButtons;
    double              cursorPosX, cursorPosY;
    int                 cursorMode;
    char                mouseButtons[GLFW_MOUSE_BUTTON_LAST + 1];
    char                keys[GLFW_KEY_LAST + 1];

    _GLFWcontext        context;

    struct {
        GLFWwindowposfun        pos;
        GLFWwindowsizefun       size;
        GLFWwindowclosefun      close;
        GLFWwindowrefreshfun    refresh;
        GLFWwindowfocusfun      focus;
        GLFWwindowiconifyfun    iconify;
        GLFWframebuffersizefun  fbsize;
        GLFWmousebuttonfun      mouseButton;
        GLFWcursorposfun        cursorPos;
        GLFWcursorenterfun      cursorEnter;
        GLFWscrollfun           scroll;
        GLFWkeyfun              key;
        GLFWcharfun             character;
        GLFWcharmodsfun         charmods;
        GLFWdropfun             drop;
    } callbacks;

    // This is defined in the window API's platform.h
    _GLFW_PLATFORM_WINDOW_STATE;
};


/*! @brief Monitor structure.
 */
struct _GLFWmonitor
{
    char*           name;

    // Physical dimensions in millimeters.
    int             widthMM, heightMM;

    // The window whose video mode is current on this monitor
    _GLFWwindow*    window;

    GLFWvidmode*    modes;
    int             modeCount;
    GLFWvidmode     currentMode;

    GLFWgammaramp   originalRamp;
    GLFWgammaramp   currentRamp;

    // This is defined in the window API's platform.h
    _GLFW_PLATFORM_MONITOR_STATE;
};


/*! @brief Cursor structure
 */
struct _GLFWcursor
{
    _GLFWcursor*    next;

    // This is defined in the window API's platform.h
    _GLFW_PLATFORM_CURSOR_STATE;
};

/*! @brief Library global data.
 */
struct _GLFWlibrary
{
    struct {
        _GLFWfbconfig   framebuffer;
        _GLFWwndconfig  window;
        _GLFWctxconfig  context;
        int             refreshRate;
    } hints;

    double              cursorPosX, cursorPosY;

    _GLFWcursor*        cursorListHead;

    _GLFWwindow*        windowListHead;
    _GLFWwindow*        cursorWindow;

    _GLFWmonitor**      monitors;
    int                 monitorCount;

    GLFWuint64          timerOffset;

    struct {
        GLFWbool        available;
        void*           handle;
        char**          extensions;
        unsigned int    extensionCount;
        PFN_vkEnumerateInstanceExtensionProperties EnumerateInstanceExtensionProperties;
        PFN_vkGetInstanceProcAddr GetInstanceProcAddr;
        GLFWbool        KHR_surface;
        GLFWbool        KHR_win32_surface;
        GLFWbool        KHR_xlib_surface;
        GLFWbool        KHR_xcb_surface;
        GLFWbool        KHR_wayland_surface;
        GLFWbool        KHR_mir_surface;
    } vk;

    struct {
        GLFWmonitorfun  monitor;
    } callbacks;

    // This is defined in the window API's platform.h
    _GLFW_PLATFORM_LIBRARY_WINDOW_STATE;
    // This is defined in the context API's context.h
    _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE;
    // This is defined in the platform's time.h
    _GLFW_PLATFORM_LIBRARY_TIME_STATE;
    // This is defined in the platform's joystick.h
    _GLFW_PLATFORM_LIBRARY_JOYSTICK_STATE;
    // This is defined in the platform's tls.h
    _GLFW_PLATFORM_LIBRARY_TLS_STATE;
};


//========================================================================
// Global state shared between compilation units of GLFW
//========================================================================

/*! @brief Flag indicating whether GLFW has been successfully initialized.
 */
extern GLFWbool _glfwInitialized;

/*! @brief All global data protected by @ref _glfwInitialized.
 *  This should only be touched after a call to @ref glfwInit that has not been
 *  followed by a call to @ref glfwTerminate.
 */
extern _GLFWlibrary _glfw;


//========================================================================
// Platform API functions
//========================================================================

/*! @brief Initializes the platform-specific part of the library.
 *  @return `GLFW_TRUE` if successful, or `GLFW_FALSE` if an error occurred.
 *  @ingroup platform
 */
int _glfwPlatformInit(void);

/*! @brief Terminates the platform-specific part of the library.
 *  @ingroup platform
 */
void _glfwPlatformTerminate(void);

/*! @copydoc glfwGetVersionString
 *  @ingroup platform
 *
 *  @note The returned string must be available for the duration of the program.
 *
 *  @note The returned string must not change for the duration of the program.
 */
const char* _glfwPlatformGetVersionString(void);

/*! @copydoc glfwGetCursorPos
 *  @ingroup platform
 */
void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos);

/*! @copydoc glfwSetCursorPos
 *  @ingroup platform
 */
void _glfwPlatformSetCursorPos(_GLFWwindow* window, double xpos, double ypos);

/*! @brief Sets the specified cursor mode of the specified window.
 *  @param[in] window The window whose cursor mode to set.
 *  @ingroup platform
 */
void _glfwPlatformSetCursorMode(_GLFWwindow* window, int mode);

/*! @copydoc glfwGetKeyName
 *  @ingroup platform
 */
const char* _glfwPlatformGetKeyName(int key, int scancode);

/*! @copydoc glfwGetMonitors
 *  @ingroup platform
 */
_GLFWmonitor** _glfwPlatformGetMonitors(int* count);

/*! @brief Checks whether two monitor objects represent the same monitor.
 *
 *  @param[in] first The first monitor.
 *  @param[in] second The second monitor.
 *  @return @c GLFW_TRUE if the monitor objects represent the same monitor, or
 *  @c GLFW_FALSE otherwise.
 *  @ingroup platform
 */
GLFWbool _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second);

/*! @copydoc glfwGetMonitorPos
 *  @ingroup platform
 */
void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos);

/*! @copydoc glfwGetVideoModes
 *  @ingroup platform
 */
GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* count);

/*! @ingroup platform
 */
void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode* mode);

/*! @copydoc glfwGetGammaRamp
 *  @ingroup platform
 */
void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp);

/*! @copydoc glfwSetGammaRamp
 *  @ingroup platform
 */
void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp);

/*! @copydoc glfwSetClipboardString
 *  @ingroup platform
 */
void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string);

/*! @copydoc glfwGetClipboardString
 *  @ingroup platform
 *
 *  @note The returned string must be valid until the next call to @ref
 *  _glfwPlatformGetClipboardString or @ref _glfwPlatformSetClipboardString.
 */
const char* _glfwPlatformGetClipboardString(_GLFWwindow* window);

/*! @copydoc glfwJoystickPresent
 *  @ingroup platform
 */
int _glfwPlatformJoystickPresent(int joy);

/*! @copydoc glfwGetJoystickAxes
 *  @ingroup platform
 */
const float* _glfwPlatformGetJoystickAxes(int joy, int* count);

/*! @copydoc glfwGetJoystickButtons
 *  @ingroup platform
 */
const unsigned char* _glfwPlatformGetJoystickButtons(int joy, int* count);

/*! @copydoc glfwGetJoystickName
 *  @ingroup platform
 */
const char* _glfwPlatformGetJoystickName(int joy);

/*! @copydoc glfwGetTimerValue
 *  @ingroup platform
 */
GLFWuint64 _glfwPlatformGetTimerValue(void);

/*! @copydoc glfwGetTimerFrequency
 *  @ingroup platform
 */
GLFWuint64 _glfwPlatformGetTimerFrequency(void);

/*! @ingroup platform
 */
int _glfwPlatformCreateWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig,
                              const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig);

/*! @ingroup platform
 */
void _glfwPlatformDestroyWindow(_GLFWwindow* window);

/*! @copydoc glfwSetWindowTitle
 *  @ingroup platform
 */
void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title);

/*! @copydoc glfwSetWindowIcon
 *  @ingroup platform
 */
void _glfwPlatformSetWindowIcon(_GLFWwindow* window, int count, const GLFWimage* images);

/*! @copydoc glfwGetWindowPos
 *  @ingroup platform
 */
void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos);

/*! @copydoc glfwSetWindowPos
 *  @ingroup platform
 */
void _glfwPlatformSetWindowPos(_GLFWwindow* window, int xpos, int ypos);

/*! @copydoc glfwGetWindowSize
 *  @ingroup platform
 */
void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height);

/*! @copydoc glfwSetWindowSize
 *  @ingroup platform
 */
void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height);

/*! @copydoc glfwSetWindowSizeLimits
 *  @ingroup platform
 */
void _glfwPlatformSetWindowSizeLimits(_GLFWwindow* window, int minwidth, int minheight, int maxwidth, int maxheight);

/*! @copydoc glfwSetWindowAspectRatio
 *  @ingroup platform
 */
void _glfwPlatformSetWindowAspectRatio(_GLFWwindow* window, int numer, int denom);

/*! @copydoc glfwGetFramebufferSize
 *  @ingroup platform
 */
void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height);

/*! @copydoc glfwGetWindowFrameSize
 *  @ingroup platform
 */
void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window, int* left, int* top, int* right, int* bottom);

/*! @copydoc glfwIconifyWindow
 *  @ingroup platform
 */
void _glfwPlatformIconifyWindow(_GLFWwindow* window);

/*! @copydoc glfwRestoreWindow
 *  @ingroup platform
 */
void _glfwPlatformRestoreWindow(_GLFWwindow* window);

/*! @copydoc glfwMaximizeWindow
 *  @ingroup platform
 */
void _glfwPlatformMaximizeWindow(_GLFWwindow* window);

/*! @copydoc glfwShowWindow
 *  @ingroup platform
 */
void _glfwPlatformShowWindow(_GLFWwindow* window);

/*! @copydoc glfwHideWindow
 *  @ingroup platform
 */
void _glfwPlatformHideWindow(_GLFWwindow* window);

/*! @copydoc glfwFocusWindow
 *  @ingroup platform
 */
void _glfwPlatformFocusWindow(_GLFWwindow* window);

/*! @copydoc glfwSetWindowMonitor
 *  @ingroup platform
 */
void _glfwPlatformSetWindowMonitor(_GLFWwindow* window, _GLFWmonitor* monitor, int xpos, int ypos, int width, int height, int refreshRate);

/*! @brief Returns whether the window is focused.
 *  @ingroup platform
 */
int _glfwPlatformWindowFocused(_GLFWwindow* window);

/*! @brief Returns whether the window is iconified.
 *  @ingroup platform
 */
int _glfwPlatformWindowIconified(_GLFWwindow* window);

/*! @brief Returns whether the window is visible.
 *  @ingroup platform
 */
int _glfwPlatformWindowVisible(_GLFWwindow* window);

/*! @brief Returns whether the window is maximized.
 *  @ingroup platform
 */
int _glfwPlatformWindowMaximized(_GLFWwindow* window);

/*! @copydoc glfwPollEvents
 *  @ingroup platform
 */
void _glfwPlatformPollEvents(void);

/*! @copydoc glfwWaitEvents
 *  @ingroup platform
 */
void _glfwPlatformWaitEvents(void);

/*! @copydoc glfwWaitEventsTimeout
 *  @ingroup platform
 */
void _glfwPlatformWaitEventsTimeout(double timeout);

/*! @copydoc glfwPostEmptyEvent
 *  @ingroup platform
 */
void _glfwPlatformPostEmptyEvent(void);

/*! @copydoc glfwMakeContextCurrent
 *  @ingroup platform
 */
void _glfwPlatformMakeContextCurrent(_GLFWwindow* window);

/*! @ingroup platform
 */
void _glfwPlatformSetCurrentContext(_GLFWwindow* context);

/*! @copydoc glfwGetCurrentContext
 *  @ingroup platform
 */
_GLFWwindow* _glfwPlatformGetCurrentContext(void);

/*! @copydoc glfwSwapBuffers
 *  @ingroup platform
 */
void _glfwPlatformSwapBuffers(_GLFWwindow* window);

/*! @copydoc glfwSwapInterval
 *  @ingroup platform
 */
void _glfwPlatformSwapInterval(int interval);

/*! @copydoc glfwExtensionSupported
 *  @ingroup platform
 */
int _glfwPlatformExtensionSupported(const char* extension);

/*! @copydoc glfwGetProcAddress
 *  @ingroup platform
 */
GLFWglproc _glfwPlatformGetProcAddress(const char* procname);

/*! @copydoc glfwCreateCursor
 *  @ingroup platform
 */
int _glfwPlatformCreateCursor(_GLFWcursor* cursor, const GLFWimage* image, int xhot, int yhot);

/*! @copydoc glfwCreateStandardCursor
 *  @ingroup platform
 */
int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape);

/*! @copydoc glfwDestroyCursor
 *  @ingroup platform
 */
void _glfwPlatformDestroyCursor(_GLFWcursor* cursor);

/*! @copydoc glfwSetCursor
 *  @ingroup platform
 */
void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor);

/*! @ingroup platform
 */
char** _glfwPlatformGetRequiredInstanceExtensions(unsigned int* count);

/*! @ingroup platform
 */
int _glfwPlatformGetPhysicalDevicePresentationSupport(VkInstance instance, VkPhysicalDevice device, unsigned int queuefamily);

/*! @ingroup platform
 */
VkResult _glfwPlatformCreateWindowSurface(VkInstance instance, _GLFWwindow* window, const VkAllocationCallbacks* allocator, VkSurfaceKHR* surface);


//========================================================================
// Event API functions
//========================================================================

/*! @brief Notifies shared code of a window focus event.
 *  @param[in] window The window that received the event.
 *  @param[in] focused `GLFW_TRUE` if the window received focus, or `GLFW_FALSE`
 *  if it lost focus.
 *  @ingroup event
 */
void _glfwInputWindowFocus(_GLFWwindow* window, GLFWbool focused);

/*! @brief Notifies shared code of a window movement event.
 *  @param[in] window The window that received the event.
 *  @param[in] xpos The new x-coordinate of the client area of the window.
 *  @param[in] ypos The new y-coordinate of the client area of the window.
 *  @ingroup event
 */
void _glfwInputWindowPos(_GLFWwindow* window, int xpos, int ypos);

/*! @brief Notifies shared code of a window resize event.
 *  @param[in] window The window that received the event.
 *  @param[in] width The new width of the client area of the window.
 *  @param[in] height The new height of the client area of the window.
 *  @ingroup event
 */
void _glfwInputWindowSize(_GLFWwindow* window, int width, int height);

/*! @brief Notifies shared code of a framebuffer resize event.
 *  @param[in] window The window that received the event.
 *  @param[in] width The new width, in pixels, of the framebuffer.
 *  @param[in] height The new height, in pixels, of the framebuffer.
 *  @ingroup event
 */
void _glfwInputFramebufferSize(_GLFWwindow* window, int width, int height);

/*! @brief Notifies shared code of a window iconification event.
 *  @param[in] window The window that received the event.
 *  @param[in] iconified `GLFW_TRUE` if the window was iconified, or
 *  `GLFW_FALSE` if it was restored.
 *  @ingroup event
 */
void _glfwInputWindowIconify(_GLFWwindow* window, GLFWbool iconified);

/*! @brief Notifies shared code of a window damage event.
 *  @param[in] window The window that received the event.
 */
void _glfwInputWindowDamage(_GLFWwindow* window);

/*! @brief Notifies shared code of a window close request event
 *  @param[in] window The window that received the event.
 *  @ingroup event
 */
void _glfwInputWindowCloseRequest(_GLFWwindow* window);

void _glfwInputWindowMonitorChange(_GLFWwindow* window, _GLFWmonitor* monitor);

/*! @brief Notifies shared code of a physical key event.
 *  @param[in] window The window that received the event.
 *  @param[in] key The key that was pressed or released.
 *  @param[in] scancode The system-specific scan code of the key.
 *  @param[in] action @ref GLFW_PRESS or @ref GLFW_RELEASE.
 *  @param[in] mods The modifiers pressed when the event was generated.
 *  @ingroup event
 */
void _glfwInputKey(_GLFWwindow* window, int key, int scancode, int action, int mods);

/*! @brief Notifies shared code of a Unicode character input event.
 *  @param[in] window The window that received the event.
 *  @param[in] codepoint The Unicode code point of the input character.
 *  @param[in] mods Bit field describing which modifier keys were held down.
 *  @param[in] plain `GLFW_TRUE` if the character is regular text input, or
 *  `GLFW_FALSE` otherwise.
 *  @ingroup event
 */
void _glfwInputChar(_GLFWwindow* window, unsigned int codepoint, int mods, GLFWbool plain);

/*! @brief Notifies shared code of a scroll event.
 *  @param[in] window The window that received the event.
 *  @param[in] x The scroll offset along the x-axis.
 *  @param[in] y The scroll offset along the y-axis.
 *  @ingroup event
 */
void _glfwInputScroll(_GLFWwindow* window, double x, double y);

/*! @brief Notifies shared code of a mouse button click event.
 *  @param[in] window The window that received the event.
 *  @param[in] button The button that was pressed or released.
 *  @param[in] action @ref GLFW_PRESS or @ref GLFW_RELEASE.
 *  @ingroup event
 */
void _glfwInputMouseClick(_GLFWwindow* window, int button, int action, int mods);

/*! @brief Notifies shared code of a cursor motion event.
 *  @param[in] window The window that received the event.
 *  @param[in] x The new x-coordinate of the cursor, relative to the left edge
 *  of the client area of the window.
 *  @param[in] y The new y-coordinate of the cursor, relative to the top edge
 *  of the client area of the window.
 *  @ingroup event
 */
void _glfwInputCursorMotion(_GLFWwindow* window, double x, double y);

/*! @brief Notifies shared code of a cursor enter/leave event.
 *  @param[in] window The window that received the event.
 *  @param[in] entered `GLFW_TRUE` if the cursor entered the client area of the
 *  window, or `GLFW_FALSE` if it left it.
 *  @ingroup event
 */
void _glfwInputCursorEnter(_GLFWwindow* window, GLFWbool entered);

/*! @ingroup event
 */
void _glfwInputMonitorChange(void);

/*! @ingroup event
 */
void _glfwInputMonitorWindowChange(_GLFWmonitor* monitor, _GLFWwindow* window);

/*! @brief Notifies shared code of an error.
 *  @param[in] error The error code most suitable for the error.
 *  @param[in] format The `printf` style format string of the error
 *  description.
 *  @ingroup event
 */
#if defined(__GNUC__)
void _glfwInputError(int error, const char* format, ...) __attribute__((format(printf, 2, 3)));
#else
void _glfwInputError(int error, const char* format, ...);
#endif

/*! @brief Notifies dropped object over window.
 *  @param[in] window The window that received the event.
 *  @param[in] count The number of dropped objects.
 *  @param[in] names The names of the dropped objects.
 *  @ingroup event
 */
void _glfwInputDrop(_GLFWwindow* window, int count, const char** names);


//========================================================================
// Utility functions
//========================================================================

/*! @ingroup utility
 */
const GLFWvidmode* _glfwChooseVideoMode(_GLFWmonitor* monitor,
                                        const GLFWvidmode* desired);

/*! @brief Performs lexical comparison between two @ref GLFWvidmode structures.
 *  @ingroup utility
 */
int _glfwCompareVideoModes(const GLFWvidmode* first, const GLFWvidmode* second);

/*! @brief Splits a color depth into red, green and blue bit depths.
 *  @ingroup utility
 */
void _glfwSplitBPP(int bpp, int* red, int* green, int* blue);

/*! @brief Searches an extension string for the specified extension.
 *  @param[in] string The extension string to search.
 *  @param[in] extensions The extension to search for.
 *  @return `GLFW_TRUE` if the extension was found, or `GLFW_FALSE` otherwise.
 *  @ingroup utility
 */
GLFWbool _glfwStringInExtensionString(const char* string, const char* extensions);

/*! @brief Chooses the framebuffer config that best matches the desired one.
 *  @param[in] desired The desired framebuffer config.
 *  @param[in] alternatives The framebuffer configs supported by the system.
 *  @param[in] count The number of entries in the alternatives array.
 *  @return The framebuffer config most closely matching the desired one, or @c
 *  NULL if none fulfilled the hard constraints of the desired values.
 *  @ingroup utility
 */
const _GLFWfbconfig* _glfwChooseFBConfig(const _GLFWfbconfig* desired,
                                         const _GLFWfbconfig* alternatives,
                                         unsigned int count);

/*! @brief Retrieves the attributes of the current context.
 *  @param[in] ctxconfig The desired context attributes.
 *  @return `GLFW_TRUE` if successful, or `GLFW_FALSE` if the context is
 *  unusable.
 *  @ingroup utility
 */
GLFWbool _glfwRefreshContextAttribs(const _GLFWctxconfig* ctxconfig);

/*! @brief Checks whether the desired context attributes are valid.
 *  @param[in] ctxconfig The context attributes to check.
 *  @return `GLFW_TRUE` if the context attributes are valid, or `GLFW_FALSE`
 *  otherwise.
 *  @ingroup utility
 *
 *  This function checks things like whether the specified client API version
 *  exists and whether all relevant options have supported and non-conflicting
 *  values.
 */
GLFWbool _glfwIsValidContextConfig(const _GLFWctxconfig* ctxconfig);

/*! @brief Checks whether the current context fulfils the specified hard
 *  constraints.
 *  @param[in] ctxconfig The desired context attributes.
 *  @return `GLFW_TRUE` if the context fulfils the hard constraints, or
 *  `GLFW_FALSE` otherwise.
 *  @ingroup utility
 */
GLFWbool _glfwIsValidContext(const _GLFWctxconfig* ctxconfig);

/*! @ingroup utility
 */
void _glfwAllocGammaArrays(GLFWgammaramp* ramp, unsigned int size);

/*! @ingroup utility
 */
void _glfwFreeGammaArrays(GLFWgammaramp* ramp);

/*! @brief Allocates and returns a monitor object with the specified name
 *  and dimensions.
 *  @param[in] name The name of the monitor.
 *  @param[in] widthMM The width, in mm, of the monitor's display area.
 *  @param[in] heightMM The height, in mm, of the monitor's display area.
 *  @return The newly created object.
 *  @ingroup utility
 */
_GLFWmonitor* _glfwAllocMonitor(const char* name, int widthMM, int heightMM);

/*! @brief Frees a monitor object and any data associated with it.
 *  @ingroup utility
  */
void _glfwFreeMonitor(_GLFWmonitor* monitor);

/*! @ingroup utility
  */
void _glfwFreeMonitors(_GLFWmonitor** monitors, int count);

/*! @ingroup utility
 */
GLFWbool _glfwIsPrintable(int key);

/*! @ingroup utility
 */
void _glfwInitVulkan(void);

/*! @ingroup utility
 */
void _glfwTerminateVulkan(void);

/*! @ingroup utility
 */
const char* _glfwGetVulkanResultString(VkResult result);

#endif // _glfw3_internal_h_
