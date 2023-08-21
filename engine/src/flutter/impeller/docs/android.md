# Android

## Backends

Android supports both GLES and Vulkan backends for Impeller.

For Android < 29, Impeller will choose GLES as the backend.
For Android >= 29, Impeller will choose Vulkan as the backend.

Version 29 provides HardwareBuffer support which is critical in efficiently
supporting Platform Views in Vulkan.

## Platform Views

Android Platform Views (i.e. an android.view.View embedded inside a Flutter app)
are supported in both GLES and Vulkan backends and the Engine manages this
automatically.

## SurfaceTexture

Flutter's Java API allows for developers to register custom SurfaceTexture
backed textures that can be rendered inside of a Flutter application. See
`TextureRegistry.registerSurfaceTexture` and `TextureRegistry.createSurfaceTexture`.

### GLES

There are no issues with SurfaceTextures when using the GLES backend.

### Vulkan

We do not currently support rendering these textures when using the Vulkan
backend. Supporting this will require adding support for importing GL textures
into Vulkan textures which will have performance implications.

