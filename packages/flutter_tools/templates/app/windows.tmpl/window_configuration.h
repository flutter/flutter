#ifndef WINDOW_CONFIGURATION_
#define WINDOW_CONFIGURATION_

// This is a temporary approach to isolate changes that people are likely to
// make to the example project from main.cpp, where the APIs are still in flux.
// This will avoid people needing to resolve conflicts or re-create changes
// slightly different every time the Windows Flutter API surface changes just
// because of, e.g., a local change to the window title.
//
// Longer term there should be simpler configuration options for common
// customizations like this, without requiring native code changes.

extern const wchar_t *kFlutterWindowTitle;
extern const unsigned int kFlutterWindowOriginX;
extern const unsigned int kFlutterWindowOriginY;
extern const unsigned int kFlutterWindowWidth;
extern const unsigned int kFlutterWindowHeight;

#endif  // WINDOW_CONFIGURATION_
