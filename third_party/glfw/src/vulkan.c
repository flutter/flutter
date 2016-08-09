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

#include "internal.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwInitVulkan(void)
{
    VkResult err;
    VkExtensionProperties* ep;
    unsigned int i, count;
#if defined(_GLFW_WIN32)
    const char* name = "vulkan-1.dll";
#else
    const char* name = "libvulkan.so.1";
#endif

    _glfw.vk.handle = _glfw_dlopen(name);
    if (!_glfw.vk.handle)
        return;

    _glfw.vk.GetInstanceProcAddr = (PFN_vkGetInstanceProcAddr)
        _glfw_dlsym(_glfw.vk.handle, "vkGetInstanceProcAddr");
    if (!_glfw.vk.GetInstanceProcAddr)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Vulkan: Loader does not export vkGetInstanceProcAddr");
        return;
    }

    _glfw.vk.EnumerateInstanceExtensionProperties = (PFN_vkEnumerateInstanceExtensionProperties)
        vkGetInstanceProcAddr(NULL, "vkEnumerateInstanceExtensionProperties");
    if (!_glfw.vk.EnumerateInstanceExtensionProperties)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Vulkan: Failed to retrieve vkEnumerateInstanceExtensionProperties");
        return;
    }

    err = vkEnumerateInstanceExtensionProperties(NULL, &count, NULL);
    if (err)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Vulkan: Failed to query instance extension count: %s",
                        _glfwGetVulkanResultString(err));
        return;
    }

    ep = calloc(count, sizeof(VkExtensionProperties));

    err = vkEnumerateInstanceExtensionProperties(NULL, &count, ep);
    if (err)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Vulkan: Failed to query instance extensions: %s",
                        _glfwGetVulkanResultString(err));

        free(ep);
        return;
    }

    for (i = 0;  i < count;  i++)
    {
        if (strcmp(ep[i].extensionName, "VK_KHR_surface") == 0)
            _glfw.vk.KHR_surface = GLFW_TRUE;
        if (strcmp(ep[i].extensionName, "VK_KHR_win32_surface") == 0)
            _glfw.vk.KHR_win32_surface = GLFW_TRUE;
        if (strcmp(ep[i].extensionName, "VK_KHR_xlib_surface") == 0)
            _glfw.vk.KHR_xlib_surface = GLFW_TRUE;
        if (strcmp(ep[i].extensionName, "VK_KHR_xcb_surface") == 0)
            _glfw.vk.KHR_xcb_surface = GLFW_TRUE;
        if (strcmp(ep[i].extensionName, "VK_KHR_wayland_surface") == 0)
            _glfw.vk.KHR_wayland_surface = GLFW_TRUE;
        if (strcmp(ep[i].extensionName, "VK_KHR_mir_surface") == 0)
            _glfw.vk.KHR_mir_surface = GLFW_TRUE;
    }

    free(ep);

    _glfw.vk.available = GLFW_TRUE;

    if (!_glfw.vk.KHR_surface)
        return;

    _glfw.vk.extensions =
        _glfwPlatformGetRequiredInstanceExtensions(&_glfw.vk.extensionCount);
}

void _glfwTerminateVulkan(void)
{
    unsigned int i;

    for (i = 0;  i < _glfw.vk.extensionCount;  i++)
        free(_glfw.vk.extensions[i]);
    free(_glfw.vk.extensions);

    if (_glfw.vk.handle)
        _glfw_dlclose(_glfw.vk.handle);
}

const char* _glfwGetVulkanResultString(VkResult result)
{
    switch (result)
    {
        case VK_SUCCESS:
            return "Success";
        case VK_NOT_READY:
            return "A fence or query has not yet completed";
        case VK_TIMEOUT:
            return "A wait operation has not completed in the specified time";
        case VK_EVENT_SET:
            return "An event is signaled";
        case VK_EVENT_RESET:
            return "An event is unsignaled";
        case VK_INCOMPLETE:
            return "A return array was too small for the result";
        case VK_ERROR_OUT_OF_HOST_MEMORY:
            return "A host memory allocation has failed";
        case VK_ERROR_OUT_OF_DEVICE_MEMORY:
            return "A device memory allocation has failed";
        case VK_ERROR_INITIALIZATION_FAILED:
            return "Initialization of an object could not be completed for implementation-specific reasons";
        case VK_ERROR_DEVICE_LOST:
            return "The logical or physical device has been lost";
        case VK_ERROR_MEMORY_MAP_FAILED:
            return "Mapping of a memory object has failed";
        case VK_ERROR_LAYER_NOT_PRESENT:
            return "A requested layer is not present or could not be loaded";
        case VK_ERROR_EXTENSION_NOT_PRESENT:
            return "A requested extension is not supported";
        case VK_ERROR_FEATURE_NOT_PRESENT:
            return "A requested feature is not supported";
        case VK_ERROR_INCOMPATIBLE_DRIVER:
            return "The requested version of Vulkan is not supported by the driver or is otherwise incompatible";
        case VK_ERROR_TOO_MANY_OBJECTS:
            return "Too many objects of the type have already been created";
        case VK_ERROR_FORMAT_NOT_SUPPORTED:
            return "A requested format is not supported on this device";
        case VK_ERROR_SURFACE_LOST_KHR:
            return "A surface is no longer available";
        case VK_SUBOPTIMAL_KHR:
            return "A swapchain no longer matches the surface properties exactly, but can still be used";
        case VK_ERROR_OUT_OF_DATE_KHR:
            return "A surface has changed in such a way that it is no longer compatible with the swapchain";
        case VK_ERROR_INCOMPATIBLE_DISPLAY_KHR:
            return "The display used by a swapchain does not use the same presentable image layout";
        case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR:
            return "The requested window is already connected to a VkSurfaceKHR, or to some other non-Vulkan API";
        case VK_ERROR_VALIDATION_FAILED_EXT:
            return "A validation layer found an error";
        default:
            return "ERROR: UNKNOWN VULKAN ERROR";
    }
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW public API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI int glfwVulkanSupported(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(GLFW_FALSE);
    return _glfw.vk.available;
}

GLFWAPI const char** glfwGetRequiredInstanceExtensions(unsigned int* count)
{
    *count = 0;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (!_glfw.vk.available)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "Vulkan: Loader not found");
        return NULL;
    }

    *count = _glfw.vk.extensionCount;
    return (const char**) _glfw.vk.extensions;
}

GLFWAPI GLFWvkproc glfwGetInstanceProcAddress(VkInstance instance,
                                              const char* procname)
{
    GLFWvkproc proc;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (!_glfw.vk.available)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "Vulkan: Loader not found");
        return NULL;
    }

    proc = (GLFWvkproc) vkGetInstanceProcAddr(instance, procname);
    if (!proc)
        proc = (GLFWvkproc) _glfw_dlsym(_glfw.vk.handle, procname);

    return proc;
}

GLFWAPI int glfwGetPhysicalDevicePresentationSupport(VkInstance instance,
                                                     VkPhysicalDevice device,
                                                     uint32_t queuefamily)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(GLFW_FALSE);

    if (!_glfw.vk.available)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "Vulkan: Loader not found");
        return GLFW_FALSE;
    }

    if (!_glfw.vk.extensions)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Vulkan: Window surface creation extensions not found");
        return GLFW_FALSE;
    }

    return _glfwPlatformGetPhysicalDevicePresentationSupport(instance,
                                                             device,
                                                             queuefamily);
}

GLFWAPI VkResult glfwCreateWindowSurface(VkInstance instance,
                                         GLFWwindow* handle,
                                         const VkAllocationCallbacks* allocator,
                                         VkSurfaceKHR* surface)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    assert(window != NULL);

    assert(surface != NULL);
    *surface = VK_NULL_HANDLE;

    _GLFW_REQUIRE_INIT_OR_RETURN(VK_ERROR_INITIALIZATION_FAILED);

    if (!_glfw.vk.available)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "Vulkan: Loader not found");
        return VK_ERROR_INITIALIZATION_FAILED;
    }

    if (!_glfw.vk.extensions)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Vulkan: Window surface creation extensions not found");
        return VK_ERROR_EXTENSION_NOT_PRESENT;
    }

    return _glfwPlatformCreateWindowSurface(instance, window, allocator, surface);
}

