// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMPELLER_DEVICE_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMPELLER_DEVICE_CONTEXT_H_

#include <functional>
#include <memory>

namespace impeller {
class Context;
}  // namespace impeller

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Returns the device context of the engine's Impeller renderer, as
///             the platform view provides it (`PlatformView::
///             GetImpellerContext`), or null if the engine does not render with
///             Impeller or has not set up its context yet.
///
///             Textures that import buffers with Vulkan need this context. The
///             Impeller context of the paint context is not enough: surfaces
///             paint with a `SurfaceContextVK` that wraps it, while snapshots
///             taken without a surface paint with the device context itself,
///             and the two cannot be told apart.
///
///             Textures call it on the raster thread, the thread the shell sets
///             the context up on.
///
using EmbedderImpellerDeviceContextGetter =
    std::function<std::shared_ptr<impeller::Context>()>;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_IMPELLER_DEVICE_CONTEXT_H_
