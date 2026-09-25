# ADR-0006: External Textures via Zero-Copy Vulkan `AHardwareBuffer` and `FlutterOpenGLTexture2`

## Status
ACCEPTED

## RFC 410 Cross-Reference
Section: *Detailed Design* -> *External Textures (Zero-Copy Vulkan and OpenGL ES)*

## Context & Problem Statement
Android provides two distinct mechanisms for external textures:
1. `SurfaceProducer`: A zero-copy pipeline that imports `AHardwareBuffer` handles directly into Vulkan (`VkImage`) or EGL (`EGLImage`).
2. `SurfaceTexture`: A legacy OpenGL ES path where native frames render into a texture ID updated via `SurfaceTexture.updateTexImage()`.

Previously, `embedder.h` lacked a mechanism to import Vulkan external images without subclassing the internal engine `flutter::Texture` class. Furthermore, the existing `FlutterOpenGLTexture` struct lacked a UV coordinate transformation matrix. On Android, `SurfaceTexture.getTransformMatrix()` provides a 4x4 matrix accounting for camera sensor orientation, video decoder padding, and coordinate inversion. Without this matrix, external video and camera streams render upside down or distorted.

## Non-Negotiable Invariants
1. **Zero-Copy Vulkan Import**: Vulkan external textures must support direct `AHardwareBuffer` import via discriminated unions without intermediate memory copies or CPU readbacks.
2. **YCbCr Sampling Support**: `FlutterVulkanExternalTexture` must supply `ycbcr_conversion_info` carrying the vendor-specific external format and component swizzle for camera and video decoder buffers.
3. **UV Transformation Parity**: OpenGL external textures must pass full 4x4 UV transformation matrices (`FlutterOpenGLTexture2.uv_transform`) to match `SurfaceTexture.getTransformMatrix()` semantics.
4. **Pull-Based Frame Model**: Content must be acquired via pull-based callbacks on the renderer config (`external_texture_frame_callback`), matching engine composition timing.

## Chosen Solution
- Extend `embedder.h` with `FlutterVulkanExternalTexture` and `FlutterVulkanExternalTextureFrameCallback` on `FlutterVulkanRendererConfig`:
  - Uses a discriminated union supporting both `FlutterVulkanImageHandle` (`VkImage`) and `FlutterAHardwareBufferHandle` (`AHardwareBuffer`).
  - Includes `FlutterVulkanYcbcrConversionInfo` for camera/video formats.
  - Parallel `FlutterHardwareBufferExternalTextureFrameCallback` sits on both Vulkan and OpenGL configs.
- Introduce `FlutterOpenGLTexture2` containing `FlutterTransformation uv_transform` to convey 4x4 transformation matrices without depending on `SkM44` or Skia headers.
- Modularize `AndroidHardwareBuffer` and `AndroidVulkanExternalTexture` inside `:flutter_embedder_native_src`.

## Rejected Alternatives & Rationale
- *Pushing raw `VkImage` pointers from Java*: Rejected because Java/Kotlin cannot safely manage Vulkan image layout transitions or descriptor sets directly without NDK graphics context coupling.
- *Omitting UV transform matrix*: Rejected because video player and camera plugins require dynamic coordinate padding and sensor rotation adjustments; omitting it causes inverted or cropped video frames.
- *Retaining Skia `SkM44` matrix types*: Rejected because Skia headers must be completely eliminated across the public C-API boundary.

## Verification Contract
- Video player plugin integration test verifies zero dropped frames and correct aspect ratio/orientation during playback.
- Camera preview integration test verifies correct YCbCr hardware sampling across multiple Android OEM devices.
- Unit tests in `flutter_embedder_native_unittests` validate `uv_transform` serialization and frame callbacks.
