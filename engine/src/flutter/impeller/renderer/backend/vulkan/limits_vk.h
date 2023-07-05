#pragma once

#include <stdint.h>

namespace impeller {

// Maximum size to use VMA image suballocation. Any allocation greater than or
// equal to this value will use a dedicated VkDeviceMemory.
//
// This value was taken from ANGLE.
constexpr size_t kImageSizeThresholdForDedicatedMemoryAllocation =
    4 * 1024 * 1024;

}  // namespace impeller
