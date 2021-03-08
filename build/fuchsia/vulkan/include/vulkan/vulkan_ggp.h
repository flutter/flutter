#ifndef VULKAN_GGP_H_
#define VULKAN_GGP_H_ 1

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



#define VK_GGP_stream_descriptor_surface 1
#define VK_GGP_STREAM_DESCRIPTOR_SURFACE_SPEC_VERSION 1
#define VK_GGP_STREAM_DESCRIPTOR_SURFACE_EXTENSION_NAME "VK_GGP_stream_descriptor_surface"
typedef VkFlags VkStreamDescriptorSurfaceCreateFlagsGGP;
typedef struct VkStreamDescriptorSurfaceCreateInfoGGP {
    VkStructureType                            sType;
    const void*                                pNext;
    VkStreamDescriptorSurfaceCreateFlagsGGP    flags;
    GgpStreamDescriptor                        streamDescriptor;
} VkStreamDescriptorSurfaceCreateInfoGGP;

typedef VkResult (VKAPI_PTR *PFN_vkCreateStreamDescriptorSurfaceGGP)(VkInstance instance, const VkStreamDescriptorSurfaceCreateInfoGGP* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);

#ifndef VK_NO_PROTOTYPES
VKAPI_ATTR VkResult VKAPI_CALL vkCreateStreamDescriptorSurfaceGGP(
    VkInstance                                  instance,
    const VkStreamDescriptorSurfaceCreateInfoGGP* pCreateInfo,
    const VkAllocationCallbacks*                pAllocator,
    VkSurfaceKHR*                               pSurface);
#endif


#define VK_GGP_frame_token 1
#define VK_GGP_FRAME_TOKEN_SPEC_VERSION   1
#define VK_GGP_FRAME_TOKEN_EXTENSION_NAME "VK_GGP_frame_token"
typedef struct VkPresentFrameTokenGGP {
    VkStructureType    sType;
    const void*        pNext;
    GgpFrameToken      frameToken;
} VkPresentFrameTokenGGP;


#ifdef __cplusplus
}
#endif

#endif
