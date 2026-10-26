// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "flutter/common/vulkan_driver_info.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Default view ID for single-view or implicit view operations.
inline constexpr FlutterViewId kAndroidImplicitViewId = 0;

/// @brief Visibility flag matching Android NDK ASurfaceTransaction visibility.
enum class AndroidSurfaceControlVisibility : int8_t {
  /// @brief Surface is hidden (ASURFACE_TRANSACTION_VISIBILITY_HIDE = 0).
  kHide = 0,
  /// @brief Surface is shown (ASURFACE_TRANSACTION_VISIBILITY_SHOW = 1).
  kShow = 1,
};

/// @brief Buffer transform flags matching NDK ANativeWindowTransform.
enum class AndroidSurfaceControlTransform : uint32_t {
  /// @brief Identity transform (ANATIVEWINDOW_TRANSFORM_IDENTITY = 0x00).
  kIdentity = 0x00,
  /// @brief Mirror horizontally (ANATIVEWINDOW_TRANSFORM_MIRROR_HORIZONTAL =
  /// 0x01).
  kMirrorHorizontal = 0x01,
  /// @brief Mirror vertically (ANATIVEWINDOW_TRANSFORM_MIRROR_VERTICAL = 0x02).
  kMirrorVertical = 0x02,
  /// @brief Rotate 90 degrees clockwise (ANATIVEWINDOW_TRANSFORM_ROTATE_90 =
  /// 0x04).
  kRotate90 = 0x04,
  /// @brief Rotate 180 degrees (ANATIVEWINDOW_TRANSFORM_ROTATE_180 = 0x03).
  kRotate180 = 0x03,
  /// @brief Rotate 270 degrees clockwise (ANATIVEWINDOW_TRANSFORM_ROTATE_270 =
  /// 0x07).
  kRotate270 = 0x07,
};

/// @brief Integer rectangle matching Android NDK ARect.
struct AndroidSurfaceControlRect {
  int32_t left = 0;
  int32_t top = 0;
  int32_t right = 0;
  int32_t bottom = 0;

  /// @brief Computed width of the rectangle.
  int32_t Width() const { return right - left; }

  /// @brief Computed height of the rectangle.
  int32_t Height() const { return bottom - top; }

  /// @brief Returns true if the rectangle has positive width and height.
  bool IsValid() const { return right > left && bottom > top; }

  bool operator==(const AndroidSurfaceControlRect& other) const {
    return left == other.left && top == other.top && right == other.right &&
           bottom == other.bottom;
  }

  bool operator!=(const AndroidSurfaceControlRect& other) const {
    return !(*this == other);
  }
};

/// @brief Per-surface frame statistics reported by ASurfaceTransactionStats.
struct AndroidSurfaceControlStats {
  /// @brief Timestamp when the buffer was acquired by SurfaceFlinger (ns).
  int64_t acquire_time_nanos = 0;
  /// @brief File descriptor for the previous buffer release fence, or -1.
  int previous_release_fence_fd = -1;
  /// @brief Frame latch timestamp in nanoseconds.
  int64_t latch_time_nanos = 0;
  /// @brief Present fence file descriptor, or -1.
  int present_fence_fd = -1;

  bool operator==(const AndroidSurfaceControlStats& other) const {
    return acquire_time_nanos == other.acquire_time_nanos &&
           previous_release_fence_fd == other.previous_release_fence_fd &&
           latch_time_nanos == other.latch_time_nanos &&
           present_fence_fd == other.present_fence_fd;
  }

  bool operator!=(const AndroidSurfaceControlStats& other) const {
    return !(*this == other);
  }
};

/// @brief RGBA color value with floating-point channels in [0.0, 1.0].
struct AndroidSurfaceControlColor {
  float r = 0.0f;
  float g = 0.0f;
  float b = 0.0f;
  float a = 1.0f;

  bool operator==(const AndroidSurfaceControlColor& other) const {
    return r == other.r && g == other.g && b == other.b && a == other.a;
  }

  bool operator!=(const AndroidSurfaceControlColor& other) const {
    return !(*this == other);
  }
};

/// @brief Tracked state of a single SurfaceControl node for testing/inspection.
struct AndroidSurfaceControlState {
  std::string debug_name;
  bool visible = true;
  int32_t z_order = 0;
  float alpha = 1.0f;
  AndroidSurfaceControlRect source_rect;
  AndroidSurfaceControlRect dest_rect;
  AndroidSurfaceControlTransform transform =
      AndroidSurfaceControlTransform::kIdentity;
  void* current_hardware_buffer = nullptr;
  int current_acquire_fence_fd = -1;
  AndroidSurfaceControlColor color;
  bool has_color = false;
  int32_t frame_rate_compatibility = 0;
  float requested_frame_rate = 0.0f;
  bool enable_back_pressure = false;
};

/// @brief Reason why Vulkan autoselection succeeded or fell back to OpenGL ES
/// during kDeferred renderer resolution.
enum class AndroidVulkanResolutionStatus : uint32_t {
  kSelectedVulkan = 0,
  kApiLevelTooLow,
  kImpellerDisabled,
  kForceOpenGLES,
  kEmulatorDetected,
  kHuaweiClientIdRejected,
  kMediaTekVendorSdkTooLow,
  kBadSocBoardRejected,
  kVulkanLibraryUnavailable,
  kInstanceExtensionsMissing,
  kInstanceCreationFailed,
  kNoPhysicalDevice,
  kKnownBadVulkanDriver,
  kDeviceExtensionsMissing,
  kRequiredColorFormatUnsupported,
  kRequiredDepthStencilFormatUnsupported,
  kRequiredSampleCountsUnsupported,
  kRequiredQueuesMissing,
  kRequiredFeaturesUnsupported,
  kDeviceCreationFailed,
};

/// @brief Android system properties inspected by the kDeferred renderer
/// resolution callback before creating a VkDevice.
struct AndroidSystemPropertiesForVulkan {
  /// @brief Android SDK API level (must be >= 29 for Impeller Vulkan).
  int32_t api_level = 34;
  /// @brief Whether Impeller is enabled in manifest/launch switches.
  bool impeller_enabled = true;
  /// @brief Whether OpenGL ES is explicitly forced by manifest/switches.
  bool force_opengles = false;
  /// @brief Value of `ro.hardware` (checked against goldfish, ranchu, qemu).
  std::string ro_hardware;
  /// @brief Value of `ro.product.model` (checked for substring `gphone`).
  std::string ro_product_model;
  /// @brief Whether `/dev/qemu_pipe` exists on the filesystem.
  bool has_qemu_pipe = false;
  /// @brief Value of `ro.com.google.clientidbase` (checked for
  /// `android-huawei`).
  std::string ro_clientidbase;
  /// @brief Value of `ro.vendor.build.version.sdk` (checked for < 32 when
  /// MediaTek platform is present).
  int32_t vendor_api_level = 34;
  /// @brief Value of `ro.vendor.mediatek.platform`.
  std::string ro_mediatek_platform;
  /// @brief Value of `ro.product.board` (checked against `kBadSocs`).
  std::string ro_product_board;
};

// Minimal binary-compatible Vulkan C ABI definitions so
// `:flutter_embedder_native_src` compiles strictly under
// `FLUTTER_ENGINE_NO_PROTOTYPES` without depending on internal engine headers.
inline constexpr int32_t kVkSuccess = 0;
inline constexpr int32_t kVkSuboptimalKhr = 1000001003;
inline constexpr int32_t kVkErrorOutOfDateKhr = -1000001004;
inline constexpr int32_t kVkErrorSurfaceLostKhr = -1000000000;
inline constexpr int32_t kVkErrorNativeWindowInUseKhr = -1000000001;

inline constexpr uint32_t kVkApiVersion11 = (1u << 22) | (1u << 12);
inline constexpr size_t kVkMaxExtensionNameSize = 256;
inline constexpr size_t kVkMaxPhysicalDeviceNameSize = 256;
inline constexpr size_t kVkUuidSize = 16;

inline constexpr uint32_t kVkStructureTypeApplicationInfo = 0;
inline constexpr uint32_t kVkStructureTypeInstanceCreateInfo = 1;
inline constexpr uint32_t kVkStructureTypeDeviceQueueCreateInfo = 2;
inline constexpr uint32_t kVkStructureTypeDeviceCreateInfo = 3;
inline constexpr uint32_t kVkStructureTypeSubmitInfo = 4;
inline constexpr uint32_t kVkStructureTypeFenceCreateInfo = 8;
inline constexpr uint32_t kVkStructureTypeSemaphoreCreateInfo = 9;
inline constexpr uint32_t kVkStructureTypeCommandPoolCreateInfo = 39;
inline constexpr uint32_t kVkStructureTypeCommandBufferAllocateInfo = 40;
inline constexpr uint32_t kVkStructureTypeCommandBufferBeginInfo = 42;
inline constexpr uint32_t kVkStructureTypeImageMemoryBarrier = 45;
inline constexpr uint32_t kVkStructureTypePhysicalDeviceFeatures2 = 1000059000;
inline constexpr uint32_t kVkStructureTypePhysicalDevice16BitStorageFeatures =
    1000083000;
inline constexpr uint32_t kVkStructureTypeExportSemaphoreCreateInfo =
    1000077000;
inline constexpr uint32_t kVkStructureTypeSemaphoreGetFdInfoKhr = 1000079001;
inline constexpr uint32_t
    kVkStructureTypePhysicalDeviceSamplerYcbcrConversionFeatures = 1000156004;
inline constexpr uint32_t kVkStructureTypeAndroidSurfaceCreateInfoKhr =
    1000008000;
inline constexpr uint32_t kVkStructureTypeSwapchainCreateInfoKhr = 1000001000;
inline constexpr uint32_t kVkStructureTypePresentInfoKhr = 1000001001;

inline constexpr uint32_t kVkFormatR8G8B8A8Unorm = 37;
inline constexpr uint32_t kVkFormatD24UnormS8Uint = 129;
inline constexpr uint32_t kVkFormatD32SfloatS8Uint = 130;
inline constexpr uint32_t kVkColorSpaceSrgbNonlinearKhr = 0;

inline constexpr uint32_t kVkFormatFeatureColorAttachmentBit = 0x00000080u;
inline constexpr uint32_t kVkFormatFeatureDepthStencilAttachmentBit =
    0x00000200u;

inline constexpr uint32_t kVkSampleCount1Bit = 0x00000001u;
inline constexpr uint32_t kVkSampleCount4Bit = 0x00000004u;

inline constexpr uint32_t kVkQueueGraphicsBit = 0x00000001u;
inline constexpr uint32_t kVkQueueComputeBit = 0x00000002u;
inline constexpr uint32_t kVkQueueTransferBit = 0x00000004u;

inline constexpr uint32_t kVkImageLayoutUndefined = 0;
inline constexpr uint32_t kVkImageLayoutGeneral = 1;
inline constexpr uint32_t kVkImageLayoutColorAttachmentOptimal = 2;
inline constexpr uint32_t kVkImageLayoutPresentSrcKhr = 1000001002;

inline constexpr uint32_t kVkImageUsageTransferSrcBit = 0x00000001u;
inline constexpr uint32_t kVkImageUsageTransferDstBit = 0x00000002u;
inline constexpr uint32_t kVkImageUsageSampledBit = 0x00000004u;
inline constexpr uint32_t kVkImageUsageColorAttachmentBit = 0x00000010u;

inline constexpr uint32_t kVkSharingModeExclusive = 0;
inline constexpr uint32_t kVkSurfaceTransformIdentityBitKhr = 0x00000001u;
inline constexpr uint32_t kVkSurfaceTransformInheritBitKhr = 0x00000100u;
inline constexpr uint32_t kVkCompositeAlphaOpaqueBitKhr = 0x00000001u;
inline constexpr uint32_t kVkCompositeAlphaPreMultipliedBitKhr = 0x00000002u;
inline constexpr uint32_t kVkCompositeAlphaPostMultipliedBitKhr = 0x00000004u;
inline constexpr uint32_t kVkCompositeAlphaInheritBitKhr = 0x00000008u;
inline constexpr uint32_t kVkPresentModeFifoKhr = 2;

inline constexpr uint32_t kVkCommandPoolCreateResetCommandBufferBit =
    0x00000002u;
inline constexpr uint32_t kVkCommandBufferLevelPrimary = 0;
inline constexpr uint32_t kVkCommandBufferUsageOneTimeSubmitBit = 0x00000001u;

inline constexpr uint32_t kVkPipelineStageTopOfPipeBit = 0x00000001u;
inline constexpr uint32_t kVkPipelineStageColorAttachmentOutputBit =
    0x00000400u;
inline constexpr uint32_t kVkPipelineStageBottomOfPipeBit = 0x00002000u;
inline constexpr uint32_t kVkPipelineStageAllCommandsBit = 0x00010000u;

inline constexpr uint32_t kVkAccessColorAttachmentWriteBit = 0x00000100u;
inline constexpr uint32_t kVkAccessMemoryReadBit = 0x00008000u;
inline constexpr uint32_t kVkImageAspectColorBit = 0x00000001u;
inline constexpr uint32_t kVkQueueFamilyIgnored = ~0u;

inline constexpr uint32_t kVkExternalSemaphoreHandleTypeSyncFdBit = 0x00000010u;

struct VkApplicationInfoCompat {
  uint32_t sType;
  const void* pNext;
  const char* pApplicationName;
  uint32_t applicationVersion;
  const char* pEngineName;
  uint32_t engineVersion;
  uint32_t apiVersion;
};

struct VkInstanceCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  const VkApplicationInfoCompat* pApplicationInfo;
  uint32_t enabledLayerCount;
  const char* const* ppEnabledLayerNames;
  uint32_t enabledExtensionCount;
  const char* const* ppEnabledExtensionNames;
};

struct VkExtensionPropertiesCompat {
  char extensionName[kVkMaxExtensionNameSize];
  uint32_t specVersion;
};

struct VkExtent2DCompat {
  uint32_t width;
  uint32_t height;
};

struct VkExtent3DCompat {
  uint32_t width;
  uint32_t height;
  uint32_t depth;
};

struct VkPhysicalDeviceLimitsCompat {
  uint32_t maxImageDimension1D;
  uint32_t maxImageDimension2D;
  uint32_t maxImageDimension3D;
  uint32_t maxImageDimensionCube;
  uint32_t maxImageArrayLayers;
  uint32_t maxTexelBufferElements;
  uint32_t maxUniformBufferRange;
  uint32_t maxStorageBufferRange;
  uint32_t maxPushConstantsSize;
  uint32_t maxMemoryAllocationCount;
  uint32_t maxSamplerAllocationCount;
  uint64_t bufferImageGranularity;
  uint64_t sparseAddressSpaceSize;
  uint32_t maxBoundDescriptorSets;
  uint32_t maxPerStageDescriptorSamplers;
  uint32_t maxPerStageDescriptorUniformBuffers;
  uint32_t maxPerStageDescriptorStorageBuffers;
  uint32_t maxPerStageDescriptorSampledImages;
  uint32_t maxPerStageDescriptorStorageImages;
  uint32_t maxPerStageDescriptorInputAttachments;
  uint32_t maxPerStageResources;
  uint32_t maxDescriptorSetSamplers;
  uint32_t maxDescriptorSetUniformBuffers;
  uint32_t maxDescriptorSetUniformBuffersDynamic;
  uint32_t maxDescriptorSetStorageBuffers;
  uint32_t maxDescriptorSetStorageBuffersDynamic;
  uint32_t maxDescriptorSetSampledImages;
  uint32_t maxDescriptorSetStorageImages;
  uint32_t maxDescriptorSetInputAttachments;
  uint32_t maxVertexInputAttributes;
  uint32_t maxVertexInputBindings;
  uint32_t maxVertexInputAttributeOffset;
  uint32_t maxVertexInputBindingStride;
  uint32_t maxVertexOutputComponents;
  uint32_t maxTessellationGenerationLevel;
  uint32_t maxTessellationPatchSize;
  uint32_t maxTessellationControlPerVertexInputComponents;
  uint32_t maxTessellationControlPerVertexOutputComponents;
  uint32_t maxTessellationControlPerPatchOutputComponents;
  uint32_t maxTessellationControlTotalOutputComponents;
  uint32_t maxTessellationEvaluationInputComponents;
  uint32_t maxTessellationEvaluationOutputComponents;
  uint32_t maxGeometryShaderInvocations;
  uint32_t maxGeometryInputComponents;
  uint32_t maxGeometryOutputComponents;
  uint32_t maxGeometryOutputVertices;
  uint32_t maxGeometryTotalOutputComponents;
  uint32_t maxFragmentInputComponents;
  uint32_t maxFragmentOutputAttachments;
  uint32_t maxFragmentDualSrcAttachments;
  uint32_t maxFragmentCombinedOutputResources;
  uint32_t maxComputeSharedMemorySize;
  uint32_t maxComputeWorkGroupCount[3];
  uint32_t maxComputeWorkGroupInvocations;
  uint32_t maxComputeWorkGroupSize[3];
  uint32_t subPixelPrecisionBits;
  uint32_t subTexelPrecisionBits;
  uint32_t mipmapPrecisionBits;
  uint32_t maxDrawIndexedIndexValue;
  uint32_t maxDrawIndirectCount;
  float maxSamplerLodBias;
  float maxSamplerAnisotropy;
  uint32_t maxViewports;
  uint32_t maxViewportDimensions[2];
  float viewportBoundsRange[2];
  uint32_t viewportSubPixelBits;
  size_t minMemoryMapAlignment;
  uint64_t minTexelBufferOffsetAlignment;
  uint64_t minUniformBufferOffsetAlignment;
  uint64_t minStorageBufferOffsetAlignment;
  int32_t minTexelOffset;
  uint32_t maxTexelOffset;
  int32_t minTexelGatherOffset;
  uint32_t maxTexelGatherOffset;
  float minInterpolationOffset;
  float maxInterpolationOffset;
  uint32_t subPixelInterpolationOffsetBits;
  uint32_t maxFramebufferWidth;
  uint32_t maxFramebufferHeight;
  uint32_t maxFramebufferLayers;
  uint32_t framebufferColorSampleCounts;
  uint32_t framebufferDepthSampleCounts;
  uint32_t framebufferStencilSampleCounts;
  uint32_t framebufferNoAttachmentsSampleCounts;
  uint32_t maxColorAttachments;
  uint32_t sampledImageColorSampleCounts;
  uint32_t sampledImageIntegerSampleCounts;
  uint32_t sampledImageDepthSampleCounts;
  uint32_t sampledImageStencilSampleCounts;
  uint32_t storageImageSampleCounts;
  uint32_t maxSampleMaskWords;
  uint32_t timestampComputeAndGraphics;
  float timestampPeriod;
  uint32_t maxClipDistances;
  uint32_t maxCullDistances;
  uint32_t maxCombinedClipAndCullDistances;
  uint32_t discreteQueuePriorities;
  float pointSizeRange[2];
  float lineWidthRange[2];
  float pointSizeGranularity;
  float lineWidthGranularity;
  uint32_t strictLines;
  uint32_t standardSampleLocations;
  uint64_t optimalBufferCopyOffsetAlignment;
  uint64_t optimalBufferCopyRowPitchAlignment;
  uint64_t nonCoherentAtomSize;
};

struct VkPhysicalDeviceSparsePropertiesCompat {
  uint32_t residencyStandard2DBlockShape;
  uint32_t residencyStandard2DMultisampleBlockShape;
  uint32_t residencyStandard3DBlockShape;
  uint32_t residencyAlignedMipSize;
  uint32_t residencyNonResidentStrict;
};

/// @brief Binary-compatible `VkPhysicalDeviceProperties` satisfying the
/// template requirements of `flutter::VulkanDriverInfo`.
struct VkPhysicalDevicePropertiesCompat {
  uint32_t apiVersion;
  uint32_t driverVersion;
  uint32_t vendorID;
  uint32_t deviceID;
  uint32_t deviceType;
  char deviceName[kVkMaxPhysicalDeviceNameSize];
  uint8_t pipelineCacheUUID[kVkUuidSize];
  VkPhysicalDeviceLimitsCompat limits;
  VkPhysicalDeviceSparsePropertiesCompat sparseProperties;
};

struct VkFormatPropertiesCompat {
  uint32_t linearTilingFeatures;
  uint32_t optimalTilingFeatures;
  uint32_t bufferFeatures;
};

struct VkQueueFamilyPropertiesCompat {
  uint32_t queueFlags;
  uint32_t queueCount;
  uint32_t timestampValidBits;
  VkExtent3DCompat minImageTransferGranularity;
};

struct VkPhysicalDeviceFeaturesCompat {
  uint32_t features[55];
};

struct VkPhysicalDeviceFeatures2Compat {
  uint32_t sType;
  void* pNext;
  VkPhysicalDeviceFeaturesCompat features;
};

struct VkPhysicalDeviceSamplerYcbcrConversionFeaturesCompat {
  uint32_t sType;
  void* pNext;
  uint32_t samplerYcbcrConversion;
};

struct VkPhysicalDevice16BitStorageFeaturesCompat {
  uint32_t sType;
  void* pNext;
  uint32_t storageBuffer16BitAccess;
  uint32_t uniformAndStorageBuffer16BitAccess;
  uint32_t storagePushConstant16;
  uint32_t storageInputOutput16;
};

struct VkDeviceQueueCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t queueFamilyIndex;
  uint32_t queueCount;
  const float* pQueuePriorities;
};

struct VkDeviceCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t queueCreateInfoCount;
  const VkDeviceQueueCreateInfoCompat* pQueueCreateInfos;
  uint32_t enabledLayerCount;
  const char* const* ppEnabledLayerNames;
  uint32_t enabledExtensionCount;
  const char* const* ppEnabledExtensionNames;
  const VkPhysicalDeviceFeaturesCompat* pEnabledFeatures;
};

struct VkAndroidSurfaceCreateInfoKHRCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  void* window;
};

struct VkSurfaceCapabilitiesKHRCompat {
  uint32_t minImageCount;
  uint32_t maxImageCount;
  VkExtent2DCompat currentExtent;
  VkExtent2DCompat minImageExtent;
  VkExtent2DCompat maxImageExtent;
  uint32_t maxImageArrayLayers;
  uint32_t supportedTransforms;
  uint32_t currentTransform;
  uint32_t supportedCompositeAlpha;
  uint32_t supportedUsageFlags;
};

struct VkSurfaceFormatKHRCompat {
  uint32_t format;
  uint32_t colorSpace;
};

struct VkSwapchainCreateInfoKHRCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  uint64_t surface;
  uint32_t minImageCount;
  uint32_t imageFormat;
  uint32_t imageColorSpace;
  VkExtent2DCompat imageExtent;
  uint32_t imageArrayLayers;
  uint32_t imageUsage;
  uint32_t imageSharingMode;
  uint32_t queueFamilyIndexCount;
  const uint32_t* pQueueFamilyIndices;
  uint32_t preTransform;
  uint32_t compositeAlpha;
  uint32_t presentMode;
  uint32_t clipped;
  uint64_t oldSwapchain;
};

struct VkPresentInfoKHRCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t waitSemaphoreCount;
  const uint64_t* pWaitSemaphores;
  uint32_t swapchainCount;
  const uint64_t* pSwapchains;
  const uint32_t* pImageIndices;
  int32_t* pResults;
};

struct VkFenceCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
};

struct VkExportSemaphoreCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t handleTypes;
};

struct VkSemaphoreCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
};

struct VkSemaphoreGetFdInfoKHRCompat {
  uint32_t sType;
  const void* pNext;
  uint64_t semaphore;
  uint32_t handleType;
};

struct VkCommandPoolCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t queueFamilyIndex;
};

struct VkCommandBufferAllocateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint64_t commandPool;
  uint32_t level;
  uint32_t commandBufferCount;
};

struct VkCommandBufferBeginInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  const void* pInheritanceInfo;
};

struct VkImageSubresourceRangeCompat {
  uint32_t aspectMask;
  uint32_t baseMipLevel;
  uint32_t levelCount;
  uint32_t baseArrayLayer;
  uint32_t layerCount;
};

struct VkImageMemoryBarrierCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t srcAccessMask;
  uint32_t dstAccessMask;
  uint32_t oldLayout;
  uint32_t newLayout;
  uint32_t srcQueueFamilyIndex;
  uint32_t dstQueueFamilyIndex;
  uint64_t image;
  VkImageSubresourceRangeCompat subresourceRange;
};

struct VkSubmitInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t waitSemaphoreCount;
  const uint64_t* pWaitSemaphores;
  const uint32_t* pWaitDstStageMask;
  uint32_t commandBufferCount;
  void* const* pCommandBuffers;
  uint32_t signalSemaphoreCount;
  const uint64_t* pSignalSemaphores;
};

class AndroidSurfaceTransaction;
class AndroidSurfaceControlProvider;

/// @brief Abstract representation of an Android ASurfaceControl node AND
/// the RFC 410.0000 surface, swapchain, deferred renderer resolution, HCPP
/// fence synchronization, and low-memory controller.
///
/// Subclasses (`DefaultAndroidSurfaceControl`, `InMemoryAndroidSurfaceControl`)
/// implement the NDK `ASurfaceControl` node operations, while concrete
/// instances of `AndroidSurfaceControl` also manage per-`FlutterViewId`
/// surfaces (`ANativeWindow*`, `ASurfaceControl*`, swapchains), the
/// `kDeferred` `resolve_callback`, `PresentImage` layout transitions, HCPP
/// `VkSemaphore` sync fd export, and `NotifyLowMemoryWarning` dispatch.
class AndroidSurfaceControl {
 public:
  /// @brief Constructs an `AndroidSurfaceControl` controller with optional
  /// dynamic library loader and surface control provider.
  explicit AndroidSurfaceControl(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr,
      std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider =
          nullptr);

  virtual ~AndroidSurfaceControl();

  /// @brief Returns true if the underlying ASurfaceControl handle is valid.
  virtual bool IsValid() const;

  /// @brief Returns the raw opaque ASurfaceControl* pointer.
  virtual void* RawHandle() const;

  /// @brief Returns the debug name passed at creation time.
  virtual const std::string& DebugName() const;

  /// @brief Configures the C-API proc table and engine handle used to invoke
  /// `NotifyLowMemoryWarning`.
  void SetEngineProcTable(const FlutterEngineProcTable& proc_table,
                          FLUTTER_API_SYMBOL(FlutterEngine) engine);

  /// @brief Configures the system properties evaluated during `kDeferred`
  /// renderer resolution.
  void SetSystemPropertiesForVulkan(
      const AndroidSystemPropertiesForVulkan& props);

  /// @brief Returns the current system properties configured for Vulkan
  /// resolution.
  const AndroidSystemPropertiesForVulkan& GetSystemPropertiesForVulkan() const;

  /// @brief Evaluates Android system properties (`IsDeviceEmulator`, Huawei,
  /// MediaTek API < 32, and `kBadSocs`) prior to loading Vulkan.
  static AndroidVulkanResolutionStatus EvaluateSystemProperties(
      const AndroidSystemPropertiesForVulkan& props);

  /// @brief Populates a `FlutterRendererConfig` with `kDeferred` and binds
  /// `ResolveRendererConfigCallback`.
  void PopulateDeferredRendererConfig(FlutterRendererConfig* config_out);

  /// @brief Static C-API callback for `FlutterDeferredRendererConfig`.
  static bool ResolveRendererConfigCallback(void* user_data,
                                            FlutterRendererConfig* config_out);

  /// @brief Performs single-pass `kDeferred` resolution on the raster thread:
  /// checks system properties, `VulkanDriverInfo`, and `CapabilitiesVK`
  /// extensions/formats/sample counts/queues/features before `vkCreateDevice`,
  /// returning `kVulkan` or falling back to `kOpenGL`.
  bool ResolveRendererConfig(FlutterRendererConfig* config_out);

  /// @brief Returns the most recent Vulkan resolution status recorded by
  /// `ResolveRendererConfig`.
  AndroidVulkanResolutionStatus LastVulkanResolutionStatus() const;

  /// @brief Returns the resolved renderer type (`kVulkan` or `kOpenGL`).
  FlutterRendererType ResolvedRendererType() const;

  /// @brief Returns the active Vulkan instance handle (`VkInstance`), or
  /// `nullptr`.
  void* GetVulkanInstance() const;

  /// @brief Returns the active Vulkan physical device handle
  /// (`VkPhysicalDevice`), or `nullptr`.
  void* GetVulkanPhysicalDevice() const;

  /// @brief Returns the active Vulkan logical device handle (`VkDevice`), or
  /// `nullptr`.
  void* GetVulkanDevice() const;

  /// @brief Returns the active Vulkan graphics queue handle (`VkQueue`), or
  /// `nullptr`.
  void* GetVulkanQueue() const;

  /// @brief Returns the active Vulkan graphics queue family index.
  uint32_t GetVulkanQueueFamilyIndex() const;

  /// @brief Sets an external texture frame callback for Vulkan or OpenGL ES.
  void SetVulkanExternalTextureCallback(
      FlutterVulkanTextureFrameCallback callback);
  void SetOpenGLExternalTextureCallback(
      FlutterOpenGLTextureFrameCallback callback);

  // ---------------------------------------------------------------------------
  // Per-FlutterViewId Surface Lifecycle
  // ---------------------------------------------------------------------------

  /// @brief Registers or replaces the surface for `view_id`.
  bool SurfaceCreated(FlutterViewId view_id,
                      void* native_window,
                      void* surface_control = nullptr,
                      uint32_t width = 0,
                      uint32_t height = 0);

  /// @brief Convenience overload for the implicit view (`view_id = 0`).
  bool SurfaceCreated(void* native_window,
                      uint32_t width = 0,
                      uint32_t height = 0);

  /// @brief Replaces the `ANativeWindow*` for `view_id` on window changes.
  bool SurfaceWindowChanged(FlutterViewId view_id,
                            void* native_window,
                            void* surface_control = nullptr,
                            uint32_t width = 0,
                            uint32_t height = 0);

  /// @brief Updates the dimensions of the surface for `view_id` and marks its
  /// swapchain out of date so it is recreated on the next frame.
  bool SurfaceChanged(FlutterViewId view_id, uint32_t width, uint32_t height);

  /// @brief Convenience overload for the implicit view (`view_id = 0`).
  bool SurfaceChanged(uint32_t width, uint32_t height);

  /// @brief Destroys the swapchain and surface for `view_id`. If no views
  /// remain visible (`!HasAnySurface()`), dispatches
  /// `proc_table_.NotifyLowMemoryWarning(engine_)`.
  void SurfaceDestroyed(FlutterViewId view_id);

  /// @brief Convenience overload for the implicit view (`view_id = 0`).
  void SurfaceDestroyed();

  /// @brief Handles Android `onTrimMemory` callbacks by dispatching
  /// `proc_table_.NotifyLowMemoryWarning(engine_)` when level >=
  /// `TRIM_MEMORY_RUNNING_LOW` (10) or `TRIM_MEMORY_UI_HIDDEN` (20).
  void OnTrimMemory(int level);

  /// @brief Returns the number of times `NotifyLowMemoryWarning` was invoked.
  size_t LowMemoryWarningCount() const;

  /// @brief Returns true if `view_id` currently has an attached native window.
  bool HasSurface(FlutterViewId view_id = kAndroidImplicitViewId) const;

  /// @brief Returns the `ANativeWindow*` for `view_id`, or `nullptr`.
  void* GetNativeWindow(FlutterViewId view_id = kAndroidImplicitViewId) const;

  /// @brief Returns the `ASurfaceControl*` for `view_id`, or `nullptr`.
  void* GetASurfaceControl(
      FlutterViewId view_id = kAndroidImplicitViewId) const;

  /// @brief Returns the surface width for `view_id`.
  uint32_t GetSurfaceWidth(
      FlutterViewId view_id = kAndroidImplicitViewId) const;

  /// @brief Returns the surface height for `view_id`.
  uint32_t GetSurfaceHeight(
      FlutterViewId view_id = kAndroidImplicitViewId) const;

  // ---------------------------------------------------------------------------
  // Vulkan Swapchain, PresentImage, and HCPP Fence Export
  // ---------------------------------------------------------------------------

  /// @brief Acquires the next swapchain image for `view_id`, creating or
  /// recreating the swapchain if needed.
  bool AcquireNextImageForView(FlutterViewId view_id,
                               const FlutterFrameInfo* frame_info,
                               FlutterVulkanImage* image_out);

  /// @brief Static C-API callback for `get_next_image_callback`.
  static FlutterVulkanImage GetNextImageCallback(
      void* user_data,
      const FlutterFrameInfo* frame_info);

  /// @brief Transitions `image->image` from `oldLayout =
  /// VK_IMAGE_LAYOUT_GENERAL` to `VK_IMAGE_LAYOUT_PRESENT_SRC_KHR` and presents
  /// it on the swapchain for `view_id`.
  bool PresentImageForView(FlutterViewId view_id,
                           const FlutterVulkanImage* image);

  /// @brief Static C-API callback for `present_image_callback`.
  static bool PresentImageCallback(void* user_data,
                                   const FlutterVulkanImage* image);

  /// @brief Static C-API callback for `get_instance_proc_address_callback`.
  static void* GetInstanceProcAddressCallback(
      void* user_data,
      FlutterVulkanInstanceHandle instance,
      const char* name);

  /// @brief Exports an acquire sync fd from an embedder-owned `VkSemaphore`
  /// after submitting a barrier on `VkQueue`, and optionally attaches the
  /// buffer and fence to an `AndroidSurfaceTransaction` for HCPP.
  int ExportHcppAcquireFenceFd(FlutterViewId view_id,
                               uint64_t image_handle = 0,
                               AndroidSurfaceTransaction* transaction = nullptr,
                               AndroidSurfaceControl* surface_node = nullptr,
                               void* hardware_buffer = nullptr);

  // ---------------------------------------------------------------------------
  // Compositor Backing Store & Present View Callbacks
  // ---------------------------------------------------------------------------

  /// @brief Creates a compositor backing store, returning `false` when no
  /// `ANativeWindow*` is attached or when mid-frame surface loss occurs.
  bool CreateBackingStore(const FlutterBackingStoreConfig* config,
                          FlutterBackingStore* backing_store_out);

  /// @brief Collects a compositor backing store.
  bool CollectBackingStore(const FlutterBackingStore* backing_store);

  /// @brief Presents compositor layers for the implicit view.
  bool PresentLayers(const FlutterLayer** layers, size_t layers_count);

  /// @brief Presents compositor layers for `info->view_id`
  /// (`present_view_callback`).
  bool PresentView(const FlutterPresentViewInfo* info);

  // ---------------------------------------------------------------------------
  // Inspection Hooks for Unit Tests
  // ---------------------------------------------------------------------------

  /// @brief Returns the `oldLayout` recorded by the most recent `PresentImage`
  /// barrier.
  uint32_t LastPresentBarrierOldLayout() const;

  /// @brief Returns the `newLayout` recorded by the most recent `PresentImage`
  /// barrier.
  uint32_t LastPresentBarrierNewLayout() const;

  /// @brief Returns the `preTransform` used by the most recent swapchain
  /// creation for `view_id`.
  uint32_t LastSwapchainPreTransform(
      FlutterViewId view_id = kAndroidImplicitViewId) const;

  /// @brief Returns the number of times `vkDestroySurfaceKHR` was called.
  size_t VulkanSurfaceDestroyCount() const;

  /// @brief Returns the number of times `vkDestroySwapchainKHR` was called.
  size_t VulkanSwapchainDestroyCount() const;

  /// @brief Returns the most recently exported HCPP acquire sync fd, or -1.
  int LastExportedHcppFenceFd() const;

 protected:
  AndroidSurfaceControl(const std::string& debug_name, void* raw_handle);

 private:
  struct PerViewSurfaceState {
    FlutterViewId view_id = kAndroidImplicitViewId;
    void* native_window = nullptr;
    void* surface_control = nullptr;
    uint32_t width = 0;
    uint32_t height = 0;
    uint64_t vk_surface = 0;
    uint64_t vk_swapchain = 0;
    uint32_t vk_surface_format = kVkFormatR8G8B8A8Unorm;
    uint32_t vk_pre_transform = kVkSurfaceTransformIdentityBitKhr;
    std::vector<uint64_t> swapchain_images;
    uint32_t current_image_index = 0;
    bool has_acquired_image = false;
    bool swapchain_needs_recreation = true;
    uint64_t acquire_fence = 0;
    uint64_t render_complete_semaphore = 0;
    uint64_t hcpp_export_semaphore = 0;
    uint64_t command_pool = 0;
    std::vector<void*> command_buffers;
    void* egl_surface = nullptr;
  };

  using PFN_vkGetInstanceProcAddr = void* (*)(void* instance, const char* name);
  using PFN_vkEnumerateInstanceExtensionProperties =
      int32_t (*)(const char* layer_name,
                  uint32_t* count,
                  VkExtensionPropertiesCompat* props);
  using PFN_vkCreateInstance =
      int32_t (*)(const VkInstanceCreateInfoCompat* create_info,
                  const void* allocator,
                  void** instance_out);
  using PFN_vkDestroyInstance = void (*)(void* instance, const void* allocator);
  using PFN_vkEnumeratePhysicalDevices = int32_t (*)(void* instance,
                                                     uint32_t* count,
                                                     void** physical_devices);
  using PFN_vkGetPhysicalDeviceProperties =
      void (*)(void* physical_device, VkPhysicalDevicePropertiesCompat* props);
  using PFN_vkGetPhysicalDeviceFormatProperties =
      void (*)(void* physical_device,
               uint32_t format,
               VkFormatPropertiesCompat* props);
  using PFN_vkGetPhysicalDeviceQueueFamilyProperties =
      void (*)(void* physical_device,
               uint32_t* count,
               VkQueueFamilyPropertiesCompat* props);
  using PFN_vkGetPhysicalDeviceFeatures2 =
      void (*)(void* physical_device,
               VkPhysicalDeviceFeatures2Compat* features);
  using PFN_vkEnumerateDeviceExtensionProperties =
      int32_t (*)(void* physical_device,
                  const char* layer_name,
                  uint32_t* count,
                  VkExtensionPropertiesCompat* props);
  using PFN_vkCreateDevice =
      int32_t (*)(void* physical_device,
                  const VkDeviceCreateInfoCompat* create_info,
                  const void* allocator,
                  void** device_out);
  using PFN_vkDestroyDevice = void (*)(void* device, const void* allocator);
  using PFN_vkGetDeviceProcAddr = void* (*)(void* device, const char* name);
  using PFN_vkGetDeviceQueue = void (*)(void* device,
                                        uint32_t queue_family_index,
                                        uint32_t queue_index,
                                        void** queue_out);
  using PFN_vkCreateAndroidSurfaceKHR =
      int32_t (*)(void* instance,
                  const VkAndroidSurfaceCreateInfoKHRCompat* create_info,
                  const void* allocator,
                  uint64_t* surface_out);
  using PFN_vkDestroySurfaceKHR = void (*)(void* instance,
                                           uint64_t surface,
                                           const void* allocator);
  using PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR =
      int32_t (*)(void* physical_device,
                  uint64_t surface,
                  VkSurfaceCapabilitiesKHRCompat* caps);
  using PFN_vkGetPhysicalDeviceSurfaceFormatsKHR =
      int32_t (*)(void* physical_device,
                  uint64_t surface,
                  uint32_t* count,
                  VkSurfaceFormatKHRCompat* formats);
  using PFN_vkCreateSwapchainKHR =
      int32_t (*)(void* device,
                  const VkSwapchainCreateInfoKHRCompat* create_info,
                  const void* allocator,
                  uint64_t* swapchain_out);
  using PFN_vkDestroySwapchainKHR = void (*)(void* device,
                                             uint64_t swapchain,
                                             const void* allocator);
  using PFN_vkGetSwapchainImagesKHR = int32_t (*)(void* device,
                                                  uint64_t swapchain,
                                                  uint32_t* count,
                                                  uint64_t* images);
  using PFN_vkAcquireNextImageKHR = int32_t (*)(void* device,
                                                uint64_t swapchain,
                                                uint64_t timeout,
                                                uint64_t semaphore,
                                                uint64_t fence,
                                                uint32_t* image_index_out);
  using PFN_vkQueuePresentKHR =
      int32_t (*)(void* queue, const VkPresentInfoKHRCompat* present_info);
  using PFN_vkQueueSubmit = int32_t (*)(void* queue,
                                        uint32_t submit_count,
                                        const VkSubmitInfoCompat* submits,
                                        uint64_t fence);
  using PFN_vkQueueWaitIdle = int32_t (*)(void* queue);
  using PFN_vkCreateFence =
      int32_t (*)(void* device,
                  const VkFenceCreateInfoCompat* create_info,
                  const void* allocator,
                  uint64_t* fence_out);
  using PFN_vkDestroyFence = void (*)(void* device,
                                      uint64_t fence,
                                      const void* allocator);
  using PFN_vkWaitForFences = int32_t (*)(void* device,
                                          uint32_t fence_count,
                                          const uint64_t* fences,
                                          uint32_t wait_all,
                                          uint64_t timeout);
  using PFN_vkResetFences = int32_t (*)(void* device,
                                        uint32_t fence_count,
                                        const uint64_t* fences);
  using PFN_vkCreateSemaphore =
      int32_t (*)(void* device,
                  const VkSemaphoreCreateInfoCompat* create_info,
                  const void* allocator,
                  uint64_t* semaphore_out);
  using PFN_vkDestroySemaphore = void (*)(void* device,
                                          uint64_t semaphore,
                                          const void* allocator);
  using PFN_vkGetSemaphoreFdKHR =
      int32_t (*)(void* device,
                  const VkSemaphoreGetFdInfoKHRCompat* get_fd_info,
                  int* fd_out);
  using PFN_vkCreateCommandPool =
      int32_t (*)(void* device,
                  const VkCommandPoolCreateInfoCompat* create_info,
                  const void* allocator,
                  uint64_t* pool_out);
  using PFN_vkDestroyCommandPool = void (*)(void* device,
                                            uint64_t command_pool,
                                            const void* allocator);
  using PFN_vkAllocateCommandBuffers =
      int32_t (*)(void* device,
                  const VkCommandBufferAllocateInfoCompat* alloc_info,
                  void** command_buffers_out);
  using PFN_vkResetCommandBuffer = int32_t (*)(void* command_buffer,
                                               uint32_t flags);
  using PFN_vkBeginCommandBuffer =
      int32_t (*)(void* command_buffer,
                  const VkCommandBufferBeginInfoCompat* begin_info);
  using PFN_vkEndCommandBuffer = int32_t (*)(void* command_buffer);
  using PFN_vkCmdPipelineBarrier =
      void (*)(void* command_buffer,
               uint32_t src_stage_mask,
               uint32_t dst_stage_mask,
               uint32_t dependency_flags,
               uint32_t memory_barrier_count,
               const void* memory_barriers,
               uint32_t buffer_memory_barrier_count,
               const void* buffer_memory_barriers,
               uint32_t image_memory_barrier_count,
               const VkImageMemoryBarrierCompat* image_memory_barriers);

  bool InitializeVulkanOnRasterThreadLocked();
  bool InitializeOpenGLFallbackLocked(FlutterRendererConfig* config_out);
  bool EnsureSwapchainForViewLocked(PerViewSurfaceState& state,
                                    uint32_t requested_width,
                                    uint32_t requested_height);
  void DestroyVulkanSwapchainLocked(PerViewSurfaceState& state);
  void DestroyVulkanSurfaceLocked(PerViewSurfaceState& state);
  void TeardownVulkanLocked();
  bool HasAnySurfaceLocked() const;
  void DispatchLowMemoryWarningLocked();

  std::string debug_name_;
  void* raw_handle_ = nullptr;
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider_;

  mutable std::mutex mutex_;
  FlutterEngineProcTable proc_table_ = {};
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  size_t low_memory_warning_count_ = 0;

  AndroidSystemPropertiesForVulkan system_props_;
  AndroidVulkanResolutionStatus last_vulkan_status_ =
      AndroidVulkanResolutionStatus::kSelectedVulkan;
  FlutterRendererType resolved_renderer_type_ = kOpenGL;

  FlutterVulkanTextureFrameCallback vulkan_external_texture_callback_ = nullptr;
  FlutterOpenGLTextureFrameCallback opengl_external_texture_callback_ = nullptr;

  std::map<FlutterViewId, PerViewSurfaceState> view_surfaces_;
  FlutterViewId active_acquire_view_id_ = kAndroidImplicitViewId;

  std::unique_ptr<OSLibrary> vulkan_library_;
  std::unique_ptr<OSLibrary> egl_library_;
  std::unique_ptr<OSLibrary> gles_library_;

  void* vk_instance_ = nullptr;
  void* vk_physical_device_ = nullptr;
  void* vk_device_ = nullptr;
  void* vk_queue_ = nullptr;
  uint32_t vk_queue_family_index_ = 0;
  std::vector<std::string> enabled_instance_extensions_;
  std::vector<const char*> enabled_instance_extension_ptrs_;
  std::vector<std::string> enabled_device_extensions_;
  std::vector<const char*> enabled_device_extension_ptrs_;

  // All Vulkan procedure pointers use `lower_snake_case` (`vk_*_fn_`) and are
  // explicitly guarded at function entry.
  PFN_vkGetInstanceProcAddr vk_get_instance_proc_addr_fn_ = nullptr;
  PFN_vkEnumerateInstanceExtensionProperties
      vk_enumerate_instance_extension_properties_fn_ = nullptr;
  PFN_vkCreateInstance vk_create_instance_fn_ = nullptr;
  PFN_vkDestroyInstance vk_destroy_instance_fn_ = nullptr;
  PFN_vkEnumeratePhysicalDevices vk_enumerate_physical_devices_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceProperties vk_get_physical_device_properties_fn_ =
      nullptr;
  PFN_vkGetPhysicalDeviceFormatProperties
      vk_get_physical_device_format_properties_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceQueueFamilyProperties
      vk_get_physical_device_queue_family_properties_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceFeatures2 vk_get_physical_device_features_2_fn_ =
      nullptr;
  PFN_vkEnumerateDeviceExtensionProperties
      vk_enumerate_device_extension_properties_fn_ = nullptr;
  PFN_vkCreateDevice vk_create_device_fn_ = nullptr;
  PFN_vkDestroyDevice vk_destroy_device_fn_ = nullptr;
  PFN_vkGetDeviceProcAddr vk_get_device_proc_addr_fn_ = nullptr;
  PFN_vkGetDeviceQueue vk_get_device_queue_fn_ = nullptr;
  PFN_vkCreateAndroidSurfaceKHR vk_create_android_surface_khr_fn_ = nullptr;
  PFN_vkDestroySurfaceKHR vk_destroy_surface_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR
      vk_get_physical_device_surface_capabilities_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfaceFormatsKHR
      vk_get_physical_device_surface_formats_khr_fn_ = nullptr;
  PFN_vkCreateSwapchainKHR vk_create_swapchain_khr_fn_ = nullptr;
  PFN_vkDestroySwapchainKHR vk_destroy_swapchain_khr_fn_ = nullptr;
  PFN_vkGetSwapchainImagesKHR vk_get_swapchain_images_khr_fn_ = nullptr;
  PFN_vkAcquireNextImageKHR vk_acquire_next_image_khr_fn_ = nullptr;
  PFN_vkQueuePresentKHR vk_queue_present_khr_fn_ = nullptr;
  PFN_vkQueueSubmit vk_queue_submit_fn_ = nullptr;
  PFN_vkQueueWaitIdle vk_queue_wait_idle_fn_ = nullptr;
  PFN_vkCreateFence vk_create_fence_fn_ = nullptr;
  PFN_vkDestroyFence vk_destroy_fence_fn_ = nullptr;
  PFN_vkWaitForFences vk_wait_for_fences_fn_ = nullptr;
  PFN_vkResetFences vk_reset_fences_fn_ = nullptr;
  PFN_vkCreateSemaphore vk_create_semaphore_fn_ = nullptr;
  PFN_vkDestroySemaphore vk_destroy_semaphore_fn_ = nullptr;
  PFN_vkGetSemaphoreFdKHR vk_get_semaphore_fd_khr_fn_ = nullptr;
  PFN_vkCreateCommandPool vk_create_command_pool_fn_ = nullptr;
  PFN_vkDestroyCommandPool vk_destroy_command_pool_fn_ = nullptr;
  PFN_vkAllocateCommandBuffers vk_allocate_command_buffers_fn_ = nullptr;
  PFN_vkResetCommandBuffer vk_reset_command_buffer_fn_ = nullptr;
  PFN_vkBeginCommandBuffer vk_begin_command_buffer_fn_ = nullptr;
  PFN_vkEndCommandBuffer vk_end_command_buffer_fn_ = nullptr;
  PFN_vkCmdPipelineBarrier vk_cmd_pipeline_barrier_fn_ = nullptr;

  uint32_t last_present_barrier_old_layout_ = kVkImageLayoutUndefined;
  uint32_t last_present_barrier_new_layout_ = kVkImageLayoutUndefined;
  size_t vk_surface_destroy_count_ = 0;
  size_t vk_swapchain_destroy_count_ = 0;
  int last_exported_hcpp_fence_fd_ = -1;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceControl);
};

/// @brief Abstract representation of an Android ASurfaceTransaction.
class AndroidSurfaceTransaction {
 public:
  using OnCompleteCallback =
      std::function<void(const AndroidSurfaceControlStats& stats)>;
  using OnCommitCallback =
      std::function<void(const AndroidSurfaceControlStats& stats)>;

  virtual ~AndroidSurfaceTransaction() = default;

  /// @brief Returns true if the underlying ASurfaceTransaction handle is valid.
  virtual bool IsValid() const = 0;

  /// @brief Applies the transaction to SurfaceFlinger.
  virtual void Apply() = 0;

  /// @brief Re-parents `child` under `new_parent` (or detaches if nullptr).
  virtual void Reparent(AndroidSurfaceControl* child,
                        AndroidSurfaceControl* new_parent) = 0;

  /// @brief Sets the visibility of `surface`.
  virtual void SetVisibility(AndroidSurfaceControl* surface,
                             AndroidSurfaceControlVisibility visibility) = 0;

  /// @brief Sets the Z-order of `surface` relative to its parent.
  virtual void SetZOrder(AndroidSurfaceControl* surface, int32_t z_order) = 0;

  /// @brief Attaches an AHardwareBuffer* and optional acquire fence fd to
  /// `surface`.
  virtual void SetBuffer(AndroidSurfaceControl* surface,
                         void* hardware_buffer,
                         int acquire_fence_fd = -1) = 0;

  /// @brief Sets the geometry (source crop, destination frame, and transform)
  /// of `surface`.
  virtual void SetGeometry(AndroidSurfaceControl* surface,
                           const AndroidSurfaceControlRect& source,
                           const AndroidSurfaceControlRect& destination,
                           AndroidSurfaceControlTransform transform) = 0;

  /// @brief Sets the buffer transparency alpha in [0.0, 1.0].
  virtual void SetBufferAlpha(AndroidSurfaceControl* surface, float alpha) = 0;

  /// @brief Sets the solid background color of `surface`.
  virtual void SetColor(AndroidSurfaceControl* surface,
                        const AndroidSurfaceControlColor& color) = 0;

  /// @brief Sets the desired frame rate for `surface` (API 30+).
  virtual void SetFrameRate(AndroidSurfaceControl* surface,
                            float frame_rate,
                            int8_t compatibility) = 0;

  /// @brief Enables or disables back-pressure on buffer latching (API 31+).
  virtual void SetEnableBackPressure(AndroidSurfaceControl* surface,
                                     bool enable) = 0;

  /// @brief Registers a callback invoked when SurfaceFlinger completes the
  /// transaction.
  virtual void SetOnCompleteCallback(OnCompleteCallback callback) = 0;

  /// @brief Registers a callback invoked when SurfaceFlinger commits the
  /// transaction (API 31+).
  virtual void SetOnCommitCallback(OnCommitCallback callback) = 0;

 protected:
  AndroidSurfaceTransaction() = default;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceTransaction);
};

/// @brief Abstract factory for creating AndroidSurfaceControl and
/// AndroidSurfaceTransaction instances.
class AndroidSurfaceControlProvider {
 public:
  virtual ~AndroidSurfaceControlProvider() = default;

  /// @brief Returns true if the Android SurfaceControl NDK API (API 29+) is
  /// available.
  virtual bool IsAvailable() const = 0;

  /// @brief Creates an ASurfaceControl rooted at an ANativeWindow*.
  virtual std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* native_window,
      const std::string& debug_name) = 0;

  /// @brief Creates a child ASurfaceControl parented to `parent`.
  virtual std::unique_ptr<AndroidSurfaceControl> CreateFromParent(
      AndroidSurfaceControl* parent,
      const std::string& debug_name) = 0;

  /// @brief Creates a new ASurfaceTransaction.
  virtual std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() = 0;

 protected:
  AndroidSurfaceControlProvider() = default;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceControlProvider);
};

/// @brief Production implementation of AndroidSurfaceControlProvider backed by
/// dynamic symbol resolution from `libandroid.so`.
class DefaultAndroidSurfaceControlProvider final
    : public AndroidSurfaceControlProvider {
 public:
  using ASurfaceControlCreateFromWindowFn = void* (*)(void* parent_window,
                                                      const char* debug_name);
  using ASurfaceControlCreateFn = void* (*)(void* parent_control,
                                            const char* debug_name);
  using ASurfaceControlReleaseFn = void (*)(void* surface_control);

  using ASurfaceTransactionCreateFn = void* (*)();
  using ASurfaceTransactionDeleteFn = void (*)(void* transaction);
  using ASurfaceTransactionApplyFn = void (*)(void* transaction);
  using ASurfaceTransactionReparentFn = void (*)(void* transaction,
                                                 void* surface_control,
                                                 void* new_parent);
  using ASurfaceTransactionSetVisibilityFn = void (*)(void* transaction,
                                                      void* surface_control,
                                                      int8_t visibility);
  using ASurfaceTransactionSetZOrderFn = void (*)(void* transaction,
                                                  void* surface_control,
                                                  int32_t z_order);
  using ASurfaceTransactionSetBufferFn = void (*)(void* transaction,
                                                  void* surface_control,
                                                  void* buffer,
                                                  int acquire_fence_fd);
  using ASurfaceTransactionSetGeometryFn =
      void (*)(void* transaction,
               void* surface_control,
               const AndroidSurfaceControlRect& source,
               const AndroidSurfaceControlRect& destination,
               int32_t transform);
  using ASurfaceTransactionSetBufferAlphaFn = void (*)(void* transaction,
                                                       void* surface_control,
                                                       float alpha);
  using ASurfaceTransactionSetColorFn = void (*)(void* transaction,
                                                 void* surface_control,
                                                 float r,
                                                 float g,
                                                 float b,
                                                 float a,
                                                 int32_t dataspace);
  using ASurfaceTransactionSetFrameRateFn = void (*)(void* transaction,
                                                     void* surface_control,
                                                     float frame_rate,
                                                     int8_t compatibility);
  using ASurfaceTransactionSetEnableBackPressureFn =
      void (*)(void* transaction, void* surface_control, bool enable);
  using ASurfaceTransactionCallbackFunc = void (*)(void* context, void* stats);
  using ASurfaceTransactionSetOnCompleteFn =
      void (*)(void* transaction,
               void* context,
               ASurfaceTransactionCallbackFunc func);
  using ASurfaceTransactionSetOnCommitFn =
      void (*)(void* transaction,
               void* context,
               ASurfaceTransactionCallbackFunc func);
  using ASurfaceTransactionStatsGetAcquireTimeFn =
      int64_t (*)(void* stats, void* surface_control);
  using ASurfaceTransactionStatsGetPreviousReleaseFenceFdFn =
      int (*)(void* stats, void* surface_control);
  using ASurfaceTransactionStatsGetLatchTimeFn = int64_t (*)(void* stats);
  using ASurfaceTransactionStatsGetPresentFenceFdFn = int (*)(void* stats);

  struct ProcTable {
    ASurfaceControlCreateFromWindowFn create_from_window = nullptr;
    ASurfaceControlCreateFn create = nullptr;
    ASurfaceControlReleaseFn release = nullptr;
    ASurfaceTransactionCreateFn transaction_create = nullptr;
    ASurfaceTransactionDeleteFn transaction_delete = nullptr;
    ASurfaceTransactionApplyFn transaction_apply = nullptr;
    ASurfaceTransactionReparentFn transaction_reparent = nullptr;
    ASurfaceTransactionSetVisibilityFn transaction_set_visibility = nullptr;
    ASurfaceTransactionSetZOrderFn transaction_set_z_order = nullptr;
    ASurfaceTransactionSetBufferFn transaction_set_buffer = nullptr;
    ASurfaceTransactionSetGeometryFn transaction_set_geometry = nullptr;
    ASurfaceTransactionSetBufferAlphaFn transaction_set_buffer_alpha = nullptr;
    ASurfaceTransactionSetColorFn transaction_set_color = nullptr;
    ASurfaceTransactionSetFrameRateFn transaction_set_frame_rate = nullptr;
    ASurfaceTransactionSetEnableBackPressureFn
        transaction_set_enable_back_pressure = nullptr;
    ASurfaceTransactionSetOnCompleteFn transaction_set_on_complete = nullptr;
    ASurfaceTransactionSetOnCommitFn transaction_set_on_commit = nullptr;
    ASurfaceTransactionStatsGetAcquireTimeFn stats_get_acquire_time = nullptr;
    ASurfaceTransactionStatsGetPreviousReleaseFenceFdFn
        stats_get_previous_release_fence_fd = nullptr;
    ASurfaceTransactionStatsGetLatchTimeFn stats_get_latch_time = nullptr;
    ASurfaceTransactionStatsGetPresentFenceFdFn stats_get_present_fence_fd =
        nullptr;

    bool IsComplete() const {
      return create_from_window != nullptr && create != nullptr &&
             release != nullptr && transaction_create != nullptr &&
             transaction_delete != nullptr && transaction_apply != nullptr &&
             transaction_reparent != nullptr &&
             transaction_set_visibility != nullptr &&
             transaction_set_z_order != nullptr &&
             transaction_set_buffer != nullptr &&
             transaction_set_geometry != nullptr &&
             transaction_set_buffer_alpha != nullptr;
    }
  };

  explicit DefaultAndroidSurfaceControlProvider(
      std::shared_ptr<OSLibraryLoader> loader = nullptr);

  ~DefaultAndroidSurfaceControlProvider() override;

  bool IsAvailable() const override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* native_window,
      const std::string& debug_name) override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromParent(
      AndroidSurfaceControl* parent,
      const std::string& debug_name) override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() override;

  const ProcTable& procs() const { return procs_; }

 private:
  std::unique_ptr<OSLibrary> android_library_;
  ProcTable procs_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceControlProvider);
};

/// @brief Default NDK-backed AndroidSurfaceControl implementation.
class DefaultAndroidSurfaceControl final : public AndroidSurfaceControl {
 public:
  DefaultAndroidSurfaceControl(
      void* handle,
      std::string debug_name,
      const DefaultAndroidSurfaceControlProvider::ProcTable& procs);

  ~DefaultAndroidSurfaceControl() override;

  bool IsValid() const override;
  void* RawHandle() const override;
  const std::string& DebugName() const override;

 private:
  void* handle_ = nullptr;
  std::string debug_name_;
  DefaultAndroidSurfaceControlProvider::ProcTable procs_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceControl);
};

/// @brief Default NDK-backed AndroidSurfaceTransaction implementation.
class DefaultAndroidSurfaceTransaction final
    : public AndroidSurfaceTransaction {
 public:
  DefaultAndroidSurfaceTransaction(
      void* handle,
      const DefaultAndroidSurfaceControlProvider::ProcTable& procs);

  ~DefaultAndroidSurfaceTransaction() override;

  bool IsValid() const override;
  void Apply() override;
  void Reparent(AndroidSurfaceControl* child,
                AndroidSurfaceControl* new_parent) override;
  void SetVisibility(AndroidSurfaceControl* surface,
                     AndroidSurfaceControlVisibility visibility) override;
  void SetZOrder(AndroidSurfaceControl* surface, int32_t z_order) override;
  void SetBuffer(AndroidSurfaceControl* surface,
                 void* hardware_buffer,
                 int acquire_fence_fd = -1) override;
  void SetGeometry(AndroidSurfaceControl* surface,
                   const AndroidSurfaceControlRect& source,
                   const AndroidSurfaceControlRect& destination,
                   AndroidSurfaceControlTransform transform) override;
  void SetBufferAlpha(AndroidSurfaceControl* surface, float alpha) override;
  void SetColor(AndroidSurfaceControl* surface,
                const AndroidSurfaceControlColor& color) override;
  void SetFrameRate(AndroidSurfaceControl* surface,
                    float frame_rate,
                    int8_t compatibility) override;
  void SetEnableBackPressure(AndroidSurfaceControl* surface,
                             bool enable) override;
  void SetOnCompleteCallback(OnCompleteCallback callback) override;
  void SetOnCommitCallback(OnCommitCallback callback) override;

  void SetStatsTargetSurface(AndroidSurfaceControl* surface);

 private:
  struct CallbackContext {
    OnCompleteCallback on_complete;
    OnCommitCallback on_commit;
    DefaultAndroidSurfaceControlProvider::ProcTable procs;
    void* target_surface_handle = nullptr;
  };

  static void OnCompleteThunk(void* context, void* stats);
  static void OnCommitThunk(void* context, void* stats);
  static AndroidSurfaceControlStats ExtractStats(
      const DefaultAndroidSurfaceControlProvider::ProcTable& procs,
      void* stats,
      void* surface_handle);

  void* handle_ = nullptr;
  DefaultAndroidSurfaceControlProvider::ProcTable procs_;
  void* stats_target_surface_ = nullptr;
  OnCompleteCallback pending_on_complete_;
  OnCommitCallback pending_on_commit_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidSurfaceTransaction);
};

/// @brief Host-testable in-memory implementation of AndroidSurfaceControl.
class InMemoryAndroidSurfaceControl final : public AndroidSurfaceControl {
 public:
  InMemoryAndroidSurfaceControl(uint64_t id,
                                std::string debug_name,
                                void* parent_window,
                                InMemoryAndroidSurfaceControl* parent_control);

  ~InMemoryAndroidSurfaceControl() override;

  bool IsValid() const override;
  void* RawHandle() const override;
  const std::string& DebugName() const override;

  uint64_t id() const { return id_; }
  void* parent_window() const { return parent_window_; }
  InMemoryAndroidSurfaceControl* parent_control() const {
    return parent_control_;
  }
  void set_parent_control(InMemoryAndroidSurfaceControl* new_parent) {
    parent_control_ = new_parent;
  }

  AndroidSurfaceControlState& mutable_state() { return state_; }
  const AndroidSurfaceControlState& state() const { return state_; }

 private:
  uint64_t id_ = 0;
  void* parent_window_ = nullptr;
  InMemoryAndroidSurfaceControl* parent_control_ = nullptr;
  AndroidSurfaceControlState state_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceControl);
};

/// @brief Host-testable in-memory implementation of AndroidSurfaceTransaction.
class InMemoryAndroidSurfaceTransaction final
    : public AndroidSurfaceTransaction {
 public:
  explicit InMemoryAndroidSurfaceTransaction(
      const AndroidSurfaceControlStats& simulated_stats = {});

  ~InMemoryAndroidSurfaceTransaction() override;

  bool IsValid() const override;
  void Apply() override;
  void Reparent(AndroidSurfaceControl* child,
                AndroidSurfaceControl* new_parent) override;
  void SetVisibility(AndroidSurfaceControl* surface,
                     AndroidSurfaceControlVisibility visibility) override;
  void SetZOrder(AndroidSurfaceControl* surface, int32_t z_order) override;
  void SetBuffer(AndroidSurfaceControl* surface,
                 void* hardware_buffer,
                 int acquire_fence_fd = -1) override;
  void SetGeometry(AndroidSurfaceControl* surface,
                   const AndroidSurfaceControlRect& source,
                   const AndroidSurfaceControlRect& destination,
                   AndroidSurfaceControlTransform transform) override;
  void SetBufferAlpha(AndroidSurfaceControl* surface, float alpha) override;
  void SetColor(AndroidSurfaceControl* surface,
                const AndroidSurfaceControlColor& color) override;
  void SetFrameRate(AndroidSurfaceControl* surface,
                    float frame_rate,
                    int8_t compatibility) override;
  void SetEnableBackPressure(AndroidSurfaceControl* surface,
                             bool enable) override;
  void SetOnCompleteCallback(OnCompleteCallback callback) override;
  void SetOnCommitCallback(OnCommitCallback callback) override;

  bool IsApplied() const { return applied_; }
  size_t PendingOperationCount() const { return pending_ops_.size(); }

 private:
  std::vector<std::function<void()>> pending_ops_;
  OnCompleteCallback on_complete_;
  OnCommitCallback on_commit_;
  AndroidSurfaceControlStats simulated_stats_;
  bool applied_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceTransaction);
};

/// @brief Host-testable in-memory implementation of
/// AndroidSurfaceControlProvider.
class InMemoryAndroidSurfaceControlProvider final
    : public AndroidSurfaceControlProvider {
 public:
  explicit InMemoryAndroidSurfaceControlProvider(bool available = true);
  ~InMemoryAndroidSurfaceControlProvider() override;

  bool IsAvailable() const override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromWindow(
      void* native_window,
      const std::string& debug_name) override;

  std::unique_ptr<AndroidSurfaceControl> CreateFromParent(
      AndroidSurfaceControl* parent,
      const std::string& debug_name) override;

  std::unique_ptr<AndroidSurfaceTransaction> CreateTransaction() override;

  void SetSimulatedStats(const AndroidSurfaceControlStats& stats) {
    simulated_stats_ = stats;
  }

  size_t CreatedSurfaceCount() const { return next_id_ - 1; }
  size_t CreatedTransactionCount() const { return created_transactions_; }

 private:
  bool available_ = true;
  uint64_t next_id_ = 1;
  size_t created_transactions_ = 0;
  AndroidSurfaceControlStats simulated_stats_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidSurfaceControlProvider);
};

}  // namespace android

using android::AndroidSurfaceControl;
using android::AndroidSurfaceControlColor;
using android::AndroidSurfaceControlProvider;
using android::AndroidSurfaceControlRect;
using android::AndroidSurfaceControlState;
using android::AndroidSurfaceControlStats;
using android::AndroidSurfaceControlTransform;
using android::AndroidSurfaceControlVisibility;
using android::AndroidSurfaceTransaction;
using android::AndroidSystemPropertiesForVulkan;
using android::AndroidVulkanResolutionStatus;
using android::DefaultAndroidSurfaceControl;
using android::DefaultAndroidSurfaceControlProvider;
using android::DefaultAndroidSurfaceTransaction;
using android::InMemoryAndroidSurfaceControl;
using android::InMemoryAndroidSurfaceControlProvider;
using android::InMemoryAndroidSurfaceTransaction;
using android::kAndroidImplicitViewId;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_CONTROL_H_
