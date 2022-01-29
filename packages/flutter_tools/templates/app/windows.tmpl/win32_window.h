#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <Windows.h>
#include <Windowsx.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates and shows a win32 window with |title| and position and size using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, hence to ensure a
  // consistent size to will treat the width height passed in to this function
  // as logical pixels and scale to appropriate for the default monitor. Returns
  // true if the window was created successfully.
  bool CreateAndShow(const std::wstring &title, const Point &origin,
                     const Size &size);

  // Release OS resources asociated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle();

 protected:
  // Registers a window class with default style attributes, cursor and
  // icon.
  WNDCLASS RegisterWindowClass();

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responsponds to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Processes and route salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  LRESULT
  MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                 LPARAM const lparam) noexcept;

 private:
  // should message loop keep running
  bool messageloop_running_ = true;

  // Retrieves a class instance pointer for |window|
  static Win32Window *GetThisFromHandle(HWND const window) noexcept;

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;
};

#endif  // WIN32_WINDOW_H_
