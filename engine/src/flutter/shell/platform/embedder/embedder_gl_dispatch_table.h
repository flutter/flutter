#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_DISPATCH_TABLE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_DISPATCH_TABLE_H_

#include <functional>
#include "shell/gpu/gpu_surface_gl_delegate.h"

namespace flutter {

struct GLDispatchTable {
  std::function<bool(void)> gl_make_current_callback;                // required
  std::function<bool(void)> gl_clear_current_callback;               // required
  std::function<bool(GLPresentInfo)> gl_present_callback;            // required
  std::function<intptr_t(GLFrameInfo)> gl_fbo_callback;              // required
  std::function<bool(void)> gl_make_resource_current_callback;       // optional
  std::function<DlMatrix(void)> gl_surface_transformation_callback;  // optional
  std::function<void*(const char*)> gl_proc_resolver;                // optional
  std::function<GLFBOInfo(intptr_t)> gl_populate_existing_damage;    // required
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_GL_DISPATCH_TABLE_H_
