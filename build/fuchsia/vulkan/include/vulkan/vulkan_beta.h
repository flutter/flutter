#ifndef VULKAN_BETA_H_
#define VULKAN_BETA_H_ 1

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



#define VK_KHR_deferred_host_operations 1
VK_DEFINE_NON_DISPATCHABLE_HANDLE(VkDeferredOperationKHR)
#define VK_KHR_DEFERRED_HOST_OPERATIONS_SPEC_VERSION 3
#define VK_KHR_DEFERRED_HOST_OPERATIONS_EXTENSION_NAME "VK_KHR_deferred_host_operations"
typedef struct VkDeferredOperationInfoKHR {
    VkStructureType           sType;
    const void*               pNext;
    VkDeferredOperationKHR    operationHandle;
} VkDeferredOperationInfoKHR;

typedef VkResult (VKAPI_PTR *PFN_vkCreateDeferredOperationKHR)(VkDevice device, const VkAllocationCallbacks* pAllocator, VkDeferredOperationKHR* pDeferredOperation);
typedef void (VKAPI_PTR *PFN_vkDestroyDeferredOperationKHR)(VkDevice device, VkDeferredOperationKHR operation, const VkAllocationCallbacks* pAllocator);
typedef uint32_t (VKAPI_PTR *PFN_vkGetDeferredOperationMaxConcurrencyKHR)(VkDevice device, VkDeferredOperationKHR operation);
typedef VkResult (VKAPI_PTR *PFN_vkGetDeferredOperationResultKHR)(VkDevice device, VkDeferredOperationKHR operation);
typedef VkResult (VKAPI_PTR *PFN_vkDeferredOperationJoinKHR)(VkDevice device, VkDeferredOperationKHR operation);

#ifndef VK_NO_PROTOTYPES
VKAPI_ATTR VkResult VKAPI_CALL vkCreateDeferredOperationKHR(
    VkDevice                                    device,
    const VkAllocationCallbacks*                pAllocator,
    VkDeferredOperationKHR*                     pDeferredOperation);

VKAPI_ATTR void VKAPI_CALL vkDestroyDeferredOperationKHR(
    VkDevice                                    device,
    VkDeferredOperationKHR                      operation,
    const VkAllocationCallbacks*                pAllocator);

VKAPI_ATTR uint32_t VKAPI_CALL vkGetDeferredOperationMaxConcurrencyKHR(
    VkDevice                                    device,
    VkDeferredOperationKHR                      operation);

VKAPI_ATTR VkResult VKAPI_CALL vkGetDeferredOperationResultKHR(
    VkDevice                                    device,
    VkDeferredOperationKHR                      operation);

VKAPI_ATTR VkResult VKAPI_CALL vkDeferredOperationJoinKHR(
    VkDevice                                    device,
    VkDeferredOperationKHR                      operation);
#endif


#define VK_KHR_pipeline_library 1
#define VK_KHR_PIPELINE_LIBRARY_SPEC_VERSION 1
#define VK_KHR_PIPELINE_LIBRARY_EXTENSION_NAME "VK_KHR_pipeline_library"
typedef struct VkPipelineLibraryCreateInfoKHR {
    VkStructureType      sType;
    const void*          pNext;
    uint32_t             libraryCount;
    const VkPipeline*    pLibraries;
} VkPipelineLibraryCreateInfoKHR;



#define VK_KHR_ray_tracing 1
#define VK_KHR_RAY_TRACING_SPEC_VERSION   8
#define VK_KHR_RAY_TRACING_EXTENSION_NAME "VK_KHR_ray_tracing"

typedef enum VkAccelerationStructureBuildTypeKHR {
    VK_ACCELERATION_STRUCTURE_BUILD_TYPE_HOST_KHR = 0,
    VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR = 1,
    VK_ACCELERATION_STRUCTURE_BUILD_TYPE_HOST_OR_DEVICE_KHR = 2,
    VK_ACCELERATION_STRUCTURE_BUILD_TYPE_MAX_ENUM_KHR = 0x7FFFFFFF
} VkAccelerationStructureBuildTypeKHR;
typedef union VkDeviceOrHostAddressKHR {
    VkDeviceAddress    deviceAddress;
    void*              hostAddress;
} VkDeviceOrHostAddressKHR;

typedef union VkDeviceOrHostAddressConstKHR {
    VkDeviceAddress    deviceAddress;
    const void*        hostAddress;
} VkDeviceOrHostAddressConstKHR;

typedef struct VkAccelerationStructureBuildOffsetInfoKHR {
    uint32_t    primitiveCount;
    uint32_t    primitiveOffset;
    uint32_t    firstVertex;
    uint32_t    transformOffset;
} VkAccelerationStructureBuildOffsetInfoKHR;

typedef struct VkRayTracingShaderGroupCreateInfoKHR {
    VkStructureType                   sType;
    const void*                       pNext;
    VkRayTracingShaderGroupTypeKHR    type;
    uint32_t                          generalShader;
    uint32_t                          closestHitShader;
    uint32_t                          anyHitShader;
    uint32_t                          intersectionShader;
    const void*                       pShaderGroupCaptureReplayHandle;
} VkRayTracingShaderGroupCreateInfoKHR;

typedef struct VkRayTracingPipelineInterfaceCreateInfoKHR {
    VkStructureType    sType;
    const void*        pNext;
    uint32_t           maxPayloadSize;
    uint32_t           maxAttributeSize;
    uint32_t           maxCallableSize;
} VkRayTracingPipelineInterfaceCreateInfoKHR;

typedef struct VkRayTracingPipelineCreateInfoKHR {
    VkStructureType                                      sType;
    const void*                                          pNext;
    VkPipelineCreateFlags                                flags;
    uint32_t                                             stageCount;
    const VkPipelineShaderStageCreateInfo*               pStages;
    uint32_t                                             groupCount;
    const VkRayTracingShaderGroupCreateInfoKHR*          pGroups;
    uint32_t                                             maxRecursionDepth;
    VkPipelineLibraryCreateInfoKHR                       libraries;
    const VkRayTracingPipelineInterfaceCreateInfoKHR*    pLibraryInterface;
    VkPipelineLayout                                     layout;
    VkPipeline                                           basePipelineHandle;
    int32_t                                              basePipelineIndex;
} VkRayTracingPipelineCreateInfoKHR;

typedef struct VkAccelerationStructureGeometryTrianglesDataKHR {
    VkStructureType                  sType;
    const void*                      pNext;
    VkFormat                         vertexFormat;
    VkDeviceOrHostAddressConstKHR    vertexData;
    VkDeviceSize                     vertexStride;
    VkIndexType                      indexType;
    VkDeviceOrHostAddressConstKHR    indexData;
    VkDeviceOrHostAddressConstKHR    transformData;
} VkAccelerationStructureGeometryTrianglesDataKHR;

typedef struct VkAccelerationStructureGeometryAabbsDataKHR {
    VkStructureType                  sType;
    const void*                      pNext;
    VkDeviceOrHostAddressConstKHR    data;
    VkDeviceSize                     stride;
} VkAccelerationStructureGeometryAabbsDataKHR;

typedef struct VkAccelerationStructureGeometryInstancesDataKHR {
    VkStructureType                  sType;
    const void*                      pNext;
    VkBool32                         arrayOfPointers;
    VkDeviceOrHostAddressConstKHR    data;
} VkAccelerationStructureGeometryInstancesDataKHR;

typedef union VkAccelerationStructureGeometryDataKHR {
    VkAccelerationStructureGeometryTrianglesDataKHR    triangles;
    VkAccelerationStructureGeometryAabbsDataKHR        aabbs;
    VkAccelerationStructureGeometryInstancesDataKHR    instances;
} VkAccelerationStructureGeometryDataKHR;

typedef struct VkAccelerationStructureGeometryKHR {
    VkStructureType                           sType;
    const void*                               pNext;
    VkGeometryTypeKHR                         geometryType;
    VkAccelerationStructureGeometryDataKHR    geometry;
    VkGeometryFlagsKHR                        flags;
} VkAccelerationStructureGeometryKHR;

typedef struct VkAccelerationStructureBuildGeometryInfoKHR {
    VkStructureType                                     sType;
    const void*                                         pNext;
    VkAccelerationStructureTypeKHR                      type;
    VkBuildAccelerationStructureFlagsKHR                flags;
    VkBool32                                            update;
    VkAccelerationStructureKHR                          srcAccelerationStructure;
    VkAccelerationStructureKHR                          dstAccelerationStructure;
    VkBool32                                            geometryArrayOfPointers;
    uint32_t                                            geometryCount;
    const VkAccelerationStructureGeometryKHR* const*    ppGeometries;
    VkDeviceOrHostAddressKHR                            scratchData;
} VkAccelerationStructureBuildGeometryInfoKHR;

typedef struct VkAccelerationStructureCreateGeometryTypeInfoKHR {
    VkStructureType      sType;
    const void*          pNext;
    VkGeometryTypeKHR    geometryType;
    uint32_t             maxPrimitiveCount;
    VkIndexType          indexType;
    uint32_t             maxVertexCount;
    VkFormat             vertexFormat;
    VkBool32             allowsTransforms;
} VkAccelerationStructureCreateGeometryTypeInfoKHR;

typedef struct VkAccelerationStructureCreateInfoKHR {
    VkStructureType                                            sType;
    const void*                                                pNext;
    VkDeviceSize                                               compactedSize;
    VkAccelerationStructureTypeKHR                             type;
    VkBuildAccelerationStructureFlagsKHR                       flags;
    uint32_t                                                   maxGeometryCount;
    const VkAccelerationStructureCreateGeometryTypeInfoKHR*    pGeometryInfos;
    VkDeviceAddress                                            deviceAddress;
} VkAccelerationStructureCreateInfoKHR;

typedef struct VkAccelerationStructureMemoryRequirementsInfoKHR {
    VkStructureType                                     sType;
    const void*                                         pNext;
    VkAccelerationStructureMemoryRequirementsTypeKHR    type;
    VkAccelerationStructureBuildTypeKHR                 buildType;
    VkAccelerationStructureKHR                          accelerationStructure;
} VkAccelerationStructureMemoryRequirementsInfoKHR;

typedef struct VkPhysicalDeviceRayTracingFeaturesKHR {
    VkStructureType    sType;
    void*              pNext;
    VkBool32           rayTracing;
    VkBool32           rayTracingShaderGroupHandleCaptureReplay;
    VkBool32           rayTracingShaderGroupHandleCaptureReplayMixed;
    VkBool32           rayTracingAccelerationStructureCaptureReplay;
    VkBool32           rayTracingIndirectTraceRays;
    VkBool32           rayTracingIndirectAccelerationStructureBuild;
    VkBool32           rayTracingHostAccelerationStructureCommands;
    VkBool32           rayQuery;
    VkBool32           rayTracingPrimitiveCulling;
} VkPhysicalDeviceRayTracingFeaturesKHR;

typedef struct VkPhysicalDeviceRayTracingPropertiesKHR {
    VkStructureType    sType;
    void*              pNext;
    uint32_t           shaderGroupHandleSize;
    uint32_t           maxRecursionDepth;
    uint32_t           maxShaderGroupStride;
    uint32_t           shaderGroupBaseAlignment;
    uint64_t           maxGeometryCount;
    uint64_t           maxInstanceCount;
    uint64_t           maxPrimitiveCount;
    uint32_t           maxDescriptorSetAccelerationStructures;
    uint32_t           shaderGroupHandleCaptureReplaySize;
} VkPhysicalDeviceRayTracingPropertiesKHR;

typedef struct VkAccelerationStructureDeviceAddressInfoKHR {
    VkStructureType               sType;
    const void*                   pNext;
    VkAccelerationStructureKHR    accelerationStructure;
} VkAccelerationStructureDeviceAddressInfoKHR;

typedef struct VkAccelerationStructureVersionKHR {
    VkStructureType    sType;
    const void*        pNext;
    const uint8_t*     versionData;
} VkAccelerationStructureVersionKHR;

typedef struct VkStridedBufferRegionKHR {
    VkBuffer        buffer;
    VkDeviceSize    offset;
    VkDeviceSize    stride;
    VkDeviceSize    size;
} VkStridedBufferRegionKHR;

typedef struct VkTraceRaysIndirectCommandKHR {
    uint32_t    width;
    uint32_t    height;
    uint32_t    depth;
} VkTraceRaysIndirectCommandKHR;

typedef struct VkCopyAccelerationStructureToMemoryInfoKHR {
    VkStructureType                       sType;
    const void*                           pNext;
    VkAccelerationStructureKHR            src;
    VkDeviceOrHostAddressKHR              dst;
    VkCopyAccelerationStructureModeKHR    mode;
} VkCopyAccelerationStructureToMemoryInfoKHR;

typedef struct VkCopyMemoryToAccelerationStructureInfoKHR {
    VkStructureType                       sType;
    const void*                           pNext;
    VkDeviceOrHostAddressConstKHR         src;
    VkAccelerationStructureKHR            dst;
    VkCopyAccelerationStructureModeKHR    mode;
} VkCopyMemoryToAccelerationStructureInfoKHR;

typedef struct VkCopyAccelerationStructureInfoKHR {
    VkStructureType                       sType;
    const void*                           pNext;
    VkAccelerationStructureKHR            src;
    VkAccelerationStructureKHR            dst;
    VkCopyAccelerationStructureModeKHR    mode;
} VkCopyAccelerationStructureInfoKHR;

typedef VkResult (VKAPI_PTR *PFN_vkCreateAccelerationStructureKHR)(VkDevice                                           device, const VkAccelerationStructureCreateInfoKHR*        pCreateInfo, const VkAllocationCallbacks*       pAllocator, VkAccelerationStructureKHR*                        pAccelerationStructure);
typedef void (VKAPI_PTR *PFN_vkGetAccelerationStructureMemoryRequirementsKHR)(VkDevice device, const VkAccelerationStructureMemoryRequirementsInfoKHR* pInfo, VkMemoryRequirements2* pMemoryRequirements);
typedef void (VKAPI_PTR *PFN_vkCmdBuildAccelerationStructureKHR)(VkCommandBuffer                                    commandBuffer, uint32_t infoCount, const VkAccelerationStructureBuildGeometryInfoKHR* pInfos, const VkAccelerationStructureBuildOffsetInfoKHR* const* ppOffsetInfos);
typedef void (VKAPI_PTR *PFN_vkCmdBuildAccelerationStructureIndirectKHR)(VkCommandBuffer                  commandBuffer, const VkAccelerationStructureBuildGeometryInfoKHR* pInfo, VkBuffer                                           indirectBuffer, VkDeviceSize                                       indirectOffset, uint32_t                                           indirectStride);
typedef VkResult (VKAPI_PTR *PFN_vkBuildAccelerationStructureKHR)(VkDevice                                           device, uint32_t infoCount, const VkAccelerationStructureBuildGeometryInfoKHR* pInfos, const VkAccelerationStructureBuildOffsetInfoKHR* const* ppOffsetInfos);
typedef VkResult (VKAPI_PTR *PFN_vkCopyAccelerationStructureKHR)(VkDevice device, const VkCopyAccelerationStructureInfoKHR* pInfo);
typedef VkResult (VKAPI_PTR *PFN_vkCopyAccelerationStructureToMemoryKHR)(VkDevice device, const VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
typedef VkResult (VKAPI_PTR *PFN_vkCopyMemoryToAccelerationStructureKHR)(VkDevice device, const VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
typedef VkResult (VKAPI_PTR *PFN_vkWriteAccelerationStructuresPropertiesKHR)(VkDevice device, uint32_t accelerationStructureCount, const VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType  queryType, size_t       dataSize, void* pData, size_t stride);
typedef void (VKAPI_PTR *PFN_vkCmdCopyAccelerationStructureKHR)(VkCommandBuffer commandBuffer, const VkCopyAccelerationStructureInfoKHR* pInfo);
typedef void (VKAPI_PTR *PFN_vkCmdCopyAccelerationStructureToMemoryKHR)(VkCommandBuffer commandBuffer, const VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
typedef void (VKAPI_PTR *PFN_vkCmdCopyMemoryToAccelerationStructureKHR)(VkCommandBuffer commandBuffer, const VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
typedef void (VKAPI_PTR *PFN_vkCmdTraceRaysKHR)(VkCommandBuffer commandBuffer, const VkStridedBufferRegionKHR* pRaygenShaderBindingTable, const VkStridedBufferRegionKHR* pMissShaderBindingTable, const VkStridedBufferRegionKHR* pHitShaderBindingTable, const VkStridedBufferRegionKHR* pCallableShaderBindingTable, uint32_t width, uint32_t height, uint32_t depth);
typedef VkResult (VKAPI_PTR *PFN_vkCreateRayTracingPipelinesKHR)(VkDevice device, VkPipelineCache pipelineCache, uint32_t createInfoCount, const VkRayTracingPipelineCreateInfoKHR* pCreateInfos, const VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
typedef VkDeviceAddress (VKAPI_PTR *PFN_vkGetAccelerationStructureDeviceAddressKHR)(VkDevice device, const VkAccelerationStructureDeviceAddressInfoKHR* pInfo);
typedef VkResult (VKAPI_PTR *PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR)(VkDevice device, VkPipeline pipeline, uint32_t firstGroup, uint32_t groupCount, size_t dataSize, void* pData);
typedef void (VKAPI_PTR *PFN_vkCmdTraceRaysIndirectKHR)(VkCommandBuffer commandBuffer, const VkStridedBufferRegionKHR* pRaygenShaderBindingTable, const VkStridedBufferRegionKHR* pMissShaderBindingTable, const VkStridedBufferRegionKHR* pHitShaderBindingTable, const VkStridedBufferRegionKHR* pCallableShaderBindingTable, VkBuffer buffer, VkDeviceSize offset);
typedef VkResult (VKAPI_PTR *PFN_vkGetDeviceAccelerationStructureCompatibilityKHR)(VkDevice device, const VkAccelerationStructureVersionKHR* version);

#ifndef VK_NO_PROTOTYPES
VKAPI_ATTR VkResult VKAPI_CALL vkCreateAccelerationStructureKHR(
    VkDevice                                    device,
    const VkAccelerationStructureCreateInfoKHR* pCreateInfo,
    const VkAllocationCallbacks*                pAllocator,
    VkAccelerationStructureKHR*                 pAccelerationStructure);

VKAPI_ATTR void VKAPI_CALL vkGetAccelerationStructureMemoryRequirementsKHR(
    VkDevice                                    device,
    const VkAccelerationStructureMemoryRequirementsInfoKHR* pInfo,
    VkMemoryRequirements2*                      pMemoryRequirements);

VKAPI_ATTR void VKAPI_CALL vkCmdBuildAccelerationStructureKHR(
    VkCommandBuffer                             commandBuffer,
    uint32_t                                    infoCount,
    const VkAccelerationStructureBuildGeometryInfoKHR* pInfos,
    const VkAccelerationStructureBuildOffsetInfoKHR* const* ppOffsetInfos);

VKAPI_ATTR void VKAPI_CALL vkCmdBuildAccelerationStructureIndirectKHR(
    VkCommandBuffer                             commandBuffer,
    const VkAccelerationStructureBuildGeometryInfoKHR* pInfo,
    VkBuffer                                    indirectBuffer,
    VkDeviceSize                                indirectOffset,
    uint32_t                                    indirectStride);

VKAPI_ATTR VkResult VKAPI_CALL vkBuildAccelerationStructureKHR(
    VkDevice                                    device,
    uint32_t                                    infoCount,
    const VkAccelerationStructureBuildGeometryInfoKHR* pInfos,
    const VkAccelerationStructureBuildOffsetInfoKHR* const* ppOffsetInfos);

VKAPI_ATTR VkResult VKAPI_CALL vkCopyAccelerationStructureKHR(
    VkDevice                                    device,
    const VkCopyAccelerationStructureInfoKHR*   pInfo);

VKAPI_ATTR VkResult VKAPI_CALL vkCopyAccelerationStructureToMemoryKHR(
    VkDevice                                    device,
    const VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);

VKAPI_ATTR VkResult VKAPI_CALL vkCopyMemoryToAccelerationStructureKHR(
    VkDevice                                    device,
    const VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);

VKAPI_ATTR VkResult VKAPI_CALL vkWriteAccelerationStructuresPropertiesKHR(
    VkDevice                                    device,
    uint32_t                                    accelerationStructureCount,
    const VkAccelerationStructureKHR*           pAccelerationStructures,
    VkQueryType                                 queryType,
    size_t                                      dataSize,
    void*                                       pData,
    size_t                                      stride);

VKAPI_ATTR void VKAPI_CALL vkCmdCopyAccelerationStructureKHR(
    VkCommandBuffer                             commandBuffer,
    const VkCopyAccelerationStructureInfoKHR*   pInfo);

VKAPI_ATTR void VKAPI_CALL vkCmdCopyAccelerationStructureToMemoryKHR(
    VkCommandBuffer                             commandBuffer,
    const VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);

VKAPI_ATTR void VKAPI_CALL vkCmdCopyMemoryToAccelerationStructureKHR(
    VkCommandBuffer                             commandBuffer,
    const VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);

VKAPI_ATTR void VKAPI_CALL vkCmdTraceRaysKHR(
    VkCommandBuffer                             commandBuffer,
    const VkStridedBufferRegionKHR*             pRaygenShaderBindingTable,
    const VkStridedBufferRegionKHR*             pMissShaderBindingTable,
    const VkStridedBufferRegionKHR*             pHitShaderBindingTable,
    const VkStridedBufferRegionKHR*             pCallableShaderBindingTable,
    uint32_t                                    width,
    uint32_t                                    height,
    uint32_t                                    depth);

VKAPI_ATTR VkResult VKAPI_CALL vkCreateRayTracingPipelinesKHR(
    VkDevice                                    device,
    VkPipelineCache                             pipelineCache,
    uint32_t                                    createInfoCount,
    const VkRayTracingPipelineCreateInfoKHR*    pCreateInfos,
    const VkAllocationCallbacks*                pAllocator,
    VkPipeline*                                 pPipelines);

VKAPI_ATTR VkDeviceAddress VKAPI_CALL vkGetAccelerationStructureDeviceAddressKHR(
    VkDevice                                    device,
    const VkAccelerationStructureDeviceAddressInfoKHR* pInfo);

VKAPI_ATTR VkResult VKAPI_CALL vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(
    VkDevice                                    device,
    VkPipeline                                  pipeline,
    uint32_t                                    firstGroup,
    uint32_t                                    groupCount,
    size_t                                      dataSize,
    void*                                       pData);

VKAPI_ATTR void VKAPI_CALL vkCmdTraceRaysIndirectKHR(
    VkCommandBuffer                             commandBuffer,
    const VkStridedBufferRegionKHR*             pRaygenShaderBindingTable,
    const VkStridedBufferRegionKHR*             pMissShaderBindingTable,
    const VkStridedBufferRegionKHR*             pHitShaderBindingTable,
    const VkStridedBufferRegionKHR*             pCallableShaderBindingTable,
    VkBuffer                                    buffer,
    VkDeviceSize                                offset);

VKAPI_ATTR VkResult VKAPI_CALL vkGetDeviceAccelerationStructureCompatibilityKHR(
    VkDevice                                    device,
    const VkAccelerationStructureVersionKHR*    version);
#endif

#ifdef __cplusplus
}
#endif

#endif
