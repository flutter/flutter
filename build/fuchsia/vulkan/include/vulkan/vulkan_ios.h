#ifndef VULKAN_IOS_H_
#define VULKAN_IOS_H_ 1

/*
** Copyright (c) 2015-2020 The Khronos Group Inc.
**
** SPDX-License-Identifier: Apache-2.0
*/

/*
** This header is generated from the Khronos Vulkan XML API Registry.
**
*/


#ifdef __cplusplus
extern "C" {
#endif



#define VK_MVK_ios_surface 1
#define VK_MVK_IOS_SURFACE_SPEC_VERSION   2
#define VK_MVK_IOS_SURFACE_EXTENSION_NAME "VK_MVK_ios_surface"
typedef VkFlags VkIOSSurfaceCreateFlagsMVK;
typedef struct VkIOSSurfaceCreateInfoMVK {
    VkStructureType               sType;
    const void*                   pNext;
    VkIOSSurfaceCreateFlagsMVK    flags;
    const void*                   pView;
} VkIOSSurfaceCreateInfoMVK;

typedef VkResult (VKAPI_PTR *PFN_vkCreateIOSSurfaceMVK)(VkInstance instance, const VkIOSSurfaceCreateInfoMVK* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);

#ifndef VK_NO_PROTOTYPES
VKAPI_ATTR VkResult VKAPI_CALL vkCreateIOSSurfaceMVK(
    VkInstance                                  instance,
    const VkIOSSurfaceCreateInfoMVK*            pCreateInfo,
    const VkAllocationCallbacks*                pAllocator,
    VkSurfaceKHR*                               pSurface);
#endif

#ifdef __cplusplus
}
#endif

#endif
