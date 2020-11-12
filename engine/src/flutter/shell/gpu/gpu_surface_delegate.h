#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_

#include "flutter/flow/embedded_views.h"

namespace flutter {

class GPUSurfaceDelegate {
 public:
  virtual ~GPUSurfaceDelegate() {}

  //----------------------------------------------------------------------------
  /// @brief      Gets the view embedder that controls how the Flutter layer
  ///             hierarchy split into multiple chunks should be composited back
  ///             on-screen. This field is optional and the Flutter rasterizer
  ///             will render into a single on-screen surface if this call
  ///             returns a null external view embedder. This happens on the GPU
  ///             thread.
  ///
  /// @return     The external view embedder, or, null if Flutter is rendering
  ///             into a single on-screen surface.
  ///
  virtual ExternalViewEmbedder* GetExternalViewEmbedder() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_
