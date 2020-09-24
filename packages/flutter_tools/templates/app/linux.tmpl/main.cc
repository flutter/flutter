#include "my_application.h"

int main(int argc, char** argv) {
  // We only currently support X11 and Wayland.
  gdk_set_allowed_backends("wayland,x11");

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
