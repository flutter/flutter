#include "my_application.h"

int main(int argc, char** argv) {
  // Only X11 is currently supported.
  // Wayland support is being developed: https://github.com/flutter/flutter/issues/57932.
  gdk_set_allowed_backends("x11");

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
