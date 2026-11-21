#include "my_application.h"

int main(int argc, char** argv) {
#ifdef FLUTTER_LINUX_GTK4
  // Keep GTK composition on GL when Flutter supplies GL textures on Wayland.
  // GTK 4.16 and later can otherwise select Vulkan for this window.
  const char* renderer = g_getenv("FLUTTER_LINUX_RENDERER");
  const char* backend = g_getenv("GDK_BACKEND");
  if (gtk_check_version(4, 16, 0) == nullptr &&
      g_getenv("WAYLAND_DISPLAY") != nullptr &&
      (backend == nullptr || g_strcmp0(backend, "wayland") == 0) &&
      (renderer == nullptr || g_strcmp0(renderer, "opengl") == 0) &&
      g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_DMABUF"), "1") != 0 &&
      g_strcmp0(g_getenv("FLUTTER_GTK4_ENABLE_GRAPHICS_OFFLOAD"), "1") != 0) {
    g_setenv("GSK_RENDERER", "gl", FALSE);
  }
#endif
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
