// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_NATIVE_WIDGET_TYPES_H_
#define UI_GFX_NATIVE_WIDGET_TYPES_H_

#include "build/build_config.h"

#if defined(OS_ANDROID)
#include <jni.h>
#endif

#include "base/basictypes.h"
#include "base/logging.h"
#include "ui/gfx/gfx_export.h"

// This file provides cross platform typedefs for native widget types.
//   NativeWindow: this is a handle to a native, top-level window
//   NativeView: this is a handle to a native UI element. It may be the
//     same type as a NativeWindow on some platforms.
//   NativeViewId: Often, in our cross process model, we need to pass around a
//     reference to a "window". This reference will, say, be echoed back from a
//     renderer to the browser when it wishes to query its size. On Windows we
//     use an HWND for this.
//
//     As a rule of thumb - if you're in the renderer, you should be dealing
//     with NativeViewIds. This should remind you that you shouldn't be doing
//     direct operations on platform widgets from the renderer process.
//
//     If you're in the browser, you're probably dealing with NativeViews,
//     unless you're in the IPC layer, which will be translating between
//     NativeViewIds from the renderer and NativeViews.
//
//   NativeEditView: a handle to a native edit-box. The Mac folks wanted this
//     specific typedef.
//
//   NativeImage: The platform-specific image type used for drawing UI elements
//     in the browser.
//
// The name 'View' here meshes with OS X where the UI elements are called
// 'views' and with our Chrome UI code where the elements are also called
// 'views'.

class SkRegion;
namespace ui {
class Event;
}

#if defined(OS_POSIX)
typedef struct _PangoFontDescription PangoFontDescription;
typedef struct _cairo cairo_t;
#endif

#if defined(OS_ANDROID)
struct ANativeWindow;
namespace ui {
class WindowAndroid;
class ViewAndroid;
}
#endif
class SkBitmap;

#if defined(USE_GLFW)
struct GLFWwindow;
#endif

namespace gfx {

#if defined(OS_LINUX)
typedef SkRegion* NativeRegion;
typedef ui::Event* NativeEvent;
#elif defined(OS_ANDROID)
typedef void* NativeRegion;
typedef jobject NativeEvent;
#endif

#if defined(USE_CAIRO)
typedef PangoFontDescription* NativeFont;
typedef void* NativeEditView;
typedef cairo_t* NativeDrawingContext;
typedef void* NativeViewAccessible;
#else
typedef void* NativeFont;
typedef void* NativeEditView;
typedef void* NativeDrawingContext;
typedef void* NativeViewAccessible;
#endif

// A constant value to indicate that gfx::NativeCursor refers to no cursor.
#if defined(OS_LINUX)
const int kNullCursor = 0;
#endif

typedef SkBitmap NativeImageType;
typedef NativeImageType* NativeImage;

// Note: for test_shell we're packing a pointer into the NativeViewId. So, if
// you make it a type which is smaller than a pointer, you have to fix
// test_shell.
//
// See comment at the top of the file for usage.
typedef intptr_t NativeViewId;

// PluginWindowHandle is an abstraction wrapping "the types of windows
// used by NPAPI plugins". On Windows it's an HWND, on X it's an X
// window id.
#if defined(USE_X11)
  typedef unsigned long PluginWindowHandle;
  const PluginWindowHandle kNullPluginWindow = 0;
#elif defined(OS_ANDROID)
  typedef uint64 PluginWindowHandle;
  const PluginWindowHandle kNullPluginWindow = 0;
#elif defined(USE_OZONE)
  typedef intptr_t PluginWindowHandle;
  const PluginWindowHandle kNullPluginWindow = 0;
#else
  // On Mac we don't have windowed plugins. We use a NULL/0 PluginWindowHandle
  // in shared code to indicate there is no window present.
  typedef bool PluginWindowHandle;
  const PluginWindowHandle kNullPluginWindow = 0;
#endif

enum SurfaceType {
  EMPTY,
  NATIVE_DIRECT,
  NULL_TRANSPORT,
  SURFACE_TYPE_LAST = NULL_TRANSPORT
};

struct GLSurfaceHandle {
  GLSurfaceHandle()
      : handle(kNullPluginWindow),
        transport_type(EMPTY),
        parent_client_id(0) {
  }
  GLSurfaceHandle(PluginWindowHandle handle_, SurfaceType transport_)
      : handle(handle_),
        transport_type(transport_),
        parent_client_id(0) {
    DCHECK(!is_null() || handle == kNullPluginWindow);
    DCHECK(transport_type != NULL_TRANSPORT ||
           handle == kNullPluginWindow);
  }
  bool is_null() const { return transport_type == EMPTY; }
  bool is_transport() const {
    return transport_type == NULL_TRANSPORT;
  }
  PluginWindowHandle handle;
  SurfaceType transport_type;
  uint32 parent_client_id;
};

// AcceleratedWidget provides a surface to compositors to paint pixels.
#if defined(USE_GLFW)
typedef GLFWwindow* AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#elif defined(USE_X11)
typedef unsigned long AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#elif defined(OS_ANDROID)
typedef ANativeWindow* AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#elif defined(USE_OZONE)
typedef intptr_t AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#elif defined(OS_IOS)
typedef uintptr_t AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#elif defined(OS_MACOSX)
typedef uintptr_t AcceleratedWidget;
const AcceleratedWidget kNullAcceleratedWidget = 0;
#else
#error unknown platform
#endif

}  // namespace gfx

#endif  // UI_GFX_NATIVE_WIDGET_TYPES_H_
