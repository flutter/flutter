#ifndef FLUTTER_FL_APPLICATION_H_
#define FLUTTER_FL_APPLICATION_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(FlApplication, fl_application, FL, APPLICATION,
                     GtkApplication)

/**
 * fl_application_new:
 *
 * Creates a new Flutter application.
 *
 * Returns: a new #FlApplication.
 */
FlApplication* fl_application_new();

#endif  // FLUTTER_FL_APPLICATION_H_
