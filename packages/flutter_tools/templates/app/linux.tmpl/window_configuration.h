#ifndef WINDOW_CONFIGURATION_
#define WINDOW_CONFIGURATION_

// This is a temporary approach to isolate common customizations from main.cpp,
// where the APIs are still in flux. This should simplify re-creating the
// runner while preserving local changes.
//
// Longer term there should be simpler configuration options for common
// customizations like this, without requiring native code changes.

extern const char *kFlutterWindowTitle;
extern const unsigned int kFlutterWindowWidth;
extern const unsigned int kFlutterWindowHeight;

#endif  // WINDOW_CONFIGURATION_
