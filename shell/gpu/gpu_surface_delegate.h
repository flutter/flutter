#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"

namespace flutter {

class GPUSurfaceDelegate {
 public:
  // Get a reference to the external views embedder. This happens on the same
  // thread that the renderer is operating on.
  virtual ExternalViewEmbedder* GetExternalViewEmbedder() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_DELEGATE_H_
