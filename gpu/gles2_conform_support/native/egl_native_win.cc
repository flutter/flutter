// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extern "C" {
#if defined(GLES2_CONFORM_SUPPORT_ONLY)
#include "gpu/gles2_conform_support/gtf/gtf_stubs.h"
#else
#include "third_party/gles2_conform/GTF_ES/glsl/GTF/Source/eglNative.h"
#endif
}

#include <string>

namespace {
LPCTSTR kWindowClassName = TEXT("ES2CONFORM");

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg,
                            WPARAM w_param, LPARAM l_param) {
  LRESULT result = 0;
  switch (msg) {
    case WM_CLOSE:
      ::DestroyWindow(hwnd);
      break;
    case WM_DESTROY:
      ::PostQuitMessage(0);
      break;
    case WM_ERASEBKGND:
      // Return a non-zero value to indicate that the background has been
      // erased.
      result = 1;
      break;
    default:
      result = ::DefWindowProc(hwnd, msg, w_param, l_param);
      break;
  }
  return result;
}
}  // namespace.

extern "C" {

GTFbool GTFNativeCreateDisplay(EGLNativeDisplayType *pNativeDisplay) {
  *pNativeDisplay = EGL_DEFAULT_DISPLAY;
  return GTFtrue;
}

void GTFNativeDestroyDisplay(EGLNativeDisplayType nativeDisplay) {
  // Nothing to destroy since we are using EGL_DEFAULT_DISPLAY
}

GTFbool GTFNativeCreateWindow(EGLNativeDisplayType nativeDisplay,
                              EGLDisplay eglDisplay, EGLConfig eglConfig,
                              const char* title, int width, int height,
                              EGLNativeWindowType *pNativeWindow) {
  WNDCLASS wnd_class = {0};
  HINSTANCE instance = GetModuleHandle(NULL);
  wnd_class.style = CS_OWNDC;
  wnd_class.lpfnWndProc = WindowProc;
  wnd_class.hInstance = instance;
  wnd_class.hbrBackground =
      reinterpret_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
  wnd_class.lpszClassName = kWindowClassName;
  if (!RegisterClass(&wnd_class))
    return GTFfalse;

  DWORD wnd_style = WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
  RECT wnd_rect;
  wnd_rect.left = 0;
  wnd_rect.top = 0;
  wnd_rect.right = width;
  wnd_rect.bottom = height;
  if (!AdjustWindowRect(&wnd_rect, wnd_style, FALSE))
    return GTFfalse;

#ifdef UNICODE
  // Convert ascii string to wide string.
  const std::wstring wnd_title(title, title + strlen(title));
#else
  const std::string wnd_title = title;
#endif  // UNICODE

  HWND hwnd = CreateWindow(
      wnd_class.lpszClassName,
      wnd_title.c_str(),
      wnd_style,
      0,
      0,
      wnd_rect.right - wnd_rect.left,
      wnd_rect.bottom - wnd_rect.top,
      NULL,
      NULL,
      instance,
      NULL);
  if (hwnd == NULL)
    return GTFfalse;

  ShowWindow(hwnd, SW_SHOWNORMAL);
  *pNativeWindow = hwnd;
  return GTFtrue;
}

void GTFNativeDestroyWindow(EGLNativeDisplayType nativeDisplay,
                            EGLNativeWindowType nativeWindow) {
  DestroyWindow(nativeWindow);
  UnregisterClass(kWindowClassName, GetModuleHandle(NULL));
}

EGLImageKHR GTFCreateEGLImage(int width, int height,
                              GLenum format, GLenum type) {
  return (EGLImageKHR)NULL;
}

void GTFDestroyEGLImage(EGLImageKHR image) {
}

}  // extern "C"
