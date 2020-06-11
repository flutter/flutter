#include "fl_application.h"

int main(int argc, char** argv) {
  g_autoptr(FlApplication) app = fl_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
